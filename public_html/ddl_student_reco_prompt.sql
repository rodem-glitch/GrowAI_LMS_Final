-- 학생 추천 프롬프트 저장 테이블
CREATE TABLE IF NOT EXISTS `TB_STUDENT_RECO_PROMPT` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `site_id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `prompt` TEXT NOT NULL,
  `status` INT NOT NULL DEFAULT 1,
  `reg_date` VARCHAR(14) NOT NULL,
  `mod_date` VARCHAR(14) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_site_user` (`site_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
