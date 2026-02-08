-- ============================================================================
-- epoly AI LMS - MySQL Database Initialization Script
-- ============================================================================
-- 파일 경로: GoogleAI/sql/init.sql
-- 설명: 한국폴리텍대학 AI 기반 학습관리시스템(LMS) 전체 데이터베이스 초기화
-- 인코딩: utf8mb4_unicode_ci (이모지, 한글 완벽 지원)
-- 엔진: InnoDB (트랜잭션, 외래키 지원)
-- 작성일: 2026-02-08
-- ============================================================================

CREATE DATABASE IF NOT EXISTS epoly_ai
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE epoly_ai;

-- 기존 테이블 삭제 (의존 관계 역순)
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS ai_recommendations;
DROP TABLE IF EXISTS ai_chat_history;
DROP TABLE IF EXISTS content_embeddings;
DROP TABLE IF EXISTS fraud_logs;
DROP TABLE IF EXISTS exam_answers;
DROP TABLE IF EXISTS exam_questions;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS assignment_submissions;
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS attendances;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS grade_criteria;
DROP TABLE IF EXISTS syllabus;
DROP TABLE IF EXISTS lessons;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS login_logs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS lm_sync_log;
DROP TABLE IF EXISTS lm_poly_member_key;
DROP TABLE IF EXISTS lm_poly_member_tmp;
DROP TABLE IF EXISTS lm_poly_member;
DROP TABLE IF EXISTS site_settings;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================================
-- 1. 사용자 관리 (User Management)
-- ============================================================================

