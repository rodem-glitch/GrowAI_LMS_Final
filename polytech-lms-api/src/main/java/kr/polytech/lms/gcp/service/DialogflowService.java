// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/DialogflowService.java
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
 * Dialogflow CX 서비스
 * dialogflow.googleapis.com REST API 연동
 * 대화형 AI 에이전트 통합
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DialogflowService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.location:asia-northeast3}")
    private String location;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    @Value("${gcp.dialogflow.agent-id:}")
    private String agentId;

    @Value("${gcp.dialogflow.language-code:ko}")
    private String defaultLanguageCode;

    /**
     * 액세스 토큰 획득
     */
    private String getAccessToken() {
        try {
            GoogleCredentials credentials;
            if (credentialsPath != null && !credentialsPath.isEmpty()) {
                credentials = GoogleCredentials.fromStream(new FileInputStream(credentialsPath))
                    .createScoped("https://www.googleapis.com/auth/cloud-platform",
                                  "https://www.googleapis.com/auth/dialogflow");
            } else {
                credentials = GoogleCredentials.getApplicationDefault()
                    .createScoped("https://www.googleapis.com/auth/cloud-platform",
                                  "https://www.googleapis.com/auth/dialogflow");
            }
            credentials.refreshIfExpired();
            return credentials.getAccessToken().getTokenValue();
        } catch (IOException e) {
            log.error("GCP 인증 실패: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 세션 ID 생성
     */
    public String createSessionId() {
        return UUID.randomUUID().toString();
    }

    /**
     * 사용자 메시지 처리 (Dialogflow CX)
     */
    public Map<String, Object> detectIntent(String sessionId, String text, String languageCode) {
        log.info("Dialogflow 의도 감지: session={}, text={}", sessionId, text);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return getMockResponse(text);
        }

        // Dialogflow CX API URL
        String url = String.format(
            "https://%s-dialogflow.googleapis.com/v3/projects/%s/locations/%s/agents/%s/sessions/%s:detectIntent",
            location, projectId, location, agentId, sessionId
        );

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> queryInput = Map.of(
                "text", Map.of("text", text),
                "languageCode", languageCode != null ? languageCode : defaultLanguageCode
            );

            Map<String, Object> body = Map.of("queryInput", queryInput);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode queryResult = root.path("queryResult");

                String responseText = queryResult.path("responseMessages").get(0)
                    .path("text").path("text").get(0).asText();
                String intentName = queryResult.path("intent").path("displayName").asText();
                double confidence = queryResult.path("intentDetectionConfidence").asDouble();

                // 파라미터 추출
                Map<String, Object> parameters = new HashMap<>();
                JsonNode params = queryResult.path("parameters");
                params.fields().forEachRemaining(entry ->
                    parameters.put(entry.getKey(), entry.getValue().asText())
                );

                log.info("Dialogflow 응답: intent={}, confidence={}", intentName, confidence);

                return Map.of(
                    "success", true,
                    "sessionId", sessionId,
                    "query", text,
                    "responseText", responseText,
                    "intent", intentName,
                    "confidence", confidence,
                    "parameters", parameters,
                    "languageCode", languageCode != null ? languageCode : defaultLanguageCode
                );
            }

        } catch (Exception e) {
            log.error("Dialogflow 호출 실패: {}", e.getMessage());
        }

        return getMockResponse(text);
    }

    /**
     * 간단한 텍스트 쿼리 (새 세션)
     */
    public Map<String, Object> query(String text) {
        return detectIntent(createSessionId(), text, null);
    }

    /**
     * 이벤트 트리거
     */
    public Map<String, Object> triggerEvent(String sessionId, String eventName, Map<String, Object> parameters) {
        log.info("Dialogflow 이벤트 트리거: event={}", eventName);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of("success", false, "error", "인증 실패");
        }

        String url = String.format(
            "https://%s-dialogflow.googleapis.com/v3/projects/%s/locations/%s/agents/%s/sessions/%s:detectIntent",
            location, projectId, location, agentId, sessionId
        );

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> queryInput = Map.of(
                "event", Map.of(
                    "event", eventName,
                    "parameters", parameters != null ? parameters : Map.of()
                ),
                "languageCode", defaultLanguageCode
            );

            Map<String, Object> body = Map.of("queryInput", queryInput);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                return Map.of("success", true, "event", eventName);
            }

        } catch (Exception e) {
            log.error("이벤트 트리거 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "이벤트 트리거 실패");
    }

    /**
     * LMS 관련 의도 처리 (커스텀 로직)
     */
    public Map<String, Object> handleLmsQuery(String sessionId, String query) {
        Map<String, Object> result = detectIntent(sessionId, query, "ko");

        String intent = (String) result.getOrDefault("intent", "");

        // LMS 관련 의도별 추가 처리
        switch (intent.toLowerCase()) {
            case "course.inquiry":
                result.put("action", "SHOW_COURSES");
                result.put("apiEndpoint", "/api/haksa/courses");
                break;
            case "grade.inquiry":
                result.put("action", "SHOW_GRADES");
                result.put("apiEndpoint", "/api/haksa/grade/student");
                break;
            case "attendance.check":
                result.put("action", "CHECK_ATTENDANCE");
                result.put("apiEndpoint", "/api/haksa/attendance/check");
                break;
            case "syllabus.inquiry":
                result.put("action", "SHOW_SYLLABUS");
                result.put("apiEndpoint", "/api/haksa/syllabus");
                break;
            default:
                result.put("action", "GENERAL_RESPONSE");
        }

        return result;
    }

    /**
     * Mock 응답 (테스트/폴백용)
     */
    private Map<String, Object> getMockResponse(String query) {
        String responseText;
        String intent;

        // 간단한 키워드 매칭
        String lowerQuery = query.toLowerCase();
        if (lowerQuery.contains("강좌") || lowerQuery.contains("과목")) {
            responseText = "수강 중인 강좌 목록을 확인하시겠습니까? '내 강좌' 메뉴에서 확인하실 수 있습니다.";
            intent = "course.inquiry";
        } else if (lowerQuery.contains("성적") || lowerQuery.contains("학점")) {
            responseText = "성적 조회를 원하시는군요. 성적 메뉴에서 과목별 성적을 확인하실 수 있습니다.";
            intent = "grade.inquiry";
        } else if (lowerQuery.contains("출석") || lowerQuery.contains("출결")) {
            responseText = "출석 현황을 확인해 드리겠습니다. 강좌별 출석률과 상세 내역을 확인하실 수 있습니다.";
            intent = "attendance.check";
        } else if (lowerQuery.contains("계획서") || lowerQuery.contains("강의계획")) {
            responseText = "강의계획서 조회를 도와드리겠습니다. 해당 강좌를 선택하시면 PDF로 다운로드할 수 있습니다.";
            intent = "syllabus.inquiry";
        } else if (lowerQuery.contains("안녕") || lowerQuery.contains("hello")) {
            responseText = "안녕하세요! 한국폴리텍대학 LMS 도우미입니다. 강좌, 성적, 출석 등에 대해 질문해 주세요.";
            intent = "greeting";
        } else {
            responseText = "죄송합니다. 질문을 이해하지 못했습니다. 강좌, 성적, 출석 등에 대해 질문해 주세요.";
            intent = "fallback";
        }

        return Map.of(
            "success", true,
            "sessionId", createSessionId(),
            "query", query,
            "responseText", responseText,
            "intent", intent,
            "confidence", 0.85,
            "parameters", Map.of(),
            "languageCode", "ko",
            "isMock", true
        );
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean authenticated = getAccessToken() != null;

        return Map.of(
            "service", "dialogflow-cx",
            "projectId", projectId,
            "location", location,
            "agentId", agentId != null ? agentId : "not-configured",
            "defaultLanguage", defaultLanguageCode,
            "authenticated", authenticated,
            "status", authenticated ? "UP" : "DEGRADED"
        );
    }
}
