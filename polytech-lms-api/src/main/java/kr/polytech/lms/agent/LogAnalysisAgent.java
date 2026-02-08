// polytech-lms-api/src/main/java/kr/polytech/lms/agent/LogAnalysisAgent.java
package kr.polytech.lms.agent;

import kr.polytech.lms.gcp.service.BigQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Log Analysis Agent
 * 로그 분석 및 이상 행위 탐지
 * Tech: Cloud Logging + BigQuery
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LogAnalysisAgent {

    private final BigQueryService bigQueryService;

    // 로그 버퍼 (분석 대기)
    private final Queue<LogEntry> logBuffer = new ConcurrentLinkedQueue<>();

    // 이상 행위 패턴
    private final Map<String, AnomalyPattern> anomalyPatterns = new ConcurrentHashMap<>();

    // 분석 결과 히스토리
    private final List<AnalysisResult> analysisHistory = Collections.synchronizedList(new ArrayList<>());

    // 탐지된 이상 행위
    private final List<AnomalyEvent> detectedAnomalies = Collections.synchronizedList(new ArrayList<>());

    // 통계
    private long totalLogsProcessed = 0;
    private long anomaliesDetected = 0;

    // 이상 탐지 패턴
    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
        "(union|select|insert|update|delete|drop|--|;|')", Pattern.CASE_INSENSITIVE);
    private static final Pattern XSS_PATTERN = Pattern.compile(
        "(<script|javascript:|onerror|onclick)", Pattern.CASE_INSENSITIVE);
    private static final Pattern PATH_TRAVERSAL_PATTERN = Pattern.compile(
        "(\\.\\./|\\.\\.\\\\|%2e%2e)", Pattern.CASE_INSENSITIVE);

    /**
     * 실시간 로그 분석 (10초마다)
     */
    @Scheduled(fixedRate = 10000)
    public void scheduledLogAnalysis() {
        if (!logBuffer.isEmpty()) {
            log.debug("Log Analysis Agent: 실시간 로그 분석");
            processLogBuffer();
        }
    }

    /**
     * 정기 통계 분석 (5분마다)
     */
    @Scheduled(fixedRate = 300000)
    public void scheduledStatisticalAnalysis() {
        log.debug("Log Analysis Agent: 통계 분석 수행");
        performStatisticalAnalysis();
    }

    /**
     * 일일 종합 분석 (매일 자정)
     */
    @Scheduled(cron = "0 0 0 * * *")
    public void scheduledDailyAnalysis() {
        log.info("Log Analysis Agent: 일일 종합 분석 시작");
        performDailyAnalysis();
    }

    /**
     * 로그 수집
     */
    public void collectLog(String level, String source, String message, Map<String, Object> metadata) {
        LogEntry entry = new LogEntry(level, source, message, metadata);
        logBuffer.offer(entry);

        // 심각한 로그는 즉시 분석
        if ("ERROR".equals(level) || "FATAL".equals(level)) {
            analyzeLogImmediately(entry);
        }
    }

    /**
     * 로그 버퍼 처리
     */
    private void processLogBuffer() {
        List<LogEntry> batch = new ArrayList<>();
        LogEntry entry;

        // 최대 100개씩 배치 처리
        int count = 0;
        while ((entry = logBuffer.poll()) != null && count < 100) {
            batch.add(entry);
            count++;
        }

        if (!batch.isEmpty()) {
            analyzeBatch(batch);
        }
    }

    /**
     * 배치 로그 분석
     */
    private void analyzeBatch(List<LogEntry> batch) {
        totalLogsProcessed += batch.size();

        for (LogEntry entry : batch) {
            // 보안 위협 패턴 검사
            checkSecurityPatterns(entry);

            // 비정상 행위 탐지
            checkAbnormalBehavior(entry);

            // 성능 이슈 탐지
            checkPerformanceIssues(entry);
        }

        log.debug("Log Analysis Agent: {}개 로그 분석 완료", batch.size());
    }

    /**
     * 즉시 로그 분석
     */
    private void analyzeLogImmediately(LogEntry entry) {
        log.warn("Log Analysis Agent: 긴급 로그 분석 - level={}, source={}",
            entry.level, entry.source);

        checkSecurityPatterns(entry);

        // 에러 로그 패턴 분석
        if (entry.message.contains("Exception") || entry.message.contains("Error")) {
            recordAnomaly("ERROR_SPIKE", "예외 발생: " + entry.source, "HIGH", entry);
        }
    }

    /**
     * 보안 패턴 검사
     */
    private void checkSecurityPatterns(LogEntry entry) {
        String message = entry.message;

        // SQL Injection 시도 탐지
        if (SQL_INJECTION_PATTERN.matcher(message).find()) {
            recordAnomaly("SQL_INJECTION_ATTEMPT", "SQL Injection 시도 감지", "CRITICAL", entry);
        }

        // XSS 시도 탐지
        if (XSS_PATTERN.matcher(message).find()) {
            recordAnomaly("XSS_ATTEMPT", "XSS 공격 시도 감지", "HIGH", entry);
        }

        // 경로 조작 시도 탐지
        if (PATH_TRAVERSAL_PATTERN.matcher(message).find()) {
            recordAnomaly("PATH_TRAVERSAL_ATTEMPT", "경로 조작 시도 감지", "HIGH", entry);
        }

        // 인증 실패 다중 시도
        if (message.contains("authentication failed") || message.contains("로그인 실패")) {
            checkMultipleAuthFailures(entry);
        }
    }

    /**
     * 다중 인증 실패 체크
     */
    private void checkMultipleAuthFailures(LogEntry entry) {
        String ip = (String) entry.metadata.getOrDefault("ip", "unknown");

        AnomalyPattern pattern = anomalyPatterns.computeIfAbsent(
            "AUTH_FAIL_" + ip,
            k -> new AnomalyPattern("AUTH_FAILURE", ip)
        );

        pattern.count++;
        pattern.lastSeen = System.currentTimeMillis();

        // 5분 내 5회 이상 실패 시 알림
        if (pattern.count >= 5 &&
            System.currentTimeMillis() - pattern.firstSeen < 300000) {
            recordAnomaly("BRUTE_FORCE_ATTEMPT",
                String.format("무차별 대입 공격 의심 - IP: %s, 시도: %d회", ip, pattern.count),
                "CRITICAL", entry);
            pattern.count = 0; // 리셋
        }
    }

    /**
     * 비정상 행위 탐지
     */
    private void checkAbnormalBehavior(LogEntry entry) {
        // 비정상 시간대 접속
        int hour = LocalDateTime.now().getHour();
        if (hour >= 2 && hour <= 5) {
            if (entry.message.contains("login") || entry.message.contains("로그인")) {
                recordAnomaly("OFF_HOURS_ACCESS", "비정상 시간대 접속 시도", "MEDIUM", entry);
            }
        }

        // 대량 데이터 조회
        if (entry.message.contains("bulk") || entry.message.contains("export")) {
            Object count = entry.metadata.get("recordCount");
            if (count instanceof Number && ((Number) count).intValue() > 10000) {
                recordAnomaly("BULK_DATA_ACCESS", "대량 데이터 접근 감지", "HIGH", entry);
            }
        }
    }

    /**
     * 성능 이슈 탐지
     */
    private void checkPerformanceIssues(LogEntry entry) {
        // 느린 쿼리 탐지
        Object duration = entry.metadata.get("duration");
        if (duration instanceof Number && ((Number) duration).longValue() > 3000) {
            recordAnomaly("SLOW_QUERY",
                String.format("느린 쿼리 감지: %dms", ((Number) duration).longValue()),
                "MEDIUM", entry);
        }

        // 메모리 경고
        if (entry.message.contains("OutOfMemory") || entry.message.contains("heap")) {
            recordAnomaly("MEMORY_WARNING", "메모리 경고", "HIGH", entry);
        }
    }

    /**
     * 이상 행위 기록
     */
    private void recordAnomaly(String type, String description, String severity, LogEntry entry) {
        AnomalyEvent event = new AnomalyEvent(type, description, severity, entry);
        detectedAnomalies.add(event);
        anomaliesDetected++;

        log.warn("Log Analysis Agent: 이상 행위 탐지 - type={}, severity={}, desc={}",
            type, severity, description);

        // BigQuery에 기록
        bigQueryService.insertAnalyticsEvent(
            "anomaly_detected",
            Map.of(
                "type", type,
                "severity", severity,
                "description", description,
                "source", entry.source,
                "timestamp", entry.timestamp.toString()
            )
        );
    }

    /**
     * 통계 분석 수행
     */
    private void performStatisticalAnalysis() {
        // 최근 5분간 로그 통계
        long now = System.currentTimeMillis();
        long fiveMinutesAgo = now - 300000;

        Map<String, Integer> levelCounts = new HashMap<>();
        Map<String, Integer> sourceCounts = new HashMap<>();

        for (AnomalyEvent event : detectedAnomalies) {
            if (event.detectedAt.isAfter(LocalDateTime.now().minusMinutes(5))) {
                levelCounts.merge(event.severity, 1, Integer::sum);
                sourceCounts.merge(event.type, 1, Integer::sum);
            }
        }

        AnalysisResult result = new AnalysisResult(
            "STATISTICAL",
            levelCounts,
            sourceCounts,
            LocalDateTime.now()
        );
        analysisHistory.add(result);

        // 이상 임계값 초과 시 알림
        int criticalCount = levelCounts.getOrDefault("CRITICAL", 0);
        if (criticalCount > 5) {
            log.error("Log Analysis Agent: CRITICAL 이벤트 급증 - {}건", criticalCount);
        }
    }

    /**
     * 일일 종합 분석
     */
    private Map<String, Object> performDailyAnalysis() {
        // BigQuery로 일일 로그 분석
        String query = """
            SELECT
                DATE(timestamp) as date,
                level,
                COUNT(*) as count,
                COUNT(DISTINCT source) as unique_sources
            FROM logs
            WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
            GROUP BY date, level
            ORDER BY date, level
            """;

        List<Map<String, Object>> queryResult = bigQueryService.executeQuery(query);

        // 일일 요약
        Map<String, Object> dailySummary = Map.of(
            "date", LocalDateTime.now().format(DateTimeFormatter.ISO_DATE),
            "totalLogsProcessed", totalLogsProcessed,
            "anomaliesDetected", anomaliesDetected,
            "criticalEvents", detectedAnomalies.stream()
                .filter(e -> "CRITICAL".equals(e.severity))
                .count(),
            "queryResults", queryResult
        );

        log.info("Log Analysis Agent: 일일 분석 완료 - 처리: {}, 이상: {}",
            totalLogsProcessed, anomaliesDetected);

        // 통계 리셋
        totalLogsProcessed = 0;
        anomaliesDetected = 0;

        return dailySummary;
    }

    /**
     * 최근 이상 행위 조회
     */
    public List<Map<String, Object>> getRecentAnomalies(int limit) {
        return detectedAnomalies.stream()
            .sorted((a, b) -> b.detectedAt.compareTo(a.detectedAt))
            .limit(limit)
            .map(e -> Map.<String, Object>of(
                "type", e.type,
                "description", e.description,
                "severity", e.severity,
                "source", e.entry.source,
                "detectedAt", e.detectedAt.toString()
            ))
            .toList();
    }

    /**
     * 특정 유형 이상 행위 조회
     */
    public List<Map<String, Object>> getAnomaliesByType(String type) {
        return detectedAnomalies.stream()
            .filter(e -> e.type.equals(type))
            .map(e -> Map.<String, Object>of(
                "type", e.type,
                "description", e.description,
                "severity", e.severity,
                "detectedAt", e.detectedAt.toString()
            ))
            .toList();
    }

    /**
     * 에이전트 상태 조회
     */
    public Map<String, Object> getStatus() {
        long criticalCount = detectedAnomalies.stream()
            .filter(e -> "CRITICAL".equals(e.severity))
            .filter(e -> e.detectedAt.isAfter(LocalDateTime.now().minusHours(1)))
            .count();

        return Map.of(
            "agent", "LogAnalysisAgent",
            "role", "로그 분석 및 이상 행위 탐지",
            "tech", "Cloud Logging + BigQuery",
            "totalLogsProcessed", totalLogsProcessed,
            "anomaliesDetected", anomaliesDetected,
            "pendingLogs", logBuffer.size(),
            "recentCritical", criticalCount,
            "activePatterns", anomalyPatterns.size(),
            "status", criticalCount > 0 ? "ALERT" : "ACTIVE",
            "lastAnalysis", LocalDateTime.now().toString()
        );
    }

    /**
     * 로그 엔트리 내부 클래스
     */
    private record LogEntry(
        String level,
        String source,
        String message,
        Map<String, Object> metadata,
        LocalDateTime timestamp
    ) {
        LogEntry(String level, String source, String message, Map<String, Object> metadata) {
            this(level, source, message, metadata, LocalDateTime.now());
        }
    }

    /**
     * 이상 패턴 내부 클래스
     */
    private static class AnomalyPattern {
        String type;
        String identifier;
        int count;
        long firstSeen;
        long lastSeen;

        AnomalyPattern(String type, String identifier) {
            this.type = type;
            this.identifier = identifier;
            this.count = 0;
            this.firstSeen = System.currentTimeMillis();
            this.lastSeen = this.firstSeen;
        }
    }

    /**
     * 이상 이벤트 내부 클래스
     */
    private record AnomalyEvent(
        String type,
        String description,
        String severity,
        LogEntry entry,
        LocalDateTime detectedAt
    ) {
        AnomalyEvent(String type, String description, String severity, LogEntry entry) {
            this(type, description, severity, entry, LocalDateTime.now());
        }
    }

    /**
     * 분석 결과 내부 클래스
     */
    private record AnalysisResult(
        String type,
        Map<String, Integer> levelCounts,
        Map<String, Integer> sourceCounts,
        LocalDateTime timestamp
    ) {}
}
