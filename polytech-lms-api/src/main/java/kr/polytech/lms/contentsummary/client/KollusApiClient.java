package kr.polytech.lms.contentsummary.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import kr.polytech.lms.contentsummary.dto.KollusChannelContent;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

/**
 * 왜: Kollus API 호출(채널 콘텐츠 조회, media token 발급)을 한 곳에 모아두면,
 * 나중에 "api-vod" 같은 다른 버전으로 바꿀 때도 서비스 로직을 크게 건드리지 않아도 됩니다.
 */
@Component
public class KollusApiClient {

    private static final Pattern MEDIA_INFO_ATTRIBUTE_PATTERN = Pattern.compile(":media-info=\"([^\"]+)\"");

    private final KollusProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public KollusApiClient(KollusProperties properties, ObjectMapper objectMapper) {
        this.properties = Objects.requireNonNull(properties);
        this.objectMapper = Objects.requireNonNull(objectMapper);
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(properties.httpTimeout())
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();
    }

    public List<KollusChannelContent> listChannelContents(int page, int perPage, String keyword) {
        ensureConfigured(properties.accessToken(), "kollus.access-token");
        ensureConfigured(properties.channelKey(), "kollus.channel-key");

        StringBuilder qs = new StringBuilder();
        qs.append("access_token=").append(urlEncode(properties.accessToken()));
        qs.append("&page=").append(page);
        qs.append("&per_page=").append(perPage);
        qs.append("&channel_key=").append(urlEncode(properties.channelKey()));
        qs.append("&order=position_desc");
        if (keyword != null && !keyword.isBlank()) {
            qs.append("&keyword=").append(urlEncode(keyword.trim()));
        }

        URI uri = URI.create(properties.apiBaseUrl() + "/0/media/channel/media_content?" + qs);
        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(properties.httpTimeout())
            .GET()
            .build();

        String body = send(request);
        return parseChannelContents(body);
    }

    public String issueMediaToken(String mediaContentKey) {
        ensureConfigured(properties.accessToken(), "kollus.access-token");
        ensureConfigured(properties.securityKey(), "kollus.security-key");

        if (mediaContentKey == null || mediaContentKey.isBlank()) {
            throw new IllegalArgumentException("mediaContentKey가 비어 있습니다.");
        }

        URI uri = URI.create(properties.apiBaseUrl() + "/0/media_auth/media_token/get_media_link_by_userid");

        String form = ""
            + "security_key=" + urlEncode(properties.securityKey())
            + "&media_content_key=" + urlEncode(mediaContentKey.trim())
            + "&access_token=" + urlEncode(properties.accessToken())
            + "&client_user_id=" + urlEncode(properties.clientUserId())
            + "&expire_time=" + properties.mediaTokenExpireTime().toSeconds()
            + "&awt_code=";

        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(properties.httpTimeout())
            .header("Content-Type", "application/x-www-form-urlencoded")
            .POST(HttpRequest.BodyPublishers.ofString(form))
            .build();

        String body = send(request);
        return parseMediaToken(body);
    }

    public URI buildDownloadUriByMediaToken(String mediaToken) {
        if (mediaToken == null || mediaToken.isBlank()) {
            throw new IllegalArgumentException("mediaToken이 비어 있습니다.");
        }
        // ✅ 왜: `get_media_link_by_userid`는 실제 파일(URL)이 아니라 "media_token"만 내려줍니다.
        // `/si?key=<media_token>`로 바로 파일을 받을 수 있을 것처럼 보이지만,
        // 실제로는 mp4가 아니라 토큰 문자열(text/plain)을 내려줘서 ffmpeg가 실패합니다.
        //
        // 해결: 플레이어 페이지(`/s?key=...`) HTML 안의 `:media-info="...JSON..."`에
        // 서명된 mp4 URL(xcdn.kollus.com/...mp4?sign=...)이 들어있어,
        // 그 mp4 URL을 찾아서 다운로드에 사용합니다.
        URI playerPage = URI.create(properties.playerBaseUrl() + "/s?key=" + urlEncode(mediaToken.trim()));
        HttpRequest request = HttpRequest.newBuilder(playerPage)
            .timeout(properties.httpTimeout())
            .GET()
            .build();

        String html = send(request);
        return extractSignedMp4UriFromPlayerHtml(html);
    }

