// polytech-lms-api/src/main/java/kr/polytech/lms/agent/AgentOrchestrator.java
package kr.polytech.lms.agent;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.*;

/**
 * AI Agent Orchestrator
 * 6개 AI Agent 통합 관리 및 조율
 *
 * Agent 자동화 수준:
 * - Security Agent: 90% (SCC + Vertex AI, 실시간 위협 탐지)
 * - Monitoring Agent: 95% (Cloud Monitoring, BigQuery ML 예측)
 * - Backup Agent: 100% (Cloud Functions, 스케줄 기반)
 * - Helpdesk Agent: 80% (Dialogflow CX + Gemini API)
 * - Compliance Agent: 100% (Policy Analyzer, 자동 점검)
 * - Log Analysis Agent: 95% (Cloud Logging + BigQuery)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AgentOrchestrator {

    private final SecurityAgent securityAgent;
    private final MonitoringAgent monitoringAgent;
    private final BackupAgent backupAgent;
    private final HelpdeskAgent helpdeskAgent;
    private final ComplianceAgent complianceAgent;
    private final LogAnalysisAgent logAnalysisAgent;

    // 에이전트 실행 스레드 풀
    private final ExecutorService executorService = Executors.newFixedThreadPool(6);

    // 에이전트 상태 캐시
    private final Map<String, AgentStatus> agentStatuses = new ConcurrentHashMap<>();

    // 자동화 수준 설정
    private static final Map<String, Integer> AUTOMATION_LEVELS = Map.of(
        "SecurityAgent", 90,
        "MonitoringAgent", 95,
        "BackupAgent", 100,
        "HelpdeskAgent", 80,
        "ComplianceAgent", 100,
        "LogAnalysisAgent", 95
    );

    // 핵심 임무 정의
    private static final Map<String, String> CORE_MISSIONS = Map.of(
        "SecurityAgent", "실시간 위협 탐지 및 Cloud Armor 기반 자동 차단",
        "MonitoringAgent", "BigQuery ML 기반 이상 징후 예측 및 자동 알림",
        "BackupAgent", "스케줄 기반 백업 수행 및 주 1회 복구 무결성 검증",
        "HelpdeskAgent", "Gemini API 연동 사용자 문의 응대 및 장애 분류",
        "ComplianceAgent", "보안 정책 준수 여부 상시 점검 및 리포팅",
        "LogAnalysisAgent", "BigQuery 연동 대용량 로그 패턴 및 이상 행위 탐지"
    );

    /**
     * 주기적 에이전트 상태 수집 (30초마다)
     */
    @Scheduled(fixedRate = 30000)
    public void collectAgentStatuses() {
        log.debug("Agent Orchestrator: 에이전트 상태 수집");

        List<Future<AgentStatus>> futures = new ArrayList<>();

        futures.add(executorService.submit(() -> collectStatus("SecurityAgent", securityAgent.getStatus())));
        futures.add(executorService.submit(() -> collectStatus("MonitoringAgent", monitoringAgent.getStatus())));
        futures.add(executorService.submit(() -> collectStatus("BackupAgent", backupAgent.getStatus())));
        futures.add(executorService.submit(() -> collectStatus("HelpdeskAgent", helpdeskAgent.getStatus())));
        futures.add(executorService.submit(() -> collectStatus("ComplianceAgent", complianceAgent.getStatus())));
        futures.add(executorService.submit(() -> collectStatus("LogAnalysisAgent", logAnalysisAgent.getStatus())));

        for (Future<AgentStatus> future : futures) {
            try {
                AgentStatus status = future.get(5, TimeUnit.SECONDS);
                agentStatuses.put(status.agentName, status);
            } catch (Exception e) {
                log.error("에이전트 상태 수집 실패: {}", e.getMessage());
            }
        }
    }

    /**
     * 상태 수집 헬퍼
     */
    private AgentStatus collectStatus(String agentName, Map<String, Object> statusData) {
        return new AgentStatus(
            agentName,
            (String) statusData.getOrDefault("status", "UNKNOWN"),
            AUTOMATION_LEVELS.get(agentName),
            CORE_MISSIONS.get(agentName),
            statusData,
            LocalDateTime.now()
        );
    }

    /**
     * 전체 에이전트 대시보드 데이터
     */
    public Map<String, Object> getDashboard() {
        collectAgentStatuses();

        List<Map<String, Object>> agents = new ArrayList<>();

        for (Map.Entry<String, AgentStatus> entry : agentStatuses.entrySet()) {
            AgentStatus status = entry.getValue();
            Map<String, Object> agentData = new HashMap<>();
            agentData.put("name", status.agentName);
            agentData.put("status", status.status);
            agentData.put("automationLevel", status.automationLevel + "%");
            agentData.put("mission", status.mission);
            agentData.put("lastUpdate", status.lastUpdate.toString());
            agentData.put("details", status.details);
            agents.add(agentData);
        }

        int activeCount = (int) agents.stream()
            .filter(a -> "ACTIVE".equals(a.get("status")))
            .count();

        return Map.of(
            "timestamp", LocalDateTime.now().toString(),
            "totalAgents", 6,
            "activeAgents", activeCount,
            "averageAutomation", "93.3%",
            "agents", agents,
            "systemStatus", activeCount == 6 ? "ALL_OPERATIONAL" : "DEGRADED"
        );
    }

    /**
     * 특정 에이전트 상태 조회
     */
    public Map<String, Object> getAgentStatus(String agentName) {
        return switch (agentName.toLowerCase()) {
            case "security" -> securityAgent.getStatus();
            case "monitoring" -> monitoringAgent.getStatus();
            case "backup" -> backupAgent.getStatus();
            case "helpdesk" -> helpdeskAgent.getStatus();
            case "compliance" -> complianceAgent.getStatus();
            case "loganalysis" -> logAnalysisAgent.getStatus();
            default -> Map.of("error", "Unknown agent: " + agentName);
        };
    }

    /**
     * 보안 위협 통합 대응
     */
    public Map<String, Object> handleSecurityThreat(String threatType, String source,
            Map<String, Object> details) {

        log.warn("Agent Orchestrator: 보안 위협 통합 대응 - type={}, source={}",
            threatType, source);

        List<Map<String, Object>> responses = new ArrayList<>();

        // 1. Security Agent - 즉시 위협 감지 및 대응
        securityAgent.detectThreat(threatType, source, details);
        responses.add(Map.of(
            "agent", "SecurityAgent",
            "action", "THREAT_DETECTED",
            "timestamp", LocalDateTime.now().toString()
        ));

        // 2. Log Analysis Agent - 관련 로그 분석
        String ip = (String) details.get("ipAddress");
        logAnalysisAgent.collectLog("SECURITY", threatType, "Threat detected: " + source,
            Map.of("ipAddress", ip != null ? ip : "unknown", "threatType", threatType));
        responses.add(Map.of(
            "agent", "LogAnalysisAgent",
            "action", "LOG_COLLECTED",
            "timestamp", LocalDateTime.now().toString()
        ));

        // 3. Monitoring Agent - 시스템 상태 확인
        Map<String, Object> metrics = monitoringAgent.collectAndAnalyzeMetrics();
        responses.add(Map.of(
            "agent", "MonitoringAgent",
            "action", "METRICS_ANALYZED",
            "systemStatus", metrics.get("status"),
            "timestamp", LocalDateTime.now().toString()
        ));

        return Map.of(
            "threatType", threatType,
            "source", source,
            "responses", responses,
            "overallStatus", "THREAT_HANDLED",
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 정기 시스템 점검 실행
     */
    public Map<String, Object> runSystemCheck() {
        log.info("Agent Orchestrator: 정기 시스템 점검 시작");

        Map<String, Object> results = new HashMap<>();

        // 병렬로 모든 에이전트 점검 실행
        CompletableFuture<Map<String, Object>> securityFuture =
            CompletableFuture.supplyAsync(securityAgent::performSecurityScan, executorService);

        CompletableFuture<Map<String, Object>> monitoringFuture =
            CompletableFuture.supplyAsync(monitoringAgent::collectAndAnalyzeMetrics, executorService);

        CompletableFuture<Map<String, Object>> complianceFuture =
            CompletableFuture.supplyAsync(complianceAgent::performFullComplianceCheck, executorService);

        try {
            results.put("security", securityFuture.get(30, TimeUnit.SECONDS));
            results.put("monitoring", monitoringFuture.get(30, TimeUnit.SECONDS));
            results.put("compliance", complianceFuture.get(30, TimeUnit.SECONDS));

            // 전체 상태 결정
            String securityStatus = (String) ((Map<?, ?>) results.get("security")).get("status");
            String monitoringStatus = (String) ((Map<?, ?>) results.get("monitoring")).get("status");
            String complianceStatus = (String) ((Map<?, ?>) results.get("compliance")).get("overallStatus");

            String overallStatus = determineOverallStatus(securityStatus, monitoringStatus, complianceStatus);

            results.put("overallStatus", overallStatus);
            results.put("timestamp", LocalDateTime.now().toString());

            log.info("Agent Orchestrator: 시스템 점검 완료 - status={}", overallStatus);

        } catch (Exception e) {
            log.error("시스템 점검 실패: {}", e.getMessage());
            results.put("error", e.getMessage());
            results.put("overallStatus", "ERROR");
        }

        return results;
    }

    /**
     * 전체 상태 결정
     */
    private String determineOverallStatus(String... statuses) {
        for (String status : statuses) {
            if (status != null && (status.contains("CRITICAL") || status.contains("ALERT"))) {
                return "CRITICAL";
            }
        }
        for (String status : statuses) {
            if (status != null && (status.contains("WARNING") || status.contains("NON_COMPLIANT"))) {
                return "WARNING";
            }
        }
        return "HEALTHY";
    }

    /**
     * 에이전트 재시작
     */
    public void restartAgent(String agentName) {
        log.warn("Agent Orchestrator: 에이전트 재시작 - {}", agentName);
        // 에이전트 재초기화 로직 (필요시 구현)
    }

    /**
     * 오케스트레이터 상태
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "service", "AgentOrchestrator",
            "role", "6개 AI Agent 통합 관리",
            "agents", List.of(
                Map.of("name", "SecurityAgent", "automation", "90%", "service", "SCC + Vertex AI"),
                Map.of("name", "MonitoringAgent", "automation", "95%", "service", "Cloud Monitoring"),
                Map.of("name", "BackupAgent", "automation", "100%", "service", "Cloud Functions"),
                Map.of("name", "HelpdeskAgent", "automation", "80%", "service", "Dialogflow CX"),
                Map.of("name", "ComplianceAgent", "automation", "100%", "service", "Policy Analyzer"),
                Map.of("name", "LogAnalysisAgent", "automation", "95%", "service", "Cloud Logging")
            ),
            "averageAutomation", "93.3%",
            "activeAgents", agentStatuses.size(),
            "status", "ACTIVE"
        );
    }

    /**
     * 에이전트 상태 레코드
     */
    private record AgentStatus(
        String agentName,
        String status,
        int automationLevel,
        String mission,
        Map<String, Object> details,
        LocalDateTime lastUpdate
    ) {}
}
