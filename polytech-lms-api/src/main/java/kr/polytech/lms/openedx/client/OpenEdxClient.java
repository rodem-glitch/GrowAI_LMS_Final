// polytech-lms-api/src/main/java/kr/polytech/lms/openedx/client/OpenEdxClient.java
package kr.polytech.lms.openedx.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * Open edX API 클라이언트
 * LMS 플랫폼과의 통신을 담당
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OpenEdxClient {

    private final OpenEdxProperties properties;
    private final RestTemplate restTemplate = new RestTemplate();

    private String accessToken;
    private long tokenExpiry;

    /**
     * OAuth2 액세스 토큰 발급
     */
    public String getAccessToken() {
        if (accessToken != null && System.currentTimeMillis() < tokenExpiry) {
            return accessToken;
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");
        body.add("client_id", properties.clientId());
        body.add("client_secret", properties.clientSecret());

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(
                properties.oauthTokenUrl(),
                new HttpEntity<>(body, headers),
                Map.class
            );

            if (response.getBody() != null) {
                accessToken = (String) response.getBody().get("access_token");
                Integer expiresIn = (Integer) response.getBody().get("expires_in");
                tokenExpiry = System.currentTimeMillis() + (expiresIn * 1000L) - 60000;
                log.info("Open edX 토큰 발급 완료");
            }
        } catch (Exception e) {
            log.error("Open edX 토큰 발급 실패: {}", e.getMessage());
        }

        return accessToken;
    }

    /**
     * 과정 목록 조회
     */
    public Map<String, Object> getCourses() {
        return get("/api/courses/v1/courses/");
    }

    /**
     * 과정 상세 조회
     */
    public Map<String, Object> getCourse(String courseId) {
        return get("/api/courses/v1/courses/" + courseId + "/");
    }

    /**
     * 수강 등록
     */
    public Map<String, Object> enrollUser(String courseId, String username) {
        Map<String, Object> body = Map.of(
            "course_details", Map.of("course_id", courseId),
            "user", username
        );
        return post("/api/enrollment/v1/enrollment", body);
    }

    /**
     * 수강 현황 조회
     */
    public Map<String, Object> getEnrollments(String username) {
        return get("/api/enrollment/v1/enrollment?user=" + username);
    }

    /**
     * 진도 조회
     */
    public Map<String, Object> getProgress(String courseId, String username) {
        return get("/api/courses/v1/courses/" + courseId + "/progress/" + username + "/");
    }

    private Map<String, Object> get(String path) {
        if (!properties.enabled()) {
            log.debug("Open edX 비활성화 상태");
            return Map.of("error", "Open edX disabled");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(getAccessToken());

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                properties.baseUrl() + path,
                HttpMethod.GET,
                new HttpEntity<>(headers),
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            log.error("Open edX API 호출 실패: {}", e.getMessage());
            return Map.of("error", e.getMessage());
        }
    }

    private Map<String, Object> post(String path, Object body) {
        if (!properties.enabled()) {
            return Map.of("error", "Open edX disabled");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(getAccessToken());
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(
                properties.baseUrl() + path,
                new HttpEntity<>(body, headers),
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            log.error("Open edX API 호출 실패: {}", e.getMessage());
            return Map.of("error", e.getMessage());
        }
    }
}
