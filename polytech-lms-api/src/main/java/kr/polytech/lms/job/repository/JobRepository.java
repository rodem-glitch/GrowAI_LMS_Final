package kr.polytech.lms.job.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.dao.DataAccessException;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Repository
public class JobRepository {
    // 왜: 코드 테이블/채용 캐시를 간단한 SQL로 조회하기 위해 JdbcTemplate을 사용합니다.

    private final JdbcTemplate jdbcTemplate;

    public JobRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = Objects.requireNonNull(jdbcTemplate);
    }

    public List<JobRegionCodeRow> findRegionCodes(String depthType, String depth1) {
        String safeDepthType = normalizeDepthType(depthType, "1");
        List<Object> params = new ArrayList<>();

        StringBuilder sql = new StringBuilder("""
            SELECT idx, depth1, depth2, depth3
            FROM regioncode
            WHERE 1=1
            """);

        appendDepthFilter(sql, params, safeDepthType);

        if (depth1 != null && !depth1.isBlank()) {
            sql.append(" AND depth1 = ?");
            params.add(depth1.trim());
        }

        return jdbcTemplate.query(sql.toString(), params.toArray(), (rs, rowNum) -> {
            String title = resolveDepthTitle(safeDepthType, rs.getString("depth1"), rs.getString("depth2"), rs.getString("depth3"));
            return new JobRegionCodeRow(
                rs.getInt("idx"),
                title,
                rs.getString("depth1"),
                rs.getString("depth2"),
                rs.getString("depth3")
            );
        });
    }

    public List<JobOccupationCodeRow> findOccupationCodes(String depthType, String depth1) {
        String safeDepthType = normalizeDepthType(depthType, "2");
        List<Object> params = new ArrayList<>();

        StringBuilder sql = new StringBuilder("""
            SELECT idx, code, depth1, depth2, depth3
            FROM occupationcode
            WHERE 1=1
            """);

        appendDepthFilter(sql, params, safeDepthType);

        if (depth1 != null && !depth1.isBlank()) {
            sql.append(" AND depth1 = ?");
            params.add(depth1.trim());
        }

        return jdbcTemplate.query(sql.toString(), params.toArray(), (rs, rowNum) -> {
            String title = resolveDepthTitle(safeDepthType, rs.getString("depth1"), rs.getString("depth2"), rs.getString("depth3"));
            return new JobOccupationCodeRow(
                rs.getInt("idx"),
                rs.getString("code"),
                title,
                rs.getString("depth1"),
                rs.getString("depth2"),
                rs.getString("depth3")
            );
        });
    }

    public Optional<JobRecruitCacheRow> findRecruitCache(String queryKey, String provider) {
        try {
            List<JobRecruitCacheRow> rows = jdbcTemplate.query("""
                SELECT total, start_page, `display`, payload_json, updated_at
                FROM job_recruit_cache
                WHERE query_key = ? AND provider = ?
                """, new Object[]{queryKey, normalizeProvider(provider)}, (rs, rowNum) -> new JobRecruitCacheRow(
                rs.getInt("total"),
                rs.getInt("start_page"),
                rs.getInt("display"),
                rs.getString("payload_json"),
                toLocalDateTime(rs.getTimestamp("updated_at"))
            ));
            return rows.stream().findFirst();
        } catch (DataAccessException e) {
            // 왜: provider 컬럼이 아직 없으면 기존 테이블을 조회해도 동작해야 합니다.
            try {
                List<JobRecruitCacheRow> rows = jdbcTemplate.query("""
                    SELECT total, start_page, `display`, payload_json, updated_at
                    FROM job_recruit_cache
                    WHERE query_key = ?
                    """, new Object[]{queryKey}, (rs, rowNum) -> new JobRecruitCacheRow(
                    rs.getInt("total"),
                    rs.getInt("start_page"),
                    rs.getInt("display"),
                    rs.getString("payload_json"),
                    toLocalDateTime(rs.getTimestamp("updated_at"))
                ));
                return rows.stream().findFirst();
            } catch (DataAccessException ignored) {
                return Optional.empty();
            }
        }
    }

    public List<JobRecruitCacheKey> findAllRecruitCacheKeys() {
        try {
            return jdbcTemplate.query("""
                SELECT query_key, provider, region_code, occupation_code, start_page, `display`
                FROM job_recruit_cache
                """, (rs, rowNum) -> new JobRecruitCacheKey(
                rs.getString("query_key"),
                rs.getString("provider"),
                rs.getString("region_code"),
                rs.getString("occupation_code"),
                rs.getInt("start_page"),
                rs.getInt("display")
            ));
        } catch (DataAccessException e) {
            // 왜: provider 컬럼이 없으면 기존 컬럼으로라도 갱신 목록을 구성합니다.
            try {
                return jdbcTemplate.query("""
                    SELECT query_key, region_code, occupation_code, start_page, `display`
                    FROM job_recruit_cache
                    """, (rs, rowNum) -> new JobRecruitCacheKey(
                    rs.getString("query_key"),
                    "WORK24",
                    rs.getString("region_code"),
                    rs.getString("occupation_code"),
                    rs.getInt("start_page"),
                    rs.getInt("display")
                ));
            } catch (DataAccessException ignored) {
                return List.of();
            }
        }
    }

    public void upsertRecruitCache(JobRecruitCacheRow row, JobRecruitCacheKey key) {
        try {
            jdbcTemplate.update("""
                INSERT INTO job_recruit_cache
                    (query_key, provider, region_code, occupation_code, start_page, `display`, total, payload_json, updated_at)
                VALUES
                    (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    provider = VALUES(provider),
                    region_code = VALUES(region_code),
                    occupation_code = VALUES(occupation_code),
                    start_page = VALUES(start_page),
                    `display` = VALUES(`display`),
                    total = VALUES(total),
                    payload_json = VALUES(payload_json),
                    updated_at = VALUES(updated_at)
                """,
                key.queryKey(),
                normalizeProvider(key.provider()),
                key.regionCode(),
                key.occupationCode(),
                key.startPage(),
                key.display(),
                row.total(),
                row.payloadJson(),
                Timestamp.valueOf(row.updatedAt())
            );
        } catch (DataAccessException e) {
            // 왜: provider 컬럼이 없는 구버전 테이블도 동작할 수 있어야 합니다.
            try {
                jdbcTemplate.update("""
                    INSERT INTO job_recruit_cache
                        (query_key, region_code, occupation_code, start_page, `display`, total, payload_json, updated_at)
                    VALUES
                        (?, ?, ?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                        region_code = VALUES(region_code),
                        occupation_code = VALUES(occupation_code),
                        start_page = VALUES(start_page),
                        `display` = VALUES(`display`),
                        total = VALUES(total),
                        payload_json = VALUES(payload_json),
                        updated_at = VALUES(updated_at)
                    """,
                    key.queryKey(),
                    key.regionCode(),
                    key.occupationCode(),
                    key.startPage(),
                    key.display(),
                    row.total(),
                    row.payloadJson(),
                    Timestamp.valueOf(row.updatedAt())
                );
            } catch (DataAccessException ignored) {
                // 왜: 캐시 저장 실패가 조회 기능 자체를 막으면 안 됩니다(실시간 조회로라도 응답).
            }
        }
    }

    private static void appendDepthFilter(StringBuilder sql, List<Object> params, String depthType) {
        switch (depthType) {
            case "1" -> sql.append(" AND depth1 <> ''");
            case "2" -> sql.append(" AND depth2 <> ''");
            case "3" -> sql.append(" AND depth3 <> ''");
            default -> {
                sql.append(" AND depth1 <> ''");
            }
        }
    }

    private static String resolveDepthTitle(String depthType, String depth1, String depth2, String depth3) {
        return switch (depthType) {
            case "1" -> depth1;
            case "2" -> depth2;
            case "3" -> depth3;
            default -> depth1;
        };
    }

    private static String normalizeDepthType(String depthType, String defaultValue) {
        if (depthType == null || depthType.isBlank()) return defaultValue;
        String trimmed = depthType.trim();
        return switch (trimmed) {
            case "1", "2", "3" -> trimmed;
            default -> defaultValue;
        };
    }

    private static LocalDateTime toLocalDateTime(Timestamp timestamp) {
        if (timestamp == null) return LocalDateTime.MIN;
        return timestamp.toLocalDateTime();
    }

    private static String normalizeProvider(String provider) {
        if (provider == null || provider.isBlank()) return "WORK24";
        return provider.trim().toUpperCase();
    }

    public record JobRegionCodeRow(int idx, String title, String depth1, String depth2, String depth3) {
    }

    public record JobOccupationCodeRow(int idx, String code, String title, String depth1, String depth2, String depth3) {
    }

    public record JobRecruitCacheRow(int total, int startPage, int display, String payloadJson, LocalDateTime updatedAt) {
    }

    public record JobRecruitCacheKey(
        String queryKey,
        String provider,
        String regionCode,
        String occupationCode,
        int startPage,
        int display
    ) {
    }
}
