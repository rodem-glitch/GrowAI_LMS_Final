package kr.polytech.lms.contentsummary.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Objects;
import org.springframework.stereotype.Component;

/**
 * 왜: "전사"는 요약보다 앞 단계라서 실패 원인이 다양합니다(파일 포맷/용량/네트워크).
 * 그래서 HTTP 요청/응답을 최대한 단순하고 확실하게(멀티파트 직접 구성) 처리합니다.
 */
@Component
public class OpenAiWhisperSttClient implements SttClient {

    private final SttProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public OpenAiWhisperSttClient(SttProperties properties, ObjectMapper objectMapper) {
        this.properties = Objects.requireNonNull(properties);
        this.objectMapper = Objects.requireNonNull(objectMapper);
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(safeTimeout(properties.httpTimeout(), Duration.ofMinutes(5)))
            .build();
    }

    @Override
    public String transcribe(Path mediaFile, String language) {
        String apiKey = properties.openai().apiKey();
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("stt.openai.api-key 설정이 필요합니다. (환경변수 또는 application-local.yml)");
        }
        if (mediaFile == null) throw new IllegalArgumentException("mediaFile이 null입니다.");
        if (!Files.exists(mediaFile)) throw new IllegalArgumentException("mediaFile이 존재하지 않습니다: " + mediaFile);

        String model = properties.openai().model();
        String lang = (language == null || language.isBlank()) ? properties.language() : language.trim();

        String boundary = "----polytech-lms-api-stt-" + System.currentTimeMillis();
        byte[] body = buildMultipartBody(boundary, model, lang, mediaFile);

        URI uri = URI.create(properties.openai().baseUrl() + "/audio/transcriptions");
        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(safeTimeout(properties.httpTimeout(), Duration.ofMinutes(10)))
            .header("Authorization", "Bearer " + apiKey.trim())
            .header("Content-Type", "multipart/form-data; boundary=" + boundary)
            .POST(HttpRequest.BodyPublishers.ofByteArray(body))
            .build();

        String responseBody = send(request);
        return parseTranscriptionText(responseBody);
    }

    private String send(HttpRequest request) {
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            int status = response.statusCode();
            if (status < 200 || status >= 300) {
                throw new IllegalStateException("STT 호출 실패 (HTTP " + status + ")");
            }
            return response.body();
        } catch (Exception e) {
            throw new IllegalStateException("STT 통신 중 오류가 발생했습니다.", e);
        }
    }

    private String parseTranscriptionText(String body) {
        try {
            JsonNode root = objectMapper.readTree(body);
            String text = root.get("text") == null ? null : root.get("text").asText(null);
            if (text == null) return "";
            return text.trim();
        } catch (Exception e) {
            throw new IllegalStateException("STT 응답 파싱에 실패했습니다.", e);
        }
    }

    private static byte[] buildMultipartBody(String boundary, String model, String language, Path file) {
        try {
            String filename = file.getFileName().toString();
            String contentType = guessContentType(file);
            byte[] fileBytes = Files.readAllBytes(file);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            writePart(out, boundary, "model", model);
            writePart(out, boundary, "language", language);
            writePart(out, boundary, "response_format", "json");

            out.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
            out.write(("Content-Disposition: form-data; name=\"file\"; filename=\"" + escapeQuotes(filename) + "\"\r\n")
                .getBytes(StandardCharsets.UTF_8));
            out.write(("Content-Type: " + contentType + "\r\n\r\n").getBytes(StandardCharsets.UTF_8));
            out.write(fileBytes);
            out.write("\r\n".getBytes(StandardCharsets.UTF_8));

            out.write(("--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("멀티파트 요청 본문 생성에 실패했습니다.", e);
        }
    }

    private static void writePart(ByteArrayOutputStream out, String boundary, String name, String value) throws IOException {
        out.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        out.write(("Content-Disposition: form-data; name=\"" + escapeQuotes(name) + "\"\r\n\r\n")
            .getBytes(StandardCharsets.UTF_8));
        out.write((value == null ? "" : value).getBytes(StandardCharsets.UTF_8));
        out.write("\r\n".getBytes(StandardCharsets.UTF_8));
    }

    private static String escapeQuotes(String s) {
        if (s == null) return "";
        return s.replace("\"", "\\\"");
    }

    private static String guessContentType(Path file) {
        String name = file.getFileName().toString().toLowerCase();
        if (name.endsWith(".wav")) return "audio/wav";
        if (name.endsWith(".mp3")) return "audio/mpeg";
        if (name.endsWith(".m4a")) return "audio/mp4";
        if (name.endsWith(".mp4")) return "video/mp4";
        return "application/octet-stream";
    }

    private static Duration safeTimeout(Duration configured, Duration fallback) {
        if (configured == null) return fallback;
        if (configured.isZero() || configured.isNegative()) return fallback;
        return configured;
    }
}

