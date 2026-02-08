// polytech-lms-api/src/main/java/kr/polytech/lms/agent/MonitoringAgent.java
package kr.polytech.lms.agent;

import kr.polytech.lms.gcp.service.BigQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Monitoring Agent
 * 인프라 상태 감시 및 이상 징후 예측
 * Tech: Cloud Monitoring + BigQuery ML
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MonitoringAgent {

    private final BigQueryService bigQueryService;

    // 메트릭 히스토리 (시계열 데이터)
    private final Map<String, List<MetricPoint>> metricHistory = new ConcurrentHashMap<>();

    // 임계값 설정
    private static final double CPU_THRESHOLD = 80.0;
    private static final double MEMORY_THRESHOLD = 85.0;
    private static final double LATENCY_THRESHOLD = 1000.0; // ms
    private static final double ERROR_RATE_THRESHOLD = 5.0; // %

    /**
     * 정기 모니터링 (1분마다)
     */
    @Scheduled(fixedRate = 60000)
    public void scheduledMonitoring() {
        log.debug("Monitoring Agent: 정기 모니터링 실행");
        collectAndAnalyzeMetrics();
    }

    /**
     * 메트릭 수집 및 분석
     */
    public Map<String, Object> collectAndAnalyzeMetrics() {
        log.info("Monitoring Agent: 메트릭 수집 시작");

        // 시뮬레이션된 메트릭 수집
        Map<String, Double> currentMetrics = collectCurrentMetrics();

        // 메트릭 기록
        recordMetrics(currentMetrics);

        // 이상 탐지
        List<Map<String, Object>> anomalies = detectAnomalies(currentMetrics);

        // 예측 분석 (BigQuery ML)
        Map<String, Object> predictions = predictTrends();

        // 상태 결정
        String status = determineOverallStatus(currentMetrics, anomalies);

        Map<String, Object> result = Map.of(
            "timestamp", LocalDateTime.now().toString(),
            "metrics", currentMetrics,
            "anomalies", anomalies,
            "predictions", predictions,
            "status", status
        );

        if (!anomalies.isEmpty()) {
            log.warn("Monitoring Agent: 이상 징후 감지 - {}건", anomalies.size());
        }

        return result;
    }

    /**
     * 현재 메트릭 수집 (시뮬레이션)
     */
    private Map<String, Double> collectCurrentMetrics() {
        Random random = new Random();

        return Map.of(
            "cpu_usage", 40.0 + random.nextDouble() * 30,
            "memory_usage", 50.0 + random.nextDouble() * 25,
            "disk_usage", 45.0 + random.nextDouble() * 20,
            "network_in", random.nextDouble() * 100,
            "network_out", random.nextDouble() * 80,
            "api_latency", 100.0 + random.nextDouble() * 200,
            "error_rate", random.nextDouble() * 3,
            "active_sessions", (double) (50 + random.nextInt(100)),
            "requests_per_second", 100.0 + random.nextDouble() * 200
        );
    }

    /**
     * 메트릭 기록
     */
    private void recordMetrics(Map<String, Double> metrics) {
        long timestamp = System.currentTimeMillis();

        for (Map.Entry<String, Double> entry : metrics.entrySet()) {
            String metricName = entry.getKey();
            double value = entry.getValue();

            metricHistory.computeIfAbsent(metricName, k -> new ArrayList<>())
                .add(new MetricPoint(timestamp, value));

            // 최근 1시간 데이터만 유지
            List<MetricPoint> history = metricHistory.get(metricName);
            long oneHourAgo = timestamp - 3600000;
            history.removeIf(p -> p.timestamp < oneHourAgo);
        }
    }

    /**
     * 이상 탐지
     */
    private List<Map<String, Object>> detectAnomalies(Map<String, Double> metrics) {
        List<Map<String, Object>> anomalies = new ArrayList<>();

        // CPU 사용량 체크
        if (metrics.get("cpu_usage") > CPU_THRESHOLD) {
            anomalies.add(Map.of(
                "metric", "cpu_usage",
                "value", metrics.get("cpu_usage"),
                "threshold", CPU_THRESHOLD,
                "severity", "HIGH",
                "message", "CPU 사용량이 임계값을 초과했습니다."
            ));
        }

        // 메모리 사용량 체크
        if (metrics.get("memory_usage") > MEMORY_THRESHOLD) {
            anomalies.add(Map.of(
                "metric", "memory_usage",
                "value", metrics.get("memory_usage"),
                "threshold", MEMORY_THRESHOLD,
                "severity", "HIGH",
                "message", "메모리 사용량이 임계값을 초과했습니다."
            ));
        }

        // API 지연시간 체크
        if (metrics.get("api_latency") > LATENCY_THRESHOLD) {
            anomalies.add(Map.of(
                "metric", "api_latency",
                "value", metrics.get("api_latency"),
                "threshold", LATENCY_THRESHOLD,
                "severity", "MEDIUM",
                "message", "API 응답 지연이 발생하고 있습니다."
            ));
        }

        // 에러율 체크
        if (metrics.get("error_rate") > ERROR_RATE_THRESHOLD) {
            anomalies.add(Map.of(
                "metric", "error_rate",
                "value", metrics.get("error_rate"),
                "threshold", ERROR_RATE_THRESHOLD,
                "severity", "HIGH",
                "message", "에러율이 비정상적으로 높습니다."
            ));
        }

        return anomalies;
    }

    /**
     * 트렌드 예측 (BigQuery ML 시뮬레이션)
     */
    private Map<String, Object> predictTrends() {
        // 실제로는 BigQuery ML 모델로 예측
        return Map.of(
            "cpu_trend", "STABLE",
            "memory_trend", "INCREASING",
            "predicted_peak_time", "14:00",
            "recommended_scaling", "NONE",
            "confidence", 0.85
        );
    }

    /**
     * 전체 상태 결정
     */
    private String determineOverallStatus(Map<String, Double> metrics, List<Map<String, Object>> anomalies) {
        if (anomalies.stream().anyMatch(a -> "CRITICAL".equals(a.get("severity")))) {
            return "CRITICAL";
        }
        if (anomalies.stream().anyMatch(a -> "HIGH".equals(a.get("severity")))) {
            return "WARNING";
        }
        if (!anomalies.isEmpty()) {
            return "ATTENTION";
        }
        return "HEALTHY";
    }

    /**
     * 특정 메트릭 히스토리 조회
     */
    public List<Map<String, Object>> getMetricHistory(String metricName, int minutes) {
        List<MetricPoint> history = metricHistory.getOrDefault(metricName, Collections.emptyList());
        long cutoff = System.currentTimeMillis() - (minutes * 60000L);

        return history.stream()
            .filter(p -> p.timestamp >= cutoff)
            .map(p -> Map.<String, Object>of(
                "timestamp", p.timestamp,
                "value", p.value
            ))
            .toList();
    }

    /**
     * 에이전트 상태 조회
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "agent", "MonitoringAgent",
            "role", "인프라 상태 감시 및 이상 징후 예측",
            "tech", "Cloud Monitoring + BigQuery ML",
            "metricsTracked", metricHistory.size(),
            "dataPoints", metricHistory.values().stream().mapToInt(List::size).sum(),
            "status", "ACTIVE",
            "lastCheck", LocalDateTime.now().toString()
        );
    }

    /**
     * 메트릭 포인트 내부 클래스
     */
    private record MetricPoint(long timestamp, double value) {}
}
