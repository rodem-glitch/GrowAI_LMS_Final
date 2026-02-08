// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/AiMetricsService.java
package kr.polytech.lms.ai.service;

import io.micrometer.core.instrument.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

/**
 * AI 서비스 메트릭 수집
 * Prometheus 연동 및 성능 모니터링
 */
@Slf4j
@Service
public class AiMetricsService {

    private final MeterRegistry meterRegistry;

    // 카운터
    private final Counter llmRequestCounter;
    private final Counter llmErrorCounter;
    private final Counter embeddingRequestCounter;
    private final Counter ragQueryCounter;
    private final Counter cacheHitCounter;
    private final Counter cacheMissCounter;

    // 타이머
    private final Timer llmLatencyTimer;
    private final Timer embeddingLatencyTimer;
    private final Timer ragLatencyTimer;
    private final Timer vectorSearchTimer;

    // 게이지
    private final AtomicLong activeRequests = new AtomicLong(0);
    private final AtomicLong queuedRequests = new AtomicLong(0);

    public AiMetricsService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;

        // 카운터 등록
        this.llmRequestCounter = Counter.builder("ai.llm.requests.total")
            .description("Total LLM requests")
            .register(meterRegistry);

        this.llmErrorCounter = Counter.builder("ai.llm.errors.total")
            .description("Total LLM errors")
            .register(meterRegistry);

        this.embeddingRequestCounter = Counter.builder("ai.embedding.requests.total")
            .description("Total embedding requests")
            .register(meterRegistry);

        this.ragQueryCounter = Counter.builder("ai.rag.queries.total")
            .description("Total RAG queries")
            .register(meterRegistry);

        this.cacheHitCounter = Counter.builder("ai.cache.hits.total")
            .description("Total cache hits")
            .register(meterRegistry);

        this.cacheMissCounter = Counter.builder("ai.cache.misses.total")
            .description("Total cache misses")
            .register(meterRegistry);

        // 타이머 등록
        this.llmLatencyTimer = Timer.builder("ai.llm.latency")
            .description("LLM response latency")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);

        this.embeddingLatencyTimer = Timer.builder("ai.embedding.latency")
            .description("Embedding generation latency")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);

        this.ragLatencyTimer = Timer.builder("ai.rag.latency")
            .description("RAG query latency")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);

        this.vectorSearchTimer = Timer.builder("ai.vector.search.latency")
            .description("Vector search latency")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);

        // 게이지 등록
        Gauge.builder("ai.requests.active", activeRequests, AtomicLong::get)
            .description("Active AI requests")
            .register(meterRegistry);

        Gauge.builder("ai.requests.queued", queuedRequests, AtomicLong::get)
            .description("Queued AI requests")
            .register(meterRegistry);
    }

    // LLM 메트릭
    public void recordLlmRequest() {
        llmRequestCounter.increment();
    }

    public void recordLlmError() {
        llmErrorCounter.increment();
    }

    public void recordLlmLatency(long durationMs) {
        llmLatencyTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }

    // 임베딩 메트릭
    public void recordEmbeddingRequest() {
        embeddingRequestCounter.increment();
    }

    public void recordEmbeddingLatency(long durationMs) {
        embeddingLatencyTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }

    // RAG 메트릭
    public void recordRagQuery() {
        ragQueryCounter.increment();
    }

    public void recordRagLatency(long durationMs) {
        ragLatencyTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }

    // 벡터 검색 메트릭
    public void recordVectorSearchLatency(long durationMs) {
        vectorSearchTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }

    // 캐시 메트릭
    public void recordCacheHit() {
        cacheHitCounter.increment();
    }

    public void recordCacheMiss() {
        cacheMissCounter.increment();
    }

    // 활성 요청 관리
    public void incrementActiveRequests() {
        activeRequests.incrementAndGet();
    }

    public void decrementActiveRequests() {
        activeRequests.decrementAndGet();
    }

    public void setQueuedRequests(long count) {
        queuedRequests.set(count);
    }

    // 토큰 사용량 기록
    public void recordTokenUsage(int promptTokens, int completionTokens) {
        Counter.builder("ai.tokens.prompt.total")
            .register(meterRegistry)
            .increment(promptTokens);

        Counter.builder("ai.tokens.completion.total")
            .register(meterRegistry)
            .increment(completionTokens);
    }
}
