package kr.polytech.lms.statistics.ai.v3;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.statistics.ai.GeminiClient;
import kr.polytech.lms.statistics.ai.StatisticsAiProperties;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryRequest;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryResponse;
import kr.polytech.lms.statistics.internalstats.InternalStatisticsService;
import kr.polytech.lms.statistics.kosis.service.KosisStatisticsService;
import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import kr.polytech.lms.statistics.sgis.service.SgisCompanyCacheService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Year;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * AI 통계 v3 서비스 - 심플하고 유연한 구조
 * 
 * 핵심 철학:
 * - 되묻지 않음 (CLARIFY 없음) - 항상 뭔가 보여줌
 * - LLM에게 데이터를 주고 직접 분석하게 함
 * - 모호한 질문에도 합리적 기본값으로 응답
 */
@Service
public class StatisticsAiV3Service {

    private static final Logger log = LoggerFactory.getLogger(StatisticsAiV3Service.class);

    private final StatisticsAiProperties properties;
    private final GeminiClient geminiClient;
    private final ObjectMapper objectMapper;
    private final InternalStatisticsService internalStatisticsService;
    private final SgisCompanyCacheService sgisCompanyCacheService;
    private final KosisStatisticsService kosisStatisticsService;
    private final MajorIndustryMappingService majorIndustryMappingService;

    public StatisticsAiV3Service(
            StatisticsAiProperties properties,
            GeminiClient geminiClient,
            ObjectMapper objectMapper,
            InternalStatisticsService internalStatisticsService,
            SgisCompanyCacheService sgisCompanyCacheService,
            KosisStatisticsService kosisStatisticsService,
            MajorIndustryMappingService majorIndustryMappingService
    ) {
        this.properties = properties;
        this.geminiClient = geminiClient;
        this.objectMapper = objectMapper;
        this.internalStatisticsService = internalStatisticsService;
        this.sgisCompanyCacheService = sgisCompanyCacheService;
        this.kosisStatisticsService = kosisStatisticsService;
        this.majorIndustryMappingService = majorIndustryMappingService;
    }

    public StatisticsAiQueryResponse query(StatisticsAiQueryRequest request) {
        if (request == null || !StringUtils.hasText(request.prompt())) {
            return buildFallbackResponse("질문을 입력해 주세요.");
        }

        String prompt = request.prompt().trim();
        Map<String, Object> context = request.context() != null ? request.context() : Map.of();

        try {
            // 1. LLM에게 필요한 데이터 소스 계획 요청
            List<PlanItem> plan = planData(prompt, context);

            // 2. 계획에 따라 데이터 조회
            DataBundle data = fetchDataBasedOnPlan(plan);

            // 3. LLM에게 데이터와 질문 전달하여 분석 요청
            String modelPrompt = buildPrompt(prompt, data);
            String modelResponse = geminiClient.generateText(modelPrompt);

            // 4. LLM 응답 파싱하여 응답 생성
            return parseResponse(modelResponse, data);

        } catch (Exception e) {
            log.error("AI 통계 v3 처리 실패: prompt={}", safeText(prompt, 100), e);
            // 실패 시에도 기본 데이터로 차트 그리기 시도
            return buildFallbackWithData(prompt, context);
        }
    }

    // ========== 프롬프트 빌드 ==========

