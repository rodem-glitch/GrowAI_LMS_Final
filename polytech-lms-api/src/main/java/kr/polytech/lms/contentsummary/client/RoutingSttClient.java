package kr.polytech.lms.contentsummary.client;

import java.nio.file.Path;
import java.util.Locale;
import java.util.Objects;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

/**
 * 왜: STT 제공자(OpenAI/Google)를 설정으로 바꿔가며 실험해야 해서,
 * 서비스 코드(ContentSummaryService)는 "전사해줘"만 호출하고 실제 구현은 여기서 라우팅합니다.
 *
 * - OpenAI STT 코드는 삭제하지 않고 유지합니다(요구사항).
 * - 어떤 STT를 쓸지는 `stt.provider`로 결정합니다.
 */
@Primary
@Component
public class RoutingSttClient implements SttClient {

    private final SttProperties properties;
    private final OpenAiWhisperSttClient openAiWhisperSttClient;
    private final GoogleSpeechV2SttClient googleSpeechV2SttClient;

    public RoutingSttClient(
        SttProperties properties,
        OpenAiWhisperSttClient openAiWhisperSttClient,
        GoogleSpeechV2SttClient googleSpeechV2SttClient
    ) {
        this.properties = Objects.requireNonNull(properties);
        this.openAiWhisperSttClient = Objects.requireNonNull(openAiWhisperSttClient);
        this.googleSpeechV2SttClient = Objects.requireNonNull(googleSpeechV2SttClient);
    }

    @Override
    public String transcribe(Path mediaFile, String language) {
        String provider = normalize(properties.provider());
        if (provider.isBlank() || "openai".equals(provider)) {
            return openAiWhisperSttClient.transcribe(mediaFile, language);
        }
        if ("google".equals(provider) || "gcp".equals(provider) || "gcp-speech-v2".equals(provider)) {
            return googleSpeechV2SttClient.transcribe(mediaFile, language);
        }
        throw new IllegalStateException("지원하지 않는 STT provider 입니다: " + provider + " (openai/google)");
    }

    private static String normalize(String s) {
        return s == null ? "" : s.trim().toLowerCase(Locale.ROOT);
    }
}

