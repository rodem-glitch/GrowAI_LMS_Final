package kr.polytech.lms.recocontent.service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import kr.polytech.lms.global.vector.service.VectorStoreService;
import kr.polytech.lms.recocontent.entity.RecoContent;
import kr.polytech.lms.recocontent.repository.RecoContentRepository;
import kr.polytech.lms.recocontent.service.dto.IndexRecoContentsRequest;
import kr.polytech.lms.recocontent.service.dto.IndexRecoContentsResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class RecoContentVectorIndexService {

    private final RecoContentRepository recoContentRepository;
    private final VectorStoreService vectorStoreService;
    private final String embeddingModelName;

    public RecoContentVectorIndexService(
        RecoContentRepository recoContentRepository,
        VectorStoreService vectorStoreService,
        @Value("${spring.ai.google.genai.embedding.text.options.model:text-embedding-004}") String embeddingModelName
    ) {
        // 왜: MySQL(원본)과 Qdrant(검색)을 분리하되, 운영에서 "재색인"을 쉽게 하기 위해 한 서비스로 묶습니다.
        this.recoContentRepository = Objects.requireNonNull(recoContentRepository);
        this.vectorStoreService = Objects.requireNonNull(vectorStoreService);
        this.embeddingModelName = embeddingModelName == null ? "" : embeddingModelName;
    }

    public IndexRecoContentsResponse indexFromDatabase(IndexRecoContentsRequest request) {
        IndexRecoContentsRequest safe = request == null ? new IndexRecoContentsRequest(null, null, null) : request;

        PageRequest pageable = PageRequest.of(
            safe.pageOrDefault(),
            safe.sizeOrDefault(),
            Sort.by(Sort.Direction.ASC, "id")
        );

        Page<RecoContent> page = recoContentRepository.findAll(pageable);

        int indexed = 0;
        for (RecoContent content : page.getContent()) {
            if (content.getId() == null) continue;
            String docId = "reco_content:" + content.getId();

            Map<String, Object> metadata = buildMetadata(content, safe.embeddingVersionOrDefault());
            String text = buildEmbeddingText(content);

            vectorStoreService.upsertText(docId, text, metadata);
            indexed++;
        }

        return new IndexRecoContentsResponse(page.getNumberOfElements(), indexed);
    }

    private Map<String, Object> buildMetadata(RecoContent content, int embeddingVersion) {
        Map<String, Object> meta = new HashMap<>();
        meta.put("source", "tb_reco_content");
        meta.put("content_id", content.getId());
        meta.put("category_nm", content.getCategoryNm());
        meta.put("title", content.getTitle());
        meta.put("keywords", content.getKeywords());
        meta.put("embedding_model", embeddingModelName);
        meta.put("embedding_version", embeddingVersion);
        meta.put("indexed_at", Instant.now().getEpochSecond());
        return meta;
    }

    private String buildEmbeddingText(RecoContent content) {
        // 왜: 벡터 검색 품질을 올리려면, "제목+요약+키워드+카테고리"를 한 문서로 합쳐 임베딩하는 방식이 안전합니다.
        StringBuilder sb = new StringBuilder();
        if (content.getCategoryNm() != null && !content.getCategoryNm().isBlank()) {
            sb.append("분야: ").append(content.getCategoryNm()).append("\n");
        }
        if (content.getTitle() != null && !content.getTitle().isBlank()) {
            sb.append("강의명: ").append(content.getTitle()).append("\n");
        }
        if (content.getSummary() != null && !content.getSummary().isBlank()) {
            sb.append("요약: ").append(content.getSummary()).append("\n");
        }
        if (content.getKeywords() != null && !content.getKeywords().isBlank()) {
            sb.append("키워드: ").append(content.getKeywords()).append("\n");
        }
        return sb.toString().trim();
    }
}

