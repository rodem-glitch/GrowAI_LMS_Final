package kr.polytech.lms.job.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.job.client.Work24Client;
import kr.polytech.lms.job.config.Work24Properties;
import kr.polytech.lms.job.repository.JobRepository;
import kr.polytech.lms.job.repository.JobRepository.JobOccupationCodeRow;
import kr.polytech.lms.job.repository.JobRepository.JobRecruitCacheKey;
import kr.polytech.lms.job.repository.JobRepository.JobRecruitCacheRow;
import kr.polytech.lms.job.repository.JobRepository.JobRegionCodeRow;
import kr.polytech.lms.job.service.dto.JobOccupationCodeResponse;
import kr.polytech.lms.job.service.dto.JobRecruitItem;
import kr.polytech.lms.job.service.dto.JobRecruitListResponse;
import kr.polytech.lms.job.service.dto.JobRecruitSearchCriteria;
import kr.polytech.lms.job.service.dto.JobRegionCodeResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class JobService {
    // 왜: 채용 API는 Work24 실시간 조회 + DB 캐시를 동시에 지원해야 해서 서비스에서 정책을 통합합니다.

    private static final Logger log = LoggerFactory.getLogger(JobService.class);

    private final JobRepository jobRepository;
    private final Work24Client work24Client;
    private final Work24Properties work24Properties;
    private final ObjectMapper objectMapper;

    public JobService(
        JobRepository jobRepository,
        Work24Client work24Client,
        Work24Properties work24Properties,
        ObjectMapper objectMapper
    ) {
        this.jobRepository = Objects.requireNonNull(jobRepository);
        this.work24Client = Objects.requireNonNull(work24Client);
        this.work24Properties = Objects.requireNonNull(work24Properties);
        this.objectMapper = Objects.requireNonNull(objectMapper);
    }

    public List<JobRegionCodeResponse> getRegionCodes(String depthType, String depth1) {
        List<JobRegionCodeRow> rows = jobRepository.findRegionCodes(depthType, depth1);
        return rows.stream()
            .map(row -> new JobRegionCodeResponse(
                row.idx(),
                row.title(),
                row.depth1(),
                row.depth2(),
                row.depth3()
            ))
            .toList();
    }

    public List<JobOccupationCodeResponse> getOccupationCodes(String depthType, String depth1) {
        List<JobOccupationCodeRow> rows = jobRepository.findOccupationCodes(depthType, depth1);
        return rows.stream()
            .map(row -> new JobOccupationCodeResponse(
                row.idx(),
                row.code(),
                row.title(),
                row.depth1(),
                row.depth2(),
                row.depth3()
            ))
            .toList();
    }

    public JobRecruitListResponse getRecruitments(
        String region,
        String occupation,
        Integer startPage,
        Integer display,
        CachePolicy cachePolicy
    ) {
        JobRecruitSearchCriteria criteria = normalizeCriteria(region, occupation, startPage, display);
        CachePolicy safePolicy = cachePolicy == null ? CachePolicy.PREFER_CACHE : cachePolicy;

        if (safePolicy != CachePolicy.FORCE_LIVE) {
            Optional<JobRecruitListResponse> cached = findCachedRecruitments(criteria, safePolicy);
            if (cached.isPresent()) {
                return cached.get();
            }
        }

        JobRecruitListResponse live = work24Client.fetchRecruitList(criteria);
        saveRecruitCache(criteria, live);
        return live;
    }

    public JobRecruitListResponse getRelatedRecruitments(String occupation, Integer limit, CachePolicy cachePolicy) {
        int safeLimit = normalizeDisplay(limit, 3);
        return getRecruitments(null, occupation, 1, safeLimit, cachePolicy);
    }

    public JobRecruitListResponse refreshRecruitments(
        String region,
        String occupation,
        Integer startPage,
        Integer display
    ) {
        JobRecruitSearchCriteria criteria = normalizeCriteria(region, occupation, startPage, display);
        JobRecruitListResponse live = work24Client.fetchRecruitList(criteria);
        saveRecruitCache(criteria, live);
        return live;
    }

    @Scheduled(cron = "0 0 6 * * *", zone = "Asia/Seoul")
    public void refreshCachedRecruitmentsAtMorning() {
        if (!work24Properties.getCache().isEnabled()) {
            return;
        }

        List<JobRecruitCacheKey> keys = jobRepository.findAllRecruitCacheKeys();
        if (keys.isEmpty()) {
            return;
        }

        for (JobRecruitCacheKey key : keys) {
            try {
                refreshRecruitmentCache(key);
            } catch (Exception e) {
                log.warn("채용 캐시 갱신 실패: queryKey={}", key.queryKey(), e);
            }
        }
    }

    private void refreshRecruitmentCache(JobRecruitCacheKey key) {
        JobRecruitSearchCriteria criteria = new JobRecruitSearchCriteria(
            key.regionCode(),
            key.occupationCode(),
            key.startPage(),
            key.display(),
            "L"
        );
        JobRecruitListResponse live = work24Client.fetchRecruitList(criteria);
        saveRecruitCache(criteria, live);
    }

    private Optional<JobRecruitListResponse> findCachedRecruitments(
        JobRecruitSearchCriteria criteria,
        CachePolicy cachePolicy
    ) {
        if (!work24Properties.getCache().isEnabled()) {
            return Optional.empty();
        }

        String queryKey = buildQueryKey(criteria);
        Optional<JobRecruitCacheRow> cached = jobRepository.findRecruitCache(queryKey);
        if (cached.isEmpty()) {
            if (cachePolicy == CachePolicy.CACHE_ONLY) {
                throw new IllegalStateException("캐시된 채용 정보가 없습니다.");
            }
            return Optional.empty();
        }

        JobRecruitCacheRow row = cached.get();
        if (!isCacheFresh(row.updatedAt())) {
            if (cachePolicy == CachePolicy.CACHE_ONLY) {
                return Optional.of(parseCache(row));
            }
            return Optional.empty();
        }

        return Optional.of(parseCache(row));
    }

    private JobRecruitListResponse parseCache(JobRecruitCacheRow row) {
        try {
            List<JobRecruitItem> items = objectMapper.readValue(
                row.payloadJson(),
                new TypeReference<List<JobRecruitItem>>() {}
            );
            return new JobRecruitListResponse(row.total(), row.startPage(), row.display(), items);
        } catch (Exception e) {
            throw new IllegalStateException("채용 캐시 파싱에 실패했습니다.", e);
        }
    }

    private void saveRecruitCache(JobRecruitSearchCriteria criteria, JobRecruitListResponse response) {
        if (!work24Properties.getCache().isEnabled()) {
            return;
        }

        try {
            String payloadJson = objectMapper.writeValueAsString(response.wanted());
            JobRecruitCacheRow row = new JobRecruitCacheRow(
                response.total(),
                response.startPage(),
                response.display(),
                payloadJson,
                LocalDateTime.now()
            );
            JobRecruitCacheKey key = new JobRecruitCacheKey(
                buildQueryKey(criteria),
                criteria.region(),
                criteria.occupation(),
                criteria.startPage(),
                criteria.display()
            );
            jobRepository.upsertRecruitCache(row, key);
        } catch (Exception e) {
            log.warn("채용 캐시 저장에 실패했습니다.", e);
        }
    }

    private boolean isCacheFresh(LocalDateTime updatedAt) {
        long ttlMinutes = work24Properties.getCache().getTtlMinutes();
        if (ttlMinutes <= 0) return false;
        LocalDateTime now = LocalDateTime.now();
        Duration age = Duration.between(updatedAt, now);
        return !age.isNegative() && age.toMinutes() <= ttlMinutes;
    }

    private JobRecruitSearchCriteria normalizeCriteria(
        String region,
        String occupation,
        Integer startPage,
        Integer display
    ) {
        return new JobRecruitSearchCriteria(
            trimToNull(region),
            trimToNull(occupation),
            normalizeStartPage(startPage, 1),
            normalizeDisplay(display, 10),
            "L"
        );
    }

    private int normalizeStartPage(Integer value, int fallback) {
        if (value == null || value <= 0) return fallback;
        return value;
    }

    private int normalizeDisplay(Integer value, int fallback) {
        if (value == null || value <= 0) return fallback;
        return Math.min(value, 100);
    }

    private String buildQueryKey(JobRecruitSearchCriteria criteria) {
        return "%s|%s|%d|%d".formatted(
            nullToDash(criteria.region()),
            nullToDash(criteria.occupation()),
            criteria.startPage(),
            criteria.display()
        );
    }

    private static String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isBlank() ? null : trimmed;
    }

    private static String nullToDash(String value) {
        return value == null ? "-" : value;
    }

    public enum CachePolicy {
        // 왜: 화면/운영 상황에 따라 캐시 우선, 실시간 강제, 캐시만 사용을 구분합니다.
        PREFER_CACHE,
        FORCE_LIVE,
        CACHE_ONLY;

        public static CachePolicy from(String raw) {
            if (raw == null || raw.isBlank()) return PREFER_CACHE;
            String value = raw.trim().toUpperCase();
            return switch (value) {
                case "FORCE_LIVE" -> FORCE_LIVE;
                case "CACHE_ONLY" -> CACHE_ONLY;
                default -> PREFER_CACHE;
            };
        }
    }

}
