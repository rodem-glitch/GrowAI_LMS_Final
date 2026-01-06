package kr.polytech.lms.tutorcontentrecommend.service.dto;

import java.util.Map;

public record TutorContentRecommendResponse(
    Long lessonId,
    Long recoContentId,
    String title,
    String categoryNm,
    double score,
    Map<String, Object> metadata
) {}

