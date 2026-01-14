package kr.polytech.lms.global.vector.service;

import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private static final Logger log = LoggerFactory.getLogger(QueryEmbeddingService.class);

    private final EmbeddingModel embeddingModel;

    public QueryEmbeddingService(EmbeddingModel embeddingModel) {
        // 왜: Spring AI가 자동 설정한 EmbeddingModel을 그대로 주입받되,
        //     쿼리 시에만 task-type을 오버라이드해서 사용합니다.
        this.embeddingModel = Objects.requireNonNull(embeddingModel);
        log.info("[QueryEmbeddingService] 초기화 완료. EmbeddingModel 클래스: {}", embeddingModel.getClass().getName());
    }

    /**
     * RETRIEVAL_QUERY task-type으로 쿼리 텍스트를 임베딩합니다.
     * @param query 검색 쿼리 텍스트
     * @return 임베딩 벡터 (float 배열)
     */
    public float[] embedQuery(String query) {
        log.info("[QueryEmbedding] ========== 쿼리 임베딩 시작 ==========");
        log.info("[QueryEmbedding] 입력 쿼리: '{}'", query);

        if (query == null || query.isBlank()) {
            log.warn("[QueryEmbedding] 빈 쿼리 입력됨. 빈 벡터 반환.");
            return new float[0];
        }

        try {
            // 왜: GoogleGenAiTextEmbeddingOptions로 task-type을 RETRIEVAL_QUERY로 지정합니다.
            // 기본 설정(RETRIEVAL_DOCUMENT)을 이 요청에서만 오버라이드합니다.
            GoogleGenAiTextEmbeddingOptions queryOptions = GoogleGenAiTextEmbeddingOptions.builder()
                .taskType(GoogleGenAiTextEmbeddingOptions.TaskType.RETRIEVAL_QUERY)
                .build();
            log.info("[QueryEmbedding] Task-Type 설정: RETRIEVAL_QUERY");

            EmbeddingRequest request = new EmbeddingRequest(
                List.of(query),
                queryOptions
            );

            log.info("[QueryEmbedding] EmbeddingModel.call() 호출 시작...");
            EmbeddingResponse response = embeddingModel.call(request);

            if (response == null) {
                log.error("[QueryEmbedding] API 응답이 null입니다!");
                return new float[0];
            }

            if (response.getResults() == null || response.getResults().isEmpty()) {
                log.error("[QueryEmbedding] API 응답에 결과가 없습니다! results={}", response.getResults());
                return new float[0];
            }

            float[] vector = response.getResults().get(0).getOutput();
            
            if (vector == null || vector.length == 0) {
                log.error("[QueryEmbedding] 생성된 벡터가 비어있습니다!");
                return new float[0];
            }

            // 벡터 정보 로깅
            double magnitude = 0;
            for (float v : vector) {
                magnitude += v * v;
            }
            magnitude = Math.sqrt(magnitude);

            log.info("[QueryEmbedding] ✅ 벡터 생성 성공!");
            log.info("[QueryEmbedding] - 벡터 차원: {}", vector.length);
            log.info("[QueryEmbedding] - 벡터 크기(magnitude): {}", String.format("%.4f", magnitude));
            log.info("[QueryEmbedding] - 처음 5개 값: {}", Arrays.toString(Arrays.copyOf(vector, Math.min(5, vector.length))));
            log.info("[QueryEmbedding] ========================================");

            return vector;

        } catch (Exception e) {
            log.error("[QueryEmbedding] ❌ 임베딩 생성 중 예외 발생!", e);
            log.error("[QueryEmbedding] 예외 타입: {}, 메시지: {}", e.getClass().getName(), e.getMessage());
            return new float[0];
        }
    }
}
