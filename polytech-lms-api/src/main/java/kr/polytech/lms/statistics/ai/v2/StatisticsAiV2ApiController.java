package kr.polytech.lms.statistics.ai.v2;

import kr.polytech.lms.statistics.ai.StatisticsAiQueryRequest;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryResponse;
import kr.polytech.lms.statistics.ai.v3.StatisticsAiV3Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/statistics/api/ai/v2")
public class StatisticsAiV2ApiController {
    // 왜: v3 서비스를 기본으로 사용하고, 설정으로 v2로 롤백 가능하게 함

    private static final Logger log = LoggerFactory.getLogger(StatisticsAiV2ApiController.class);

    private final StatisticsAiV2Service statisticsAiV2Service;
    private final StatisticsAiV3Service statisticsAiV3Service;
    
    @Value("${statistics.ai.use-v3:true}")
    private boolean useV3;

    public StatisticsAiV2ApiController(
            StatisticsAiV2Service statisticsAiV2Service,
            StatisticsAiV3Service statisticsAiV3Service
    ) {
        this.statisticsAiV2Service = statisticsAiV2Service;
        this.statisticsAiV3Service = statisticsAiV3Service;
    }

    @GetMapping("/catalog")
    public StatisticsAiV2CatalogResponse catalog() {
        return statisticsAiV2Service.getCatalog();
    }

    @PostMapping("/query")
    public ResponseEntity<?> query(@RequestBody StatisticsAiQueryRequest request) {
        try {
            // 왜: v3 서비스가 더 심플하고 유연하므로 기본으로 사용
            //     문제 발생 시 설정(statistics.ai.use-v3=false)으로 v2로 롤백 가능
            if (useV3) {
                return ResponseEntity.ok(statisticsAiV3Service.query(request));
            }
            return ResponseEntity.ok(statisticsAiV2Service.query(request));
        } catch (IllegalArgumentException e) {
            log.warn("AI 통계 v2 요청 검증 실패: prompt={}, contextKeys={}",
                    safePrompt(request), safeContextKeys(request), e);
            return ResponseEntity.ok(errorResponse(e.getMessage()));
        } catch (IllegalStateException e) {
            log.error("AI 통계 v2 처리 실패(상태): prompt={}, contextKeys={}",
                    safePrompt(request), safeContextKeys(request), e);
            return ResponseEntity.ok(errorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("AI 통계 v2 처리 중 예외: prompt={}, contextKeys={}",
                    safePrompt(request), safeContextKeys(request), e);
            return ResponseEntity.ok(errorResponse("AI 통계 처리 중 오류가 발생했습니다."));
        }
    }

    private StatisticsAiQueryResponse errorResponse(String message) {
        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                message,
                List.of(
                        "서울(11) 20대 인구를 2020~2024로 보여줘",
                        "서울(11) ICT 종사자 수를 2020~2024로 보여줘",
                        "서울정수 취업률 Top 10 보여줘 (2024)",
                        "서울정수 입학충원률 Top 10 보여줘",
                        "서울(11) ICT 종사자 수와 서울정수 취업률을 2020~2024로 같이 보여줘"
                ),
                List.of(),
                null,
                null,
                List.of(),
                List.of(),
                // 왜: 화면은 debug를 쓰지 않지만, 개발자는 네트워크 응답(JSON)에서 원인 힌트를 바로 볼 수 있습니다.
                Map.of("error", message)
        );
    }

    private String safePrompt(StatisticsAiQueryRequest request) {
        if (request == null || request.prompt() == null) return null;
        String p = request.prompt().trim();
        if (p.length() <= 200) return p;
        return p.substring(0, 200) + "...";
    }

    private List<String> safeContextKeys(StatisticsAiQueryRequest request) {
        if (request == null || request.context() == null) return List.of();
        return request.context().keySet().stream().limit(30).toList();
    }
}