    private String buildPrompt(String question, DataBundle data) {
        StringBuilder sb = new StringBuilder();
        sb.append("""
            당신은 한국폴리텍대학의 AI 통계 분석가입니다.
            
            [핵심 규칙]
            - 반드시 JSON만 응답하세요. 설명이나 마크다운 금지.
            - 절대 되묻지 마세요. 주어진 데이터로 최선의 분석을 하세요.
            - 숫자를 조작하거나 만들어내지 마세요. 주어진 데이터만 사용하세요.
            - 사용자에게 친근하고 인사이트 있는 분석을 제공하세요.
            
            [출력 JSON 형식]
            {
               "summary": "분석 결과 요약 (2-3문장)",
               "insight": "핵심 인사이트 (1문장)",
               "chartType": "line 또는 bar",
               "chartTitle": "차트 제목",
               "labels": ["라벨1", "라벨2", ...],
               "datasets": [
                   {"label": "데이터셋명", "values": [숫자1, 숫자2, ...]}
               ],
               "tableHeaders": ["헤더1", "헤더2"],
               "tableRows": [["값1", "값2"], ...]
            }
            
            """);

        // 데이터 추가
        sb.append("[현재 보유 데이터]\n");
        
        boolean hasData = false;
        
        if (data.employmentTop != null && !data.employmentTop.isEmpty()) {
            sb.append("- 취업률 Top 10:\n");
            for (var r : data.employmentTop) {
                sb.append("  - ").append(r.dept()).append(": ").append(r.rate()).append("%\n");
            }
            hasData = true;
        }

        if (data.employmentSeries != null && !data.employmentSeries.isEmpty()) {
            sb.append("- 연도별 평균 취업률:\n");
            for (var entry : data.employmentSeries.entrySet()) {
                sb.append("  - ").append(entry.getKey()).append("년: ").append(entry.getValue()).append("%\n");
            }
            hasData = true;
        }

        if (data.admissionTop != null && !data.admissionTop.isEmpty()) {
            sb.append("- 입학충원률 Top 10:\n");
            for (var r : data.admissionTop) {
                sb.append("  - ").append(r.dept()).append(": ").append(r.rate()).append("%\n");
            }
            hasData = true;
        }

        if (data.industryData != null && !data.industryData.isEmpty()) {
            sb.append("- 서울 ICT 종사자 수:\n");
            for (var entry : data.industryData.entrySet()) {
                sb.append("  - ").append(entry.getKey()).append("년: ").append(String.format("%,d", entry.getValue())).append("명\n");
            }
            hasData = true;
        }
        
        if (!hasData) {
            sb.append("(관련된 데이터가 없습니다. 일반적인 답변을 해주세요.)\n");
        }

        sb.append("\n[사용자 질문]\n").append(question).append("\n");

        return sb.toString();
    }

    // ========== 데이터 플래닝 (LLM) ==========

    private List<PlanItem> planData(String prompt, Map<String, Object> context) {
        // 1. 프롬프트 구성: 가용 데이터 소스 설명
        String planningPrompt = """
                당신은 통계 데이터 검색 플래너입니다.
                사용자의 질문을 분석하여, 답변에 필요한 데이터 소스를 결정해서 JSON 배열로 반환하세요.
                
                [가용 데이터 소스]
                1. "EMPLOYMENT_TOP": 학과별 취업률 상위 10개 (파라미터: campus)
                   - 질문 예: "취업 잘 되는 과", "취업률 순위", "인기 학과"
                2. "EMPLOYMENT_TREND": 학과/학교 전체 취업률 연도별 추이 4년치 (파라미터: campus)
                   - 질문 예: "취업률 변화", "취업률 추세", "작년이랑 비교"
                3. "ADMISSION_TOP": 학과별 입학충원률 상위 10개 (파라미터: campus)
                   - 질문 예: "충원 잘 되는 곳", "인기 있는 과", "경쟁률"
                4. "INDUSTRY_ICT": 서울지역 ICT 산업 종사자/사업체 수 추이 (파라미터: 없음)
                   - 질문 예: "IT 산업 전망", "개발자 수요", "ICT 기업"
                   
                [규칙]
                - 질문이 모호하면, 가장 연관성 높은 데이터를 추측해서 포함하세요. (예: "우리 학교 어때?" -> 취업률, 충원률 모두 포함)
                - 결과는 반드시 JSON 배열만 출력하세요. 마크다운이나 설명 금지.
                
                [출력 형식 예시]
                [{"type":"EMPLOYMENT_TOP","campus":"서울정수"},{"type":"INDUSTRY_ICT"}]
                
                [사용자 질문]
                """ + prompt;

        try {
            String response = geminiClient.generateText(planningPrompt);
            return parsePlan(response, context);
        } catch (Exception e) {
            log.warn("데이터 플래닝 실패, 기본값 사용: {}", e.getMessage());
            // 실패 시 기본 데이터셋 반환
            return List.of(
                    new PlanItem("EMPLOYMENT_TOP", "서울정수"),
                    new PlanItem("EMPLOYMENT_TREND", "서울정수")
            );
        }
    }

