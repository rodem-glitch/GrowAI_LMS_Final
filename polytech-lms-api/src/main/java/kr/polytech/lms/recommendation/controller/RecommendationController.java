// polytech-lms-api/src/main/java/kr/polytech/lms/recommendation/controller/RecommendationController.java
package kr.polytech.lms.recommendation.controller;

import kr.polytech.lms.recommendation.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * AI 추천 API 컨트롤러
 * 개인 맞춤형 과정/콘텐츠 추천
 */
@Slf4j
@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService recommendationService;

    /**
     * 개인 맞춤형 과정 추천
     */
    @GetMapping("/courses")
    public ResponseEntity<Map<String, Object>> getRecommendedCourses(
            @RequestParam Long userId,
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(defaultValue = "10") int limit) {

        log.info("과정 추천 요청: userId={}, siteId={}", userId, siteId);

        List<Map<String, Object>> recommendations = recommendationService.getPersonalizedCourses(
            userId, siteId, limit);

        return ResponseEntity.ok(Map.of(
            "userId", userId,
            "recommendations", recommendations,
            "count", recommendations.size()
        ));
    }

    /**
     * 유사 과정 추천
     */
    @GetMapping("/courses/{courseId}/similar")
    public ResponseEntity<Map<String, Object>> getSimilarCourses(
            @PathVariable Long courseId,
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(defaultValue = "5") int limit) {

        log.info("유사 과정 추천: courseId={}", courseId);

        List<Map<String, Object>> similar = recommendationService.getSimilarCourses(
            courseId, siteId, limit);

        return ResponseEntity.ok(Map.of(
            "courseId", courseId,
            "similarCourses", similar,
            "count", similar.size()
        ));
    }

    /**
     * 학습 이벤트 기록
     */
    @PostMapping("/events")
    public ResponseEntity<Map<String, Object>> recordEvent(
            @RequestBody Map<String, Object> event) {

        String eventType = (String) event.get("eventType");
        Long userId = Long.valueOf(event.get("userId").toString());
        Long courseId = Long.valueOf(event.get("courseId").toString());

        log.info("학습 이벤트 기록: type={}, userId={}, courseId={}", eventType, userId, courseId);

        recommendationService.recordLearningEvent(eventType, userId, courseId);

        return ResponseEntity.ok(Map.of(
            "recorded", true,
            "eventType", eventType,
            "userId", userId,
            "courseId", courseId
        ));
    }
}
