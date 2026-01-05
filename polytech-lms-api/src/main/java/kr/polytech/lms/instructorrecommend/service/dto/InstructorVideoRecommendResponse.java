package kr.polytech.lms.instructorrecommend.service.dto;

import java.util.Map;

public record InstructorVideoRecommendResponse(
    String lessonId,
    String lessonName,
    double score,
    Map<String, Object> metadata
) {}

