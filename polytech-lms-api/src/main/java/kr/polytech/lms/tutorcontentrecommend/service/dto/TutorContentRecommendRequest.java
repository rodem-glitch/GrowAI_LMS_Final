package kr.polytech.lms.tutorcontentrecommend.service.dto;

import java.util.List;

public record TutorContentRecommendRequest(
    String courseName,
    String courseIntro,
    String courseDetail,
    String lessonTitle,
    String lessonDescription,
    String keywords,
    Integer topK,
    Double similarityThreshold
) {
    public static TutorContentRecommendRequest empty() {
        return new TutorContentRecommendRequest(null, null, null, null, null, null, null, null);
    }

    public int topKOrDefault() {
        int raw = topK == null ? 10 : topK;
        return Math.max(1, Math.min(raw, 50));
    }

    public double similarityThresholdOrDefault() {
        double raw = similarityThreshold == null ? 0.2 : similarityThreshold;
        return Math.max(0.0, Math.min(raw, 1.0));
    }
}
