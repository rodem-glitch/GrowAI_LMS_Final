-- 교수자 과정(프로그램) 운영계획서/상세필드 저장용 DDL
-- 왜 필요한가:
-- - `project` 화면의 "과정개설(CreateCourseForm) / 운영계획서(OperationalPlan)"에는
--   기본 정보(분류/계열/전공/대상/목표) + 반복 리스트(교과편성/교수계획서/수행평가서) 같은 값이 많습니다.
-- - 기존 `LM_SUBJECT`는 과정명 중심의 최소 컬럼만 있어, 위 데이터를 그대로 저장할 공간이 없습니다.
-- - 그래서 과정 1건(SUBJECT_ID)당 1건으로 JSON을 저장하는 보조 테이블을 추가합니다.
--
-- 설계 원칙:
-- - DROP/DELETE는 하지 않습니다.
-- - MySQL 버전에 따라 `CREATE TABLE IF NOT EXISTS`만으로 부족한 경우가 있어,
--   information_schema로 “없는 것만” 생성합니다.

SET @tbl := 'LM_SUBJECT_PLAN';

-- 1) 테이블 생성: 과정 운영계획서(JSON) 1:1 저장소
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'CREATE TABLE `LM_SUBJECT_PLAN` ('
      '  `SUBJECT_ID` int NOT NULL COMMENT ''과정(프로그램) ID'','
      '  `SITE_ID` int NOT NULL DEFAULT -1 COMMENT ''사이트아이디(참고용)'','
      '  `PLAN_JSON` mediumtext COMMENT ''운영계획서/상세필드 JSON'','
      '  `REG_DATE` varchar(14) NOT NULL COMMENT ''등록일'','
      '  `MOD_DATE` varchar(14) DEFAULT NULL COMMENT ''수정일'','
      '  `STATUS` int NOT NULL DEFAULT 1 COMMENT ''상태(1=정상,0=중지,-1=삭제)'','
      '  PRIMARY KEY (`SUBJECT_ID`),'
      '  KEY `IDX_LM_SUBJECT_PLAN_SITE` (`SITE_ID`,`STATUS`,`SUBJECT_ID`)'
      ') ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT=''교수자 과정 운영계획서 저장''',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

