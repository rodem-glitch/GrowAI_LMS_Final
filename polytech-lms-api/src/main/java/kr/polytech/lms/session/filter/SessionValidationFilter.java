// polytech-lms-api/src/main/java/kr/polytech/lms/session/filter/SessionValidationFilter.java
package kr.polytech.lms.session.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.session.service.SessionManagementService;
import kr.polytech.lms.session.service.SessionManagementService.SessionValidationResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Session Validation Filter
 * 모든 보호된 요청에 대해 세션 유효성 검증
 */
@Slf4j
@Component
@Order(2)
@RequiredArgsConstructor
public class SessionValidationFilter implements Filter {

    private final SessionManagementService sessionService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 세션 검증 제외 경로
    private static final List<String> EXCLUDED_PATHS = List.of(
        "/api/session/create",
        "/api/session/validate",
        "/api/auth/login",
        "/api/auth/register",
        "/api/auth/oauth2",
        "/api/public/",
        "/health",
        "/actuator"
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
            FilterChain chain) throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = httpRequest.getRequestURI();

        // 제외 경로 확인
        if (isExcludedPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        // 세션 ID 추출
        String sessionId = extractSessionId(httpRequest);

        if (sessionId == null) {
            // Authorization 헤더의 Bearer 토큰 확인 (JWT 사용 시)
            String authHeader = httpRequest.getHeader("Authorization");
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                // JWT 토큰은 다른 필터에서 처리
                chain.doFilter(request, response);
                return;
            }

            sendUnauthorizedResponse(httpResponse, "세션 ID가 필요합니다.", "NO_SESSION");
            return;
        }

        // 세션 검증
        SessionValidationResult result = sessionService.validateSession(sessionId);

        if (!result.valid) {
            String code = result.blocked ? "SESSION_BLOCKED" :
                         (result.expired ? "SESSION_EXPIRED" : "SESSION_INVALID");
            sendUnauthorizedResponse(httpResponse, result.message, code);
            return;
        }

        // 요청에 사용자 정보 추가
        httpRequest.setAttribute("userId", result.session.userId);
        httpRequest.setAttribute("sessionId", sessionId);

        chain.doFilter(request, response);
    }

    /**
     * 세션 ID 추출 (헤더 또는 쿠키)
     */
    private String extractSessionId(HttpServletRequest request) {
        // 1. X-Session-Id 헤더에서 확인
        String sessionId = request.getHeader("X-Session-Id");
        if (sessionId != null && !sessionId.isEmpty()) {
            return sessionId;
        }

        // 2. 쿠키에서 확인
        if (request.getCookies() != null) {
            for (jakarta.servlet.http.Cookie cookie : request.getCookies()) {
                if ("SESSION_ID".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }

        // 3. 쿼리 파라미터에서 확인 (비권장)
        sessionId = request.getParameter("sessionId");
        if (sessionId != null && !sessionId.isEmpty()) {
            log.warn("세션 ID가 쿼리 파라미터로 전달됨 - 보안 권장사항 위반");
            return sessionId;
        }

        return null;
    }

    /**
     * 제외 경로 확인
     */
    private boolean isExcludedPath(String path) {
        return EXCLUDED_PATHS.stream()
            .anyMatch(excluded -> path.startsWith(excluded) || path.equals(excluded));
    }

    /**
     * 인증 실패 응답 전송
     */
    private void sendUnauthorizedResponse(HttpServletResponse response,
            String message, String code) throws IOException {

        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");

        Map<String, Object> errorResponse = Map.of(
            "success", false,
            "error", message,
            "code", code,
            "timestamp", System.currentTimeMillis()
        );

        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }
}
