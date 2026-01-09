package kr.polytech.lms.studentcontentrecommend.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import kr.polytech.lms.global.vector.service.VectorStoreService;
import kr.polytech.lms.global.vector.service.dto.VectorSearchResult;
import kr.polytech.lms.recocontent.entity.RecoContent;
import kr.polytech.lms.recocontent.repository.RecoContentRepository;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentHomeRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentSearchRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentVideoRecommendResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class StudentContentRecommendService {

    private final VectorStoreService vectorStoreService;
    private final JdbcTemplate jdbcTemplate;
    private final RecoContentRepository recoContentRepository;

    public StudentContentRecommendService(
        VectorStoreService vectorStoreService,
        JdbcTemplate jdbcTemplate,
        RecoContentRepository recoContentRepository
    ) {
        // 왜: 교수자/학생 모두 같은 벡터 DB(Qdrant)를 쓰므로, 검색 코어(VectorStoreService)는 공통으로 재사용합니다.
        this.vectorStoreService = Objects.requireNonNull(vectorStoreService);
        // 왜: 레거시 LMS DB에서 "수강/시청/완료" 상태를 빠르게 확인해야 해서 JdbcTemplate을 사용합니다.
        this.jdbcTemplate = Objects.requireNonNull(jdbcTemplate);
        this.recoContentRepository = Objects.requireNonNull(recoContentRepository);
    }

    public List<StudentVideoRecommendResponse> recommendHome(StudentHomeRecommendRequest request) {
        StudentHomeRecommendRequest safe = request == null ? StudentHomeRecommendRequest.empty() : request;

        String query = buildHomeQueryText(safe);
        String filterExpression = "source == 'tb_reco_content'";

        int desiredTopK = safe.topKOrDefault();
        // 왜: 홈 추천에서 "이미 수강/시청/완료 제외"를 하면 후보가 많이 빠질 수 있으니, Qdrant는 넉넉히 가져옵니다.
        int fetchTopK = computeFetchTopK(desiredTopK, safe.excludeEnrolledOrDefault() || safe.excludeWatchedOrDefault() || safe.excludeCompletedOrDefault());

        List<VectorSearchResult> results = vectorStoreService.similaritySearch(
            query,
            fetchTopK,
            safe.similarityThresholdOrDefault(),
            filterExpression
        );

        return postProcessResults(
            results,
            safe.userId(),
            safe.siteId(),
            desiredTopK,
            safe.excludeEnrolledOrDefault(),
            safe.excludeWatchedOrDefault(),
            safe.excludeCompletedOrDefault()
        );
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

        // 왜: 검색은 기본적으로 전체에서 찾되, 가능하면 "내가 본/수강한/완료한" 표시를 같이 내려줍니다.
        return postProcessResults(results, safe.userId(), safe.siteId(), safe.topKOrDefault(), false, false, false);
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

    private List<StudentVideoRecommendResponse> postProcessResults(
        List<VectorSearchResult> results,
        Long userId,
        Integer siteId,
        int desiredTopK,
        boolean excludeEnrolled,
        boolean excludeWatched,
        boolean excludeCompleted
    ) {
        Map<String, LessonStudyStatus> statusByLessonId = fetchLessonStudyStatus(userId, siteId);
        Set<String> seenLessonIds = new HashSet<>();
        List<StudentVideoRecommendResponse> out = new ArrayList<>();

        for (VectorSearchResult result : results) {
            StudentVideoRecommendResponse response = toResponse(result, statusByLessonId);
            String lessonId = response.lessonId();

            // 왜: 임시 데이터(lesson_id 없는 문서)도 존재할 수 있으니, 그 경우는 그냥 통과시킵니다.
            if (lessonId != null) {
                // 왜: 같은 레슨이 중복으로 내려오면 UX가 나빠서, 첫 번째만 남깁니다.
                if (!seenLessonIds.add(lessonId)) continue;

                LessonStudyStatus status = statusByLessonId.get(lessonId);
                if (excludeEnrolled && status != null && Boolean.TRUE.equals(status.enrolled())) continue;
                if (excludeWatched && status != null && Boolean.TRUE.equals(status.watched())) continue;
                if (excludeCompleted && status != null && Boolean.TRUE.equals(status.completed())) continue;
            }

            out.add(response);
            if (out.size() >= desiredTopK) break;
        }

        return out;
    }

    private StudentVideoRecommendResponse toResponse(VectorSearchResult result, Map<String, LessonStudyStatus> statusByLessonId) {
        Map<String, Object> meta = result.metadata() == null ? new HashMap<>() : new HashMap<>(result.metadata());

        String lessonId = toStringValue(meta.get("lesson_id"));
        Long recoContentId = toLong(meta.get("content_id"));

        // 왜: 벡터 메타데이터에는 summary가 없을 수 있으므로, DB에서 직접 조회합니다.
        String title = null;
        String categoryNm = null;
        String summary = null;
        String keywords = null;

        if (recoContentId != null) {
            RecoContent content = recoContentRepository.findById(recoContentId).orElse(null);
            if (content != null) {
                title = content.getTitle();
                categoryNm = content.getCategoryNm();
                summary = content.getSummary();
                keywords = content.getKeywords();
                if (lessonId == null) {
                    lessonId = content.getLessonId();
                }
            }
        }

        // 왜: DB 조회 실패 시 메타데이터에서 fallback
        if (title == null) {
            title = meta.get("title") != null ? String.valueOf(meta.get("title")) : null;
        }
        if (categoryNm == null) {
            categoryNm = meta.get("category_nm") != null ? String.valueOf(meta.get("category_nm")) : null;
        }

        LessonStudyStatus status = (lessonId == null || lessonId.isBlank()) ? null : statusByLessonId.get(lessonId);
        return new StudentVideoRecommendResponse(
            lessonId,
            recoContentId,
            title,
            categoryNm,
            summary,
            keywords,
            result.score(),
            status == null ? null : status.enrolled(),
            status == null ? null : status.watched(),
            status == null ? null : status.completed(),
            status == null ? null : status.lastDate(),
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

    private int computeFetchTopK(int desiredTopK, boolean needBuffer) {
        if (!needBuffer) return desiredTopK;
        // 왜: 제외 조건이 켜지면 결과가 부족할 수 있으니, Qdrant에서 더 많이 가져옵니다(네트워크/CPU 균형을 위해 상한 둠).
        int buffered = desiredTopK * 10 + 50;
        return Math.max(desiredTopK, Math.min(buffered, 300));
    }

    private Map<String, LessonStudyStatus> fetchLessonStudyStatus(Long userId, Integer siteId) {
        // 왜: 콜러스 영상은 외부 콘텐츠라서 기존 LMS DB(LM_COURSE_PROGRESS)에 학습 기록이 없습니다.
        // 추후 콜러스 시청 기록을 별도 테이블로 관리하게 되면, 여기서 조회하면 됩니다.
        // 현재는 빈 Map을 반환하여 수강/시청/완료 상태 표시 없이 추천만 합니다.
        return Map.of();
    }

    private record LessonStudyStatus(
        Boolean enrolled,
        Boolean watched,
        Boolean completed,
        String lastDate
    ) {}
}
