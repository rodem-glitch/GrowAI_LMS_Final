package kr.polytech.lms.contentsummary.client;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 요약/키워드 생성은 외부 LLM API 호출이 필요하고, 키/모델/타임아웃은 환경마다 달라서 설정으로 분리합니다.
 */
@ConfigurationProperties(prefix = "gemini")
public class GeminiProperties {

    private String baseUrl;
    private String apiKey;
    private String model;
    private Double temperature;
    private Integer maxOutputTokens;
    private Duration httpTimeout;

    public GeminiProperties() {
    }

    public String baseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = normalizeBaseUrl(baseUrl, "https://generativelanguage.googleapis.com/v1beta");
    }

    public String apiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String model() {
        return model;
    }

    public void setModel(String model) {
        this.model = (model == null || model.isBlank()) ? "gemini-3-flash-preview" : model.trim();
    }

    public Double temperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature == null ? 0.2d : temperature;
    }

    public Integer maxOutputTokens() {
        return maxOutputTokens;
    }

    public void setMaxOutputTokens(Integer maxOutputTokens) {
        this.maxOutputTokens = maxOutputTokens == null ? 2048 : maxOutputTokens;
    }

    public Duration httpTimeout() {
        return httpTimeout;
    }

    public void setHttpTimeout(Duration httpTimeout) {
        this.httpTimeout = httpTimeout == null ? Duration.ofMinutes(5) : httpTimeout;
    }

    private static String normalizeBaseUrl(String baseUrl, String defaultValue) {
        String url = (baseUrl == null || baseUrl.isBlank()) ? defaultValue : baseUrl.trim();
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://" + url;
        }
        // 트레일링 슬래시 제거 (ex: .../v1beta/ -> .../v1beta)
        if (url.endsWith("/")) {
            url = url.substring(0, url.length() - 1);
        }
        return url;
    }
}