    private URI extractSignedMp4UriFromPlayerHtml(String html) {
        try {
            if (html == null || html.isBlank()) {
                throw new IllegalStateException("플레이어 HTML 응답이 비어 있습니다.");
            }

            Matcher m = MEDIA_INFO_ATTRIBUTE_PATTERN.matcher(html);
            if (!m.find()) {
                throw new IllegalStateException("플레이어 HTML에서 media-info를 찾지 못했습니다.");
            }

            // HTML attribute 안이라 &quot; 같은 엔티티가 섞여 있습니다. JSON 파싱 전에 풀어줘야 합니다.
            String encodedJson = m.group(1);
            String json = HtmlUtils.htmlUnescape(encodedJson);
            JsonNode root = objectMapper.readTree(json);

            String mp4Url = findBestMp4Url(root);
            if (mp4Url == null || mp4Url.isBlank()) {
                throw new IllegalStateException("플레이어 media-info에서 MP4 URL을 찾지 못했습니다.");
            }
            return URI.create(mp4Url.trim());
        } catch (Exception e) {
            // ✅ media_token 같은 민감 값이 예외 메시지/로그에 섞이지 않도록, 원문 HTML은 포함하지 않습니다.
            throw new IllegalStateException("Kollus 플레이어 HTML에서 다운로드 URL을 해석하지 못했습니다.", e);
        }
    }

    private static String findBestMp4Url(JsonNode root) {
        // 1) 가장 흔한 케이스: 서명 파라미터(sign=)가 붙은 mp4 URL
        String signed = findFirstText(root, s -> isMp4Url(s) && s.contains("sign="));
        if (signed != null) return signed;

        // 2) fallback: sign이 없어도 mp4 URL이면 사용(환경/계정에 따라 다를 수 있음)
        return findFirstText(root, KollusApiClient::isMp4Url);
    }

    private static boolean isMp4Url(String s) {
        if (s == null) return false;
        String t = s.trim();
        if (!(t.startsWith("http://") || t.startsWith("https://"))) return false;
        // 썸네일 파일명 패턴: xxx.mp4.[big].jpg 같은 케이스는 제외
        if (t.contains(".mp4.")) return false;
        return t.matches("(?i).+\\.mp4(\\?.*)?$");
    }

    private static String findFirstText(JsonNode node, java.util.function.Predicate<String> predicate) {
        if (node == null || node.isNull() || node.isMissingNode()) return null;
        if (node.isTextual()) {
            String s = node.asText();
            return predicate.test(s) ? s : null;
        }
        if (node.isArray()) {
            for (JsonNode child : node) {
                String found = findFirstText(child, predicate);
                if (found != null) return found;
            }
        }
        if (node.isObject()) {
            for (java.util.Iterator<JsonNode> it = node.elements(); it.hasNext(); ) {
                String found = findFirstText(it.next(), predicate);
                if (found != null) return found;
            }
        }
        return null;
    }

    private String send(HttpRequest request) {
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            int status = response.statusCode();
            if (status < 200 || status >= 300) {
                // 왜: access token 같은 비밀값이 로그에 섞이면 사고가 나서, 본문 전체를 그대로 던지지 않습니다.
                throw new IllegalStateException("Kollus API 호출 실패 (HTTP " + status + ")");
            }
            return response.body();
        } catch (Exception e) {
            throw new IllegalStateException("Kollus API 통신 중 오류가 발생했습니다.", e);
        }
    }

    private List<KollusChannelContent> parseChannelContents(String body) {
        try {
            JsonNode root = objectMapper.readTree(body);
            JsonNode items = root.at("/result/items/item");
            List<KollusChannelContent> out = new ArrayList<>();
            if (items.isArray()) {
                for (JsonNode item : items) {
                    String mediaKey = text(item, "media_content_key");
                    String title = text(item, "title");
                    Integer totalTime = intOrNull(item, "total_time");
                    if (mediaKey == null || mediaKey.isBlank()) continue;
                    out.add(new KollusChannelContent(mediaKey, title, totalTime));
                }
            }
            return out;
        } catch (Exception e) {
            throw new IllegalStateException("Kollus 채널 콘텐츠 목록 파싱에 실패했습니다.", e);
        }
    }

    private String parseMediaToken(String body) {
        try {
            JsonNode root = objectMapper.readTree(body);
            String token = root.at("/result/media_token").asText(null);
            if (token == null || token.isBlank()) {
                throw new IllegalStateException("media_token이 응답에 없습니다.");
            }
            return token;
        } catch (Exception e) {
            throw new IllegalStateException("Kollus media token 파싱에 실패했습니다.", e);
        }
    }

    private static String text(JsonNode node, String field) {
        if (node == null) return null;
        JsonNode v = node.get(field);
        if (v == null || v.isNull()) return null;
        String s = v.asText();
        return s == null ? null : s.trim();
    }

    private static Integer intOrNull(JsonNode node, String field) {
        if (node == null) return null;
        JsonNode v = node.get(field);
        if (v == null || v.isNull()) return null;
        if (!v.isNumber()) {
            String s = v.asText();
            if (s == null || s.isBlank()) return null;
            try {
                return Integer.parseInt(s.trim());
            } catch (Exception ignored) {
                return null;
            }
        }
        return v.intValue();
    }

    private static String urlEncode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static void ensureConfigured(String value, String propertyName) {
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(propertyName + " 설정이 필요합니다. (환경변수 또는 application-local.yml)");
        }
    }
}

