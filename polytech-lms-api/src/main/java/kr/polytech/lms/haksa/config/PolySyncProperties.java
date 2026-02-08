// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/config/PolySyncProperties.java
package kr.polytech.lms.haksa.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * 학사포털(e-poly) 회원 동기화 설정
 * poly_sync.jsp 동등 구현을 위한 프로퍼티
 */
@ConfigurationProperties(prefix = "poly-sync")
public class PolySyncProperties {

    private boolean enabled;
    private String endpoint;
    private Duration httpTimeout;
    private int batchSize;
    private int maxRetries;
    private long retryDelayMs;

    public PolySyncProperties() {
    }

    /** 동기화 활성화 여부 */
    public boolean enabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    /** 학사포털 VPN 엔드포인트 (예: https://e-poly.kopo.ac.kr/main/vpn_test.jsp) */
    public String endpoint() {
        return endpoint;
    }

    public void setEndpoint(String endpoint) {
        if (endpoint == null || endpoint.isBlank()) {
            this.endpoint = "https://e-poly.kopo.ac.kr/main/vpn_test.jsp";
        } else {
            this.endpoint = endpoint;
        }
    }

    /** HTTP 요청 타임아웃 */
    public Duration httpTimeout() {
        return httpTimeout;
    }

    public void setHttpTimeout(Duration httpTimeout) {
        this.httpTimeout = (httpTimeout == null) ? Duration.ofSeconds(60) : httpTimeout;
    }

    /** 배치 사이즈 (fetchPolyRaw의 한번 조회 건수) */
    public int batchSize() {
        return batchSize;
    }

    public void setBatchSize(int batchSize) {
        this.batchSize = (batchSize <= 0) ? 2000 : batchSize;
    }

    /** 재시도 횟수 */
    public int maxRetries() {
        return maxRetries;
    }

    public void setMaxRetries(int maxRetries) {
        this.maxRetries = (maxRetries <= 0) ? 3 : maxRetries;
    }

    /** 재시도 간 대기(ms) */
    public long retryDelayMs() {
        return retryDelayMs;
    }

    public void setRetryDelayMs(long retryDelayMs) {
        this.retryDelayMs = (retryDelayMs <= 0) ? 3000 : retryDelayMs;
    }
}
