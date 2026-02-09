// polytech-lms-api/src/main/java/kr/polytech/lms/agent/controller/AgentController.java
package kr.polytech.lms.agent.controller;

import kr.polytech.lms.agent.*;
import kr.polytech.lms.gcp.service.CloudArmorService;
import kr.polytech.lms.security.csap.CsapComplianceService;
import kr.polytech.lms.security.error.ExternalServiceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * AI Agent REST Controller
 * 6개 AI Agent 통합 API
 *
 * Agent 목록:
 * - Security Agent (90% 자동화) - SCC + Vertex AI
 * - Monitoring Agent (95% 자동화) - Cloud Monitoring
 * - Backup Agent (100% 자동화) - Cloud Functions
 * - Helpdesk Agent (80% 자동화) - Dialogflow CX + Gemini
 * - Compliance Agent (100% 자동화) - Policy Analyzer
 * - Log Analysis Agent (95% 자동화) - Cloud Logging + BigQuery
 */
@Slf4j
@RestController
@RequestMapping("/api/agents")
@RequiredArgsConstructor
public class AgentController {

    private final AgentOrchestrator orchestrator;
    private final SecurityAgent securityAgent;
    private final MonitoringAgent monitoringAgent;
    private final BackupAgent backupAgent;
    private final HelpdeskAgent helpdeskAgent;
    private final ComplianceAgent complianceAgent;
    private final LogAnalysisAgent logAnalysisAgent;
    private final CloudArmorService cloudArmorService;
    private final CsapComplianceService csapService;

    // ===== 오케스트레이터 API =====

