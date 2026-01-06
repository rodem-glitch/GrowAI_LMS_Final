package kr.polytech.lms.studentcontentrecommend.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import kr.polytech.lms.global.vector.service.VectorStoreService;
import kr.polytech.lms.global.vector.service.dto.VectorSearchResult;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentHomeRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentSearchRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentVideoRecommendResponse;
import org.springframework.stereotype.Service;

@Service
public class StudentContentRecommendService {

    private final VectorStoreService vectorStoreService;

    public StudentContentRecommendService(VectorStoreService vectorStoreService) {
        // 왜: 교수자/학생 모두 같은 벡터 DB(Qdrant)를 쓰므로, 검색 코어(VectorStoreService)는 공통으로 재사용합니다.
        this.vectorStoreService = Objects.requireNonNull(vectorStoreService);
    }

    public List<StudentVideoRecommendResponse> recommendHome(StudentHomeRecommendRequest request) {
        StudentHomeRecommendRequest safe = request == null ? StudentHomeRecommendRequest.empty() : request;

        String query = buildHomeQueryText(safe);
        String filterExpression = "source == 'tb_reco_content'";

        List<VectorSearchResult> results = vectorStoreService.similaritySearch(
            query,
            safe.topKOrDefault(),
            safe.similarityThresholdOrDefault(),
            filterExpression
        );

        return results.stream().map(this::toResponse).toList();
    }

    public List<StudentVideoRecommendResponse> recommendSearch(StudentSearchRecommendRequest request) {
        StudentSearchRecommendRequest safe = request == null ? StudentSearchRecommendRequest.empty() : request;

        String query = buildSearchQueryText(safe);
        String filterExpression = "source == 'tb_reco_content'";

        List<VectorSearchResult> results = vectorStoreService.similaritySearch(
            query,
            safe.topKOrDefault(),
            safe.similarityThresholdOrDefault(),
            filterExpression
        );

        return results.stream().map(this::toResponse).toList();
    }

    private String buildHomeQueryText(StudentHomeRecommendRequest request) {
        // 왜: 홈 추천은 사용자가 검색어를 입력하지 않아도, "내가 무엇을 배우고 있는지"를 힌트로 추천을 만들기 위함입니다.
        StringBuilder sb = new StringBuilder();

        appendIfPresent(sb, "학과", request.deptName());
        appendIfPresent(sb, "전공", request.majorName());

        if (request.courseNames() != null && !request.courseNames().isEmpty()) {
            String joined = request.courseNames().stream()
                .filter(v -> v != null && !v.isBlank())
                .map(String::trim)
                .distinct()
                .limit(20)
                .reduce((a, b) -> a + ", " + b)
                .orElse("");
            appendIfPresent(sb, "수강과목", joined);
        }

        appendIfPresent(sb, "관심사/요청", request.extraQuery());

        if (sb.length() == 0) {
            return "학생에게 도움이 되는 교육용 영상을 추천해 주세요.";
        }

        sb.append("요청: 위 학생에게 도움이 되는 교육용 영상을 추천해 주세요.");
        return sb.toString();
    }

    private String buildSearchQueryText(StudentSearchRecommendRequest request) {
        // 왜: 검색 추천은 사용자가 친 자연어가 곧 "의도"라서, 불필요한 포맷팅 없이 그대로 쓰는 게 좋습니다.
        String q = request.query() == null ? "" : request.query().trim();
        if (q.isBlank()) return "학생에게 도움이 되는 교육용 영상을 추천해 주세요.";
        return q;
    }

    private void appendIfPresent(StringBuilder sb, String label, String value) {
        if (value == null) return;
        String trimmed = value.trim();
        if (trimmed.isBlank()) return;
        sb.append(label).append(": ").append(trimmed).append("\n");
    }

    private StudentVideoRecommendResponse toResponse(VectorSearchResult result) {
        Map<String, Object> meta = result.metadata() == null ? new HashMap<>() : new HashMap<>(result.metadata());

        Long lessonId = toLong(meta.get("lesson_id"));
        Long recoContentId = toLong(meta.get("content_id"));

        String title = meta.get("title") != null ? String.valueOf(meta.get("title")) : null;
        String category = meta.get("category_nm") != null ? String.valueOf(meta.get("category_nm")) : null;

        return new StudentVideoRecommendResponse(
            lessonId,
            recoContentId,
            title,
            category,
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
}

