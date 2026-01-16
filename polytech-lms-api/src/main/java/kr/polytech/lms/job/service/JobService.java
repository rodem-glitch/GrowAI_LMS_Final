package kr.polytech.lms.job.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.job.client.JobKoreaClient;
import kr.polytech.lms.job.client.Work24Client;
import kr.polytech.lms.job.client.Work24CodeClient;
import kr.polytech.lms.job.config.JobKoreaProperties;
import kr.polytech.lms.job.config.Work24Properties;
import kr.polytech.lms.job.repository.JobRepository;
import kr.polytech.lms.job.repository.JobRepository.JobOccupationCodeRow;
import kr.polytech.lms.job.repository.JobRepository.JobRecruitCacheKey;
import kr.polytech.lms.job.repository.JobRepository.JobRecruitCacheRow;
import kr.polytech.lms.job.repository.JobRepository.JobRegionCodeRow;
import kr.polytech.lms.job.repository.JobRepository.OccupationCodeInsertRow;
import kr.polytech.lms.job.repository.JobRepository.RegionCodeInsertRow;
import kr.polytech.lms.job.service.dto.JobOccupationCodeResponse;
import kr.polytech.lms.job.service.dto.JobRecruitItem;
import kr.polytech.lms.job.service.dto.JobRecruitListResponse;
import kr.polytech.lms.job.service.dto.JobRecruitSearchCriteria;
import kr.polytech.lms.job.service.dto.JobRegionCodeResponse;
import kr.polytech.lms.job.service.dto.JobCodeSyncResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

@Service
public class JobService {
    // 왜: 채용 API는 Work24 실시간 조회 + DB 캐시를 동시에 지원해야 해서 서비스에서 정책을 통합합니다.

    private static final Logger log = LoggerFactory.getLogger(JobService.class);

    private final JobRepository jobRepository;
    private final Work24Client work24Client;
    private final Work24CodeClient work24CodeClient;
    private final Work24Properties work24Properties;
    private final JobKoreaClient jobKoreaClient;
    private final JobKoreaProperties jobKoreaProperties;
    private final ObjectMapper objectMapper;

