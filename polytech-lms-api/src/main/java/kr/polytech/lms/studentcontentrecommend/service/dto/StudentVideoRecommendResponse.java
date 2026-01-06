package kr.polytech.lms.studentcontentrecommend.service.dto;

import java.util.Map;

public record StudentVideoRecommendResponse(
    Long lessonId,
    Long recoContentId,
    String title,
    String categoryNm,
    double score,
    Map<String, Object> metadata
) {}