    private List<PlanItem> parsePlan(String response, Map<String, Object> context) {
        List<PlanItem> plans = new ArrayList<>();
        try {
            String json = extractJson(response);
            JsonNode root = objectMapper.readTree(json);
            if (root.isArray()) {
                for (JsonNode node : root) {
                    String type = node.path("type").asText();
                    String campus = node.path("campus").asText(contextString(context, "campus"));
                    // 컨텍스트에도 없고 LLM도 안 줬으면 기본값
                    if (!StringUtils.hasText(campus)) {
                        campus = "서울정수";
                    }
                    plans.add(new PlanItem(type, campus));
                }
            }
        } catch (Exception e) {
            log.warn("플랜 파싱 오류: {}", e.getMessage());
        }
        
        // 파싱 실패 또는 빈 결과면 기본값
        if (plans.isEmpty()) {
            plans.add(new PlanItem("EMPLOYMENT_TOP", "서울정수"));
            plans.add(new PlanItem("EMPLOYMENT_TREND", "서울정수"));
        }
        return plans;
    }

    // ========== 데이터 조회 (Generic) ==========

    private DataBundle fetchDataBasedOnPlan(List<PlanItem> plans) {
        DataBundle data = new DataBundle();
        int currentYear = Year.now().getValue();
        List<Integer> defaultYears = List.of(currentYear - 4, currentYear - 3, currentYear - 2, currentYear - 1);

        for (PlanItem item : plans) {
            try {
                switch (item.type) {
                    case "EMPLOYMENT_TOP" -> {
                        if (data.employmentTop == null) {
                            data.employmentTop = internalStatisticsService.getTopEmploymentRates(item.campus, 10);
                        }
                    }
                    case "EMPLOYMENT_TREND" -> {
                        if (data.employmentSeries == null) {
                            data.employmentSeries = loadInternalEmploymentSeries(item.campus, defaultYears);
                        }
                    }
                    case "ADMISSION_TOP" -> {
                        if (data.admissionTop == null) {
                            data.admissionTop = internalStatisticsService.getTopAdmissionFillRates(item.campus, 10);
                        }
                    }
                    case "INDUSTRY_ICT" -> {
                        if (data.industryData == null) {
                            data.industryData = loadIndustryData("11", defaultYears); // 서울(11) 고정
                        }
                    }
                }
            } catch (Exception e) {
                log.debug("데이터 로딩 실패 ({}): {}", item.type, e.getMessage());
            }
        }
        return data;
    }

    private Map<Integer, Double> loadInternalEmploymentSeries(String campus, List<Integer> years) {
        Map<Integer, Double> result = new LinkedHashMap<>();
        for (Integer year : years) {
            try {
                List<InternalStatisticsService.EmploymentStat> stats = 
                        internalStatisticsService.getEmploymentStatsForYear(year);
                if (stats != null && !stats.isEmpty()) {
                    var filtered = stats.stream();
                    if (StringUtils.hasText(campus)) {
                        filtered = filtered.filter(s -> campus.equals(s.campus()));
                    }
                    double avg = filtered.mapToDouble(s -> s.employmentRate()).average().orElse(0);
                    if (avg > 0) {
                        result.put(year, Math.round(avg * 100.0) / 100.0);
                    }
                }
            } catch (Exception e) {
                log.debug("{}년 취업률 조회 실패: {}", year, e.getMessage());
            }
        }
        return result;
    }

    private Map<Integer, Long> loadIndustryData(String admCd, List<Integer> years) {
        Map<Integer, Long> result = new LinkedHashMap<>();
        List<String> ictCodes = majorIndustryMappingService.getSgisClassCodesByCategory().getOrDefault("ICT", List.of());
        
        for (Integer year : years) {
            long sum = 0L;
            for (String code : ictCodes) {
                try {
                    var stats = sgisCompanyCacheService.getCompanyStats(String.valueOf(year), admCd, code);
                    if (stats != null && stats.totWorker() != null) {
                        sum += stats.totWorker();
                    }
                } catch (Exception e) {
                    log.debug("SGIS 조회 실패: year={}, code={}", year, code);
                }
            }
            if (sum > 0) {
                result.put(year, sum);
            }
        }
        return result;
    }

    // ========== 프롬프트 빌드 ==========

