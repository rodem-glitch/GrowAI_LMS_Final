package kr.polytech.lms.contentsummary.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import kr.polytech.lms.contentsummary.dto.RecoContentSummaryDraft;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Gemini 3 Flash를 사용하여 영상 파일에서 직접 요약을 생성하는 클라이언트.
 * 왜: STT + 전사 텍스트 요약 대신 영상을 직접 처리하면 단계가 줄고 GCS 권한이 필요 없어집니다.
 */
@Component
public class GeminiVideoSummaryClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiVideoSummaryClient.class);

    private static final String UPLOAD_BASE_URL = "https://generativelanguage.googleapis.com/upload/v1beta/files";
    private static final int CHUNK_SIZE = 8 * 1024 * 1024; // 8MB chunks for resumable upload

    private final GeminiProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public GeminiVideoSummaryClient(GeminiProperties properties, ObjectMapper objectMapper) {
        this.properties = Objects.requireNonNull(properties);
        this.objectMapper = Objects.requireNonNull(objectMapper);
        // 왜: 영상 업로드는 시간이 오래 걸릴 수 있으므로 타임아웃을 넉넉하게 설정합니다.
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofMinutes(5))
            .build();
    }

    /**
     * 영상 파일을 Gemini File API에 업로드하고 file URI를 반환합니다.
     */
    public String uploadVideo(Path videoFile) throws IOException, InterruptedException {
        if (!Files.exists(videoFile)) {
            throw new IllegalArgumentException("영상 파일이 존재하지 않습니다: " + videoFile);
        }

        String apiKey = requireApiKey();
        long fileSize = Files.size(videoFile);
        String mimeType = detectMimeType(videoFile);
        String displayName = videoFile.getFileName().toString();

        log.info("Gemini File API 업로드 시작: {} ({}bytes, {})", displayName, fileSize, mimeType);

        // Step 1: Initiate resumable upload
        String uploadUrl = initiateResumableUpload(apiKey, fileSize, mimeType, displayName);

        // Step 2: Upload file content
        String fileUri = uploadFileContent(uploadUrl, videoFile, fileSize);

        log.info("Gemini File API 업로드 완료: {}", fileUri);
        return fileUri;
    }

    /**
     * 업로드된 영상에서 직접 요약을 생성합니다.
     */
    public RecoContentSummaryDraft summarizeFromVideo(String fileUri, String title, String mimeType) {
        if (fileUri == null || fileUri.isBlank()) {
            throw new IllegalArgumentException("fileUri가 비어 있습니다.");
        }

        String apiKey = requireApiKey();
        String model = properties.model();
        String safeTitle = title == null ? "" : title.trim();

        URI uri = URI.create(properties.baseUrl()
            + "/models/"
            + urlEncode(model)
            + ":generateContent?key="
            + urlEncode(apiKey.trim()));

        String prompt = buildVideoSummaryPrompt(safeTitle);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("contents", List.of(
            Map.of(
                "role", "user",
                "parts", List.of(
                    Map.of("file_data", Map.of(
                        "mime_type", mimeType,
                        "file_uri", fileUri
                    )),
                    Map.of("text", prompt)
                )
            )
        ));
        body.put("generationConfig", Map.of(
            "temperature", properties.temperature(),
            "maxOutputTokens", properties.maxOutputTokens()
        ));

        String jsonBody = toJson(body);

        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(Duration.ofMinutes(10)) // 영상 분석은 시간이 더 걸릴 수 있음
            .header("Content-Type", "application/json; charset=utf-8")
            .POST(HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8))
            .build();

        String responseBody = send(request);
        String rawJson = extractCandidateText(responseBody);

        return parseAndNormalize(rawJson);
    }

    /**
     * 영상 파일을 업로드하고 바로 요약을 생성합니다 (편의 메서드).
     */
    public RecoContentSummaryDraft uploadAndSummarize(Path videoFile, String title) throws IOException, InterruptedException {
        String mimeType = detectMimeType(videoFile);
        String fileUri = uploadVideo(videoFile);
        return summarizeFromVideo(fileUri, title, mimeType);
    }

    private String initiateResumableUpload(String apiKey, long fileSize, String mimeType, String displayName) 
            throws IOException, InterruptedException {
        URI uri = URI.create(UPLOAD_BASE_URL + "?key=" + urlEncode(apiKey));

        Map<String, Object> metadata = Map.of("file", Map.of("display_name", displayName));
        String metadataJson = toJson(metadata);

        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(Duration.ofMinutes(2))
            .header("X-Goog-Upload-Protocol", "resumable")
            .header("X-Goog-Upload-Command", "start")
            .header("X-Goog-Upload-Header-Content-Length", String.valueOf(fileSize))
            .header("X-Goog-Upload-Header-Content-Type", mimeType)
            .header("Content-Type", "application/json; charset=utf-8")
            .POST(HttpRequest.BodyPublishers.ofString(metadataJson, StandardCharsets.UTF_8))
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        if (response.statusCode() != 200) {
            throw new IllegalStateException("Gemini File API 업로드 초기화 실패 (HTTP " + response.statusCode() + "): " + response.body());
        }

        // Get the upload URL from response header
        String uploadUrl = response.headers().firstValue("X-Goog-Upload-URL").orElse(null);
        if (uploadUrl == null || uploadUrl.isBlank()) {
            throw new IllegalStateException("Gemini File API 응답에 업로드 URL이 없습니다.");
        }

        return uploadUrl;
    }

    private String uploadFileContent(String uploadUrl, Path videoFile, long fileSize) 
            throws IOException, InterruptedException {
        byte[] fileBytes = Files.readAllBytes(videoFile);

        HttpRequest request = HttpRequest.newBuilder(URI.create(uploadUrl))
            .timeout(Duration.ofMinutes(30)) // 대용량 파일 업로드 타임아웃
            .header("X-Goog-Upload-Offset", "0")
            .header("X-Goog-Upload-Command", "upload, finalize")
            // Content-Length는 HttpClient가 자동 설정하므로 생략
            .POST(HttpRequest.BodyPublishers.ofByteArray(fileBytes))
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        if (response.statusCode() != 200) {
            throw new IllegalStateException("Gemini File API 파일 업로드 실패 (HTTP " + response.statusCode() + "): " + response.body());
        }

        // Parse response to get file URI
        try {
            JsonNode root = objectMapper.readTree(response.body());
            JsonNode fileNode = root.get("file");
            if (fileNode == null) {
                throw new IllegalStateException("응답에 file 정보가 없습니다.");
            }
            String uri = fileNode.has("uri") ? fileNode.get("uri").asText() : null;
            if (uri == null || uri.isBlank()) {
                throw new IllegalStateException("응답에 file.uri가 없습니다.");
            }
            return uri;
        } catch (Exception e) {
            throw new IllegalStateException("Gemini File API 응답 파싱 실패: " + response.body(), e);
        }
    }

    private String buildVideoSummaryPrompt(String title) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 교육용 영상 콘텐츠를 추천하기 위한 메타데이터를 생성하는 도우미입니다.\n");
        sb.append("이 영상을 분석하고, 반드시 JSON만 출력하세요(설명/마크다운/코드블록 금지).\n");
        sb.append("JSON 스키마:\n");
        sb.append("{\n");
        sb.append("  \"category_nm\": \"기술분야 키워드 2개(쉼표로 구분)\",\n");
        sb.append("  \"summary\": \"영상 내용 요약 200~300자(공백 포함, 한글)\",\n");
        sb.append("  \"keywords\": [\"키워드1\", \"키워드2\", \"... 최대 10개\"]\n");
        sb.append("}\n");
        sb.append("규칙:\n");
        sb.append("- category_nm은 정확히 2개 키워드로 구성하고, 너무 일반적인 단어(예: 기술, 강의)는 피하세요.\n");
        sb.append("- summary는 200~300자(공백 포함) 1문단으로 작성하세요.\n");
        sb.append("- keywords는 영상 내용을 대표하는 키워드를 최대 10개까지, 중복 없이 작성하세요.\n");
        sb.append("- 영상의 음성과 화면 내용을 모두 참고하여 분석하세요.\n");
        if (!title.isBlank()) {
            sb.append("\n영상 제목: ").append(title).append("\n");
        }
        return sb.toString();
    }

    private RecoContentSummaryDraft parseAndNormalize(String raw) {
        JsonNode json = parseJsonFromText(raw);
        String categoryNm = text(json, "category_nm");
        String summary = text(json, "summary");
        List<String> keywords = readKeywords(json.get("keywords"));

        String normalizedCategory = normalizeCategory(categoryNm, keywords);
        List<String> normalizedKeywords = normalizeKeywords(keywords);

        return new RecoContentSummaryDraft(
            normalizedCategory,
            summary == null ? "" : summary.trim().replaceAll("\\s+", " "),
            normalizedKeywords
        );
    }

    private JsonNode parseJsonFromText(String raw) {
        String s = raw == null ? "" : raw.trim();
        if (s.startsWith("```")) {
            s = s.replaceAll("^```[a-zA-Z]*\\s*", "").replaceAll("\\s*```$", "").trim();
        }
        int start = s.indexOf('{');
        int end = s.lastIndexOf('}');
        if (start >= 0 && end > start) {
            s = s.substring(start, end + 1);
        }
        try {
            return objectMapper.readTree(s);
        } catch (Exception e) {
            throw new IllegalStateException("요약 JSON 파싱에 실패했습니다. 원문=" + safeSnippet(raw), e);
        }
    }

    private String normalizeCategory(String categoryNm, List<String> keywords) {
        List<String> parts = splitTokens(categoryNm);
        if (parts.size() >= 2) {
            return parts.get(0) + ", " + parts.get(1);
        }
        if (parts.size() == 1) {
            String second = keywords != null && !keywords.isEmpty() ? keywords.get(0) : "기타";
            if (second.equals(parts.get(0))) second = "기타";
            return parts.get(0) + ", " + second;
        }
        if (keywords != null && keywords.size() >= 2) {
            return keywords.get(0) + ", " + keywords.get(1);
        }
        if (keywords != null && keywords.size() == 1) {
            return keywords.get(0) + ", 기타";
        }
        return "기타, 기타";
    }

    private List<String> normalizeKeywords(List<String> keywords) {
        List<String> out = new ArrayList<>();
        if (keywords != null) {
            for (String k : keywords) {
                if (k == null) continue;
                String t = k.trim();
                if (t.isBlank()) continue;
                if (!out.contains(t)) out.add(t);
                if (out.size() >= 10) break;
            }
        }
        return out;
    }

    private static List<String> splitTokens(String raw) {
        if (raw == null) return List.of();
        String s = raw.trim();
        if (s.isBlank()) return List.of();
        String normalized = s.replace("|", ",").replace("/", ",").replace("·", ",");
        String[] arr = normalized.split(",");
        List<String> out = new ArrayList<>();
        for (String a : arr) {
            if (a == null) continue;
            String t = a.trim();
            if (t.isBlank()) continue;
            out.add(t);
        }
        return out;
    }

    private static String text(JsonNode root, String field) {
        if (root == null) return null;
        JsonNode v = root.get(field);
        if (v == null || v.isNull()) return null;
        String s = v.asText(null);
        return s == null ? null : s.trim();
    }

    private List<String> readKeywords(JsonNode node) {
        if (node == null || node.isNull() || node.isMissingNode()) return List.of();
        if (node.isArray()) {
            List<String> out = new ArrayList<>();
            for (JsonNode n : node) {
                if (n == null || n.isNull()) continue;
                String s = n.asText(null);
                if (s == null || s.isBlank()) continue;
                out.add(s.trim());
                if (out.size() >= 10) break;
            }
            return out;
        }
        String s = node.asText("");
        if (s.isBlank()) return List.of();
        String normalized = s.replace("\n", ",");
        String[] arr = normalized.split(",");
        List<String> out = new ArrayList<>();
        for (String a : arr) {
            String t = a == null ? "" : a.trim();
            if (t.isBlank()) continue;
            out.add(t);
            if (out.size() >= 10) break;
        }
        return out;
    }

    private String send(HttpRequest request) {
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            int status = response.statusCode();
            if (status < 200 || status >= 300) {
                throw new IllegalStateException("Gemini API 호출 실패 (HTTP " + status + "): " + safeSnippet(response.body()));
            }
            return response.body();
        } catch (Exception e) {
            throw new IllegalStateException("Gemini API 통신 중 오류가 발생했습니다.", e);
        }
    }

    private String extractCandidateText(String body) {
        try {
            JsonNode root = objectMapper.readTree(body);
            JsonNode text = root.at("/candidates/0/content/parts/0/text");
            if (text.isMissingNode() || text.isNull()) return "";
            String v = text.asText("");
            return v == null ? "" : v.trim();
        } catch (Exception e) {
            throw new IllegalStateException("Gemini 응답 파싱에 실패했습니다.", e);
        }
    }

    private String requireApiKey() {
        String apiKey = properties.apiKey();
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("gemini.api-key 설정이 필요합니다.");
        }
        return apiKey.trim();
    }

    private String detectMimeType(Path file) {
        String fileName = file.getFileName().toString().toLowerCase();
        if (fileName.endsWith(".mp4")) return "video/mp4";
        if (fileName.endsWith(".mpeg") || fileName.endsWith(".mpg")) return "video/mpeg";
        if (fileName.endsWith(".mov")) return "video/quicktime";
        if (fileName.endsWith(".avi")) return "video/x-msvideo";
        if (fileName.endsWith(".webm")) return "video/webm";
        if (fileName.endsWith(".mkv")) return "video/x-matroska";
        // 기본값은 mp4
        return "video/mp4";
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("JSON 생성에 실패했습니다.", e);
        }
    }

    private static String urlEncode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static String safeSnippet(String raw) {
        if (raw == null) return "";
        String s = raw.replace("\r", " ").replace("\n", " ").trim();
        if (s.length() <= 500) return s;
        return s.substring(0, 500) + "...";
    }
}
