package kr.polytech.lms.statistics.ai;

import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;

import java.util.List;

public record StatisticsAiCatalogResponse(
        String version,
        List<QueryTypeSpec> queryTypes,
        List<String> supportedChartTypes,
        List<MajorIndustryMappingService.CampusGroup> campusGroups,
        List<AdmRegion> admRegions,
        List<Integer> recommendedYears
) {
    public record QueryTypeSpec(
            String code,
            String name,
            List<String> requiredFields,
            List<String> optionalFields
    ) {
    }

    public record AdmRegion(
            String admCd,
            String name
    ) {
    }
}

