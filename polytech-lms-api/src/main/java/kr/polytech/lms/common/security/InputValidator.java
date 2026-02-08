// polytech-lms-api/src/main/java/kr/polytech/lms/common/security/InputValidator.java
package kr.polytech.lms.common.security;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

import java.util.regex.Pattern;

/**
 * 입력값 검증 유틸리티
 * 행정안전부 시큐어코딩 가이드라인 준수
 * - SQL Injection 방지
 * - XSS 방지
 * - 경로 조작 방지
 */
@Slf4j
@Component
public class InputValidator {

    // SQL Injection 패턴
    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
        "('|--|;|/\\*|\\*/|xp_|exec|execute|insert|select|delete|update|drop|" +
        "alter|create|truncate|replace|union|script|concat|char\\(|chr\\()",
        Pattern.CASE_INSENSITIVE
    );

    // 경로 조작 패턴
    private static final Pattern PATH_TRAVERSAL_PATTERN = Pattern.compile(
        "(\\.\\./|\\.\\.\\\\|%2e%2e%2f|%2e%2e/|\\.\\.%2f|%2e%2e%5c)",
        Pattern.CASE_INSENSITIVE
    );

    // 허용된 문자 패턴 (알파벳, 숫자, 한글, 일부 특수문자)
    private static final Pattern ALLOWED_CHARS = Pattern.compile(
        "^[a-zA-Z0-9가-힣\\s\\-_.,@#$%&*()+=\\[\\]{}|:;\"'<>?/\\\\]+$"
    );

    /**
     * SQL Injection 검사
     * MyBatis #{} 바인딩을 사용하지만 추가 검증
     */
    public boolean isSqlInjectionSafe(String input) {
        if (input == null || input.isEmpty()) {
            return true;
        }
        boolean safe = !SQL_INJECTION_PATTERN.matcher(input).find();
        if (!safe) {
            log.warn("SQL Injection 시도 감지: {}", SensitiveDataMaskingFilter.maskSensitiveData(input));
        }
        return safe;
    }

    /**
     * XSS 공격 패턴 검사
     */
    public boolean isXssSafe(String input) {
        if (input == null || input.isEmpty()) {
            return true;
        }

        String[] xssPatterns = {
            "<script>", "</script>", "javascript:", "onerror=", "onclick=",
            "onload=", "onmouseover=", "eval(", "expression(", "vbscript:"
        };

        String lowerInput = input.toLowerCase();
        for (String pattern : xssPatterns) {
            if (lowerInput.contains(pattern)) {
                log.warn("XSS 공격 시도 감지: {}", SensitiveDataMaskingFilter.maskSensitiveData(input));
                return false;
            }
        }
        return true;
    }

    /**
     * 경로 조작 공격 검사
     */
    public boolean isPathTraversalSafe(String input) {
        if (input == null || input.isEmpty()) {
            return true;
        }
        boolean safe = !PATH_TRAVERSAL_PATTERN.matcher(input).find();
        if (!safe) {
            log.warn("경로 조작 시도 감지: {}", SensitiveDataMaskingFilter.maskSensitiveData(input));
        }
        return safe;
    }

    /**
     * 종합 입력값 검증
     */
    public boolean isValidInput(String input) {
        return isSqlInjectionSafe(input) && isXssSafe(input) && isPathTraversalSafe(input);
    }

    /**
     * HTML 이스케이프
     */
    public String escapeHtml(String input) {
        if (input == null) {
            return null;
        }
        return HtmlUtils.htmlEscape(input);
    }

    /**
     * SQL 특수문자 이스케이프
     */
    public String escapeSql(String input) {
        if (input == null) {
            return null;
        }
        return input
            .replace("'", "''")
            .replace("\\", "\\\\")
            .replace("%", "\\%")
            .replace("_", "\\_");
    }

    /**
     * 입력값 정제 (허용된 문자만 유지)
     */
    public String sanitize(String input) {
        if (input == null) {
            return null;
        }

        // XSS 패턴 제거
        String sanitized = input
            .replaceAll("<script[^>]*>.*?</script>", "")
            .replaceAll("<[^>]+>", "")
            .replaceAll("javascript:", "")
            .replaceAll("on\\w+\\s*=", "");

        // HTML 이스케이프
        return HtmlUtils.htmlEscape(sanitized.trim());
    }

    /**
     * 코스 코드 검증 (알파벳, 숫자, 하이픈만 허용)
     */
    public boolean isValidCourseCode(String code) {
        if (code == null || code.isEmpty()) {
            return false;
        }
        return code.matches("^[A-Za-z0-9\\-]+$");
    }

    /**
     * 회원 키 검증
     */
    public boolean isValidMemberKey(String key) {
        if (key == null || key.isEmpty()) {
            return false;
        }
        return key.matches("^[A-Za-z0-9]+$");
    }

    /**
     * 이메일 검증
     */
    public boolean isValidEmail(String email) {
        if (email == null || email.isEmpty()) {
            return false;
        }
        return email.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
    }

    /**
     * 전화번호 검증
     */
    public boolean isValidPhoneNumber(String phone) {
        if (phone == null || phone.isEmpty()) {
            return false;
        }
        return phone.matches("^01[016789][-\\s]?\\d{3,4}[-\\s]?\\d{4}$");
    }
}
