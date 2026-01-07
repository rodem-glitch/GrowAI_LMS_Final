-- 왜: KOSIS 인구 통계를 DB에 캐시하기 위한 테이블을 로컬 환경에서 자동 생성합니다.
-- 주의: 운영에서는 DBA/마이그레이션 도구로 DDL을 관리하는 것을 권장드립니다.

CREATE TABLE IF NOT EXISTS kosis_population (
    `year`      VARCHAR(4)   NOT NULL,
    `age_type`  VARCHAR(8)   NOT NULL,
    `gender`    VARCHAR(2)   NOT NULL,
    `adm_cd`    VARCHAR(20)  NOT NULL,
    `adm_nm`    VARCHAR(200) NOT NULL,
    `population` BIGINT      NOT NULL,
    PRIMARY KEY (`year`, `age_type`, `gender`, `adm_cd`)
);

