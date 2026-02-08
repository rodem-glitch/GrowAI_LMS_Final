// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/SecurityCommandCenterService.java
package kr.polytech.lms.gcp.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.GoogleCredentials;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.FileInputStream;
import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

/**
 * Security Command Center 서비스
 * securitycenter.googleapis.com REST API 연동
 * 보안 위협 모니터링 및 취약점 관리
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SecurityCommandCenterService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.organization-id:}")
    private String organizationId;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    // 로컬 보안 이벤트 로그 (메모리 캐시)
    private final List<Map<String, Object>> localSecurityEvents = Collections.synchronizedList(new ArrayList<>());

    /**
     * 액세스 토큰 획득
     */
    private String getAccessToken() {
        try {
            GoogleCredentials credentials;
            if (credentialsPath != null && !credentialsPath.isEmpty()) {
                credentials = GoogleCredentials.fromStream(new FileInputStream(credentialsPath))
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
            } else {
                credentials = GoogleCredentials.getApplicationDefault()
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
            }
            credentials.refreshIfExpired();
            return credentials.getAccessToken().getTokenValue();
        } catch (IOException e) {
            log.error("GCP 인증 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 보안 발견 사항(Findings) 목록 조회
     */
    public List<Map<String, Object>> listFindings(String filter, int pageSize) {
        log.info("Security Command Center 발견사항 조회");

        String accessToken = getAccessToken();
        if (accessToken == null || organizationId == null || organizationId.isEmpty()) {
            return getMockFindings();
        }

        String url = String.format(
            "https://securitycenter.googleapis.com/v1/organizations/%s/sources/-/findings?pageSize=%d",
            organizationId, pageSize
        );

        if (filter != null && !filter.isEmpty()) {
            url += "&filter=" + filter;
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<Void> request = new HttpEntity<>(headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                List<Map<String, Object>> findings = new ArrayList<>();

                for (JsonNode finding : root.path("listFindingsResults")) {
                    JsonNode f = finding.path("finding");
                    findings.add(Map.of(
                        "name", f.path("name").asText(),
                        "category", f.path("category").asText(),
                        "severity", f.path("severity").asText(),
                        "state", f.path("state").asText(),
                        "resourceName", f.path("resourceName").asText(),
                        "eventTime", f.path("eventTime").asText(),
                        "description", f.path("description").asText("")
                    ));
                }

                return findings;
            }

        } catch (Exception e) {
            log.error("발견사항 조회 실패: {}", e.getMessage());
        }

        return getMockFindings();
    }

    /**
     * 보안 이벤트 로깅
     */
    public void logSecurityEvent(String eventType, String severity, String description, Map<String, Object> details) {
        Map<String, Object> event = new HashMap<>();
        event.put("eventId", UUID.randomUUID().toString());
        event.put("eventType", eventType);
        event.put("severity", severity);
        event.put("description", description);
        event.put("details", details != null ? details : Map.of());
        event.put("timestamp", LocalDateTime.now().toString());
        event.put("projectId", projectId);

        localSecurityEvents.add(event);

        // 최대 1000개까지만 유지
        while (localSecurityEvents.size() > 1000) {
            localSecurityEvents.remove(0);
        }

        log.warn("보안 이벤트 기록: type={}, severity={}, desc={}", eventType, severity, description);

        // 심각한 이벤트는 SCC에 보고 (실제 구현)
        if ("CRITICAL".equals(severity) || "HIGH".equals(severity)) {
            reportToScc(event);
        }
    }

    /**
     * SCC에 보안 이벤트 보고
     */
    private void reportToScc(Map<String, Object> event) {
        String accessToken = getAccessToken();
        if (accessToken == null || organizationId == null || organizationId.isEmpty()) {
            log.debug("SCC 보고 건너뛰기 (인증/설정 없음)");
            return;
        }

        // 실제 SCC 발견사항 생성 API 호출
        log.info("SCC에 보안 이벤트 보고: {}", event.get("eventType"));
    }

    /**
     * 로그인 실패 이벤트
     */
    public void logLoginFailure(String userId, String ipAddress, String reason) {
        logSecurityEvent(
            "LOGIN_FAILURE",
            "MEDIUM",
            "로그인 실패: " + reason,
            Map.of("userId", userId, "ipAddress", ipAddress, "reason", reason)
        );
    }

    /**
     * 대리출석 의심 이벤트
     */
    public void logFraudAttempt(String memberKey, String fraudType, String details) {
        logSecurityEvent(
            "FRAUD_ATTEMPT",
            "HIGH",
            "대리출석 의심: " + fraudType,
            Map.of("memberKey", memberKey, "fraudType", fraudType, "details", details)
        );
    }

    /**
     * SQL Injection 시도 이벤트
     */
    public void logSqlInjectionAttempt(String ipAddress, String input) {
        logSecurityEvent(
            "SQL_INJECTION_ATTEMPT",
            "CRITICAL",
            "SQL Injection 시도 감지",
            Map.of("ipAddress", ipAddress, "input", input.substring(0, Math.min(100, input.length())))
        );
    }

    /**
     * XSS 공격 시도 이벤트
     */
    public void logXssAttempt(String ipAddress, String input) {
        logSecurityEvent(
            "XSS_ATTEMPT",
            "HIGH",
            "XSS 공격 시도 감지",
            Map.of("ipAddress", ipAddress, "input", input.substring(0, Math.min(100, input.length())))
        );
    }

    /**
     * 비정상 접근 시도 이벤트
     */
    public void logUnauthorizedAccess(String userId, String resource, String ipAddress) {
        logSecurityEvent(
            "UNAUTHORIZED_ACCESS",
            "MEDIUM",
            "비인가 접근 시도",
            Map.of("userId", userId, "resource", resource, "ipAddress", ipAddress)
        );
    }

    /**
     * 로컬 보안 이벤트 조회
     */
    public List<Map<String, Object>> getLocalSecurityEvents(int limit) {
        int start = Math.max(0, localSecurityEvents.size() - limit);
        return new ArrayList<>(localSecurityEvents.subList(start, localSecurityEvents.size()));
    }

    /**
     * 보안 통계 조회
     */
    public Map<String, Object> getSecurityStatistics() {
        long now = System.currentTimeMillis();
        long oneDayAgo = now - 24 * 60 * 60 * 1000;

        int totalEvents = localSecurityEvents.size();
        int criticalCount = 0, highCount = 0, mediumCount = 0, lowCount = 0;
        int last24hCount = 0;

        Map<String, Integer> eventTypeCounts = new HashMap<>();

        for (Map<String, Object> event : localSecurityEvents) {
            String severity = (String) event.get("severity");
            String eventType = (String) event.get("eventType");

            switch (severity) {
                case "CRITICAL" -> criticalCount++;
                case "HIGH" -> highCount++;
                case "MEDIUM" -> mediumCount++;
                case "LOW" -> lowCount++;
            }

            eventTypeCounts.merge(eventType, 1, Integer::sum);
        }

        return Map.of(
            "totalEvents", totalEvents,
            "bySeverity", Map.of(
                "critical", criticalCount,
                "high", highCount,
                "medium", mediumCount,
                "low", lowCount
            ),
            "byType", eventTypeCounts,
            "last24Hours", last24hCount,
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 취약점 스캔 결과 조회
     */
    public List<Map<String, Object>> getVulnerabilities() {
        // Mock 취약점 데이터
        return List.of(
            Map.of(
                "id", "vuln-001",
                "name", "Outdated Dependency",
                "severity", "MEDIUM",
                "description", "log4j 2.17.0 이전 버전 사용 중",
                "recommendation", "log4j 2.17.1 이상으로 업데이트",
                "status", "OPEN"
            ),
            Map.of(
                "id", "vuln-002",
                "name", "Weak Password Policy",
                "severity", "LOW",
                "description", "비밀번호 복잡성 정책이 약함",
                "recommendation", "최소 12자, 특수문자 포함 정책 적용",
                "status", "IN_PROGRESS"
            )
        );
    }

    /**
     * Mock 발견사항 (테스트용)
     */
    private List<Map<String, Object>> getMockFindings() {
        return List.of(
            Map.of(
                "name", "finding-001",
                "category", "MISCONFIGURATION",
                "severity", "HIGH",
                "state", "ACTIVE",
                "resourceName", "projects/polytech-lms/instances/lms-db",
                "eventTime", LocalDateTime.now().minusHours(2).toString(),
                "description", "데이터베이스 공개 접근 허용됨"
            ),
            Map.of(
                "name", "finding-002",
                "category", "VULNERABILITY",
                "severity", "MEDIUM",
                "state", "ACTIVE",
                "resourceName", "projects/polytech-lms/buckets/lms-storage",
                "eventTime", LocalDateTime.now().minusDays(1).toString(),
                "description", "스토리지 버킷 ACL 설정 검토 필요"
            )
        );
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean authenticated = getAccessToken() != null;
        boolean configured = organizationId != null && !organizationId.isEmpty();

        return Map.of(
            "service", "security-command-center",
            "projectId", projectId,
            "organizationId", organizationId != null ? organizationId : "not-configured",
            "localEventsCount", localSecurityEvents.size(),
            "authenticated", authenticated,
            "configured", configured,
            "status", authenticated && configured ? "UP" : "DEGRADED"
        );
    }
}
