// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/layer/InfrastructureLayer.java
package kr.polytech.lms.gcp.layer;

import kr.polytech.lms.gcp.service.GoogleIdentityService;
import kr.polytech.lms.gcp.service.BigQueryService;
import kr.polytech.lms.session.service.SessionManagementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Infrastructure Layer
 * 데이터 및 인증 계층 - Identity Platform, Cloud Logging
 *
 * 역할:
 * - 사용자 인증/인가 (Google Identity Platform)
 * - 중앙 집중식 로깅 (Cloud Logging)
 * - 세션 관리
 * - 감사 로그 (Cloud Audit Logs)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class InfrastructureLayer {

    private final GoogleIdentityService identityService;
    private final SessionManagementService sessionService;
    private final BigQueryService bigQueryService;

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    // 로그 버퍼 (Cloud Logging 전송 전)
    private final List<LogEntry> logBuffer = Collections.synchronizedList(new ArrayList<>());

    // 감사 로그 캐시
    private final Map<String, List<AuditEvent>> auditCache = new ConcurrentHashMap<>();

    /**
     * 사용자 인증 (Google Identity Platform)
     */
    public Map<String, Object> authenticateUser(String idToken) {
        log.info("Infrastructure Layer: 사용자 인증");

        Map<String, Object> verifyResult = identityService.verifyIdToken(idToken);

        if ((boolean) verifyResult.getOrDefault("valid", false)) {
            // 세션 생성
            String userId = (String) verifyResult.get("userId");

            // 감사 로그 기록
            recordAuditEvent(userId, "USER_LOGIN", "사용자 로그인 성공", null);

            return Map.of(
                "authenticated", true,
                "userId", userId,
                "email", verifyResult.get("email"),
                "provider", "Google Identity Platform",
                "timestamp", LocalDateTime.now().toString()
            );
        }

        return Map.of(
            "authenticated", false,
            "error", verifyResult.getOrDefault("error", "인증 실패"),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 토큰 갱신
     */
    public Map<String, Object> refreshToken(String refreshToken) {
        return identityService.refreshAccessToken(refreshToken);
    }

    /**
     * 세션 생성
     */
    public Map<String, Object> createSession(String userId, String deviceInfo,
            String ipAddress, String userAgent) {

        SessionManagementService.SessionCreationResult result =
            sessionService.createSession(userId, deviceInfo, ipAddress, userAgent);

        if (result.success) {
            recordAuditEvent(userId, "SESSION_CREATED",
                "세션 생성: " + result.sessionId, ipAddress);

            return Map.of(
                "success", true,
                "sessionId", result.sessionId,
                "message", "세션이 생성되었습니다."
            );
        }

        return Map.of(
            "success", false,
            "error", result.errorMessage
        );
    }

    /**
     * 세션 검증
     */
    public Map<String, Object> validateSession(String sessionId) {
        SessionManagementService.SessionValidationResult result =
            sessionService.validateSession(sessionId);

        if (result.valid) {
            return Map.of(
                "valid", true,
                "userId", result.session.userId
            );
        }

        return Map.of(
            "valid", false,
            "error", result.message,
            "blocked", result.blocked,
            "expired", result.expired
        );
    }

    /**
     * 로그 기록 (Cloud Logging)
     */
    public void writeLog(String severity, String source, String message,
            Map<String, Object> labels) {

        LogEntry entry = new LogEntry(
            severity,
            source,
            message,
            labels,
            LocalDateTime.now()
        );

        logBuffer.add(entry);

        // 버퍼가 100개 이상이면 Cloud Logging으로 전송
        if (logBuffer.size() >= 100) {
            flushLogs();
        }

        log.debug("Infrastructure Layer: 로그 기록 - severity={}, source={}", severity, source);
    }

    /**
     * 로그 플러시 (Cloud Logging 전송)
     */
    public void flushLogs() {
        if (logBuffer.isEmpty()) return;

        List<LogEntry> toFlush = new ArrayList<>(logBuffer);
        logBuffer.clear();

        // Cloud Logging API 호출 (시뮬레이션)
        log.info("Infrastructure Layer: Cloud Logging으로 {}개 로그 전송", toFlush.size());

        // BigQuery에도 기록 (장기 보존)
        for (LogEntry entry : toFlush) {
            bigQueryService.insertAnalyticsEvent("system_log", Map.of(
                "severity", entry.severity,
                "source", entry.source,
                "message", entry.message,
                "timestamp", entry.timestamp.toString()
            ));
        }
    }

    /**
     * 감사 이벤트 기록 (Cloud Audit Logs)
     */
    public void recordAuditEvent(String userId, String action, String description,
            String ipAddress) {

        AuditEvent event = new AuditEvent(
            UUID.randomUUID().toString(),
            userId,
            action,
            description,
            ipAddress,
            LocalDateTime.now()
        );

        auditCache.computeIfAbsent(userId, k -> new ArrayList<>()).add(event);

        // BigQuery에 영구 보관
        bigQueryService.insertAnalyticsEvent("audit_log", Map.of(
            "eventId", event.eventId,
            "userId", event.userId,
            "action", event.action,
            "description", event.description,
            "ipAddress", event.ipAddress != null ? event.ipAddress : "N/A",
            "timestamp", event.timestamp.toString()
        ));

        log.info("Infrastructure Layer: 감사 로그 기록 - user={}, action={}",
            userId, action);
    }

    /**
     * 사용자 감사 이벤트 조회
     */
    public List<Map<String, Object>> getAuditEvents(String userId, int limit) {
        List<AuditEvent> events = auditCache.getOrDefault(userId, List.of());

        return events.stream()
            .sorted((a, b) -> b.timestamp.compareTo(a.timestamp))
            .limit(limit)
            .map(e -> Map.<String, Object>of(
                "eventId", e.eventId,
                "action", e.action,
                "description", e.description,
                "timestamp", e.timestamp.toString()
            ))
            .toList();
    }

    /**
     * 인프라 상태 모니터링
     */
    public Map<String, Object> getInfrastructureStatus() {
        return Map.of(
            "identityPlatform", identityService.healthCheck(),
            "sessionManagement", sessionService.getSessionStatistics(),
            "logging", Map.of(
                "bufferSize", logBuffer.size(),
                "status", "ACTIVE"
            ),
            "auditLogs", Map.of(
                "totalUsers", auditCache.size(),
                "totalEvents", auditCache.values().stream()
                    .mapToInt(List::size).sum(),
                "status", "ACTIVE"
            )
        );
    }

    /**
     * 레이어 상태
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "layer", "Infrastructure Layer",
            "role", "데이터 및 인증 (Data & Authentication)",
            "services", List.of(
                Map.of("name", "Google Identity Platform", "status", "ACTIVE",
                    "purpose", "사용자 인증/인가"),
                Map.of("name", "Cloud Logging", "status", "ACTIVE",
                    "purpose", "중앙 집중식 로깅"),
                Map.of("name", "Cloud Audit Logs", "status", "ACTIVE",
                    "purpose", "감사 로그"),
                Map.of("name", "Session Management", "status", "ACTIVE",
                    "purpose", "세션 관리")
            ),
            "projectId", projectId,
            "status", "ACTIVE"
        );
    }

    /**
     * 로그 엔트리 레코드
     */
    private record LogEntry(
        String severity,
        String source,
        String message,
        Map<String, Object> labels,
        LocalDateTime timestamp
    ) {}

    /**
     * 감사 이벤트 레코드
     */
    private record AuditEvent(
        String eventId,
        String userId,
        String action,
        String description,
        String ipAddress,
        LocalDateTime timestamp
    ) {}
}
