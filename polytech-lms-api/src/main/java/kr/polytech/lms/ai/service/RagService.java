// polytech-lms-api/src/main/java/kr/polytech/lms/ai/service/RagService.java
package kr.polytech.lms.ai.service;

import kr.polytech.lms.ai.client.VllmClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * RAG (Retrieval-Augmented Generation) 서비스
 * 벡터 검색 + LLM 결합으로 정확한 답변 생성
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RagService {

    private final QdrantService qdrantService;
    private final VllmClient vllmClient;

    private static final int DEFAULT_TOP_K = 5;
    private static final double MIN_SCORE_THRESHOLD = 0.5;

    /**
     * RAG 기반 질의응답
     */
    public Map<String, Object> query(String question) {
        return query(question, null, DEFAULT_TOP_K);
    }

    /**
     * RAG 기반 질의응답 (과정 필터링)
     */
    public Map<String, Object> query(String question, Long courseId, int topK) {
        long startTime = System.currentTimeMillis();

        // 1. 관련 문서 검색
        List<Map<String, Object>> relevantDocs = qdrantService.searchLearningContent(
            question, courseId, topK);

        // 2. 점수 필터링
        relevantDocs = relevantDocs.stream()
            .filter(doc -> {
                Double score = (Double) doc.get("score");
                return score != null && score >= MIN_SCORE_THRESHOLD;
            })
            .collect(Collectors.toList());

        if (relevantDocs.isEmpty()) {
            return Map.of(
                "answer", "죄송합니다. 관련된 학습 자료를 찾을 수 없습니다. 질문을 다시 확인해주세요.",
                "sources", Collections.emptyList(),
                "processingTime", System.currentTimeMillis() - startTime
            );
        }

        // 3. 컨텍스트 구성
        String context = buildContext(relevantDocs);

        // 4. LLM 응답 생성
        String answer = vllmClient.generateLearningAssistance(question, context);

        // 5. 소스 정보 추출
        List<Map<String, Object>> sources = extractSources(relevantDocs);

        long processingTime = System.currentTimeMillis() - startTime;
        log.info("RAG 질의 완료: {}ms, 관련문서: {}", processingTime, relevantDocs.size());

        return Map.of(
            "answer", answer,
            "sources", sources,
            "processingTime", processingTime,
            "documentsUsed", relevantDocs.size()
        );
    }

    /**
     * 컨텍스트 문자열 구성
     */
    private String buildContext(List<Map<String, Object>> docs) {
        StringBuilder context = new StringBuilder();

        for (int i = 0; i < docs.size(); i++) {
            Map<String, Object> doc = docs.get(i);
            String text = (String) doc.get("text");
            Double score = (Double) doc.get("score");

            context.append(String.format("[자료 %d] (관련도: %.2f)\n", i + 1, score));
            context.append(text);
            context.append("\n\n");
        }

        return context.toString();
    }

    /**
     * 소스 정보 추출
     */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> extractSources(List<Map<String, Object>> docs) {
        List<Map<String, Object>> sources = new ArrayList<>();

        for (Map<String, Object> doc : docs) {
            Map<String, Object> payload = (Map<String, Object>) doc.get("payload");
            if (payload == null) continue;

            Map<String, Object> source = new HashMap<>();
            source.put("docId", doc.get("doc_id"));
            source.put("score", doc.get("score"));
            source.put("title", payload.getOrDefault("title", ""));
            source.put("courseId", payload.get("course_id"));
            source.put("lessonId", payload.get("lesson_id"));

            sources.add(source);
        }

        return sources;
    }

    /**
     * 학습 자료 인덱싱
     */
    public boolean indexLearningContent(String id, String title, String content,
                                         Long courseId, Long lessonId) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("title", title);
        metadata.put("course_id", courseId);
        metadata.put("lesson_id", lessonId);
        metadata.put("indexed_at", System.currentTimeMillis());

        String fullText = title + "\n\n" + content;
        return qdrantService.upsertDocument("lms_learning_content", id, fullText, metadata);
    }

    /**
     * 과정 전체 자료 인덱싱
     */
    public int indexCourseContent(Long courseId, List<Map<String, Object>> contents) {
        int successCount = 0;

        for (Map<String, Object> content : contents) {
            String id = String.valueOf(content.get("id"));
            String title = (String) content.getOrDefault("title", "");
            String text = (String) content.getOrDefault("content", "");
            Long lessonId = (Long) content.get("lesson_id");

            if (indexLearningContent(id, title, text, courseId, lessonId)) {
                successCount++;
            }
        }

        log.info("과정 {} 인덱싱 완료: {}/{}", courseId, successCount, contents.size());
        return successCount;
    }

    /**
     * 유사 학습 자료 추천
     */
    public List<Map<String, Object>> recommendSimilarContent(String contentId, int limit) {
        // 현재 컨텐츠의 텍스트로 유사 문서 검색
        Map<String, Object> collectionInfo = qdrantService.getCollectionInfo("lms_learning_content");
        // 구현: 현재 문서를 가져와서 유사 문서 검색
        return Collections.emptyList();
    }
}
