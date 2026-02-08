package kr.polytech.lms.statistics.kosis.service;

import kr.polytech.lms.statistics.kosis.client.KosisClient;
import kr.polytech.lms.statistics.kosis.client.dto.KosisPopulationRow;
import kr.polytech.lms.statistics.kosis.persistence.KosisPopulation;
import kr.polytech.lms.statistics.kosis.persistence.KosisPopulationId;
import kr.polytech.lms.statistics.kosis.persistence.KosisPopulationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.time.Year;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class KosisStatisticsService {
    // 왜: 컨트롤러는 요청/응답에 집중하고, 비즈니스 규칙(기본값/검증)은 서비스로 분리합니다.

    private static final Logger log = LoggerFactory.getLogger(KosisStatisticsService.class);

    private final KosisClient kosisClient;
    private final KosisPopulationRepository kosisPopulationRepository;

    public KosisStatisticsService(
            KosisClient kosisClient,
            KosisPopulationRepository kosisPopulationRepository
    ) {
        this.kosisClient = kosisClient;
        this.kosisPopulationRepository = kosisPopulationRepository;
    }

    public List<KosisPopulationRow> getPopulation(String year, String ageType, String gender) throws IOException {
        return getPopulation(year, ageType, gender, null);
    }

    public List<KosisPopulationRow> getPopulation(String year, String ageType, String gender, String admCd) throws IOException {
        String resolvedYear = resolveYear(year);
        String resolvedAgeType = resolveAgeType(ageType);
        String resolvedGender = resolveGender(gender);
        String resolvedAdmCd = resolveAdmCd(admCd);

        List<KosisPopulationRow> cached = findPopulationFromCache(resolvedYear, resolvedAgeType, resolvedGender, resolvedAdmCd);
        if (!cached.isEmpty()) {
            return cached;
        }

        List<KosisPopulationRow> fetched = kosisClient.fetchPopulation(resolvedYear, resolvedAgeType, resolvedGender, resolvedAdmCd);
        savePopulationToCache(resolvedYear, resolvedAgeType, resolvedGender, fetched);
        return fetched;
    }

    @Scheduled(cron = "0 0 3 * * *", zone = "Asia/Seoul") // 매일 오전 3시 (한국 시간)
    public void refreshKosisPopulationCache() {
        log.info("KOSIS 인구 통계 캐시 갱신 시작 (스케줄러)");
        try {
            // 기본 파라미터로 데이터를 가져와 캐시를 갱신합니다.
            // 실제 구현 시에는 갱신이 필요한 다양한 연도, 연령대, 성별, 행정구역 코드를 순회해야 합니다.
            String year = String.valueOf(Year.now().getValue()); // 현재 연도
            String ageType = resolveAgeType(null); // 기본 연령대 (20대=32)
            String gender = resolveGender(null);   // 기본 성별 (전체=0)
            String admCd = resolveAdmCd(null);     // 전체 행정구역 (null)

            List<KosisPopulationRow> fetched = kosisClient.fetchPopulation(year, ageType, gender, admCd);
            if (!fetched.isEmpty()) {
                // 기존 데이터 삭제 후 새로 저장 (간단한 갱신 방식)
                kosisPopulationRepository.deleteAll();
                savePopulationToCache(year, ageType, gender, fetched);
                log.info("KOSIS 인구 통계 캐시 갱신 완료: {}건", fetched.size());
            } else {
                log.warn("KOSIS 인구 통계 캐시 갱신 실패: 조회된 데이터 없음");
            }
        } catch (Exception e) {
            log.error("KOSIS 인구 통계 캐시 갱신 중 오류 발생", e);
        }
    }

    private List<KosisPopulationRow> findPopulationFromCache(String year, String ageType, String gender, String admCd) {
        // 왜: 레거시와 동일하게 "DB에 있으면 DB 우선"으로 외부 API 호출을 줄입니다.
        List<KosisPopulation> entities = (StringUtils.hasText(admCd))
                ? kosisPopulationRepository.findByIdYearAndIdAgeTypeAndIdGenderAndIdAdmCd(year, ageType, gender, admCd)
                : kosisPopulationRepository.findByIdYearAndIdAgeTypeAndIdGenderOrderByIdAdmCdAsc(year, ageType, gender);
        return entities.stream().map(this::toRow).toList();
    }

    private void savePopulationToCache(String year, String ageType, String gender, Collection<KosisPopulationRow> rows) {
        // 왜: 결과가 비어있을 때는 저장 의미가 없고, 오히려 "빈 캐시"가 되어 다음에 다시 조회가 막힐 수 있습니다.
        if (rows == null || rows.isEmpty()) {
            return;
        }

        List<KosisPopulation> entities = rows.stream()
                .map(row -> toEntity(year, ageType, gender, row))
                .collect(Collectors.toList()); // Use Collectors.toList() for mutable list

        kosisPopulationRepository.saveAll(entities);
    }

    private KosisPopulation toEntity(String year, String ageType, String gender, KosisPopulationRow row) {
        // 왜: 외부 응답의 필드가 비어있으면 캐시 키가 깨지므로 저장 전에 방어합니다.
        String admCd = (row.getAdmCd() == null) ? "" : row.getAdmCd().trim();
        String admNm = (row.getAdmNm() == null) ? "" : row.getAdmNm().trim();
        long population = row.getPopulation();

        if (!StringUtils.hasText(admCd) || !StringUtils.hasText(admNm)) {
            throw new IllegalStateException("KOSIS 응답에 행정구역 코드/명이 비어 있습니다. 캐시 저장이 불가능합니다.");
        }

        return new KosisPopulation(new KosisPopulationId(year, ageType, gender, admCd), admNm, population);
    }

    private KosisPopulationRow toRow(KosisPopulation entity) {
        KosisPopulationRow row = new KosisPopulationRow();
        row.setAdmCd(entity.getId().getAdmCd());
        row.setAdmNm(entity.getAdmNm());
        row.setPopulation(entity.getPopulation());
        return row;
    }

    private String resolveYear(String year) {
        // 왜: 기본 화면 기본값을 2024로 고정해 혼선을 줄입니다.
        if (!StringUtils.hasText(year)) {
            return String.valueOf(Year.now().getValue()); // 현재 연도로 변경
        }
        return year.trim();
    }

    private String resolveAgeType(String ageType) {
        // 왜: 레거시 기본값(20대=32)을 그대로 사용해 화면 테스트를 쉽게 합니다.
        if (!StringUtils.hasText(ageType)) {
            return "32";
        }
        return ageType.trim();
    }

    private String resolveGender(String gender) {
        // 왜: 레거시 기본값(전체=0)을 그대로 사용해 화면 테스트를 쉽게 합니다.
        if (!StringUtils.hasText(gender)) {
            return "0";
        }
        return gender.trim();
    }

    private String resolveAdmCd(String admCd) {
        // 왜: 행정구역을 고정하면 응답이 1행만 내려와서 "연령대별 분포" 계산이 훨씬 빨라집니다.
        if (!StringUtils.hasText(admCd)) {
            return null;
        }
        return admCd.trim();
    }
}