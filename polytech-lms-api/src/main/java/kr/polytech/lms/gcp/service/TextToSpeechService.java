// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/TextToSpeechService.java
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
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

/**
 * Text-to-Speech 서비스
 * texttospeech.googleapis.com REST API 연동
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TextToSpeechService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    @Value("${gcp.tts.language-code:ko-KR}")
    private String defaultLanguageCode;

    @Value("${gcp.tts.voice-name:ko-KR-Wavenet-A}")
    private String defaultVoiceName;

    @Value("${gcp.tts.output-dir:./tts-output}")
    private String outputDir;

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
     * 텍스트를 음성으로 변환
     */
    public Map<String, Object> synthesizeSpeech(String text, String voiceName, String languageCode) {
        log.info("TTS 요청: {}자, voice={}", text.length(), voiceName);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of(
                "success", false,
                "error", "인증 실패"
            );
        }

        String url = "https://texttospeech.googleapis.com/v1/text:synthesize";

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> input = Map.of("text", text);
            Map<String, Object> voice = Map.of(
                "languageCode", languageCode != null ? languageCode : defaultLanguageCode,
                "name", voiceName != null ? voiceName : defaultVoiceName
            );
            Map<String, Object> audioConfig = Map.of(
                "audioEncoding", "MP3",
                "speakingRate", 1.0,
                "pitch", 0.0
            );

            Map<String, Object> body = Map.of(
                "input", input,
                "voice", voice,
                "audioConfig", audioConfig
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String audioContent = root.path("audioContent").asText();

                // Base64 디코딩하여 파일 저장
                byte[] audioBytes = Base64.getDecoder().decode(audioContent);
                String fileName = "tts_" + System.currentTimeMillis() + ".mp3";
                Path outputPath = Path.of(outputDir, fileName);

                Files.createDirectories(outputPath.getParent());
                Files.write(outputPath, audioBytes);

                log.info("TTS 완료: {}", outputPath);

                return Map.of(
                    "success", true,
                    "fileName", fileName,
                    "filePath", outputPath.toString(),
                    "fileSize", audioBytes.length,
                    "audioBase64", audioContent
                );
            }

        } catch (Exception e) {
            log.error("TTS 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "음성 합성 실패");
    }

    /**
     * 기본 설정으로 음성 변환
     */
    public Map<String, Object> synthesizeSpeech(String text) {
        return synthesizeSpeech(text, null, null);
    }

    /**
     * SSML로 음성 변환
     */
    public Map<String, Object> synthesizeSsml(String ssml, String voiceName, String languageCode) {
        log.info("TTS SSML 요청: {}자", ssml.length());

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return Map.of("success", false, "error", "인증 실패");
        }

        String url = "https://texttospeech.googleapis.com/v1/text:synthesize";

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> input = Map.of("ssml", ssml);
            Map<String, Object> voice = Map.of(
                "languageCode", languageCode != null ? languageCode : defaultLanguageCode,
                "name", voiceName != null ? voiceName : defaultVoiceName
            );
            Map<String, Object> audioConfig = Map.of("audioEncoding", "MP3");

            Map<String, Object> body = Map.of(
                "input", input,
                "voice", voice,
                "audioConfig", audioConfig
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String audioContent = root.path("audioContent").asText();

                return Map.of(
                    "success", true,
                    "audioBase64", audioContent
                );
            }

        } catch (Exception e) {
            log.error("TTS SSML 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "SSML 음성 합성 실패");
    }

    /**
     * 사용 가능한 음성 목록 조회
     */
    public List<Map<String, Object>> listVoices(String languageCode) {
        log.info("음성 목록 조회: {}", languageCode);

        String accessToken = getAccessToken();
        if (accessToken == null) {
            return getDefaultVoiceList();
        }

        String url = "https://texttospeech.googleapis.com/v1/voices";
        if (languageCode != null) {
            url += "?languageCode=" + languageCode;
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<Void> request = new HttpEntity<>(headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                List<Map<String, Object>> voices = new ArrayList<>();

                for (JsonNode voice : root.path("voices")) {
                    voices.add(Map.of(
                        "name", voice.path("name").asText(),
                        "languageCodes", voice.path("languageCodes"),
                        "ssmlGender", voice.path("ssmlGender").asText(),
                        "naturalSampleRateHertz", voice.path("naturalSampleRateHertz").asInt()
                    ));
                }

                return voices;
            }

        } catch (Exception e) {
            log.error("음성 목록 조회 실패: {}", e.getMessage());
        }

        return getDefaultVoiceList();
    }

    /**
     * 기본 음성 목록 (폴백용)
     */
    private List<Map<String, Object>> getDefaultVoiceList() {
        return List.of(
            Map.of("name", "ko-KR-Wavenet-A", "gender", "FEMALE", "type", "Wavenet"),
            Map.of("name", "ko-KR-Wavenet-B", "gender", "FEMALE", "type", "Wavenet"),
            Map.of("name", "ko-KR-Wavenet-C", "gender", "MALE", "type", "Wavenet"),
            Map.of("name", "ko-KR-Wavenet-D", "gender", "MALE", "type", "Wavenet"),
            Map.of("name", "ko-KR-Standard-A", "gender", "FEMALE", "type", "Standard"),
            Map.of("name", "ko-KR-Standard-B", "gender", "FEMALE", "type", "Standard"),
            Map.of("name", "ko-KR-Standard-C", "gender", "MALE", "type", "Standard"),
            Map.of("name", "ko-KR-Standard-D", "gender", "MALE", "type", "Standard")
        );
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean authenticated = getAccessToken() != null;

        return Map.of(
            "service", "text-to-speech",
            "defaultLanguage", defaultLanguageCode,
            "defaultVoice", defaultVoiceName,
            "authenticated", authenticated,
            "status", authenticated ? "UP" : "DEGRADED"
        );
    }
}
