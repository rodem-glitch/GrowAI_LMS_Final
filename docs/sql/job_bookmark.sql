-- 채용 북마크(학생) 기능용 DDL
-- 왜 필요한가:
-- - 채용 화면(job-test.html)에는 북마크 버튼 UI가 있지만, 현재는 클릭 시 화면 상태만 바뀌고 DB 저장이 없습니다.
-- - 로그인 사용자(userId)가 "어떤 채용 공고를 저장했는지"를 DB에 남겨야, 나중에 "북마크 목록" 화면을 만들 수 있습니다.
--
-- 설계 원칙:
-- - 멀티사이트: SITE_ID 포함
-- - 유일키: (SITE_ID, USER_ID, PROVIDER, WANTED_AUTH_NO)
-- - 삭제는 소프트삭제(STATUS=-1)로 처리
-- - MySQL 버전에 따라 `CREATE TABLE IF NOT EXISTS`만으로 부족할 수 있어 information_schema로 “없는 것만” 생성합니다.

SET @tbl := 'TB_JOB_BOOKMARK';

-- 1) 테이블 생성
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'CREATE TABLE `TB_JOB_BOOKMARK` ('
      '  `ID` int NOT NULL COMMENT ''PK'','
      '  `SITE_ID` int NOT NULL DEFAULT 0 COMMENT ''사이트아이디'','
      '  `USER_ID` int NOT NULL DEFAULT 0 COMMENT ''회원아이디'','
      '  `PROVIDER` varchar(20) NOT NULL COMMENT ''제공처(WORK24/JOBKOREA 등)'','
      '  `WANTED_AUTH_NO` varchar(60) NOT NULL COMMENT ''공고키(Work24 wantedAuthNo / JobKorea GI_No)'','
      '  `WANTED_INFO_URL` varchar(400) DEFAULT NULL COMMENT ''상세 URL(스냅샷)'','
      '  `TITLE` varchar(300) DEFAULT NULL COMMENT ''공고 제목(스냅샷)'','
      '  `COMPANY` varchar(200) DEFAULT NULL COMMENT ''회사명(스냅샷)'','
      '  `REGION` varchar(200) DEFAULT NULL COMMENT ''지역(스냅샷)'','
      '  `CLOSE_DT` varchar(20) DEFAULT NULL COMMENT ''마감일(스냅샷)'','
      '  `ITEM_JSON` mediumtext COMMENT ''공고 전체 JSON 스냅샷(UI 동일 렌더링용)'','
      '  `REG_DATE` varchar(14) NOT NULL COMMENT ''등록일'','
      '  `MOD_DATE` varchar(14) DEFAULT NULL COMMENT ''수정일'','
      '  `STATUS` int NOT NULL DEFAULT 1 COMMENT ''상태(1=정상,0=중지,-1=삭제)'','
      '  PRIMARY KEY (`ID`),'
      '  UNIQUE KEY `UK_TB_JOB_BOOKMARK_USER` (`SITE_ID`,`USER_ID`,`PROVIDER`,`WANTED_AUTH_NO`),'
      '  KEY `IDX_TB_JOB_BOOKMARK_LIST` (`SITE_ID`,`USER_ID`,`STATUS`,`ID`)'
      ') ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT=''채용 북마크(학생)'''
    ,
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1-1) 컬럼 추가(기존 테이블에 없으면 추가)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `TB_JOB_BOOKMARK` ADD COLUMN `ITEM_JSON` mediumtext COMMENT ''공고 전체 JSON 스냅샷(UI 동일 렌더링용)'' AFTER `CLOSE_DT`',
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = 'ITEM_JSON'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 시퀀스 등록 (왜: Malgn DataObject.getSequence()는 tb_sequence를 기준으로 ID를 발급합니다)
-- 주의: 기존 값이 있으면 건드리지 않습니다.
INSERT IGNORE INTO `tb_sequence` (`ID`, `SEQ`) VALUES ('TB_JOB_BOOKMARK', 0);
