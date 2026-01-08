package kr.polytech.lms.statistics.ai;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/statistics/api/ai")
public class StatisticsAiApiController {
    // 왜: 프론트(UI)는 별도 구현하더라도, 백엔드는 "자연어 → 실행계획(JSON) → 기존 데이터로 계산 → 차트 데이터"를
    //     한 API로 제공하면 화면 구현이 단순해지고, 가드레일(검증/권한)을 서버에서 통제할 수 있습니다.

    private final StatisticsAiService statisticsAiService;

    public StatisticsAiApiController(StatisticsAiService statisticsAiService) {
        this.statisticsAiService = statisticsAiService;
    }

    @GetMapping("/catalog")
    public StatisticsAiCatalogResponse catalog() {
        return statisticsAiService.getCatalog();
    }

    @PostMapping("/query")
    public ResponseEntity<?> query(@RequestBody StatisticsAiQueryRequest request) {
        try {
            return ResponseEntity.ok(statisticsAiService.query(request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError("AI 통계 처리 중 오류가 발생했습니다."));
        }
    }

    private record ApiError(String message) {
    }
}

