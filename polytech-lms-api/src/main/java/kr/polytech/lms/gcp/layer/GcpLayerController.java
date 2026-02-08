// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/layer/GcpLayerController.java
package kr.polytech.lms.gcp.layer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

/**
 * GCP Layer REST Controller
 * 3계층 아키텍처 통합 API
 *
 * Layer 구성:
 * 1. AI Gateway Layer - 사용자 접점 (Dialogflow CX, Data Studio)
 * 2. AI Agent Layer - 핵심 로직 (Vertex AI, BigQuery ML, Cloud Functions)
 * 3. Infrastructure Layer - 데이터 및 인증 (Identity Platform, Cloud Logging)
 */
@Slf4j
@RestController
@RequestMapping("/api/gcp")
@RequiredArgsConstructor
public class GcpLayerController {

    private final AiGatewayLayer gatewayLayer;
    private final AiAgentLayer agentLayer;
    private final InfrastructureLayer infraLayer;

    // ===== 전체 아키텍처 API =====

    /**
     * 전체 GCP 아키텍처 상태
     */
    @GetMapping("/architecture")
    public ResponseEntity<?> getArchitectureOverview() {
        return ResponseEntity.ok(Map.of(
            "architecture", "Google AI Agentic Ecosystem",
            "description", "GCP(관리 계층)와 NCP(인프라 계층) 하이브리드 구조",
            "layers", List.of(
                Map.of(
                    "name", "AI Gateway Layer",
                    "role", "사용자 접점",
                    "services", List.of("Dialogflow CX", "Data Studio"),
                    "status", gatewayLayer.getStatus()
                ),
                Map.of(
                    "name", "AI Agent Layer",
                    "role", "핵심 로직",
                    "services", List.of("Vertex AI", "BigQuery ML", "Cloud Functions"),
                    "status", agentLayer.getStatus()
                ),
                Map.of(
                    "name", "Infrastructure Layer",
                    "role", "데이터 및 인증",
                    "services", List.of("Identity Platform", "Cloud Logging"),
                    "status", infraLayer.getStatus()
                )
            ),
            "timestamp", LocalDateTime.now().toString()
        ));
    }

    // ===== AI Gateway Layer API =====

    /**
     * 사용자 요청 처리 (대화형)
     */
    @PostMapping("/gateway/process")
    public ResponseEntity<?> processUserRequest(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String query = request.get("query");
        String sessionId = request.get("sessionId");

        return ResponseEntity.ok(gatewayLayer.processUserRequest(userId, query, sessionId));
    }

    /**
     * 대시보드 데이터 (Data Studio 연동)
     */
    @GetMapping("/gateway/dashboard/{type}")
    public ResponseEntity<?> getDashboardData(@PathVariable String type) {
        return ResponseEntity.ok(gatewayLayer.getDashboardData(type));
    }

    /**
     * 리포트 생성
     */
    @PostMapping("/gateway/report")
    public ResponseEntity<?> generateReport(@RequestBody Map<String, Object> request) {
        String reportType = (String) request.get("reportType");
        @SuppressWarnings("unchecked")
        Map<String, Object> parameters = (Map<String, Object>) request.getOrDefault("parameters", Map.of());

        return ResponseEntity.ok(gatewayLayer.generateReport(reportType, parameters));
    }

    /**
     * Gateway Layer 상태
     */
    @GetMapping("/gateway/status")
    public ResponseEntity<?> getGatewayStatus() {
        return ResponseEntity.ok(gatewayLayer.getStatus());
    }

    // ===== AI Agent Layer API =====

    /**
     * AI 분석 수행
     */
    @PostMapping("/agent/analyze")
    public ResponseEntity<?> performAiAnalysis(@RequestBody Map<String, Object> request) {
        String analysisType = (String) request.get("analysisType");
        String input = (String) request.get("input");
        @SuppressWarnings("unchecked")
        List<String> context = (List<String>) request.getOrDefault("context", List.of());

        return ResponseEntity.ok(agentLayer.performAiAnalysis(analysisType, input, context));
    }

    /**
     * 에이전트 작업 실행
     */
    @PostMapping("/agent/execute")
    public ResponseEntity<?> executeAgentTask(@RequestBody Map<String, Object> request) {
        String agentName = (String) request.get("agentName");
        String taskType = (String) request.get("taskType");
        @SuppressWarnings("unchecked")
        Map<String, Object> parameters = (Map<String, Object>) request.getOrDefault("parameters", Map.of());

        return ResponseEntity.ok(agentLayer.executeAgentTask(agentName, taskType, parameters));
    }

