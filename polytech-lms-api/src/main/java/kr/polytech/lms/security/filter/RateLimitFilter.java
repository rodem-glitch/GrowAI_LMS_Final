// polytech-lms-api/src/main/java/kr/polytech/lms/security/filter/RateLimitFilter.java
package kr.polytech.lms.security.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * API Rate Limiting 필터
 * IP 기반 요청 제한으로 DDoS 방지
 */
@Slf4j
@Component
@Order(1)
public class RateLimitFilter implements Filter {

    // IP별 요청 카운터 (분 단위)
    private final Map<String, RateLimitInfo> requestCounts = new ConcurrentHashMap<>();

    // 분당 최대 요청 수
    private static final int MAX_REQUESTS_PER_MINUTE = 100;

    // 차단 시간 (분)
    private static final int BLOCK_DURATION_MINUTES = 5;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String clientIp = getClientIp(httpRequest);
        String path = httpRequest.getRequestURI();

        // 헬스체크, 메트릭은 제외
        if (path.startsWith("/actuator/") || path.startsWith("/api/public/")) {
            chain.doFilter(request, response);
            return;
        }

        RateLimitInfo info = requestCounts.computeIfAbsent(clientIp, k -> new RateLimitInfo());

        // 차단된 IP 확인
        if (info.isBlocked()) {
            log.warn("차단된 IP 접근 시도: {}", clientIp);
            httpResponse.setStatus(429);
            httpResponse.setContentType("application/json");
            httpResponse.getWriter().write("{\"error\":\"Too Many Requests\",\"retryAfter\":" + info.getBlockRemainingSeconds() + "}");
            return;
        }

        // 요청 카운트 증가
        int count = info.incrementAndGet();

        if (count > MAX_REQUESTS_PER_MINUTE) {
            info.block(BLOCK_DURATION_MINUTES);
            log.warn("Rate limit 초과로 IP 차단: {} (요청수: {})", clientIp, count);
            httpResponse.setStatus(429);
            httpResponse.setContentType("application/json");
            httpResponse.getWriter().write("{\"error\":\"Rate limit exceeded\",\"blocked\":true}");
            return;
        }

        // Rate Limit 헤더 추가
        httpResponse.setHeader("X-RateLimit-Limit", String.valueOf(MAX_REQUESTS_PER_MINUTE));
        httpResponse.setHeader("X-RateLimit-Remaining", String.valueOf(MAX_REQUESTS_PER_MINUTE - count));

        chain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
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

    /**
     * Rate Limit 정보 클래스
     */
    private static class RateLimitInfo {
        private final AtomicInteger count = new AtomicInteger(0);
        private long windowStart = System.currentTimeMillis();
        private long blockedUntil = 0;

        public synchronized int incrementAndGet() {
            long now = System.currentTimeMillis();
            // 1분 윈도우 리셋
            if (now - windowStart > 60_000) {
                count.set(0);
                windowStart = now;
            }
            return count.incrementAndGet();
        }

        public boolean isBlocked() {
            return System.currentTimeMillis() < blockedUntil;
        }

        public void block(int minutes) {
            blockedUntil = System.currentTimeMillis() + (minutes * 60_000L);
        }

        public long getBlockRemainingSeconds() {
            return Math.max(0, (blockedUntil - System.currentTimeMillis()) / 1000);
        }
    }
}
