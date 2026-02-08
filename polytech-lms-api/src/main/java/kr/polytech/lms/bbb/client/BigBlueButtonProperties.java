// polytech-lms-api/src/main/java/kr/polytech/lms/bbb/client/BigBlueButtonProperties.java
package kr.polytech.lms.bbb.client;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * BigBlueButton 화상강의 설정
 */
@ConfigurationProperties(prefix = "bbb")
public record BigBlueButtonProperties(
    String baseUrl,
    String secret,
    boolean enabled
) {
    public BigBlueButtonProperties {
        if (baseUrl == null) baseUrl = "http://localhost:8090/bigbluebutton";
        if (enabled == false) enabled = false;
    }
}