    private String buildPrompt(String question, DataBundle data, QueryIntent intent) {
        StringBuilder sb = new StringBuilder();
        sb.append("""
            당신은 한국폴리텍대학의 AI 통계 분석가입니다.
            
            [핵심 규칙]
            - 반드시 JSON만 응답하세요. 설명이나 마크다운 금지.
            - 절대 되묻지 마세요. 주어진 데이터로 최선의 분석을 하세요.
            - 숫자를 조작하거나 만들어내지 마세요. 주어진 데이터만 사용하세요.
            - 사용자에게 친근하고 인사이트 있는 분석을 제공하세요.
            
            [출력 JSON 형식]
            {
               "summary": "분석 결과 요약 (2-3문장)",
               "insight": "핵심 인사이트 (1문장)",
               "chartType": "line 또는 bar",
               "chartTitle": "차트 제목",
               "labels": ["라벨1", "라벨2", ...],
               "datasets": [
                   {"label": "데이터셋명", "values": [숫자1, 숫자2, ...]}
               ],
               "tableHeaders": ["헤더1", "헤더2"],
               "tableRows": [["값1", "값2"], ...]
            }
            
            """);

        // 데이터 추가
        sb.append("[현재 보유 데이터]\n");
        
        if (data.employmentTop != null && !data.employmentTop.isEmpty()) {
            sb.append("- 취업률 Top 10:\n");
            for (var r : data.employmentTop) {
                sb.append("  - ").append(r.dept()).append(": ").append(r.rate()).append("%\n");
            }
        }

        if (data.employmentSeries != null && !data.employmentSeries.isEmpty()) {
            sb.append("- 연도별 평균 취업률:\n");
            for (var entry : data.employmentSeries.entrySet()) {
                sb.append("  - ").append(entry.getKey()).append("년: ").append(entry.getValue()).append("%\n");
            }
        }

        if (data.admissionTop != null && !data.admissionTop.isEmpty()) {
            sb.append("- 입학충원률 Top 10:\n");
            for (var r : data.admissionTop) {
                sb.append("  - ").append(r.dept()).append(": ").append(r.rate()).append("%\n");
            }
        }

        if (data.industryData != null && !data.industryData.isEmpty()) {
            sb.append("- 서울 ICT 종사자 수:\n");
            for (var entry : data.industryData.entrySet()) {
                sb.append("  - ").append(entry.getKey()).append("년: ").append(String.format("%,d", entry.getValue())).append("명\n");
            }
        }

        sb.append("\n[사용자 질문]\n").append(question).append("\n");

        return sb.toString();
    }

    // ========== 응답 파싱 ==========

    private StatisticsAiQueryResponse parseResponse(String modelResponse, DataBundle data) {
        try {
            String json = extractJson(modelResponse);
            JsonNode node = objectMapper.readTree(json);

            String summary = node.path("summary").asText("데이터를 분석했습니다.");
            String insight = node.path("insight").asText("");
            String chartType = node.path("chartType").asText("bar");
            String chartTitle = node.path("chartTitle").asText("분석 결과");

            List<String> labels = readStringArray(node.path("labels"));
            List<StatisticsAiQueryResponse.Dataset> datasets = new ArrayList<>();
            
            JsonNode datasetsNode = node.path("datasets");
            if (datasetsNode.isArray()) {
                for (JsonNode ds : datasetsNode) {
                    String label = ds.path("label").asText("값");
                    List<Double> values = readDoubleArray(ds.path("values"));
                    datasets.add(new StatisticsAiQueryResponse.Dataset(label, values, null));
                }
            }

            // 차트가 비어있으면 기본 데이터로 채움
            if (labels.isEmpty() || datasets.isEmpty()) {
                return buildChartFromData(data, summary, insight);
            }

            StatisticsAiQueryResponse.ChartSpec chart = new StatisticsAiQueryResponse.ChartSpec(
                    chartTitle, chartType,
                    new StatisticsAiQueryResponse.ChartData(labels, datasets)
            );

            // 테이블 파싱
            StatisticsAiQueryResponse.TableSpec table = null;
            JsonNode tableHeaders = node.path("tableHeaders");
            JsonNode tableRows = node.path("tableRows");
            if (tableHeaders.isArray() && tableRows.isArray()) {
                List<String> headers = readStringArray(tableHeaders);
                List<List<Object>> rows = new ArrayList<>();
                for (JsonNode row : tableRows) {
                    if (row.isArray()) {
                        List<Object> rowData = new ArrayList<>();
                        for (JsonNode cell : row) {
                            rowData.add(cell.isNumber() ? cell.numberValue() : cell.asText());
                        }
                        rows.add(rowData);
                    }
                }
                if (!headers.isEmpty() && !rows.isEmpty()) {
                    table = new StatisticsAiQueryResponse.TableSpec(headers, rows);
                }
            }

            String fullSummary = "📊 " + summary;
            if (StringUtils.hasText(insight)) {
                fullSummary += "\n\n💡 " + insight;
            }

            return new StatisticsAiQueryResponse(
                    false, null, null, null, null,
                    List.of(chart), table, fullSummary,
                    List.of(new StatisticsAiQueryResponse.SourceSpec("AI 분석", "v3")),
                    List.of(), null
            );

        } catch (Exception e) {
            log.warn("LLM 응답 파싱 실패, 기본 차트로 대체: {}", e.getMessage());
            return buildChartFromData(data, "데이터를 분석했습니다.", null);
        }
    }

