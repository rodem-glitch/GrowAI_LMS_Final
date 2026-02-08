// polytech-lms-api/src/main/java/kr/polytech/lms/security/filter/SqlInjectionFilter.java
package kr.polytech.lms.security.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.regex.Pattern;

/**
 * SQL Injection 방지 필터
 * 행안부 시큐어코딩 가이드 준수
 */
@Slf4j
@Component
@Order(3)
public class SqlInjectionFilter implements Filter {

    // SQL Injection 공격 패턴
    private static final Pattern[] SQL_PATTERNS = {
        // UNION 기반 공격
        Pattern.compile("(?i).*\\bUNION\\b.*\\bSELECT\\b.*"),
        // 주석 기반 공격
        Pattern.compile(".*--.*"),
        Pattern.compile(".*/\\*.*\\*/.*"),
        // Boolean 기반 공격
        Pattern.compile("(?i).*\\bOR\\b.*=.*"),
        Pattern.compile("(?i).*\\bAND\\b.*=.*"),
        // 시간 기반 공격
        Pattern.compile("(?i).*\\bSLEEP\\b.*\\(.*\\).*"),
        Pattern.compile("(?i).*\\bBENCHMARK\\b.*\\(.*\\).*"),
        Pattern.compile("(?i).*\\bWAITFOR\\b.*\\bDELAY\\b.*"),
        // 스택 쿼리
        Pattern.compile(".*;\\s*DROP\\b.*", Pattern.CASE_INSENSITIVE),
        Pattern.compile(".*;\\s*DELETE\\b.*", Pattern.CASE_INSENSITIVE),
        Pattern.compile(".*;\\s*UPDATE\\b.*", Pattern.CASE_INSENSITIVE),
        Pattern.compile(".*;\\s*INSERT\\b.*", Pattern.CASE_INSENSITIVE),
        // 정보 수집
        Pattern.compile("(?i).*\\bINFORMATION_SCHEMA\\b.*"),
        Pattern.compile("(?i).*\\bSYSOBJECTS\\b.*"),
        Pattern.compile("(?i).*\\bSYSCOLUMNS\\b.*")
    };

    // 허용되는 SQL 키워드 (검색 필드에서 사용 가능)
    private static final String[] ALLOWED_CONTEXTS = {
        "search", "keyword", "query", "q"
    };

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // 모든 파라미터 검사
        java.util.Enumeration<String> paramNames = httpRequest.getParameterNames();
        while (paramNames.hasMoreElements()) {
            String paramName = paramNames.nextElement();
            String[] values = httpRequest.getParameterValues(paramName);

            if (values != null) {
                for (String value : values) {
                    if (detectSqlInjection(value, paramName)) {
                        log.warn("SQL Injection 시도 감지: param={}, value={}, IP={}",
                            paramName, truncate(value, 100), getClientIp(httpRequest));

                        httpResponse.setStatus(400);
                        httpResponse.setContentType("application/json");
                        httpResponse.getWriter().write("{\"error\":\"Invalid request parameters\"}");
                        return;
                    }
                }
            }
        }

        chain.doFilter(request, response);
    }

    private boolean detectSqlInjection(String value, String paramName) {
        if (value == null || value.isEmpty()) {
            return false;
        }

        // 검색 필드는 일부 패턴 허용
        boolean isSearchField = false;
        for (String context : ALLOWED_CONTEXTS) {
            if (paramName.toLowerCase().contains(context)) {
                isSearchField = true;
                break;
            }
        }

        // SQL 패턴 검사
        for (Pattern pattern : SQL_PATTERNS) {
            if (pattern.matcher(value).matches()) {
                // 검색 필드에서 OR/AND는 허용
                if (isSearchField && (pattern.pattern().contains("OR") || pattern.pattern().contains("AND"))) {
                    continue;
                }
                return true;
            }
        }

        return false;
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String truncate(String value, int maxLength) {
        if (value == null) return null;
        return value.length() > maxLength ? value.substring(0, maxLength) + "..." : value;
    }
}
