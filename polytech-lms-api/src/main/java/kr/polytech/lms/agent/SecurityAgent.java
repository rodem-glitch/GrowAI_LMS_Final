// polytech-lms-api/src/main/java/kr/polytech/lms/agent/SecurityAgent.java
package kr.polytech.lms.agent;

import kr.polytech.lms.gcp.service.SecurityCommandCenterService;
import kr.polytech.lms.gcp.service.VertexAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Security Agent
 * 24/7 보안 이벤트 탐지 및 자동 대응
 * Tech: Security Command Center + Vertex AI
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SecurityAgent {

    private final SecurityCommandCenterService sccService;
    private final VertexAiService vertexAiService;

    // 위협 패턴 캐시
    private final Map<String, Integer> ipFailureCount = new HashMap<>();
    private final Set<String> blockedIps = new HashSet<>();

    /**
     * 정기 보안 스캔 (5분마다)
     */
    @Scheduled(fixedRate = 300000)
    public void scheduledSecurityScan() {
        log.debug("Security Agent: 정기 보안 스캔 실행");
        performSecurityScan();
    }

    /**
     * 보안 스캔 수행
     */
    public Map<String, Object> performSecurityScan() {
        log.info("Security Agent: 보안 스캔 시작");

        List<Map<String, Object>> threats = new ArrayList<>();
        int criticalCount = 0, highCount = 0;

        // 1. SCC 발견사항 조회
        List<Map<String, Object>> findings = sccService.listFindings(null, 100);
        for (Map<String, Object> finding : findings) {
            String severity = (String) finding.get("severity");
            if ("CRITICAL".equals(severity)) {
                criticalCount++;
                threats.add(finding);
                // 자동 대응
                handleCriticalThreat(finding);
            } else if ("HIGH".equals(severity)) {
                highCount++;
                threats.add(finding);
            }
        }

        // 2. 취약점 분석
        List<Map<String, Object>> vulnerabilities = sccService.getVulnerabilities();

        // 3. AI 기반 위협 분석
        if (!threats.isEmpty()) {
            analyzeThreatsWithAi(threats);
        }

        Map<String, Object> result = Map.of(
            "scanTime", LocalDateTime.now().toString(),
            "findingsCount", findings.size(),
            "criticalCount", criticalCount,
            "highCount", highCount,
            "vulnerabilitiesCount", vulnerabilities.size(),
            "blockedIps", blockedIps.size(),
            "status", criticalCount > 0 ? "ALERT" : (highCount > 0 ? "WARNING" : "OK")
        );

        log.info("Security Agent: 보안 스캔 완료 - {}", result.get("status"));
        return result;
    }

    /**
     * 실시간 위협 감지
     */
    public void detectThreat(String eventType, String source, Map<String, Object> details) {
        log.warn("Security Agent: 위협 감지 - type={}, source={}", eventType, source);

        // IP 기반 차단 로직
        String ipAddress = (String) details.get("ipAddress");
        if (ipAddress != null) {
            int failCount = ipFailureCount.getOrDefault(ipAddress, 0) + 1;
            ipFailureCount.put(ipAddress, failCount);

            // 5회 이상 실패 시 IP 차단
            if (failCount >= 5) {
                blockIp(ipAddress, "다중 실패 감지");
            }
        }

        // SCC에 보안 이벤트 로깅
        String severity = determineSeverity(eventType);
        sccService.logSecurityEvent(eventType, severity, "위협 감지: " + eventType, details);

        // 심각한 위협은 즉시 알림
        if ("CRITICAL".equals(severity) || "HIGH".equals(severity)) {
            sendSecurityAlert(eventType, source, details);
        }
    }

    /**
     * IP 차단
     */
    public void blockIp(String ipAddress, String reason) {
        if (!blockedIps.contains(ipAddress)) {
            blockedIps.add(ipAddress);
            log.warn("Security Agent: IP 차단 - ip={}, reason={}", ipAddress, reason);

            sccService.logSecurityEvent(
                "IP_BLOCKED",
                "HIGH",
                "IP 주소 차단: " + reason,
                Map.of("ipAddress", ipAddress, "reason", reason)
            );
        }
    }

    /**
     * IP 차단 해제
     */
    public void unblockIp(String ipAddress) {
        blockedIps.remove(ipAddress);
        ipFailureCount.remove(ipAddress);
        log.info("Security Agent: IP 차단 해제 - ip={}", ipAddress);
    }

    /**
     * IP 차단 여부 확인
     */
    public boolean isBlocked(String ipAddress) {
        return blockedIps.contains(ipAddress);
    }

    /**
     * 심각한 위협 자동 대응
     */
    private void handleCriticalThreat(Map<String, Object> threat) {
        log.error("Security Agent: 심각한 위협 자동 대응 - {}", threat.get("category"));

        // 자동 대응 로직
        // 1. 관련 리소스 격리
        // 2. 관리자 알림
        // 3. 증거 수집
    }

    /**
     * AI 기반 위협 분석
     */
    private void analyzeThreatsWithAi(List<Map<String, Object>> threats) {
        log.info("Security Agent: AI 기반 위협 분석 시작");

        StringBuilder context = new StringBuilder();
        for (Map<String, Object> threat : threats) {
            context.append(String.format("위협: %s, 심각도: %s, 설명: %s\n",
                threat.get("category"),
                threat.get("severity"),
                threat.get("description")
            ));
        }

        // Vertex AI로 위협 패턴 분석
        Map<String, Object> analysis = vertexAiService.ragQuery(
            "다음 보안 위협들을 분석하고 대응 방안을 제시해주세요.",
            List.of(context.toString())
        );

        log.info("Security Agent: AI 분석 완료 - {}", analysis.get("answer"));
    }

    /**
     * 보안 알림 전송
     */
    private void sendSecurityAlert(String eventType, String source, Map<String, Object> details) {
        log.error("Security Agent: 보안 알림 - type={}, source={}", eventType, source);
        // 실제로는 이메일, Slack, SMS 등으로 알림
    }

    /**
     * 이벤트 유형에 따른 심각도 결정
     */
    private String determineSeverity(String eventType) {
        return switch (eventType.toUpperCase()) {
            case "SQL_INJECTION_ATTEMPT", "DATA_BREACH" -> "CRITICAL";
            case "XSS_ATTEMPT", "FRAUD_ATTEMPT", "UNAUTHORIZED_ACCESS" -> "HIGH";
            case "LOGIN_FAILURE", "SUSPICIOUS_ACTIVITY" -> "MEDIUM";
            default -> "LOW";
        };
    }

    /**
     * 에이전트 상태 조회
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "agent", "SecurityAgent",
            "role", "24/7 보안 이벤트 탐지 및 자동 대응",
            "tech", "Security Command Center + Vertex AI",
            "blockedIps", blockedIps.size(),
            "monitoredEvents", ipFailureCount.size(),
            "status", "ACTIVE",
            "lastScan", LocalDateTime.now().toString()
        );
    }
}
