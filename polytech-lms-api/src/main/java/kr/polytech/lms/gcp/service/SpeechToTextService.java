// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/SpeechToTextService.java
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
import org.springframework.web.multipart.MultipartFile;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;

/**
 * Speech-to-Text 서비스
 * speech.googleapis.com REST API 연동
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SpeechToTextService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    @Value("${gcp.stt.language-code:ko-KR}")
    private String defaultLanguageCode;

    @Value("${gcp.stt.sample-rate:16000}")
    private int defaultSampleRate;

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
     * 음성을 텍스트로 변환 (동기 방식)
     */
    public Map<String, Object> recognizeSpeech(byte[] audioData, String languageCode, int sampleRate) {
        log.info("STT 요청: {}bytes, lang={}", audioData.length, languageCode);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of("success", false, "error", "인증 실패");
        }

        String url = "https://speech.googleapis.com/v1/speech:recognize";

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            String audioBase64 = Base64.getEncoder().encodeToString(audioData);

            Map<String, Object> config = Map.of(
                "encoding", "LINEAR16",
                "sampleRateHertz", sampleRate > 0 ? sampleRate : defaultSampleRate,
                "languageCode", languageCode != null ? languageCode : defaultLanguageCode,
                "enableAutomaticPunctuation", true,
                "enableWordTimeOffsets", true
            );

            Map<String, Object> audio = Map.of("content", audioBase64);

            Map<String, Object> body = Map.of(
                "config", config,
                "audio", audio
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode results = root.path("results");

                if (results.isArray() && results.size() > 0) {
                    StringBuilder transcript = new StringBuilder();
                    double confidence = 0;
                    int count = 0;

                    List<Map<String, Object>> alternatives = new ArrayList<>();

                    for (JsonNode result : results) {
                        JsonNode alt = result.path("alternatives").get(0);
                        transcript.append(alt.path("transcript").asText()).append(" ");
                        confidence += alt.path("confidence").asDouble();
                        count++;

                        alternatives.add(Map.of(
                            "transcript", alt.path("transcript").asText(),
                            "confidence", alt.path("confidence").asDouble()
                        ));
                    }

                    log.info("STT 완료: {}자", transcript.length());

                    return Map.of(
                        "success", true,
                        "transcript", transcript.toString().trim(),
                        "confidence", count > 0 ? confidence / count : 0,
                        "alternatives", alternatives,
                        "languageCode", languageCode != null ? languageCode : defaultLanguageCode
                    );
                }

                return Map.of(
                    "success", true,
                    "transcript", "",
                    "confidence", 0,
                    "message", "음성이 감지되지 않았습니다."
                );
            }

        } catch (Exception e) {
            log.error("STT 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "음성 인식 실패");
    }

    /**
     * 기본 설정으로 음성 인식
     */
    public Map<String, Object> recognizeSpeech(byte[] audioData) {
        return recognizeSpeech(audioData, null, 0);
    }

    /**
     * MultipartFile에서 음성 인식
     */
    public Map<String, Object> recognizeSpeech(MultipartFile file, String languageCode) {
        try {
            byte[] audioData = file.getBytes();
            return recognizeSpeech(audioData, languageCode, 0);
        } catch (IOException e) {
            log.error("파일 읽기 실패: {}", e.getMessage());
            return Map.of("success", false, "error", "파일 읽기 실패");
        }
    }

    /**
     * 장시간 음성 인식 (비동기 방식)
     */
    public Map<String, Object> recognizeLongAudio(String gcsUri, String languageCode) {
        log.info("장시간 STT 요청: {}", gcsUri);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of("success", false, "error", "인증 실패");
        }

        String url = "https://speech.googleapis.com/v1/speech:longrunningrecognize";

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> config = Map.of(
                "encoding", "LINEAR16",
                "sampleRateHertz", defaultSampleRate,
                "languageCode", languageCode != null ? languageCode : defaultLanguageCode,
                "enableAutomaticPunctuation", true,
                "enableWordTimeOffsets", true
            );

            Map<String, Object> audio = Map.of("uri", gcsUri);

            Map<String, Object> body = Map.of(
                "config", config,
                "audio", audio
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String operationName = root.path("name").asText();

                log.info("장시간 STT 작업 시작: {}", operationName);

                return Map.of(
                    "success", true,
                    "operationName", operationName,
                    "message", "음성 인식 작업이 시작되었습니다. 작업 ID로 결과를 조회하세요."
                );
            }

        } catch (Exception e) {
            log.error("장시간 STT 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "장시간 음성 인식 시작 실패");
    }

    /**
     * 장시간 음성 인식 결과 조회
     */
    public Map<String, Object> getLongAudioResult(String operationName) {
        log.info("장시간 STT 결과 조회: {}", operationName);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of("success", false, "error", "인증 실패");
        }

        String url = String.format("https://speech.googleapis.com/v1/operations/%s", operationName);

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<Void> request = new HttpEntity<>(headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                boolean done = root.path("done").asBoolean();

                if (done) {
                    JsonNode results = root.path("response").path("results");
                    StringBuilder transcript = new StringBuilder();

                    for (JsonNode result : results) {
                        transcript.append(result.path("alternatives").get(0).path("transcript").asText()).append(" ");
                    }

                    return Map.of(
                        "success", true,
                        "done", true,
                        "transcript", transcript.toString().trim()
                    );
                } else {
                    return Map.of(
                        "success", true,
                        "done", false,
                        "message", "작업이 아직 진행 중입니다."
                    );
                }
            }

        } catch (Exception e) {
            log.error("결과 조회 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "결과 조회 실패");
    }

    /**
     * 실시간 스트리밍 음성 인식 설정 정보
     */
    public Map<String, Object> getStreamingConfig() {
        return Map.of(
            "languageCode", defaultLanguageCode,
            "sampleRateHertz", defaultSampleRate,
            "encoding", "LINEAR16",
            "websocketUrl", String.format("wss://speech.googleapis.com/v1/speech:streamingRecognize?project=%s", projectId),
            "maxDurationSeconds", 300
        );
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean authenticated = getAccessToken() != null;

        return Map.of(
            "service", "speech-to-text",
            "defaultLanguage", defaultLanguageCode,
            "defaultSampleRate", defaultSampleRate,
            "authenticated", authenticated,
            "status", authenticated ? "UP" : "DEGRADED"
        );
    }
}
