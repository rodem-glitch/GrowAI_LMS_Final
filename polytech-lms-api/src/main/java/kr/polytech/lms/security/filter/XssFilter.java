// polytech-lms-api/src/main/java/kr/polytech/lms/security/filter/XssFilter.java
package kr.polytech.lms.security.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

import java.io.IOException;
import java.util.regex.Pattern;

/**
 * XSS (Cross-Site Scripting) 방지 필터
 * 행안부 시큐어코딩 가이드 준수
 */
@Slf4j
@Component
@Order(2)
public class XssFilter implements Filter {

    // XSS 공격 패턴
    private static final Pattern[] XSS_PATTERNS = {
        Pattern.compile("<script>(.*?)</script>", Pattern.CASE_INSENSITIVE),
        Pattern.compile("javascript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("vbscript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onload(.*?)=", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onerror(.*?)=", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onclick(.*?)=", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onmouseover(.*?)=", Pattern.CASE_INSENSITIVE),
        Pattern.compile("eval\\((.*?)\\)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("expression\\((.*?)\\)", Pattern.CASE_INSENSITIVE)
    };

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        chain.doFilter(new XssRequestWrapper((HttpServletRequest) request), response);
    }

    /**
     * XSS 필터링을 적용하는 Request Wrapper
     */
    private static class XssRequestWrapper extends HttpServletRequestWrapper {

        public XssRequestWrapper(HttpServletRequest request) {
            super(request);
        }

        @Override
        public String getParameter(String name) {
            String value = super.getParameter(name);
            return sanitize(value);
        }

        @Override
        public String[] getParameterValues(String name) {
            String[] values = super.getParameterValues(name);
            if (values == null) {
                return null;
            }
            String[] sanitizedValues = new String[values.length];
            for (int i = 0; i < values.length; i++) {
                sanitizedValues[i] = sanitize(values[i]);
            }
            return sanitizedValues;
        }

        @Override
        public String getHeader(String name) {
            String value = super.getHeader(name);
            return sanitize(value);
        }

        private String sanitize(String value) {
            if (value == null) {
                return null;
            }

            // XSS 패턴 제거
            String sanitized = value;
            for (Pattern pattern : XSS_PATTERNS) {
                sanitized = pattern.matcher(sanitized).replaceAll("");
            }

            // HTML 엔티티 이스케이프
            sanitized = HtmlUtils.htmlEscape(sanitized);

            return sanitized;
        }
    }
}
