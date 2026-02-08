// polytech-lms-api/src/main/java/kr/polytech/lms/session/service/SessionManagementService.java
package kr.polytech.lms.session.service;

import kr.polytech.lms.gcp.service.BigQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Session Management Service
 * Google Identity Platform 연동 세션 관리
 *
 * 기능:
 * - Concurrent Session Control (동시 세션 제어)
 * - Session Timeout Management
 * - Forced Logout (강제 로그아웃)
 * - Session Audit Logging (Cloud Audit Logs + BigQuery)
 * - SAML 2.0 통합 세션 관리
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SessionManagementService {

    private final BigQueryService bigQueryService;

    // 활성 세션 저장소
    private final Map<String, UserSession> activeSessions = new ConcurrentHashMap<>();

    // 사용자별 세션 매핑 (userId -> Set<sessionId>)
    private final Map<String, Set<String>> userSessions = new ConcurrentHashMap<>();

    // 차단된 세션
    private final Set<String> blockedSessions = ConcurrentHashMap.newKeySet();

    // 설정값
    @Value("${session.max-concurrent:1}")
    private int maxConcurrentSessions;

    @Value("${session.timeout-minutes:30}")
    private int sessionTimeoutMinutes;

    @Value("${session.absolute-timeout-hours:8}")
    private int absoluteTimeoutHours;

    @Value("${session.policy:LAST_IN_WINS}")
    private String sessionPolicy; // FIRST_IN_WINS, LAST_IN_WINS, DENY_NEW

    /**
     * 세션 타임아웃 체크 (1분마다)
     */
    @Scheduled(fixedRate = 60000)
    public void checkSessionTimeouts() {
        log.debug("Session Manager: 세션 타임아웃 체크");

        LocalDateTime now = LocalDateTime.now();
        List<String> expiredSessions = new ArrayList<>();

        for (Map.Entry<String, UserSession> entry : activeSessions.entrySet()) {
            UserSession session = entry.getValue();

            // 유휴 타임아웃 체크
            long idleMinutes = ChronoUnit.MINUTES.between(session.lastActivity, now);
            if (idleMinutes > sessionTimeoutMinutes) {
                expiredSessions.add(entry.getKey());
                log.info("Session expired (idle): sessionId={}, userId={}",
                    session.sessionId, session.userId);
            }

            // 절대 타임아웃 체크
            long totalHours = ChronoUnit.HOURS.between(session.createdAt, now);
            if (totalHours > absoluteTimeoutHours) {
                expiredSessions.add(entry.getKey());
                log.info("Session expired (absolute): sessionId={}, userId={}",
                    session.sessionId, session.userId);
            }
        }

        // 만료된 세션 제거
        for (String sessionId : expiredSessions) {
            terminateSession(sessionId, "SESSION_TIMEOUT");
        }
    }

    /**
     * 세션 생성 (로그인 시)
     * 동시 세션 제어 정책 적용
     */
    public SessionCreationResult createSession(String userId, String deviceInfo,
            String ipAddress, String userAgent) {

        log.info("Session creation request: userId={}, ip={}", userId, ipAddress);

        // 기존 활성 세션 확인
        Set<String> existingSessions = userSessions.getOrDefault(userId, new HashSet<>());
        int activeCount = existingSessions.size();

        // 동시 세션 제어 정책 적용
        if (activeCount >= maxConcurrentSessions) {
            return handleConcurrentSessionLimit(userId, existingSessions, deviceInfo, ipAddress, userAgent);
        }

        // 새 세션 생성
        return createNewSession(userId, deviceInfo, ipAddress, userAgent);
    }

    /**
     * 동시 세션 제한 처리
     */
    private SessionCreationResult handleConcurrentSessionLimit(String userId,
            Set<String> existingSessions, String deviceInfo, String ipAddress, String userAgent) {

        log.warn("Concurrent session limit reached: userId={}, activeCount={}, policy={}",
            userId, existingSessions.size(), sessionPolicy);

        switch (sessionPolicy) {
            case "FIRST_IN_WINS":
                // 선입자 우선: 새 로그인 거부
                logSessionEvent(userId, null, "SESSION_DENIED",
                    "다른 기기에서 이미 로그인되어 있습니다.", ipAddress);
                return SessionCreationResult.denied(
                    "이미 다른 기기에서 로그인되어 있습니다. 기존 세션을 종료하고 다시 시도해주세요."
                );

            case "LAST_IN_WINS":
                // 후입자 우선: 기존 세션 모두 종료
                for (String oldSessionId : existingSessions) {
                    terminateSession(oldSessionId, "FORCED_LOGOUT_NEW_LOGIN");
                }
                return createNewSession(userId, deviceInfo, ipAddress, userAgent);

            case "DENY_NEW":
            default:
                // 신규 차단: 새 로그인 거부
                logSessionEvent(userId, null, "SESSION_DENIED",
                    "동시 접속 제한 초과", ipAddress);
                return SessionCreationResult.denied(
                    String.format("동시 접속 제한(%d대)을 초과했습니다.", maxConcurrentSessions)
                );
        }
    }

    /**
     * 새 세션 생성
     */
    private SessionCreationResult createNewSession(String userId, String deviceInfo,
            String ipAddress, String userAgent) {

        String sessionId = generateSessionId();
        LocalDateTime now = LocalDateTime.now();

        UserSession session = new UserSession(
            sessionId,
            userId,
            deviceInfo,
            ipAddress,
            userAgent,
            now,
            now
        );

        // 세션 저장
        activeSessions.put(sessionId, session);
        userSessions.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(sessionId);

        // 감사 로그
        logSessionEvent(userId, sessionId, "SESSION_CREATED", "세션 생성 성공", ipAddress);

        log.info("Session created: sessionId={}, userId={}, ip={}", sessionId, userId, ipAddress);

        return SessionCreationResult.success(sessionId, session);
    }

    /**
     * 세션 검증 (요청마다)
     */
    public SessionValidationResult validateSession(String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return SessionValidationResult.invalid("세션 ID가 없습니다.");
        }

        // 차단된 세션 확인
        if (blockedSessions.contains(sessionId)) {
            return SessionValidationResult.blocked("세션이 차단되었습니다.");
        }

        UserSession session = activeSessions.get(sessionId);
        if (session == null) {
            return SessionValidationResult.invalid("세션이 존재하지 않습니다.");
        }

        LocalDateTime now = LocalDateTime.now();

        // 유휴 타임아웃 확인
        long idleMinutes = ChronoUnit.MINUTES.between(session.lastActivity, now);
        if (idleMinutes > sessionTimeoutMinutes) {
            terminateSession(sessionId, "IDLE_TIMEOUT");
            return SessionValidationResult.expired("세션이 만료되었습니다. 다시 로그인해주세요.");
        }

        // 절대 타임아웃 확인
        long totalHours = ChronoUnit.HOURS.between(session.createdAt, now);
        if (totalHours > absoluteTimeoutHours) {
            terminateSession(sessionId, "ABSOLUTE_TIMEOUT");
            return SessionValidationResult.expired("세션 유효 시간이 초과되었습니다.");
        }

        // 세션 활동 시간 갱신
        session.lastActivity = now;

        return SessionValidationResult.valid(session);
    }

    /**
     * 세션 종료 (로그아웃)
     */
    public void terminateSession(String sessionId, String reason) {
        UserSession session = activeSessions.remove(sessionId);

        if (session != null) {
            // 사용자 세션 매핑에서 제거
            Set<String> sessions = userSessions.get(session.userId);
            if (sessions != null) {
                sessions.remove(sessionId);
                if (sessions.isEmpty()) {
                    userSessions.remove(session.userId);
                }
            }

            // 감사 로그
            logSessionEvent(session.userId, sessionId, "SESSION_TERMINATED", reason, session.ipAddress);

            log.info("Session terminated: sessionId={}, userId={}, reason={}",
                sessionId, session.userId, reason);
        }
    }

    /**
     * 강제 로그아웃 (관리자/보안 이벤트)
     */
    public void forceLogout(String userId, String reason) {
        log.warn("Force logout initiated: userId={}, reason={}", userId, reason);

        Set<String> sessions = userSessions.get(userId);
        if (sessions != null) {
            for (String sessionId : new HashSet<>(sessions)) {
                terminateSession(sessionId, "FORCED_LOGOUT: " + reason);
            }
        }

        logSessionEvent(userId, null, "FORCE_LOGOUT", reason, null);
    }

    /**
     * 전체 세션 강제 종료 (긴급 상황)
     */
    public int forceLogoutAll(String reason) {
        log.error("EMERGENCY: Force logout all sessions - reason={}", reason);

        int count = activeSessions.size();

        for (String sessionId : new HashSet<>(activeSessions.keySet())) {
            terminateSession(sessionId, "EMERGENCY_LOGOUT: " + reason);
        }

        logSessionEvent("SYSTEM", null, "EMERGENCY_LOGOUT_ALL", reason, null);

        return count;
    }

    /**
     * 세션 차단 (보안 위협 감지 시)
     */
    public void blockSession(String sessionId, String reason) {
        blockedSessions.add(sessionId);
        terminateSession(sessionId, "BLOCKED: " + reason);

        log.warn("Session blocked: sessionId={}, reason={}", sessionId, reason);
    }

    /**
     * 세션 ID 생성
     */
    private String generateSessionId() {
        return UUID.randomUUID().toString().replace("-", "") +
               Long.toHexString(System.currentTimeMillis());
    }

    /**
     * 세션 이벤트 로깅 (Cloud Audit Logs + BigQuery)
     */
    private void logSessionEvent(String userId, String sessionId, String eventType,
            String description, String ipAddress) {

        Map<String, Object> eventData = new HashMap<>();
        eventData.put("user_id", userId);
        eventData.put("session_id", sessionId != null ? sessionId : "N/A");
        eventData.put("event_type", eventType);
        eventData.put("description", description);
        eventData.put("ip_address", ipAddress != null ? ipAddress : "N/A");
        eventData.put("timestamp", LocalDateTime.now().toString());

        // BigQuery에 영구 보관
        bigQueryService.insertAnalyticsEvent("session_event", eventData);

        log.debug("Session event logged: type={}, userId={}", eventType, userId);
    }

    /**
     * 사용자의 활성 세션 목록 조회
     */
    public List<Map<String, Object>> getUserActiveSessions(String userId) {
        Set<String> sessionIds = userSessions.getOrDefault(userId, Set.of());

        return sessionIds.stream()
            .map(activeSessions::get)
            .filter(Objects::nonNull)
            .map(session -> {
                Map<String, Object> info = new HashMap<>();
                info.put("sessionId", session.sessionId);
                info.put("deviceInfo", session.deviceInfo);
                info.put("ipAddress", session.ipAddress);
                info.put("createdAt", session.createdAt.toString());
                info.put("lastActivity", session.lastActivity.toString());
                return info;
            })
            .collect(Collectors.toList());
    }

    /**
     * 특정 세션 종료 (사용자 요청)
     */
    public boolean terminateUserSession(String userId, String targetSessionId) {
        Set<String> sessions = userSessions.get(userId);
        if (sessions != null && sessions.contains(targetSessionId)) {
            terminateSession(targetSessionId, "USER_REQUESTED");
            return true;
        }
        return false;
    }

    /**
     * 모든 다른 세션 종료 (현재 세션 유지)
     */
    public int terminateOtherSessions(String userId, String currentSessionId) {
        Set<String> sessions = userSessions.get(userId);
        if (sessions == null) return 0;

        int count = 0;
        for (String sessionId : new HashSet<>(sessions)) {
            if (!sessionId.equals(currentSessionId)) {
                terminateSession(sessionId, "USER_LOGOUT_OTHERS");
                count++;
            }
        }
        return count;
    }

    /**
     * 세션 통계 조회
     */
    public Map<String, Object> getSessionStatistics() {
        int totalSessions = activeSessions.size();
        int totalUsers = userSessions.size();

        // 세션 연령 분석
        LocalDateTime now = LocalDateTime.now();
        long recentSessions = activeSessions.values().stream()
            .filter(s -> ChronoUnit.MINUTES.between(s.createdAt, now) < 30)
            .count();

        return Map.of(
            "totalActiveSessions", totalSessions,
            "totalActiveUsers", totalUsers,
            "recentSessions", recentSessions,
            "blockedSessions", blockedSessions.size(),
            "maxConcurrentAllowed", maxConcurrentSessions,
            "sessionPolicy", sessionPolicy,
            "timeoutMinutes", sessionTimeoutMinutes,
            "absoluteTimeoutHours", absoluteTimeoutHours
        );
    }

    /**
     * 서비스 상태 조회
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "service", "SessionManagementService",
            "role", "Concurrent Session Control + Session Management API",
            "features", List.of(
                "동시 세션 제어 (Concurrent Session Control)",
                "세션 타임아웃 관리",
                "강제 로그아웃 (Forced Logout)",
                "세션 감사 로깅 (Cloud Audit Logs + BigQuery)",
                "SAML 2.0 통합"
            ),
            "policy", sessionPolicy,
            "maxConcurrent", maxConcurrentSessions,
            "activeSessions", activeSessions.size(),
            "activeUsers", userSessions.size(),
            "status", "ACTIVE"
        );
    }

    /**
     * 사용자 세션 레코드
     */
    public static class UserSession {
        public final String sessionId;
        public final String userId;
        public final String deviceInfo;
        public final String ipAddress;
        public final String userAgent;
        public final LocalDateTime createdAt;
        public LocalDateTime lastActivity;

        public UserSession(String sessionId, String userId, String deviceInfo,
                String ipAddress, String userAgent, LocalDateTime createdAt,
                LocalDateTime lastActivity) {
            this.sessionId = sessionId;
            this.userId = userId;
            this.deviceInfo = deviceInfo;
            this.ipAddress = ipAddress;
            this.userAgent = userAgent;
            this.createdAt = createdAt;
            this.lastActivity = lastActivity;
        }
    }

    /**
     * 세션 생성 결과
     */
    public static class SessionCreationResult {
        public final boolean success;
        public final String sessionId;
        public final UserSession session;
        public final String errorMessage;

        private SessionCreationResult(boolean success, String sessionId,
                UserSession session, String errorMessage) {
            this.success = success;
            this.sessionId = sessionId;
            this.session = session;
            this.errorMessage = errorMessage;
        }

        public static SessionCreationResult success(String sessionId, UserSession session) {
            return new SessionCreationResult(true, sessionId, session, null);
        }

        public static SessionCreationResult denied(String message) {
            return new SessionCreationResult(false, null, null, message);
        }
    }

    /**
     * 세션 검증 결과
     */
    public static class SessionValidationResult {
        public final boolean valid;
        public final boolean blocked;
        public final boolean expired;
        public final UserSession session;
        public final String message;

        private SessionValidationResult(boolean valid, boolean blocked, boolean expired,
                UserSession session, String message) {
            this.valid = valid;
            this.blocked = blocked;
            this.expired = expired;
            this.session = session;
            this.message = message;
        }

        public static SessionValidationResult valid(UserSession session) {
            return new SessionValidationResult(true, false, false, session, null);
        }

        public static SessionValidationResult invalid(String message) {
            return new SessionValidationResult(false, false, false, null, message);
        }

        public static SessionValidationResult blocked(String message) {
            return new SessionValidationResult(false, true, false, null, message);
        }

        public static SessionValidationResult expired(String message) {
            return new SessionValidationResult(false, false, true, null, message);
        }
    }
}
