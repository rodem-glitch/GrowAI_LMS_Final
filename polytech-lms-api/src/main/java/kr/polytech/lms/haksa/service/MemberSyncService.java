// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/MemberSyncService.java
package kr.polytech.lms.haksa.service;

import kr.polytech.lms.haksa.client.PolyApiClient;
import kr.polytech.lms.haksa.config.PolySyncProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

/**
 * 학사포털 회원 동기화 서비스
 * poly_sync.jsp의 LM_POLY_MEMBER 적재 부분(308~376행) Java 구현
 *
 * 전체 흐름:
 *   외부 학사시스템(e-poly.kopo.ac.kr)에서 View 데이터를 HTTP로 받아 로컬 DB에 미러링
 *
 * 단계별 로직:
 *   1. COM.LMS_MEMBER_VIEW 외부 호출 (fetchPolyRaw)
 *   2. TMP 테이블 초기화 (TRUNCATE LM_POLY_MEMBER_TMP)
 *   3. 회원 데이터 REPLACE INTO LM_POLY_MEMBER_TMP (18개 컬럼)
 *   4. 별칭키 매핑 LM_POLY_MEMBER_KEY_TMP
 *   5. TB_USER.login_id → member_key 추가 매핑
 *   6. 안전 스왑: RENAME TABLE (원자적 교체)
 *   7. (선택) 학사에서 사라진 사용자 자동삭제
 */
@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "poly-sync", name = "enabled", havingValue = "true", matchIfMissing = false)
public class MemberSyncService {

    private final PolyApiClient polyApiClient;
    private final PolySyncProperties properties;
    private final JdbcTemplate jdbcTemplate;

    // 동기화 상태 추적
    private LocalDateTime lastSyncTime;
    private String lastSyncStatus = "NEVER";
    private int lastSyncCount = 0;

    /**
     * 전체 회원 동기화 (매일 새벽 1시 실행)
     * poly_sync.jsp 2-2) 회원 적재 로직 전체 구현
     */
    @Scheduled(cron = "${poly-sync.cron:0 0 1 * * *}")
    @Transactional
    public Map<String, Object> syncAllMembers() {
        log.info("========== 회원 동기화 시작 ==========");
        long startTime = System.currentTimeMillis();

        int syncCount = 0;
        int errorCount = 0;

        try {
            // === Step 1: COM.LMS_MEMBER_VIEW 외부 호출 (line 224) ===
            log.info("[Step 1] COM.LMS_MEMBER_VIEW 외부 호출...");
            int memberCnt = polyApiClient.fetchMemberCount();
            if (memberCnt < 0) {
                // VPN 미연결 또는 학사포털 장애 시 mock/fallback 사용
                log.warn("[Step 1] 회원 건수 조회 실패 - VPN 미연결 가능성. Mock 데이터로 대체합니다.");
                memberCnt = 0;
            }

            List<Map<String, Object>> memberRecords = polyApiClient.fetchPolyRaw(
                    "COM.LMS_MEMBER_VIEW",
                    Math.max(memberCnt, properties.batchSize()),
                    properties.maxRetries(),
                    properties.batchSize(),
                    ""
            );
            log.info("[Step 1] 조회 완료: {}건", memberRecords.size());

            if (memberRecords.isEmpty()) {
                log.warn("[Step 1] 조회 결과 0건 - 동기화를 건너뜁니다.");
                lastSyncStatus = "SKIPPED";
                return buildResult("SKIPPED", 0, 0, System.currentTimeMillis() - startTime,
                        "조회 결과 0건으로 동기화를 건너뛰었습니다.");
            }

            // === Step 2: TMP 테이블 초기화 (line 312-320) ===
            log.info("[Step 2] TRUNCATE LM_POLY_MEMBER_TMP...");
            ensureTmpTablesExist();
            jdbcTemplate.execute("TRUNCATE TABLE LM_POLY_MEMBER_TMP");
            jdbcTemplate.execute("TRUNCATE TABLE LM_POLY_MEMBER_KEY_TMP");
            log.info("[Step 2] TMP 테이블 초기화 완료");

            // === Step 3: 회원 데이터 REPLACE INTO LM_POLY_MEMBER_TMP (line 344-360) ===
            log.info("[Step 3] LM_POLY_MEMBER_TMP에 회원 데이터 적재...");
            for (Map<String, Object> record : memberRecords) {
                try {
                    insertMemberTmp(record);
                    syncCount++;
                } catch (Exception e) {
                    log.error("[Step 3] 회원 적재 실패: member_key={}, error={}",
                            record.get("MEMBER_KEY"), e.getMessage());
                    errorCount++;
                }
            }
            log.info("[Step 3] 적재 완료: 성공={}건, 실패={}건", syncCount, errorCount);

            // === Step 4: 별칭키 매핑 LM_POLY_MEMBER_KEY_TMP (line 363-375) ===
            log.info("[Step 4] 별칭키 매핑 생성...");
            buildKeyMapping();
            log.info("[Step 4] 별칭키 매핑 완료");

            // === Step 5: TB_USER.login_id → member_key 추가 매핑 (line 382-395) ===
            log.info("[Step 5] TB_USER.etc3 ← member_key 매핑...");
            int mappedCount = mapUserMemberKey();
            log.info("[Step 5] TB_USER 매핑 완료: {}건", mappedCount);

            // === Step 6: 안전 스왑 - RENAME TABLE (line 433-437) ===
            log.info("[Step 6] 테이블 원자적 스왑...");
            atomicTableSwap();
            log.info("[Step 6] 테이블 스왑 완료: LM_POLY_MEMBER 교체됨");

            // === Step 7: (선택) 학사에서 사라진 사용자 자동삭제 (line 446-483) ===
            log.info("[Step 7] 사라진 사용자 확인...");
            int deletedCount = cleanupMissingUsers();
            log.info("[Step 7] 사라진 사용자 처리: {}건", deletedCount);

            // 결과 집계
            long duration = System.currentTimeMillis() - startTime;
            lastSyncTime = LocalDateTime.now();
            lastSyncStatus = errorCount == 0 ? "SUCCESS" : "PARTIAL";
            lastSyncCount = syncCount;

            // 동기화 로그 저장
            saveSyncLog("MEMBER_SYNC", syncCount, errorCount, duration);

            log.info("========== 회원 동기화 완료: {}건 성공, {}건 실패, {}ms ==========",
                    syncCount, errorCount, duration);

            return buildResult(lastSyncStatus, syncCount, errorCount, duration, null);

        } catch (Exception e) {
            lastSyncStatus = "FAILED";
            long duration = System.currentTimeMillis() - startTime;
            log.error("========== 회원 동기화 실패: {} ==========", e.getMessage(), e);
            saveSyncLog("MEMBER_SYNC", syncCount, errorCount, duration);
            throw new RuntimeException("회원 동기화 실패", e);
        }
    }

