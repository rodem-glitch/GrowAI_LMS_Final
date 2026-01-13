package kr.polytech.lms.statistics.dashboard.service;

import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import kr.polytech.lms.statistics.sgis.service.SgisCompanyCacheService;
import kr.polytech.lms.statistics.student.excel.CampusStudentQuotaExcelService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.time.Year;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class IndustryAnalysisService {
    // 왜: 화면(산업분포 분석)은
    //  1) 지역 산업 비율(종사자 수 기반, SGIS tot_worker)
    //  2) 캠퍼스 전공(학과) 재학생 비율
    //  3) 둘의 차이(GAP)
    // 를 같은 분류(첨단/고기술/… 7개)로 비교하는 것이 핵심입니다.

    private static final List<String> CATEGORY_ORDER = List.of(
            "첨단기술",
            "고기술",
            "중기술",
            "저기술",
            "창의 및 디지털",
            "ICT",
            "전문서비스"
    );

    private final MajorIndustryMappingService majorIndustryMappingService;
    private final SgisCompanyCacheService sgisCompanyCacheService;
    private final CampusStudentQuotaExcelService campusStudentQuotaExcelService;

    public IndustryAnalysisService(
            MajorIndustryMappingService majorIndustryMappingService,
            SgisCompanyCacheService sgisCompanyCacheService,
            CampusStudentQuotaExcelService campusStudentQuotaExcelService
    ) {
        this.majorIndustryMappingService = majorIndustryMappingService;
        this.sgisCompanyCacheService = sgisCompanyCacheService;
        this.campusStudentQuotaExcelService = campusStudentQuotaExcelService;
    }

    public IndustryAnalysisResponse analyze(
            String campus,
            String admCd,
            Integer statsYear
    ) throws IOException {
        String resolvedCampus = normalizeCampus(campus);
        String resolvedAdmCd = resolveAdmCd(admCd);

        int desiredStatsYear = resolveStatsYear(statsYear);
        int usedStatsYear = resolveAvailableStatsYear(desiredStatsYear, resolvedAdmCd);

        Map<String, Long> campusCategoryCounts = countCampusStudentsByCategory(resolvedCampus);
        long campusTotal = campusCategoryCounts.values().stream().mapToLong(Long::longValue).sum();

        Map<String, Long> regionCategoryCounts = countRegionCompaniesByCategory(usedStatsYear, resolvedAdmCd);
        long regionTotal = regionCategoryCounts.values().stream().mapToLong(Long::longValue).sum();

        List<CategoryRow> rows = new ArrayList<>();
        for (String category : CATEGORY_ORDER) {
            long regionCount = regionCategoryCounts.getOrDefault(category, 0L);
            long campusCount = campusCategoryCounts.getOrDefault(category, 0L);

            double regionRatio = toPercent(regionCount, regionTotal);
            double campusRatio = toPercent(campusCount, campusTotal);
            double gap = campusRatio - regionRatio;

            rows.add(new CategoryRow(category, regionCount, regionRatio, campusCount, campusRatio, gap));
        }

        return new IndustryAnalysisResponse(
                resolvedCampus,
                resolvedAdmCd,
                usedStatsYear,
                campusTotal,
                regionTotal,
                rows
        );
    }

    private Map<String, Long> countCampusStudentsByCategory(String campus) {
        Map<String, Long> categoryCounts = new LinkedHashMap<>();
        for (String category : CATEGORY_ORDER) {
            categoryCounts.put(category, 0L);
        }

        applyCampusCountsFromAdmissionQuotaExcel(campus, categoryCounts);

        return categoryCounts;
    }

    private void applyCampusCountsFromAdmissionQuotaExcel(String campus, Map<String, Long> categoryCounts) {
        // 왜: 사용자가 "현재 엑셀 데이터만으로 통계를 보고 싶다"는 요구가 있어,
        //     DB 재학생 대신 입시율관리.xlsx의 "정원"을 학생수 대체 지표로 사용합니다.
        List<CampusStudentQuotaExcelService.CampusDeptQuota> quotas = campusStudentQuotaExcelService.getCampusDeptQuotas();
        for (CampusStudentQuotaExcelService.CampusDeptQuota row : quotas) {
            if (StringUtils.hasText(campus) && !campus.equals(row.campus())) {
                continue;
            }

            majorIndustryMappingService
                    .findCategoryByCampusAndDept(row.campus(), row.dept())
                    .ifPresent(category -> categoryCounts.compute(
                            category,
                            (k, existing) -> (existing == null ? 0L : existing) + row.quota()
                    ));
        }
    }

    private Map<String, Long> countRegionCompaniesByCategory(int year, String admCd) throws IOException {
        Map<String, List<String>> classCodesByCategory = majorIndustryMappingService.getSgisClassCodesByCategory();

        Map<String, Long> categoryCounts = new LinkedHashMap<>();
        for (String category : CATEGORY_ORDER) {
            categoryCounts.put(category, 0L);
        }

        for (String category : CATEGORY_ORDER) {
            List<String> classCodes = classCodesByCategory.getOrDefault(category, List.of());
            long sum = 0L;
            for (String classCode : classCodes) {
                Long totWorker = sgisCompanyCacheService.getCompanyStats(String.valueOf(year), admCd, classCode).totWorker();
                if (totWorker != null) {
                    sum += totWorker;
                }
            }
            categoryCounts.put(category, sum);
        }

        return categoryCounts;
    }

    private int resolveAvailableStatsYear(int desiredYear, String admCd) throws IOException {
        // 왜: SGIS 사업체 통계는 "최신 연도"가 바로 제공되지 않는 경우가 있어, 사용 가능한 연도로 자동 보정합니다.
        // - 예: 2024가 N/A면 2023으로 내려가서 조회
        for (int y = desiredYear; y >= desiredYear - 5; y--) {
            Map<String, Long> counts = countRegionCompaniesByCategory(y, admCd);
            long total = counts.values().stream().mapToLong(Long::longValue).sum();
            if (total > 0) {
                return y;
            }
        }
        return desiredYear;
    }

    private int resolveStatsYear(Integer statsYear) {
        if (statsYear != null) {
            return statsYear;
        }
        // 왜: SGIS는 당해 연도(예: 2026)는 아직 미제공일 가능성이 높아서 기본값을 전년도(-1)로 둡니다.
        return Year.now().getValue() - 1;
    }

    private String normalizeCampus(String campus) {
        if (!StringUtils.hasText(campus) || "전체".equals(campus) || "전체 캠퍼스".equals(campus)) {
            return null;
        }
        return campus.trim();
    }

    private String resolveAdmCd(String admCd) {
        // 왜: 지역 선택이 없을 때는 "서울(11)"을 기본으로 두어, 화면을 바로 확인할 수 있게 합니다.
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

    public record IndustryAnalysisResponse(
            String campus,
            String admCd,
            int statsYear,
            long campusStudentTotal,
            long regionCompanyTotal,
            List<CategoryRow> rows
    ) {
    }

    public record CategoryRow(
            String category,
            long regionCount,
            double regionRatio,
            long campusCount,
            double campusRatio,
            double gap
    ) {
    }
}
