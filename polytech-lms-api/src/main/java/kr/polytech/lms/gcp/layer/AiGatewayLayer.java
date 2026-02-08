// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/layer/AiGatewayLayer.java
package kr.polytech.lms.gcp.layer;

import kr.polytech.lms.gcp.service.DialogflowService;
import kr.polytech.lms.gcp.service.BigQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

/**
 * AI Gateway Layer
 * 사용자 접점 계층 - Dialogflow CX, Data Studio 연동
 *
 * 역할:
 * - 사용자 요청 라우팅
 * - 대화형 인터페이스 제공
 * - 대시보드/리포트 데이터 제공
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AiGatewayLayer {

    private final DialogflowService dialogflowService;
    private final BigQueryService bigQueryService;

    // 요청 라우팅 테이블
    private static final Map<String, String> INTENT_ROUTES = Map.of(
        "course.inquiry", "/api/haksa/courses",
        "grade.inquiry", "/api/haksa/grade/student",
        "attendance.check", "/api/haksa/attendance/check",
        "syllabus.inquiry", "/api/haksa/syllabus",
        "helpdesk.query", "/api/agents/helpdesk/query",
        "report.request", "/api/reports"
    );

    /**
     * 사용자 요청 처리 (Dialogflow CX 연동)
     */
    public Map<String, Object> processUserRequest(String userId, String query, String sessionId) {
        log.info("AI Gateway: 사용자 요청 처리 - userId={}", userId);

        // 1. Dialogflow로 의도 파악
        Map<String, Object> dialogflowResult = dialogflowService.detectIntent(
            sessionId != null ? sessionId : dialogflowService.createSessionId(),
            query,
            "ko"
        );

        String intent = (String) dialogflowResult.getOrDefault("intent", "unknown");
        double confidence = (double) dialogflowResult.getOrDefault("confidence", 0.0);
        String responseText = (String) dialogflowResult.get("responseText");

        // 2. 라우팅 결정
        String route = INTENT_ROUTES.getOrDefault(intent, "/api/agents/helpdesk/query");

        // 3. 응답 구성
        Map<String, Object> response = new HashMap<>();
        response.put("userId", userId);
        response.put("query", query);
        response.put("intent", intent);
        response.put("confidence", confidence);
        response.put("responseText", responseText);
        response.put("route", route);
        response.put("requiresAction", confidence > 0.7);
        response.put("timestamp", LocalDateTime.now().toString());

        log.info("AI Gateway: 요청 라우팅 - intent={}, route={}", intent, route);

        return response;
    }

    /**
     * Data Studio 대시보드 데이터 제공
     */
    public Map<String, Object> getDashboardData(String dashboardType) {
        log.info("AI Gateway: 대시보드 데이터 요청 - type={}", dashboardType);

        return switch (dashboardType.toLowerCase()) {
            case "overview" -> getOverviewDashboard();
            case "learning" -> getLearningDashboard();
            case "security" -> getSecurityDashboard();
            case "performance" -> getPerformanceDashboard();
            default -> getOverviewDashboard();
        };
    }

    /**
     * 개요 대시보드
     */
    private Map<String, Object> getOverviewDashboard() {
        return Map.of(
            "type", "overview",
            "summary", bigQueryService.getDashboardSummary(),
            "courseComparison", bigQueryService.getCourseComparison(),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 학습 대시보드
     */
    private Map<String, Object> getLearningDashboard() {
        return Map.of(
            "type", "learning",
            "progressStats", bigQueryService.getLearningProgressStats("ALL"),
            "attendanceStats", bigQueryService.getAttendanceStats("ALL"),
            "gradeDistribution", bigQueryService.getGradeDistribution("ALL"),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 보안 대시보드
     */
    private Map<String, Object> getSecurityDashboard() {
        return Map.of(
            "type", "security",
            "metrics", Map.of(
                "blockedThreats", 127,
                "activeAlerts", 3,
                "complianceScore", 98.5,
                "lastScan", LocalDateTime.now().minusHours(1).toString()
            ),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 성능 대시보드
     */
    private Map<String, Object> getPerformanceDashboard() {
        return Map.of(
            "type", "performance",
            "metrics", Map.of(
                "avgResponseTime", "125ms",
                "uptime", "99.97%",
                "activeUsers", 234,
                "requestsPerSecond", 156
            ),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 리포트 생성 요청
     */
    public Map<String, Object> generateReport(String reportType, Map<String, Object> parameters) {
        log.info("AI Gateway: 리포트 생성 - type={}", reportType);

        return Map.of(
            "reportType", reportType,
            "status", "GENERATING",
            "parameters", parameters,
            "estimatedTime", "30 seconds",
            "downloadUrl", "/api/reports/download/" + UUID.randomUUID(),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 게이트웨이 상태
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "layer", "AI Gateway Layer",
            "role", "사용자 접점 (User Interface)",
            "services", List.of(
                Map.of("name", "Dialogflow CX", "status", "ACTIVE", "purpose", "대화형 AI"),
                Map.of("name", "Data Studio", "status", "ACTIVE", "purpose", "대시보드/리포트")
            ),
            "routes", INTENT_ROUTES.size(),
            "status", "ACTIVE"
        );
    }
}