    /**
     * 전체 에이전트 대시보드
     */
    @GetMapping("/dashboard")
    public ResponseEntity<?> getDashboard() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", orchestrator.getDashboard(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("에이전트 대시보드 조회 실패", e);
            throw new ExternalServiceException("AgentOrchestrator", "AGENT_001",
                "에이전트 대시보드 조회에 실패했습니다.", e);
        }
    }

    /**
     * 시스템 전체 점검 실행
     */
    @PostMapping("/system-check")
    public ResponseEntity<?> runSystemCheck() {
        log.info("시스템 전체 점검 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", orchestrator.runSystemCheck(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("시스템 전체 점검 실패", e);
            throw new ExternalServiceException("AgentOrchestrator", "AGENT_001",
                "시스템 전체 점검에 실패했습니다.", e);
        }
    }

    /**
     * 오케스트레이터 상태
     */
    @GetMapping("/orchestrator/status")
    public ResponseEntity<?> getOrchestratorStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", orchestrator.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("오케스트레이터 상태 조회 실패", e);
            throw new ExternalServiceException("AgentOrchestrator", "AGENT_001",
                "오케스트레이터 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Security Agent API (90% 자동화) =====

    /**
     * 보안 스캔 실행
     */
    @PostMapping("/security/scan")
    public ResponseEntity<?> runSecurityScan() {
        log.info("보안 스캔 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", securityAgent.performSecurityScan(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("보안 스캔 실패", e);
            throw new ExternalServiceException("SecurityAgent", "AGENT_002",
                "보안 스캔에 실패했습니다.", e);
        }
    }

    /**
     * 위협 감지 및 대응
     */
    @PostMapping("/security/threat")
    public ResponseEntity<?> detectThreat(@RequestBody Map<String, Object> request) {
        String eventType = (String) request.get("eventType");
        String source = (String) request.get("source");

        if (eventType == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "이벤트 유형(eventType)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("위협 감지 처리: eventType={}, source={}", eventType, source);

        try {
            securityAgent.detectThreat(eventType, source, request);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("message", "위협이 감지되어 대응되었습니다.", "eventType", eventType),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("위협 감지 처리 실패: eventType={}", eventType, e);
            throw new ExternalServiceException("SecurityAgent", "AGENT_002",
                "위협 감지 처리에 실패했습니다.", e);
        }
    }

    /**
     * IP 차단 (Cloud Armor 연동)
     */
    @PostMapping("/security/block-ip")
    public ResponseEntity<?> blockIp(@RequestBody Map<String, Object> request) {
        String ipAddress = (String) request.get("ipAddress");
        if (ipAddress == null || ipAddress.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "IP 주소(ipAddress)를 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        String reason = (String) request.getOrDefault("reason", "Manual block");
        int duration = request.get("duration") instanceof Number ?
            ((Number) request.get("duration")).intValue() : 60;

        log.info("IP 차단 요청: ipAddress={}, reason={}", ipAddress, reason);

        try {
            securityAgent.blockIp(ipAddress, reason);
            Map<String, Object> result = cloudArmorService.blockIp(ipAddress, reason, duration);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("IP 차단 실패: ipAddress={}", ipAddress, e);
            throw new ExternalServiceException("CloudArmor", "AGENT_002",
                "IP 차단에 실패했습니다.", e);
        }
    }

    /**
     * IP 차단 해제
     */
    @PostMapping("/security/unblock-ip")
    public ResponseEntity<?> unblockIp(@RequestBody Map<String, Object> request) {
        String ipAddress = (String) request.get("ipAddress");
        if (ipAddress == null || ipAddress.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "IP 주소(ipAddress)를 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("IP 차단 해제 요청: ipAddress={}", ipAddress);

        try {
            securityAgent.unblockIp(ipAddress);
            Map<String, Object> result = cloudArmorService.unblockIp(ipAddress);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("IP 차단 해제 실패: ipAddress={}", ipAddress, e);
            throw new ExternalServiceException("CloudArmor", "AGENT_002",
                "IP 차단 해제에 실패했습니다.", e);
        }
    }

    /**
     * Security Agent 상태
     */
    @GetMapping("/security/status")
    public ResponseEntity<?> getSecurityStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", securityAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Security Agent 상태 조회 실패", e);
            throw new ExternalServiceException("SecurityAgent", "AGENT_001",
                "Security Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Monitoring Agent API (95% 자동화) =====

    /**
     * 메트릭 수집 및 분석
     */
    @PostMapping("/monitoring/analyze")
    public ResponseEntity<?> analyzeMetrics() {
        log.info("메트릭 수집 및 분석 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", monitoringAgent.collectAndAnalyzeMetrics(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("메트릭 분석 실패", e);
            throw new ExternalServiceException("MonitoringAgent", "AGENT_001",
                "메트릭 분석에 실패했습니다.", e);
        }
    }

    /**
     * 메트릭 히스토리 조회
     */
    @GetMapping("/monitoring/history/{metricName}")
    public ResponseEntity<?> getMetricHistory(
            @PathVariable String metricName,
            @RequestParam(defaultValue = "60") int minutes) {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", monitoringAgent.getMetricHistory(metricName, minutes),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("메트릭 히스토리 조회 실패: metricName={}", metricName, e);
            throw new ExternalServiceException("MonitoringAgent", "AGENT_001",
                "메트릭 히스토리 조회에 실패했습니다.", e);
        }
    }

    /**
     * Monitoring Agent 상태
     */
    @GetMapping("/monitoring/status")
    public ResponseEntity<?> getMonitoringStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", monitoringAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Monitoring Agent 상태 조회 실패", e);
            throw new ExternalServiceException("MonitoringAgent", "AGENT_001",
                "Monitoring Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Backup Agent API (100% 자동화) =====

    /**
     * 수동 전체 백업 실행
     */
    @PostMapping("/backup/full")
    public ResponseEntity<?> performFullBackup() {
        log.info("수동 전체 백업 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", backupAgent.performFullBackup("MANUAL"),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("전체 백업 실패", e);
            throw new ExternalServiceException("BackupAgent", "AGENT_001",
                "백업 실행에 실패했습니다.", e);
        }
    }

    /**
     * 백업 복구
     */
    @PostMapping("/backup/restore")
    public ResponseEntity<?> restoreBackup(@RequestBody Map<String, String> request) {
        String backupName = request.get("backupName");
        if (backupName == null || backupName.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "백업명(backupName)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        log.info("백업 복구 실행: backupName={}", backupName);

        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", backupAgent.restoreBackup(backupName),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("백업 복구 실패: backupName={}", backupName, e);
            throw new ExternalServiceException("BackupAgent", "AGENT_001",
                "백업 복구에 실패했습니다.", e);
        }
    }

    /**
     * 백업 목록 조회
     */
    @GetMapping("/backup/list")
    public ResponseEntity<?> listBackups() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", backupAgent.listBackups(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("백업 목록 조회 실패", e);
            throw new ExternalServiceException("BackupAgent", "AGENT_001",
                "백업 목록 조회에 실패했습니다.", e);
        }
    }

    /**
     * Backup Agent 상태
     */
    @GetMapping("/backup/status")
    public ResponseEntity<?> getBackupStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", backupAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Backup Agent 상태 조회 실패", e);
            throw new ExternalServiceException("BackupAgent", "AGENT_001",
                "Backup Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Helpdesk Agent API (80% 자동화) =====

    /**
     * 사용자 문의 처리
     */
    @PostMapping("/helpdesk/query")
    public ResponseEntity<?> handleQuery(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String query = request.get("query");

        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "문의 내용(query)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        String sessionId = request.getOrDefault("sessionId", java.util.UUID.randomUUID().toString());

        log.info("헬프데스크 문의: userId={}", userId);

        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", helpdeskAgent.handleQuery(userId, query, sessionId),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("헬프데스크 문의 처리 실패: userId={}", userId, e);
            throw new ExternalServiceException("HelpdeskAgent", "AGENT_003",
                "문의 처리에 실패했습니다.", e);
        }
    }

    /**
     * 티켓 상태 조회
     */
    @GetMapping("/helpdesk/ticket/{ticketId}")
    public ResponseEntity<?> getTicketStatus(@PathVariable String ticketId) {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", helpdeskAgent.getTicketStatus(ticketId),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("티켓 상태 조회 실패: ticketId={}", ticketId, e);
            throw new ExternalServiceException("HelpdeskAgent", "AGENT_003",
                "티켓 상태 조회에 실패했습니다.", e);
        }
    }

    /**
     * 티켓 해결 처리
     */
    @PostMapping("/helpdesk/ticket/{ticketId}/resolve")
    public ResponseEntity<?> resolveTicket(
            @PathVariable String ticketId,
            @RequestBody Map<String, String> request) {
        String resolution = request.get("resolution");

        try {
            helpdeskAgent.resolveTicket(ticketId, resolution);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("ticketId", ticketId, "status", "RESOLVED"),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("티켓 해결 처리 실패: ticketId={}", ticketId, e);
            throw new ExternalServiceException("HelpdeskAgent", "AGENT_003",
                "티켓 해결 처리에 실패했습니다.", e);
        }
    }

    /**
     * Helpdesk Agent 상태
     */
    @GetMapping("/helpdesk/status")
    public ResponseEntity<?> getHelpdeskStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", helpdeskAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Helpdesk Agent 상태 조회 실패", e);
            throw new ExternalServiceException("HelpdeskAgent", "AGENT_001",
                "Helpdesk Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Compliance Agent API (100% 자동화) =====

    /**
     * 전체 컴플라이언스 점검
     */
    @PostMapping("/compliance/audit")
    public ResponseEntity<?> performComplianceAudit() {
        log.info("전체 컴플라이언스 점검 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", complianceAgent.performFullComplianceCheck(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("컴플라이언스 점검 실패", e);
            throw new ExternalServiceException("ComplianceAgent", "AGENT_001",
                "컴플라이언스 점검에 실패했습니다.", e);
        }
    }

    /**
     * 정책 위반 목록 조회
     */
    @GetMapping("/compliance/violations")
    public ResponseEntity<?> getViolations() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", complianceAgent.getViolations(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("정책 위반 목록 조회 실패", e);
            throw new ExternalServiceException("ComplianceAgent", "AGENT_001",
                "정책 위반 목록 조회에 실패했습니다.", e);
        }
    }

    /**
     * Compliance Agent 상태
     */
    @GetMapping("/compliance/status")
    public ResponseEntity<?> getComplianceStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", complianceAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Compliance Agent 상태 조회 실패", e);
            throw new ExternalServiceException("ComplianceAgent", "AGENT_001",
                "Compliance Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Log Analysis Agent API (95% 자동화) =====

    /**
     * 로그 수집
     */
    @PostMapping("/logs/collect")
    public ResponseEntity<?> collectLog(@RequestBody Map<String, Object> request) {
        String level = (String) request.get("level");
        String source = (String) request.get("source");
        String message = (String) request.get("message");

        if (message == null || message.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "로그 메시지(message)를 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> metadata = (Map<String, Object>) request.getOrDefault("metadata", Map.of());

        try {
            logAnalysisAgent.collectLog(level, source, message, metadata);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("message", "로그가 수집되었습니다."),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("로그 수집 실패", e);
            throw new ExternalServiceException("LogAnalysisAgent", "AGENT_001",
                "로그 수집에 실패했습니다.", e);
        }
    }

    /**
     * 최근 이상 행위 조회
     */
    @GetMapping("/logs/anomalies")
    public ResponseEntity<?> getRecentAnomalies(@RequestParam(defaultValue = "20") int limit) {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", logAnalysisAgent.getRecentAnomalies(limit),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("이상 행위 조회 실패", e);
            throw new ExternalServiceException("LogAnalysisAgent", "AGENT_001",
                "이상 행위 조회에 실패했습니다.", e);
        }
    }

    /**
     * 특정 유형 이상 행위 조회
     */
    @GetMapping("/logs/anomalies/{type}")
    public ResponseEntity<?> getAnomaliesByType(@PathVariable String type) {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", logAnalysisAgent.getAnomaliesByType(type),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("유형별 이상 행위 조회 실패: type={}", type, e);
            throw new ExternalServiceException("LogAnalysisAgent", "AGENT_001",
                "이상 행위 조회에 실패했습니다.", e);
        }
    }

    /**
     * Log Analysis Agent 상태
     */
    @GetMapping("/logs/status")
    public ResponseEntity<?> getLogAnalysisStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", logAnalysisAgent.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Log Analysis Agent 상태 조회 실패", e);
            throw new ExternalServiceException("LogAnalysisAgent", "AGENT_001",
                "Log Analysis Agent 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== CSAP 인증 API =====

    /**
     * CSAP 인증 점검
     */
    @PostMapping("/csap/audit")
    public ResponseEntity<?> performCsapAudit() {
        log.info("CSAP 인증 점검 실행");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.performComplianceAudit(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("CSAP 인증 점검 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "CSAP 인증 점검에 실패했습니다.", e);
        }
    }

    /**
     * 네트워크 분리 상세
     */
    @GetMapping("/csap/network-separation")
    public ResponseEntity<?> getNetworkSeparation() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.getNetworkSeparationDetails(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("네트워크 분리 상세 조회 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "네트워크 분리 상세 조회에 실패했습니다.", e);
        }
    }

    /**
     * 암호화 상세
     */
    @GetMapping("/csap/encryption")
    public ResponseEntity<?> getEncryption() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.getEncryptionDetails(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("암호화 상세 조회 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "암호화 상세 조회에 실패했습니다.", e);
        }
    }

    /**
     * 물리적 보안 상세
     */
    @GetMapping("/csap/physical-security")
    public ResponseEntity<?> getPhysicalSecurity() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.getPhysicalSecurityDetails(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("물리적 보안 상세 조회 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "물리적 보안 상세 조회에 실패했습니다.", e);
        }
    }

    /**
     * 로그 보존 상세
     */
    @GetMapping("/csap/log-retention")
    public ResponseEntity<?> getLogRetention() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.getLogRetentionDetails(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("로그 보존 상세 조회 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "로그 보존 상세 조회에 실패했습니다.", e);
        }
    }

    /**
     * CSAP 상태
     */
    @GetMapping("/csap/status")
    public ResponseEntity<?> getCsapStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", csapService.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("CSAP 상태 조회 실패", e);
            throw new ExternalServiceException("CSAP", "AGENT_001",
                "CSAP 상태 조회에 실패했습니다.", e);
        }
    }

    // ===== Cloud Armor API =====

    /**
     * Cloud Armor 정책 상태
     */
    @GetMapping("/cloud-armor/status")
    public ResponseEntity<?> getCloudArmorStatus() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", cloudArmorService.getStatus(),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Cloud Armor 상태 조회 실패", e);
            throw new ExternalServiceException("CloudArmor", "AGENT_001",
                "Cloud Armor 상태 조회에 실패했습니다.", e);
        }
    }

    /**
     * Cloud Armor 차단 이력
     */
    @GetMapping("/cloud-armor/block-history")
    public ResponseEntity<?> getBlockHistory(@RequestParam(defaultValue = "50") int limit) {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", cloudArmorService.getBlockHistory(limit),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Cloud Armor 차단 이력 조회 실패", e);
            throw new ExternalServiceException("CloudArmor", "AGENT_001",
                "차단 이력 조회에 실패했습니다.", e);
        }
    }

    /**
     * DDoS 정책 업데이트
     */
    @PostMapping("/cloud-armor/ddos-policy")
    public ResponseEntity<?> updateDdosPolicy(@RequestBody Map<String, Object> config) {
        log.info("DDoS 정책 업데이트 요청");
        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", cloudArmorService.updateDdosPolicy(config),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("DDoS 정책 업데이트 실패", e);
            throw new ExternalServiceException("CloudArmor", "AGENT_002",
                "DDoS 정책 업데이트에 실패했습니다.", e);
        }
    }

    /**
     * WAF 규칙 업데이트
     */
    @PostMapping("/cloud-armor/waf-rules")
    public ResponseEntity<?> updateWafRules(@RequestBody Map<String, Object> request) {
        String ruleType = (String) request.get("ruleType");
        if (ruleType == null || ruleType.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "규칙 유형(ruleType)을 입력해주세요.",
                "timestamp", LocalDateTime.now().toString()));
        }

        boolean enabled = request.get("enabled") instanceof Boolean ?
            (Boolean) request.get("enabled") : true;

        log.info("WAF 규칙 업데이트: ruleType={}, enabled={}", ruleType, enabled);

        try {
            return ResponseEntity.ok(Map.of(
                "success", true, "data", cloudArmorService.updateWafRules(ruleType, enabled),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("WAF 규칙 업데이트 실패: ruleType={}", ruleType, e);
            throw new ExternalServiceException("CloudArmor", "AGENT_002",
                "WAF 규칙 업데이트에 실패했습니다.", e);
        }
    }
}
