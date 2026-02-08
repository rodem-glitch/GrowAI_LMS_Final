// polytech-lms-api/src/main/java/kr/polytech/lms/agent/controller/AgentController.java
package kr.polytech.lms.agent.controller;

import kr.polytech.lms.agent.*;
import kr.polytech.lms.gcp.service.CloudArmorService;
import kr.polytech.lms.security.csap.CsapComplianceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
        return ResponseEntity.ok(orchestrator.getDashboard());
    }

    /**
     * 시스템 전체 점검 실행
     */
    @PostMapping("/system-check")
    public ResponseEntity<?> runSystemCheck() {
        return ResponseEntity.ok(orchestrator.runSystemCheck());
    }

    /**
     * 오케스트레이터 상태
     */
    @GetMapping("/orchestrator/status")
    public ResponseEntity<?> getOrchestratorStatus() {
        return ResponseEntity.ok(orchestrator.getStatus());
    }

    // ===== Security Agent API (90% 자동화) =====

    /**
     * 보안 스캔 실행
     */
    @PostMapping("/security/scan")
    public ResponseEntity<?> runSecurityScan() {
        return ResponseEntity.ok(securityAgent.performSecurityScan());
    }

    /**
     * 위협 감지 및 대응
     */
    @PostMapping("/security/threat")
    public ResponseEntity<?> detectThreat(@RequestBody Map<String, Object> request) {
        String eventType = (String) request.get("eventType");
        String source = (String) request.get("source");

        securityAgent.detectThreat(eventType, source, request);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "위협이 감지되어 대응되었습니다.",
            "eventType", eventType
        ));
    }

    /**
     * IP 차단 (Cloud Armor 연동)
     */
    @PostMapping("/security/block-ip")
    public ResponseEntity<?> blockIp(@RequestBody Map<String, Object> request) {
        String ipAddress = (String) request.get("ipAddress");
        String reason = (String) request.getOrDefault("reason", "Manual block");
        int duration = (int) request.getOrDefault("duration", 60);

        securityAgent.blockIp(ipAddress, reason);
        Map<String, Object> result = cloudArmorService.blockIp(ipAddress, reason, duration);

        return ResponseEntity.ok(result);
    }

    /**
     * IP 차단 해제
     */
    @PostMapping("/security/unblock-ip")
    public ResponseEntity<?> unblockIp(@RequestBody Map<String, Object> request) {
        String ipAddress = (String) request.get("ipAddress");

        securityAgent.unblockIp(ipAddress);
        Map<String, Object> result = cloudArmorService.unblockIp(ipAddress);

        return ResponseEntity.ok(result);
    }

    /**
     * Security Agent 상태
     */
    @GetMapping("/security/status")
    public ResponseEntity<?> getSecurityStatus() {
        return ResponseEntity.ok(securityAgent.getStatus());
    }

    // ===== Monitoring Agent API (95% 자동화) =====

    /**
     * 메트릭 수집 및 분석
     */
    @PostMapping("/monitoring/analyze")
    public ResponseEntity<?> analyzeMetrics() {
        return ResponseEntity.ok(monitoringAgent.collectAndAnalyzeMetrics());
    }

    /**
     * 메트릭 히스토리 조회
     */
    @GetMapping("/monitoring/history/{metricName}")
    public ResponseEntity<?> getMetricHistory(
            @PathVariable String metricName,
            @RequestParam(defaultValue = "60") int minutes) {
        return ResponseEntity.ok(monitoringAgent.getMetricHistory(metricName, minutes));
    }

    /**
     * Monitoring Agent 상태
     */
    @GetMapping("/monitoring/status")
    public ResponseEntity<?> getMonitoringStatus() {
        return ResponseEntity.ok(monitoringAgent.getStatus());
    }

    // ===== Backup Agent API (100% 자동화) =====

    /**
     * 수동 전체 백업 실행
     */
    @PostMapping("/backup/full")
    public ResponseEntity<?> performFullBackup() {
        return ResponseEntity.ok(backupAgent.performFullBackup("MANUAL"));
    }

    /**
     * 백업 복구
     */
    @PostMapping("/backup/restore")
    public ResponseEntity<?> restoreBackup(@RequestBody Map<String, String> request) {
        String backupName = request.get("backupName");
        return ResponseEntity.ok(backupAgent.restoreBackup(backupName));
    }

    /**
     * 백업 목록 조회
     */
    @GetMapping("/backup/list")
    public ResponseEntity<?> listBackups() {
        return ResponseEntity.ok(backupAgent.listBackups());
    }

    /**
     * Backup Agent 상태
     */
    @GetMapping("/backup/status")
    public ResponseEntity<?> getBackupStatus() {
        return ResponseEntity.ok(backupAgent.getStatus());
    }

    // ===== Helpdesk Agent API (80% 자동화) =====

    /**
     * 사용자 문의 처리
     */
    @PostMapping("/helpdesk/query")
    public ResponseEntity<?> handleQuery(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String query = request.get("query");
        String sessionId = request.getOrDefault("sessionId", java.util.UUID.randomUUID().toString());

        return ResponseEntity.ok(helpdeskAgent.handleQuery(userId, query, sessionId));
    }

    /**
     * 티켓 상태 조회
     */
    @GetMapping("/helpdesk/ticket/{ticketId}")
    public ResponseEntity<?> getTicketStatus(@PathVariable String ticketId) {
        return ResponseEntity.ok(helpdeskAgent.getTicketStatus(ticketId));
    }

    /**
     * 티켓 해결 처리
     */
    @PostMapping("/helpdesk/ticket/{ticketId}/resolve")
    public ResponseEntity<?> resolveTicket(
            @PathVariable String ticketId,
            @RequestBody Map<String, String> request) {
        String resolution = request.get("resolution");
        helpdeskAgent.resolveTicket(ticketId, resolution);
        return ResponseEntity.ok(Map.of("success", true, "ticketId", ticketId));
    }

    /**
     * Helpdesk Agent 상태
     */
    @GetMapping("/helpdesk/status")
    public ResponseEntity<?> getHelpdeskStatus() {
        return ResponseEntity.ok(helpdeskAgent.getStatus());
    }

    // ===== Compliance Agent API (100% 자동화) =====

    /**
     * 전체 컴플라이언스 점검
     */
    @PostMapping("/compliance/audit")
    public ResponseEntity<?> performComplianceAudit() {
        return ResponseEntity.ok(complianceAgent.performFullComplianceCheck());
    }

    /**
     * 정책 위반 목록 조회
     */
    @GetMapping("/compliance/violations")
    public ResponseEntity<?> getViolations() {
        return ResponseEntity.ok(complianceAgent.getViolations());
    }

    /**
     * Compliance Agent 상태
     */
    @GetMapping("/compliance/status")
    public ResponseEntity<?> getComplianceStatus() {
        return ResponseEntity.ok(complianceAgent.getStatus());
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
        @SuppressWarnings("unchecked")
        Map<String, Object> metadata = (Map<String, Object>) request.getOrDefault("metadata", Map.of());

        logAnalysisAgent.collectLog(level, source, message, metadata);

        return ResponseEntity.ok(Map.of("success", true, "message", "로그가 수집되었습니다."));
    }

    /**
     * 최근 이상 행위 조회
     */
    @GetMapping("/logs/anomalies")
    public ResponseEntity<?> getRecentAnomalies(@RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(logAnalysisAgent.getRecentAnomalies(limit));
    }

    /**
     * 특정 유형 이상 행위 조회
     */
    @GetMapping("/logs/anomalies/{type}")
    public ResponseEntity<?> getAnomaliesByType(@PathVariable String type) {
        return ResponseEntity.ok(logAnalysisAgent.getAnomaliesByType(type));
    }

    /**
     * Log Analysis Agent 상태
     */
    @GetMapping("/logs/status")
    public ResponseEntity<?> getLogAnalysisStatus() {
        return ResponseEntity.ok(logAnalysisAgent.getStatus());
    }

    // ===== CSAP 인증 API =====

    /**
     * CSAP 인증 점검
     */
    @PostMapping("/csap/audit")
    public ResponseEntity<?> performCsapAudit() {
        return ResponseEntity.ok(csapService.performComplianceAudit());
    }

    /**
     * 네트워크 분리 상세
     */
    @GetMapping("/csap/network-separation")
    public ResponseEntity<?> getNetworkSeparation() {
        return ResponseEntity.ok(csapService.getNetworkSeparationDetails());
    }

    /**
     * 암호화 상세
     */
    @GetMapping("/csap/encryption")
    public ResponseEntity<?> getEncryption() {
        return ResponseEntity.ok(csapService.getEncryptionDetails());
    }

    /**
     * 물리적 보안 상세
     */
    @GetMapping("/csap/physical-security")
    public ResponseEntity<?> getPhysicalSecurity() {
        return ResponseEntity.ok(csapService.getPhysicalSecurityDetails());
    }

    /**
     * 로그 보존 상세
     */
    @GetMapping("/csap/log-retention")
    public ResponseEntity<?> getLogRetention() {
        return ResponseEntity.ok(csapService.getLogRetentionDetails());
    }

    /**
     * CSAP 상태
     */
    @GetMapping("/csap/status")
    public ResponseEntity<?> getCsapStatus() {
        return ResponseEntity.ok(csapService.getStatus());
    }

    // ===== Cloud Armor API =====

    /**
     * Cloud Armor 정책 상태
     */
    @GetMapping("/cloud-armor/status")
    public ResponseEntity<?> getCloudArmorStatus() {
        return ResponseEntity.ok(cloudArmorService.getStatus());
    }

    /**
     * Cloud Armor 차단 이력
     */
    @GetMapping("/cloud-armor/block-history")
    public ResponseEntity<?> getBlockHistory(@RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(cloudArmorService.getBlockHistory(limit));
    }

    /**
     * DDoS 정책 업데이트
     */
    @PostMapping("/cloud-armor/ddos-policy")
    public ResponseEntity<?> updateDdosPolicy(@RequestBody Map<String, Object> config) {
        return ResponseEntity.ok(cloudArmorService.updateDdosPolicy(config));
    }

    /**
     * WAF 규칙 업데이트
     */
    @PostMapping("/cloud-armor/waf-rules")
    public ResponseEntity<?> updateWafRules(@RequestBody Map<String, Object> request) {
        String ruleType = (String) request.get("ruleType");
        boolean enabled = (boolean) request.getOrDefault("enabled", true);
        return ResponseEntity.ok(cloudArmorService.updateWafRules(ruleType, enabled));
    }
}
