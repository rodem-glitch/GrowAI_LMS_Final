package kr.polytech.lms.studentcontentrecommend.service.dto;

public record StudentSearchRecommendRequest(
    Long userId,
    Integer siteId,
    String query,
    Integer topK,
    Double similarityThreshold
) {
    public static StudentSearchRecommendRequest empty() {
        return new StudentSearchRecommendRequest(null, null, null, null, null);
    }

    public int topKOrDefault() {
        int raw = topK == null ? 50 : topK;
        return Math.max(1, Math.min(raw, 200));
    }

    public double similarityThresholdOrDefault() {
        double raw = similarityThreshold == null ? 0.2 : similarityThreshold;
        return Math.max(0.0, Math.min(raw, 1.0));
    }
}
