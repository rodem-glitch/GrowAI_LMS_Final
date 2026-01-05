package kr.polytech.lms.global.vector.service;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import kr.polytech.lms.global.vector.service.dto.VectorSearchResult;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

@Service
public class VectorStoreService {

    private final VectorStore vectorStore;

    public VectorStoreService(VectorStore vectorStore) {
        // 왜: Qdrant/임베딩 구현체에 묶이지 않고, Spring AI의 VectorStore 추상화만 의존해 재사용성을 높입니다.
        this.vectorStore = Objects.requireNonNull(vectorStore);
    }

    public void upsertText(String text, Map<String, Object> metadata) {
        // 왜: 기존 코드 호환을 위해 id 없이 적재하는 메서드를 남깁니다.
        if (text == null || text.isBlank()) return;
        vectorStore.add(List.of(new Document(text, metadata)));
    }

    public void upsertText(String id, String text, Map<String, Object> metadata) {
        // 왜: 같은 lesson_id를 여러 번 적재해도 "덮어쓰기(upsert)"가 되도록 문서 id를 고정합니다.
        if (text == null || text.isBlank()) return;

        if (id == null || id.isBlank()) {
            vectorStore.add(List.of(new Document(text, metadata)));
            return;
        }

        vectorStore.add(List.of(new Document(id, text, metadata)));
    }

    public List<VectorSearchResult> similaritySearch(String query, int topK, double similarityThreshold) {
        return similaritySearch(query, topK, similarityThreshold, null);
    }

    public List<VectorSearchResult> similaritySearch(
        String query,
        int topK,
        double similarityThreshold,
        String filterExpression
    ) {
        if (query == null || query.isBlank()) return List.of();

        int safeTopK = Math.max(1, Math.min(topK, 50));
        double safeThreshold = Math.max(0.0, Math.min(similarityThreshold, 1.0));

        SearchRequest.Builder builder = SearchRequest.builder()
            .query(query)
            .topK(safeTopK)
            .similarityThreshold(safeThreshold);

        if (filterExpression != null && !filterExpression.isBlank()) {
            // 왜: 교수자/학생 추천처럼 "상황"이 있는 검색은 메타데이터 필터를 걸어야 품질이 안정적으로 올라갑니다.
            builder.filterExpression(filterExpression);
        }

        List<Document> results = vectorStore.similaritySearch(builder.build());

        return results.stream()
            .map(d -> new VectorSearchResult(d.getText(), d.getMetadata(), d.getScore()))
            .toList();
    }
}
