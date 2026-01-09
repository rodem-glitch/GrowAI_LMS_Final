package kr.polytech.lms.contentsummary.client;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 요약/키워드 생성은 외부 LLM API 호출이 필요하고, 키/모델/타임아웃은 환경마다 달라서 설정으로 분리합니다.
 */
@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(
    String baseUrl,
    String apiKey,
    String model,
    Double temperature,
    Integer maxOutputTokens,
    Duration httpTimeout
) {
    public GeminiProperties {
        baseUrl = normalizeBaseUrl(baseUrl, "https://generativelanguage.googleapis.com/v1beta");
        model = (model == null || model.isBlank()) ? "gemini-2.0-flash-exp" : model.trim();
        temperature = temperature == null ? 0.2d : temperature;
        maxOutputTokens = maxOutputTokens == null ? 2048 : maxOutputTokens;
        httpTimeout = httpTimeout == null ? Duration.ofMinutes(5) : httpTimeout;
    }

    private static String normalizeBaseUrl(String baseUrl, String defaultValue) {
        if (baseUrl == null || baseUrl.isBlank()) return defaultValue;
        String trimmed = baseUrl.trim();
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) return trimmed;
        return "https://" + trimmed;
    }
}

