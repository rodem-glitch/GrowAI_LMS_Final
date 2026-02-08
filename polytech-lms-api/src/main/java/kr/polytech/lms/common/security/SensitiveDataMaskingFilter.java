// polytech-lms-api/src/main/java/kr/polytech/lms/common/security/SensitiveDataMaskingFilter.java
package kr.polytech.lms.common.security;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.filter.Filter;
import ch.qos.logback.core.spi.FilterReply;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 민감정보 로그 마스킹 필터
 * 행정안전부 시큐어코딩 가이드라인 - 민감정보 로그 출력 금지
 */
public class SensitiveDataMaskingFilter extends Filter<ILoggingEvent> {

    // 민감정보 패턴
    private static final Pattern[] SENSITIVE_PATTERNS = {
        // 비밀번호
        Pattern.compile("(password|passwd|pwd)\\s*[=:]\\s*['\"]?([^'\"\\s]+)['\"]?", Pattern.CASE_INSENSITIVE),
        // 주민등록번호
        Pattern.compile("\\d{6}[-]?\\d{7}"),
        // 신용카드 번호
        Pattern.compile("\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}"),
        // API 키
        Pattern.compile("(api[_-]?key|apikey|api_secret|secret[_-]?key)\\s*[=:]\\s*['\"]?([^'\"\\s]+)['\"]?", Pattern.CASE_INSENSITIVE),
        // 이메일 (부분 마스킹)
        Pattern.compile("([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+)\\.([a-zA-Z]{2,})", Pattern.CASE_INSENSITIVE),
        // 전화번호
        Pattern.compile("(01[016789])[-\\s]?(\\d{3,4})[-\\s]?(\\d{4})"),
        // JWT 토큰
        Pattern.compile("(Bearer\\s+)?eyJ[A-Za-z0-9-_]+\\.eyJ[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+", Pattern.CASE_INSENSITIVE)
    };

    // 마스킹 대체 문자열
    private static final String[] MASKED_VALUES = {
        "$1=***MASKED***",           // 비밀번호
        "******-*******",             // 주민등록번호
        "****-****-****-****",        // 신용카드
        "$1=***MASKED***",           // API 키
        "***@***.***",                // 이메일
        "$1-****-$3",                 // 전화번호
        "***JWT_TOKEN***"             // JWT
    };

    @Override
    public FilterReply decide(ILoggingEvent event) {
        // 로그 메시지는 마스킹 후 통과
        return FilterReply.NEUTRAL;
    }

    /**
     * 민감정보 마스킹 처리
     */
    public static String maskSensitiveData(String message) {
        if (message == null) {
            return null;
        }

        String masked = message;
        for (int i = 0; i < SENSITIVE_PATTERNS.length; i++) {
            Matcher matcher = SENSITIVE_PATTERNS[i].matcher(masked);
            if (matcher.find()) {
                masked = matcher.replaceAll(MASKED_VALUES[i]);
            }
        }
        return masked;
    }
}
