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

import java.time.LocalDateTime;
import java.util.HashMap;
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
        String sessionId = (String) request.get("sessionId");
        String systemPrompt = (String) request.get("systemPrompt");

        if (message == null || message.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "errorCode", "AI_001",
                "message", "메시지가 비어있습니다.",
                "timestamp", LocalDateTime.now().toString()
            ));
        }

        log.info("AI 채팅 요청: {}", message.substring(0, Math.min(50, message.length())));

        try {
            List<Map<String, String>> messages = new java.util.ArrayList<>();
            messages.add(Map.of("role", "user", "content", message));

            var response = vllmClient.chatCompletion(messages, systemPrompt);

            // vLLM 에러 응답 체크
            if (response.getError() != null && !response.getError().isEmpty()) {
                log.warn("vLLM 에러 응답: {}", response.getError());
                return ResponseEntity.status(503).body(Map.of(
                    "success", false,
                    "errorCode", "AI_003",
                    "message", "AI 서비스 연결에 실패했습니다.",
                    "timestamp", LocalDateTime.now().toString()
                ));
            }

            String content = response.getContent();
            if (content == null || content.isEmpty()) {
                return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "errorCode", "AI_001",
                    "message", "AI 서비스에서 응답을 받지 못했습니다.",
                    "timestamp", LocalDateTime.now().toString()
                ));
            }

            Map<String, Object> data = new HashMap<>();
            data.put("response", content);
            data.put("sessionId", sessionId != null ? sessionId : java.util.UUID.randomUUID().toString());
            data.put("tokens", response.getTotalTokens());
            data.put("model", "gemma-2-9b-it");

            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", data,
                "timestamp", LocalDateTime.now().toString()
            ));

        } catch (Exception e) {
            log.error("AI 채팅 처리 실패: {}", e.getMessage(), e);
            return ResponseEntity.status(503).body(Map.of(
                "success", false,
                "errorCode", "AI_003",
                "message", "AI 서비스 연결에 실패했습니다.",
                "timestamp", LocalDateTime.now().toString()
            ));
        }
    }

    /**
     * RAG 기반 학습 질의응답
     */
    @PostMapping("/query")
    public ResponseEntity<Map<String, Object>> query(@RequestBody Map<String, Object> request) {
        String question = (String) request.get("question");
        if (question == null || question.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AI_001",
                "message", "질문이 비어있습니다.", "timestamp", LocalDateTime.now().toString()));
        }

        Long courseId = request.get("courseId") != null ?
            ((Number) request.get("courseId")).longValue() : null;
        int topK = request.get("topK") != null ?
            ((Number) request.get("topK")).intValue() : 5;

        log.info("RAG 질의: courseId={}, question={}", courseId,
            question.substring(0, Math.min(50, question.length())));

        try {
            Map<String, Object> result = ragService.query(question, courseId, topK);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result, "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("RAG 질의 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "RAG", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 문서 인덱싱
     */
    @PostMapping("/index")
    public ResponseEntity<Map<String, Object>> indexDocument(@RequestBody Map<String, Object> request) {
        String id = (String) request.get("id");
        String title = (String) request.get("title");
        String content = (String) request.get("content");
        if (id == null || content == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "필수 항목(id, content)을 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        Long courseId = request.get("courseId") != null ?
            ((Number) request.get("courseId")).longValue() : null;
        Long lessonId = request.get("lessonId") != null ?
            ((Number) request.get("lessonId")).longValue() : null;

        try {
            boolean success = ragService.indexLearningContent(id, title, content, courseId, lessonId);
            return ResponseEntity.ok(Map.of(
                "success", success, "data", Map.of("documentId", id),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("문서 인덱싱 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "Qdrant", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 배치 인덱싱
     */
    @PostMapping("/index/batch")
    public ResponseEntity<Map<String, Object>> indexBatch(@RequestBody Map<String, Object> request) {
        if (request.get("courseId") == null || request.get("contents") == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "필수 항목(courseId, contents)을 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        Long courseId = ((Number) request.get("courseId")).longValue();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> contents = (List<Map<String, Object>>) request.get("contents");

        try {
            int count = ragService.indexCourseContent(courseId, contents);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("courseId", courseId, "indexedCount", count, "totalCount", contents.size()),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("배치 인덱싱 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "Qdrant", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 유사도 검색
     */
    @PostMapping("/search")
    public ResponseEntity<Map<String, Object>> search(@RequestBody Map<String, Object> request) {
        String query = (String) request.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AI_001",
                "message", "검색어가 비어있습니다.", "timestamp", LocalDateTime.now().toString()));
        }
        int limit = request.get("limit") != null ?
            ((Number) request.get("limit")).intValue() : 10;

        try {
            List<Map<String, Object>> results = qdrantService.search(query, limit);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("query", query, "results", results, "count", results.size()),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("유사도 검색 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "Qdrant", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 텍스트 임베딩
     */
    @PostMapping("/embed")
    public ResponseEntity<Map<String, Object>> embed(@RequestBody Map<String, Object> request) {
        String text = (String) request.get("text");
        if (text == null || text.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "AI_001",
                "message", "텍스트가 비어있습니다.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            float[] embedding = embeddingService.embed(text);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("text", text.substring(0, Math.min(100, text.length())),
                    "dimension", embedding.length, "embedding", embedding),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("임베딩 생성 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "Embedding", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * AI 서비스 상태 확인
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        try {
            boolean vllmHealthy = vllmClient.isHealthy();
            boolean embeddingHealthy = embeddingService.isHealthy();
            boolean qdrantHealthy = qdrantService.isHealthy();
            boolean allHealthy = vllmHealthy && embeddingHealthy && qdrantHealthy;

            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of(
                    "status", allHealthy ? "healthy" : "degraded",
                    "services", Map.of(
                        "vllm", vllmHealthy ? "UP" : "DOWN",
                        "embedding", embeddingHealthy ? "UP" : "DOWN",
                        "qdrant", qdrantHealthy ? "UP" : "DOWN"),
                    "model", "gemma-2-9b-it", "embeddingModel", "bge-m3"),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("AI 헬스체크 실패: {}", e.getMessage());
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("status", "degraded",
                    "services", Map.of("vllm", "DOWN", "embedding", "DOWN", "qdrant", "DOWN")),
                "timestamp", LocalDateTime.now().toString()));
        }
    }

    /**
     * 모델 정보 조회
     */
    @GetMapping("/models")
    public ResponseEntity<Map<String, Object>> getModels() {
        try {
            Map<String, Object> vllmModels = vllmClient.getModelInfo();
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("llm", vllmModels,
                    "embedding", Map.of("model", "BAAI/bge-m3", "dimension", embeddingService.getDimension())),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("모델 정보 조회 실패: {}", e.getMessage(), e);
            throw new kr.polytech.lms.security.error.ExternalServiceException(
                "vLLM", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }
}
