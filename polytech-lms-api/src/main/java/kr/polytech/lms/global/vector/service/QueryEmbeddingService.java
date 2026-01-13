package kr.polytech.lms.global.vector.service;

import java.util.List;
import java.util.Objects;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingRequest;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.ai.google.genai.text.GoogleGenAiTextEmbeddingOptions;
import org.springframework.stereotype.Service;

/**
 * 쿼리용 임베딩을 RETRIEVAL_QUERY task-type으로 생성하는 서비스.
 * 왜: 문서 인덱싱은 RETRIEVAL_DOCUMENT, 검색 쿼리는 RETRIEVAL_QUERY를 사용해야
 *     벡터 공간에서 쿼리-문서 매칭이 최적화됩니다.
 */
@Service
public class QueryEmbeddingService {

    private final EmbeddingModel embeddingModel;

    public QueryEmbeddingService(EmbeddingModel embeddingModel) {
        // 왜: Spring AI가 자동 설정한 EmbeddingModel을 그대로 주입받되,
        //     쿼리 시에만 task-type을 오버라이드해서 사용합니다.
        this.embeddingModel = Objects.requireNonNull(embeddingModel);
    }

    /**
     * RETRIEVAL_QUERY task-type으로 쿼리 텍스트를 임베딩합니다.
     * @param query 검색 쿼리 텍스트
     * @return 임베딩 벡터 (float 배열)
     */
    public float[] embedQuery(String query) {
        if (query == null || query.isBlank()) {
            return new float[0];
        }

        // 왜: GoogleGenAiTextEmbeddingOptions로 task-type을 RETRIEVAL_QUERY로 지정합니다.
        // 기본 설정(RETRIEVAL_DOCUMENT)을 이 요청에서만 오버라이드합니다.
        GoogleGenAiTextEmbeddingOptions queryOptions = GoogleGenAiTextEmbeddingOptions.builder()
            .taskType(GoogleGenAiTextEmbeddingOptions.TaskType.RETRIEVAL_QUERY)
            .build();

        EmbeddingRequest request = new EmbeddingRequest(
            List.of(query),
            queryOptions
        );

        EmbeddingResponse response = embeddingModel.call(request);

        if (response == null || response.getResults() == null || response.getResults().isEmpty()) {
            return new float[0];
        }

        return response.getResults().get(0).getOutput();
    }
}
