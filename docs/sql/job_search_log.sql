-- 채용 자연어 검색어 로그(학생) 기능용 DDL
-- 왜 필요한가:
-- - 교수 화면에서 "내 담당 과목 학생들이 어떤 검색어를 검색했는지(익명)" 통계를 보여주기 위해
--   학생의 검색어를 DB에 기록해야 합니다.
--
-- 설계 원칙:
-- - 멀티사이트: SITE_ID 포함
-- - 개인정보: 학생 이름은 저장하지 않고 USER_ID만 저장(화면에서는 익명 집계)
-- - 단순 집계: QUERY_TEXT(검색어) + REG_DATE(검색 시각)만으로도 충분히 통계가 가능합니다.
-- - MySQL 버전에 따라 `CREATE TABLE IF NOT EXISTS`만으로 부족할 수 있어 information_schema로 “없는 것만” 생성합니다.

SET @tbl := 'TB_JOB_SEARCH_LOG';

-- 1) 테이블 생성
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'CREATE TABLE `TB_JOB_SEARCH_LOG` ('
      '  `ID` int NOT NULL COMMENT ''PK'','
      '  `SITE_ID` int NOT NULL DEFAULT 0 COMMENT ''사이트아이디'','
      '  `USER_ID` int NOT NULL DEFAULT 0 COMMENT ''회원아이디(검색 수행자)'','
      '  `PROVIDER` varchar(20) NOT NULL DEFAULT ''ALL'' COMMENT ''제공처(통합=ALL 고정)'','
      '  `QUERY_TEXT` varchar(200) NOT NULL COMMENT ''검색어(자연어)'','
      '  `REG_DATE` varchar(14) NOT NULL COMMENT ''등록일'','
      '  `STATUS` int NOT NULL DEFAULT 1 COMMENT ''상태(1=정상,0=중지,-1=삭제)'','
      '  PRIMARY KEY (`ID`),'
      '  KEY `IDX_TB_JOB_SEARCH_LOG_USER` (`SITE_ID`,`USER_ID`,`STATUS`,`REG_DATE`),'
      '  KEY `IDX_TB_JOB_SEARCH_LOG_QUERY` (`SITE_ID`,`STATUS`,`QUERY_TEXT`)'
      ') ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT=''채용 자연어 검색어 로그'''
    ,
    'SELECT 1'
  )
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 시퀀스 등록 (왜: Malgn DataObject.getSequence()는 tb_sequence를 기준으로 ID를 발급합니다)
-- 주의: 기존 값이 있으면 건드리지 않습니다.
INSERT IGNORE INTO `tb_sequence` (`ID`, `SEQ`) VALUES ('TB_JOB_SEARCH_LOG', 0);

