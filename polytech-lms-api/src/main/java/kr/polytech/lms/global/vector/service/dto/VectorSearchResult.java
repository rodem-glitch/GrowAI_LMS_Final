package kr.polytech.lms.global.vector.service.dto;

import java.util.Map;

public record VectorSearchResult(
    String text,
    Map<String, Object> metadata,
    double score
) {}

