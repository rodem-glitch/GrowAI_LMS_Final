-- docker/mysql/init/01-create-tables.sql
-- LMS 감사 로그 테이블

CREATE TABLE IF NOT EXISTS TB_AUDIT_LOG (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(100),
    method_name VARCHAR(100),
    http_method VARCHAR(10),
    request_uri VARCHAR(500),
    client_ip VARCHAR(50),
    duration_ms BIGINT,
    result VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created_at (created_at),
    INDEX idx_client_ip (client_ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 사용자 로그인 로그
CREATE TABLE IF NOT EXISTS TB_USER_LOGIN_LOG (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    site_id BIGINT DEFAULT 1,
    login_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    client_ip VARCHAR(50),
    user_agent VARCHAR(500),
    success_yn CHAR(1) DEFAULT 'Y',
    INDEX idx_login_date (login_date),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- OpenSearch 채용 동기화 로그
CREATE TABLE IF NOT EXISTS TB_JOB_SYNC_LOG (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    job_id VARCHAR(100),
    action VARCHAR(20),
    status VARCHAR(20),
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
