package kr.polytech.lms.instructorrecommend.service.dto;

import java.util.List;

public record InstructorVideoRecommendRequest(
    Integer siteId,
    Integer categoryId,
    String courseName,
    String subjectName,
    String grade,
    String term,
    String keywords,
    String freeText,
    List<String> lessonTypes,
    int topK,
    double similarityThreshold
) {
    public InstructorVideoRecommendRequest {
        // 왜: 요청 값이 비어있어도 개발/테스트가 가능하도록 안전한 기본값으로 보정합니다.
        if (topK <= 0) topK = 10;
        if (topK > 50) topK = 50;
        if (similarityThreshold < 0.0) similarityThreshold = 0.0;
        if (similarityThreshold > 1.0) similarityThreshold = 1.0;

        // 왜: "영상 추천"인 만큼, 기본은 영상 계열 타입만 검색되도록 제한합니다.
        // - 01: 위캔디오, 03: MP4, 05: 콜러스(레거시 기준)
        if (lessonTypes == null || lessonTypes.isEmpty()) {
            lessonTypes = List.of("05", "03", "01");
        }
    }
}
