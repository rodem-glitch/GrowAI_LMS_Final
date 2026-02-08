// polytech-lms-api/src/main/java/kr/polytech/lms/openedx/client/OpenEdxProperties.java
package kr.polytech.lms.openedx.client;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Open edX 연동 설정
 * LMS 플랫폼 API 연동을 위한 속성
 */
@ConfigurationProperties(prefix = "openedx")
public record OpenEdxProperties(
    String baseUrl,
    String clientId,
    String clientSecret,
    String oauthTokenUrl,
    boolean enabled
) {
    public OpenEdxProperties {
        if (baseUrl == null) baseUrl = "http://localhost:18000";
        if (oauthTokenUrl == null) oauthTokenUrl = baseUrl + "/oauth2/access_token";
        if (enabled == false) enabled = false;
    }
}
