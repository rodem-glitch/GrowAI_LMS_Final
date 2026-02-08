// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/config/GcpConfig.java
package kr.polytech.lms.gcp.config;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;

/**
 * GCP 서비스 통합 설정
 * REST API 방식으로 연동하므로 클라이언트 라이브러리는 사용하지 않음
 * - Vertex AI (aiplatform.googleapis.com)
 * - BigQuery (bigquery.googleapis.com)
 * - Text-to-Speech (texttospeech.googleapis.com)
 * - Speech-to-Text (speech.googleapis.com)
 */
@Slf4j
@Configuration
@Getter
public class GcpConfig {

    @Value("${gcp.project-id:polytech-lms}")
    private String projectId;

    @Value("${gcp.location:asia-northeast3}")
    private String location;

    @Value("${gcp.credentials-path:}")
    private String credentialsPath;

    @Value("${gcp.vertex-ai.embedding-model:text-multilingual-embedding-002}")
    private String vertexEmbeddingModel;

    @Value("${gcp.vertex-ai.text-model:gemini-1.5-flash}")
    private String vertexTextModel;

    @Value("${gcp.bigquery.dataset:lms_analytics}")
    private String bigQueryDataset;

    @Value("${gcp.tts.language-code:ko-KR}")
    private String ttsLanguageCode;

    @Value("${gcp.tts.voice-name:ko-KR-Wavenet-A}")
    private String ttsVoiceName;

    @Value("${gcp.stt.language-code:ko-KR}")
    private String sttLanguageCode;

    @Value("${gcp.stt.sample-rate:16000}")
    private int sttSampleRate;

    @PostConstruct
    public void init() {
        log.info("GCP 서비스 설정 로드 완료");
        log.info("  - Project ID: {}", projectId);
        log.info("  - Location: {}", location);
        log.info("  - Vertex AI Embedding: {}", vertexEmbeddingModel);
        log.info("  - Vertex AI Text: {}", vertexTextModel);
        log.info("  - BigQuery Dataset: {}", bigQueryDataset);
        log.info("  - TTS Voice: {}", ttsVoiceName);
        log.info("  - STT Language: {}", sttLanguageCode);

        if (credentialsPath == null || credentialsPath.isEmpty()) {
            log.info("  - 인증: GOOGLE_APPLICATION_CREDENTIALS 환경변수 또는 ADC 사용");
        } else {
            log.info("  - 인증: {}", credentialsPath);
        }
    }
}
