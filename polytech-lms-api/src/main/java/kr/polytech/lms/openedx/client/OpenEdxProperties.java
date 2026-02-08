// polytech-lms-api/src/main/java/kr/polytech/lms/openedx/client/OpenEdxProperties.java
package kr.polytech.lms.openedx.client;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Open edX 연동 설정
 * LMS 플랫폼 API 연동을 위한 속성
 */
@ConfigurationProperties(prefix = "openedx")
public class OpenEdxProperties {

    private String baseUrl;
    private String clientId;
    private String clientSecret;
    private String oauthTokenUrl;
    private boolean enabled;

    public OpenEdxProperties() {
    }

    public String baseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = (baseUrl == null) ? "http://localhost:18000" : baseUrl;
    }

    public String clientId() {
        return clientId;
    }

    public void setClientId(String clientId) {
        this.clientId = clientId;
    }

    public String clientSecret() {
        return clientSecret;
    }

    public void setClientSecret(String clientSecret) {
        this.clientSecret = clientSecret;
    }

    public String oauthTokenUrl() {
        return oauthTokenUrl;
    }

    public void setOauthTokenUrl(String oauthTokenUrl) {
        if (oauthTokenUrl == null) {
            // Use baseUrl if already set, otherwise use default
            String base = (this.baseUrl != null) ? this.baseUrl : "http://localhost:18000";
            this.oauthTokenUrl = base + "/oauth2/access_token";
        } else {
            this.oauthTokenUrl = oauthTokenUrl;
        }
    }

    public boolean enabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }
}
