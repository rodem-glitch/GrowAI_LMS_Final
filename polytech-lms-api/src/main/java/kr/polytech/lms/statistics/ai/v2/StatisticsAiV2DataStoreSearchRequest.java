package kr.polytech.lms.statistics.ai.v2;

import java.util.Map;

public record StatisticsAiV2DataStoreSearchRequest(
        String prompt,
        Map<String, Object> context
) {
}

