// polytech-lms-api/src/main/java/kr/polytech/lms/ai/controller/AiController.java
package kr.polytech.lms.ai.controller;

import kr.polytech.lms.ai.client.VllmClient;
import kr.polytech.lms.ai.service.EmbeddingService;
import kr.polytech.lms.ai.service.QdrantService;
import kr.polytech.lms.ai.service.RagService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * AI 서비스 API 컨트롤러
 * vLLM + Qdrant 기반 온프레미스 AI
 */
@Slf4j
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final VllmClient vllmClient;
    private final EmbeddingService embeddingService;
    private final QdrantService qdrantService;
    private final RagService ragService;

    /**
     * AI 채팅 (직접 LLM 호출)
     */
    @PostMapping("/chat")
    public ResponseEntity<Map<String, Object>> chat(@RequestBody Map<String, Object> request) {
        String message = (String) request.get("message");
        String systemPrompt = (String) request.get("systemPrompt");

        log.info("AI 채팅 요청: {}", message.substring(0, Math.min(50, message.length())));

        List<Map<String, String>> messages = List.of(
            Map.of("role", "user", "content", message)
        );

        var response = vllmClient.chatCompletion(messages, systemPrompt);

        return ResponseEntity.ok(Map.of(
            "response", response.getContent(),
            "tokens", response.getTotalTokens(),
            "model", "gemma-2-9b-it"
        ));
    }

    /**
     * RAG 기반 학습 질의응답
     */
    @PostMapping("/query")
    public ResponseEntity<Map<String, Object>> query(@RequestBody Map<String, Object> request) {
        String question = (String) request.get("question");
        Long courseId = request.get("courseId") != null ?
            ((Number) request.get("courseId")).longValue() : null;
        int topK = request.get("topK") != null ?
            ((Number) request.get("topK")).intValue() : 5;

        log.info("RAG 질의: courseId={}, question={}", courseId,
            question.substring(0, Math.min(50, question.length())));

        Map<String, Object> result = ragService.query(question, courseId, topK);

        return ResponseEntity.ok(result);
    }

    /**
     * 문서 인덱싱
     */
    @PostMapping("/index")
    public ResponseEntity<Map<String, Object>> indexDocument(@RequestBody Map<String, Object> request) {
        String id = (String) request.get("id");
        String title = (String) request.get("title");
        String content = (String) request.get("content");
        Long courseId = request.get("courseId") != null ?
            ((Number) request.get("courseId")).longValue() : null;
        Long lessonId = request.get("lessonId") != null ?
            ((Number) request.get("lessonId")).longValue() : null;

        boolean success = ragService.indexLearningContent(id, title, content, courseId, lessonId);

        return ResponseEntity.ok(Map.of(
            "success", success,
            "documentId", id
        ));
    }

    /**
     * 배치 인덱싱
     */
    @PostMapping("/index/batch")
    public ResponseEntity<Map<String, Object>> indexBatch(@RequestBody Map<String, Object> request) {
        Long courseId = ((Number) request.get("courseId")).longValue();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> contents = (List<Map<String, Object>>) request.get("contents");

        int count = ragService.indexCourseContent(courseId, contents);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "courseId", courseId,
            "indexedCount", count,
            "totalCount", contents.size()
        ));
    }

    /**
     * 유사도 검색
     */
    @PostMapping("/search")
    public ResponseEntity<Map<String, Object>> search(@RequestBody Map<String, Object> request) {
        String query = (String) request.get("query");
        int limit = request.get("limit") != null ?
            ((Number) request.get("limit")).intValue() : 10;

        List<Map<String, Object>> results = qdrantService.search(query, limit);

        return ResponseEntity.ok(Map.of(
            "query", query,
            "results", results,
            "count", results.size()
        ));
    }

    /**
     * 텍스트 임베딩
     */
    @PostMapping("/embed")
    public ResponseEntity<Map<String, Object>> embed(@RequestBody Map<String, Object> request) {
        String text = (String) request.get("text");

        float[] embedding = embeddingService.embed(text);

        return ResponseEntity.ok(Map.of(
            "text", text.substring(0, Math.min(100, text.length())),
            "dimension", embedding.length,
            "embedding", embedding
        ));
    }

    /**
     * AI 서비스 상태 확인
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        boolean vllmHealthy = vllmClient.isHealthy();
        boolean embeddingHealthy = embeddingService.isHealthy();
        boolean qdrantHealthy = qdrantService.isHealthy();

        boolean allHealthy = vllmHealthy && embeddingHealthy && qdrantHealthy;

        return ResponseEntity.ok(Map.of(
            "status", allHealthy ? "healthy" : "degraded",
            "services", Map.of(
                "vllm", vllmHealthy ? "UP" : "DOWN",
                "embedding", embeddingHealthy ? "UP" : "DOWN",
                "qdrant", qdrantHealthy ? "UP" : "DOWN"
            ),
            "model", "gemma-2-9b-it",
            "embeddingModel", "bge-m3"
        ));
    }

    /**
     * 모델 정보 조회
     */
    @GetMapping("/models")
    public ResponseEntity<Map<String, Object>> getModels() {
        Map<String, Object> vllmModels = vllmClient.getModelInfo();

        return ResponseEntity.ok(Map.of(
            "llm", vllmModels,
            "embedding", Map.of(
                "model", "BAAI/bge-m3",
                "dimension", embeddingService.getDimension()
            )
        ));
    }
}
