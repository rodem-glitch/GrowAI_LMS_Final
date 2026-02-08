-- ==========================================================================
-- 학사포털 회원 동기화 테이블 DDL
-- poly_sync.jsp의 LM_POLY_MEMBER 적재 부분(308~376행) 대응
--
-- 이 스크립트는 참조용입니다. MemberSyncService가 최초 실행 시 자동 생성합니다.
-- ==========================================================================

-- 1. 학사포털 회원 본 테이블
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
  COMMENT='학사포털 회원 미러 테이블';

-- 2. 임시 적재용 (TRUNCATE → REPLACE INTO → RENAME SWAP)
CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_TMP LIKE LM_POLY_MEMBER;

-- 3. 별칭키 매핑 테이블
--    member_key → member_key (자기 자신)
--    rpst_member_key → member_key (대표키 매핑)
CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_KEY (
    lookup_key  VARCHAR(50) NOT NULL PRIMARY KEY COMMENT '조회키 (member_key 또는 rpst_member_key)',
    member_key  VARCHAR(50) NOT NULL             COMMENT '실제 member_key',
    INDEX idx_poly_key_member (member_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='학사포털 회원 별칭키 매핑';

-- 4. 별칭키 매핑 임시
CREATE TABLE IF NOT EXISTS LM_POLY_MEMBER_KEY_TMP LIKE LM_POLY_MEMBER_KEY;

-- 5. 동기화 실행 이력
CREATE TABLE IF NOT EXISTS LM_SYNC_LOG (
    id            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sync_type     VARCHAR(50)  NOT NULL COMMENT '동기화유형 (MEMBER_SYNC, COURSE_SYNC 등)',
    success_count INT          NOT NULL DEFAULT 0 COMMENT '성공건수',
    error_count   INT          NOT NULL DEFAULT 0 COMMENT '실패건수',
    duration_ms   BIGINT       NOT NULL DEFAULT 0 COMMENT '소요시간(ms)',
    sync_time     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '동기화시각',
    INDEX idx_sync_log_type_time (sync_type, sync_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='동기화 실행 이력';
