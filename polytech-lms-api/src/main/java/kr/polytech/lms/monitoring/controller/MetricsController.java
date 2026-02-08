// polytech-lms-api/src/main/java/kr/polytech/lms/monitoring/controller/MetricsController.java
package kr.polytech.lms.monitoring.controller;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Timer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 커스텀 메트릭 컨트롤러
 * 비즈니스 메트릭 수집 및 조회
 */
@Slf4j
@RestController
@RequestMapping("/api/metrics")
public class MetricsController {

    private final MeterRegistry meterRegistry;
    private final JdbcTemplate jdbcTemplate;

    private final Counter loginCounter;
    private final Counter courseAccessCounter;
    private final Timer apiResponseTimer;

    public MetricsController(MeterRegistry meterRegistry, JdbcTemplate jdbcTemplate) {
        this.meterRegistry = meterRegistry;
        this.jdbcTemplate = jdbcTemplate;

        // 커스텀 메트릭 등록
        this.loginCounter = Counter.builder("lms.login.total")
            .description("총 로그인 횟수")
            .register(meterRegistry);

        this.courseAccessCounter = Counter.builder("lms.course.access")
            .description("과정 접근 횟수")
            .register(meterRegistry);

        this.apiResponseTimer = Timer.builder("lms.api.response.time")
            .description("API 응답 시간")
            .register(meterRegistry);
    }

    /**
     * 로그인 메트릭 기록
     */
    public void recordLogin(String userId) {
        loginCounter.increment();
        log.debug("로그인 메트릭 기록: userId={}", userId);
    }

    /**
     * 과정 접근 메트릭 기록
     */
    public void recordCourseAccess(Long courseId) {
        courseAccessCounter.increment();
        Counter.builder("lms.course.access.detail")
            .tag("courseId", String.valueOf(courseId))
            .register(meterRegistry)
            .increment();
    }

    /**
     * API 응답 시간 기록
     */
    public void recordApiTime(long durationMs) {
        apiResponseTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }

    /**
     * 시스템 메트릭 조회
     */
    @GetMapping("/system")
    public ResponseEntity<Map<String, Object>> getSystemMetrics() {
        Map<String, Object> metrics = new HashMap<>();

        Runtime runtime = Runtime.getRuntime();
        metrics.put("heapMemoryUsed", runtime.totalMemory() - runtime.freeMemory());
        metrics.put("heapMemoryMax", runtime.maxMemory());
        metrics.put("availableProcessors", runtime.availableProcessors());

        return ResponseEntity.ok(metrics);
    }

    /**
     * 비즈니스 메트릭 조회
     */
    @GetMapping("/business")
    public ResponseEntity<Map<String, Object>> getBusinessMetrics(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {

        Map<String, Object> metrics = new HashMap<>();

        try {
            // 오늘 로그인 수
            Integer todayLogins = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM TB_USER_LOGIN_LOG WHERE DATE(login_date) = CURDATE() AND site_id = ?",
                Integer.class, siteId);
            metrics.put("todayLogins", todayLogins != null ? todayLogins : 0);

            // 현재 활성 세션 수 (추정)
            Integer activeSessions = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM TB_USER_LOGIN_LOG WHERE login_date >= DATE_SUB(NOW(), INTERVAL 30 MINUTE) AND site_id = ?",
                Integer.class, siteId);
            metrics.put("activeSessions", activeSessions != null ? activeSessions : 0);

            // 오늘 신규 수강 등록
            Integer todayEnrollments = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM LM_COURSE_USER WHERE DATE(reg_date) = CURDATE() AND site_id = ?",
                Integer.class, siteId);
            metrics.put("todayEnrollments", todayEnrollments != null ? todayEnrollments : 0);

        } catch (Exception e) {
            log.error("비즈니스 메트릭 조회 실패: {}", e.getMessage());
            metrics.put("error", e.getMessage());
        }

        return ResponseEntity.ok(metrics);
    }
}
