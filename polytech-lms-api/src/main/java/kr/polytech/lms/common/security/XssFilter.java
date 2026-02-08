// polytech-lms-api/src/main/java/kr/polytech/lms/common/security/XssFilter.java
package kr.polytech.lms.common.security;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * XSS 방지 필터
 * 행정안전부 시큐어코딩 가이드라인 - XSS 방지
 */
@Slf4j
@Component
@Order(1)
public class XssFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;

        // XSS 방지 래퍼로 요청 감싸기
        XssRequestWrapper wrappedRequest = new XssRequestWrapper(httpRequest);

        chain.doFilter(wrappedRequest, response);
    }
}