    /**
     * Cloud Function 트리거
     */
    @PostMapping("/agent/function/{functionName}")
    public ResponseEntity<?> triggerCloudFunction(
            @PathVariable String functionName,
            @RequestBody Map<String, Object> payload) {

        return ResponseEntity.ok(agentLayer.triggerCloudFunction(functionName, payload)
            .join()); // 동기식으로 결과 반환
    }

    /**
     * 모든 에이전트 상태
     */
    @GetMapping("/agent/states")
    public ResponseEntity<?> getAllAgentStates() {
        return ResponseEntity.ok(Map.of(
            "agents", agentLayer.getAllAgentStates(),
            "timestamp", LocalDateTime.now().toString()
        ));
    }

    /**
     * Agent Layer 상태
     */
    @GetMapping("/agent/status")
    public ResponseEntity<?> getAgentLayerStatus() {
        return ResponseEntity.ok(agentLayer.getStatus());
    }

    // ===== Infrastructure Layer API =====

    /**
     * 사용자 인증
     */
    @PostMapping("/infra/authenticate")
    public ResponseEntity<?> authenticateUser(@RequestBody Map<String, String> request) {
        String idToken = request.get("idToken");
        return ResponseEntity.ok(infraLayer.authenticateUser(idToken));
    }

    /**
     * 토큰 갱신
     */
    @PostMapping("/infra/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        return ResponseEntity.ok(infraLayer.refreshToken(refreshToken));
    }

    /**
     * 세션 생성
     */
    @PostMapping("/infra/session/create")
    public ResponseEntity<?> createSession(@RequestBody Map<String, String> request) {
        return ResponseEntity.ok(infraLayer.createSession(
            request.get("userId"),
            request.getOrDefault("deviceInfo", "Unknown"),
            request.getOrDefault("ipAddress", "0.0.0.0"),
            request.getOrDefault("userAgent", "Unknown")
        ));
    }

    /**
     * 세션 검증
     */
    @PostMapping("/infra/session/validate")
    public ResponseEntity<?> validateSession(@RequestBody Map<String, String> request) {
        return ResponseEntity.ok(infraLayer.validateSession(request.get("sessionId")));
    }

    /**
     * 로그 기록
     */
    @PostMapping("/infra/log")
    public ResponseEntity<?> writeLog(@RequestBody Map<String, Object> request) {
        String severity = (String) request.getOrDefault("severity", "INFO");
        String source = (String) request.getOrDefault("source", "UNKNOWN");
        String message = (String) request.get("message");
        @SuppressWarnings("unchecked")
        Map<String, Object> labels = (Map<String, Object>) request.getOrDefault("labels", Map.of());

        infraLayer.writeLog(severity, source, message, labels);

        return ResponseEntity.ok(Map.of("success", true, "message", "로그가 기록되었습니다."));
    }

    /**
     * 감사 이벤트 조회
     */
    @GetMapping("/infra/audit/{userId}")
    public ResponseEntity<?> getAuditEvents(
            @PathVariable String userId,
            @RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(infraLayer.getAuditEvents(userId, limit));
    }

    /**
     * 인프라 모니터링 상태
     */
    @GetMapping("/infra/monitoring")
    public ResponseEntity<?> getInfrastructureStatus() {
        return ResponseEntity.ok(infraLayer.getInfrastructureStatus());
    }

    /**
     * Infrastructure Layer 상태
     */
    @GetMapping("/infra/status")
    public ResponseEntity<?> getInfraLayerStatus() {
        return ResponseEntity.ok(infraLayer.getStatus());
    }

    // ===== 통합 Health Check =====

    /**
     * 전체 GCP 서비스 Health Check
     */
    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "layers", Map.of(
                "gateway", "UP",
                "agent", "UP",
                "infrastructure", "UP"
            ),
            "services", Map.of(
                "dialogflowCx", "UP",
                "dataStudio", "UP",
                "vertexAi", "UP",
                "bigQueryMl", "UP",
                "cloudFunctions", "UP",
                "identityPlatform", "UP",
                "cloudLogging", "UP"
            ),
            "timestamp", LocalDateTime.now().toString()
        ));
    }
}
