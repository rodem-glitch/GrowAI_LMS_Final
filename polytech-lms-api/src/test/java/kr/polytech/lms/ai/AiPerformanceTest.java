// polytech-lms-api/src/test/java/kr/polytech/lms/ai/AiPerformanceTest.java
package kr.polytech.lms.ai;

import kr.polytech.lms.ai.client.VllmClient;
import kr.polytech.lms.ai.service.EmbeddingService;
import kr.polytech.lms.ai.service.QdrantService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

/**
 * AI 서비스 성능 테스트
 * 처리량, 지연시간, 동시성 검증
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AiPerformanceTest {

    @Autowired
    private VllmClient vllmClient;

    @Autowired
    private EmbeddingService embeddingService;

    @Autowired
    private QdrantService qdrantService;

    private static final int WARMUP_ITERATIONS = 3;
    private static final int TEST_ITERATIONS = 10;
    private static final int CONCURRENT_REQUESTS = 5;

    @Test
    @Order(1)
    @DisplayName("임베딩 지연시간 측정")
    void testEmbeddingLatency() {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");

        String testText = "한국폴리텍대학 온라인 학습관리시스템 성능 테스트입니다.";

        // 워밍업
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            embeddingService.embed(testText);
        }

        // 측정
        List<Long> latencies = new ArrayList<>();
        for (int i = 0; i < TEST_ITERATIONS; i++) {
            long start = System.currentTimeMillis();
            embeddingService.embed(testText);
            latencies.add(System.currentTimeMillis() - start);
        }

        double avgLatency = latencies.stream().mapToLong(Long::longValue).average().orElse(0);
        long maxLatency = latencies.stream().mapToLong(Long::longValue).max().orElse(0);
        long minLatency = latencies.stream().mapToLong(Long::longValue).min().orElse(0);

        System.out.println("=== 임베딩 지연시간 ===");
        System.out.println("평균: " + avgLatency + "ms");
        System.out.println("최소: " + minLatency + "ms");
        System.out.println("최대: " + maxLatency + "ms");

        // 성능 기준: 평균 500ms 이하
        assertTrue(avgLatency < 500, "평균 지연시간이 500ms를 초과합니다");
    }

    @Test
    @Order(2)
    @DisplayName("임베딩 처리량 측정")
    void testEmbeddingThroughput() {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");

        List<String> texts = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            texts.add("테스트 문장 번호 " + i + ": 한국폴리텍대학 학습 자료입니다.");
        }

        long start = System.currentTimeMillis();
        List<float[]> embeddings = embeddingService.embedBatch(texts);
        long duration = System.currentTimeMillis() - start;

        double throughput = (double) texts.size() / duration * 1000;

        System.out.println("=== 임베딩 처리량 ===");
        System.out.println("처리 건수: " + embeddings.size());
        System.out.println("소요 시간: " + duration + "ms");
        System.out.println("처리량: " + String.format("%.2f", throughput) + " docs/sec");

        assertEquals(texts.size(), embeddings.size());
    }

    @Test
    @Order(3)
    @DisplayName("vLLM 지연시간 측정")
    void testVllmLatency() {
        Assumptions.assumeTrue(vllmClient.isHealthy(), "vLLM 서버가 실행 중이어야 합니다");

        String prompt = "안녕하세요. 간단히 자기소개 해주세요.";

        // 워밍업
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            vllmClient.generate(prompt);
        }

        // 측정
        List<Long> latencies = new ArrayList<>();
        for (int i = 0; i < TEST_ITERATIONS; i++) {
            long start = System.currentTimeMillis();
            String response = vllmClient.generate(prompt);
            latencies.add(System.currentTimeMillis() - start);
            assertNotNull(response);
        }

        double avgLatency = latencies.stream().mapToLong(Long::longValue).average().orElse(0);
        long p95 = latencies.stream().sorted().skip((long) (latencies.size() * 0.95)).findFirst().orElse(0L);

        System.out.println("=== vLLM 지연시간 ===");
        System.out.println("평균: " + avgLatency + "ms");
        System.out.println("P95: " + p95 + "ms");
    }

    @Test
    @Order(4)
    @DisplayName("Qdrant 검색 지연시간 측정")
    void testQdrantSearchLatency() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");

        String query = "프로그래밍 기초 학습";

        // 워밍업
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            qdrantService.search(query, 10);
        }

        // 측정
        List<Long> latencies = new ArrayList<>();
        for (int i = 0; i < TEST_ITERATIONS; i++) {
            long start = System.currentTimeMillis();
            qdrantService.search(query, 10);
            latencies.add(System.currentTimeMillis() - start);
        }

        double avgLatency = latencies.stream().mapToLong(Long::longValue).average().orElse(0);

        System.out.println("=== Qdrant 검색 지연시간 ===");
        System.out.println("평균: " + avgLatency + "ms");

        // 성능 기준: 평균 100ms 이하
        assertTrue(avgLatency < 100, "검색 평균 지연시간이 100ms를 초과합니다");
    }

    @Test
    @Order(5)
    @DisplayName("동시 요청 처리 테스트")
    void testConcurrentRequests() throws InterruptedException {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");

        ExecutorService executor = Executors.newFixedThreadPool(CONCURRENT_REQUESTS);
        CountDownLatch latch = new CountDownLatch(CONCURRENT_REQUESTS * TEST_ITERATIONS);
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger errorCount = new AtomicInteger(0);

        long startTime = System.currentTimeMillis();

        for (int i = 0; i < CONCURRENT_REQUESTS * TEST_ITERATIONS; i++) {
            final int idx = i;
            executor.submit(() -> {
                try {
                    String text = "동시성 테스트 문장 " + idx;
                    float[] embedding = embeddingService.embed(text);
                    if (embedding != null && embedding.length > 0) {
                        successCount.incrementAndGet();
                    } else {
                        errorCount.incrementAndGet();
                    }
                } catch (Exception e) {
                    errorCount.incrementAndGet();
                } finally {
                    latch.countDown();
                }
            });
        }

        latch.await(60, TimeUnit.SECONDS);
        executor.shutdown();

        long duration = System.currentTimeMillis() - startTime;
        int totalRequests = CONCURRENT_REQUESTS * TEST_ITERATIONS;

        System.out.println("=== 동시성 테스트 결과 ===");
        System.out.println("총 요청: " + totalRequests);
        System.out.println("성공: " + successCount.get());
        System.out.println("실패: " + errorCount.get());
        System.out.println("소요 시간: " + duration + "ms");
        System.out.println("처리량: " + String.format("%.2f", (double) totalRequests / duration * 1000) + " req/sec");

        assertTrue(successCount.get() > totalRequests * 0.9, "성공률이 90% 미만입니다");
    }

    @Test
    @Order(6)
    @DisplayName("메모리 사용량 모니터링")
    void testMemoryUsage() {
        Runtime runtime = Runtime.getRuntime();

        // GC 실행
        System.gc();
        Thread.yield();

        long beforeMemory = runtime.totalMemory() - runtime.freeMemory();

        // 대량 임베딩 생성
        if (embeddingService.isHealthy()) {
            for (int i = 0; i < 50; i++) {
                embeddingService.embed("메모리 테스트 문장 " + i);
            }
        }

        long afterMemory = runtime.totalMemory() - runtime.freeMemory();
        long memoryUsed = afterMemory - beforeMemory;

        System.out.println("=== 메모리 사용량 ===");
        System.out.println("처리 전: " + formatBytes(beforeMemory));
        System.out.println("처리 후: " + formatBytes(afterMemory));
        System.out.println("증가량: " + formatBytes(memoryUsed));
    }

    private String formatBytes(long bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return String.format("%.2f KB", bytes / 1024.0);
        return String.format("%.2f MB", bytes / (1024.0 * 1024));
    }
}
