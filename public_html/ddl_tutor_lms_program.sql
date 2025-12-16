-- 교수자 과정(프로그램) 개설/관리 기능 추가용 DDL
-- 왜 필요한가:
-- - `project` 화면에서 교수자가 만든 과정(프로그램)을 "본인 것만" 조회/수정/삭제하려면 등록자(USER_ID)가 필요합니다.
-- - 과정 기간(START_DATE/END_DATE)을 저장해야 화면에서 즉시(목록/선택/연동) 표시할 수 있습니다.
--
-- 주의:
-- - 운영 반영 시 기존 데이터 보호를 위해 DROP/DELETE는 하지 않습니다.
-- - MySQL 버전에 따라 `ADD COLUMN IF NOT EXISTS`가 지원되지 않을 수 있어 information_schema로 “없는 것만” 추가합니다.

SET @tbl := 'LM_SUBJECT';

-- 1) USER_ID: 등록자(교수자)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `LM_SUBJECT` ADD COLUMN `USER_ID` int NOT NULL DEFAULT 0 COMMENT ''등록자(교수자)'' AFTER `SITE_ID`',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = 'USER_ID'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) START_DATE: 과정 시작일(yyyyMMdd)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `LM_SUBJECT` ADD COLUMN `START_DATE` varchar(8) DEFAULT NULL COMMENT ''과정 시작일'' AFTER `COURSE_NM`',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = 'START_DATE'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) END_DATE: 과정 종료일(yyyyMMdd)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `LM_SUBJECT` ADD COLUMN `END_DATE` varchar(8) DEFAULT NULL COMMENT ''과정 종료일'' AFTER `START_DATE`',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = 'END_DATE'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) 인덱스: 교수자 과정 목록 조회 성능
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `LM_SUBJECT` ADD INDEX `IDX_LM_SUBJECT_TUTOR` (`SITE_ID`, `USER_ID`, `STATUS`, `ID`)',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND INDEX_NAME = 'IDX_LM_SUBJECT_TUTOR'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

