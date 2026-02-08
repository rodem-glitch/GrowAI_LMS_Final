// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/AiHealthIndicator.java
package kr.polytech.lms.ai.service;

import kr.polytech.lms.ai.client.VllmClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * AI 서비스 헬스 인디케이터
 * Actuator 헬스체크 통합
 */
@Slf4j
@Component("aiServices")
@ConditionalOnProperty(name = "ai.health.enabled", havingValue = "true", matchIfMissing = false)
@RequiredArgsConstructor
public class AiHealthIndicator implements HealthIndicator {

    private final VllmClient vllmClient;
    private final EmbeddingService embeddingService;
    private final QdrantService qdrantService;

    @Override
    public Health health() {
        Map<String, Object> details = new HashMap<>();
        boolean allHealthy = true;

        // vLLM 상태
        boolean vllmHealthy = vllmClient.isHealthy();
        details.put("vllm", Map.of(
            "status", vllmHealthy ? "UP" : "DOWN",
            "model", "gemma-2-9b-it"
        ));
        if (!vllmHealthy) allHealthy = false;

        // 임베딩 서비스 상태
        boolean embeddingHealthy = embeddingService.isHealthy();
        details.put("embedding", Map.of(
            "status", embeddingHealthy ? "UP" : "DOWN",
            "model", "bge-m3",
            "dimension", embeddingService.getDimension()
        ));
        if (!embeddingHealthy) allHealthy = false;

        // Qdrant 상태
        boolean qdrantHealthy = qdrantService.isHealthy();
        details.put("qdrant", Map.of(
            "status", qdrantHealthy ? "UP" : "DOWN",
            "type", "vector-database"
        ));
        if (!qdrantHealthy) allHealthy = false;

        // GPU 메트릭 (옵션)
        try {
            Map<String, Object> gpuInfo = getGpuMetrics();
            details.put("gpu", gpuInfo);
        } catch (Exception e) {
            details.put("gpu", Map.of("status", "UNKNOWN"));
        }

        if (allHealthy) {
            return Health.up()
                .withDetails(details)
                .build();
        } else {
            return Health.down()
                .withDetails(details)
                .build();
        }
    }

    private Map<String, Object> getGpuMetrics() {
        // GPU 메트릭 수집 (실제 환경에서는 DCGM Exporter 연동)
        return Map.of(
            "status", "UP",
            "memoryUsed", "N/A",
            "utilization", "N/A"
        );
    }
}
