package kr.polytech.lms.instructorrecommend.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import kr.polytech.lms.global.vector.service.VectorStoreService;
import kr.polytech.lms.global.vector.service.dto.VectorSearchResult;
import kr.polytech.lms.instructorrecommend.service.dto.InstructorVideoRecommendRequest;
import kr.polytech.lms.instructorrecommend.service.dto.InstructorVideoRecommendResponse;
import org.springframework.stereotype.Service;

@Service
public class InstructorRecommendService {

    private final VectorStoreService vectorStoreService;

    public InstructorRecommendService(VectorStoreService vectorStoreService) {
        // 왜: 추천 엔진(벡터 검색)을 공통 모듈로 분리해 학생/교수자 추천이 같은 코어를 재사용하게 합니다.
        this.vectorStoreService = vectorStoreService;
    }

    public List<InstructorVideoRecommendResponse> recommendVideos(InstructorVideoRecommendRequest request) {
        String query = buildQueryText(request);
        String filterExpression = buildFilterExpression(request);

        List<VectorSearchResult> results = vectorStoreService.similaritySearch(
            query,
            request.topK(),
            request.similarityThreshold(),
            filterExpression
        );

        return results.stream()
            .map(this::toResponse)
            .toList();
    }

    private String buildFilterExpression(InstructorVideoRecommendRequest request) {
        // 왜: 벡터 검색 결과를 "해당 사이트/카테고리/영상타입"으로 제한해야 추천 품질이 안정적으로 올라갑니다.
        StringBuilder filter = new StringBuilder();

        if (request.siteId() != null) {
            filter.append("site_id == ").append(request.siteId());
        }

        if (request.categoryId() != null) {
            if (filter.length() > 0) filter.append(" && ");
            filter.append("category_id == ").append(request.categoryId());
        }

        if (request.lessonTypes() != null && !request.lessonTypes().isEmpty()) {
            if (filter.length() > 0) filter.append(" && ");
            String inList = request.lessonTypes().stream()
                .filter(v -> v != null && !v.isBlank())
                .map(v -> "'" + v.replace("'", "") + "'")
                .reduce((a, b) -> a + ", " + b)
                .orElse("'05'");
            filter.append("lesson_type in [").append(inList).append("]");
        }

        return filter.toString();
    }

    private String buildQueryText(InstructorVideoRecommendRequest request) {
        // 왜: 벡터 검색 품질은 "질문 문장(쿼리)" 품질에 크게 좌우됩니다.
        // - 아직 화면/필드가 확정 전이므로, 들어온 값을 최대한 자연어로 합쳐서 쿼리를 구성합니다.
        StringBuilder sb = new StringBuilder();

        if (request.courseName() != null && !request.courseName().isBlank()) {
            sb.append("과정명: ").append(request.courseName()).append("\n");
        }
        if (request.subjectName() != null && !request.subjectName().isBlank()) {
            sb.append("과목: ").append(request.subjectName()).append("\n");
        }
        if (request.grade() != null && !request.grade().isBlank()) {
            sb.append("학년: ").append(request.grade()).append("\n");
        }
        if (request.term() != null && !request.term().isBlank()) {
            sb.append("학기: ").append(request.term()).append("\n");
        }
        if (request.keywords() != null && !request.keywords().isBlank()) {
            sb.append("키워드: ").append(request.keywords()).append("\n");
        }
        if (request.freeText() != null && !request.freeText().isBlank()) {
            sb.append("추가설명: ").append(request.freeText()).append("\n");
        }

        if (sb.length() == 0) {
            // 왜: 최소한의 검색이 되게, 빈 요청은 광범위한 기본 문장으로 처리합니다.
            return "교수자가 과정에 넣을 교육용 영상을 추천해 주세요.";
        }

        sb.append("요청: 위 정보를 바탕으로 과정에 적합한 교육용 영상(차시)을 추천해 주세요.");
        return sb.toString();
    }

    private InstructorVideoRecommendResponse toResponse(VectorSearchResult result) {
        Map<String, Object> meta = result.metadata() != null ? result.metadata() : new HashMap<>();
        Object lessonId = meta.get("lesson_id");
        Object lessonName = meta.get("lesson_nm");

        return new InstructorVideoRecommendResponse(
            lessonId != null ? String.valueOf(lessonId) : null,
            lessonName != null ? String.valueOf(lessonName) : null,
            result.score(),
            meta
        );
    }
}
