package kr.polytech.lms.studentcontentrecommend.service.dto;

import java.util.Map;

public record StudentVideoRecommendResponse(
    String lessonId,
    Long recoContentId,
    String title,
    String categoryNm,
    double score,
    Boolean enrolled,
    Boolean watched,
    Boolean completed,
    String lastDate,
    Map<String, Object> metadata
) {}
