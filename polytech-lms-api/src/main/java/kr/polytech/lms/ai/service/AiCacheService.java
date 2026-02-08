// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/AiCacheService.java
package kr.polytech.lms.ai.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.stats.CacheStats;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * AI 서비스 캐시
 * 임베딩 및 LLM 응답 캐싱으로 성능 최적화
 */
@Slf4j
@Service
public class AiCacheService {

    @Value("${ai.performance.cache.enabled:true}")
    private boolean cacheEnabled;

    @Value("${ai.performance.cache.ttl-minutes:30}")
    private int ttlMinutes;

    @Value("${ai.performance.cache.max-size:1000}")
    private int maxSize;

    // 임베딩 캐시 (텍스트 해시 -> 벡터)
    private Cache<String, float[]> embeddingCache;

    // LLM 응답 캐시 (프롬프트 해시 -> 응답)
    private Cache<String, String> responseCache;

    // 검색 결과 캐시
    private Cache<String, Object> searchCache;

    @PostConstruct
    public void init() {
        if (!cacheEnabled) {
            log.info("AI 캐시 비활성화됨");
            return;
        }

        // 임베딩 캐시 초기화
        embeddingCache = Caffeine.newBuilder()
            .maximumSize(maxSize)
            .expireAfterWrite(ttlMinutes, TimeUnit.MINUTES)
            .recordStats()
            .build();

        // LLM 응답 캐시 초기화 (TTL 짧게)
        responseCache = Caffeine.newBuilder()
            .maximumSize(maxSize / 2)
            .expireAfterWrite(ttlMinutes / 2, TimeUnit.MINUTES)
            .recordStats()
            .build();

        // 검색 결과 캐시
        searchCache = Caffeine.newBuilder()
            .maximumSize(maxSize)
            .expireAfterWrite(5, TimeUnit.MINUTES)
            .recordStats()
            .build();

        log.info("AI 캐시 초기화 완료: maxSize={}, ttl={}min", maxSize, ttlMinutes);
    }

    /**
     * 임베딩 캐시 조회
     */
    public float[] getEmbedding(String text) {
        if (!cacheEnabled || embeddingCache == null) return null;
        String key = hashText(text);
        return embeddingCache.getIfPresent(key);
    }

    /**
     * 임베딩 캐시 저장
     */
    public void putEmbedding(String text, float[] embedding) {
        if (!cacheEnabled || embeddingCache == null) return;
        String key = hashText(text);
        embeddingCache.put(key, embedding);
    }

    /**
     * LLM 응답 캐시 조회
     */
    public String getResponse(String prompt) {
        if (!cacheEnabled || responseCache == null) return null;
        String key = hashText(prompt);
        return responseCache.getIfPresent(key);
    }

    /**
     * LLM 응답 캐시 저장
     */
    public void putResponse(String prompt, String response) {
        if (!cacheEnabled || responseCache == null) return;
        String key = hashText(prompt);
        responseCache.put(key, response);
    }

    /**
     * 검색 결과 캐시 조회
     */
    @SuppressWarnings("unchecked")
    public <T> T getSearchResult(String query, Class<T> type) {
        if (!cacheEnabled || searchCache == null) return null;
        String key = hashText(query);
        return (T) searchCache.getIfPresent(key);
    }

    /**
     * 검색 결과 캐시 저장
     */
    public void putSearchResult(String query, Object result) {
        if (!cacheEnabled || searchCache == null) return;
        String key = hashText(query);
        searchCache.put(key, result);
    }

    /**
     * 캐시 통계 조회
     */
    public Map<String, Object> getStats() {
        if (!cacheEnabled) {
            return Map.of("enabled", false);
        }

        CacheStats embeddingStats = embeddingCache != null ? embeddingCache.stats() : null;
        CacheStats responseStats = responseCache != null ? responseCache.stats() : null;
        CacheStats searchStats = searchCache != null ? searchCache.stats() : null;

        return Map.of(
            "enabled", true,
            "embedding", formatStats(embeddingStats),
            "response", formatStats(responseStats),
            "search", formatStats(searchStats)
        );
    }

    /**
     * 전체 캐시 클리어
     */
    public void clearAll() {
        if (embeddingCache != null) embeddingCache.invalidateAll();
        if (responseCache != null) responseCache.invalidateAll();
        if (searchCache != null) searchCache.invalidateAll();
        log.info("AI 캐시 전체 클리어");
    }

    private String hashText(String text) {
        // 간단한 해시 (실제로는 더 강력한 해시 사용 권장)
        return String.valueOf(text.hashCode());
    }

    private Map<String, Object> formatStats(CacheStats stats) {
        if (stats == null) {
            return Map.of("available", false);
        }
        return Map.of(
            "hitCount", stats.hitCount(),
            "missCount", stats.missCount(),
            "hitRate", String.format("%.2f%%", stats.hitRate() * 100),
            "evictionCount", stats.evictionCount()
        );
    }
}
