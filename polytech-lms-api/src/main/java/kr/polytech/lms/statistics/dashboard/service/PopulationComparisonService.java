package kr.polytech.lms.statistics.dashboard.service;

import kr.polytech.lms.statistics.kosis.client.dto.KosisPopulationRow;
import kr.polytech.lms.statistics.kosis.service.KosisStatisticsService;
import kr.polytech.lms.statistics.student.excel.CampusStudentPopulationExcelService;
import kr.polytech.lms.statistics.student.persistence.StudentStatisticsJdbcRepository;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.time.Year;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class PopulationComparisonService {
    // 왜: 인구 탭은 "지역(행정구역) 인구 분포"와 "캠퍼스 학생(재학생) 분포"를 같은 연령대 축으로 비교하는 화면입니다.
    // - 지역 인구는 KOSIS(SGIS) API로,
    // - 캠퍼스 학생은 (1) 엑셀 기반 또는 (2) 내부 DB 기반으로 계산합니다.

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
    private final StudentStatisticsJdbcRepository studentStatisticsJdbcRepository;

    public PopulationComparisonService(
            KosisStatisticsService kosisStatisticsService,
            CampusStudentPopulationExcelService campusStudentPopulationExcelService,
            StudentStatisticsJdbcRepository studentStatisticsJdbcRepository
    ) {
        this.kosisStatisticsService = kosisStatisticsService;
        this.campusStudentPopulationExcelService = campusStudentPopulationExcelService;
        this.studentStatisticsJdbcRepository = studentStatisticsJdbcRepository;
    }

    public PopulationComparisonResponse compare(
            String campus,
            String year,
            String term,
            String admCd,
            Integer populationYear
    ) throws IOException {
        if (!StringUtils.hasText(campus)) {
            throw new IllegalArgumentException("campus는 필수입니다.");
        }

        String resolvedCampus = campus.trim();
        ResolvedTerm resolvedTerm = resolveYearTerm(year, term);
        String resolvedAdmCd = resolveAdmCd(admCd);
        int desiredPopulationYear = resolvePopulationYear(populationYear);
        int usedPopulationYear = resolveAvailablePopulationYear(desiredPopulationYear, resolvedAdmCd);

        Map<String, GenderCount> regionCounts = loadRegionPopulationGenderCounts(resolvedAdmCd, usedPopulationYear);
        long regionTotal = regionCounts.values().stream().mapToLong(GenderCount::total).sum();

        Map<String, GenderCount> campusCounts = loadCampusStudentAgeGenderCounts(resolvedCampus, resolvedTerm, usedPopulationYear);
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
                resolvedTerm.year(),
                resolvedTerm.term(),
                resolvedAdmCd,
                usedPopulationYear,
                campusTotal,
                regionTotal,
                rows
        );
    }

    private Map<String, GenderCount> loadRegionPopulationGenderCounts(String admCd, int year) throws IOException {
        Map<String, GenderCount> result = new LinkedHashMap<>();
        for (AgeBand band : AGE_BANDS) {
            long maleSum = 0L;
            long femaleSum = 0L;
            for (String ageType : band.ageTypes()) {
                maleSum += sumPopulation(kosisStatisticsService.getPopulation(String.valueOf(year), ageType, "1", admCd));
                femaleSum += sumPopulation(kosisStatisticsService.getPopulation(String.valueOf(year), ageType, "2", admCd));
            }
            result.put(band.label(), new GenderCount(maleSum, femaleSum));
        }
        return result;
    }

    private Map<String, GenderCount> loadCampusStudentAgeGenderCounts(String campus, ResolvedTerm term, int baseYear) {
        if (campusStudentPopulationExcelService.isEnabled()) {
            Map<String, CampusStudentPopulationExcelService.GenderCount> rows =
                    campusStudentPopulationExcelService.countByAgeBandAndGender(campus, term.year(), term.term(), baseYear);
            Map<String, GenderCount> result = new LinkedHashMap<>();
            for (AgeBand band : AGE_BANDS) {
                CampusStudentPopulationExcelService.GenderCount c = rows.getOrDefault(band.label(), CampusStudentPopulationExcelService.GenderCount.empty());
                result.put(band.label(), new GenderCount(c.male(), c.female()));
            }
            return result;
        }

        // 왜: 엑셀 파일이 없으면(또는 로컬에서 아직 준비되지 않으면) DB 기반 계산으로라도 화면을 확인할 수 있게 합니다.
        List<StudentStatisticsJdbcRepository.AgeBandGenderCount> rows =
                studentStatisticsJdbcRepository.countEnrolledStudentsByAgeBandAndGender(term.year(), term.term(), campus, baseYear);

        Map<String, GenderCount> result = new LinkedHashMap<>();
        for (AgeBand band : AGE_BANDS) {
            result.put(band.label(), GenderCount.empty());
        }

        for (StudentStatisticsJdbcRepository.AgeBandGenderCount row : rows) {
            if (!result.containsKey(row.ageBand())) {
                continue;
            }

            GenderCount existing = result.get(row.ageBand());
            if ("1".equals(row.gender())) {
                result.put(row.ageBand(), new GenderCount(existing.male() + row.studentCount(), existing.female()));
                continue;
            }
            if ("2".equals(row.gender())) {
                result.put(row.ageBand(), new GenderCount(existing.male(), existing.female() + row.studentCount()));
            }
        }

        return result;
    }

    private ResolvedTerm resolveYearTerm(String year, String term) {
        if (StringUtils.hasText(year) && StringUtils.hasText(term)) {
            return new ResolvedTerm(year.trim(), term.trim());
        }

        List<StudentStatisticsJdbcRepository.YearTerm> recent = studentStatisticsJdbcRepository.findRecentYearTerms(1);
        if (!recent.isEmpty()) {
            StudentStatisticsJdbcRepository.YearTerm first = recent.get(0);
            return new ResolvedTerm(first.year(), first.term());
        }

        throw new IllegalStateException("재학생 기준 학기를 찾지 못했습니다. LM_POLY_STUDENT 데이터가 있는지 확인해 주세요.");
    }

    private int resolvePopulationYear(Integer populationYear) {
        if (populationYear != null) {
            return populationYear;
        }
        // 왜: KOSIS 인구 통계도 당해 연도는 미제공일 수 있어, 기본값을 전년도(-1)로 둡니다.
        return Year.now().getValue() - 1;
    }

    private int resolveAvailablePopulationYear(int desiredYear, String admCd) throws IOException {
        // 왜: KOSIS 인구 통계는 최신 연도가 바로 제공되지 않을 수 있어, 사용 가능한 연도를 자동 보정합니다.
        // - 예: 2024가 N/A면 2023으로 내려가서 조회
        for (int y = desiredYear; y >= desiredYear - 5; y--) {
            long sample = sumPopulation(kosisStatisticsService.getPopulation(String.valueOf(y), "32", "0", admCd));
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

    private record AgeBand(String label, List<String> ageTypes) {
    }

    private record ResolvedTerm(String year, String term) {
    }

    public record PopulationComparisonResponse(
            String campus,
            String year,
            String term,
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
