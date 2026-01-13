package kr.polytech.lms.statistics.ai;

import java.util.Map;

public record StatisticsAiQueryRequest(
        String prompt,
        Map<String, Object> context
) {
}

