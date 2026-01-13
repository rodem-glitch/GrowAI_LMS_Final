package kr.polytech.lms.statistics.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.statistics.dashboard.service.IndustryAnalysisService;
import kr.polytech.lms.statistics.dashboard.service.PopulationComparisonService;
import kr.polytech.lms.statistics.dashboard.service.StatisticsMetaService;
import kr.polytech.lms.statistics.internalstats.InternalStatisticsService;
import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Year;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class StatisticsAiService {
    // 왜: "자유질문"을 실무에서 안전하게 쓰려면,
    //  1) LLM은 질문을 실행계획(JSON)으로 '번역'만 하고,
    //  2) 실제 수치/그래프 데이터는 서버가 기존 데이터(통계청 API/내부 엑셀)로만 계산하며,
    //  3) 서버가 실행계획을 검증해 권한/호환성/누락을 통제
    // 해야 합니다. (LLM 환각/임의 숫자 생성 방지)

    private static final List<StatisticsAiCatalogResponse.AdmRegion> ADM_REGIONS = List.of(
            new StatisticsAiCatalogResponse.AdmRegion("11", "서울특별시"),
            new StatisticsAiCatalogResponse.AdmRegion("26", "부산광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("27", "대구광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("28", "인천광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("29", "광주광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("30", "대전광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("31", "울산광역시"),
            new StatisticsAiCatalogResponse.AdmRegion("36", "세종특별자치시"),
            new StatisticsAiCatalogResponse.AdmRegion("41", "경기도"),
            new StatisticsAiCatalogResponse.AdmRegion("42", "강원특별자치도"),
            new StatisticsAiCatalogResponse.AdmRegion("43", "충청북도"),
            new StatisticsAiCatalogResponse.AdmRegion("44", "충청남도"),
            new StatisticsAiCatalogResponse.AdmRegion("45", "전라북도"),
            new StatisticsAiCatalogResponse.AdmRegion("46", "전라남도"),
            new StatisticsAiCatalogResponse.AdmRegion("47", "경상북도"),
            new StatisticsAiCatalogResponse.AdmRegion("48", "경상남도"),
            new StatisticsAiCatalogResponse.AdmRegion("50", "제주특별자치도")
    );

    private final StatisticsAiProperties properties;
    private final GeminiClient geminiClient;
    private final ObjectMapper objectMapper;
    private final StatisticsMetaService statisticsMetaService;
    private final InternalStatisticsService internalStatisticsService;
    private final PopulationComparisonService populationComparisonService;
    private final IndustryAnalysisService industryAnalysisService;

    public StatisticsAiService(
            StatisticsAiProperties properties,
            GeminiClient geminiClient,
            ObjectMapper objectMapper,
            StatisticsMetaService statisticsMetaService,
            InternalStatisticsService internalStatisticsService,
            PopulationComparisonService populationComparisonService,
            IndustryAnalysisService industryAnalysisService
    ) {
        this.properties = properties;
        this.geminiClient = geminiClient;
        this.objectMapper = objectMapper;
        this.statisticsMetaService = statisticsMetaService;
        this.internalStatisticsService = internalStatisticsService;
        this.populationComparisonService = populationComparisonService;
        this.industryAnalysisService = industryAnalysisService;
    }

    public StatisticsAiCatalogResponse getCatalog() {
        int now = Year.now().getValue();
        List<Integer> years = new ArrayList<>();
        for (int y = now - 1; y >= now - 8; y--) {
            years.add(y);
        }

        return new StatisticsAiCatalogResponse(
                "v1",
                List.of(
                        new StatisticsAiCatalogResponse.QueryTypeSpec(
                                AiQueryType.INTERNAL_EMPLOYMENT_TOP.name(),
                                "내부 취업률 Top N",
                                List.of("campus"),
                                List.of("top")
                        ),
                        new StatisticsAiCatalogResponse.QueryTypeSpec(
                                AiQueryType.INTERNAL_ADMISSION_TOP.name(),
                                "내부 입학충원률 Top N",
                                List.of("campus"),
                                List.of("top")
                        ),
                        new StatisticsAiCatalogResponse.QueryTypeSpec(
                                AiQueryType.POPULATION_COMPARE.name(),
                                "인구(지역) vs 캠퍼스 학생 분포 비교",
                                List.of("campus"),
                                List.of("admCd", "populationYear")
                        ),
                        new StatisticsAiCatalogResponse.QueryTypeSpec(
                                AiQueryType.INDUSTRY_ANALYSIS.name(),
                                "산업분포(지역) vs 캠퍼스 전공 분포 비교",
                                List.of(),
                                List.of("campus", "admCd", "statsYear")
                        )
                ),
                List.of("bar", "line", "stacked_bar"),
                statisticsMetaService.getCampusGroups(),
                ADM_REGIONS,
                years
        );
    }

    public StatisticsAiQueryResponse query(StatisticsAiQueryRequest request) throws Exception {
        if (request == null || !StringUtils.hasText(request.prompt())) {
            throw new IllegalArgumentException("prompt는 필수입니다.");
        }

        StatisticsAiCatalogResponse catalog = getCatalog();
        List<String> knownCampuses = flattenCampuses(catalog.campusGroups());

        String modelPrompt = buildModelPrompt(request.prompt(), request.context(), catalog);
        String modelText = geminiClient.generateText(modelPrompt);

        AiDecision decision = parseModelDecision(modelText);

        if (decision.action() == AiDecision.Action.CLARIFY) {
            return new StatisticsAiQueryResponse(
                    true,
                    decision.question(),
                    buildClarifyOptions(decision, catalog),
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    debug(decision)
            );
        }

        if (decision.action() == AiDecision.Action.UNSUPPORTED) {
            return new StatisticsAiQueryResponse(
                    false,
                    null,
                    null,
                    decision.message() == null ? "지원하지 않는 질문입니다." : decision.message(),
                    decision.examples(),
                    null,
                    null,
                    null,
                    null,
                    null,
                    debug(decision)
            );
        }

        // EXECUTE
        AiQueryType queryType = decision.queryType();
        Map<String, Object> params = decision.params() == null ? Map.of() : decision.params();

        return switch (queryType) {
            case INTERNAL_EMPLOYMENT_TOP -> executeInternalTop(
                    "취업률(%)",
                    AiQueryType.INTERNAL_EMPLOYMENT_TOP,
                    ensureKnownCampus(resolveCampus(params, request.context()), knownCampuses, decision),
                    resolveTop(params, 10),
                    true,
                    decision
            );
            case INTERNAL_ADMISSION_TOP -> executeInternalTop(
                    "입학충원률(%)",
                    AiQueryType.INTERNAL_ADMISSION_TOP,
                    ensureKnownCampus(resolveCampus(params, request.context()), knownCampuses, decision),
                    resolveTop(params, 10),
                    false,
                    decision
            );
            case POPULATION_COMPARE -> executePopulationCompare(params, request.context(), knownCampuses, decision);
            case INDUSTRY_ANALYSIS -> executeIndustryAnalysis(params, request.context(), knownCampuses, decision);
        };
    }

    private StatisticsAiQueryResponse executeInternalTop(
            String label,
            AiQueryType type,
            String campus,
            int top,
            boolean employment,
            AiDecision decision
    ) {
        if (!StringUtils.hasText(campus)) {
            return clarification("캠퍼스를 선택해 주세요.", List.of("campus"), decision);
        }

        List<InternalStatisticsService.DepartmentRate> rows = employment
                ? internalStatisticsService.getTopEmploymentRates(campus, top)
                : internalStatisticsService.getTopAdmissionFillRates(campus, top);

        List<String> labels = rows.stream().map(InternalStatisticsService.DepartmentRate::dept).toList();
        List<Double> values = rows.stream().map(r -> r.rate()).map(Double::valueOf).toList();

        StatisticsAiQueryResponse.ChartSpec chart = new StatisticsAiQueryResponse.ChartSpec(
                campus + " " + label + " Top " + top,
                "bar",
                new StatisticsAiQueryResponse.ChartData(
                        labels,
                        List.of(new StatisticsAiQueryResponse.Dataset(label, values, null))
                )
        );

        List<List<Object>> tableRows = new ArrayList<>();
        for (InternalStatisticsService.DepartmentRate r : rows) {
            tableRows.add(List.of(r.dept(), round2(r.rate())));
        }

        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                null,
                null,
                List.of(chart),
                new StatisticsAiQueryResponse.TableSpec(List.of("학과", label), tableRows),
                "캠퍼스=" + campus + " / 기준=내부 엑셀 집계 / Top=" + top,
                List.of(new StatisticsAiQueryResponse.SourceSpec("내부 통계 엑셀", "statistics.data.*-file 기반 집계")),
                List.of(),
                debug(decision)
        );
    }

    private StatisticsAiQueryResponse executePopulationCompare(Map<String, Object> params, Map<String, Object> context, List<String> knownCampuses, AiDecision decision) throws Exception {
        String campus = ensureKnownCampus(resolveCampus(params, context), knownCampuses, decision);
        if (!StringUtils.hasText(campus)) {
            return clarification("캠퍼스를 선택해 주세요.", List.of("campus"), decision);
        }

        String admCd = resolveAdmCd(params, context);
        Integer year = resolveInteger(params, "populationYear", context, "populationYear");

        PopulationComparisonService.PopulationComparisonResponse r =
                populationComparisonService.compare(campus, admCd, year);

        List<String> labels = r.rows().stream().map(PopulationComparisonService.AgeRow::ageBand).toList();
        List<Double> regionRatios = r.rows().stream().map(row -> round2(row.regionRatio())).toList();
        List<Double> campusRatios = r.rows().stream().map(row -> round2(row.campusRatio())).toList();
        List<Double> gaps = r.rows().stream().map(row -> round2(row.gap())).toList();

        List<StatisticsAiQueryResponse.ChartSpec> charts = List.of(
                new StatisticsAiQueryResponse.ChartSpec(
                        "연령대별 인구비율 vs 캠퍼스 학생비율",
                        "bar",
                        new StatisticsAiQueryResponse.ChartData(
                                labels,
                                List.of(
                                        new StatisticsAiQueryResponse.Dataset("행정구역 인구비율", regionRatios, null),
                                        new StatisticsAiQueryResponse.Dataset("캠퍼스 학생비율", campusRatios, null)
                                )
                        )
                ),
                new StatisticsAiQueryResponse.ChartSpec(
                        "연령대별 GAP(캠퍼스-행정, %p)",
                        "bar",
                        new StatisticsAiQueryResponse.ChartData(
                                labels,
                                List.of(new StatisticsAiQueryResponse.Dataset("GAP(%p)", gaps, null))
                        )
                )
        );

        List<List<Object>> tableRows = new ArrayList<>();
        for (PopulationComparisonService.AgeRow row : r.rows()) {
            tableRows.add(List.of(
                    row.ageBand(),
                    row.regionCount(),
                    round2(row.regionRatio()),
                    row.campusCount(),
                    round2(row.campusRatio()),
                    round2(row.gap())
            ));
        }

        List<StatisticsAiQueryResponse.WarningSpec> warnings = new ArrayList<>();
        if (r.campusStudentSampleSize() <= 0) {
            warnings.add(new StatisticsAiQueryResponse.WarningSpec(
                    "CAMPUS_SAMPLE_EMPTY",
                    "캠퍼스 학생 연령/성별 데이터(엑셀)가 없어서 캠퍼스 비율이 0으로 표시될 수 있습니다."
            ));
        }

        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                null,
                null,
                charts,
                new StatisticsAiQueryResponse.TableSpec(
                        List.of("연령대", "행정구역 인구(명)", "행정구역 비율(%)", "캠퍼스 학생(명)", "캠퍼스 비율(%)", "GAP(%p)"),
                        tableRows
                ),
                "캠퍼스=" + r.campus() + " / 행정구역=" + r.admCd() + " / 인구연도=" + r.populationYear()
                        + " / 캠퍼스표본=" + r.campusStudentSampleSize() + "명",
                List.of(
                        new StatisticsAiQueryResponse.SourceSpec("통계청/SGIS 인구 통계", "KOSIS/SGIS OpenAPI 기반"),
                        new StatisticsAiQueryResponse.SourceSpec("캠퍼스 학생 분포", "statistics.data.student-population-file(옵션) 기반")
                ),
                warnings,
                debug(decision)
        );
    }

    private StatisticsAiQueryResponse executeIndustryAnalysis(Map<String, Object> params, Map<String, Object> context, List<String> knownCampuses, AiDecision decision) throws Exception {
        String campus = resolveCampus(params, context);
        if (StringUtils.hasText(campus)) {
            if ("전체".equals(campus) || "전체 캠퍼스".equals(campus)) {
                campus = null;
            } else if (!knownCampuses.contains(campus)) {
                // 왜: 산업 탭은 campus가 선택값이지만, "전체"도 허용합니다. 알 수 없는 값이면 되물음으로 보정합니다.
                return clarification("캠퍼스 이름을 확인해 주세요. (예: 서울정수, 전체)", List.of("campus"), decision);
            }
        }
        String admCd = resolveAdmCd(params, context);
        Integer year = resolveInteger(params, "statsYear", context, "statsYear");

        IndustryAnalysisService.IndustryAnalysisResponse r = industryAnalysisService.analyze(campus, admCd, year);

        List<String> labels = r.rows().stream().map(IndustryAnalysisService.CategoryRow::category).toList();
        List<Double> regionRatios = r.rows().stream().map(row -> round2(row.regionRatio())).toList();
        List<Double> campusRatios = r.rows().stream().map(row -> round2(row.campusRatio())).toList();
        List<Double> gaps = r.rows().stream().map(row -> round2(row.gap())).toList();

        List<StatisticsAiQueryResponse.ChartSpec> charts = List.of(
                new StatisticsAiQueryResponse.ChartSpec(
                        "산업분포: 행정구역 vs 캠퍼스",
                        "bar",
                        new StatisticsAiQueryResponse.ChartData(
                                labels,
                                List.of(
                                        new StatisticsAiQueryResponse.Dataset("행정구역 종사자 비율", regionRatios, null),
                                        new StatisticsAiQueryResponse.Dataset("캠퍼스 학생 비율", campusRatios, null)
                                )
                        )
                ),
                new StatisticsAiQueryResponse.ChartSpec(
                        "산업분포 GAP(캠퍼스-행정, %p)",
                        "bar",
                        new StatisticsAiQueryResponse.ChartData(
                                labels,
                                List.of(new StatisticsAiQueryResponse.Dataset("GAP(%p)", gaps, null))
                        )
                )
        );

        List<List<Object>> tableRows = new ArrayList<>();
        for (IndustryAnalysisService.CategoryRow row : r.rows()) {
            tableRows.add(List.of(
                    row.category(),
                    row.regionCount(),
                    round2(row.regionRatio()),
                    row.campusCount(),
                    round2(row.campusRatio()),
                    round2(row.gap())
            ));
        }

        List<StatisticsAiQueryResponse.WarningSpec> warnings = new ArrayList<>();
        if (r.campusStudentTotal() <= 0) {
            warnings.add(new StatisticsAiQueryResponse.WarningSpec(
                    "CAMPUS_TOTAL_EMPTY",
                    "캠퍼스 학생/정원 기반 데이터가 0으로 계산되어 캠퍼스 비율이 0일 수 있습니다. (입시율관리.xlsx 또는 매핑 파일 확인)"
            ));
        }

        String campusLabel = r.campus() == null ? "전체" : r.campus();
        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                null,
                null,
                charts,
                new StatisticsAiQueryResponse.TableSpec(
                        List.of("분야", "행정구역 종사자(명)", "행정구역 비율(%)", "캠퍼스 학생/정원(명)", "캠퍼스 비율(%)", "GAP(%p)"),
                        tableRows
                ),
                "캠퍼스=" + campusLabel + " / 행정구역=" + r.admCd() + " / 산업연도=" + r.statsYear(),
                List.of(
                        new StatisticsAiQueryResponse.SourceSpec("통계청/SGIS 사업체 통계", "tot_worker 기반"),
                        new StatisticsAiQueryResponse.SourceSpec("캠퍼스 학생(대체지표)", "입시율관리.xlsx의 정원 합계 사용"),
                        new StatisticsAiQueryResponse.SourceSpec("전공-산업 매핑", "statistics.mapping.major-industry-file 기반")
                ),
                warnings,
                debug(decision)
        );
    }

    private StatisticsAiQueryResponse clarification(String question, List<String> fields, AiDecision decision) {
        // 왜: 되물음은 "선택지"가 있어야 사용자가 다시 입력하지 않고도 바로 해결할 수 있습니다.
        //     UI 구현이 단순해지도록, catalog와 동일한 선택지(캠퍼스/행정구역/추천연도)를 같이 내려줍니다.
        int now = Year.now().getValue();
        List<Integer> years = new ArrayList<>();
        for (int y = now - 1; y >= now - 8; y--) {
            years.add(y);
        }

        Map<String, Object> options = new LinkedHashMap<>();
        options.put("fields", fields == null ? List.of() : fields);
        options.put("campusGroups", statisticsMetaService.getCampusGroups());
        options.put("admRegions", ADM_REGIONS);
        options.put("recommendedYears", years);

        return new StatisticsAiQueryResponse(
                true,
                question,
                options,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                debug(decision)
        );
    }

    private Map<String, Object> buildClarifyOptions(AiDecision decision, StatisticsAiCatalogResponse catalog) {
        // 왜: 되물음 시에는 사용자가 바로 선택할 수 있도록 "가능한 값 목록"을 같이 내려주는 편이 좋습니다.
        Map<String, Object> options = new LinkedHashMap<>();
        options.put("fields", decision.fields() == null ? List.of() : decision.fields());
        options.put("campusGroups", catalog.campusGroups());
        options.put("admRegions", catalog.admRegions());
        options.put("recommendedYears", catalog.recommendedYears());
        return options;
    }

    private Map<String, Object> debug(AiDecision decision) {
        if (!properties.isDebug()) {
            return null;
        }

        Map<String, Object> debug = new LinkedHashMap<>();
        debug.put("modelDecision", decision.rawJson());
        return debug;
    }

    private String buildModelPrompt(String userPrompt, Map<String, Object> context, StatisticsAiCatalogResponse catalog) {
        // 왜: LLM 출력이 흔들리면(자유 텍스트/추정치 등) 실무에서 바로 사고가 나므로,
        //     "JSON만 출력" + "가능한 범위(카탈로그)" + "애매하면 되물음" 규칙을 강하게 주입합니다.

        String campusList = buildCampusListForPrompt(catalog.campusGroups());
        String admList = buildAdmListForPrompt(catalog.admRegions());
        String contextText = (context == null || context.isEmpty()) ? "" : ("컨텍스트(JSON): " + toCompactJson(context));

        return """
                당신은 'AI 통계 실행계획 생성기'입니다.

                [중요 규칙]
                - 반드시 JSON 객체만 출력하세요. (설명, 코드블록, 마크다운 금지)
                - 숫자(통계 값)를 추측/생성하지 마세요. 당신은 '실행계획'만 만듭니다.
                - SQL을 만들거나 DB를 직접 조회하는 계획을 만들지 마세요.
                - 아래 '지원 쿼리 타입'과 '허용 파라미터'만 사용하세요.
                - 필수 값이 없거나 애매하면 action=CLARIFY 로 되물어야 합니다.

                [지원 쿼리 타입]
                - INTERNAL_EMPLOYMENT_TOP: 내부 취업률 Top N (필수: campus, 선택: top)
                - INTERNAL_ADMISSION_TOP: 내부 입학충원률 Top N (필수: campus, 선택: top)
                - POPULATION_COMPARE: 인구(행정구역) vs 캠퍼스 학생 분포 비교 (필수: campus, 선택: admCd, populationYear)
                - INDUSTRY_ANALYSIS: 산업분포 비교 (선택: campus(없으면 전체), admCd, statsYear)

                [허용 파라미터 가이드]
                - campus: 캠퍼스명 (예: "서울정수"). "캠퍼스" 접미사는 있어도 되고 없어도 됩니다.
                - admCd: 행정구역 코드 (예: "11"=서울특별시)
                - populationYear, statsYear: 연도 (정수). 없으면 기본값은 '전년도'로 처리됩니다.
                - top: 1~30 정수

                [캠퍼스 후보(참고)]
                %s

                [행정구역 후보(참고)]
                %s

                [출력 JSON 형식]
                - 실행:
                  {"action":"EXECUTE","queryType":"POPULATION_COMPARE","params":{"campus":"서울정수","admCd":"11","populationYear":2023}}
                - 되물음:
                  {"action":"CLARIFY","question":"캠퍼스를 어떤 기준으로 볼까요?","fields":["campus"]}
                - 불가:
                  {"action":"UNSUPPORTED","message":"현재는 인구/산업/내부통계 범위만 지원합니다.","examples":["서울정수 취업률 top10 보여줘","서울(11) 2023년 연령대별 인구비율 보여줘"]}

                %s

                [사용자 질문]
                %s
                """.formatted(campusList, admList, contextText, userPrompt);
    }

    private String buildCampusListForPrompt(List<MajorIndustryMappingService.CampusGroup> groups) {
        if (groups == null || groups.isEmpty()) {
            return "- (캠퍼스 목록 없음)";
        }

        List<String> campuses = new ArrayList<>();
        for (MajorIndustryMappingService.CampusGroup g : groups) {
            if (g.campuses() == null) continue;
            campuses.addAll(g.campuses());
        }
        campuses = campuses.stream().filter(StringUtils::hasText).distinct().sorted().toList();

        // 왜: 캠퍼스가 너무 많으면 LLM 프롬프트 토큰을 낭비하므로, 상위 일부만 힌트로 제공합니다.
        int max = Math.min(80, campuses.size());
        List<String> sliced = campuses.subList(0, max);
        return "- " + String.join(", ", sliced) + (campuses.size() > max ? " ..." : "");
    }

    private List<String> flattenCampuses(List<MajorIndustryMappingService.CampusGroup> groups) {
        if (groups == null || groups.isEmpty()) {
            return List.of();
        }
        List<String> campuses = new ArrayList<>();
        for (MajorIndustryMappingService.CampusGroup g : groups) {
            if (g == null || g.campuses() == null) continue;
            campuses.addAll(g.campuses());
        }
        return campuses.stream().filter(StringUtils::hasText).distinct().sorted().toList();
    }

    private String ensureKnownCampus(String campus, List<String> knownCampuses, AiDecision decision) {
        if (!StringUtils.hasText(campus)) {
            return null;
        }
        if (knownCampuses == null || knownCampuses.isEmpty()) {
            return campus;
        }
        if (knownCampuses.contains(campus)) {
            return campus;
        }
        // 왜: 캠퍼스명이 살짝 다르면 내부/인구 통계가 모두 "campus 필수"에서 막히므로, 바로 되물어 정확도를 올립니다.
        return null;
    }

    private String buildAdmListForPrompt(List<StatisticsAiCatalogResponse.AdmRegion> regions) {
        if (regions == null || regions.isEmpty()) {
            return "- (행정구역 목록 없음)";
        }
        return regions.stream()
                .map(r -> r.admCd() + "=" + r.name())
                .reduce((a, b) -> a + ", " + b)
                .map(s -> "- " + s)
                .orElse("- (행정구역 목록 없음)");
    }

    private String toCompactJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return String.valueOf(value);
        }
    }

    private AiDecision parseModelDecision(String modelText) throws Exception {
        String json = extractJsonObject(modelText);
        JsonNode node = objectMapper.readTree(json);

        String action = upper(node.path("action").asText(null));
        if (!StringUtils.hasText(action)) {
            // 왜: 모델이 action을 누락하면 실행/되물음/불가 판단이 어려우므로 보수적으로 되물음 처리합니다.
            return AiDecision.clarify("어떤 통계를 원하시는지 조금 더 구체적으로 알려주세요. (예: 캠퍼스/지역/연도)", List.of("prompt"), node);
        }

        if ("CLARIFY".equals(action)) {
            String question = node.path("question").asText("추가 정보가 필요합니다.");
            List<String> fields = readStringList(node.get("fields"));
            return AiDecision.clarify(question, fields, node);
        }

        if ("UNSUPPORTED".equals(action)) {
            String message = node.path("message").asText("지원하지 않는 질문입니다.");
            List<String> examples = readStringList(node.get("examples"));
            return AiDecision.unsupported(message, examples, node);
        }

        if (!"EXECUTE".equals(action)) {
            return AiDecision.unsupported("지원하지 않는 action입니다. action=" + action, List.of(), node);
        }

        String queryTypeText = upper(node.path("queryType").asText(null));
        if (!StringUtils.hasText(queryTypeText)) {
            return AiDecision.clarify("어떤 종류의 통계를 원하시는지 선택이 필요합니다.", List.of("queryType"), node);
        }

        AiQueryType queryType;
        try {
            queryType = AiQueryType.valueOf(queryTypeText);
        } catch (IllegalArgumentException e) {
            return AiDecision.unsupported("지원하지 않는 queryType 입니다. queryType=" + queryTypeText, List.of(), node);
        }

        Map<String, Object> params = readObjectMap(node.get("params"));
        return AiDecision.execute(queryType, params, node);
    }

    private String extractJsonObject(String text) {
        if (!StringUtils.hasText(text)) {
            throw new IllegalStateException("LLM 응답이 비어 있습니다.");
        }

        String cleaned = text.trim();
        cleaned = cleaned.replace("```json", "").replace("```", "").trim();

        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start < 0 || end < 0 || end <= start) {
            throw new IllegalStateException("LLM 응답에서 JSON 객체를 찾지 못했습니다. 응답=" + safeTruncate(cleaned, 300));
        }

        return cleaned.substring(start, end + 1);
    }

    private String safeTruncate(String text, int max) {
        if (text == null) return null;
        if (text.length() <= max) return text;
        return text.substring(0, max) + "...";
    }

    private Map<String, Object> readObjectMap(JsonNode node) {
        if (node == null || node.isNull() || !node.isObject()) {
            return Map.of();
        }

        Map<String, Object> map = new LinkedHashMap<>();
        node.fields().forEachRemaining(e -> map.put(e.getKey(), jsonNodeToJava(e.getValue())));
        return map;
    }

    private Object jsonNodeToJava(JsonNode node) {
        if (node == null || node.isNull()) return null;
        if (node.isTextual()) return node.asText();
        if (node.isNumber()) return node.numberValue();
        if (node.isBoolean()) return node.booleanValue();
        if (node.isArray()) {
            List<Object> list = new ArrayList<>();
            for (JsonNode n : node) {
                list.add(jsonNodeToJava(n));
            }
            return list;
        }
        if (node.isObject()) {
            return readObjectMap(node);
        }
        return node.asText();
    }

    private List<String> readStringList(JsonNode node) {
        if (node == null || node.isNull()) {
            return List.of();
        }

        if (node.isArray()) {
            List<String> list = new ArrayList<>();
            for (JsonNode n : node) {
                if (n != null && n.isTextual() && StringUtils.hasText(n.asText())) {
                    list.add(n.asText());
                }
            }
            return list;
        }

        if (node.isTextual() && StringUtils.hasText(node.asText())) {
            return List.of(node.asText());
        }

        return List.of();
    }

    private String resolveCampus(Map<String, Object> params, Map<String, Object> context) {
        String campus = resolveOptionalString(params, "campus", context, "campus");
        if (!StringUtils.hasText(campus)) {
            return null;
        }

        String trimmed = campus.trim();
        if (trimmed.endsWith("캠퍼스")) {
            return trimmed.substring(0, trimmed.length() - "캠퍼스".length()).trim();
        }
        return trimmed;
    }

    private String resolveAdmCd(Map<String, Object> params, Map<String, Object> context) {
        String admCd = resolveOptionalString(params, "admCd", context, "admCd");
        if (!StringUtils.hasText(admCd) || "전체".equals(admCd)) {
            return "11";
        }

        String trimmed = admCd.trim();
        // 왜: 사용자가 "서울"처럼 이름으로 입력할 수 있어, 간단히 매핑해 봅니다.
        String mapped = mapAdmCdByName(trimmed);
        return mapped != null ? mapped : trimmed;
    }

    private String mapAdmCdByName(String text) {
        String v = text.trim().toLowerCase(Locale.KOREA);
        for (StatisticsAiCatalogResponse.AdmRegion r : ADM_REGIONS) {
            if (r.name().toLowerCase(Locale.KOREA).contains(v) || v.contains(r.name().toLowerCase(Locale.KOREA))) {
                return r.admCd();
            }
        }
        return null;
    }

    private Integer resolveInteger(Map<String, Object> params, String key, Map<String, Object> context, String contextKey) {
        Object v = firstNonNull(params.get(key), context == null ? null : context.get(contextKey));
        if (v == null) return null;
        if (v instanceof Number n) return n.intValue();
        if (v instanceof String s && StringUtils.hasText(s) && s.trim().matches("\\d+")) return Integer.parseInt(s.trim());
        return null;
    }

    private String resolveOptionalString(Map<String, Object> params, String key, Map<String, Object> context, String contextKey) {
        Object v = firstNonNull(params.get(key), context == null ? null : context.get(contextKey));
        if (v == null) return null;
        String s = String.valueOf(v).trim();
        return StringUtils.hasText(s) ? s : null;
    }

    private int resolveTop(Map<String, Object> params, int defaultTop) {
        Integer top = resolveInteger(params, "top", null, null);
        int resolved = top == null ? defaultTop : top;
        if (resolved < 1) resolved = 1;
        if (resolved > 30) resolved = 30;
        return resolved;
    }

    private Object firstNonNull(Object a, Object b) {
        return a != null ? a : b;
    }

    private double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private String upper(String v) {
        return v == null ? null : v.trim().toUpperCase(Locale.ROOT);
    }

    private record AiDecision(
            Action action,
            AiQueryType queryType,
            Map<String, Object> params,
            String question,
            List<String> fields,
            String message,
            List<String> examples,
            String rawJson
    ) {
        enum Action {EXECUTE, CLARIFY, UNSUPPORTED}

        static AiDecision execute(AiQueryType queryType, Map<String, Object> params, JsonNode raw) {
            return new AiDecision(Action.EXECUTE, queryType, params, null, null, null, null, raw == null ? null : raw.toString());
        }

        static AiDecision clarify(String question, List<String> fields, JsonNode raw) {
            return new AiDecision(Action.CLARIFY, null, null, question, fields, null, null, raw == null ? null : raw.toString());
        }

        static AiDecision unsupported(String message, List<String> examples, JsonNode raw) {
            return new AiDecision(Action.UNSUPPORTED, null, null, null, null, message, examples, raw == null ? null : raw.toString());
        }
    }
}
