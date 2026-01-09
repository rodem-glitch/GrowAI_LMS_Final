package kr.polytech.lms.tutorcontentrecommend.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import kr.polytech.lms.global.vector.service.VectorStoreService;
import kr.polytech.lms.global.vector.service.dto.VectorSearchResult;
import kr.polytech.lms.tutorcontentrecommend.service.dto.TutorContentRecommendRequest;
import kr.polytech.lms.tutorcontentrecommend.service.dto.TutorContentRecommendResponse;
import org.springframework.stereotype.Service;

@Service
public class TutorContentRecommendService {

    private final VectorStoreService vectorStoreService;

    public TutorContentRecommendService(VectorStoreService vectorStoreService) {
        // 왜: 벡터 DB(Qdrant) 검색은 공통 VectorStoreService로 통일해서, 추천 도메인별로 재사용합니다.
        this.vectorStoreService = Objects.requireNonNull(vectorStoreService);
    }

    public List<TutorContentRecommendResponse> recommendLessons(TutorContentRecommendRequest request) {
        TutorContentRecommendRequest safe = request == null ? TutorContentRecommendRequest.empty() : request;

        String query = buildQueryText(safe);
        String filterExpression = "source == 'tb_reco_content'";

        List<VectorSearchResult> results = vectorStoreService.similaritySearch(
            query,
            safe.topKOrDefault(),
            safe.similarityThresholdOrDefault(),
            filterExpression
        );

        return results.stream()
            .map(this::toResponse)
            .toList();
    }

    private String buildQueryText(TutorContentRecommendRequest request) {
        // 왜: 교수자가 입력한 "과목/차시" 정보는 영상 추천에 필요한 힌트이므로, 자연어 문장으로 합쳐 임베딩 쿼리를 만듭니다.
        StringBuilder sb = new StringBuilder();

        appendIfPresent(sb, "과목명", request.courseName());
        appendIfPresent(sb, "과목소개", request.courseIntro());
        appendIfPresent(sb, "과목세부내용", request.courseDetail());
        appendIfPresent(sb, "차시제목", request.lessonTitle());
        appendIfPresent(sb, "차시설명", request.lessonDescription());
        appendIfPresent(sb, "키워드", request.keywords());

        if (sb.length() == 0) {
            // 왜: 아무것도 안 들어오면 벡터 검색이 의미가 없어서, 최소한의 기본 문장을 제공합니다.
            return "과목 개설에 적합한 교육용 영상을 추천해 주세요.";
        }

        sb.append("요청: 위 내용을 학습하는 데 도움이 되는 기존 교육용 영상을 추천해 주세요.");
        return sb.toString();
    }

    private void appendIfPresent(StringBuilder sb, String label, String value) {
        if (value == null) return;
        String trimmed = value.trim();
        if (trimmed.isBlank()) return;
        sb.append(label).append(": ").append(trimmed).append("\n");
    }

    private TutorContentRecommendResponse toResponse(VectorSearchResult result) {
        Map<String, Object> meta = result.metadata() == null ? new HashMap<>() : new HashMap<>(result.metadata());

        String lessonId = toStringValue(meta.get("lesson_id"));
        Long recoContentId = toLong(meta.get("content_id"));

        String title = meta.get("title") != null ? String.valueOf(meta.get("title")) : null;
        String category = meta.get("category_nm") != null ? String.valueOf(meta.get("category_nm")) : null;
        String summary = meta.get("summary") != null ? String.valueOf(meta.get("summary")) : null;
        String keywords = meta.get("keywords") != null ? String.valueOf(meta.get("keywords")) : null;

        return new TutorContentRecommendResponse(
            lessonId,
            recoContentId,
            title,
            category,
            summary,
            keywords,
            result.score(),
            meta
        );
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Number n) return n.longValue();
        try {
            String s = String.valueOf(value).trim();
            if (s.isBlank()) return null;
            return Long.parseLong(s);
        } catch (Exception ignored) {
            return null;
        }
    }

    private String toStringValue(Object value) {
        // 왜: 콜러스 영상 키값은 '5vcd73vW' 같은 문자열이므로, 그대로 String으로 변환합니다.
        if (value == null) return null;
        String s = String.valueOf(value).trim();
        return s.isBlank() ? null : s;
    }
}
