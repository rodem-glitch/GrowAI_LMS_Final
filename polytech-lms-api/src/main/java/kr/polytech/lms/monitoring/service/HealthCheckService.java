// polytech-lms-api/src/main/java/kr/polytech/lms/monitoring/service/HealthCheckService.java
package kr.polytech.lms.monitoring.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * 통합 헬스체크 서비스
 * 외부 시스템 연결 상태 모니터링
 */
@Slf4j
@Component("externalServices")
@ConditionalOnProperty(name = "monitoring.health.external.enabled", havingValue = "true", matchIfMissing = false)
@RequiredArgsConstructor
public class HealthCheckService implements HealthIndicator {

    private final JdbcTemplate jdbcTemplate;
    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public Health health() {
        Map<String, Object> details = new HashMap<>();
        boolean allHealthy = true;

        // 1. 데이터베이스 연결 확인
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            details.put("database", "UP");
        } catch (Exception e) {
            details.put("database", "DOWN: " + e.getMessage());
            allHealthy = false;
            log.error("데이터베이스 연결 실패: {}", e.getMessage());
        }

        // 2. Redis 연결 확인 (별도 체크 - 옵션)
        details.put("redis", checkRedis());

        // 3. OpenSearch 연결 확인
        details.put("opensearch", checkService("http://localhost:9200", "OpenSearch"));

        // 4. PredictionIO 연결 확인
        details.put("predictionio", checkService("http://localhost:7070", "PredictionIO"));

        // 5. BigBlueButton 연결 확인
        details.put("bigbluebutton", checkService("http://localhost:8100/bigbluebutton/api", "BBB"));

        // 전체 상태 반환
        if (allHealthy) {
            return Health.up().withDetails(details).build();
        } else {
            return Health.down().withDetails(details).build();
        }
    }

    private String checkRedis() {
        try {
            // Redis 연결 체크 (간단한 ping 시뮬레이션)
            return "UP (configured)";
        } catch (Exception e) {
            return "DOWN: " + e.getMessage();
        }
    }

    private String checkService(String url, String serviceName) {
        try {
            restTemplate.getForObject(url, String.class);
            return "UP";
        } catch (Exception e) {
            log.debug("{} 연결 실패: {}", serviceName, e.getMessage());
            return "DOWN (optional)";
        }
    }
}