    public JobService(
        JobRepository jobRepository,
        Work24Client work24Client,
        Work24CodeClient work24CodeClient,
        Work24Properties work24Properties,
        JobKoreaClient jobKoreaClient,
        JobKoreaProperties jobKoreaProperties,
        ObjectMapper objectMapper
    ) {
        this.jobRepository = Objects.requireNonNull(jobRepository);
        this.work24Client = Objects.requireNonNull(work24Client);
        this.work24CodeClient = Objects.requireNonNull(work24CodeClient);
        this.work24Properties = Objects.requireNonNull(work24Properties);
        this.jobKoreaClient = Objects.requireNonNull(jobKoreaClient);
        this.jobKoreaProperties = Objects.requireNonNull(jobKoreaProperties);
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

    public List<JobOccupationCodeResponse> getOccupationCodes(String depthType, String depth1, String depth2) {
        List<JobOccupationCodeRow> rows = jobRepository.findOccupationCodes(depthType, depth1, depth2);
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

    public JobCodeSyncResponse refreshWork24Codes(boolean refreshRegion, boolean refreshOccupation) {
        int regionCount = 0;
        int occupationCount = 0;

        if (!refreshRegion && !refreshOccupation) {
            throw new IllegalArgumentException("refresh 대상이 비어 있습니다. target=ALL/REGION/OCCUPATION 중 선택해 주세요.");
        }

        if (refreshRegion) {
            // 왜: 현재 화면에서는 직종 코드가 우선이라, 지역 코드는 추후 소스(코드표)가 정해지면 연결합니다.
            //      (공통코드 OpenAPI 권한이 없는 환경에서도 동작해야 하므로 지금은 스킵합니다.)
            log.warn("Work24 지역 코드는 현재 스킵합니다(target=REGION).");
        }

        if (refreshOccupation) {
            List<OccupationCodeInsertRow> rows = loadOccupationCodesFromCsv();
            jobRepository.replaceOccupationCodes(rows);
            occupationCount = rows.size();
        }

        return new JobCodeSyncResponse(regionCount, occupationCount);
    }

    private List<OccupationCodeInsertRow> loadOccupationCodesFromCsv() {
        Path csvPath = resolveOccupationCsvPath();
        List<OccupationCodeInsertRow> rows = new ArrayList<>();
        Set<String> seenCodes = new HashSet<>();

        String currentDepth1Name = "";
        String currentDepth1Code = "";
        String currentDepth2Name = "";
        String currentDepth2Code = "";

        Charset charset = Charset.forName("MS949");
        try (BufferedReader reader = Files.newBufferedReader(csvPath, charset)) {
            String header = reader.readLine();
            if (header == null || header.isBlank()) {
                throw new IllegalStateException("직종코드 CSV 헤더가 비어 있습니다.");
            }

            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;

                List<String> cols = parseCsvLine(line);
                if (cols.size() < 4) continue;

                String rawId = cols.get(0).trim();
                String depth1 = safe(cols.get(1));
                String depth2 = safe(cols.get(2));
                String depth3 = safe(cols.get(3));

                if (!depth1.isEmpty()) {
                    currentDepth1Name = depth1;
                    currentDepth1Code = normalizeDepth1Code(rawId);
                    currentDepth2Name = "";
                    currentDepth2Code = "";

                    addOccupationRow(rows, seenCodes,
                        currentDepth1Code,
                        null,
                        currentDepth1Name,
                        "",
                        ""
                    );
                    continue;
                }

                if (!depth2.isEmpty()) {
                    if (currentDepth1Code.isEmpty()) {
                        // 왜: CSV 구조상 대분류가 먼저 와야 하지만, 예외 데이터가 있으면 건너뜁니다.
                        log.warn("직종코드 CSV: 대분류 없이 중분류가 등장했습니다. code={}", rawId);
                        continue;
                    }
                    currentDepth2Name = depth2;
                    currentDepth2Code = normalizeDepth2Code(rawId);

                    addOccupationRow(rows, seenCodes,
                        currentDepth2Code,
                        currentDepth1Code,
                        currentDepth1Name,
                        currentDepth2Name,
                        ""
                    );
                    continue;
                }

                if (!depth3.isEmpty()) {
                    if (currentDepth2Code.isEmpty()) {
                        // 왜: CSV 구조상 중분류가 먼저 와야 하지만, 예외 데이터가 있으면 건너뜁니다.
                        log.warn("직종코드 CSV: 중분류 없이 소분류가 등장했습니다. code={}", rawId);
                        continue;
                    }
                    String code = normalizeDepth3Code(rawId);
                    addOccupationRow(rows, seenCodes,
                        code,
                        currentDepth2Code,
                        currentDepth1Name,
                        currentDepth2Name,
                        depth3
                    );
                }
            }
        } catch (Exception e) {
            throw new IllegalStateException("직종코드 CSV 로딩에 실패했습니다: " + e.getMessage(), e);
        }

        if (rows.isEmpty()) {
            throw new IllegalStateException("직종코드 CSV에서 적재할 데이터가 없습니다.");
        }

        return rows;
    }

    private Path resolveOccupationCsvPath() {
        String raw = work24Properties.getOccupationCsvPath();
        if (raw == null || raw.isBlank()) {
            throw new IllegalStateException("work24.occupation-csv-path가 비어 있습니다.");
        }

        Path path = Paths.get(raw.trim());
        if (path.isAbsolute()) return path;

        // 왜: bootRun 실행 디렉터리 기준 상대경로를 허용하면 로컬에서 바로 테스트가 가능합니다.
        String baseDir = System.getProperty("user.dir", ".");
        return Paths.get(baseDir).resolve(path).normalize();
    }

    private void addOccupationRow(
        List<OccupationCodeInsertRow> rows,
        Set<String> seenCodes,
        String code,
        String parentCode,
        String depth1,
        String depth2,
        String depth3
    ) {
        if (code == null || code.isBlank()) return;
        if (!seenCodes.add(code)) return;
        rows.add(new OccupationCodeInsertRow(
            code.trim(),
            parentCode == null ? null : parentCode.trim(),
            safe(depth1),
            safe(depth2),
            safe(depth3)
        ));
    }

    private static String safe(String value) {
        if (value == null) return "";
        String trimmed = value.trim();
        return trimmed.isBlank() ? "" : trimmed;
    }

    private static String normalizeDepth1Code(String raw) {
        if (raw == null) return "";
        String v = raw.trim();
        if (v.isBlank()) return "";
        if (v.matches("^\\d+$")) {
            return v.length() == 1 ? ("0" + v) : v;
        }
        return v;
    }

    private static String normalizeDepth2Code(String raw) {
        if (raw == null) return "";
        String v = raw.trim();
        if (v.isBlank()) return "";
        if (v.matches("^\\d{2}$")) return "0" + v;
        return v;
    }

    private static String normalizeDepth3Code(String raw) {
        if (raw == null) return "";
        String v = raw.trim();
        if (v.isBlank()) return "";
        if (v.matches("^\\d{5}$")) return "0" + v;
        return v;
    }

    private static List<String> parseCsvLine(String line) {
        // 왜: CSV 안에 쉼표(,)가 들어간 항목이 있어 단순 split(",")로는 파싱이 깨집니다.
        List<String> out = new ArrayList<>();
        StringBuilder sb = new StringBuilder();
        boolean inQuotes = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    sb.append('"');
                    i++;
                    continue;
                }
                inQuotes = !inQuotes;
                continue;
            }
            if (c == ',' && !inQuotes) {
                out.add(sb.toString());
                sb.setLength(0);
                continue;
            }
            sb.append(c);
        }
        out.add(sb.toString());
        return out;
    }

    public JobRecruitListResponse getRecruitments(
        String region,
        String occupation,
        Integer startPage,
        Integer display,
        CachePolicy cachePolicy
    ) {
        return getRecruitments(region, occupation, startPage, display, Provider.WORK24, cachePolicy);
    }

    public JobRecruitListResponse getRecruitments(
        String region,
        String occupation,
        Integer startPage,
        Integer display,
        Provider provider,
        CachePolicy cachePolicy
    ) {
        Provider safeProvider = provider == null ? Provider.WORK24 : provider;
        JobRecruitSearchCriteria criteria = normalizeCriteria(region, occupation, startPage, display);
        CachePolicy safePolicy = cachePolicy == null ? CachePolicy.PREFER_CACHE : cachePolicy;

        if (safeProvider == Provider.ALL) {
            return mergeRecruitments(criteria, safePolicy);
        }

        if (safePolicy != CachePolicy.FORCE_LIVE) {
            Optional<JobRecruitListResponse> cached = findCachedRecruitments(criteria, safeProvider, safePolicy);
            if (cached.isPresent()) {
                return cached.get();
            }
        }

        JobRecruitListResponse live = fetchFromProvider(criteria, safeProvider);
        saveRecruitCache(criteria, safeProvider, live);
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
        saveRecruitCache(criteria, Provider.WORK24, live);
        return live;
    }

    @Scheduled(cron = "0 0 6 * * *", zone = "Asia/Seoul")
    public void refreshCachedRecruitmentsAtMorning() {
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
        Provider provider = Provider.from(key.provider());
        if (!isCacheEnabled(provider)) {
            return;
        }
        JobRecruitListResponse live = fetchFromProvider(criteria, provider);
        saveRecruitCache(criteria, provider, live);
    }

    private Optional<JobRecruitListResponse> findCachedRecruitments(
        JobRecruitSearchCriteria criteria,
        Provider provider,
        CachePolicy cachePolicy
    ) {
        if (!isCacheEnabled(provider)) {
            return Optional.empty();
        }

        String queryKey = buildQueryKey(criteria, provider);
        Optional<JobRecruitCacheRow> cached = jobRepository.findRecruitCache(queryKey, provider.name());
        if (cached.isEmpty()) {
            if (cachePolicy == CachePolicy.CACHE_ONLY) {
                throw new IllegalStateException("캐시된 채용 정보가 없습니다.");
            }
            return Optional.empty();
        }

        JobRecruitCacheRow row = cached.get();
        if (!isCacheFresh(provider, row.updatedAt())) {
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

    private void saveRecruitCache(JobRecruitSearchCriteria criteria, Provider provider, JobRecruitListResponse response) {
        if (!isCacheEnabled(provider)) {
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
                buildQueryKey(criteria, provider),
                provider.name(),
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

    private boolean isCacheFresh(Provider provider, LocalDateTime updatedAt) {
        long ttlMinutes = resolveTtlMinutes(provider);
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

    private String buildQueryKey(JobRecruitSearchCriteria criteria, Provider provider) {
        return "%s|%s|%s|%d|%d".formatted(
            provider.name(),
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

    private JobRecruitListResponse mergeRecruitments(JobRecruitSearchCriteria criteria, CachePolicy cachePolicy) {
        JobRecruitListResponse work24 = getRecruitments(
            criteria.region(),
            criteria.occupation(),
            criteria.startPage(),
            criteria.display(),
            Provider.WORK24,
            cachePolicy
        );
        JobRecruitListResponse jobkorea = getRecruitments(
            criteria.region(),
            criteria.occupation(),
            criteria.startPage(),
            criteria.display(),
            Provider.JOBKOREA,
            cachePolicy
        );
        List<JobRecruitItem> merged = new java.util.ArrayList<>();
        if (work24.wanted() != null) merged.addAll(work24.wanted());
        if (jobkorea.wanted() != null) merged.addAll(jobkorea.wanted());
        int total = work24.total() + jobkorea.total();
        return new JobRecruitListResponse(total, criteria.startPage(), criteria.display(), merged);
    }

    private JobRecruitListResponse fetchFromProvider(JobRecruitSearchCriteria criteria, Provider provider) {
        return switch (provider) {
            case WORK24 -> work24Client.fetchRecruitList(criteria);
            case JOBKOREA -> jobKoreaClient.fetchRecruitList(criteria);
            case ALL -> throw new IllegalArgumentException("ALL은 개별 호출 없이 병합으로만 처리합니다.");
        };
    }

    private boolean isCacheEnabled(Provider provider) {
        return switch (provider) {
            case WORK24 -> work24Properties.getCache().isEnabled();
            case JOBKOREA -> jobKoreaProperties.getCache().isEnabled();
            case ALL -> false;
        };
    }

    private long resolveTtlMinutes(Provider provider) {
        return switch (provider) {
            case WORK24 -> work24Properties.getCache().getTtlMinutes();
            case JOBKOREA -> jobKoreaProperties.getCache().getTtlMinutes();
            case ALL -> 0L;
        };
    }

    private Integer parseRegionCode(String code) {
        if (code == null || code.isBlank()) return null;
        try {
            return Integer.parseInt(code.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public enum Provider {
        // 왜: Work24 단일/잡코리아 단일/통합 조회를 선택할 수 있게 합니다.
        WORK24,
        JOBKOREA,
        ALL;

        public static Provider from(String raw) {
            if (raw == null || raw.isBlank()) return WORK24;
            String value = raw.trim().toUpperCase();
            return switch (value) {
                case "JOBKOREA" -> JOBKOREA;
                case "ALL" -> ALL;
                default -> WORK24;
            };
        }
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
