package kr.polytech.lms.studentcontentrecommend.service.dto;

import java.util.List;

public record StudentHomeRecommendRequest(
    String deptName,
    String majorName,
    List<String> courseNames,
    String extraQuery,
    Integer topK,
    Double similarityThreshold
) {
    public static StudentHomeRecommendRequest empty() {
        return new StudentHomeRecommendRequest(null, null, null, null, null, null);
    }

    public int topKOrDefault() {
        int raw = topK == null ? 20 : topK;
        return Math.max(1, Math.min(raw, 50));
    }

    public double similarityThresholdOrDefault() {
        double raw = similarityThreshold == null ? 0.2 : similarityThreshold;
        return Math.max(0.0, Math.min(raw, 1.0));
    }
}

