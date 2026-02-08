// polytech-lms-api/src/main/java/kr/polytech/lms/analytics/service/AnalyticsService.java
package kr.polytech.lms.analytics.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 학습 분석 서비스
 * Apache Superset 연동 및 통계 데이터 제공
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final JdbcTemplate jdbcTemplate;

    /**
     * 전체 학습 현황 통계
     */
    public Map<String, Object> getLearningOverview(Long siteId) {
        Map<String, Object> stats = new HashMap<>();

        try {
            // 총 수강생 수
            Integer totalLearners = jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT user_id) FROM LM_COURSE_USER WHERE site_id = ? AND status = 1",
                Integer.class, siteId);
            stats.put("totalLearners", totalLearners != null ? totalLearners : 0);

            // 총 과정 수
            Integer totalCourses = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM LM_COURSE WHERE site_id = ? AND status = 1",
                Integer.class, siteId);
            stats.put("totalCourses", totalCourses != null ? totalCourses : 0);

            // 수료율
            Double completionRate = jdbcTemplate.queryForObject(
                "SELECT ROUND(SUM(CASE WHEN complete_yn = 'Y' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 1) " +
                "FROM LM_COURSE_USER WHERE site_id = ? AND status = 1",
                Double.class, siteId);
            stats.put("completionRate", completionRate != null ? completionRate : 0.0);

            // 평균 진도율
            Double avgProgress = jdbcTemplate.queryForObject(
                "SELECT ROUND(AVG(progress), 1) FROM LM_COURSE_USER WHERE site_id = ? AND status = 1",
                Double.class, siteId);
            stats.put("avgProgress", avgProgress != null ? avgProgress : 0.0);

        } catch (Exception e) {
            log.error("통계 조회 실패: {}", e.getMessage());
            stats.put("error", e.getMessage());
        }

        return stats;
    }

    /**
     * 일별 학습 현황
     */
    public List<Map<String, Object>> getDailyLearningStats(Long siteId, int days) {
        try {
            String sql = """
                SELECT DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(reg_date))) as date,
                       COUNT(*) as enrollments,
                       SUM(CASE WHEN complete_yn = 'Y' THEN 1 ELSE 0 END) as completions
                FROM LM_COURSE_USER
                WHERE site_id = ? AND reg_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
                GROUP BY DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(reg_date)))
                ORDER BY date DESC
                """;
            return jdbcTemplate.queryForList(sql, siteId, days);
        } catch (Exception e) {
            log.error("일별 통계 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 과정별 수강 현황
     */
    public List<Map<String, Object>> getCourseEnrollmentStats(Long siteId, int limit) {
        try {
            String sql = """
                SELECT c.id, c.course_nm,
                       COUNT(cu.id) as total_enrollments,
                       SUM(CASE WHEN cu.complete_yn = 'Y' THEN 1 ELSE 0 END) as completions,
                       ROUND(AVG(cu.progress), 1) as avg_progress
                FROM LM_COURSE c
                LEFT JOIN LM_COURSE_USER cu ON c.id = cu.course_id AND cu.status = 1
                WHERE c.site_id = ? AND c.status = 1
                GROUP BY c.id, c.course_nm
                ORDER BY total_enrollments DESC
                LIMIT ?
                """;
            return jdbcTemplate.queryForList(sql, siteId, limit);
        } catch (Exception e) {
            log.error("과정별 통계 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 시간대별 학습 패턴
     */
    public List<Map<String, Object>> getHourlyLearningPattern(Long siteId) {
        try {
            String sql = """
                SELECT HOUR(FROM_UNIXTIME(UNIX_TIMESTAMP(conn_date))) as hour,
                       COUNT(*) as access_count
                FROM LM_COURSE_USER_LOG
                WHERE site_id = ? AND conn_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
                GROUP BY HOUR(FROM_UNIXTIME(UNIX_TIMESTAMP(conn_date)))
                ORDER BY hour
                """;
            return jdbcTemplate.queryForList(sql, siteId);
        } catch (Exception e) {
            log.error("시간대별 패턴 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 학습자 진도율 분포
     */
    public Map<String, Object> getProgressDistribution(Long siteId) {
        Map<String, Object> distribution = new LinkedHashMap<>();

        try {
            String sql = """
                SELECT
                    SUM(CASE WHEN progress = 0 THEN 1 ELSE 0 END) as not_started,
                    SUM(CASE WHEN progress > 0 AND progress < 25 THEN 1 ELSE 0 END) as progress_1_24,
                    SUM(CASE WHEN progress >= 25 AND progress < 50 THEN 1 ELSE 0 END) as progress_25_49,
                    SUM(CASE WHEN progress >= 50 AND progress < 75 THEN 1 ELSE 0 END) as progress_50_74,
                    SUM(CASE WHEN progress >= 75 AND progress < 100 THEN 1 ELSE 0 END) as progress_75_99,
                    SUM(CASE WHEN progress = 100 THEN 1 ELSE 0 END) as completed
                FROM LM_COURSE_USER
                WHERE site_id = ? AND status = 1
                """;

            Map<String, Object> result = jdbcTemplate.queryForMap(sql, siteId);
            distribution.put("미시작 (0%)", result.get("not_started"));
            distribution.put("1-24%", result.get("progress_1_24"));
            distribution.put("25-49%", result.get("progress_25_49"));
            distribution.put("50-74%", result.get("progress_50_74"));
            distribution.put("75-99%", result.get("progress_75_99"));
            distribution.put("완료 (100%)", result.get("completed"));

        } catch (Exception e) {
            log.error("진도율 분포 조회 실패: {}", e.getMessage());
        }

        return distribution;
    }

    /**
     * Superset 임베드용 게스트 토큰 생성 정보
     */
    public Map<String, Object> getSupersetEmbedInfo(String dashboardId) {
        // Superset API를 통해 게스트 토큰을 발급받아 대시보드 임베딩
        return Map.of(
            "dashboardId", dashboardId,
            "embedUrl", "/superset/dashboard/" + dashboardId + "/",
            "note", "Superset 서버에서 게스트 토큰 발급 필요"
        );
    }
}