CREATE TABLE users (
    member_key   BIGINT       NOT NULL AUTO_INCREMENT COMMENT '회원 고유키',
    user_id      VARCHAR(50)  NOT NULL COMMENT '로그인 ID',
    password_hash VARCHAR(255) NOT NULL COMMENT '비밀번호 해시 (bcrypt)',
    kor_name     VARCHAR(50)  NOT NULL COMMENT '한글 이름',
    eng_name     VARCHAR(100) DEFAULT NULL COMMENT '영문 이름',
    email        VARCHAR(150) DEFAULT NULL COMMENT '이메일 주소',
    mobile       VARCHAR(20)  DEFAULT NULL COMMENT '휴대폰 번호',
    birth_date   DATE         DEFAULT NULL COMMENT '생년월일',
    gender       CHAR(1)      DEFAULT NULL COMMENT '성별 (M/F)',
    user_type    SMALLINT     NOT NULL DEFAULT 10 COMMENT '사용자 유형 (10=학생, 30=교수, 90=관리자)',
    dept_code    VARCHAR(20)  DEFAULT NULL COMMENT '학과 코드',
    dept_name    VARCHAR(100) DEFAULT NULL COMMENT '학과명',
    campus_code  VARCHAR(20)  DEFAULT NULL COMMENT '캠퍼스 코드',
    campus_name  VARCHAR(100) DEFAULT NULL COMMENT '캠퍼스명',
    grade        SMALLINT     DEFAULT NULL COMMENT '학년 (1~4)',
    student_no   VARCHAR(20)  DEFAULT NULL COMMENT '학번',
    status       VARCHAR(20)  NOT NULL DEFAULT 'active' COMMENT '계정 상태 (active/inactive/suspended/graduated)',
    profile_image VARCHAR(500) DEFAULT NULL COMMENT '프로필 이미지 URL',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (member_key),
    UNIQUE KEY uk_users_user_id (user_id),
    INDEX idx_users_user_type (user_type),
    INDEX idx_users_dept_code (dept_code),
    INDEX idx_users_campus_code (campus_code),
    INDEX idx_users_status (status),
    INDEX idx_users_student_no (student_no),
    INDEX idx_users_kor_name (kor_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='사용자 정보 테이블';


-- ============================================================================
-- 2. 강좌 관리 (Course Management)
-- ============================================================================

CREATE TABLE courses (
    course_code   VARCHAR(30)  NOT NULL COMMENT '강좌 코드 (PK)',
    course_name   VARCHAR(200) NOT NULL COMMENT '강좌명',
    category      VARCHAR(100) DEFAULT NULL COMMENT '강좌 카테고리',
    description   TEXT         DEFAULT NULL COMMENT '강좌 설명',
    credit        SMALLINT     DEFAULT 3 COMMENT '학점',
    semester      VARCHAR(20)  DEFAULT NULL COMMENT '학기 (예: 2026-1)',
    professor_key BIGINT       DEFAULT NULL COMMENT '담당 교수 회원키',
    thumbnail     VARCHAR(500) DEFAULT NULL COMMENT '썸네일 이미지 URL',
    status        VARCHAR(20)  NOT NULL DEFAULT 'upcoming' COMMENT '강좌 상태 (active/closed/upcoming)',
    max_students  INT          DEFAULT 40 COMMENT '최대 수강 인원',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (course_code),
    INDEX idx_courses_semester (semester),
    INDEX idx_courses_professor (professor_key),
    INDEX idx_courses_status (status),
    INDEX idx_courses_category (category),
    CONSTRAINT fk_courses_professor FOREIGN KEY (professor_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='강좌 정보 테이블';


-- ============================================================================
-- 3. 수강 신청 (Enrollment)
-- ============================================================================

CREATE TABLE enrollments (
    id          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '수강 ID',
    course_code VARCHAR(30) NOT NULL COMMENT '강좌 코드',
    member_key  BIGINT      NOT NULL COMMENT '회원 고유키',
    enrolled_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수강 신청일시',
    status      VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '수강 상태 (active/completed/dropped)',
    progress    TINYINT     NOT NULL DEFAULT 0 COMMENT '진도율 (0~100)',
    last_access DATETIME    DEFAULT NULL COMMENT '최종 접속일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_enrollment_course_member (course_code, member_key),
    INDEX idx_enrollments_member (member_key),
    INDEX idx_enrollments_status (status),
    INDEX idx_enrollments_enrolled_at (enrolled_at),
    CONSTRAINT fk_enrollments_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='수강 신청 테이블';


-- ============================================================================
-- 4. 차시/수업 계획 (Lessons / LectPlan)
-- ============================================================================

CREATE TABLE lessons (
    id              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '차시 ID',
    course_code     VARCHAR(30)  NOT NULL COMMENT '강좌 코드',
    week            SMALLINT     NOT NULL COMMENT '주차 (1~16)',
    seq             SMALLINT     NOT NULL DEFAULT 1 COMMENT '주차 내 순서',
    title           VARCHAR(300) NOT NULL COMMENT '차시 제목',
    description     TEXT         DEFAULT NULL COMMENT '차시 설명',
    type            VARCHAR(20)  NOT NULL DEFAULT 'video' COMMENT '콘텐츠 유형 (video/document/link/scorm)',
    content_url     VARCHAR(1000) DEFAULT NULL COMMENT '콘텐츠 URL',
    duration_minutes INT         DEFAULT 0 COMMENT '학습 시간 (분)',
    valid_from      DATETIME     DEFAULT NULL COMMENT '학습 시작 가능일',
    valid_to        DATETIME     DEFAULT NULL COMMENT '학습 마감일',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_lessons_course_week_seq (course_code, week, seq),
    INDEX idx_lessons_course_code (course_code),
    INDEX idx_lessons_week (week),
    INDEX idx_lessons_type (type),
    INDEX idx_lessons_valid_period (valid_from, valid_to),
    CONSTRAINT fk_lessons_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='차시(수업) 정보 테이블';


-- ============================================================================
-- 5. 출석 관리 (Attendance)
-- ============================================================================

CREATE TABLE attendances (
    id              BIGINT      NOT NULL AUTO_INCREMENT COMMENT '출석 ID',
    lesson_id       BIGINT      NOT NULL COMMENT '차시 ID',
    member_key      BIGINT      NOT NULL COMMENT '회원 고유키',
    status          VARCHAR(20) NOT NULL DEFAULT 'absent' COMMENT '출석 상태 (present/absent/late/excused)',
    watched_seconds INT         DEFAULT 0 COMMENT '시청 시간 (초)',
    checked_at      DATETIME    DEFAULT NULL COMMENT '출석 체크 일시',
    ip_address      VARCHAR(45) DEFAULT NULL COMMENT '접속 IP 주소',
    user_agent      VARCHAR(500) DEFAULT NULL COMMENT '브라우저 User-Agent',

    PRIMARY KEY (id),
    UNIQUE KEY uk_attendance_lesson_member (lesson_id, member_key),
    INDEX idx_attendances_member (member_key),
    INDEX idx_attendances_status (status),
    INDEX idx_attendances_checked_at (checked_at),
    CONSTRAINT fk_attendances_lesson FOREIGN KEY (lesson_id) REFERENCES lessons (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_attendances_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='출석 관리 테이블';


-- ============================================================================
-- 6. 부정행위 탐지 (Anti-Fraud)
-- ============================================================================

CREATE TABLE fraud_logs (
    id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '부정행위 로그 ID',
    member_key   BIGINT       NOT NULL COMMENT '회원 고유키',
    course_code  VARCHAR(30)  DEFAULT NULL COMMENT '강좌 코드',
    fraud_type   VARCHAR(50)  NOT NULL COMMENT '부정행위 유형 (ip_change/multi_device/rapid_progress/screen_capture/proxy)',
    severity     VARCHAR(20)  NOT NULL DEFAULT 'low' COMMENT '심각도 (low/medium/high/critical)',
    details      JSON         DEFAULT NULL COMMENT '상세 내용 (JSON)',
    ip_address   VARCHAR(45)  DEFAULT NULL COMMENT '접속 IP 주소',
    fingerprint  VARCHAR(255) DEFAULT NULL COMMENT '브라우저 핑거프린트',
    detected_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '탐지 일시',

    PRIMARY KEY (id),
    INDEX idx_fraud_member (member_key),
    INDEX idx_fraud_course (course_code),
    INDEX idx_fraud_type (fraud_type),
    INDEX idx_fraud_severity (severity),
    INDEX idx_fraud_detected_at (detected_at),
    INDEX idx_fraud_member_course (member_key, course_code),
    CONSTRAINT fk_fraud_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='부정행위 탐지 로그 테이블';


-- ============================================================================
-- 7. 과제 관리 (Assignments)
-- ============================================================================

CREATE TABLE assignments (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '과제 ID',
    course_code VARCHAR(30)  NOT NULL COMMENT '강좌 코드',
    week        SMALLINT     DEFAULT NULL COMMENT '주차',
    title       VARCHAR(300) NOT NULL COMMENT '과제 제목',
    description TEXT         DEFAULT NULL COMMENT '과제 설명',
    due_date    DATETIME     DEFAULT NULL COMMENT '제출 마감일',
    max_score   INT          NOT NULL DEFAULT 100 COMMENT '최대 점수',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_assignments_course (course_code),
    INDEX idx_assignments_week (course_code, week),
    INDEX idx_assignments_due_date (due_date),
    CONSTRAINT fk_assignments_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='과제 정보 테이블';


CREATE TABLE assignment_submissions (
    id            BIGINT    NOT NULL AUTO_INCREMENT COMMENT '제출 ID',
    assignment_id BIGINT    NOT NULL COMMENT '과제 ID',
    member_key    BIGINT    NOT NULL COMMENT '회원 고유키',
    content       TEXT      DEFAULT NULL COMMENT '제출 내용',
    file_url      VARCHAR(1000) DEFAULT NULL COMMENT '첨부파일 URL',
    score         INT       DEFAULT NULL COMMENT '점수',
    feedback      TEXT      DEFAULT NULL COMMENT '교수 피드백',
    submitted_at  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '제출일시',
    graded_at     DATETIME  DEFAULT NULL COMMENT '채점일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_submission_assignment_member (assignment_id, member_key),
    INDEX idx_submissions_member (member_key),
    INDEX idx_submissions_submitted_at (submitted_at),
    INDEX idx_submissions_graded_at (graded_at),
    CONSTRAINT fk_submissions_assignment FOREIGN KEY (assignment_id) REFERENCES assignments (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_submissions_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='과제 제출 테이블';


-- ============================================================================
-- 8. 시험 관리 (Exams)
-- ============================================================================

CREATE TABLE exams (
    id               BIGINT       NOT NULL AUTO_INCREMENT COMMENT '시험 ID',
    course_code      VARCHAR(30)  NOT NULL COMMENT '강좌 코드',
    week             SMALLINT     DEFAULT NULL COMMENT '주차',
    title            VARCHAR(300) NOT NULL COMMENT '시험 제목',
    exam_type        VARCHAR(20)  NOT NULL DEFAULT 'quiz' COMMENT '시험 유형 (midterm/final/quiz)',
    duration_minutes INT          DEFAULT 60 COMMENT '시험 시간 (분)',
    start_time       DATETIME     DEFAULT NULL COMMENT '시험 시작 시간',
    end_time         DATETIME     DEFAULT NULL COMMENT '시험 종료 시간',
    total_score      INT          NOT NULL DEFAULT 100 COMMENT '총점',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_exams_course (course_code),
    INDEX idx_exams_type (exam_type),
    INDEX idx_exams_period (start_time, end_time),
    INDEX idx_exams_course_week (course_code, week),
    CONSTRAINT fk_exams_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='시험 정보 테이블';


CREATE TABLE exam_questions (
    id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '문항 ID',
    exam_id       BIGINT       NOT NULL COMMENT '시험 ID',
    seq           SMALLINT     NOT NULL COMMENT '문항 순서',
    question_text TEXT         NOT NULL COMMENT '문제 내용',
    question_type VARCHAR(20)  NOT NULL DEFAULT 'mc' COMMENT '문항 유형 (mc=객관식/short=단답형/essay=서술형)',
    options       JSON         DEFAULT NULL COMMENT '선택지 (객관식 JSON 배열)',
    correct_answer VARCHAR(1000) DEFAULT NULL COMMENT '정답',
    score         INT          NOT NULL DEFAULT 0 COMMENT '배점',

    PRIMARY KEY (id),
    UNIQUE KEY uk_exam_question_seq (exam_id, seq),
    INDEX idx_questions_exam (exam_id),
    INDEX idx_questions_type (question_type),
    CONSTRAINT fk_questions_exam FOREIGN KEY (exam_id) REFERENCES exams (id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='시험 문항 테이블';


CREATE TABLE exam_answers (
    id           BIGINT   NOT NULL AUTO_INCREMENT COMMENT '답안 ID',
    question_id  BIGINT   NOT NULL COMMENT '문항 ID',
    member_key   BIGINT   NOT NULL COMMENT '회원 고유키',
    answer_text  TEXT     DEFAULT NULL COMMENT '답안 내용',
    score        INT      DEFAULT NULL COMMENT '득점',
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '제출일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_answer_question_member (question_id, member_key),
    INDEX idx_answers_member (member_key),
    INDEX idx_answers_submitted_at (submitted_at),
    CONSTRAINT fk_answers_question FOREIGN KEY (question_id) REFERENCES exam_questions (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_answers_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='시험 답안 테이블';


-- ============================================================================
-- 9. 성적 관리 (Grades)
-- ============================================================================

CREATE TABLE grades (
    id               BIGINT        NOT NULL AUTO_INCREMENT COMMENT '성적 ID',
    course_code      VARCHAR(30)   NOT NULL COMMENT '강좌 코드',
    member_key       BIGINT        NOT NULL COMMENT '회원 고유키',
    midterm          DECIMAL(5,2)  DEFAULT NULL COMMENT '중간고사 점수',
    final_exam       DECIMAL(5,2)  DEFAULT NULL COMMENT '기말고사 점수',
    assignment       DECIMAL(5,2)  DEFAULT NULL COMMENT '과제 점수',
    attendance_score DECIMAL(5,2)  DEFAULT NULL COMMENT '출석 점수',
    total            DECIMAL(5,2)  DEFAULT NULL COMMENT '총점',
    grade_letter     VARCHAR(5)    DEFAULT NULL COMMENT '학점 등급 (A+/A/B+/B/C+/C/D+/D/F)',
    is_completed     TINYINT(1)    NOT NULL DEFAULT 0 COMMENT '성적 확정 여부',
    completed_at     DATETIME      DEFAULT NULL COMMENT '성적 확정일시',
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_grades_course_member (course_code, member_key),
    INDEX idx_grades_member (member_key),
    INDEX idx_grades_grade_letter (grade_letter),
    INDEX idx_grades_is_completed (is_completed),
    CONSTRAINT fk_grades_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_grades_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='성적 관리 테이블';


-- ============================================================================
-- 10. 게시판/게시글 (Board / Posts)
-- ============================================================================

CREATE TABLE boards (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '게시글 ID',
    board_type  VARCHAR(20)  NOT NULL COMMENT '게시판 유형 (notice/faq/qna/forum)',
    course_code VARCHAR(30)  DEFAULT NULL COMMENT '강좌 코드 (NULL=전체 게시판)',
    title       VARCHAR(500) NOT NULL COMMENT '제목',
    content     TEXT         NOT NULL COMMENT '내용',
    author_key  BIGINT       NOT NULL COMMENT '작성자 회원키',
    is_pinned   TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '상단 고정 여부',
    view_count  INT          NOT NULL DEFAULT 0 COMMENT '조회수',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일시',
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (id),
    INDEX idx_boards_type (board_type),
    INDEX idx_boards_course (course_code),
    INDEX idx_boards_author (author_key),
    INDEX idx_boards_pinned_created (is_pinned DESC, created_at DESC),
    INDEX idx_boards_type_course (board_type, course_code),
    INDEX idx_boards_created_at (created_at DESC),
    CONSTRAINT fk_boards_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_boards_author FOREIGN KEY (author_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='게시판 테이블';


CREATE TABLE comments (
    id         BIGINT   NOT NULL AUTO_INCREMENT COMMENT '댓글 ID',
    board_id   BIGINT   NOT NULL COMMENT '게시글 ID',
    author_key BIGINT   NOT NULL COMMENT '작성자 회원키',
    content    TEXT     NOT NULL COMMENT '댓글 내용',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일시',

    PRIMARY KEY (id),
    INDEX idx_comments_board (board_id),
    INDEX idx_comments_author (author_key),
    INDEX idx_comments_created_at (created_at),
    CONSTRAINT fk_comments_board FOREIGN KEY (board_id) REFERENCES boards (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_comments_author FOREIGN KEY (author_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='댓글 테이블';


-- ============================================================================
-- 11. AI / 벡터 검색 (AI Chat, Recommendations, Embeddings)
-- ============================================================================

CREATE TABLE ai_chat_history (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'AI 채팅 ID',
    member_key  BIGINT       NOT NULL COMMENT '회원 고유키',
    session_id  VARCHAR(100) NOT NULL COMMENT '채팅 세션 ID',
    role        VARCHAR(20)  NOT NULL COMMENT '메시지 역할 (user/assistant)',
    message     TEXT         NOT NULL COMMENT '메시지 내용',
    model       VARCHAR(50)  DEFAULT NULL COMMENT 'AI 모델명',
    tokens_used INT          DEFAULT 0 COMMENT '사용 토큰 수',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_ai_chat_member (member_key),
    INDEX idx_ai_chat_session (session_id),
    INDEX idx_ai_chat_member_session (member_key, session_id),
    INDEX idx_ai_chat_created_at (created_at),
    CONSTRAINT fk_ai_chat_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 채팅 이력 테이블';


CREATE TABLE ai_recommendations (
    id                  BIGINT       NOT NULL AUTO_INCREMENT COMMENT '추천 ID',
    member_key          BIGINT       NOT NULL COMMENT '회원 고유키',
    recommendation_type VARCHAR(30)  NOT NULL COMMENT '추천 유형 (course/content/career)',
    target_id           VARCHAR(100) DEFAULT NULL COMMENT '추천 대상 ID (강좌코드 또는 콘텐츠 ID)',
    score               DECIMAL(5,4) DEFAULT NULL COMMENT '추천 점수 (0~1)',
    reason              TEXT         DEFAULT NULL COMMENT '추천 사유',
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_ai_rec_member (member_key),
    INDEX idx_ai_rec_type (recommendation_type),
    INDEX idx_ai_rec_member_type (member_key, recommendation_type),
    INDEX idx_ai_rec_score (score DESC),
    INDEX idx_ai_rec_created_at (created_at),
    CONSTRAINT fk_ai_rec_member FOREIGN KEY (member_key) REFERENCES users (member_key)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 추천 정보 테이블';


CREATE TABLE content_embeddings (
    id             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '임베딩 ID',
    content_type   VARCHAR(30)  NOT NULL COMMENT '콘텐츠 유형 (lesson/course)',
    content_id     VARCHAR(100) NOT NULL COMMENT '콘텐츠 ID',
    embedding_text TEXT         NOT NULL COMMENT '임베딩 원본 텍스트',
    vector_id      VARCHAR(255) DEFAULT NULL COMMENT 'Qdrant 벡터 ID',
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_embeddings_type (content_type),
    INDEX idx_embeddings_content (content_type, content_id),
    INDEX idx_embeddings_vector_id (vector_id),
    UNIQUE KEY uk_embeddings_type_content (content_type, content_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='콘텐츠 벡터 임베딩 테이블 (Qdrant 연동)';


-- ============================================================================
-- 12. 동기화 테이블 (Sync - poly_sync)
-- ============================================================================

CREATE TABLE lm_poly_member (
    id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '레코드 ID',
    member_key   BIGINT       DEFAULT NULL COMMENT '매핑된 회원키',
    poly_id      VARCHAR(50)  NOT NULL COMMENT '폴리텍 학사 시스템 ID',
    kor_name     VARCHAR(50)  DEFAULT NULL COMMENT '한글 이름',
    dept_code    VARCHAR(20)  DEFAULT NULL COMMENT '학과 코드',
    dept_name    VARCHAR(100) DEFAULT NULL COMMENT '학과명',
    campus_code  VARCHAR(20)  DEFAULT NULL COMMENT '캠퍼스 코드',
    campus_name  VARCHAR(100) DEFAULT NULL COMMENT '캠퍼스명',
    user_type    SMALLINT     DEFAULT NULL COMMENT '사용자 유형',
    student_no   VARCHAR(20)  DEFAULT NULL COMMENT '학번',
    status       VARCHAR(20)  DEFAULT 'active' COMMENT '상태',
    synced_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '동기화 일시',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_poly_member_poly_id (poly_id),
    INDEX idx_poly_member_key (member_key),
    INDEX idx_poly_member_synced (synced_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='폴리텍 학사 동기화 회원 테이블 (mirror)';


CREATE TABLE lm_poly_member_tmp (
    id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '레코드 ID',
    poly_id      VARCHAR(50)  NOT NULL COMMENT '폴리텍 학사 시스템 ID',
    kor_name     VARCHAR(50)  DEFAULT NULL COMMENT '한글 이름',
    dept_code    VARCHAR(20)  DEFAULT NULL COMMENT '학과 코드',
    dept_name    VARCHAR(100) DEFAULT NULL COMMENT '학과명',
    campus_code  VARCHAR(20)  DEFAULT NULL COMMENT '캠퍼스 코드',
    campus_name  VARCHAR(100) DEFAULT NULL COMMENT '캠퍼스명',
    user_type    SMALLINT     DEFAULT NULL COMMENT '사용자 유형',
    student_no   VARCHAR(20)  DEFAULT NULL COMMENT '학번',
    batch_id     VARCHAR(50)  DEFAULT NULL COMMENT '배치 처리 ID',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_poly_tmp_poly_id (poly_id),
    INDEX idx_poly_tmp_batch (batch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='폴리텍 학사 동기화 임시 테이블';


CREATE TABLE lm_poly_member_key (
    id         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '레코드 ID',
    poly_id    VARCHAR(50) NOT NULL COMMENT '폴리텍 학사 시스템 ID',
    member_key BIGINT      NOT NULL COMMENT '매핑된 LMS 회원키',
    mapped_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '매핑일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_poly_key_poly_id (poly_id),
    UNIQUE KEY uk_poly_key_member (member_key),
    INDEX idx_poly_key_mapped (mapped_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='폴리텍 학사 ID - LMS 회원키 매핑 테이블';


CREATE TABLE lm_sync_log (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '동기화 로그 ID',
    sync_type   VARCHAR(50)  NOT NULL COMMENT '동기화 유형 (member/course/enrollment)',
    direction   VARCHAR(20)  NOT NULL DEFAULT 'import' COMMENT '동기화 방향 (import/export)',
    total_count INT          DEFAULT 0 COMMENT '전체 건수',
    success_count INT        DEFAULT 0 COMMENT '성공 건수',
    fail_count  INT          DEFAULT 0 COMMENT '실패 건수',
    error_detail TEXT        DEFAULT NULL COMMENT '오류 상세',
    batch_id    VARCHAR(50)  DEFAULT NULL COMMENT '배치 처리 ID',
    started_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '시작일시',
    finished_at DATETIME     DEFAULT NULL COMMENT '종료일시',
    status      VARCHAR(20)  NOT NULL DEFAULT 'running' COMMENT '상태 (running/completed/failed)',

    PRIMARY KEY (id),
    INDEX idx_sync_log_type (sync_type),
    INDEX idx_sync_log_status (status),
    INDEX idx_sync_log_started (started_at),
    INDEX idx_sync_log_batch (batch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='데이터 동기화 로그 테이블';


-- ============================================================================
-- 13. 시스템 설정 및 로그인 로그 (System)
-- ============================================================================

CREATE TABLE site_settings (
    setting_key   VARCHAR(100) NOT NULL COMMENT '설정 키 (PK)',
    setting_value TEXT         DEFAULT NULL COMMENT '설정 값',
    description   VARCHAR(500) DEFAULT NULL COMMENT '설정 설명',
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='사이트 설정 테이블';


CREATE TABLE login_logs (
    id         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '로그인 로그 ID',
    member_key BIGINT       DEFAULT NULL COMMENT '회원 고유키 (로그인 실패 시 NULL 가능)',
    user_id    VARCHAR(50)  DEFAULT NULL COMMENT '시도한 로그인 ID',
    ip_address VARCHAR(45)  DEFAULT NULL COMMENT '접속 IP 주소',
    user_agent VARCHAR(500) DEFAULT NULL COMMENT '브라우저 User-Agent',
    success    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '로그인 성공 여부',
    fail_reason VARCHAR(100) DEFAULT NULL COMMENT '실패 사유',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    INDEX idx_login_member (member_key),
    INDEX idx_login_user_id (user_id),
    INDEX idx_login_ip (ip_address),
    INDEX idx_login_success (success),
    INDEX idx_login_created_at (created_at),
    INDEX idx_login_member_created (member_key, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='로그인 로그 테이블';


-- ============================================================================
-- 14. 강의 계획서 (Syllabus)
-- ============================================================================

CREATE TABLE syllabus (
    id                   BIGINT      NOT NULL AUTO_INCREMENT COMMENT '강의 계획서 ID',
    course_code          VARCHAR(30) NOT NULL COMMENT '강좌 코드',
    overview             TEXT        DEFAULT NULL COMMENT '강좌 개요',
    objectives           TEXT        DEFAULT NULL COMMENT '학습 목표',
    evaluation_criteria  JSON        DEFAULT NULL COMMENT '평가 기준 (JSON)',
    textbooks            JSON        DEFAULT NULL COMMENT '교재 정보 (JSON 배열)',
    weekly_plan          JSON        DEFAULT NULL COMMENT '주차별 계획 (JSON 배열)',
    created_at           DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at           DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_syllabus_course (course_code),
    CONSTRAINT fk_syllabus_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='강의 계획서 테이블';


-- ============================================================================
-- 15. 성적 배점 기준 (Grade Criteria)
-- ============================================================================

CREATE TABLE grade_criteria (
    id                BIGINT       NOT NULL AUTO_INCREMENT COMMENT '배점 기준 ID',
    course_code       VARCHAR(30)  NOT NULL COMMENT '강좌 코드',
    midterm_ratio     DECIMAL(5,2) NOT NULL DEFAULT 30.00 COMMENT '중간고사 비율 (%)',
    final_ratio       DECIMAL(5,2) NOT NULL DEFAULT 30.00 COMMENT '기말고사 비율 (%)',
    assignment_ratio  DECIMAL(5,2) NOT NULL DEFAULT 20.00 COMMENT '과제 비율 (%)',
    attendance_ratio  DECIMAL(5,2) NOT NULL DEFAULT 20.00 COMMENT '출석 비율 (%)',
    is_locked         TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '확정 잠금 여부',
    created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',

    PRIMARY KEY (id),
    UNIQUE KEY uk_grade_criteria_course (course_code),
    CONSTRAINT fk_grade_criteria_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='성적 배점 기준 테이블';


-- ============================================================================
-- 초기 데이터 삽입 (Initial Data)
-- ============================================================================

-- --------------------------------------------------------------------------
-- 기본 관리자 계정
-- 비밀번호: admin1234 (bcrypt 해시)
-- --------------------------------------------------------------------------
INSERT INTO users (user_id, password_hash, kor_name, eng_name, email, user_type, status)
VALUES (
    'admin',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '시스템관리자',
    'System Admin',
    'admin@epoly.ac.kr',
    90,
    'active'
);

-- --------------------------------------------------------------------------
-- 샘플 교수 계정
-- --------------------------------------------------------------------------
INSERT INTO users (user_id, password_hash, kor_name, eng_name, email, user_type, dept_code, dept_name, campus_code, campus_name, status)
VALUES (
    'prof_kim',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '김교수',
    'Prof. Kim',
    'prof.kim@epoly.ac.kr',
    30,
    'CSE',
    '컴퓨터공학과',
    'SEOUL',
    '서울캠퍼스',
    'active'
);

-- --------------------------------------------------------------------------
-- 샘플 학생 계정
-- --------------------------------------------------------------------------
INSERT INTO users (user_id, password_hash, kor_name, eng_name, email, user_type, dept_code, dept_name, campus_code, campus_name, grade, student_no, status)
VALUES (
    'student_lee',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '이학생',
    'Lee Student',
    'student.lee@epoly.ac.kr',
    10,
    'CSE',
    '컴퓨터공학과',
    'SEOUL',
    '서울캠퍼스',
    2,
    '2024010001',
    'active'
);

-- --------------------------------------------------------------------------
-- 사이트 설정 초기값
-- --------------------------------------------------------------------------
INSERT INTO site_settings (setting_key, setting_value, description) VALUES
    ('site.name', 'epoly AI LMS', '사이트 이름'),
    ('site.description', '한국폴리텍대학 AI 기반 학습관리시스템', '사이트 설명'),
    ('site.logo_url', '/assets/images/logo.png', '사이트 로고 URL'),
    ('site.favicon_url', '/assets/images/favicon.ico', '파비콘 URL'),
    ('site.primary_color', '#1E40AF', '사이트 주 색상'),
    ('site.semester.current', '2026-1', '현재 학기'),
    ('site.semester.start_date', '2026-03-02', '학기 시작일'),
    ('site.semester.end_date', '2026-06-20', '학기 종료일'),
    ('auth.session_timeout_minutes', '120', '세션 만료 시간 (분)'),
    ('auth.max_login_attempts', '5', '최대 로그인 시도 횟수'),
    ('auth.lockout_duration_minutes', '30', '계정 잠금 시간 (분)'),
    ('auth.password_min_length', '8', '비밀번호 최소 길이'),
    ('auth.jwt_expiry_hours', '24', 'JWT 토큰 만료 시간'),
    ('attendance.min_watch_ratio', '0.8', '출석 인정 최소 시청 비율'),
    ('attendance.late_threshold_minutes', '15', '지각 기준 시간 (분)'),
    ('fraud.detection_enabled', 'true', '부정행위 탐지 활성화'),
    ('fraud.ip_change_threshold', '3', 'IP 변경 감지 임계값'),
    ('fraud.rapid_progress_threshold', '0.5', '비정상 진도 탈출 임계값 (비율)'),
    ('ai.chat_enabled', 'true', 'AI 챗봇 활성화'),
    ('ai.model_name', 'gemini-2.0-flash', 'AI 모델명'),
    ('ai.max_tokens_per_request', '4096', 'AI 요청당 최대 토큰'),
    ('ai.recommendation_enabled', 'true', 'AI 추천 활성화'),
    ('ai.embedding_model', 'text-embedding-004', '임베딩 모델명'),
    ('ai.qdrant_collection', 'epoly_content', 'Qdrant 컬렉션명'),
    ('upload.max_file_size_mb', '100', '최대 업로드 파일 크기 (MB)'),
    ('upload.allowed_extensions', 'pdf,doc,docx,ppt,pptx,xls,xlsx,hwp,hwpx,zip,jpg,png,mp4', '허용 파일 확장자'),
    ('notification.email_enabled', 'false', '이메일 알림 활성화'),
    ('notification.sms_enabled', 'false', 'SMS 알림 활성화'),
    ('system.maintenance_mode', 'false', '유지보수 모드'),
    ('system.version', '1.0.0', '시스템 버전');

-- --------------------------------------------------------------------------
-- 샘플 강좌 데이터
-- --------------------------------------------------------------------------
INSERT INTO courses (course_code, course_name, category, description, credit, semester, professor_key, status, max_students)
VALUES
    ('CSE101-2026-1', 'Python 프로그래밍 기초', '컴퓨터공학', 'Python 언어의 기본 문법과 프로그래밍 개념을 학습합니다.', 3, '2026-1', 2, 'active', 40),
    ('CSE201-2026-1', '데이터베이스 설계', '컴퓨터공학', 'MySQL 기반 데이터베이스 설계 및 SQL 활용을 학습합니다.', 3, '2026-1', 2, 'active', 35),
    ('CSE301-2026-1', '인공지능 개론', '컴퓨터공학', 'AI/ML 기초 이론과 실습을 통해 인공지능의 원리를 이해합니다.', 3, '2026-1', 2, 'upcoming', 30);

-- --------------------------------------------------------------------------
-- 샘플 수강 신청
-- --------------------------------------------------------------------------
INSERT INTO enrollments (course_code, member_key, status, progress)
VALUES
    ('CSE101-2026-1', 3, 'active', 25),
    ('CSE201-2026-1', 3, 'active', 10);

-- --------------------------------------------------------------------------
-- 샘플 공지사항 게시글
-- --------------------------------------------------------------------------
INSERT INTO boards (board_type, course_code, title, content, author_key, is_pinned)
VALUES
    ('notice', NULL, '2026학년도 1학기 수강신청 안내', '2026학년도 1학기 수강신청 기간은 2월 15일부터 2월 28일까지입니다.\n\n수강신청 시 유의사항:\n1. 수강 가능 학점은 최대 21학점입니다.\n2. 선수과목을 반드시 확인하시기 바랍니다.\n3. 수강정정 기간은 3월 2일~3월 6일입니다.', 1, 1),
    ('notice', NULL, 'epoly AI LMS 시스템 오픈 안내', 'AI 기반 학습관리시스템이 정식 오픈되었습니다.\n\n주요 기능:\n- AI 학습 도우미 챗봇\n- 맞춤형 콘텐츠 추천\n- 부정행위 탐지 시스템\n- 실시간 학습 분석\n\n문의사항은 관리자에게 연락 바랍니다.', 1, 1),
    ('faq', NULL, '비밀번호를 잊어버렸어요', '로그인 페이지에서 "비밀번호 찾기"를 클릭하신 후, 등록된 이메일로 비밀번호 재설정 링크를 받으실 수 있습니다.', 1, 0),
    ('faq', NULL, '출석이 인정되지 않아요', '출석이 인정되려면 해당 차시 영상의 80% 이상을 시청해야 합니다. 영상을 빨리감기하거나 건너뛴 경우 출석이 인정되지 않을 수 있습니다.', 1, 0),
    ('notice', 'CSE101-2026-1', '[Python 기초] 1주차 강의 안내', '1주차 Python 프로그래밍 기초 강의가 업로드되었습니다.\n\n학습 내용:\n- Python 설치 및 개발환경 설정\n- 변수와 자료형\n- 입출력 함수\n\n3월 8일까지 학습을 완료해 주세요.', 2, 0);

-- --------------------------------------------------------------------------
-- 샘플 차시 데이터
-- --------------------------------------------------------------------------
INSERT INTO lessons (course_code, week, seq, title, description, type, duration_minutes, valid_from, valid_to)
VALUES
    ('CSE101-2026-1', 1, 1, 'Python 소개 및 설치', 'Python 프로그래밍 언어의 특징과 개발환경 설정', 'video', 50, '2026-03-02 00:00:00', '2026-03-08 23:59:59'),
    ('CSE101-2026-1', 1, 2, '변수와 자료형', '정수, 실수, 문자열 등 기본 자료형 학습', 'video', 45, '2026-03-02 00:00:00', '2026-03-08 23:59:59'),
    ('CSE101-2026-1', 1, 3, '1주차 실습 자료', '1주차 실습 예제 코드 및 과제 안내', 'document', 0, '2026-03-02 00:00:00', '2026-03-08 23:59:59'),
    ('CSE101-2026-1', 2, 1, '조건문과 반복문', 'if, elif, else와 for, while 문법', 'video', 55, '2026-03-09 00:00:00', '2026-03-15 23:59:59'),
    ('CSE101-2026-1', 2, 2, '함수 정의와 호출', 'def 키워드를 이용한 함수 작성', 'video', 50, '2026-03-09 00:00:00', '2026-03-15 23:59:59'),
    ('CSE201-2026-1', 1, 1, '데이터베이스 개념', '데이터베이스의 정의와 DBMS 개요', 'video', 60, '2026-03-02 00:00:00', '2026-03-08 23:59:59'),
    ('CSE201-2026-1', 1, 2, 'MySQL 설치 및 설정', 'MySQL 8.0 설치와 기본 설정 방법', 'video', 40, '2026-03-02 00:00:00', '2026-03-08 23:59:59');

-- --------------------------------------------------------------------------
-- 샘플 성적 배점 기준
-- --------------------------------------------------------------------------
INSERT INTO grade_criteria (course_code, midterm_ratio, final_ratio, assignment_ratio, attendance_ratio)
VALUES
    ('CSE101-2026-1', 30.00, 30.00, 20.00, 20.00),
    ('CSE201-2026-1', 25.00, 35.00, 20.00, 20.00);

-- --------------------------------------------------------------------------
-- 샘플 강의 계획서
-- --------------------------------------------------------------------------
INSERT INTO syllabus (course_code, overview, objectives, evaluation_criteria, textbooks, weekly_plan)
VALUES (
    'CSE101-2026-1',
    'Python 프로그래밍의 기본 문법과 개념을 학습하여 프로그래밍적 사고력을 기르는 과목입니다.',
    '1. Python 기본 문법을 이해하고 활용할 수 있다.\n2. 조건문, 반복문, 함수를 이용한 프로그램을 작성할 수 있다.\n3. 파일 입출력과 예외처리를 구현할 수 있다.\n4. 간단한 데이터 분석 프로그램을 작성할 수 있다.',
    '{"midterm": 30, "final": 30, "assignment": 20, "attendance": 20}',
    '[{"title": "점프 투 파이썬", "author": "박응용", "publisher": "이지스퍼블리싱"}]',
    '[{"week": 1, "topic": "Python 소개 및 개발환경 설정"}, {"week": 2, "topic": "변수, 자료형, 연산자"}, {"week": 3, "topic": "조건문 (if/elif/else)"}, {"week": 4, "topic": "반복문 (for/while)"}, {"week": 5, "topic": "함수 정의와 활용"}, {"week": 6, "topic": "리스트, 튜플, 딕셔너리"}, {"week": 7, "topic": "문자열 처리"}, {"week": 8, "topic": "중간고사"}, {"week": 9, "topic": "파일 입출력"}, {"week": 10, "topic": "예외처리"}, {"week": 11, "topic": "클래스와 객체"}, {"week": 12, "topic": "모듈과 패키지"}, {"week": 13, "topic": "데이터 분석 기초 (pandas)"}, {"week": 14, "topic": "데이터 시각화 (matplotlib)"}, {"week": 15, "topic": "종합 프로젝트"}, {"week": 16, "topic": "기말고사"}]'
);


-- ============================================================================
-- 데이터 무결성 확인
-- ============================================================================
SELECT '============================================' AS '';
SELECT '  epoly AI LMS Database Initialized' AS '';
SELECT '============================================' AS '';
SELECT CONCAT('  Tables created: ', COUNT(*)) AS '' FROM information_schema.tables WHERE table_schema = 'epoly_ai';
SELECT '' AS '';
SELECT TABLE_NAME AS 'Table', TABLE_ROWS AS 'Rows', TABLE_COMMENT AS 'Description'
FROM information_schema.tables
WHERE table_schema = 'epoly_ai'
ORDER BY ORDINAL_POSITION;
SELECT '' AS '';
SELECT '  Initialization complete.' AS '';
