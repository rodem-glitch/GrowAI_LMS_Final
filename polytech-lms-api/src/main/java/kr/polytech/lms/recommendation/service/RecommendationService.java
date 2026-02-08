// polytech-lms-api/src/main/java/kr/polytech/lms/recommendation/service/RecommendationService.java
package kr.polytech.lms.recommendation.service;

import kr.polytech.lms.recommendation.client.PredictionIOClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 개인 맞춤형 추천 서비스
 * PredictionIO + 규칙 기반 하이브리드 추천
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final PredictionIOClient predictionIOClient;
    private final JdbcTemplate jdbcTemplate;

    /**
     * 사용자별 과정 추천
     */
    public List<Map<String, Object>> getPersonalizedCourses(Long userId, Long siteId, int limit) {
        List<Map<String, Object>> recommendations = new ArrayList<>();

        // 1. PredictionIO AI 추천
        List<Map<String, Object>> aiRecommendations = predictionIOClient.getRecommendations(
            String.valueOf(userId), limit);

        if (!aiRecommendations.isEmpty()) {
            List<String> courseIds = aiRecommendations.stream()
                .map(r -> r.get("item").toString())
                .collect(Collectors.toList());

            recommendations.addAll(getCourseDetails(courseIds, siteId));
            log.info("AI 추천 결과: userId={}, count={}", userId, recommendations.size());
        }

        // 2. AI 결과가 부족하면 규칙 기반 추천으로 보완
        if (recommendations.size() < limit) {
            int remaining = limit - recommendations.size();
            List<Map<String, Object>> ruleBasedRecs = getRuleBasedRecommendations(userId, siteId, remaining);

            // 중복 제거
            Set<Object> existingIds = recommendations.stream()
                .map(r -> r.get("id"))
                .collect(Collectors.toSet());

            ruleBasedRecs.stream()
                .filter(r -> !existingIds.contains(r.get("id")))
                .forEach(recommendations::add);
        }

        return recommendations.stream().limit(limit).collect(Collectors.toList());
    }

    /**
     * 규칙 기반 추천 (사용자 이력 분석)
     */
    private List<Map<String, Object>> getRuleBasedRecommendations(Long userId, Long siteId, int limit) {
        try {
            // 사용자가 수강한 과정의 카테고리 분석
            String sql = """
                SELECT DISTINCT c.id, c.course_nm, c.onoff_type, c.course_type,
                       (SELECT COUNT(*) FROM LM_COURSE_USER cu2 WHERE cu2.course_id = c.id AND cu2.complete_yn = 'Y') as completions
                FROM LM_COURSE c
                WHERE c.site_id = ? AND c.status = 1 AND c.display_yn = 'Y'
                  AND c.id NOT IN (SELECT course_id FROM LM_COURSE_USER WHERE user_id = ?)
                ORDER BY completions DESC, c.reg_date DESC
                LIMIT ?
                """;

            return jdbcTemplate.queryForList(sql, siteId, userId, limit);

        } catch (Exception e) {
            log.error("규칙 기반 추천 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 과정 상세 정보 조회
     */
    private List<Map<String, Object>> getCourseDetails(List<String> courseIds, Long siteId) {
        if (courseIds.isEmpty()) return Collections.emptyList();

        try {
            String placeholders = courseIds.stream()
                .map(id -> "?")
                .collect(Collectors.joining(","));

            String sql = String.format("""
                SELECT id, course_nm, course_type, onoff_type, status
                FROM LM_COURSE
                WHERE id IN (%s) AND site_id = ? AND status = 1
                """, placeholders);

            List<Object> params = new ArrayList<>(courseIds);
            params.add(siteId);

            return jdbcTemplate.queryForList(sql, params.toArray());

        } catch (Exception e) {
            log.error("과정 상세 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 유사 과정 추천
     */
    public List<Map<String, Object>> getSimilarCourses(Long courseId, Long siteId, int limit) {
        List<Map<String, Object>> similar = predictionIOClient.getSimilarItems(
            String.valueOf(courseId), limit);

        if (!similar.isEmpty()) {
            List<String> courseIds = similar.stream()
                .map(r -> r.get("item").toString())
                .collect(Collectors.toList());
            return getCourseDetails(courseIds, siteId);
        }

        // 폴백: 같은 유형의 과정 추천
        return getFallbackSimilarCourses(courseId, siteId, limit);
    }

    /**
     * 폴백 유사 과정 (같은 유형)
     */
    private List<Map<String, Object>> getFallbackSimilarCourses(Long courseId, Long siteId, int limit) {
        try {
            String sql = """
                SELECT c2.id, c2.course_nm, c2.course_type, c2.onoff_type
                FROM LM_COURSE c1
                JOIN LM_COURSE c2 ON c1.course_type = c2.course_type AND c1.id != c2.id
                WHERE c1.id = ? AND c2.site_id = ? AND c2.status = 1 AND c2.display_yn = 'Y'
                ORDER BY c2.reg_date DESC
                LIMIT ?
                """;

            return jdbcTemplate.queryForList(sql, courseId, siteId, limit);

        } catch (Exception e) {
            log.error("폴백 유사 과정 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 학습 이벤트 기록 (PredictionIO 전송)
     */
    public void recordLearningEvent(String eventType, Long userId, Long courseId) {
        switch (eventType) {
            case "view" -> predictionIOClient.recordView(
                String.valueOf(userId), String.valueOf(courseId));
            case "enroll" -> predictionIOClient.recordEnroll(
                String.valueOf(userId), String.valueOf(courseId));
            case "complete" -> predictionIOClient.recordComplete(
                String.valueOf(userId), String.valueOf(courseId), 100);
            default -> log.warn("알 수 없는 이벤트 유형: {}", eventType);
        }
    }
}
