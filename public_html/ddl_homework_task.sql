-- 수행평가(과제) 반복 관리(추가과제/피드백 이력) 기능 추가용 DDL
-- 왜 필요한가:
-- - 기존 `LM_HOMEWORK_USER`는 (HOMEWORK_ID, COURSE_USER_ID) PK라서 학생 1명당 과제 1건만 저장됩니다.
-- - “추가 과제 부여 + 피드백”을 학생별로 여러 번(횟수 제한 없이) 반복하려면, 이력을 누적 저장할 별도 테이블이 필요합니다.
--
-- 주의:
-- - 운영 반영 시 기존 데이터 보호를 위해 `DROP TABLE`은 하지 않습니다.
-- - 이미 테이블/시퀀스가 존재하면 이 스크립트는 “없는 것만” 생성합니다.

-- 1) 추가과제/피드백 이력 테이블
CREATE TABLE IF NOT EXISTS `LM_HOMEWORK_TASK` (
  `ID` int NOT NULL COMMENT '고유값',
  `SITE_ID` int NOT NULL DEFAULT '-1' COMMENT '사이트아이디(참고용)',
  `COURSE_ID` int NOT NULL DEFAULT '0' COMMENT '과정아이디',
  `HOMEWORK_ID` int NOT NULL DEFAULT '0' COMMENT '과제아이디',
  `COURSE_USER_ID` int NOT NULL DEFAULT '0' COMMENT '수강생아이디',
  `USER_ID` int NOT NULL DEFAULT '0' COMMENT '회원아이디',
  `PARENT_ID` int NOT NULL DEFAULT '0' COMMENT '상위ID',
  `ASSIGN_USER_ID` int DEFAULT NULL COMMENT '부여자',
  `TASK` text COMMENT '추가과제 내용',
  `SUBJECT` varchar(255) DEFAULT NULL COMMENT '제목',
  `CONTENT` text COMMENT '내용',
  `SUBMIT_YN` varchar(1) NOT NULL DEFAULT 'N' COMMENT '제출여부',
  `SUBMIT_DATE` varchar(14) DEFAULT NULL COMMENT '제출일시',
  `CONFIRM_YN` varchar(1) NOT NULL DEFAULT 'N' COMMENT '평가여부',
  `CONFIRM_USER_ID` int DEFAULT NULL COMMENT '평가자',
  `CONFIRM_DATE` varchar(14) DEFAULT NULL COMMENT '평가일시',
  `FEEDBACK` text COMMENT '코멘트',
  `IP_ADDR` varchar(20) DEFAULT NULL COMMENT '아이피주소',
  `MOD_DATE` varchar(14) DEFAULT NULL COMMENT '변경일',
  `REG_DATE` varchar(14) DEFAULT NULL COMMENT '등록일',
  `STATUS` int NOT NULL DEFAULT '1' COMMENT '상태',
  PRIMARY KEY (`ID`),
  KEY `IDX_HOMEWORK_USER` (`HOMEWORK_ID`,`COURSE_USER_ID`),
  KEY `IDX_COURSE_USER` (`COURSE_ID`,`COURSE_USER_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COMMENT='과제 추가과제/피드백 이력';

-- 2) 시퀀스(키 생성) 등록
-- 왜: HomeworkTaskDao.getSequence()가 `tb_sequence`의 테이블명(ID)을 사용합니다.
INSERT IGNORE INTO `tb_sequence` (`ID`, `SEQ`) VALUES ('LM_HOMEWORK_TASK', 0);

