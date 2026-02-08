// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/EmbeddingService.java
package kr.polytech.lms.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

/**
 * 온프레미스 임베딩 서비스
 * BGE-M3 / KoSimCSE 모델을 활용한 텍스트 벡터화
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmbeddingService {

    @Value("${embedding.url:http://localhost:8001}")
    private String embeddingUrl;

    @Value("${embedding.model:BAAI/bge-m3}")
    private String modelName;

    @Value("${embedding.enabled:true}")
    private boolean enabled;

    @Value("${embedding.batch-size:32}")
    private int batchSize;

    @Value("${embedding.dimension:1024}")
    private int dimension;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 단일 텍스트 임베딩
     */
    public float[] embed(String text) {
        if (!enabled || text == null || text.isEmpty()) {
            return new float[dimension];
        }

        List<float[]> embeddings = embedBatch(List.of(text));
        return embeddings.isEmpty() ? new float[dimension] : embeddings.get(0);
    }

    /**
     * 배치 텍스트 임베딩
     */
    public List<float[]> embedBatch(List<String> texts) {
        if (!enabled || texts == null || texts.isEmpty()) {
            return Collections.emptyList();
        }

        List<float[]> allEmbeddings = new ArrayList<>();

        // 배치 처리
        for (int i = 0; i < texts.size(); i += batchSize) {
            List<String> batch = texts.subList(i, Math.min(i + batchSize, texts.size()));
            List<float[]> batchResult = callEmbeddingApi(batch);
            allEmbeddings.addAll(batchResult);
        }

        return allEmbeddings;
    }

    /**
     * 임베딩 API 호출
     */
    private List<float[]> callEmbeddingApi(List<String> texts) {
        try {
            String url = embeddingUrl + "/v1/embeddings";

            Map<String, Object> request = Map.of(
                "model", modelName,
                "input", texts,
                "encoding_format", "float"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);

            long startTime = System.currentTimeMillis();
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            long duration = System.currentTimeMillis() - startTime;
            log.debug("임베딩 API 응답 시간: {}ms, 배치 크기: {}", duration, texts.size());

            return parseEmbeddingResponse(response.getBody());

        } catch (Exception e) {
            log.error("임베딩 API 호출 실패: {}", e.getMessage());
            // 폴백: 빈 벡터 반환
            List<float[]> fallback = new ArrayList<>();
            for (int i = 0; i < texts.size(); i++) {
                fallback.add(new float[dimension]);
            }
            return fallback;
        }
    }

    /**
     * 임베딩 응답 파싱
     */
    @SuppressWarnings("unchecked")
    private List<float[]> parseEmbeddingResponse(Map<String, Object> response) {
        List<float[]> embeddings = new ArrayList<>();

        if (response == null || !response.containsKey("data")) {
            return embeddings;
        }

        List<Map<String, Object>> data = (List<Map<String, Object>>) response.get("data");
        for (Map<String, Object> item : data) {
            List<Number> embedding = (List<Number>) item.get("embedding");
            float[] vector = new float[embedding.size()];
            for (int i = 0; i < embedding.size(); i++) {
                vector[i] = embedding.get(i).floatValue();
            }
            embeddings.add(vector);
        }

        return embeddings;
    }

    /**
     * 코사인 유사도 계산
     */
    public double cosineSimilarity(float[] a, float[] b) {
        if (a.length != b.length) {
            throw new IllegalArgumentException("벡터 차원이 다릅니다");
        }

        double dotProduct = 0.0;
        double normA = 0.0;
        double normB = 0.0;

        for (int i = 0; i < a.length; i++) {
            dotProduct += a[i] * b[i];
            normA += a[i] * a[i];
            normB += b[i] * b[i];
        }

        if (normA == 0 || normB == 0) {
            return 0.0;
        }

        return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
    }

    /**
     * 헬스체크
     */
    public boolean isHealthy() {
        if (!enabled) {
            return false;
        }

        try {
            String url = embeddingUrl + "/health";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.debug("임베딩 서비스 헬스체크 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 임베딩 차원 반환
     */
    public int getDimension() {
        return dimension;
    }
}
