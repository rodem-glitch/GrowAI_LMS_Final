package kr.polytech.lms.security.sql;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.util.Objects;

/**
 * KISA SR1-2: SQL 삽입 공격 방지
 *
 * PreparedStatement 파라미터 바인딩 헬퍼
 * - 타입 안전한 파라미터 설정
 * - NULL 값 안전 처리
 * - 배치 처리 지원
 */
public final class PreparedStatementHelper {

    private PreparedStatementHelper() {
        throw new AssertionError("Utility class - instantiation not allowed");
    }

    /**
     * 파라미터 배열을 PreparedStatement에 바인딩
     */
    public static void bindParameters(PreparedStatement stmt, Object[] params) throws SQLException {
        if (params == null || params.length == 0) {
            return;
        }
        for (int i = 0; i < params.length; i++) {
            setParameter(stmt, i + 1, params[i]);
        }
    }

    /**
     * 파라미터 리스트를 PreparedStatement에 바인딩
     */
    public static void bindParameters(PreparedStatement stmt, List<?> params) throws SQLException {
        if (params == null || params.isEmpty()) {
            return;
        }
        for (int i = 0; i < params.size(); i++) {
            setParameter(stmt, i + 1, params.get(i));
        }
    }

    /**
     * 단일 파라미터 설정 (타입 자동 감지)
     */
    public static void setParameter(PreparedStatement stmt, int index, Object value) throws SQLException {
        Objects.requireNonNull(stmt, "PreparedStatement cannot be null");

        if (value == null) {
            stmt.setNull(index, Types.VARCHAR);
            return;
        }

        switch (value) {
            case String s -> stmt.setString(index, s);
            case Integer i -> stmt.setInt(index, i);
            case Long l -> stmt.setLong(index, l);
            case Double d -> stmt.setDouble(index, d);
            case Float f -> stmt.setFloat(index, f);
            case Boolean b -> stmt.setBoolean(index, b);
            case LocalDateTime ldt -> stmt.setTimestamp(index, Timestamp.valueOf(ldt));
            case LocalDate ld -> stmt.setDate(index, Date.valueOf(ld));
            case Timestamp ts -> stmt.setTimestamp(index, ts);
            case Date dt -> stmt.setDate(index, dt);
            case byte[] bytes -> stmt.setBytes(index, bytes);
            case Short sh -> stmt.setShort(index, sh);
            case java.math.BigDecimal bd -> stmt.setBigDecimal(index, bd);
            default -> stmt.setObject(index, value);
        }
    }

    /**
     * 문자열 파라미터 안전 설정 (NULL 처리 포함)
     */
    public static void setStringOrNull(PreparedStatement stmt, int index, String value) throws SQLException {
        if (value == null || value.isBlank()) {
            stmt.setNull(index, Types.VARCHAR);
        } else {
            stmt.setString(index, value.trim());
        }
    }

    /**
     * 정수 파라미터 안전 설정 (NULL 처리 포함)
     */
    public static void setIntOrNull(PreparedStatement stmt, int index, Integer value) throws SQLException {
        if (value == null) {
            stmt.setNull(index, Types.INTEGER);
        } else {
            stmt.setInt(index, value);
        }
    }

    /**
     * Long 파라미터 안전 설정
     */
    public static void setLongOrNull(PreparedStatement stmt, int index, Long value) throws SQLException {
        if (value == null) {
            stmt.setNull(index, Types.BIGINT);
        } else {
            stmt.setLong(index, value);
        }
    }

    /**
     * 날짜/시간 파라미터 안전 설정
     */
    public static void setTimestampOrNull(PreparedStatement stmt, int index, LocalDateTime value) throws SQLException {
        if (value == null) {
            stmt.setNull(index, Types.TIMESTAMP);
        } else {
            stmt.setTimestamp(index, Timestamp.valueOf(value));
        }
    }

    /**
     * Boolean 파라미터 안전 설정
     */
    public static void setBooleanOrNull(PreparedStatement stmt, int index, Boolean value) throws SQLException {
        if (value == null) {
            stmt.setNull(index, Types.BOOLEAN);
        } else {
            stmt.setBoolean(index, value);
        }
    }

    /**
     * PreparedStatement 생성 및 파라미터 바인딩
     */
    public static PreparedStatement createStatement(Connection conn, String sql, Object[] params) throws SQLException {
        PreparedStatement stmt = conn.prepareStatement(sql);
        try {
            bindParameters(stmt, params);
            return stmt;
        } catch (SQLException e) {
            stmt.close();
            throw e;
        }
    }

    /**
     * PreparedStatement 생성 및 파라미터 바인딩 (GeneratedKeys 반환용)
     */
    public static PreparedStatement createStatementWithGeneratedKeys(Connection conn, String sql, Object[] params) throws SQLException {
        PreparedStatement stmt = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
        try {
            bindParameters(stmt, params);
            return stmt;
        } catch (SQLException e) {
            stmt.close();
            throw e;
        }
    }

    /**
     * IN 절용 플레이스홀더 문자열 생성
     */
    public static String createInClausePlaceholders(int count) {
        if (count <= 0) {
            throw new IllegalArgumentException("Count must be positive");
        }
        StringBuilder sb = new StringBuilder(count * 2);
        for (int i = 0; i < count; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append("?");
        }
        return sb.toString();
    }

    /**
     * 쿼리에 IN 절 파라미터 동적 추가
     */
    public static String replaceInClause(String sql, String placeholder, int paramCount) {
        return sql.replace(placeholder, createInClausePlaceholders(paramCount));
    }
}
