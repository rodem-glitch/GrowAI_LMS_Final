CREATE TABLE TB_KOLLUS_MEDIA (
  id INT NOT NULL,
  site_id INT NOT NULL,
  media_content_key VARCHAR(100) NOT NULL,
  title VARCHAR(255) DEFAULT '',
  snapshot_url VARCHAR(500) DEFAULT '',
  category_key VARCHAR(100) DEFAULT '',
  category_nm VARCHAR(255) DEFAULT '',
  original_file_name VARCHAR(255) DEFAULT '',
  total_time INT DEFAULT 0,
  content_width INT DEFAULT 0,
  content_height INT DEFAULT 0,
  reg_date VARCHAR(14) DEFAULT '',
  mod_date VARCHAR(14) DEFAULT '',
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IDX_KOLLUS_MEDIA_SITE_KEY
  ON TB_KOLLUS_MEDIA (site_id, media_content_key);
