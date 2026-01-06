-- 왜: JPA ddl-auto가 none이라서, 운영/개발 DB에 테이블을 먼저 만들어야 합니다.
CREATE TABLE TB_RECO_CONTENT (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_nm VARCHAR(100) NOT NULL,
  title       VARCHAR(200) NOT NULL,
  summary     TEXT NOT NULL,
  keywords    VARCHAR(500) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

