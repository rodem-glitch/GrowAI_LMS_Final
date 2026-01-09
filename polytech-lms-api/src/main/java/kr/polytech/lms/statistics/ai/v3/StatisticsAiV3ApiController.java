package kr.polytech.lms.statistics.ai.v3;

import kr.polytech.lms.statistics.ai.StatisticsAiQueryRequest;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * AI 통계 v3 API 컨트롤러
 * 
 * v2 대비 개선:
 * - 되묻기(CLARIFY) 없이 항상 결과 반환
 * - 심플한 구조로 빠른 응답
 */
@RestController
@RequestMapping("/statistics/api/ai/v3")
public class StatisticsAiV3ApiController {

    private static final Logger log = LoggerFactory.getLogger(StatisticsAiV3ApiController.class);

    private final StatisticsAiV3Service statisticsAiV3Service;

    public StatisticsAiV3ApiController(StatisticsAiV3Service statisticsAiV3Service) {
        this.statisticsAiV3Service = statisticsAiV3Service;
    }

    @PostMapping("/query")
    public ResponseEntity<?> query(@RequestBody StatisticsAiQueryRequest request) {
        try {
            return ResponseEntity.ok(statisticsAiV3Service.query(request));
        } catch (Exception e) {
            log.error("AI 통계 v3 처리 중 예외: prompt={}", safePrompt(request), e);
            return ResponseEntity.ok(errorResponse("AI 통계 처리 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "version", "v3",
                "description", "AI 통계 v3 - 심플하고 유연한 분석"
        ));
    }

    private StatisticsAiQueryResponse errorResponse(String message) {
        return new StatisticsAiQueryResponse(
                false, null, null, message,
                List.of("취업률 보여줘", "입학충원률 Top 10", "산업 현황 분석해줘"),
                List.of(), null, null, List.of(), List.of(),
                Map.of("error", message)
        );
    }

    private String safePrompt(StatisticsAiQueryRequest request) {
        if (request == null || request.prompt() == null) return null;
        String p = request.prompt().trim();
        return p.length() <= 100 ? p : p.substring(0, 100) + "...";
    }
}
