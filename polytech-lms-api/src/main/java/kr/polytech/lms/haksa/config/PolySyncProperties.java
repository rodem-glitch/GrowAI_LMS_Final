// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/config/PolySyncProperties.java
package kr.polytech.lms.haksa.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * 학사포털(e-poly) 회원 동기화 설정
 * poly_sync.jsp 동등 구현을 위한 프로퍼티
 */
@ConfigurationProperties(prefix = "poly-sync")
public record PolySyncProperties(
    /** 동기화 활성화 여부 */
    boolean enabled,
    /** 학사포털 VPN 엔드포인트 (예: https://e-poly.kopo.ac.kr/main/vpn_test.jsp) */
    String endpoint,
    /** HTTP 요청 타임아웃 */
    Duration httpTimeout,
    /** 배치 사이즈 (fetchPolyRaw의 한번 조회 건수) */
    int batchSize,
    /** 재시도 횟수 */
    int maxRetries,
    /** 재시도 간 대기(ms) */
    long retryDelayMs
) {
    public PolySyncProperties {
        // 기본값 설정
        if (endpoint == null || endpoint.isBlank()) {
            endpoint = "https://e-poly.kopo.ac.kr/main/vpn_test.jsp";
        }
        if (httpTimeout == null) {
            httpTimeout = Duration.ofSeconds(60);
        }
        if (batchSize <= 0) {
            batchSize = 2000;
        }
        if (maxRetries <= 0) {
            maxRetries = 3;
        }
        if (retryDelayMs <= 0) {
            retryDelayMs = 3000;
        }
    }
}
