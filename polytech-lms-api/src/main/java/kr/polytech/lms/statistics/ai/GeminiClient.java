package kr.polytech.lms.statistics.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Component
public class GeminiClient {
    // 왜: Spring AI(ChatModel)를 붙이면 설정/의존성이 프로젝트마다 달라질 수 있어,
    //     v1에서는 Google Generative Language API를 REST로 직접 호출해 동작을 단순화합니다.
    //     (LLM은 실행계획(JSON) 생성만 하고, 실제 수치 계산은 서버가 수행합니다)

    private static final String DEFAULT_BASE_URL = "https://generativelanguage.googleapis.com";

    private final StatisticsAiProperties properties;
    private final RestClient restClient;

    public GeminiClient(StatisticsAiProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(DEFAULT_BASE_URL)
                .build();
    }

    public String generateText(String prompt) {
        if (!properties.isEnabled()) {
            throw new IllegalStateException("AI 통계 기능이 비활성화되어 있습니다. (statistics.ai.enabled=false)");
        }

        if (!StringUtils.hasText(properties.getApiKey())) {
            throw new IllegalStateException("AI 통계 API 키가 설정되지 않았습니다. 환경변수 GOOGLE_API_KEY 또는 STATISTICS_AI_API_KEY를 설정해 주세요.");
        }

        String model = StringUtils.hasText(properties.getModel()) ? properties.getModel().trim() : "gemini-1.5-flash";
        String path = "/v1beta/models/" + model + ":generateContent";

        Map<String, Object> body = Map.of(
                "contents", new Object[]{
                        Map.of(
                                "role", "user",
                                "parts", new Object[]{Map.of("text", prompt)}
                        )
                },
                // 왜: 실행계획(JSON) 생성은 창의성이 필요하지 않아, temperature를 낮춰 재현성을 높입니다.
                "generationConfig", Map.of(
                        "temperature", 0.1,
                        "maxOutputTokens", 2048
                )
        );

        JsonNode response = restClient.post()
                .uri(uriBuilder -> uriBuilder.path(path).queryParam("key", properties.getApiKey()).build())
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(JsonNode.class);

        if (response == null) {
            throw new IllegalStateException("Gemini 응답이 비어 있습니다.");
        }

        JsonNode candidates = response.get("candidates");
        if (candidates == null || !candidates.isArray() || candidates.isEmpty()) {
            throw new IllegalStateException("Gemini 응답에 candidates가 없습니다. 응답=" + safeTruncate(response.toString(), 500));
        }

        JsonNode textNode = candidates.path(0).path("content").path("parts").path(0).path("text");
        if (textNode == null || !textNode.isTextual() || !StringUtils.hasText(textNode.asText())) {
            throw new IllegalStateException("Gemini 응답에서 텍스트를 찾지 못했습니다. 응답=" + safeTruncate(response.toString(), 500));
        }

        return textNode.asText();
    }

    private String safeTruncate(String text, int max) {
        if (text == null) return null;
        if (text.length() <= max) return text;
        return text.substring(0, max) + "...";
    }
}
