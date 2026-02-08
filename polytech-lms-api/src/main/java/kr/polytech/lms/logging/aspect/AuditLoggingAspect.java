// polytech-lms-api/src/main/java/kr/polytech/lms/logging/aspect/AuditLoggingAspect.java
package kr.polytech.lms.logging.aspect;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;

/**
 * 감사 로깅 AOP
 * 중요 API 호출 기록 및 성능 모니터링
 */
@Slf4j
@Aspect
@Component
@RequiredArgsConstructor
public class AuditLoggingAspect {

    private final JdbcTemplate jdbcTemplate;

    /**
     * 모든 Controller 메서드 로깅
     */
    @Around("execution(* kr.polytech.lms..controller..*(..))")
    public Object logControllerMethods(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String className = signature.getDeclaringType().getSimpleName();
        String methodName = signature.getName();

        // 요청 정보 추출
        HttpServletRequest request = getCurrentRequest();
        String clientIp = getClientIp(request);
        String requestUri = request != null ? request.getRequestURI() : "unknown";
        String httpMethod = request != null ? request.getMethod() : "unknown";

        try {
            Object result = joinPoint.proceed();

            long duration = System.currentTimeMillis() - startTime;

            // 성능 로그
            if (duration > 1000) {
                log.warn("SLOW API: {}.{} - {}ms [{}] {}",
                    className, methodName, duration, httpMethod, requestUri);
            } else {
                log.info("API: {}.{} - {}ms [{}] {}",
                    className, methodName, duration, httpMethod, requestUri);
            }

            // 감사 로그 저장 (비동기로 처리 권장)
            saveAuditLog(className, methodName, httpMethod, requestUri, clientIp, duration, "SUCCESS");

            return result;

        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("API ERROR: {}.{} - {}ms [{}] {} - {}",
                className, methodName, duration, httpMethod, requestUri, e.getMessage());

            saveAuditLog(className, methodName, httpMethod, requestUri, clientIp, duration, "ERROR: " + e.getMessage());

            throw e;
        }
    }

    /**
     * 서비스 레이어 성능 모니터링
     */
    @Around("execution(* kr.polytech.lms..service..*(..))")
    public Object logServiceMethods(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String className = signature.getDeclaringType().getSimpleName();
        String methodName = signature.getName();

        try {
            Object result = joinPoint.proceed();

            long duration = System.currentTimeMillis() - startTime;
            if (duration > 500) {
                log.warn("SLOW SERVICE: {}.{} - {}ms", className, methodName, duration);
            }

            return result;

        } catch (Exception e) {
            log.error("SERVICE ERROR: {}.{} - {}", className, methodName, e.getMessage());
            throw e;
        }
    }

    private HttpServletRequest getCurrentRequest() {
        try {
            ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attrs != null ? attrs.getRequest() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String getClientIp(HttpServletRequest request) {
        if (request == null) return "unknown";

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

    private void saveAuditLog(String className, String methodName, String httpMethod,
                               String requestUri, String clientIp, long duration, String result) {
        try {
            // 민감 정보 필터링
            String sanitizedUri = requestUri.replaceAll("password=[^&]*", "password=***")
                                            .replaceAll("token=[^&]*", "token=***");

            jdbcTemplate.update(
                """
                INSERT INTO TB_AUDIT_LOG (class_name, method_name, http_method, request_uri,
                    client_ip, duration_ms, result, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                className, methodName, httpMethod, sanitizedUri,
                clientIp, duration, result.length() > 200 ? result.substring(0, 200) : result,
                LocalDateTime.now()
            );
        } catch (Exception e) {
            // 감사 로그 저장 실패 시 경고만 출력 (서비스 중단 방지)
            log.debug("감사 로그 저장 실패: {}", e.getMessage());
        }
    }
}
