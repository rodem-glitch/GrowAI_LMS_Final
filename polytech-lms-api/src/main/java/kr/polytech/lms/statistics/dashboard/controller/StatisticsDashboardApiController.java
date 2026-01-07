package kr.polytech.lms.statistics.dashboard.controller;

import kr.polytech.lms.statistics.dashboard.service.IndustryAnalysisService;
import kr.polytech.lms.statistics.dashboard.service.PopulationComparisonService;
import kr.polytech.lms.statistics.dashboard.service.StatisticsExcelExportService;
import kr.polytech.lms.statistics.dashboard.service.StatisticsMetaService;
import kr.polytech.lms.statistics.internalstats.InternalStatisticsService;
import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/statistics/api")
public class StatisticsDashboardApiController {
    // 왜: 통계 화면(정적 HTML)이 필요한 데이터만 API로 받아서 렌더링할 수 있도록 JSON API를 제공합니다.

    private final StatisticsMetaService statisticsMetaService;
    private final IndustryAnalysisService industryAnalysisService;
    private final PopulationComparisonService populationComparisonService;
    private final InternalStatisticsService internalStatisticsService;
    private final StatisticsExcelExportService statisticsExcelExportService;

    public StatisticsDashboardApiController(
            StatisticsMetaService statisticsMetaService,
            IndustryAnalysisService industryAnalysisService,
            PopulationComparisonService populationComparisonService,
            InternalStatisticsService internalStatisticsService,
            StatisticsExcelExportService statisticsExcelExportService
    ) {
        this.statisticsMetaService = statisticsMetaService;
        this.industryAnalysisService = industryAnalysisService;
        this.populationComparisonService = populationComparisonService;
        this.internalStatisticsService = internalStatisticsService;
        this.statisticsExcelExportService = statisticsExcelExportService;
    }

    @GetMapping("/meta/campus-groups")
    public List<MajorIndustryMappingService.CampusGroup> campusGroups() {
        return statisticsMetaService.getCampusGroups();
    }

    @GetMapping("/industry/analysis")
    public ResponseEntity<?> industryAnalysis(
            @RequestParam(name = "campus", required = false) String campus,
            @RequestParam(name = "admCd", required = false) String admCd,
            @RequestParam(name = "statsYear", required = false) Integer statsYear
    ) throws IOException {
        try {
            return ResponseEntity.ok(industryAnalysisService.analyze(campus, admCd, statsYear));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/population/compare")
    public ResponseEntity<?> populationCompare(
            @RequestParam(name = "campus") String campus,
            @RequestParam(name = "admCd", required = false) String admCd,
            @RequestParam(name = "populationYear", required = false) Integer populationYear
    ) throws IOException {
        try {
            return ResponseEntity.ok(populationComparisonService.compare(campus, admCd, populationYear));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/internal/employment/top")
    public ResponseEntity<?> topEmploymentRates(
            @RequestParam(name = "campus") String campus,
            @RequestParam(name = "top", defaultValue = "10") int top
    ) {
        try {
            return ResponseEntity.ok(internalStatisticsService.getTopEmploymentRates(campus, top));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/internal/admission/top")
    public ResponseEntity<?> topAdmissionFillRates(
            @RequestParam(name = "campus") String campus,
            @RequestParam(name = "top", defaultValue = "10") int top
    ) {
        try {
            return ResponseEntity.ok(internalStatisticsService.getTopAdmissionFillRates(campus, top));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/internal/export")
    public ResponseEntity<?> exportInternalExcel(
            @RequestParam(name = "campus") String campus
    ) {
        try {
            byte[] bytes = statisticsExcelExportService.exportInternal(
                    campus,
                    internalStatisticsService.getEmploymentRates(campus),
                    internalStatisticsService.getAdmissionFillRates(campus)
            );
            return toExcelResponse("내부통계_" + campus + ".xlsx", bytes);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/population/export")
    public ResponseEntity<?> exportPopulationExcel(
            @RequestParam(name = "campus") String campus,
            @RequestParam(name = "admCd", required = false) String admCd,
            @RequestParam(name = "populationYear", required = false) Integer populationYear
    ) throws IOException {
        try {
            PopulationComparisonService.PopulationComparisonResponse response =
                    populationComparisonService.compare(campus, admCd, populationYear);
            byte[] bytes = statisticsExcelExportService.exportPopulation(response);
            String filename = "인구비율_%s_%s_%s.xlsx".formatted(campus, response.admCd(), response.populationYear());
            return toExcelResponse(filename, bytes);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    @GetMapping("/industry/export")
    public ResponseEntity<?> exportIndustryExcel(
            @RequestParam(name = "campus", required = false) String campus,
            @RequestParam(name = "admCd", required = false) String admCd,
            @RequestParam(name = "statsYear", required = false) Integer statsYear
    ) throws IOException {
        try {
            IndustryAnalysisService.IndustryAnalysisResponse response =
                    industryAnalysisService.analyze(campus, admCd, statsYear);
            byte[] bytes = statisticsExcelExportService.exportIndustry(response);
            String filename = "산업비율_%s_%s_%s.xlsx".formatted(
                    response.campus() == null ? "전체" : response.campus(),
                    response.admCd(),
                    response.statsYear()
            );
            return toExcelResponse(filename, bytes);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiError(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiError(e.getMessage()));
        }
    }

    private ResponseEntity<byte[]> toExcelResponse(String filename, byte[] bytes) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        headers.setContentDisposition(ContentDisposition.attachment().filename(filename, StandardCharsets.UTF_8).build());
        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
    }

    private record ApiError(String message) {
    }
}
