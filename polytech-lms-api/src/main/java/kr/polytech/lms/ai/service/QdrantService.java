// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/QdrantService.java
package kr.polytech.lms.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

/**
 * Qdrant 벡터 데이터베이스 서비스
 * 학습 자료 벡터 저장 및 유사도 검색
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class QdrantService {

    @Value("${qdrant.url:http://localhost:6333}")
    private String qdrantUrl;

    @Value("${qdrant.enabled:true}")
    private boolean enabled;

    @Value("${qdrant.collection:lms_documents}")
    private String defaultCollection;

    private final EmbeddingService embeddingService;
    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 컬렉션 생성
     */
    public boolean createCollection(String collectionName, int dimension) {
        if (!enabled) return false;

        try {
            String url = qdrantUrl + "/collections/" + collectionName;

            Map<String, Object> request = Map.of(
                "vectors", Map.of(
                    "size", dimension,
                    "distance", "Cosine"
                ),
                "optimizers_config", Map.of(
                    "memmap_threshold", 20000
                ),
                "replication_factor", 1
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            restTemplate.exchange(url, HttpMethod.PUT, entity, Map.class);

            log.info("Qdrant 컬렉션 생성: {}", collectionName);
            return true;

        } catch (Exception e) {
            log.error("컬렉션 생성 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 문서 저장 (Upsert)
     */
    public boolean upsertDocument(String id, String text, Map<String, Object> metadata) {
        return upsertDocument(defaultCollection, id, text, metadata);
    }

    public boolean upsertDocument(String collection, String id, String text, Map<String, Object> metadata) {
        if (!enabled) return false;

        try {
            float[] embedding = embeddingService.embed(text);

            String url = qdrantUrl + "/collections/" + collection + "/points";

            Map<String, Object> point = new HashMap<>();
            point.put("id", id.hashCode() & 0x7FFFFFFF); // 양수 ID로 변환
            point.put("vector", toList(embedding));

            Map<String, Object> payload = new HashMap<>(metadata != null ? metadata : Map.of());
            payload.put("text", text);
            payload.put("doc_id", id);
            point.put("payload", payload);

            Map<String, Object> request = Map.of(
                "points", List.of(point)
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            restTemplate.exchange(url, HttpMethod.PUT, entity, Map.class);

            log.debug("문서 저장 완료: {}", id);
            return true;

        } catch (Exception e) {
            log.error("문서 저장 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 배치 문서 저장
     */
    public int upsertBatch(String collection, List<Map<String, Object>> documents) {
        if (!enabled || documents.isEmpty()) return 0;

        int successCount = 0;
        for (Map<String, Object> doc : documents) {
            String id = (String) doc.get("id");
            String text = (String) doc.get("text");
            Map<String, Object> metadata = (Map<String, Object>) doc.getOrDefault("metadata", Map.of());

            if (upsertDocument(collection, id, text, metadata)) {
                successCount++;
            }
        }

        log.info("배치 저장 완료: {}/{}", successCount, documents.size());
        return successCount;
    }

    /**
     * 유사도 검색
     */
    public List<Map<String, Object>> search(String query, int limit) {
        return search(defaultCollection, query, limit, null);
    }

    public List<Map<String, Object>> search(String collection, String query, int limit, Map<String, Object> filter) {
        if (!enabled) return Collections.emptyList();

        try {
            float[] queryVector = embeddingService.embed(query);
            String url = qdrantUrl + "/collections/" + collection + "/points/search";

            Map<String, Object> request = new HashMap<>();
            request.put("vector", toList(queryVector));
            request.put("limit", limit);
            request.put("with_payload", true);
            request.put("with_vectors", false);

            if (filter != null && !filter.isEmpty()) {
                request.put("filter", filter);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            return parseSearchResults(response.getBody());

        } catch (Exception e) {
            log.error("검색 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 학습 자료 검색 (RAG용)
     */
    public List<Map<String, Object>> searchLearningContent(String query, Long courseId, int limit) {
        Map<String, Object> filter = null;
        if (courseId != null) {
            filter = Map.of(
                "must", List.of(
                    Map.of("key", "course_id", "match", Map.of("value", courseId))
                )
            );
        }
        return search("lms_learning_content", query, limit, filter);
    }

    /**
     * 검색 결과 파싱
     */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> parseSearchResults(Map<String, Object> response) {
        List<Map<String, Object>> results = new ArrayList<>();

        if (response == null || !response.containsKey("result")) {
            return results;
        }

        List<Map<String, Object>> hits = (List<Map<String, Object>>) response.get("result");
        for (Map<String, Object> hit : hits) {
            Map<String, Object> result = new HashMap<>();
            result.put("id", hit.get("id"));
            result.put("score", hit.get("score"));
            result.put("payload", hit.get("payload"));

            // payload에서 text 추출
            Map<String, Object> payload = (Map<String, Object>) hit.get("payload");
            if (payload != null) {
                result.put("text", payload.get("text"));
                result.put("doc_id", payload.get("doc_id"));
            }

            results.add(result);
        }

        return results;
    }

    /**
     * 문서 삭제
     */
    public boolean deleteDocument(String collection, String id) {
        if (!enabled) return false;

        try {
            String url = qdrantUrl + "/collections/" + collection + "/points/delete";

            Map<String, Object> request = Map.of(
                "points", List.of(id.hashCode() & 0x7FFFFFFF)
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);

            return true;

        } catch (Exception e) {
            log.error("문서 삭제 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 컬렉션 정보 조회
     */
    public Map<String, Object> getCollectionInfo(String collection) {
        try {
            String url = qdrantUrl + "/collections/" + collection;
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            return response.getBody();
        } catch (Exception e) {
            log.error("컬렉션 정보 조회 실패: {}", e.getMessage());
            return Map.of("error", e.getMessage());
        }
    }

    /**
     * 헬스체크
     */
    public boolean isHealthy() {
        if (!enabled) return false;

        try {
            String url = qdrantUrl + "/";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.debug("Qdrant 헬스체크 실패: {}", e.getMessage());
            return false;
        }
    }

    private List<Float> toList(float[] array) {
        List<Float> list = new ArrayList<>(array.length);
        for (float f : array) {
            list.add(f);
        }
        return list;
    }
}
