// polytech-lms-api/src/main/java/kr/polytech/lms/recommendation/client/PredictionIOClient.java
package kr.polytech.lms.recommendation.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.*;

/**
 * Apache PredictionIO API 클라이언트
 * AI 기반 개인 맞춤형 추천 엔진 연동
 */
@Slf4j
@Component
public class PredictionIOClient {

    @Value("${predictionio.event-server-url:http://localhost:7070}")
    private String eventServerUrl;

    @Value("${predictionio.engine-url:http://localhost:8000}")
    private String engineUrl;

    @Value("${predictionio.access-key:}")
    private String accessKey;

    @Value("${predictionio.enabled:false}")
    private boolean enabled;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 사용자 행동 이벤트 전송
     */
    public boolean sendEvent(String event, String entityType, String entityId,
                             String targetEntityType, String targetEntityId,
                             Map<String, Object> properties) {
        if (!enabled) {
            log.debug("PredictionIO 비활성화 상태");
            return false;
        }

        Map<String, Object> eventData = new HashMap<>();
        eventData.put("event", event);
        eventData.put("entityType", entityType);
        eventData.put("entityId", entityId);
        eventData.put("eventTime", java.time.Instant.now().toString());

        if (targetEntityType != null && targetEntityId != null) {
            eventData.put("targetEntityType", targetEntityType);
            eventData.put("targetEntityId", targetEntityId);
        }

        if (properties != null && !properties.isEmpty()) {
            eventData.put("properties", properties);
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String url = eventServerUrl + "/events.json?accessKey=" + accessKey;
            ResponseEntity<Map> response = restTemplate.postForEntity(
                url, new HttpEntity<>(eventData, headers), Map.class);

            log.debug("PredictionIO 이벤트 전송 성공: event={}, entityId={}", event, entityId);
            return response.getStatusCode().is2xxSuccessful();

        } catch (Exception e) {
            log.error("PredictionIO 이벤트 전송 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 사용자 생성/업데이트 이벤트
     */
    public boolean setUser(String userId, Map<String, Object> properties) {
        return sendEvent("$set", "user", userId, null, null, properties);
    }

    /**
     * 아이템(과정) 생성/업데이트 이벤트
     */
    public boolean setItem(String itemId, Map<String, Object> properties) {
        return sendEvent("$set", "item", itemId, null, null, properties);
    }

    /**
     * 사용자-아이템 조회 이벤트
     */
    public boolean recordView(String userId, String itemId) {
        return sendEvent("view", "user", userId, "item", itemId, null);
    }

    /**
     * 사용자-아이템 수강 이벤트
     */
    public boolean recordEnroll(String userId, String itemId) {
        return sendEvent("enroll", "user", userId, "item", itemId, null);
    }

    /**
     * 사용자-아이템 완료 이벤트
     */
    public boolean recordComplete(String userId, String itemId, int score) {
        Map<String, Object> props = Map.of("score", score);
        return sendEvent("complete", "user", userId, "item", itemId, props);
    }

    /**
     * 사용자-아이템 평점 이벤트
     */
    public boolean recordRating(String userId, String itemId, double rating) {
        Map<String, Object> props = Map.of("rating", rating);
        return sendEvent("rate", "user", userId, "item", itemId, props);
    }

    /**
     * 추천 결과 조회
     */
    public List<Map<String, Object>> getRecommendations(String userId, int numResults) {
        if (!enabled) {
            log.debug("PredictionIO 비활성화 상태");
            return Collections.emptyList();
        }

        try {
            Map<String, Object> query = Map.of(
                "user", userId,
                "num", numResults
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            ResponseEntity<Map> response = restTemplate.postForEntity(
                engineUrl + "/queries.json",
                new HttpEntity<>(query, headers),
                Map.class
            );

            if (response.getBody() != null && response.getBody().containsKey("itemScores")) {
                return (List<Map<String, Object>>) response.getBody().get("itemScores");
            }

        } catch (Exception e) {
            log.error("PredictionIO 추천 조회 실패: {}", e.getMessage());
        }

        return Collections.emptyList();
    }

    /**
     * 유사 아이템 조회
     */
    public List<Map<String, Object>> getSimilarItems(String itemId, int numResults) {
        if (!enabled) {
            return Collections.emptyList();
        }

        try {
            Map<String, Object> query = Map.of(
                "items", List.of(itemId),
                "num", numResults
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            ResponseEntity<Map> response = restTemplate.postForEntity(
                engineUrl + "/queries.json",
                new HttpEntity<>(query, headers),
                Map.class
            );

            if (response.getBody() != null && response.getBody().containsKey("itemScores")) {
                return (List<Map<String, Object>>) response.getBody().get("itemScores");
            }

        } catch (Exception e) {
            log.error("PredictionIO 유사 아이템 조회 실패: {}", e.getMessage());
        }

        return Collections.emptyList();
    }
}
