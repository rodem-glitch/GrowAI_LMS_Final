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
        if (text == null || text.isBlank()) return;
        vectorStore.add(List.of(new Document(text, metadata)));
    }

    public List<VectorSearchResult> similaritySearch(String query, int topK, double similarityThreshold) {
        if (query == null || query.isBlank()) return List.of();

        int safeTopK = Math.max(1, Math.min(topK, 50));
        double safeThreshold = Math.max(0.0, Math.min(similarityThreshold, 1.0));

        List<Document> results = vectorStore.similaritySearch(
            SearchRequest.builder()
                .query(query)
                .topK(safeTopK)
                .similarityThreshold(safeThreshold)
                .build()
        );

        return results.stream()
            .map(d -> new VectorSearchResult(d.getText(), d.getMetadata(), d.getScore()))
            .toList();
    }
}

