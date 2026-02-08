// config/GoogleAiConfig.java — Google AI / Gemini / Qdrant 설정
package kr.polytech.epoly.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.boot.web.client.RestTemplateBuilder;

import java.time.Duration;

@Configuration
public class GoogleAiConfig {

    @Value("${google.ai.api-key:}")
    private String apiKey;

    @Value("${google.ai.gemini.model:gemini-2.0-flash}")
    private String geminiModel;

    @Value("${qdrant.host:localhost}")
    private String qdrantHost;

    @Value("${qdrant.port:6334}")
    private int qdrantPort;

    @Value("${qdrant.collection-name:lms_contents}")
    private String collectionName;

    @Bean
    public RestTemplate geminiRestTemplate(RestTemplateBuilder builder) {
        return builder
                .setConnectTimeout(Duration.ofSeconds(10))
                .setReadTimeout(Duration.ofSeconds(30))
                .build();
    }

    public String getApiKey() { return apiKey; }
    public String getGeminiModel() { return geminiModel; }
    public String getQdrantHost() { return qdrantHost; }
    public int getQdrantPort() { return qdrantPort; }
    public String getCollectionName() { return collectionName; }
}
