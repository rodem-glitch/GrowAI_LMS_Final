package kr.polytech.lms.statistics.dashboard.service;

import kr.polytech.lms.statistics.kosis.client.dto.KosisPopulationRow;
import kr.polytech.lms.statistics.kosis.service.KosisStatisticsService;
import kr.polytech.lms.statistics.student.excel.CampusStudentPopulationExcelService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Year;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class PopulationComparisonService {
    // 왜: 인구 탭은 "지역(행정구역) 인구 분포"와 "캠퍼스 학생(재학생) 분포"를 같은 연령대 축으로 비교하는 화면입니다.
    // - 지역 인구는 KOSIS(SGIS) API로,
    // - 캠퍼스 학생은 엑셀 기반으로 계산합니다. (내부 DB와 무관하게 동작해야 한다는 요구사항 반영)

    private static final List<AgeBand> AGE_BANDS = List.of(
            new AgeBand("10대", List.of("31")),
            new AgeBand("20대", List.of("32")),
            new AgeBand("30대", List.of("33")),
            new AgeBand("40대", List.of("34")),
            new AgeBand("50대", List.of("35")),
            // 왜: SGIS의 age_type=40은 70대 이상(70+) 집계이므로, 60대(36) + 70대 이상(40)으로 60대 이상을 구성합니다.
            new AgeBand("60대 이상", List.of("36", "40"))
    );

    private final KosisStatisticsService kosisStatisticsService;
    private final CampusStudentPopulationExcelService campusStudentPopulationExcelService;

    private static final Logger log = LoggerFactory.getLogger(PopulationComparisonService.class);

    public PopulationComparisonService(
            KosisStatisticsService kosisStatisticsService,
            CampusStudentPopulationExcelService campusStudentPopulationExcelService
    ) {
        this.kosisStatisticsService = kosisStatisticsService;
        this.campusStudentPopulationExcelService = campusStudentPopulationExcelService;
    }

    public PopulationComparisonResponse compare(
            String campus,
            String admCd,
            Integer populationYear
    ) {
        if (!StringUtils.hasText(campus)) {
            throw new IllegalArgumentException("campus는 필수입니다.");
        }

        String resolvedCampus = campus.trim();
        String resolvedAdmCd = resolveAdmCd(admCd);
        int desiredPopulationYear = resolvePopulationYear(populationYear);

        int usedPopulationYear = resolveAvailablePopulationYear(desiredPopulationYear, resolvedAdmCd);

        Map<String, GenderCount> regionCounts = loadRegionPopulationGenderCounts(resolvedAdmCd, usedPopulationYear);
        long regionTotal = regionCounts.values().stream().mapToLong(GenderCount::total).sum();

        Map<String, GenderCount> campusCounts = loadCampusStudentAgeGenderCounts(resolvedCampus, usedPopulationYear);
        long campusTotal = campusCounts.values().stream().mapToLong(GenderCount::total).sum();

        List<AgeRow> rows = new ArrayList<>();
        for (AgeBand band : AGE_BANDS) {
            GenderCount region = regionCounts.getOrDefault(band.label(), GenderCount.empty());
            GenderCount campusCount = campusCounts.getOrDefault(band.label(), GenderCount.empty());

            double regionRatio = toPercent(region.total(), regionTotal);
            double campusRatio = toPercent(campusCount.total(), campusTotal);
            double gap = campusRatio - regionRatio;

            double regionMaleRatio = toPercent(region.male(), region.total());
            double campusMaleRatio = toPercent(campusCount.male(), campusCount.total());
            double maleGap = campusMaleRatio - regionMaleRatio;

            rows.add(new AgeRow(
                    band.label(),
                    region.total(),
                    regionRatio,
                    campusCount.total(),
                    campusRatio,
                    gap,
                    regionMaleRatio,
                    campusMaleRatio,
                    maleGap
            ));
        }

        return new PopulationComparisonResponse(
                resolvedCampus,
                resolvedAdmCd,
                usedPopulationYear,
                campusTotal,
                regionTotal,
                rows
        );
    }

    private Map<String, GenderCount> loadRegionPopulationGenderCounts(String admCd, int year) {
        Map<String, GenderCount> result = new LinkedHashMap<>();
        for (AgeBand band : AGE_BANDS) {
            long maleSum = 0L;
            long femaleSum = 0L;
            for (String ageType : band.ageTypes()) {
                maleSum += safeSumPopulation(year, ageType, "1", admCd);
                femaleSum += safeSumPopulation(year, ageType, "2", admCd);
            }
            result.put(band.label(), new GenderCount(maleSum, femaleSum));
        }
        return result;
    }

    private Map<String, GenderCount> loadCampusStudentAgeGenderCounts(String campus, int baseYear) {
        Map<String, GenderCount> empty = emptyGenderCounts();

        if (campusStudentPopulationExcelService.isEnabled()) {
            Map<String, CampusStudentPopulationExcelService.GenderCount> rows =
                    campusStudentPopulationExcelService.countByAgeBandAndGender(campus, null, null, baseYear);
            Map<String, GenderCount> result = new LinkedHashMap<>();
            for (AgeBand band : AGE_BANDS) {
                CampusStudentPopulationExcelService.GenderCount c = rows.getOrDefault(band.label(), CampusStudentPopulationExcelService.GenderCount.empty());
                result.put(band.label(), new GenderCount(c.male(), c.female()));
            }
            return result;
        }

        // 왜: 현재 요구사항은 "내부 DB와 무관"이므로, 엑셀 파일이 없으면 0으로 표시합니다(오류 대신 안전한 기본값).
        return empty;
    }

    private int resolvePopulationYear(Integer populationYear) {
        if (populationYear != null) {
            return populationYear;
        }
        // 왜: 기본 화면 기본값을 2024로 고정해 혼선을 줄입니다.
        return 2024;
    }

    private int resolveAvailablePopulationYear(int desiredYear, String admCd) {
        // 왜: KOSIS 인구 통계는 최신 연도가 바로 제공되지 않을 수 있어, 사용 가능한 연도를 자동 보정합니다.
        // - 예: 2024가 N/A면 2023으로 내려가서 조회
        for (int y = desiredYear; y >= desiredYear - 5; y--) {
            long sample = safeSumPopulation(y, "32", "0", admCd);
            if (sample > 0) {
                return y;
            }
        }
        return desiredYear;
    }

    private String resolveAdmCd(String admCd) {
        if (!StringUtils.hasText(admCd) || "전체".equals(admCd)) {
            return "11";
        }
        return admCd.trim();
    }

    private double toPercent(long part, long total) {
        if (total <= 0) {
            return 0.0;
        }
        return (part * 100.0) / total;
    }

    private long sumPopulation(List<KosisPopulationRow> rows) {
        if (rows == null || rows.isEmpty()) {
            return 0L;
        }
        return rows.stream().mapToLong(KosisPopulationRow::getPopulation).sum();
    }

    private long safeSumPopulation(int year, String ageType, String gender, String admCd) {
        // 왜: 외부 API(KOSIS)는 키/토큰/장애 등으로 실패할 수 있습니다.
        //     화면 전체가 500으로 깨지지 않도록, 실패는 0으로 처리하고 나머지(캠퍼스 학생 분포)는 계속 보여줍니다.
        try {
            return sumPopulation(kosisStatisticsService.getPopulation(String.valueOf(year), ageType, gender, admCd));
        } catch (Exception e) {
            log.warn("KOSIS 인구 조회 실패(폴백=0): year={}, ageType={}, gender={}, admCd={}", year, ageType, gender, admCd, e);
            return 0L;
        }
    }

    private Map<String, GenderCount> emptyGenderCounts() {
        Map<String, GenderCount> empty = new LinkedHashMap<>();
        for (AgeBand band : AGE_BANDS) {
            empty.put(band.label(), GenderCount.empty());
        }
        return empty;
    }

    private record AgeBand(String label, List<String> ageTypes) {
    }

    public record PopulationComparisonResponse(
            String campus,
            String admCd,
            int populationYear,
            long campusStudentSampleSize,
            long regionPopulationTotal,
            List<AgeRow> rows
    ) {
    }

    public record AgeRow(
            String ageBand,
            long regionCount,
            double regionRatio,
            long campusCount,
            double campusRatio,
            double gap,
            double regionMaleRatio,
            double campusMaleRatio,
            double maleGap
    ) {
    }

    private record GenderCount(long male, long female) {
        static GenderCount empty() {
            return new GenderCount(0L, 0L);
        }

        long total() {
            return male + female;
        }
    }
}
