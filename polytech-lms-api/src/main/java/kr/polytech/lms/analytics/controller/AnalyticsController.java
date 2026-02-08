// polytech-lms-api/src/main/java/kr/polytech/lms/analytics/controller/AnalyticsController.java
package kr.polytech.lms.analytics.controller;

import kr.polytech.lms.analytics.service.AnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 학습 분석 API 컨트롤러
 * Apache Superset 연동 및 통계 대시보드
 */
@Slf4j
@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    /**
     * 전체 학습 현황 요약
     */
    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getOverview(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.info("학습 현황 요약 조회: siteId={}", siteId);
        return ResponseEntity.ok(analyticsService.getLearningOverview(siteId));
    }

    /**
     * 일별 학습 통계
     */
    @GetMapping("/daily")
    public ResponseEntity<List<Map<String, Object>>> getDailyStats(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(defaultValue = "30") int days) {
        log.info("일별 통계 조회: siteId={}, days={}", siteId, days);
        return ResponseEntity.ok(analyticsService.getDailyLearningStats(siteId, days));
    }

    /**
     * 과정별 수강 현황
     */
    @GetMapping("/courses")
    public ResponseEntity<List<Map<String, Object>>> getCourseStats(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(defaultValue = "10") int limit) {
        log.info("과정별 통계 조회: siteId={}, limit={}", siteId, limit);
        return ResponseEntity.ok(analyticsService.getCourseEnrollmentStats(siteId, limit));
    }

    /**
     * 시간대별 학습 패턴
     */
    @GetMapping("/hourly-pattern")
    public ResponseEntity<List<Map<String, Object>>> getHourlyPattern(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.info("시간대별 패턴 조회: siteId={}", siteId);
        return ResponseEntity.ok(analyticsService.getHourlyLearningPattern(siteId));
    }

    /**
     * 진도율 분포
     */
    @GetMapping("/progress-distribution")
    public ResponseEntity<Map<String, Object>> getProgressDistribution(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.info("진도율 분포 조회: siteId={}", siteId);
        return ResponseEntity.ok(analyticsService.getProgressDistribution(siteId));
    }

    /**
     * Superset 대시보드 임베드 정보
     */
    @GetMapping("/superset/embed/{dashboardId}")
    public ResponseEntity<Map<String, Object>> getSupersetEmbed(@PathVariable String dashboardId) {
        log.info("Superset 임베드 정보: dashboardId={}", dashboardId);
        return ResponseEntity.ok(analyticsService.getSupersetEmbedInfo(dashboardId));
    }

    /**
     * 대시보드 데이터 내보내기 (CSV/JSON)
     */
    @GetMapping("/export")
    public ResponseEntity<Map<String, Object>> exportData(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(defaultValue = "json") String format) {
        log.info("데이터 내보내기: siteId={}, format={}", siteId, format);

        Map<String, Object> exportData = Map.of(
            "overview", analyticsService.getLearningOverview(siteId),
            "courseStats", analyticsService.getCourseEnrollmentStats(siteId, 50),
            "progressDistribution", analyticsService.getProgressDistribution(siteId),
            "exportedAt", System.currentTimeMillis(),
            "format", format
        );

        return ResponseEntity.ok(exportData);
    }
}