    /**
     * 수동 동기화 트리거
     */
    public Map<String, Object> manualSync() {
        return syncAllMembers();
    }

    // ==========================================================================
    //  Step 3: REPLACE INTO LM_POLY_MEMBER_TMP (18개 컬럼)
    // ==========================================================================
    private void insertMemberTmp(Map<String, Object> record) {
        jdbcTemplate.update("""
            REPLACE INTO LM_POLY_MEMBER_TMP (
                member_key, rpst_member_key, user_type, kor_name, eng_name,
                email, mobile, birth_date, gender, dept_code,
                dept_name, campus_code, campus_name, grade, class_no,
                student_no, status, user_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
                getStr(record, "MEMBER_KEY"),
                getStr(record, "RPST_MEMBER_KEY", getStr(record, "MEMBER_KEY")),
                getStr(record, "USER_TYPE"),
                getStr(record, "KOR_NAME"),
                getStr(record, "ENG_NAME"),
                getStr(record, "EMAIL"),
                getStr(record, "PHONE", getStr(record, "MOBILE")),
                getStr(record, "BIRTH_DATE"),
                getStr(record, "GENDER"),
                getStr(record, "DEPT_CODE"),
                getStr(record, "DEPT_NAME"),
                getStr(record, "CAMPUS_CODE"),
                getStr(record, "CAMPUS_NAME"),
                getStr(record, "GRADE"),
                getStr(record, "CLASS_NO"),
                getStr(record, "STUDENT_NO"),
                getStr(record, "STATUS"),
                getStr(record, "USER_ID")
        );
    }

    // ==========================================================================
    //  Step 4: 별칭키 매핑 LM_POLY_MEMBER_KEY_TMP (line 363-375)
    //  member_key → member_key (자기 자신)
    //  rpst_member_key → member_key (대표키 매핑)
    // ==========================================================================
    private void buildKeyMapping() {
        // 자기 자신 매핑: member_key → member_key
        jdbcTemplate.update("""
            INSERT IGNORE INTO LM_POLY_MEMBER_KEY_TMP (lookup_key, member_key)
            SELECT member_key, member_key
            FROM LM_POLY_MEMBER_TMP
            """);

        // 대표키 매핑: rpst_member_key → member_key
        jdbcTemplate.update("""
            INSERT IGNORE INTO LM_POLY_MEMBER_KEY_TMP (lookup_key, member_key)
            SELECT rpst_member_key, member_key
            FROM LM_POLY_MEMBER_TMP
            WHERE rpst_member_key IS NOT NULL
              AND rpst_member_key != ''
              AND rpst_member_key != member_key
            """);
    }

    // ==========================================================================
    //  Step 5: TB_USER.login_id → member_key 추가 매핑 (line 382-395)
    //  TB_USER.etc3 = LM_POLY_MEMBER_TMP.member_key 조인
    // ==========================================================================
    private int mapUserMemberKey() {
        return jdbcTemplate.update("""
            UPDATE TB_USER u
            INNER JOIN LM_POLY_MEMBER_TMP t ON u.login_id = t.user_id
            SET u.etc3 = t.member_key
            WHERE t.member_key IS NOT NULL
              AND t.member_key != ''
            """);
    }

    // ==========================================================================
    //  Step 6: 안전 스왑 - RENAME TABLE (line 433-437)
    //  LM_POLY_MEMBER → SWAP → TMP → MEMBER (원자적 교체)
    // ==========================================================================
    private void atomicTableSwap() {
        // 스왑 테이블 존재 확인 후 삭제
        jdbcTemplate.execute("DROP TABLE IF EXISTS LM_POLY_MEMBER_SWAP");
        jdbcTemplate.execute("DROP TABLE IF EXISTS LM_POLY_MEMBER_KEY_SWAP");

        // 원자적 교체: OLD → SWAP, TMP → MAIN (한 문장으로 실행)
        jdbcTemplate.execute("""
            RENAME TABLE
                LM_POLY_MEMBER     TO LM_POLY_MEMBER_SWAP,
                LM_POLY_MEMBER_TMP TO LM_POLY_MEMBER
            """);

        jdbcTemplate.execute("""
            RENAME TABLE
                LM_POLY_MEMBER_KEY     TO LM_POLY_MEMBER_KEY_SWAP,
                LM_POLY_MEMBER_KEY_TMP TO LM_POLY_MEMBER_KEY
            """);

        // SWAP(구 본테이블)을 새 TMP로 재활용
        jdbcTemplate.execute("RENAME TABLE LM_POLY_MEMBER_SWAP TO LM_POLY_MEMBER_TMP");
        jdbcTemplate.execute("RENAME TABLE LM_POLY_MEMBER_KEY_SWAP TO LM_POLY_MEMBER_KEY_TMP");
    }

    // ==========================================================================
    //  Step 7: (선택) 학사에서 사라진 사용자 자동삭제 (line 446-483)
    //  old - new 차집합으로 삭제 대상 산출
    // ==========================================================================
    private int cleanupMissingUsers() {
        try {
            // old(TB_USER에 etc3 매핑된 사용자) - new(현재 LM_POLY_MEMBER) 차집합
            // 삭제 대신 상태 비활성화 처리 (안전)
            return jdbcTemplate.update("""
                UPDATE TB_USER u
                SET u.status = 0
                WHERE u.etc3 IS NOT NULL
                  AND u.etc3 != ''
                  AND u.etc3 NOT IN (
                      SELECT member_key FROM LM_POLY_MEMBER
                  )
                  AND u.status = 1
                """);
        } catch (Exception e) {
            log.warn("[Step 7] 사라진 사용자 처리 실패 (무시): {}", e.getMessage());
            return 0;
        }
    }

    // ==========================================================================
    //  테이블 DDL 보장 (최초 실행 시 자동 생성)
    // ==========================================================================
    private void ensureTmpTablesExist() {
        // LM_POLY_MEMBER (본 테이블)
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER (
                member_key      VARCHAR(50)  NOT NULL PRIMARY KEY COMMENT '회원키',
                rpst_member_key VARCHAR(50)  NULL     COMMENT '대표회원키',
                user_type       VARCHAR(10)  NULL     COMMENT '사용자유형 (10:학생, 30:교수, 90:관리자)',
                kor_name        VARCHAR(100) NULL     COMMENT '한글이름',
                eng_name        VARCHAR(100) NULL     COMMENT '영문이름',
                email           VARCHAR(200) NULL     COMMENT '이메일',
                mobile          VARCHAR(200) NULL     COMMENT '휴대폰',
                birth_date      VARCHAR(20)  NULL     COMMENT '생년월일',
                gender          VARCHAR(1)   NULL     COMMENT '성별 (M/F)',
                dept_code       VARCHAR(50)  NULL     COMMENT '학과코드',
                dept_name       VARCHAR(200) NULL     COMMENT '학과명',
                campus_code     VARCHAR(50)  NULL     COMMENT '캠퍼스코드',
                campus_name     VARCHAR(200) NULL     COMMENT '캠퍼스명',
                grade           VARCHAR(10)  NULL     COMMENT '학년',
                class_no        VARCHAR(10)  NULL     COMMENT '반',
                student_no      VARCHAR(50)  NULL     COMMENT '학번',
                status          VARCHAR(10)  NULL     COMMENT '상태 (1:정상)',
                user_id         VARCHAR(50)  NULL     COMMENT '로그인ID',
                sync_date       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '동기화일시',
                INDEX idx_poly_member_user_type (user_type),
                INDEX idx_poly_member_campus (campus_code),
                INDEX idx_poly_member_dept (dept_code),
                INDEX idx_poly_member_user_id (user_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='학사포털 회원 미러 테이블'
            """);

        // LM_POLY_MEMBER_TMP (임시 적재용)
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_TMP LIKE LM_POLY_MEMBER
            """);

        // LM_POLY_MEMBER_KEY (별칭키 매핑)
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_KEY (
                lookup_key  VARCHAR(50) NOT NULL PRIMARY KEY COMMENT '조회키 (member_key 또는 rpst_member_key)',
                member_key  VARCHAR(50) NOT NULL             COMMENT '실제 member_key',
                INDEX idx_poly_key_member (member_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='학사포털 회원 별칭키 매핑'
            """);

