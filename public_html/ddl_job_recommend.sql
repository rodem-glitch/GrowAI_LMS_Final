-- 교수 추천 채용공고 저장 테이블
CREATE TABLE IF NOT EXISTS `TB_JOB_RECOMMEND` (
  `id` int NOT NULL COMMENT 'PK',
  `site_id` int NOT NULL DEFAULT '0' COMMENT '사이트ID',
  `tutor_user_id` int NOT NULL DEFAULT '0' COMMENT '추천 교수ID',
  `course_id` int NOT NULL DEFAULT '0' COMMENT '과목ID',
  `student_user_id` int NOT NULL DEFAULT '0' COMMENT '추천 받은 학생ID',
  `provider` varchar(20) DEFAULT NULL COMMENT '제공처',
  `wanted_auth_no` varchar(60) DEFAULT NULL COMMENT '공고키',
  `wanted_info_url` varchar(400) DEFAULT NULL COMMENT '공고 URL',
  `title` varchar(300) DEFAULT NULL COMMENT '공고명',
  `company` varchar(200) DEFAULT NULL COMMENT '회사명',
  `region` varchar(200) DEFAULT NULL COMMENT '지역',
  `close_dt` varchar(20) DEFAULT NULL COMMENT '마감일',
  `item_json` mediumtext COMMENT '공고 스냅샷 JSON',
  `status` int NOT NULL DEFAULT '1' COMMENT '상태(1=정상,-1=삭제)',
  `reg_date` varchar(14) DEFAULT NULL COMMENT '등록일',
  `mod_date` varchar(14) DEFAULT NULL COMMENT '수정일',
  PRIMARY KEY (`id`),
  KEY `idx_job_recommend_student` (`site_id`,`student_user_id`,`status`),
  UNIQUE KEY `uk_job_recommend_once` (`site_id`,`student_user_id`,`provider`,`wanted_auth_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='교수 추천 채용공고';

-- tb_sequence 보완(없으면 추가)
INSERT INTO `tb_sequence` (`id`, `seq`)
SELECT 'TB_JOB_RECOMMEND', 0
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM `tb_sequence` WHERE `id` = 'TB_JOB_RECOMMEND');

