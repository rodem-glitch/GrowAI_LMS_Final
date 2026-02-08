// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/VertexAiService.java
package kr.polytech.lms.gcp.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.GoogleCredentials;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;

/**
 * Vertex AI RAG/Embeddings 서비스
 * aiplatform.googleapis.com REST API 연동
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VertexAiService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.location:asia-northeast3}")
    private String location;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    @Value("${gcp.vertex-ai.embedding-model:text-multilingual-embedding-002}")
    private String embeddingModel;

    @Value("${gcp.vertex-ai.text-model:gemini-1.5-flash}")
    private String textModel;

    /**
     * 액세스 토큰 획득
     */
    private String getAccessToken() {
        try {
            GoogleCredentials credentials;
            if (credentialsPath != null && !credentialsPath.isEmpty()) {
                credentials = GoogleCredentials.fromStream(new FileInputStream(credentialsPath))
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
            } else {
                credentials = GoogleCredentials.getApplicationDefault()
                    .createScoped("https://www.googleapis.com/auth/cloud-platform");
            }
            credentials.refreshIfExpired();
            return credentials.getAccessToken().getTokenValue();
        } catch (IOException e) {
            log.error("GCP 인증 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 텍스트 임베딩 생성
     */
    public List<Float> generateEmbedding(String text) {
        log.info("Vertex AI 임베딩 생성 요청: {}자", text.length());

        String accessToken = getAccessToken();
        if (accessToken == null) {
            log.warn("인증 실패, Mock 임베딩 반환");
            return generateMockEmbedding();
        }

        String url = String.format(
            "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:predict",
            location, projectId, location, embeddingModel
        );

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> instance = Map.of("content", text);
            Map<String, Object> body = Map.of("instances", List.of(instance));

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode values = root.path("predictions").get(0).path("embeddings").path("values");

                List<Float> embeddings = new ArrayList<>();
                values.forEach(v -> embeddings.add((float) v.asDouble()));

                log.info("임베딩 생성 완료: {}차원", embeddings.size());
                return embeddings;
            }

        } catch (Exception e) {
            log.error("Vertex AI 임베딩 생성 실패: {}", e.getMessage());
        }

        return generateMockEmbedding();
    }

    /**
     * 배치 임베딩 생성
     */
    public List<List<Float>> generateBatchEmbeddings(List<String> texts) {
        log.info("Vertex AI 배치 임베딩 생성: {}개", texts.size());

        List<List<Float>> results = new ArrayList<>();
        for (String text : texts) {
            results.add(generateEmbedding(text));
        }
        return results;
    }

    /**
     * RAG 기반 질의응답 (Gemini)
     */
    public Map<String, Object> ragQuery(String query, List<String> contexts) {
        log.info("Vertex AI RAG 질의: {}", query);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of(
                "query", query,
                "answer", "인증 실패로 AI 서비스를 이용할 수 없습니다.",
                "contextCount", contexts.size(),
                "error", "AUTH_FAILED"
            );
        }

        String url = String.format(
            "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:generateContent",
            location, projectId, location, textModel
        );

        try {
            // 프롬프트 구성
            StringBuilder prompt = new StringBuilder();
            prompt.append("다음 컨텍스트를 바탕으로 질문에 답하세요.\n\n");
            prompt.append("컨텍스트:\n");
            for (int i = 0; i < contexts.size(); i++) {
                prompt.append(String.format("[%d] %s\n", i + 1, contexts.get(i)));
            }
            prompt.append("\n질문: ").append(query);
            prompt.append("\n\n답변:");

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> content = Map.of(
                "role", "user",
                "parts", List.of(Map.of("text", prompt.toString()))
            );
            Map<String, Object> body = Map.of("contents", List.of(content));

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String answer = root.path("candidates").get(0)
                    .path("content").path("parts").get(0)
                    .path("text").asText();

                return Map.of(
                    "query", query,
                    "answer", answer,
                    "contextCount", contexts.size(),
                    "model", textModel
                );
            }

        } catch (Exception e) {
            log.error("Vertex AI RAG 질의 실패: {}", e.getMessage());
        }

        return Map.of(
            "query", query,
            "answer", "죄송합니다. 현재 AI 서비스에 연결할 수 없습니다.",
            "contextCount", contexts.size(),
            "model", textModel
        );
    }

    /**
     * 문서 요약
     */
    public String summarizeDocument(String content, int maxLength) {
        log.info("Vertex AI 문서 요약: {}자 -> {}자", content.length(), maxLength);

        String prompt = String.format(
            "다음 문서를 %d자 이내로 요약하세요:\n\n%s",
            maxLength, content
        );

        Map<String, Object> result = ragQuery(prompt, List.of());
        return (String) result.getOrDefault("answer",
            content.substring(0, Math.min(maxLength, content.length())));
    }

    /**
     * 유사도 계산 (코사인 유사도)
     */
    public double calculateSimilarity(List<Float> embedding1, List<Float> embedding2) {
        if (embedding1.size() != embedding2.size()) {
            throw new IllegalArgumentException("임베딩 차원이 일치하지 않습니다.");
        }

        double dotProduct = 0.0;
        double norm1 = 0.0;
        double norm2 = 0.0;

        for (int i = 0; i < embedding1.size(); i++) {
            dotProduct += embedding1.get(i) * embedding2.get(i);
            norm1 += embedding1.get(i) * embedding1.get(i);
            norm2 += embedding2.get(i) * embedding2.get(i);
        }

        return dotProduct / (Math.sqrt(norm1) * Math.sqrt(norm2));
    }

    /**
     * Mock 임베딩 생성 (테스트/폴백용)
     */
    private List<Float> generateMockEmbedding() {
        List<Float> embedding = new ArrayList<>();
        Random random = new Random();
        for (int i = 0; i < 768; i++) {
            embedding.add(random.nextFloat() * 2 - 1);
        }
        return embedding;
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean authenticated = getAccessToken() != null;

        return Map.of(
            "service", "vertex-ai",
            "projectId", projectId,
            "location", location,
            "embeddingModel", embeddingModel,
            "textModel", textModel,
            "authenticated", authenticated,
            "status", authenticated ? "UP" : "DEGRADED"
        );
    }
}
