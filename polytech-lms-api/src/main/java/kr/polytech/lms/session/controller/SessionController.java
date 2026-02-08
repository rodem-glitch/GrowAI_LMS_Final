// polytech-lms-api/src/main/java/kr/polytech/lms/session/controller/SessionController.java
package kr.polytech.lms.session.controller;

import kr.polytech.lms.session.service.SessionManagementService;
import kr.polytech.lms.session.service.SessionManagementService.SessionCreationResult;
import kr.polytech.lms.session.service.SessionManagementService.SessionValidationResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.*;

/**
 * Session Management REST Controller
 * Google Identity Platform 연동 세션 관리 API
 *
 * 기능:
 * - 세션 생성/검증/종료
 * - 동시 세션 제어
 * - 강제 로그아웃
 * - 세션 목록 조회
 */
@Slf4j
@RestController
@RequestMapping("/api/session")
@RequiredArgsConstructor
public class SessionController {

    private final SessionManagementService sessionService;

    /**
     * 세션 생성 (로그인 후 호출)
     */
    @PostMapping("/create")
    public ResponseEntity<?> createSession(
            @RequestBody Map<String, String> request,
            HttpServletRequest httpRequest) {

        String userId = request.get("userId");
        String deviceInfo = request.getOrDefault("deviceInfo", "Unknown Device");

        if (userId == null || userId.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(Map.of("success", false, "error", "userId is required"));
        }

        String ipAddress = getClientIpAddress(httpRequest);
        String userAgent = httpRequest.getHeader("User-Agent");

        SessionCreationResult result = sessionService.createSession(
            userId, deviceInfo, ipAddress, userAgent
        );

        if (result.success) {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "sessionId", result.sessionId,
                "message", "세션이 생성되었습니다."
            ));
        } else {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of(
                    "success", false,
                    "error", result.errorMessage,
                    "code", "CONCURRENT_SESSION_LIMIT"
                ));
        }
    }

    /**
     * 세션 검증
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateSession(@RequestBody Map<String, String> request) {
        String sessionId = request.get("sessionId");

        SessionValidationResult result = sessionService.validateSession(sessionId);

        if (result.valid) {
            return ResponseEntity.ok(Map.of(
                "valid", true,
                "userId", result.session.userId,
                "message", "세션이 유효합니다."
            ));
        } else {
            HttpStatus status = result.expired ? HttpStatus.UNAUTHORIZED : HttpStatus.FORBIDDEN;
            String code = result.blocked ? "SESSION_BLOCKED" :
                         (result.expired ? "SESSION_EXPIRED" : "SESSION_INVALID");

            return ResponseEntity.status(status)
                .body(Map.of(
                    "valid", false,
                    "error", result.message,
                    "code", code
                ));
        }
    }

    /**
     * 세션 종료 (로그아웃)
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody Map<String, String> request) {
        String sessionId = request.get("sessionId");

        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(Map.of("success", false, "error", "sessionId is required"));
        }

        sessionService.terminateSession(sessionId, "USER_LOGOUT");

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "로그아웃되었습니다."
        ));
    }

    /**
     * 다른 모든 세션 로그아웃
     */
    @PostMapping("/logout-others")
    public ResponseEntity<?> logoutOtherSessions(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String currentSessionId = request.get("currentSessionId");

        if (userId == null || currentSessionId == null) {
            return ResponseEntity.badRequest()
                .body(Map.of("success", false, "error", "userId and currentSessionId are required"));
        }

        int terminatedCount = sessionService.terminateOtherSessions(userId, currentSessionId);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "terminatedSessions", terminatedCount,
            "message", String.format("%d개의 다른 세션이 종료되었습니다.", terminatedCount)
        ));
    }

    /**
     * 특정 세션 종료
     */
    @PostMapping("/terminate")
    public ResponseEntity<?> terminateSession(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String targetSessionId = request.get("targetSessionId");

        if (userId == null || targetSessionId == null) {
            return ResponseEntity.badRequest()
                .body(Map.of("success", false, "error", "userId and targetSessionId are required"));
        }

        boolean terminated = sessionService.terminateUserSession(userId, targetSessionId);

        if (terminated) {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "세션이 종료되었습니다."
            ));
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of(
                    "success", false,
                    "error", "해당 세션을 찾을 수 없습니다."
                ));
        }
    }

    /**
     * 사용자 활성 세션 목록 조회
     */
    @GetMapping("/active/{userId}")
    public ResponseEntity<?> getActiveSessions(@PathVariable String userId) {
        List<Map<String, Object>> sessions = sessionService.getUserActiveSessions(userId);

        return ResponseEntity.ok(Map.of(
            "userId", userId,
            "activeSessions", sessions,
            "count", sessions.size()
        ));
    }

    /**
     * 강제 로그아웃 (관리자 전용)
     */
    @PostMapping("/admin/force-logout")
    public ResponseEntity<?> forceLogout(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String reason = request.getOrDefault("reason", "관리자에 의한 강제 로그아웃");

        if (userId == null || userId.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(Map.of("success", false, "error", "userId is required"));
        }

        sessionService.forceLogout(userId, reason);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", String.format("사용자 %s의 모든 세션이 종료되었습니다.", userId)
        ));
    }

    /**
     * 전체 세션 강제 종료 (긴급 상황용)
     */
    @PostMapping("/admin/force-logout-all")
    public ResponseEntity<?> forceLogoutAll(@RequestBody Map<String, String> request) {
        String reason = request.getOrDefault("reason", "긴급 상황에 의한 전체 로그아웃");

        int count = sessionService.forceLogoutAll(reason);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "terminatedSessions", count,
            "message", String.format("전체 %d개의 세션이 종료되었습니다.", count)
        ));
    }

    /**
     * 세션 통계 조회 (관리자)
     */
    @GetMapping("/admin/statistics")
    public ResponseEntity<?> getSessionStatistics() {
        return ResponseEntity.ok(sessionService.getSessionStatistics());
    }

    /**
     * 서비스 상태 조회
     */
    @GetMapping("/status")
    public ResponseEntity<?> getStatus() {
        return ResponseEntity.ok(sessionService.getStatus());
    }

    /**
     * 클라이언트 IP 주소 추출
     */
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }

        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }

        return request.getRemoteAddr();
    }
}