    // ========== 폴백 및 기본 응답 ==========

    private StatisticsAiQueryResponse buildChartFromData(DataBundle data, String summary, String insight) {
        List<StatisticsAiQueryResponse.ChartSpec> charts = new ArrayList<>();
        StatisticsAiQueryResponse.TableSpec table = null;

        // 취업률 Top 차트
        if (data.employmentTop != null && !data.employmentTop.isEmpty()) {
            List<String> labels = data.employmentTop.stream().map(r -> r.dept()).toList();
            List<Double> values = data.employmentTop.stream().map(r -> r.rate()).toList();
            
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "취업률 Top 10", "bar",
                    new StatisticsAiQueryResponse.ChartData(labels, 
                            List.of(new StatisticsAiQueryResponse.Dataset("취업률(%)", values, null)))
            ));

            List<List<Object>> rows = new ArrayList<>();
            for (var r : data.employmentTop) {
                rows.add(List.of(r.dept(), r.rate()));
            }
            table = new StatisticsAiQueryResponse.TableSpec(List.of("학과", "취업률(%)"), rows);
        }

        // 취업률 시계열 차트
        if (data.employmentSeries != null && !data.employmentSeries.isEmpty()) {
            List<String> labels = data.employmentSeries.keySet().stream().map(String::valueOf).toList();
            List<Double> values = new ArrayList<>(data.employmentSeries.values());
            
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "연도별 평균 취업률 추이", "line",
                    new StatisticsAiQueryResponse.ChartData(labels,
                            List.of(new StatisticsAiQueryResponse.Dataset("평균 취업률(%)", values, null)))
            ));
        }

        // 입학충원률 차트
        if (data.admissionTop != null && !data.admissionTop.isEmpty()) {
            List<String> labels = data.admissionTop.stream().map(r -> r.dept()).toList();
            List<Double> values = data.admissionTop.stream().map(r -> r.rate()).toList();
            
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "입학충원률 Top 10", "bar",
                    new StatisticsAiQueryResponse.ChartData(labels,
                            List.of(new StatisticsAiQueryResponse.Dataset("충원률(%)", values, null)))
            ));
        }

        // 산업 데이터 차트
        if (data.industryData != null && !data.industryData.isEmpty()) {
            List<String> labels = data.industryData.keySet().stream().map(String::valueOf).toList();
            List<Double> values = data.industryData.values().stream().map(Long::doubleValue).toList();
            
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "서울 ICT 종사자 수 추이", "line",
                    new StatisticsAiQueryResponse.ChartData(labels,
                            List.of(new StatisticsAiQueryResponse.Dataset("종사자 수(명)", values, null)))
            ));
        }

        if (charts.isEmpty()) {
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "데이터 없음", "bar",
                    new StatisticsAiQueryResponse.ChartData(List.of(), List.of())
            ));
        }

        String fullSummary = "📊 " + (summary != null ? summary : "통계 데이터를 분석했습니다.");
        if (StringUtils.hasText(insight)) {
            fullSummary += "\n\n💡 " + insight;
        }

        return new StatisticsAiQueryResponse(
                false, null, null, null, null,
                charts, table, fullSummary,
                List.of(new StatisticsAiQueryResponse.SourceSpec("내부 통계", "v3")),
                List.of(), null
        );
    }

    private StatisticsAiQueryResponse buildFallbackResponse(String message) {
        return new StatisticsAiQueryResponse(
                false, null, null, message,
                List.of("취업률 보여줘", "입학충원률 Top 10", "산업 현황 분석해줘"),
                List.of(), null, null, List.of(), List.of(), null
        );
    }

    private StatisticsAiQueryResponse buildFallbackWithData(String prompt, Map<String, Object> context) {
        // 폴백 시에도 플래닝 시도 (실패 시 기본값 사용됨)
        List<PlanItem> plan = planData(prompt, context);
        DataBundle data = fetchDataBasedOnPlan(plan);
        
        // 왜: 폴백 시에도 데이터 기반으로 구체적인 요약을 생성합니다.
        String summary = buildAutoSummary(data);
        String insight = buildAutoInsight(data);
        
        return buildChartFromData(data, summary, insight);
    }
    
    private String buildAutoSummary(DataBundle data) {
        StringBuilder sb = new StringBuilder();
        
        if (data.employmentTop != null && !data.employmentTop.isEmpty()) {
            var top = data.employmentTop.get(0);
            sb.append("서울정수 캠퍼스의 취업률 상위 학과를 분석했습니다. ");
            sb.append(String.format("1위는 %s(%.1f%%)입니다.", top.dept(), top.rate()));
        } else if (data.admissionTop != null && !data.admissionTop.isEmpty()) {
            var top = data.admissionTop.get(0);
            sb.append("입학충원률 상위 학과를 분석했습니다. ");
            sb.append(String.format("1위는 %s(%.1f%%)입니다.", top.dept(), top.rate()));
        } else if (data.industryData != null && !data.industryData.isEmpty()) {
            sb.append("서울 지역 ICT 산업 종사자 현황을 분석했습니다.");
        } else {
            sb.append("요청하신 통계 데이터를 분석했습니다.");
        }
        
        return sb.toString();
    }
    
    private String buildAutoInsight(DataBundle data) {
        if (data.employmentTop != null && data.employmentTop.size() >= 3) {
            long count100 = data.employmentTop.stream().filter(r -> r.rate() >= 100.0).count();
            if (count100 > 0) {
                return String.format("취업률 100%%를 달성한 학과가 %d개입니다!", count100);
            }
            double avgRate = data.employmentTop.stream().mapToDouble(r -> r.rate()).average().orElse(0);
            return String.format("상위 10개 학과 평균 취업률은 %.1f%%입니다.", avgRate);
        }
        
        if (data.industryData != null && data.industryData.size() >= 2) {
            var entries = new ArrayList<>(data.industryData.entrySet());
            if (entries.size() >= 2) {
                long first = entries.get(0).getValue();
                long last = entries.get(entries.size() - 1).getValue();
                double change = ((double)(last - first) / first) * 100;
                if (change > 0) {
                    return String.format("ICT 종사자 수가 %.1f%% 증가하는 추세입니다.", change);
                } else if (change < 0) {
                    return String.format("ICT 종사자 수가 %.1f%% 감소했습니다.", Math.abs(change));
                }
            }
        }
        
        return null;
    }

    // ========== 유틸리티 ==========

    private boolean containsAny(String text, String... keywords) {
        for (String k : keywords) {
            if (text.contains(k)) return true;
        }
        return false;
    }

    private String contextString(Map<String, Object> context, String key) {
        if (context == null) return null;
        Object v = context.get(key);
        return v != null ? String.valueOf(v).trim() : null;
    }

    private String extractJson(String text) {
        if (text == null) return "{}";
        String cleaned = text.replaceAll("```json", "").replaceAll("```", "").trim();
        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return cleaned.substring(start, end + 1);
        }
        return "{}";
    }

    private List<String> readStringArray(JsonNode node) {
        List<String> result = new ArrayList<>();
        if (node != null && node.isArray()) {
            for (JsonNode n : node) {
                result.add(n.asText());
            }
        }
        return result;
    }

    private List<Double> readDoubleArray(JsonNode node) {
        List<Double> result = new ArrayList<>();
        if (node != null && node.isArray()) {
            for (JsonNode n : node) {
                if (n.isNumber()) {
                    result.add(n.doubleValue());
                } else {
                    try {
                        result.add(Double.parseDouble(n.asText()));
                    } catch (NumberFormatException e) {
                        result.add(0.0);
                    }
                }
            }
        }
        return result;
    }

    private String safeText(String text, int max) {
        if (text == null) return null;
        return text.length() <= max ? text : text.substring(0, max) + "...";
    }

    // ========== 내부 클래스 ==========

    private record PlanItem(String type, String campus) {}

    private static class DataBundle {
        List<InternalStatisticsService.DepartmentRate> employmentTop;
        List<InternalStatisticsService.DepartmentRate> admissionTop;
        Map<Integer, Double> employmentSeries;
        Map<Integer, Long> industryData;
    }
}
