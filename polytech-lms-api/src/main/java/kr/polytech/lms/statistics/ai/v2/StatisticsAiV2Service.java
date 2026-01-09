package kr.polytech.lms.statistics.ai.v2;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.statistics.ai.GeminiClient;
import kr.polytech.lms.statistics.ai.StatisticsAiProperties;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryRequest;
import kr.polytech.lms.statistics.ai.StatisticsAiQueryResponse;
import kr.polytech.lms.statistics.internalstats.InternalStatisticsService;
import kr.polytech.lms.statistics.kosis.client.dto.KosisPopulationRow;
import kr.polytech.lms.statistics.kosis.service.KosisStatisticsService;
import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import kr.polytech.lms.statistics.sgis.client.SgisClient;
import kr.polytech.lms.statistics.sgis.service.SgisCompanyCacheService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.HttpClientErrorException;

import java.io.IOException;
import java.time.Year;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;

@Service
public class StatisticsAiV2Service {
    // 왜: v1은 "고정된 4개 타입"만 실행할 수 있어서, 사용자 질문을 자유롭게 조합하기 어렵습니다.
    //     v2는 LLM이 "여러 단계 실행계획(steps)"을 만들고,
    //     서버가 그 계획을 검증/병렬 실행/조합해서 결과(차트/표/요약)를 돌려주는 구조로 확장합니다.

    private static final int MAX_STEPS = 12;
    private static final int MAX_YEARS = 12;
    private static final int MAX_CLASS_CODES = 80;

    private static final Logger log = LoggerFactory.getLogger(StatisticsAiV2Service.class);

    private final StatisticsAiProperties properties;
    private final GeminiClient geminiClient;
    private final ObjectMapper objectMapper;
    private final StatisticsAiV2CatalogService catalogService;
    private final StatisticsAiV2DataStoreService dataStoreService;
    private final KosisStatisticsService kosisStatisticsService;
    private final SgisCompanyCacheService sgisCompanyCacheService;
    private final InternalStatisticsService internalStatisticsService;
    private final MajorIndustryMappingService majorIndustryMappingService;
    private final ExecutorService executor;

    public StatisticsAiV2Service(
            StatisticsAiProperties properties,
            GeminiClient geminiClient,
            ObjectMapper objectMapper,
            StatisticsAiV2CatalogService catalogService,
            StatisticsAiV2DataStoreService dataStoreService,
            KosisStatisticsService kosisStatisticsService,
            SgisCompanyCacheService sgisCompanyCacheService,
            InternalStatisticsService internalStatisticsService,
            MajorIndustryMappingService majorIndustryMappingService,
            ExecutorService statisticsAiV2Executor
    ) {
        this.properties = properties;
        this.geminiClient = geminiClient;
        this.objectMapper = objectMapper;
        this.catalogService = catalogService;
        this.dataStoreService = dataStoreService;
        this.kosisStatisticsService = kosisStatisticsService;
        this.sgisCompanyCacheService = sgisCompanyCacheService;
        this.internalStatisticsService = internalStatisticsService;
        this.majorIndustryMappingService = majorIndustryMappingService;
        this.executor = statisticsAiV2Executor;
    }

    public StatisticsAiV2CatalogResponse getCatalog() {
        return catalogService.getCatalog();
    }

    public StatisticsAiQueryResponse query(StatisticsAiQueryRequest request) {
        if (request == null || !StringUtils.hasText(request.prompt())) {
            throw new IllegalArgumentException("prompt는 필수입니다.");
        }

        StatisticsAiV2CatalogResponse catalog = catalogService.getCatalog();

        StatisticsAiV2Plan plan;
        try {
            String modelPrompt = buildModelPrompt(request.prompt(), request.context(), catalog);
            String modelText = geminiClient.generateText(modelPrompt);
            plan = parseModelPlan(modelText);
        } catch (HttpClientErrorException.TooManyRequests e) {
            // 왜: 무료 티어/쿼터 초과(429)로 LLM 호출이 막히면, 화면에서는 "전부 실패"로 보입니다.
            //     LLM이 없어도 동작 가능한 최소 범위(룰 기반 실행계획)로 폴백합니다.
            log.warn("Gemini 429(쿼터 초과)로 v2 플래너 폴백: prompt={}", safeTruncate(request.prompt(), 120), e);
            plan = buildFallbackPlan(request.prompt(), request.context(), catalog, e.getMessage());
        } catch (Exception e) {
            log.error("Gemini 호출 실패로 v2 플래너 폴백: prompt={}", safeTruncate(request.prompt(), 120), e);
            plan = buildFallbackPlan(request.prompt(), request.context(), catalog, e.getMessage());
        }

        if (plan.action() == StatisticsAiV2Plan.Action.CLARIFY) {
            // 왜: 사용자는 "추가 질문 없이" 바로 결과를 원합니다.
            //     모델이 CLARIFY를 주더라도 steps가 있으면 그대로 실행하고(부족한 값은 기본값으로),
            //     steps가 없을 때만 폴백 플랜으로 진행합니다.
            if (plan.steps() != null && !plan.steps().isEmpty()) {
                plan = new StatisticsAiV2Plan(
                        StatisticsAiV2Plan.Action.EXECUTE,
                        null,
                        null,
                        null,
                        null,
                        plan.steps(),
                        plan.rawJson()
                );
            } else {
                plan = buildFallbackPlan(request.prompt(), request.context(), catalog, "추가 정보 없이 기본값으로 진행");
            }
        } else if (plan.action() == StatisticsAiV2Plan.Action.UNSUPPORTED) {
            // 왜: 불가 응답이라도 "있는 데이터"로 최소 결과를 보여줘야 합니다.
            plan = buildFallbackPlan(request.prompt(), request.context(), catalog, "추가 정보 없이 기본값으로 진행");
        }
        return executePlan(plan, catalog);
    }

    private StatisticsAiV2Plan buildFallbackPlan(
            String prompt,
            Map<String, Object> context,
            StatisticsAiV2CatalogResponse catalog,
            String causeMessage
    ) {
        String text = (prompt == null) ? "" : prompt.trim().toLowerCase(Locale.KOREA);
        String message = "AI 통계 모델 호출이 제한되어(외부 API 오류) 임시 폴백으로 처리합니다. 잠시 후 다시 시도해 주세요."
                + (StringUtils.hasText(causeMessage) ? " (" + safeTruncate(causeMessage, 120) + ")" : "");

        List<Integer> years = pickRecentYears(catalog, 4);
        String admCd = pickAdmCd(text, catalog);
        String category = pickIndustryCategory(text);

        boolean wantsCorrelation = containsAny(text, List.of("상관", "상관관계", "correlation"));
        boolean wantsEmployment = containsAny(text, List.of("취업", "취업률"));
        boolean wantsIndustry = containsAny(text, List.of("산업", "it", "ict", "종사자", "사업체", "성장"));
        boolean wantsTrend = containsAny(text, List.of("추이", "트렌드", "변화"));

        // 1) "IT산업 vs 취업률 상관관계" 최소 지원(LLM 없이도 실행 가능)
        if (wantsCorrelation && wantsEmployment && wantsIndustry && StringUtils.hasText(category)) {
            Map<String, Object> employmentParams = new LinkedHashMap<>();
            employmentParams.put("years", years);
            employmentParams.put("category", category);
            // 왜: Java Map.of(...)는 null이 들어가면 NPE가 나므로, context 값이 없으면 키 자체를 생략합니다.
            if (context != null) {
                Object campus = context.get("campus");
                Object dept = context.get("dept");
                if (campus != null) employmentParams.put("campus", campus);
                if (dept != null) employmentParams.put("dept", dept);
            }

            List<StatisticsAiV2Plan.Step> steps = List.of(
                    new StatisticsAiV2Plan.Step(
                            "a1",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.SGIS_METRIC_SERIES,
                            "itIndustry",
                            Map.of(
                                    "admCd", admCd,
                                    "years", years,
                                    "metric", "TOTWORKER",
                                    "category", category
                            )
                    ),
                    new StatisticsAiV2Plan.Step(
                            "a2",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_SERIES,
                            "employment",
                            employmentParams
                    ),
                    new StatisticsAiV2Plan.Step(
                            "c1",
                            StatisticsAiV2Plan.Agent.CHEMIST,
                            StatisticsAiV2Ops.CHEMIST_CORRELATION,
                            "corr",
                            Map.of("xRef", "itIndustry", "yRef", "employment")
                    ),
                    new StatisticsAiV2Plan.Step(
                            "d1",
                            StatisticsAiV2Plan.Agent.DESIGNER,
                            StatisticsAiV2Ops.DESIGNER_CHART,
                            "chart",
                            Map.of(
                                    "chartType", "line_dual_axis",
                                    "title", "산업 vs 취업률 (폴백)",
                                    "seriesRefs", List.of("itIndustry", "employment")
                            )
                    )
            );

            return new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.EXECUTE,
                    null,
                    null,
                    message,
                    defaultExamples(),
                    steps,
                    "{\"fallback\":true}"
            );
        }

