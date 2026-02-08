package kr.polytech.lms.contentsummary.client;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: Kollus 연동에 필요한 값(토큰/채널/타임아웃)은 환경마다 달라서, 코드에 박아두면(하드코딩) 운영에서 바로 사고가 납니다.
 * 그래서 Spring 설정(application-local.yml, 환경변수 등)으로 주입받도록 분리합니다.
 */
@ConfigurationProperties(prefix = "kollus")
public class KollusProperties {

    private String apiBaseUrl;
    private String accessToken;
    private String securityKey;
    private String channelKey;
    private String clientUserId;
    private Duration httpTimeout;
    private Duration mediaTokenExpireTime;
    private String playerBaseUrl;

    public KollusProperties() {
    }

    public String apiBaseUrl() {
        return apiBaseUrl;
    }

    public void setApiBaseUrl(String apiBaseUrl) {
        // 왜: 사용자가 "api.kr.kollus.com"처럼 스킴을 빼고 넣는 경우가 많아서, 최소한의 보정은 여기서 합니다.
        this.apiBaseUrl = normalizeBaseUrl(apiBaseUrl, "https://api.kr.kollus.com");
    }

    public String accessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String securityKey() {
        return securityKey;
    }

    public void setSecurityKey(String securityKey) {
        this.securityKey = securityKey;
    }

    public String channelKey() {
        return channelKey;
    }

    public void setChannelKey(String channelKey) {
        this.channelKey = channelKey;
    }

    public String clientUserId() {
        return clientUserId;
    }

    public void setClientUserId(String clientUserId) {
        this.clientUserId = (clientUserId == null || clientUserId.isBlank()) ? "contentsummary" : clientUserId.trim();
    }

    public Duration httpTimeout() {
        return httpTimeout;
    }

    public void setHttpTimeout(Duration httpTimeout) {
        this.httpTimeout = httpTimeout == null ? Duration.ofSeconds(60) : httpTimeout;
    }

    public Duration mediaTokenExpireTime() {
        return mediaTokenExpireTime;
    }

    public void setMediaTokenExpireTime(Duration mediaTokenExpireTime) {
        this.mediaTokenExpireTime = mediaTokenExpireTime == null ? Duration.ofMinutes(5) : mediaTokenExpireTime;
    }

    public String playerBaseUrl() {
        return playerBaseUrl;
    }

    public void setPlayerBaseUrl(String playerBaseUrl) {
        this.playerBaseUrl = normalizeBaseUrl(playerBaseUrl, "https://v.kr.kollus.com");
    }

    private static String normalizeBaseUrl(String baseUrl, String defaultValue) {
        if (baseUrl == null || baseUrl.isBlank()) return defaultValue;
        String trimmed = baseUrl.trim();
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) return trimmed;
        return "https://" + trimmed;
    }
}
