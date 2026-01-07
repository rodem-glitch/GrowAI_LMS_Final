package kr.polytech.lms.contentsummary.client;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 전사(STT)는 외부 API를 쓰는 경우가 많고, 제공자/모델/언어가 바뀔 수 있어서 설정으로 분리합니다.
 */
@ConfigurationProperties(prefix = "stt")
public record SttProperties(
    String provider,
    String language,
    OpenAi openai,
    Duration httpTimeout
) {
    public SttProperties {
        provider = (provider == null || provider.isBlank()) ? "openai" : provider.trim();
        language = (language == null || language.isBlank()) ? "ko" : language.trim();
        openai = openai == null ? new OpenAi(null, null, null) : openai;
        httpTimeout = httpTimeout == null ? Duration.ofMinutes(5) : httpTimeout;
    }

    public record OpenAi(
        String baseUrl,
        String apiKey,
        String model
    ) {
        public OpenAi {
            baseUrl = normalizeBaseUrl(baseUrl, "https://api.openai.com/v1");
            model = (model == null || model.isBlank()) ? "gpt-4o-mini-transcribe" : model.trim();
        }

        private static String normalizeBaseUrl(String baseUrl, String defaultValue) {
            if (baseUrl == null || baseUrl.isBlank()) return defaultValue;
            String trimmed = baseUrl.trim();
            if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) return trimmed;
            return "https://" + trimmed;
        }
    }
}