        // 2) 취업률 추이(트렌드) 최소 지원
        if (wantsEmployment && (wantsTrend || !StringUtils.hasText(category))) {
            Map<String, Object> employmentParams = new LinkedHashMap<>();
            employmentParams.put("years", years);
            if (StringUtils.hasText(category)) {
                employmentParams.put("category", category);
            }
            if (context != null) {
                Object campus = context.get("campus");
                Object dept = context.get("dept");
                if (campus != null) employmentParams.put("campus", campus);
                if (dept != null) employmentParams.put("dept", dept);
            }

            List<StatisticsAiV2Plan.Step> steps = List.of(
                    new StatisticsAiV2Plan.Step(
                            "a1",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_SERIES,
                            "employment",
                            employmentParams
                    ),
                    new StatisticsAiV2Plan.Step(
                            "d1",
                            StatisticsAiV2Plan.Agent.DESIGNER,
                            StatisticsAiV2Ops.DESIGNER_CHART,
                            "chart",
                            Map.of(
                                    "chartType", "line",
                                    "title", StringUtils.hasText(category) ? category + " 취업률 추이 (폴백)" : "우리 학교 전체 취업률 추이 (폴백)",
                                    "seriesRefs", List.of("employment")
                            )
                    )
            );

            return new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.EXECUTE,
                    null,
                    null,
                    message + (StringUtils.hasText(category) ? "" : " (전체 데이터 기준)"),
                    defaultExamples(),
                    steps,
                    "{\"fallback\":true}"
            );
        }

        // 2.5) 입학충원률 추이 폴백
        boolean wantsAdmission = containsAny(text, List.of("입학", "충원", "충원률", "정원", "입학률"));
        if (wantsAdmission) {
            List<StatisticsAiV2Plan.Step> steps = List.of(
                    new StatisticsAiV2Plan.Step(
                            "a1",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.INTERNAL_ADMISSION_TOP,
                            "topAdmission",
                            Map.of("top", 10)
                    ),
                    new StatisticsAiV2Plan.Step(
                            "d1",
                            StatisticsAiV2Plan.Agent.DESIGNER,
                            StatisticsAiV2Ops.DESIGNER_CHART,
                            "chart1",
                            Map.of(
                                    "chartType", "bar",
                                    "title", "입학충원률 Top 10 (폴백)",
                                    "seriesRefs", List.of("topAdmission")
                            )
                    )
            );

            return new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.EXECUTE,
                    null,
                    null,
                    message + " (입학충원률 통계 기본 제공)",
                    defaultExamples(),
                    steps,
                    "{\"fallback\":true}"
            );
        }

        // 3) 인구 통계 질문 폴백
        boolean wantsPopulation = containsAny(text, List.of("인구", "연령", "성별", "20대", "30대", "40대", "50대", "60대"));
        if (wantsPopulation) {
            List<StatisticsAiV2Plan.Step> steps = List.of(
                    new StatisticsAiV2Plan.Step(
                            "a1",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.KOSIS_POPULATION_SERIES,
                            "population",
                            Map.of(
                                    "years", years,
                                    "admCd", admCd,
                                    "ageType", "31",  // 기본값: 20대
                                    "gender", "0"     // 기본값: 전체
                            )
                    ),
                    new StatisticsAiV2Plan.Step(
                            "d1",
                            StatisticsAiV2Plan.Agent.DESIGNER,
                            StatisticsAiV2Ops.DESIGNER_CHART,
                            "chart1",
                            Map.of(
                                    "chartType", "line",
                                    "title", "인구 추이 (폴백)",
                                    "seriesRefs", List.of("population")
                            )
                    )
            );

            return new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.EXECUTE,
                    null,
                    null,
                    message + " (인구 통계 기본 제공)",
                    defaultExamples(),
                    steps,
                    "{\"fallback\":true}"
            );
        }

        // 4) 산업/종사자 통계 질문 폴백
        boolean wantsIndustryData = containsAny(text, List.of("제조업", "서비스업", "건설업", "종사자", "사업체", "전국", "지역"));
        if (wantsIndustryData || wantsIndustry) {
            String industryCategory = StringUtils.hasText(category) ? category : "제조업";
            List<String> classCodes = majorIndustryMappingService.getSgisClassCodesByCategory().getOrDefault(industryCategory, List.of("C"));

            List<StatisticsAiV2Plan.Step> steps = List.of(
                    new StatisticsAiV2Plan.Step(
                            "a1",
                            StatisticsAiV2Plan.Agent.ANALYST,
                            StatisticsAiV2Ops.SGIS_METRIC_SERIES,
                            "industryWorkers",
                            Map.of(
                                    "years", years,
                                    "admCd", admCd,
                                    "metric", "TOTWORKER",
                                    "classCodes", classCodes
                            )
                    ),
                    new StatisticsAiV2Plan.Step(
                            "d1",
                            StatisticsAiV2Plan.Agent.DESIGNER,
                            StatisticsAiV2Ops.DESIGNER_CHART,
                            "chart1",
                            Map.of(
                                    "chartType", "line",
                                    "title", industryCategory + " 종사자 추이 (폴백)",
                                    "seriesRefs", List.of("industryWorkers")
                            )
                    )
            );

            return new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.EXECUTE,
                    null,
                    null,
                    message + " (" + industryCategory + " 통계 기본 제공)",
                    defaultExamples(),
                    steps,
                    "{\"fallback\":true}"
            );
        }

        // 5) 정보가 완전히 부족할 때: 우리 학교 취업 현황을 기본으로 제공
        List<StatisticsAiV2Plan.Step> steps = List.of(
                new StatisticsAiV2Plan.Step(
                        "a1",
                        StatisticsAiV2Plan.Agent.ANALYST,
                        StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_TOP,
                        "topEmployment",
                        Map.of("top", 5)
                ),
                new StatisticsAiV2Plan.Step(
                        "a2",
                        StatisticsAiV2Plan.Agent.ANALYST,
                        StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_SERIES,
                        "employmentSeries",
                        Map.of("years", years)
                ),
                new StatisticsAiV2Plan.Step(
                        "d1",
                        StatisticsAiV2Plan.Agent.DESIGNER,
                        StatisticsAiV2Ops.DESIGNER_CHART,
                        "chart1",
                        Map.of(
                                "chartType", "bar",
                                "title", "학교 전체 취업률 현황 (기본 제공)",
                                "seriesRefs", List.of("employmentSeries")
                        )
                )
        );

        return new StatisticsAiV2Plan(
                StatisticsAiV2Plan.Action.EXECUTE,
                null,
                null,
                message + " (정보 부족으로 학교 취업 통계 기본 제공)",
                defaultExamples(),
                steps,
                "{\"fallback\":true}"
        );
    }

    private List<Integer> pickRecentYears(StatisticsAiV2CatalogResponse catalog, int count) {
        List<Integer> years = (catalog == null || catalog.recommendedYears() == null) ? List.of() : catalog.recommendedYears();
        if (years.isEmpty()) {
            // 왜: 최신 가용 연도를 우선 사용합니다.
            List<Integer> recommended = catalogService.getCatalog().recommendedYears();
            if (recommended != null && !recommended.isEmpty()) {
                years = recommended.stream().distinct().sorted().toList();
            } else {
                int now = Year.now().getValue();
                years = List.of(now - 1, now - 2, now - 3, now - 4);
            }
        }
        years = years.stream().distinct().sorted().toList();
        if (years.size() <= count) return years;
        return years.subList(years.size() - count, years.size());
    }

    private String pickAdmCd(String text, StatisticsAiV2CatalogResponse catalog) {
        if (!StringUtils.hasText(text) || catalog == null || catalog.admRegions() == null) {
            return "11";
        }
        for (StatisticsAiV2CatalogResponse.AdmRegion r : catalog.admRegions()) {
            String name = r.name() == null ? "" : r.name().toLowerCase(Locale.KOREA);
            if (StringUtils.hasText(name) && text.contains(name)) {
                return r.admCd();
            }
        }
        return "11";
    }

    private String pickIndustryCategory(String text) {
        if (!StringUtils.hasText(text)) return null;
        // 왜: 폴백에서 질문의 키워드로 산업 분류를 추정합니다.
        //     키워드가 명확하지 않으면 null을 반환하고, 호출부에서 기본값을 사용합니다.
        if (containsAny(text, List.of("it", "ict", "정보통신", "컴퓨터", "소프트웨어", "인공지능", "ai"))) {
            return "ICT";
        }
        if (containsAny(text, List.of("첨단", "첨단기술", "첨단산업"))) {
            return "첨단기술";
        }
        if (containsAny(text, List.of("고기술", "고기술산업"))) {
            return "고기술";
        }
        if (containsAny(text, List.of("제조", "제조업", "공장", "생산"))) {
            return "제조업";
        }
        if (containsAny(text, List.of("서비스", "서비스업", "금융", "보험"))) {
            return "서비스업";
        }
        if (containsAny(text, List.of("건설", "건설업", "건축", "토목"))) {
            return "건설업";
        }
        if (containsAny(text, List.of("도소매", "유통", "판매"))) {
            return "도소매업";
        }
        if (containsAny(text, List.of("관광", "숙박", "여행"))) {
            return "관광업";
        }
        return null;
    }

    private boolean containsAny(String text, List<String> keywords) {
        if (!StringUtils.hasText(text) || keywords == null) return false;
        for (String k : keywords) {
            if (StringUtils.hasText(k) && text.contains(k.toLowerCase(Locale.KOREA))) {
                return true;
            }
        }
        return false;
    }

    private StatisticsAiQueryResponse executePlan(StatisticsAiV2Plan plan, StatisticsAiV2CatalogResponse catalog) {
        List<StatisticsAiQueryResponse.WarningSpec> warnings = new ArrayList<>();

        List<StatisticsAiV2Plan.Step> steps = plan.steps() == null ? List.of() : plan.steps();
        if (steps.isEmpty()) {
            return unsupported(new StatisticsAiV2Plan(
                    StatisticsAiV2Plan.Action.UNSUPPORTED,
                    null,
                    null,
                    "실행할 steps가 없습니다. 질문을 조금 더 구체적으로 말씀해 주세요.",
                    List.of("서울(11) ICT 종사자 수를 2020~2023으로 보여줘", "서울정수 취업률 Top 10 보여줘"),
                    List.of(),
                    plan.rawJson()
            ));
        }
        if (steps.size() > MAX_STEPS) {
            throw new IllegalArgumentException("steps가 너무 많습니다. 최대 " + MAX_STEPS + "개까지 지원합니다.");
        }

        ensureUniqueStepIds(steps);

        Map<String, V2Result> results = new LinkedHashMap<>();

        // 1) ANALYST 병렬 실행
        List<CompletableFuture<StepResult>> analystFutures = new ArrayList<>();
        for (StatisticsAiV2Plan.Step step : steps) {
            if (step.agent() != StatisticsAiV2Plan.Agent.ANALYST) {
                continue;
            }

            analystFutures.add(CompletableFuture.supplyAsync(() -> {
                try {
                    V2Result r = executeAnalyst(step);
                    return StepResult.success(stepKey(step), r);
                } catch (Exception e) {
                    // 왜: 화면에는 요약(warnings)만 내려가서, 실제 원인은 서버 로그가 없으면 추적이 불가능합니다.
                    //     step 단위로 실패 원인을 반드시 로그로 남깁니다.
                    log.warn("AI 통계 v2 ANALYST 실패: stepKey={}, agent={}, op={}, paramsKeys={}",
                            stepKey(step),
                            step.agent(),
                            step.op(),
                            (step.params() == null ? List.of() : step.params().keySet().stream().limit(30).toList()),
                            e);
                    return StepResult.fail(stepKey(step), e);
                }
            }, executor));
        }

        for (CompletableFuture<StepResult> f : analystFutures) {
            StepResult sr = f.join();
            if (sr.error != null) {
                warnings.add(new StatisticsAiQueryResponse.WarningSpec("ANALYST_ERROR", "데이터 조회 실패: " + sr.key + " (" + safeMessage(sr.error) + ")"));
                continue;
            }
            results.put(sr.key, sr.result);
        }

        appendNoticesFromResults(results, warnings);

        if (results.isEmpty()) {
            // 왜: 외부 API/엑셀 등 환경 문제로 "전부 실패"가 나더라도,
            //     화면에서는 최소 1개 차트가 보여야 사용자가 다음 행동(키 설정/재시도)을 할 수 있습니다.
            //     따라서 에러로 끝내지 않고 "빈 차트 + 안내(warnings)"로 응답합니다.
            warnings.add(new StatisticsAiQueryResponse.WarningSpec(
                    "NOTICE",
                    "데이터를 불러오지 못해 빈 차트로 표시됩니다. (외부 API 키/엑셀 파일/환경 설정을 확인해 주세요.)"
            ));

            List<StatisticsAiQueryResponse.ChartSpec> charts = List.of(
                    new StatisticsAiQueryResponse.ChartSpec(
                            "조회 결과",
                            "line",
                            new StatisticsAiQueryResponse.ChartData(
                                    List.of(),
                                    List.of(new StatisticsAiQueryResponse.Dataset("값", List.of(), null))
                            )
                    )
            );

            return new StatisticsAiQueryResponse(
                    false,
                    null,
                    null,
                    null,
                    defaultExamples(),
                    charts,
                    null,
                    buildSummary(Map.of(), warnings),
                    List.of(),
                    warnings,
                    debug(plan, catalog, results)
            );
        }

        // 2) CHEMIST 직렬 실행 (분석은 보통 앞 결과를 참조하므로)
        for (StatisticsAiV2Plan.Step step : steps) {
            if (step.agent() != StatisticsAiV2Plan.Agent.CHEMIST) {
                continue;
            }

            try {
                V2Result r = executeChemist(step, results);
                results.put(stepKey(step), r);
            } catch (Exception e) {
                warnings.add(new StatisticsAiQueryResponse.WarningSpec("CHEMIST_ERROR", "분석 실패: " + stepKey(step) + " (" + safeMessage(e) + ")"));
            }
        }

        // 3) DESIGNER: steps가 있으면 그걸 우선, 없으면 기본 추천(휴리스틱)
        // 3) DESIGNER: steps가 있으면 그걸 우선, 없으면 기본 추천(휴리스틱)
        List<StatisticsAiQueryResponse.ChartSpec> charts = new ArrayList<>();
        StatisticsAiQueryResponse.TableSpec table = null;

        boolean hasDesigner = steps.stream().anyMatch(s -> s.agent() == StatisticsAiV2Plan.Agent.DESIGNER);
        if (hasDesigner) {
            for (StatisticsAiV2Plan.Step step : steps) {
                if (step.agent() != StatisticsAiV2Plan.Agent.DESIGNER) {
                    continue;
                }

                try {
                    DesignerOutput out = executeDesigner(step, results);
                    charts.addAll(out.charts);
                    if (table == null && out.table != null) {
                        table = out.table;
                    }
                } catch (Exception e) {
                    log.warn("DESIGNER 실행 실패(무시): id={}, op={}, err={}", step.id(), step.op(), e.getMessage());
                    String msg = "시계열 시각화(차트) 생성 중 설정 오류가 발생했습니다. (id=" + step.id() + ")";
                    if (e.getMessage().contains("seriesRefs")) {
                        msg = "시각화 대상(seriesRefs) 데이터가 지정되지 않아 차트를 생성하지 못했습니다.";
                    }
                    warnings.add(new StatisticsAiQueryResponse.WarningSpec("DESIGNER_ERROR", msg));
                }
            }

            // 왜: LLM이 잘못된 chartType/refs를 주면 DESIGNER step이 실패할 수 있습니다.
            //     이 경우에도 조회된 시계열/표가 있다면 자동 추천으로 최소 1개 차트를 보여주는 게 UX가 좋습니다.
            if (charts.isEmpty() && table == null) {
                DesignerOutput out = autoDesign(results);
                charts.addAll(out.charts);
                table = out.table;
            }
        } else {
            DesignerOutput out = autoDesign(results);
            charts.addAll(out.charts);
            table = out.table;
        }

        appendEmptyChartNotice(charts, warnings);
        if (charts.isEmpty() && table == null) {
            // 왜: 결과 객체(ObjectResult)만 남는 경우(예: 상관관계 계산은 됐지만 시계열이 없었음) 화면이 "텅 빈 상태"가 됩니다.
            //     최소 1개 차트는 항상 내려가도록 안전망을 둡니다.
            warnings.add(new StatisticsAiQueryResponse.WarningSpec("NOTICE", "표시할 시계열/표가 없어 빈 차트로 표시됩니다."));
            charts.add(new StatisticsAiQueryResponse.ChartSpec(
                    "조회 결과",
                    "line",
                    new StatisticsAiQueryResponse.ChartData(
                            List.of(),
                            List.of(new StatisticsAiQueryResponse.Dataset("값", List.of(), null))
                    )
            ));
        }

        String summary = buildSummary(results, warnings);
        List<StatisticsAiQueryResponse.SourceSpec> sources = buildSources(results);

        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                null,
                null,
                charts,
                table,
                summary,
                sources,
                warnings,
                debug(plan, catalog, results)
        );
    }

    private List<String> defaultExamples() {
        return List.of(
                "서울(11) 20대 인구를 2020~2024로 보여줘",
                "서울(11) ICT 종사자 수를 2020~2024로 보여줘",
                "서울정수 취업률 Top 10 보여줘 (2024)",
                "서울정수 입학충원률 Top 10 보여줘",
                "서울(11) ICT 종사자 수와 서울정수 취업률을 2020~2024로 같이 보여줘"
        );
    }

    private void appendNoticesFromResults(Map<String, V2Result> results, List<StatisticsAiQueryResponse.WarningSpec> warnings) {
        if (results == null || warnings == null) return;
        for (V2Result r : results.values()) {
            if (r == null || r.meta() == null) continue;
            Object msg = r.meta().get("noticeMessages");
            if (msg instanceof List<?> list) {
                for (Object item : list) {
                    if (item != null) {
                        warnings.add(new StatisticsAiQueryResponse.WarningSpec("NOTICE", String.valueOf(item)));
                    }
                }
            }
        }
    }

    private void appendEmptyChartNotice(List<StatisticsAiQueryResponse.ChartSpec> charts, List<StatisticsAiQueryResponse.WarningSpec> warnings) {
        if (charts == null || warnings == null) return;
        boolean added = false;
        for (StatisticsAiQueryResponse.ChartSpec c : charts) {
            if (c == null || c.data() == null) continue;
            List<String> labels = c.data().labels();
            if (labels == null || labels.isEmpty()) {
                if (!added) {
                    warnings.add(new StatisticsAiQueryResponse.WarningSpec("NOTICE", "해당 연도 데이터가 없어 빈 차트로 표시됩니다."));
                    added = true;
                }
            }
        }
    }

    private void ensureUniqueStepIds(List<StatisticsAiV2Plan.Step> steps) {
        Set<String> ids = new LinkedHashSet<>();
        for (StatisticsAiV2Plan.Step step : steps) {
            String id = StringUtils.hasText(step.id()) ? step.id().trim() : null;
            if (!StringUtils.hasText(id)) {
                throw new IllegalArgumentException("step.id는 필수입니다.");
            }
            if (!ids.add(id)) {
                throw new IllegalArgumentException("중복 step.id가 있습니다. id=" + id);
            }
        }
    }

    private StatisticsAiQueryResponse clarification(StatisticsAiV2Plan plan, StatisticsAiV2CatalogResponse catalog) {
        Map<String, Object> options = new LinkedHashMap<>();
        options.put("fields", plan.fields() == null ? List.of() : plan.fields());
        options.put("campusGroups", catalog.campusGroups());
        options.put("admRegions", catalog.admRegions());
        options.put("recommendedYears", catalog.recommendedYears());
        options.put("industryCategories", catalog.industryCategories());

        return new StatisticsAiQueryResponse(
                true,
                StringUtils.hasText(plan.question()) ? plan.question() : "추가 정보가 필요합니다.",
                options,
                null,
                null,
                List.of(),
                null,
                null,
                List.of(),
                List.of(),
                debug(plan, catalog, Map.of())
        );
    }

    private StatisticsAiQueryResponse unsupported(StatisticsAiV2Plan plan) {
        return new StatisticsAiQueryResponse(
                false,
                null,
                null,
                StringUtils.hasText(plan.message()) ? plan.message() : "지원하지 않는 질문입니다.",
                plan.examples() == null ? List.of() : plan.examples(),
                List.of(),
                null,
                null,
                List.of(),
                List.of(new StatisticsAiQueryResponse.WarningSpec("UNSUPPORTED", "현재 v2는 일부 데이터/분석만 먼저 지원합니다.")),
                debug(plan, null, Map.of())
        );
    }

    private Map<String, Object> debug(StatisticsAiV2Plan plan, StatisticsAiV2CatalogResponse catalog, Map<String, V2Result> results) {
        if (!properties.isDebug()) {
            return null;
        }

        Map<String, Object> debug = new LinkedHashMap<>();
        debug.put("plan", plan.rawJson());
        if (catalog != null) {
            debug.put("catalogVersion", catalog.version());
        }

        List<Map<String, Object>> resultSummary = new ArrayList<>();
        for (Map.Entry<String, V2Result> e : results.entrySet()) {
            V2Result r = e.getValue();
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("key", e.getKey());
            row.put("kind", r.kind().name());
            row.put("meta", r.meta());
            resultSummary.add(row);
        }
        debug.put("results", resultSummary);
        return debug;
    }

    private List<StatisticsAiQueryResponse.SourceSpec> buildSources(Map<String, V2Result> results) {
        Set<String> sources = new LinkedHashSet<>();
        for (V2Result r : results.values()) {
            Object src = r.meta().get("source");
            if (src != null) {
                sources.add(String.valueOf(src));
            }
        }

        List<StatisticsAiQueryResponse.SourceSpec> list = new ArrayList<>();
        for (String s : sources) {
            list.add(new StatisticsAiQueryResponse.SourceSpec(s, "AI 실행계획 기반 조회"));
        }
        return list;
    }

    private String buildSummary(Map<String, V2Result> results, List<StatisticsAiQueryResponse.WarningSpec> warnings) {
        // 왜: PRD v2의 Explain은 LLM 역할이지만, 숫자 환각 위험이 크므로
        //     v2 1차는 서버가 '계산된 결과만'으로 요약/인사이트를 만듭니다.
        long seriesCount = results.values().stream().filter(r -> r instanceof TimeSeriesResult).count();
        long tableCount = results.values().stream().filter(r -> r instanceof TableResult).count();
        long analysisCount = results.values().stream().filter(r -> r instanceof ObjectResult).count();

        StringBuilder sb = new StringBuilder();
        sb.append(String.format("📊 AI가 분석한 데이터 가이드: 시계열 %d건, 표 %d건, 분석 %d건을 찾았습니다.", seriesCount, tableCount, analysisCount));

        String insight = buildInsight(results);
        if (StringUtils.hasText(insight)) {
            sb.append("\n\n💡 [핵심 요약]: ").append(insight);
        }

        if (warnings != null && !warnings.isEmpty()) {
            sb.append("\n\n⚠️ ").append(warnings.size()).append("건의 안내 사항이 있습니다. (차트 하단 Warning 참고)");
        }

        sb.append("\n\n🔍 더 궁금하신 내용이 있나요? 학과별 상세 취업률이나 지역별 인구 변화와의 상관관계를 물어보셔도 좋습니다.");

        return sb.toString();
    }

    private String buildInsight(Map<String, V2Result> results) {
        Double correlation = null;
        Double sgisGrowth = null;
        Double internalGrowth = null;
        Double employmentDelta = null;

        for (V2Result r : results.values()) {
            if (!(r instanceof ObjectResult or)) continue;

            String type = String.valueOf(or.meta.getOrDefault("type", ""));
            if ("correlation".equals(type)) {
                Object v = or.values.get("correlation");
                if (v instanceof Number n) correlation = n.doubleValue();
            } else if ("deltaPoints".equals(type)) {
                Object v = or.values.get("deltaPoints");
                if (v instanceof Number n) employmentDelta = n.doubleValue();
            } else if ("growthRate".equals(type)) {
                String ref = String.valueOf(or.meta.getOrDefault("seriesRef", ""));
                Object v = or.values.get("growthRatePercent");
                if (v instanceof Number n && StringUtils.hasText(ref)) {
                    V2Result referenced = results.get(ref);
                    if (referenced instanceof TimeSeriesResult ts) {
                        String source = String.valueOf(ts.meta.getOrDefault("source", ""));
                        if ("SGIS".equals(source)) sgisGrowth = n.doubleValue();
                        else if ("내부 엑셀".equals(source)) internalGrowth = n.doubleValue();
                    }
                }
            }
        }

        List<String> insightParts = new ArrayList<>();
        if (correlation != null) {
            String level = Math.abs(correlation) > 0.7 ? "높은" : (Math.abs(correlation) > 0.4 ? "보통 수준의" : "낮은");
            insightParts.add(String.format("두 데이터 간에 %s 상관관계(r=%.2f)가 관찰됩니다.", level, correlation));
        }
        if (sgisGrowth != null) insightParts.add(String.format("산업 종사자가 %.1f%% 성장하는 추세입니다.", sgisGrowth));
        if (internalGrowth != null) insightParts.add(String.format("학교 내부 통계상 %.1f%%의 성장률을 기록하고 있습니다.", internalGrowth));
        if (employmentDelta != null) insightParts.add(String.format("이전 대비 %+.1f%%p의 변화가 확인되었습니다.", employmentDelta));

        return insightParts.isEmpty() ? "데이터 추이가 안정적입니다." : String.join(" ", insightParts);
    }

    private DesignerOutput autoDesign(Map<String, V2Result> results) {
        List<StatisticsAiQueryResponse.ChartSpec> charts = new ArrayList<>();
        StatisticsAiQueryResponse.TableSpec table = null;

        List<TimeSeriesResult> series = new ArrayList<>();
        List<String> seriesKeys = new ArrayList<>();
        for (Map.Entry<String, V2Result> e : results.entrySet()) {
            if (e.getValue() instanceof TimeSeriesResult ts) {
                series.add(ts);
                seriesKeys.add(e.getKey());
            }
        }

        // 왜: PRD v2의 대표 시나리오(산업 시계열 vs 취업률 시계열)는 "2개 시계열 비교"가 많아서,
        //     자동 추천에서는 2개면 이중축 라인 차트를 우선 제안합니다.
        if (series.size() == 2) {
            TimeSeriesResult a = series.get(0);
            TimeSeriesResult b = series.get(1);
            String titleA = humanTitle(a, seriesKeys.get(0));
            String titleB = humanTitle(b, seriesKeys.get(1));
            charts.add(toDualAxisLineChart(titleA + " vs " + titleB, a, b));
            table = buildAlignedSeriesTable(a, b);
            return new DesignerOutput(charts, table);
        }

        for (Map.Entry<String, V2Result> e : results.entrySet()) {
            V2Result r = e.getValue();
            if (r instanceof TimeSeriesResult ts) {
                charts.add(toLineChart(humanTitle(ts, e.getKey()), ts));
            } else if (r instanceof TableResult tr) {
                if (table == null) {
                    table = new StatisticsAiQueryResponse.TableSpec(tr.columns, tr.rows);
                }
                charts.add(toBarChart(humanTitle(tr, e.getKey()), tr));
            }
        }

        return new DesignerOutput(charts, table);
    }

    private String humanTitle(V2Result result, String fallbackKey) {
        // 왜: LLM이 생성한 step key(예: mfg_workers, s1 등)보다 데이터의 실제 의미(seriesLabel, source, metric)를 사용해야
        //     사용자가 차트를 이해하는 데 훨씬 도움이 됩니다.
        if (result instanceof TimeSeriesResult ts) {
            if (StringUtils.hasText(ts.seriesLabel())) {
                String source = String.valueOf(ts.meta().getOrDefault("source", ""));
                String metric = String.valueOf(ts.meta().getOrDefault("metric", ""));
                StringBuilder sb = new StringBuilder();
                if (StringUtils.hasText(source) && !"null".equals(source)) {
                    sb.append("[").append(source).append("] ");
                }
                sb.append(ts.seriesLabel());
                if (StringUtils.hasText(metric) && !"null".equals(metric) && !ts.seriesLabel().contains(metric)) {
                    sb.append(" (").append(metric).append(")");
                }
                return sb.toString();
            }
        }
        if (result instanceof TableResult tr) {
            if (!tr.columns().isEmpty()) {
                return tr.columns().get(0) + " 통계";
            }
        }
        return fallbackKey;
    }

    private StatisticsAiQueryResponse.TableSpec buildAlignedSeriesTable(TimeSeriesResult left, TimeSeriesResult right) {
        AlignedSeries aligned = alignForChart(left, right);
        List<List<Object>> rows = new ArrayList<>();
        for (int i = 0; i < aligned.labels.size(); i++) {
            rows.add(List.of(aligned.labels.get(i), aligned.leftValues.get(i), aligned.rightValues.get(i)));
        }
        return new StatisticsAiQueryResponse.TableSpec(
                List.of("라벨", left.seriesLabel(), right.seriesLabel()),
                rows
        );
    }

    private DesignerOutput executeDesigner(StatisticsAiV2Plan.Step step, Map<String, V2Result> results) {
        if (!StatisticsAiV2Ops.DESIGNER_CHART.equalsIgnoreCase(step.op())) {
            throw new IllegalArgumentException("지원하지 않는 DESIGNER op 입니다. op=" + step.op());
        }

        String chartType = stringParam(step.params(), "chartType");
        String title = stringParam(step.params(), "title");
        List<String> seriesRefs = stringListParam(step.params(), "seriesRefs");

        // 왜: LLM이 seriesRefs를 빠뜨리거나 잘못된 형식을 줄 수 있습니다.
        //     이 경우 예외를 던지기보다, 현재 가용한 결과물 중 가장 적합한 것을 자동으로 골라 보여주는 것이 UX 상 훨씬 낫습니다.
        if (seriesRefs.isEmpty()) {
            List<String> autoRefs = new ArrayList<>();
            for (Map.Entry<String, V2Result> e : results.entrySet()) {
                if (e.getValue() instanceof TimeSeriesResult || e.getValue() instanceof TableResult) {
                    autoRefs.add(e.getKey());
                }
            }
            seriesRefs = autoRefs;
            log.info("DESIGNER seriesRefs 누락으로 자동 복구 수행: stepId={}, autoRefs={}", step.id(), seriesRefs);
        }

        if (seriesRefs.isEmpty()) {
            throw new IllegalArgumentException("시각화할 수 있는 데이터 결과가 없습니다. (seriesRefs missing and no data available)");
        }

        List<StatisticsAiQueryResponse.ChartSpec> charts = new ArrayList<>();
        StatisticsAiQueryResponse.TableSpec table = null;

        String resolvedTitle = StringUtils.hasText(title) ? title : ("조회 결과 (" + chartType + ")");

        // 차트 타입별 유연한 처리
        if ("bar".equalsIgnoreCase(chartType)) {
            V2Result r = results.get(seriesRefs.get(0));
            if (r instanceof TableResult tr) {
                charts.add(toBarChart(resolvedTitle, tr));
                table = new StatisticsAiQueryResponse.TableSpec(tr.columns, tr.rows);
            } else if (r instanceof TimeSeriesResult ts) {
                // 시계열도 바 차트로 보여줄 수 있음
                charts.add(new StatisticsAiQueryResponse.ChartSpec(resolvedTitle, "bar", toChartData(ts)));
            }
            return new DesignerOutput(charts, table);
        }

        if ("line".equalsIgnoreCase(chartType) || "dual_axis_line".equalsIgnoreCase(chartType) || "line_dual_axis".equalsIgnoreCase(chartType)) {
            if (seriesRefs.size() >= 2 && results.get(seriesRefs.get(0)) instanceof TimeSeriesResult && results.get(seriesRefs.get(1)) instanceof TimeSeriesResult) {
                TimeSeriesResult a = (TimeSeriesResult) results.get(seriesRefs.get(0));
                TimeSeriesResult b = (TimeSeriesResult) results.get(seriesRefs.get(1));
                charts.add(toDualAxisLineChart(resolvedTitle, a, b));
                return new DesignerOutput(charts, null);
            } else if (!seriesRefs.isEmpty() && results.get(seriesRefs.get(0)) instanceof TimeSeriesResult ts) {
                charts.add(new StatisticsAiQueryResponse.ChartSpec(resolvedTitle, "line", toChartData(ts)));
                return new DesignerOutput(charts, null);
            }
        }

        // 도저히 타입을 맞출 수 없으면 autoDesign에 맡김
        return autoDesign(results);
    }

    private StatisticsAiQueryResponse.ChartSpec toLineChart(String title, TimeSeriesResult ts) {
        return new StatisticsAiQueryResponse.ChartSpec(title, "line", toChartData(ts));
    }

    private StatisticsAiQueryResponse.ChartSpec toBarChart(String title, TableResult table) {
        // 왜: Top N 표는 기본적으로 막대 차트로 바로 시각화할 수 있어서, 최소 구현으로도 사용성이 좋습니다.
        int labelIndex = 0;
        int valueIndex = table.columns.size() > 1 ? 1 : 0;

        List<String> labels = new ArrayList<>();
        List<Double> values = new ArrayList<>();
        for (List<Object> row : table.rows) {
            labels.add(String.valueOf(row.get(labelIndex)));
            Object v = row.get(valueIndex);
            values.add(v instanceof Number n ? n.doubleValue() : tryParseDouble(v));
        }

        return new StatisticsAiQueryResponse.ChartSpec(
                title,
                "bar",
                new StatisticsAiQueryResponse.ChartData(
                        labels,
                        List.of(new StatisticsAiQueryResponse.Dataset(table.columns.get(valueIndex), values, null))
                )
        );
    }

    private StatisticsAiQueryResponse.ChartSpec toDualAxisLineChart(String title, TimeSeriesResult left, TimeSeriesResult right) {
        AlignedSeries aligned = alignForChart(left, right);

        List<StatisticsAiQueryResponse.Dataset> datasets = new ArrayList<>();
        datasets.add(new StatisticsAiQueryResponse.Dataset(left.seriesLabel(), aligned.leftValues, "y1"));
        datasets.add(new StatisticsAiQueryResponse.Dataset(right.seriesLabel(), aligned.rightValues, "y2"));

        return new StatisticsAiQueryResponse.ChartSpec(
                title,
                "line_dual_axis",
                new StatisticsAiQueryResponse.ChartData(aligned.labels, datasets)
        );
    }

    private StatisticsAiQueryResponse.ChartData toChartData(TimeSeriesResult ts) {
        return new StatisticsAiQueryResponse.ChartData(
                ts.labels,
                List.of(new StatisticsAiQueryResponse.Dataset(ts.seriesLabel(), ts.values, null))
        );
    }

    private V2Result executeAnalyst(StatisticsAiV2Plan.Step step) throws Exception {
        String op = upper(step.op());
        Map<String, Object> params = step.params() == null ? Map.of() : step.params();

        return switch (op) {
            case StatisticsAiV2Ops.SGIS_METRIC_SERIES -> executeSgisMetricSeries(params);
            case StatisticsAiV2Ops.KOSIS_POPULATION_SERIES -> executeKosisPopulationSeries(params);
            case StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_TOP -> executeInternalTop(params, true);
            case StatisticsAiV2Ops.INTERNAL_ADMISSION_TOP -> executeInternalTop(params, false);
            case StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_SERIES -> executeInternalEmploymentSeries(params);
            default -> throw new IllegalArgumentException("지원하지 않는 ANALYST op 입니다. op=" + step.op());
        };
    }

    private V2Result executeSgisMetricSeries(Map<String, Object> params) throws IOException {
        String admCd = resolveAdmCd(stringParam(params, "admCd"));
        List<Integer> years = resolveYears(params.get("years"));
        String metric = upper(stringParam(params, "metric"));
        if (!StringUtils.hasText(metric)) {
            metric = "TOTWORKER";
        }

        List<String> classCodes = resolveClassCodes(params);
        if (classCodes.size() > MAX_CLASS_CODES) {
            classCodes = classCodes.subList(0, MAX_CLASS_CODES);
        }

        List<String> labels = years.stream().map(String::valueOf).toList();
        List<Double> values = new ArrayList<>();
        Integer lastYearWithData = null;
        List<Integer> failedYears = new ArrayList<>();

        List<String> notices = new ArrayList<>();
        if (classCodes.isEmpty()) {
            // 왜: 사용자가 산업 분류를 말하지 않아도 "일단 보이게" 해야 합니다.
            //     폴백 기본값으로 ICT를 사용하고, 그래도 코드가 없으면 빈 결과로 진행합니다.
            classCodes = majorIndustryMappingService.getSgisClassCodesByCategory().getOrDefault("ICT", List.of());
            if (!classCodes.isEmpty()) {
                notices.add("산업 분류가 없어 기본값(ICT)으로 조회했습니다.");
            } else {
                notices.add("산업 분류 정보를 찾지 못해 빈 결과로 표시됩니다.");
            }
        }

        for (Integer y : years) {
            long sum = 0L;
            boolean hasAny = false;
            for (String code : classCodes) {
                try {
                    SgisClient.CompanyStats s = sgisCompanyCacheService.getCompanyStats(String.valueOf(y), admCd, code);
                    Long v = "CORPCNT".equals(metric) ? s.corpCnt() : s.totWorker();
                    if (v != null) {
                        sum += v;
                        hasAny = true;
                    }
                } catch (Exception e) {
                    // 왜: 연도/코드 일부가 실패해도 전체를 "실패"로 만들지 않고, 가능한 값만 합산합니다.
                    //     (완전 실패는 아래에서 1년치 폴백으로 처리)
                    if (!failedYears.contains(y)) {
                        failedYears.add(y);
                    }
                    log.debug("SGIS 조회 실패(무시): year={}, admCd={}, classCode={}, metric={}, err={}", y, admCd, code, metric, safeMessage(e));
                }
            }
            Double value = hasAny ? (double) sum : null;
            values.add(value);
            if (value != null) {
                lastYearWithData = y;
            }
        }

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "SGIS");
        meta.put("admCd", admCd);
        meta.put("metric", metric);
        meta.put("classCodesCount", classCodes.size());
        if (!failedYears.isEmpty()) meta.put("failedYears", failedYears);

        String seriesLabel = "CORPCNT".equals(metric) ? "사업체 수" : "종사자 수";

        if (values.stream().allMatch(Objects::isNull)) {
            Integer fallbackYear = findLatestSgisYearWithData(admCd, classCodes, metric);
            if (fallbackYear != null) {
                Double fallback = null;
                try {
                    fallback = loadSgisMetric(fallbackYear, admCd, classCodes, metric);
                } catch (Exception e) {
                    log.debug("SGIS 폴백 연도 조회 실패(무시): year={}, admCd={}, err={}", fallbackYear, admCd, safeMessage(e));
                }
                if (fallback != null) {
                    labels = List.of(String.valueOf(fallbackYear));
                    values = List.of(fallback);
                    notices.add("이 질문은 현재 " + fallbackYear + "년 데이터로만 조회되었습니다.");
                } else {
                    labels = List.of();
                    values = List.of();
                    notices.add("해당 연도 데이터가 없습니다.");
                }
            } else {
                labels = List.of();
                values = List.of();
                notices.add("해당 연도 데이터가 없습니다.");
            }
        } else if (lastYearWithData != null && values.size() > 1) {
            notices.add("최신 가용 연도는 " + lastYearWithData + "년입니다.");
        }

        if (!notices.isEmpty()) {
            meta.put("noticeMessages", notices);
        }

        return new TimeSeriesResult(labels, values, seriesLabel, meta);
    }

    private List<String> resolveClassCodes(Map<String, Object> params) {
        // 우선순위: classCodes > category
        List<String> classCodes = stringListParam(params, "classCodes");
        if (!classCodes.isEmpty()) {
            return classCodes.stream().map(String::trim).filter(StringUtils::hasText).toList();
        }

        String category = stringParam(params, "category");
        if (StringUtils.hasText(category)) {
            return majorIndustryMappingService.getSgisClassCodesByCategory().getOrDefault(category.trim(), List.of());
        }
        return List.of();
    }

    private V2Result executeKosisPopulationSeries(Map<String, Object> params) throws IOException {
        String admCd = resolveAdmCd(stringParam(params, "admCd"));
        List<Integer> years = resolveYears(params.get("years"));
        String ageType = stringParam(params, "ageType");
        String gender = stringParam(params, "gender");

        List<String> labels = years.stream().map(String::valueOf).toList();
        List<Double> values = new ArrayList<>();
        Integer lastYearWithData = null;
        List<Integer> failedYears = new ArrayList<>();

        for (Integer y : years) {
            try {
                List<KosisPopulationRow> rows = kosisStatisticsService.getPopulation(String.valueOf(y), ageType, gender, admCd);
                long sum = 0L;
                for (KosisPopulationRow row : rows) {
                    sum += row.getPopulation();
                }
                Double value = rows.isEmpty() ? null : (double) sum;
                values.add(value);
                if (value != null) {
                    lastYearWithData = y;
                }
            } catch (Exception e) {
                // 왜: 특정 연도(예: 최신 연도)가 아직 제공되지 않으면 -200 같은 에러가 날 수 있습니다.
                //     이때 전체 실패로 떨어지지 않게 해당 연도만 비워서 계속 진행합니다.
                values.add(null);
                failedYears.add(y);
                log.debug("KOSIS 조회 실패(무시): year={}, admCd={}, ageType={}, gender={}, err={}", y, admCd, ageType, gender, safeMessage(e));
            }
        }

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "KOSIS");
        meta.put("admCd", admCd);
        meta.put("ageType", ageType);
        meta.put("gender", gender);
        if (!failedYears.isEmpty()) meta.put("failedYears", failedYears);

        List<String> notices = new ArrayList<>();
        if (values.stream().allMatch(Objects::isNull)) {
            Integer fallbackYear = findLatestKosisYearWithData(admCd, ageType, gender);
            if (fallbackYear != null) {
                try {
                    List<KosisPopulationRow> rows = kosisStatisticsService.getPopulation(String.valueOf(fallbackYear), ageType, gender, admCd);
                    if (!rows.isEmpty()) {
                        long sum = rows.stream().mapToLong(KosisPopulationRow::getPopulation).sum();
                        labels = List.of(String.valueOf(fallbackYear));
                        values = List.of((double) sum);
                        notices.add("이 질문은 현재 " + fallbackYear + "년 데이터로만 조회되었습니다.");
                    } else {
                        labels = List.of();
                        values = List.of();
                        notices.add("해당 연도 데이터가 없습니다.");
                    }
                } catch (Exception e) {
                    labels = List.of();
                    values = List.of();
                    notices.add("해당 연도 데이터가 없습니다.");
                    log.debug("KOSIS 폴백 연도 조회 실패(무시): year={}, admCd={}, err={}", fallbackYear, admCd, safeMessage(e));
                }
            } else {
                labels = List.of();
                values = List.of();
                notices.add("해당 연도 데이터가 없습니다.");
            }
        } else if (lastYearWithData != null && values.size() > 1) {
            notices.add("최신 가용 연도는 " + lastYearWithData + "년입니다.");
        }

        if (!notices.isEmpty()) {
            meta.put("noticeMessages", notices);
        }

        return new TimeSeriesResult(labels, values, "인구 수", meta);
    }

    private V2Result executeInternalTop(Map<String, Object> params, boolean employment) {
        String campus = normalizeCampus(stringParam(params, "campus"));
        List<String> notices = new ArrayList<>();
        if (!StringUtils.hasText(campus)) {
            // 왜: 사용자가 캠퍼스를 명시하지 않아도 "추가 질문" 없이 바로 결과를 보여줘야 합니다.
            //     따라서 첫 번째 캠퍼스를 기본값으로 잡고, 안내 문구(Notice)만 남깁니다.
            campus = pickDefaultCampus();
            notices.add("캠퍼스가 없어 기본값(" + campus + ")으로 조회했습니다.");
        }
        int top = resolveTop(intParam(params, "top"), 10);

        List<InternalStatisticsService.DepartmentRate> rows = employment
                ? internalStatisticsService.getTopEmploymentRates(campus, top)
                : internalStatisticsService.getTopAdmissionFillRates(campus, top);

        String valueColumn = employment ? "취업률(%)" : "입학충원률(%)";
        List<String> columns = List.of("학과", valueColumn);

        List<List<Object>> tableRows = new ArrayList<>();
        for (InternalStatisticsService.DepartmentRate r : rows) {
            tableRows.add(List.of(r.dept(), round2(r.rate())));
        }

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "내부 엑셀");
        meta.put("campus", campus);
        meta.put("top", top);
        meta.put("metric", employment ? "employmentRate" : "fillRate");
        if (!notices.isEmpty()) {
            meta.put("noticeMessages", notices);
        }

        return new TableResult(columns, tableRows, meta);
    }

    private V2Result executeInternalEmploymentSeries(Map<String, Object> params) {
        // 왜: "우리 IT학과 취업률 5년치"처럼 시계열 분석을 하려면,
        //     내부 엑셀(연도별 파일)을 연도 기준으로 찾아서 같은 방식으로 집계해야 합니다.
        List<Integer> years = resolveYears(params.get("years"));
        String campus = normalizeCampus(stringParam(params, "campus"));
        String dept = normalizeDept(stringParam(params, "dept"));
        String category = stringParam(params, "category");

        List<String> labels = years.stream().map(String::valueOf).toList();
        List<Double> values = new ArrayList<>();
        Integer lastYearWithData = null;

        List<Integer> missingYears = new ArrayList<>();
        for (Integer y : years) {
            List<InternalStatisticsService.EmploymentStat> stats = internalStatisticsService.getEmploymentStatsForYear(y);
            if (stats.isEmpty()) {
                missingYears.add(y);
                values.add(null);
                continue;
            }

            List<InternalStatisticsService.EmploymentStat> filtered = (campus == null)
                    ? stats
                    : stats.stream().filter(r -> campus.equals(r.campus())).toList();

            Double value;
            if (StringUtils.hasText(dept)) {
                value = average(filtered.stream()
                        .filter(r -> normalizeDept(r.dept()).equals(dept))
                        .map(InternalStatisticsService.EmploymentStat::employmentRate)
                        .toList());
            } else if (StringUtils.hasText(category)) {
                String desired = category.trim();
                value = average(filtered.stream()
                        .filter(r -> majorIndustryMappingService
                                .findCategoryByCampusAndDept(r.campus(), r.dept())
                                .map(desired::equals)
                                .orElse(false))
                        .map(InternalStatisticsService.EmploymentStat::employmentRate)
                        .toList());
            } else {
                value = average(filtered.stream()
                        .map(InternalStatisticsService.EmploymentStat::employmentRate)
                        .toList());
            }

            values.add(value);
            if (value != null) {
                lastYearWithData = y;
            }
        }

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "내부 엑셀");
        if (StringUtils.hasText(campus)) meta.put("campus", campus);
        if (StringUtils.hasText(dept)) meta.put("dept", dept);
        if (StringUtils.hasText(category)) meta.put("category", category);
        if (!missingYears.isEmpty()) meta.put("missingYears", missingYears);

        String seriesLabel = "취업률(%)";
        List<String> notices = new ArrayList<>();
        if (values.stream().allMatch(Objects::isNull)) {
            Integer fallbackYear = resolveLatestEmploymentYear();
            if (fallbackYear != null) {
                List<InternalStatisticsService.EmploymentStat> stats = internalStatisticsService.getEmploymentStatsForYear(fallbackYear);
                Double value = average(stats.stream()
                        .filter(r -> campus == null || campus.equals(r.campus()))
                        .filter(r -> !StringUtils.hasText(dept) || normalizeDept(r.dept()).equals(dept))
                        .filter(r -> !StringUtils.hasText(category) || majorIndustryMappingService
                                .findCategoryByCampusAndDept(r.campus(), r.dept())
                                .map(category.trim()::equals)
                                .orElse(false))
                        .map(InternalStatisticsService.EmploymentStat::employmentRate)
                        .toList());
                if (value != null) {
                    labels = List.of(String.valueOf(fallbackYear));
                    values = List.of(value);
                    notices.add("내부 취업률은 단일 연도(" + fallbackYear + "년) 데이터만 가용합니다.");
                } else {
                    labels = List.of();
                    values = List.of();
                    notices.add("해당 연도 데이터가 없습니다.");
                }
            }
        } else if (lastYearWithData != null && values.size() > 1) {
            notices.add("최신 가용 연도는 " + lastYearWithData + "년입니다.");
        }

        if (!notices.isEmpty()) {
            meta.put("noticeMessages", notices);
        }

        return new TimeSeriesResult(labels, values, seriesLabel, meta);
    }

    private V2Result executeChemist(StatisticsAiV2Plan.Step step, Map<String, V2Result> results) {
        String op = upper(step.op());
        Map<String, Object> params = step.params() == null ? Map.of() : step.params();

        return switch (op) {
            case StatisticsAiV2Ops.CHEMIST_CORRELATION -> executeCorrelation(params, results);
            case StatisticsAiV2Ops.CHEMIST_GROWTH_RATE -> executeGrowthRate(params, results);
            case StatisticsAiV2Ops.CHEMIST_DELTA_POINTS -> executeDeltaPoints(params, results);
            default -> throw new IllegalArgumentException("지원하지 않는 CHEMIST op 입니다. op=" + step.op());
        };
    }

    private V2Result executeCorrelation(Map<String, Object> params, Map<String, V2Result> results) {
        String xRef = stringParam(params, "xRef");
        String yRef = stringParam(params, "yRef");
        // 왜: 프롬프트/모델에 따라 leftRef/rightRef로 내려오는 경우가 있어, 별칭을 허용합니다.
        if (!StringUtils.hasText(xRef)) {
            xRef = stringParam(params, "leftRef");
        }
        if (!StringUtils.hasText(yRef)) {
            yRef = stringParam(params, "rightRef");
        }
        if (!StringUtils.hasText(xRef) || !StringUtils.hasText(yRef)) {
            Map<String, Object> meta = new LinkedHashMap<>();
            meta.put("source", "CHEMIST");
            meta.put("type", "correlation");
            meta.put("noticeMessages", List.of("상관관계 계산에 필요한 시계열이 부족합니다."));
            Map<String, Object> values = new LinkedHashMap<>();
            values.put("correlation", null);
            values.put("pairs", 0);
            values.put("labels", List.of());
            return new ObjectResult(values, meta);
        }

        TimeSeriesResult x = requireTimeSeries(results, xRef);
        TimeSeriesResult y = requireTimeSeries(results, yRef);

        AlignedSeries aligned = alignForCorrelation(x, y);
        if (aligned.labels.size() < 2) {
            Map<String, Object> meta = new LinkedHashMap<>();
            meta.put("source", "CHEMIST");
            meta.put("type", "correlation");
            meta.put("xRef", xRef);
            meta.put("yRef", yRef);
            meta.put("noticeMessages", List.of("상관관계 계산을 위한 공통 연도 데이터가 부족합니다."));
            Map<String, Object> values = new LinkedHashMap<>();
            values.put("correlation", null);
            values.put("pairs", aligned.labels.size());
            values.put("labels", aligned.labels);
            return new ObjectResult(values, meta);
        }

        double r = pearson(aligned.leftValues, aligned.rightValues);

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "CHEMIST");
        meta.put("type", "correlation");
        meta.put("xRef", xRef);
        meta.put("yRef", yRef);

        Map<String, Object> values = new LinkedHashMap<>();
        values.put("correlation", round4(r));
        values.put("pairs", aligned.labels.size());
        values.put("labels", aligned.labels);

        return new ObjectResult(values, meta);
    }

    private V2Result executeDeltaPoints(Map<String, Object> params, Map<String, V2Result> results) {
        String seriesRef = stringParam(params, "seriesRef");
        if (!StringUtils.hasText(seriesRef)) {
            throw new IllegalArgumentException("seriesRef는 필수입니다.");
        }

        TimeSeriesResult ts = requireTimeSeries(results, seriesRef);
        Delta d = deltaPoints(ts.labels, ts.values);

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "CHEMIST");
        meta.put("type", "deltaPoints");
        meta.put("seriesRef", seriesRef);

        Map<String, Object> values = new LinkedHashMap<>();
        values.put("startLabel", d.startLabel);
        values.put("endLabel", d.endLabel);
        values.put("startValue", d.startValue);
        values.put("endValue", d.endValue);
        values.put("deltaPoints", round2(d.deltaPoints));

        return new ObjectResult(values, meta);
    }

    private V2Result executeGrowthRate(Map<String, Object> params, Map<String, V2Result> results) {
        String seriesRef = stringParam(params, "seriesRef");
        if (!StringUtils.hasText(seriesRef)) {
            throw new IllegalArgumentException("seriesRef는 필수입니다.");
        }

        TimeSeriesResult ts = requireTimeSeries(results, seriesRef);
        Growth g = growthRate(ts.labels, ts.values);

        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("source", "CHEMIST");
        meta.put("type", "growthRate");
        meta.put("seriesRef", seriesRef);

        Map<String, Object> values = new LinkedHashMap<>();
        values.put("startLabel", g.startLabel);
        values.put("endLabel", g.endLabel);
        values.put("startValue", g.startValue);
        values.put("endValue", g.endValue);
        values.put("growthRatePercent", round2(g.ratePercent));

        return new ObjectResult(values, meta);
    }

    private Growth growthRate(List<String> labels, List<Double> values) {
        int start = firstNonNullIndex(values);
        int end = lastNonNullIndex(values);
        if (start < 0 || end < 0 || end <= start) {
            return new Growth(null, null, null, null, 0.0);
        }

        double startValue = Objects.requireNonNull(values.get(start));
        double endValue = Objects.requireNonNull(values.get(end));
        double rate = (startValue == 0.0) ? 0.0 : ((endValue - startValue) / startValue) * 100.0;
        return new Growth(labels.get(start), labels.get(end), startValue, endValue, rate);
    }

    private Delta deltaPoints(List<String> labels, List<Double> values) {
        int start = firstNonNullIndex(values);
        int end = lastNonNullIndex(values);
        if (start < 0 || end < 0 || end <= start) {
            return new Delta(null, null, null, null, 0.0);
        }

        double startValue = Objects.requireNonNull(values.get(start));
        double endValue = Objects.requireNonNull(values.get(end));
        return new Delta(labels.get(start), labels.get(end), startValue, endValue, endValue - startValue);
    }

    private int firstNonNullIndex(List<Double> values) {
        for (int i = 0; i < values.size(); i++) {
            if (values.get(i) != null) return i;
        }
        return -1;
    }

    private int lastNonNullIndex(List<Double> values) {
        for (int i = values.size() - 1; i >= 0; i--) {
            if (values.get(i) != null) return i;
        }
        return -1;
    }

    private AlignedSeries alignForChart(TimeSeriesResult left, TimeSeriesResult right) {
        return align(left, right, 1, "차트 생성");
    }

    private AlignedSeries alignForCorrelation(TimeSeriesResult left, TimeSeriesResult right) {
        return align(left, right, 2, "상관관계 계산");
    }

    private AlignedSeries align(TimeSeriesResult left, TimeSeriesResult right, int minPairs, String reason) {
        Map<String, Double> leftMap = new LinkedHashMap<>();
        for (int i = 0; i < left.labels.size(); i++) {
            Double v = left.values.get(i);
            if (v != null) {
                leftMap.put(left.labels.get(i), v);
            }
        }

        List<String> labels = new ArrayList<>();
        List<Double> leftValues = new ArrayList<>();
        List<Double> rightValues = new ArrayList<>();

        for (int i = 0; i < right.labels.size(); i++) {
            String label = right.labels.get(i);
            Double rv = right.values.get(i);
            if (rv == null) continue;
            Double lv = leftMap.get(label);
            if (lv == null) continue;

            labels.add(label);
            leftValues.add(lv);
            rightValues.add(rv);
        }

        if (labels.size() < minPairs) {
            // 왜: 가능한 데이터만 보여줘야 하므로, 부족할 땐 빈 결과를 반환합니다.
            return new AlignedSeries(List.of(), List.of(), List.of());
        }

        return new AlignedSeries(labels, leftValues, rightValues);
    }

    private double pearson(List<Double> x, List<Double> y) {
        if (x.size() != y.size() || x.size() < 2) {
            throw new IllegalArgumentException("상관계수 계산을 위한 데이터 쌍이 부족합니다.");
        }

        int n = x.size();
        double meanX = x.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        double meanY = y.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);

        double num = 0.0;
        double denX = 0.0;
        double denY = 0.0;

        for (int i = 0; i < n; i++) {
            double dx = x.get(i) - meanX;
            double dy = y.get(i) - meanY;
            num += dx * dy;
            denX += dx * dx;
            denY += dy * dy;
        }

        double den = Math.sqrt(denX * denY);
        if (den == 0.0) return 0.0;
        return num / den;
    }

    private String stepKey(StatisticsAiV2Plan.Step step) {
        return StringUtils.hasText(step.as()) ? step.as().trim() : step.id().trim();
    }

    private TimeSeriesResult requireTimeSeries(Map<String, V2Result> results, String ref) {
        V2Result r = results.get(ref);
        if (r == null) {
            throw new IllegalArgumentException("참조 결과가 없습니다. ref=" + ref);
        }
        if (r instanceof TimeSeriesResult ts) {
            return ts;
        }
        throw new IllegalArgumentException("시계열 결과가 아닙니다. ref=" + ref + ", kind=" + r.kind());
    }

    private TableResult requireTable(Map<String, V2Result> results, String ref) {
        V2Result r = results.get(ref);
        if (r == null) {
            throw new IllegalArgumentException("참조 결과가 없습니다. ref=" + ref);
        }
        if (r instanceof TableResult tr) {
            return tr;
        }
        throw new IllegalArgumentException("표 결과가 아닙니다. ref=" + ref + ", kind=" + r.kind());
    }

    private String buildModelPrompt(String userPrompt, Map<String, Object> context, StatisticsAiV2CatalogResponse catalog) {
        String contextText = (context == null || context.isEmpty()) ? "" : ("컨텍스트(JSON): " + toCompactJson(context));
        String catalogText = toCompactJson(catalog);
        String dataStoreHint = buildDataStoreHintForPrompt(userPrompt, context);

        return """
                당신은 'AI 통계 데이터 가이드(Guide)'입니다.
                사용자의 질문을 분석하여 최적의 통계 소스를 조합하고 시각화 계획을 세웁니다.

                [핵심 철학]
                - 당신(LLM)은 계획(Plan), 조합(Combine), 데이터 가이드(Guide) 역할입니다.
                - 사용자가 모호하게 질문하더라도 시스템이 가진 데이터를 최대한 활용해 '뭐라도' 보여주세요.
                - 실제 수치는 서버가 KOSIS/SGIS/내부엑셀에서 가져오므로 숫자를 조작하지 마세요.

                [중요 규칙]
                - 반드시 JSON 객체만 출력하세요. (설명/코드블록 금지)
                - [시각화 필수 규칙]: DESIGNER_CHART의 params.seriesRefs는 반드시 이전 step의 'as' 또는 'id' 값들을 **배열([])**로 포함해야 합니다.
                - [기본값 우선]: 연도/지역 등이 없으면 '최신 5년', '서울(11)' 등 카탈로그의 권장값을 사용해 즉시 EXECUTE 하세요. 되물음(CLARIFY)은 데이터가 아예 없을 때만 하세요.
                - [우리 데이터 강조]: "우리", "학교", "내부" 등의 표현이 있다면 INTERNAL_* 연산(내부 취업/입학 통계)을 최우선으로 배치하세요.
                - [풍부한 결과]: 가능하면 시계열 조회와 TOP N 조회를 조합하여 풍부한 리포트를 구성하세요.

                [카탈로그(참고)]
                %s

                [데이터 스토어 힌트(참고)]
                %s

                [allowlist op]
                - ANALYST:
                  - %s (params: admCd, years, metric(totWorker|corpCnt), classCodes 또는 category)
                  - %s (params: years, ageType, gender, admCd)
                  - %s (params: campus, top)
                  - %s (params: campus, top)
                  - %s (params: years, campus(선택), dept(선택) 또는 category(선택))
                - CHEMIST:
                  - %s (params: xRef, yRef)
                  - %s (params: seriesRef)
                  - %s (params: seriesRef)
                - DESIGNER:
                  - %s (params: chartType(line|dual_axis_line|bar), title, seriesRefs)

                [출력 JSON 형식]
                - 실행(EXECUTE):
                  {
                    "action":"EXECUTE",
                    "steps":[
                      {"id":"a1","agent":"ANALYST","op":"SGIS_METRIC_SERIES","as":"itWorkers","params":{"admCd":"11","years":[2020,2021,2022,2023],"metric":"totWorker","category":"ICT"}},
                      {"id":"d1","agent":"DESIGNER","op":"DESIGNER_CHART","as":"chart1","params":{"chartType":"line","title":"서울 ICT 종사자 수 변화","seriesRefs":["itWorkers"]}}
                    ]
                  }
                - 되물음(CLARIFY): 데이터가 정말 부족할 때만 사용하며, 구체적인 선택지를 제안하세요.
                  {"action":"CLARIFY","question":"어느 대상을 볼까요? '전국' 혹은 '서울' 지역을 선택하거나 특정 '학과'를 말씀해 주세요.","fields":["admCd"]}

                %s

                [사용자 질문]
                %s
                """.formatted(
                catalogText,
                dataStoreHint,
                StatisticsAiV2Ops.SGIS_METRIC_SERIES,
                StatisticsAiV2Ops.KOSIS_POPULATION_SERIES,
                StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_TOP,
                StatisticsAiV2Ops.INTERNAL_ADMISSION_TOP,
                StatisticsAiV2Ops.INTERNAL_EMPLOYMENT_SERIES,
                StatisticsAiV2Ops.CHEMIST_CORRELATION,
                StatisticsAiV2Ops.CHEMIST_GROWTH_RATE,
                StatisticsAiV2Ops.CHEMIST_DELTA_POINTS,
                StatisticsAiV2Ops.DESIGNER_CHART,
                contextText,
                userPrompt
        );
    }

    private String buildDataStoreHintForPrompt(String userPrompt, Map<String, Object> context) {
        try {
            StatisticsAiV2DataStoreSearchResponse r = dataStoreService.search(userPrompt, context);
            Map<String, Object> compact = new LinkedHashMap<>();
            compact.put("dataSources", r.dataSources());
            compact.put("operations", r.operations());
            Object years = (r.hints() == null) ? null : r.hints().get("internalEmploymentAvailableYears");
            if (years != null) {
                compact.put("internalEmploymentAvailableYears", years);
            }
            String json = objectMapper.writeValueAsString(compact);
            return safeTruncate(json, 1200);
        } catch (Exception e) {
            return "- (데이터 스토어 힌트를 만들지 못했습니다)";
        }
    }

    private StatisticsAiV2Plan parseModelPlan(String modelText) {
        String json = extractJsonObject(modelText);
        try {
            JsonNode node = objectMapper.readTree(json);
            String actionText = upper(node.path("action").asText(null));
            if (!StringUtils.hasText(actionText)) {
                return new StatisticsAiV2Plan(StatisticsAiV2Plan.Action.CLARIFY, "어떤 통계를 원하시는지 조금 더 알려주세요.", List.of("prompt"), null, null, List.of(), json);
            }

            StatisticsAiV2Plan.Action action;
            try {
                action = StatisticsAiV2Plan.Action.valueOf(actionText);
            } catch (IllegalArgumentException e) {
                action = StatisticsAiV2Plan.Action.UNSUPPORTED;
            }

            if (action == StatisticsAiV2Plan.Action.CLARIFY) {
                String question = node.path("question").asText("추가 정보가 필요합니다.");
                List<String> fields = readStringList(node.get("fields"));
                List<StatisticsAiV2Plan.Step> steps = List.of();
                try {
                    // 왜: 모델이 CLARIFY를 주더라도, steps를 함께 주는 경우가 많습니다.
                    //     사용자는 되물음 없이 바로 결과를 원하므로, steps가 있으면 실행 쪽으로 활용합니다.
                    steps = readSteps(node.get("steps"));
                } catch (Exception ignore) {
                    // noop
                }
                return new StatisticsAiV2Plan(action, question, fields, null, null, steps, json);
            }

            if (action == StatisticsAiV2Plan.Action.UNSUPPORTED) {
                String message = node.path("message").asText("지원하지 않는 질문입니다.");
                List<String> examples = readStringList(node.get("examples"));
                return new StatisticsAiV2Plan(action, null, null, message, examples, List.of(), json);
            }

            List<StatisticsAiV2Plan.Step> steps = readSteps(node.get("steps"));
            return new StatisticsAiV2Plan(action, null, null, null, null, steps, json);
        } catch (Exception e) {
            throw new IllegalStateException("LLM 실행계획(JSON)을 파싱하지 못했습니다. 응답=" + safeTruncate(modelText, 300), e);
        }
    }

    private List<StatisticsAiV2Plan.Step> readSteps(JsonNode node) {
        if (node == null || node.isNull()) return List.of();
        if (!node.isArray()) return List.of();

        List<StatisticsAiV2Plan.Step> steps = new ArrayList<>();
        for (JsonNode n : node) {
            String id = n.path("id").asText(null);
            String agentText = upper(n.path("agent").asText(null));
            String op = n.path("op").asText(null);
            String as = n.path("as").asText(null);
            Map<String, Object> params = readObjectMap(n.get("params"));

            StatisticsAiV2Plan.Agent agent;
            try {
                agent = StatisticsAiV2Plan.Agent.valueOf(agentText);
            } catch (Exception e) {
                throw new IllegalArgumentException("지원하지 않는 agent 입니다. agent=" + agentText);
            }

            if (!StringUtils.hasText(id) || !StringUtils.hasText(op)) {
                throw new IllegalArgumentException("step.id/op는 필수입니다.");
            }

            steps.add(new StatisticsAiV2Plan.Step(id.trim(), agent, op.trim(), StringUtils.hasText(as) ? as.trim() : null, params));
        }
        return List.copyOf(steps);
    }

    private String extractJsonObject(String text) {
        if (!StringUtils.hasText(text)) {
            throw new IllegalStateException("LLM 응답이 비어 있습니다.");
        }

        String cleaned = text.trim();
        cleaned = cleaned.replace("```json", "").replace("```", "").trim();

        // 왜: 모델이 JSON 앞뒤에 설명을 붙이거나(혹은 잘린 JSON) 응답하면
        //     단순히 "첫 { ~ 마지막 }"로 자르면 실패할 수 있습니다. (배열 '[]' 미닫힘, 문자열 내부 괄호 등)
        //     문자열(따옴표) 영역을 고려하고, '{}'뿐 아니라 '[]'까지 스택으로 추적해
        //     "첫 번째 JSON 객체"를 최대한 복구해서 파싱을 시도합니다.

        int start = cleaned.indexOf('{');
        if (start < 0) {
            throw new IllegalStateException("LLM 응답에서 JSON 객체를 찾지 못했습니다. 응답=" + safeTruncate(cleaned, 300));
        }

        StringBuilder out = new StringBuilder();
        Deque<Character> expectedClosers = new ArrayDeque<>();

        boolean inString = false;
        boolean escaped = false;

        for (int i = start; i < cleaned.length(); i++) {
            char c = cleaned.charAt(i);

            if (inString) {
                out.append(c);
                if (escaped) {
                    escaped = false;
                    continue;
                }
                if (c == '\\') {
                    escaped = true;
                    continue;
                }
                if (c == '"') {
                    inString = false;
                }
                continue;
            }

            if (c == '"') {
                inString = true;
                out.append(c);
                continue;
            }

            if (c == '{') {
                expectedClosers.push('}');
                out.append(c);
                continue;
            }

            if (c == '[') {
                expectedClosers.push(']');
                out.append(c);
                continue;
            }

            if (c == '}' || c == ']') {
                // 왜: ']'가 닫히기 전에 '}'가 먼저 나오면(순서 꼬임/잘림),
                //     닫힘이 빠진 것들을 현재 위치 앞에 끼워 넣어 최대한 복구합니다.
                if (!expectedClosers.isEmpty()) {
                    if (c != expectedClosers.peek() && expectedClosers.contains(c)) {
                        while (!expectedClosers.isEmpty() && expectedClosers.peek() != c) {
                            out.append(expectedClosers.pop());
                        }
                    }
                    if (!expectedClosers.isEmpty() && c == expectedClosers.peek()) {
                        expectedClosers.pop();
                    }
                }

                out.append(c);
                if (expectedClosers.isEmpty()) {
                    return out.toString();
                }
                continue;
            }

            out.append(c);
        }

        // 왜: 응답이 끝까지 왔는데도 닫힘 문자가 남아있다면(잘림),
        //     남은 닫힘을 붙여서 "파싱 가능한 JSON"으로 최대한 복구합니다.
        if (inString) {
            out.append('"');
        }
        while (!expectedClosers.isEmpty()) {
            out.append(expectedClosers.pop());
        }
        return out.toString();
    }

    private String safeTruncate(String text, int max) {
        if (text == null) return null;
        if (text.length() <= max) return text;
        return text.substring(0, max) + "...";
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

    private String toCompactJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return String.valueOf(value);
        }
    }

    private String safeMessage(Exception e) {
        String m = e.getMessage();
        return StringUtils.hasText(m) ? m : e.getClass().getSimpleName();
    }

    private String upper(String v) {
        return v == null ? null : v.trim().toUpperCase(Locale.ROOT);
    }

    private String stringParam(Map<String, Object> params, String key) {
        if (params == null) return null;
        Object v = params.get(key);
        if (v == null) return null;
        String s = String.valueOf(v).trim();
        return StringUtils.hasText(s) ? s : null;
    }

    private Integer intParam(Map<String, Object> params, String key) {
        if (params == null) return null;
        Object v = params.get(key);
        if (v == null) return null;
        if (v instanceof Number n) return n.intValue();
        if (v instanceof String s && s.trim().matches("\\d+")) return Integer.parseInt(s.trim());
        return null;
    }

    private List<String> stringListParam(Map<String, Object> params, String key) {
        if (params == null) return List.of();
        Object v = params.get(key);
        if (v == null) return List.of();
        if (v instanceof List<?> list) {
            return list.stream()
                    .filter(Objects::nonNull)
                    .map(String::valueOf)
                    .map(String::trim)
                    .filter(StringUtils::hasText)
                    .toList();
        }
        if (v instanceof String s && StringUtils.hasText(s)) {
            return List.of(s.trim());
        }
        return List.of();
    }

    private List<Integer> resolveYears(Object yearsValue) {
        // 왜: v2에서 years를 너무 크게 잡으면 외부 API 호출이 폭증할 수 있으니 상한을 둡니다.
        List<Integer> years = new ArrayList<>();

        if (yearsValue instanceof List<?> list) {
            for (Object o : list) {
                Integer y = (o instanceof Number n) ? n.intValue() : tryParseInt(o);
                if (y != null) years.add(y);
            }
        } else {
            Integer y = (yearsValue instanceof Number n) ? n.intValue() : tryParseInt(yearsValue);
            if (y != null) years.add(y);
        }

        if (years.isEmpty()) {
            int now = Year.now().getValue();
            years = List.of(now - 1, now - 2, now - 3, now - 4);
        }

        years = years.stream().distinct().sorted().toList();
        if (years.size() > MAX_YEARS) {
            years = years.subList(years.size() - MAX_YEARS, years.size());
        }

        return years;
    }

    private Integer resolveLatestRecommendedYear() {
        List<Integer> recommended = catalogService.getCatalog().recommendedYears();
        if (recommended != null && !recommended.isEmpty()) {
            return recommended.stream().max(Integer::compareTo).orElse(null);
        }
        return Year.now().getValue() - 1;
    }

    private Integer findLatestKosisYearWithData(String admCd, String ageType, String gender) {
        // 왜: 카탈로그 추천 연도(now-1..now-8)는 "항상 존재하는 데이터"가 아닐 수 있습니다. (예: 2025 미제공)
        //     따라서 실제 호출을 해보면서 "성공하는 최신 연도"를 찾아 1년치라도 보여줍니다.
        List<Integer> candidates = catalogService.getCatalog().recommendedYears();
        if (candidates == null || candidates.isEmpty()) {
            int now = Year.now().getValue();
            candidates = List.of(now - 1, now - 2, now - 3, now - 4, now - 5, now - 6, now - 7, now - 8);
        }

        List<Integer> yearsDesc = candidates.stream()
                .filter(Objects::nonNull)
                .distinct()
                .sorted((a, b) -> Integer.compare(b, a))
                .toList();

        for (Integer y : yearsDesc) {
            try {
                List<KosisPopulationRow> rows = kosisStatisticsService.getPopulation(String.valueOf(y), ageType, gender, admCd);
                if (rows != null && !rows.isEmpty()) {
                    return y;
                }
            } catch (Exception e) {
                log.debug("KOSIS 최신 연도 탐색 실패(무시): year={}, admCd={}, err={}", y, admCd, safeMessage(e));
            }
        }
        return null;
    }

    private Integer findLatestSgisYearWithData(String admCd, List<String> classCodes, String metric) {
        // 왜: SGIS도 연도별 제공 범위가 고정이 아니어서, 실제 조회가 되는 최신 연도를 찾아 1년치라도 보여줍니다.
        if (classCodes == null || classCodes.isEmpty()) {
            return null;
        }
        List<Integer> candidates = catalogService.getCatalog().recommendedYears();
        if (candidates == null || candidates.isEmpty()) {
            int now = Year.now().getValue();
            candidates = List.of(now - 1, now - 2, now - 3, now - 4, now - 5, now - 6, now - 7, now - 8);
        }

        List<Integer> yearsDesc = candidates.stream()
                .filter(Objects::nonNull)
                .distinct()
                .sorted((a, b) -> Integer.compare(b, a))
                .toList();

        for (Integer y : yearsDesc) {
            try {
                Double v = loadSgisMetric(y, admCd, classCodes, metric);
                if (v != null) {
                    return y;
                }
            } catch (Exception e) {
                log.debug("SGIS 최신 연도 탐색 실패(무시): year={}, admCd={}, err={}", y, admCd, safeMessage(e));
            }
        }
        return null;
    }

    private Integer resolveLatestEmploymentYear() {
        List<Integer> years = internalStatisticsService.getAvailableEmploymentYears();
        if (years == null || years.isEmpty()) return null;
        return years.stream().max(Integer::compareTo).orElse(null);
    }

    private Double loadSgisMetric(int year, String admCd, List<String> classCodes, String metric) throws IOException {
        if (classCodes == null || classCodes.isEmpty()) return null;
        long sum = 0L;
        boolean hasAny = false;
        for (String code : classCodes) {
            SgisClient.CompanyStats s = sgisCompanyCacheService.getCompanyStats(String.valueOf(year), admCd, code);
            Long v = "CORPCNT".equals(metric) ? s.corpCnt() : s.totWorker();
            if (v != null) {
                sum += v;
                hasAny = true;
            }
        }
        return hasAny ? (double) sum : null;
    }

    private Integer tryParseInt(Object v) {
        if (v == null) return null;
        String s = String.valueOf(v).trim();
        if (!s.matches("\\d+")) return null;
        return Integer.parseInt(s);
    }

    private Double tryParseDouble(Object v) {
        if (v == null) return null;
        try {
            return Double.parseDouble(String.valueOf(v));
        } catch (Exception e) {
            return null;
        }
    }

    private String normalizeCampus(String campus) {
        if (!StringUtils.hasText(campus)) return null;
        String trimmed = campus.trim();
        if (trimmed.endsWith("캠퍼스")) {
            return trimmed.substring(0, trimmed.length() - "캠퍼스".length()).trim();
        }
        return trimmed;
    }

    private String normalizeDept(String dept) {
        if (!StringUtils.hasText(dept)) return null;
        String trimmed = dept.trim();
        int index = trimmed.indexOf('(');
        if (index > 0) {
            return trimmed.substring(0, index).trim();
        }
        return trimmed;
    }

    private Double average(List<Double> values) {
        if (values == null || values.isEmpty()) {
            return null;
        }
        double avg = values.stream().mapToDouble(Double::doubleValue).average().orElse(Double.NaN);
        return Double.isNaN(avg) ? null : avg;
    }

    private int resolveTop(Integer top, int defaultTop) {
        int resolved = top == null ? defaultTop : top;
        if (resolved < 1) resolved = 1;
        if (resolved > 30) resolved = 30;
        return resolved;
    }

    private String pickDefaultCampus() {
        // 왜: UI에서 "캠퍼스"를 따로 선택하지 않아도 결과가 나오게 하려면,
        //     시스템이 알아서 기본 캠퍼스를 하나 잡아줘야 합니다.
        //     여기서는 카탈로그(캠퍼스 그룹)에서 첫 번째 캠퍼스를 사용합니다.
        try {
            StatisticsAiV2CatalogResponse catalog = catalogService.getCatalog();
            if (catalog != null && catalog.campusGroups() != null) {
                for (MajorIndustryMappingService.CampusGroup group : catalog.campusGroups()) {
                    if (group == null || group.campuses() == null) continue;
                    for (String c : group.campuses()) {
                        String normalized = normalizeCampus(c);
                        if (StringUtils.hasText(normalized)) {
                            return normalized;
                        }
                    }
                }
            }
        } catch (Exception ignore) {
            // noop
        }
        // 마지막 안전망: 프로젝트에서 가장 흔히 쓰는 캠퍼스명을 기본값으로 둡니다.
        return "서울정수";
    }

    private String resolveAdmCd(String admCdOrName) {
        // 왜: 사용자가 "서울"처럼 이름으로 입력할 수 있어, 간단히 매핑합니다.
        if (!StringUtils.hasText(admCdOrName) || "전체".equals(admCdOrName)) {
            return "11";
        }

        String v = admCdOrName.trim().toLowerCase(Locale.KOREA);
        for (StatisticsAiV2CatalogResponse.AdmRegion r : catalogService.getCatalog().admRegions()) {
            String name = r.name() == null ? "" : r.name().toLowerCase(Locale.KOREA);
            if (name.contains(v) || v.contains(name)) {
                return r.admCd();
            }
        }

        return admCdOrName.trim();
    }

    private double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private double round4(double v) {
        return Math.round(v * 10000.0) / 10000.0;
    }

    private record StepResult(String key, V2Result result, Exception error) {
        static StepResult success(String key, V2Result result) {
            return new StepResult(key, result, null);
        }

        static StepResult fail(String key, Exception error) {
            return new StepResult(key, null, error);
        }
    }

    private record DesignerOutput(List<StatisticsAiQueryResponse.ChartSpec> charts, StatisticsAiQueryResponse.TableSpec table) {
    }

    private record Growth(String startLabel, String endLabel, Double startValue, Double endValue, double ratePercent) {
    }

    private record Delta(String startLabel, String endLabel, Double startValue, Double endValue, double deltaPoints) {
    }

    private record AlignedSeries(List<String> labels, List<Double> leftValues, List<Double> rightValues) {
    }

    private enum Kind {TIME_SERIES, TABLE, OBJECT}

    private sealed interface V2Result permits TimeSeriesResult, TableResult, ObjectResult {
        Kind kind();

        Map<String, Object> meta();
    }

    private record TimeSeriesResult(
            List<String> labels,
            List<Double> values,
            String seriesLabel,
            Map<String, Object> meta
    ) implements V2Result {
        @Override
        public Kind kind() {
            return Kind.TIME_SERIES;
        }
    }

    private record TableResult(
            List<String> columns,
            List<List<Object>> rows,
            Map<String, Object> meta
    ) implements V2Result {
        @Override
        public Kind kind() {
            return Kind.TABLE;
        }
    }

    private record ObjectResult(
            Map<String, Object> values,
            Map<String, Object> meta
    ) implements V2Result {
        @Override
        public Kind kind() {
            return Kind.OBJECT;
        }
    }
}
