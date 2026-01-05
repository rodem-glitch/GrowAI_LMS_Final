package kr.polytech.lms.instructorrecommend.service.dto;

public record InstructorVideoRecommendRequest(
    Integer siteId,
    String courseName,
    String subjectName,
    String grade,
    String term,
    String keywords,
    String freeText,
    int topK,
    double similarityThreshold
) {
    public InstructorVideoRecommendRequest {
        // 왜: 요청 값이 비어있어도 개발/테스트가 가능하도록 안전한 기본값으로 보정합니다.
        if (topK <= 0) topK = 10;
        if (topK > 50) topK = 50;
        if (similarityThreshold < 0.0) similarityThreshold = 0.0;
        if (similarityThreshold > 1.0) similarityThreshold = 1.0;
    }
}