        // LM_POLY_MEMBER_KEY_TMP
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_KEY_TMP LIKE LM_POLY_MEMBER_KEY
            """);

        // LM_SYNC_LOG (동기화 이력)
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS LM_SYNC_LOG (
                id            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                sync_type     VARCHAR(50)  NOT NULL COMMENT '동기화유형',
                success_count INT          NOT NULL DEFAULT 0 COMMENT '성공건수',
                error_count   INT          NOT NULL DEFAULT 0 COMMENT '실패건수',
                duration_ms   BIGINT       NOT NULL DEFAULT 0 COMMENT '소요시간(ms)',
                sync_time     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '동기화시각',
                INDEX idx_sync_log_type_time (sync_type, sync_time)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='동기화 실행 이력'
            """);
    }

    // ==========================================================================
    //  상태 조회
    // ==========================================================================

    /**
     * 동기화 상태 조회
     */
    public Map<String, Object> getSyncStatus() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("lastSyncTime", lastSyncTime != null ? lastSyncTime.toString() : "NEVER");
        status.put("lastSyncStatus", lastSyncStatus);
        status.put("lastSyncCount", lastSyncCount);
        status.put("vpnConnected", polyApiClient.checkVpnConnection());
        status.put("enabled", properties.enabled());

        // 현재 본테이블 건수
        try {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM LM_POLY_MEMBER", Integer.class);
            status.put("currentMemberCount", count);
        } catch (Exception e) {
            status.put("currentMemberCount", -1);
        }

        return status;
    }

    /**
     * 동기화 이력 조회
     */
    public List<Map<String, Object>> getSyncHistory(int limit) {
        try {
            return jdbcTemplate.queryForList("""
                SELECT sync_type, success_count, error_count, duration_ms, sync_time
                FROM LM_SYNC_LOG
                WHERE sync_type = 'MEMBER_SYNC'
                ORDER BY sync_time DESC
                LIMIT ?
                """, limit);
        } catch (Exception e) {
            log.debug("동기화 이력 조회 실패: {}", e.getMessage());
            return List.of();
        }
    }

    // ==========================================================================
    //  유틸리티
    // ==========================================================================

    private void saveSyncLog(String syncType, int successCount, int errorCount, long duration) {
        try {
            jdbcTemplate.update("""
                INSERT INTO LM_SYNC_LOG (sync_type, success_count, error_count, duration_ms, sync_time)
                VALUES (?, ?, ?, ?, NOW())
                """, syncType, successCount, errorCount, duration);
        } catch (Exception e) {
            log.debug("동기화 로그 저장 실패: {}", e.getMessage());
        }
    }

    private Map<String, Object> buildResult(String status, int syncCount, int errorCount,
                                            long duration, String message) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", status);
        result.put("syncCount", syncCount);
        result.put("errorCount", errorCount);
        result.put("duration", duration);
        result.put("syncTime", LocalDateTime.now().toString());
        if (message != null) {
            result.put("message", message);
        }
        return result;
    }

    private static String getStr(Map<String, Object> map, String key) {
        Object val = map.get(key);
        return val != null ? val.toString() : null;
    }

    private static String getStr(Map<String, Object> map, String key, String fallback) {
        String val = getStr(map, key);
        return (val != null && !val.isEmpty()) ? val : fallback;
    }
}
