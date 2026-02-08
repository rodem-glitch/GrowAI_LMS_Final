// polytech-lms-api/src/main/java/kr/polytech/lms/bbb/client/BigBlueButtonProperties.java
package kr.polytech.lms.bbb.client;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * BigBlueButton 화상강의 설정
 */
@ConfigurationProperties(prefix = "bbb")
public class BigBlueButtonProperties {

    private String baseUrl;
    private String secret;
    private boolean enabled;

    public BigBlueButtonProperties() {
    }

    public String baseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = (baseUrl == null) ? "http://localhost:8090/bigbluebutton" : baseUrl;
    }

    public String secret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }

    public boolean enabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }
}
