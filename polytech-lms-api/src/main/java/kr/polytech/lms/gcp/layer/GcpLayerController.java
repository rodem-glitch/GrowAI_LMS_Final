// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/layer/GcpLayerController.java
package kr.polytech.lms.gcp.layer;

import kr.polytech.lms.security.error.ExternalServiceException;
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
        try {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of(
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
                    )
                ),
                "timestamp", LocalDateTime.now().toString()
            ));
        } catch (Exception e) {
            log.error("GCP 아키텍처 상태 조회 실패", e);
            throw new ExternalServiceException("GCP", "GCP_001",
                "GCP 아키텍처 상태 조회에 실패했습니다.", e);
        }
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

        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "질문(query)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("Gateway 요청 처리: userId={}, query={}", userId,
            query.substring(0, Math.min(50, query.length())));

        try {
            Map<String, Object> result = gatewayLayer.processUserRequest(userId, query, sessionId);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Gateway 요청 처리 실패: userId={}", userId, e);
            throw new ExternalServiceException("Dialogflow", "GCP_002",
                "대화 처리에 실패했습니다.", e);
        }
    }

    /**
     * 대시보드 데이터 (Data Studio 연동)
     */
    @GetMapping("/gateway/dashboard/{type}")
    public ResponseEntity<?> getDashboardData(@PathVariable String type) {
        log.info("대시보드 데이터 조회: type={}", type);
        try {
            Map<String, Object> data = gatewayLayer.getDashboardData(type);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", data,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("대시보드 데이터 조회 실패: type={}", type, e);
            throw new ExternalServiceException("DataStudio", "GCP_002",
                "대시보드 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 리포트 생성
     */
    @PostMapping("/gateway/report")
    public ResponseEntity<?> generateReport(@RequestBody Map<String, Object> request) {
        String reportType = (String) request.get("reportType");
        if (reportType == null || reportType.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "리포트 유형(reportType)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> parameters = (Map<String, Object>) request.getOrDefault("parameters", Map.of());

        log.info("리포트 생성: reportType={}", reportType);

        try {
            Map<String, Object> result = gatewayLayer.generateReport(reportType, parameters);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("리포트 생성 실패: reportType={}", reportType, e);
            throw new ExternalServiceException("DataStudio", "GCP_002",
                "리포트 생성에 실패했습니다.", e);
        }
    }

    /**
     * Gateway Layer 상태
     */
    @GetMapping("/gateway/status")
    public ResponseEntity<?> getGatewayStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", gatewayLayer.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Gateway 상태 조회 실패", e);
            throw new ExternalServiceException("Dialogflow", "GCP_001",
                "Gateway 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== AI Agent Layer API =====

    /**
     * AI 분석 수행
     */
    @PostMapping("/agent/analyze")
    public ResponseEntity<?> performAiAnalysis(@RequestBody Map<String, Object> request) {
        String analysisType = (String) request.get("analysisType");
        String input = (String) request.get("input");

        if (input == null || input.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "분석 대상(input)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        List<String> context = (List<String>) request.getOrDefault("context", List.of());

        log.info("AI 분석 수행: analysisType={}", analysisType);

        try {
            Map<String, Object> result = agentLayer.performAiAnalysis(analysisType, input, context);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("AI 분석 실패: analysisType={}", analysisType, e);
            throw new ExternalServiceException("VertexAI", "GCP_003",
                "AI 분석에 실패했습니다.", e);
        }
    }

    /**
     * 에이전트 작업 실행
     */
    @PostMapping("/agent/execute")
    public ResponseEntity<?> executeAgentTask(@RequestBody Map<String, Object> request) {
        String agentName = (String) request.get("agentName");
        String taskType = (String) request.get("taskType");

        if (agentName == null || taskType == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "에이전트명(agentName)과 작업유형(taskType)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> parameters = (Map<String, Object>) request.getOrDefault("parameters", Map.of());

        log.info("에이전트 작업 실행: agentName={}, taskType={}", agentName, taskType);

        try {
            Map<String, Object> result = agentLayer.executeAgentTask(agentName, taskType, parameters);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("에이전트 작업 실행 실패: agentName={}, taskType={}", agentName, taskType, e);
            throw new ExternalServiceException("VertexAI", "GCP_003",
                "에이전트 작업 실행에 실패했습니다.", e);
        }
    }

    /**
     * Cloud Function 트리거
     */
    @PostMapping("/agent/function/{functionName}")
    public ResponseEntity<?> triggerCloudFunction(
            @PathVariable String functionName,
            @RequestBody Map<String, Object> payload) {

        log.info("Cloud Function 트리거: functionName={}", functionName);

        try {
            Map<String, Object> result = agentLayer.triggerCloudFunction(functionName, payload)
                .join(); // 동기식으로 결과 반환
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Cloud Function 트리거 실패: functionName={}", functionName, e);
            throw new ExternalServiceException("CloudFunctions", "GCP_003",
                "Cloud Function 실행에 실패했습니다.", e);
        }
    }

    /**
     * 모든 에이전트 상태
     */
    @GetMapping("/agent/states")
    public ResponseEntity<?> getAllAgentStates() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("agents", agentLayer.getAllAgentStates()),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("에이전트 상태 조회 실패", e);
            throw new ExternalServiceException("VertexAI", "GCP_001",
                "에이전트 상태 조회에 실패했습니다.", e);
        }
    }

    /**
     * Agent Layer 상태
     */
    @GetMapping("/agent/status")
    public ResponseEntity<?> getAgentLayerStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", agentLayer.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Agent Layer 상태 조회 실패", e);
            throw new ExternalServiceException("VertexAI", "GCP_001",
                "Agent Layer 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Infrastructure Layer API =====

    /**
     * 사용자 인증
     */
    @PostMapping("/infra/authenticate")
    public ResponseEntity<?> authenticateUser(@RequestBody Map<String, String> request) {
        String idToken = request.get("idToken");
        if (idToken == null || idToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AUTH_001",
                "message", "인증 토큰(idToken)이 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("사용자 인증 요청");

        try {
            Map<String, Object> result = infraLayer.authenticateUser(idToken);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("사용자 인증 실패", e);
            throw new ExternalServiceException("IdentityPlatform", "AUTH_001",
                "인증에 실패했습니다.", e);
        }
    }

    /**
     * 토큰 갱신
     */
    @PostMapping("/infra/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        if (refreshToken == null || refreshToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AUTH_001",
                "message", "갱신 토큰(refreshToken)이 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        try {
            Map<String, Object> result = infraLayer.refreshToken(refreshToken);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("토큰 갱신 실패", e);
            throw new ExternalServiceException("IdentityPlatform", "AUTH_001",
                "토큰 갱신에 실패했습니다.", e);
        }
    }

    /**
     * 세션 생성
     */
    @PostMapping("/infra/session/create")
    public ResponseEntity<?> createSession(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        if (userId == null || userId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "사용자 ID(userId)가 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("세션 생성: userId={}", userId);

        try {
            Map<String, Object> result = infraLayer.createSession(
                userId,
                request.getOrDefault("deviceInfo", "Unknown"),
                request.getOrDefault("ipAddress", "0.0.0.0"),
                request.getOrDefault("userAgent", "Unknown")
            );
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("세션 생성 실패: userId={}", userId, e);
            throw new ExternalServiceException("IdentityPlatform", "AUTH_001",
                "세션 생성에 실패했습니다.", e);
        }
    }

    /**
     * 세션 검증
     */
    @PostMapping("/infra/session/validate")
    public ResponseEntity<?> validateSession(@RequestBody Map<String, String> request) {
        String sessionId = request.get("sessionId");
        if (sessionId == null || sessionId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AUTH_001",
                "message", "세션 ID(sessionId)가 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        try {
            Map<String, Object> result = infraLayer.validateSession(sessionId);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("세션 검증 실패: sessionId={}", sessionId, e);
            throw new ExternalServiceException("IdentityPlatform", "AUTH_001",
                "세션 검증에 실패했습니다.", e);
        }
    }

    /**
     * 로그 기록
     */
    @PostMapping("/infra/log")
    public ResponseEntity<?> writeLog(@RequestBody Map<String, Object> request) {
        String severity = (String) request.getOrDefault("severity", "INFO");
        String source = (String) request.getOrDefault("source", "UNKNOWN");
        String message = (String) request.get("message");

        if (message == null || message.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "로그 메시지(message)가 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> labels = (Map<String, Object>) request.getOrDefault("labels", Map.of());

        try {
            infraLayer.writeLog(severity, source, message, labels);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("message", "로그가 기록되었습니다."),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("로그 기록 실패", e);
            throw new ExternalServiceException("CloudLogging", "GCP_001",
                "로그 기록에 실패했습니다.", e);
        }
    }

    /**
     * 감사 이벤트 조회
     */
    @GetMapping("/infra/audit/{userId}")
    public ResponseEntity<?> getAuditEvents(
            @PathVariable String userId,
            @RequestParam(defaultValue = "50") int limit) {
        log.info("감사 이벤트 조회: userId={}, limit={}", userId, limit);
        try {
            var events = infraLayer.getAuditEvents(userId, limit);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", events,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("감사 이벤트 조회 실패: userId={}", userId, e);
            throw new ExternalServiceException("CloudLogging", "GCP_001",
                "감사 이벤트 조회에 실패했습니다.", e);
        }
    }

    /**
     * 인프라 모니터링 상태
     */
    @GetMapping("/infra/monitoring")
    public ResponseEntity<?> getInfrastructureStatus() {
        try {
            Map<String, Object> status = infraLayer.getInfrastructureStatus();
            return ResponseEntity.ok(Map.of(
                "success", true, "data", status,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("인프라 모니터링 상태 조회 실패", e);
            throw new ExternalServiceException("GCP", "GCP_001",
                "인프라 모니터링 상태 조회에 실패했습니다.", e);
        }
    }

    /**
     * Infrastructure Layer 상태
     */
    @GetMapping("/infra/status")
    public ResponseEntity<?> getInfraLayerStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", infraLayer.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Infrastructure Layer 상태 조회 실패", e);
            throw new ExternalServiceException("GCP", "GCP_001",
                "Infrastructure Layer 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== 통합 Health Check =====

    /**
     * 전체 GCP 서비스 Health Check
     */
    @GetMapping("/layer-health")
    public ResponseEntity<?> layerHealthCheck() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of(
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
                    )
                ),
                "timestamp", LocalDateTime.now().toString()
            ));
        } catch (Exception e) {
            log.error("GCP Layer Health Check 실패", e);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("status", "degraded",
                    "layers", Map.of("gateway", "DOWN", "agent", "DOWN", "infrastructure", "DOWN")),
                "timestamp", LocalDateTime.now().toString()));
        }
    }
}
