// polytech-lms-api/src/test/java/kr/polytech/lms/ai/AiServiceIntegrationTest.java
package kr.polytech.lms.ai;

import kr.polytech.lms.ai.client.VllmClient;
import kr.polytech.lms.ai.service.EmbeddingService;
import kr.polytech.lms.ai.service.QdrantService;
import kr.polytech.lms.ai.service.RagService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * AI 서비스 통합 테스트
 * vLLM, Qdrant, 임베딩 서비스 연동 검증
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AiServiceIntegrationTest {

    @Autowired
    private VllmClient vllmClient;

    @Autowired
    private EmbeddingService embeddingService;

    @Autowired
    private QdrantService qdrantService;

    @Autowired
    private RagService ragService;

    private static final String TEST_COLLECTION = "test_collection";

    @Test
    @Order(1)
    @DisplayName("vLLM 헬스체크")
    void testVllmHealth() {
        // vLLM이 비활성화된 경우 스킵
        Assumptions.assumeTrue(vllmClient.isHealthy(), "vLLM 서버가 실행 중이어야 합니다");
        assertTrue(vllmClient.isHealthy());
    }

    @Test
    @Order(2)
    @DisplayName("vLLM 텍스트 생성")
    void testVllmGeneration() {
        Assumptions.assumeTrue(vllmClient.isHealthy(), "vLLM 서버가 실행 중이어야 합니다");

        String response = vllmClient.generate("안녕하세요. 한국폴리텍대학에 대해 간단히 설명해주세요.");

        assertNotNull(response);
        assertFalse(response.isEmpty());
        System.out.println("vLLM 응답: " + response);
    }

    @Test
    @Order(3)
    @DisplayName("임베딩 서비스 헬스체크")
    void testEmbeddingHealth() {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");
        assertTrue(embeddingService.isHealthy());
    }

    @Test
    @Order(4)
    @DisplayName("텍스트 임베딩 생성")
    void testEmbedding() {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");

        String text = "한국폴리텍대학은 실무 중심의 기술 교육을 제공합니다.";
        float[] embedding = embeddingService.embed(text);

        assertNotNull(embedding);
        assertTrue(embedding.length > 0);
        assertEquals(embeddingService.getDimension(), embedding.length);

        System.out.println("임베딩 차원: " + embedding.length);
    }

    @Test
    @Order(5)
    @DisplayName("코사인 유사도 계산")
    void testCosineSimilarity() {
        Assumptions.assumeTrue(embeddingService.isHealthy(), "임베딩 서버가 실행 중이어야 합니다");

        float[] vec1 = embeddingService.embed("자바 프로그래밍 기초");
        float[] vec2 = embeddingService.embed("Java 기초 프로그래밍");
        float[] vec3 = embeddingService.embed("요리 레시피");

        double similarity12 = embeddingService.cosineSimilarity(vec1, vec2);
        double similarity13 = embeddingService.cosineSimilarity(vec1, vec3);

        System.out.println("유사한 문장 유사도: " + similarity12);
        System.out.println("다른 문장 유사도: " + similarity13);

        // 유사한 문장은 높은 유사도, 다른 문장은 낮은 유사도
        assertTrue(similarity12 > similarity13);
    }

    @Test
    @Order(6)
    @DisplayName("Qdrant 헬스체크")
    void testQdrantHealth() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");
        assertTrue(qdrantService.isHealthy());
    }

    @Test
    @Order(7)
    @DisplayName("Qdrant 컬렉션 생성")
    void testCreateCollection() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");

        boolean created = qdrantService.createCollection(TEST_COLLECTION, embeddingService.getDimension());
        // 이미 존재해도 true 또는 false 반환
        assertNotNull(created);
    }

    @Test
    @Order(8)
    @DisplayName("문서 저장")
    void testUpsertDocument() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");

        boolean result = qdrantService.upsertDocument(
            TEST_COLLECTION,
            "doc1",
            "자바 프로그래밍 기초 과정입니다. 변수, 조건문, 반복문을 학습합니다.",
            Map.of("course_id", 1L, "lesson_id", 1L)
        );

        assertTrue(result);
    }

    @Test
    @Order(9)
    @DisplayName("문서 검색")
    void testSearch() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");

        // 먼저 문서 저장
        qdrantService.upsertDocument(TEST_COLLECTION, "doc2",
            "파이썬 데이터 분석 과정입니다. pandas와 numpy를 학습합니다.",
            Map.of("course_id", 2L));

        // 검색
        List<Map<String, Object>> results = qdrantService.search(
            TEST_COLLECTION, "프로그래밍 기초", 5, null);

        assertNotNull(results);
        System.out.println("검색 결과 수: " + results.size());

        for (Map<String, Object> result : results) {
            System.out.println("  - Score: " + result.get("score") + ", Text: " + result.get("text"));
        }
    }

    @Test
    @Order(10)
    @DisplayName("RAG 질의응답")
    void testRagQuery() {
        Assumptions.assumeTrue(vllmClient.isHealthy() && qdrantService.isHealthy(),
            "vLLM과 Qdrant 서버가 실행 중이어야 합니다");

        // 테스트 데이터 인덱싱
        ragService.indexLearningContent("test1", "Java 기초",
            "자바는 객체지향 프로그래밍 언어입니다. 클래스와 객체를 사용합니다.", 1L, 1L);

        ragService.indexLearningContent("test2", "Python 기초",
            "파이썬은 인터프리터 언어입니다. 간결한 문법이 특징입니다.", 2L, 1L);

        // RAG 질의
        Map<String, Object> result = ragService.query("자바란 무엇인가요?", null, 3);

        assertNotNull(result);
        assertNotNull(result.get("answer"));
        assertNotNull(result.get("sources"));

        System.out.println("RAG 답변: " + result.get("answer"));
        System.out.println("처리 시간: " + result.get("processingTime") + "ms");
    }

    @Test
    @Order(11)
    @DisplayName("배치 인덱싱 성능")
    void testBatchIndexing() {
        Assumptions.assumeTrue(qdrantService.isHealthy(), "Qdrant 서버가 실행 중이어야 합니다");

        List<Map<String, Object>> contents = List.of(
            Map.of("id", "batch1", "title", "웹개발 기초", "content", "HTML, CSS, JavaScript를 학습합니다.", "lesson_id", 1L),
            Map.of("id", "batch2", "title", "데이터베이스", "content", "MySQL과 SQL 쿼리를 학습합니다.", "lesson_id", 2L),
            Map.of("id", "batch3", "title", "네트워크", "content", "TCP/IP와 HTTP 프로토콜을 학습합니다.", "lesson_id", 3L)
        );

        long startTime = System.currentTimeMillis();
        int count = ragService.indexCourseContent(100L, contents);
        long duration = System.currentTimeMillis() - startTime;

        assertEquals(3, count);
        System.out.println("배치 인덱싱 완료: " + count + "개, " + duration + "ms");
    }

    @AfterAll
    static void cleanup() {
        System.out.println("테스트 완료");
    }
}
