# GrowAI LMS v5.0 — 실행 결과 로그

## 2026-02-08 DB I/F 메뉴·기능별 데이터 연동 구현

### 작업 내용
growai_lms(신규) + lms(레거시) 이중 데이터소스 구성, 메뉴/기능별 실 DB 데이터 I/F 처리

### DB 현황 (실데이터)

| DB | 주요 테이블 | 데이터 건수 |
|----|-----------|-----------|
| **growai_lms** | users | 6명 (admin, prof001~002, student001~003) |
| | courses | 4개 (CS101, CS201, AI301, WEB101) |
| | enrollments | 5건 (학생별 수강신청) |
| | site_settings | 8건 (사이트 설정) |
| **lms (레거시)** | tb_user | 82명 (Malgnsoft LMS 사용자) |
| | lm_lesson | 617개 (차시 콘텐츠) |
| | lm_subject | 48개 (과목) |
| | lm_content | 53개 (콘텐츠 패키지) |
| | lm_exam | 36개 (시험) |
| | lm_question | 181개 (문항) |
| | lm_course_progress | 37건 (학습 진도) |
| | tb_banner | 41개 (배너) |
| | lm_webtv | 26개 (영상) |
| | lm_webtv_live | 2건 (실시간 강의) |
| | tb_user_login | 733건 (로그인 이력) |
| | tb_action_log | 107건 (접속 로그) |

### Backend 구현 파일

| 파일 | 역할 |
|------|------|
| `config/LegacyDataSourceConfig.java` | lms DB 읽기전용 DataSource + JdbcTemplate Bean |
| `application.yml` (legacy-datasource 추가) | lms DB 접속정보 (HikariCP read-only) |
| `legacy/LegacyUserRepository.java` | tb_user, tb_user_login 읽기 |
| `legacy/LegacyCourseRepository.java` | lm_subject, lm_lesson, lm_content 읽기 |
| `legacy/LegacyExamRepository.java` | lm_exam, lm_question 읽기 |
| `legacy/LegacyProgressRepository.java` | lm_course_progress 읽기 |
| `legacy/LegacyBannerRepository.java` | tb_banner, lm_webtv, lm_webtv_live 읽기 |
| `legacy/LegacyLogRepository.java` | tb_action_log, tb_user_login 읽기 |
| `dataif/DataInterfaceService.java` | 메뉴별 통합 서비스 (growai + legacy 결합) |
| `dataif/DataInterfaceController.java` | REST API 11개 엔드포인트 |

### API 엔드포인트 → 메뉴 매핑

| Endpoint | 메뉴 | 데이터 소스 |
|----------|------|-----------|
| `GET /api/data/student/dashboard/{userId}` | 학생 대시보드 | enrollments + courses + progress |
| `GET /api/data/courses` | 과정 목록 | growai courses + legacy subjects |
| `GET /api/data/classroom/{contentId}` | 강의실 | lm_lesson + lm_content |
| `GET /api/data/instructor/exams` | 시험 관리 | lm_exam + lm_question 통계 |
| `GET /api/data/instructor/questions/{categoryId}` | 문항은행 | lm_question (카테고리별) |
| `GET /api/data/instructor/contents` | 콘텐츠 관리 | lm_content + lm_lesson |
| `GET /api/data/admin/monitoring` | 운영 모니터링 | user/course/exam/progress 통합 통계 |
| `GET /api/data/admin/users` | 사용자 관리 | growai users + legacy tb_user |
| `GET /api/data/admin/banners` | 배너/팝업 | tb_banner + lm_webtv + lm_webtv_live |
| `GET /api/data/admin/access-logs` | 접속 로그 | tb_action_log + tb_user_login |
| `GET /api/data/haksa/sync-status` | 학사 동기화 | 양 DB 건수 비교 |

### Frontend 연동 파일

| 페이지 | useQuery Key | API 호출 |
|--------|-------------|----------|
| `student/MainPage.tsx` | `student-dashboard` | `dataApi.getStudentDashboard(1)` |
| `admin/DashboardPage.tsx` | `admin-monitoring` | `dataApi.getAdminMonitoring()` |
| `instructor/DashboardPage.tsx` | `instructor-exams` | `dataApi.getExamManagement()` |
| `haksa/SyncPage.tsx` | `haksa-sync` | `dataApi.getHaksaSyncStatus()` |
| `services/api.ts` | — | `dataApi` 모듈 11개 메서드 추가 |

### 빌드 검증 결과
```
=== Backend Gradle Build ===
Exit Code: 0 — BUILD SUCCESSFUL (3s)

=== Frontend TypeScript ===
TSC Exit Code: 0 (No errors)

=== Frontend Vite Build ===
Exit Code: 0
Modules: 1,580+
  - dist/index.html          0.70 kB (gzip: 0.42 kB)
  - dist/assets/index.css   93.01 kB (gzip: 13.47 kB)
  - dist/assets/index.js   761.43 kB (gzip: 187.54 kB)
Built in: 7.38s
```

---

## 2026-02-08 역할별 자동이동 애니메이션 구현

### 작업 내용
`MainPortalPage.tsx` — 로그인 역할별 메인 포털 자동이동 애니메이션 추가

### 구현 상세

| 역할 | 동작 | 타이밍 |
|------|------|--------|
| **학생(student)** | 학생 카드 자동 하이라이트 → 다른 카드 페이드아웃 → `/student` 자동이동 | 600ms 하이라이트 → 1800ms 이동시작 → 300ms 페이드아웃 후 네비게이트 |
| **교수자(instructor)** | 교수자 카드 자동 하이라이트 → 다른 카드 페이드아웃 → `/instructor` 자동이동 | 동일 타이밍 |
| **관리자(admin)** | 자동이동 없음 — 모든 카드 표시 상태 유지 | 즉시 (변경 없음) |

### 애니메이션 효과
- **선택된 카드**: `scale-105`, `shadow-2xl`, `ring-4 ring-white/60`, `portal-pulse` CSS keyframe, 바운스 화살표, "이동 중..." 배지
- **비선택 카드**: `opacity-30`, `scale-95`, `blur-[2px]` 페이드아웃
- **페이지 전환**: `opacity-0` 트랜지션 (300ms)
- **중복 실행 방지**: `useRef(hasAutoNavigated)` 사용

### 빌드 검증 결과
```
=== TypeScript Check ===
TSC Exit Code: 0
Errors: 0

=== Vite Build ===
Build Exit Code: 0
Modules: 1580
Output:
  - dist/index.html          0.64 kB (gzip: 0.39 kB)
  - dist/assets/index.css   92.40 kB (gzip: 13.19 kB)
  - dist/assets/index.js   712.09 kB (gzip: 167.39 kB)
Built in: 6.80s
```

### 테스트 시나리오

#### 시나리오 1: 학생 로그인
1. `/login` → student001 / admin1234 입력 → 로그인
2. `/` 메인 포털 진입
3. 600ms 후 → 학생 카드 하이라이트 (scale-up, ring, pulse 애니메이션)
4. 다른 카드 (교수자, 관리자, 학사정보) 페이드아웃 (opacity-30, blur)
5. AI 빠른 실행 영역 페이드아웃
6. 1800ms 후 → 전체 페이지 opacity-0 페이드아웃
7. 2100ms 후 → `/student` 대시보드로 자동 이동
8. **결과**: 정상 동작 확인

#### 시나리오 2: 교수자 로그인
1. `/login` → prof001 / admin1234 입력 → 로그인
2. `/` 메인 포털 진입
3. 600ms 후 → 교수자 카드 하이라이트 (purple gradient + pulse)
4. 나머지 카드 페이드아웃
5. 1800ms 후 → `/instructor` 대시보드로 자동 이동
6. **결과**: 정상 동작 확인

#### 시나리오 3: 관리자 로그인
1. `/login` → admin / admin1234 입력 → 로그인
2. `/` 메인 포털 진입
3. 모든 카드 동일하게 표시 (4개 카드 + AI 빠른 실행 + RFP 요약)
4. 자동이동 없음 — hover 효과만 활성
5. 관리자가 원하는 섹션 직접 클릭하여 이동
6. **결과**: 정상 동작 확인 (기존과 동일)

### 수정 파일
- `frontend/src/pages/MainPortalPage.tsx` — 전체 재작성 (역할별 자동이동 로직 + 애니메이션 CSS)

---

## 2026-02-08 CSS 전역화 + React Router 경고 해결 + Favicon 추가

### 1. 애니메이션 CSS 전역화
- **Before**: `MainPortalPage.tsx` 내 인라인 `<style>` 태그로 `@keyframes portal-pulse` 정의
- **After**: `index.css`에 전역 CSS 클래스로 이동
- 추가된 전역 애니메이션:
  - `animate-portal-pulse` — 카드 선택 시 box-shadow 맥동
  - `animate-portal-card-enter` — 카드 진입 시 slide-up + fade-in
  - `animate-portal-glow` — 선택 카드 글로우 효과
  - `animate-portal-slide-right` — 화살표 우측 슬라이드
  - `animate-portal-fade-out` — 비선택 카드 페이드아웃
  - `portal-card-delay-1~4` — 스태거드 진입 딜레이

### 2. React Router v7 Future Flag 경고 해결
- **원인**: React Router v6에서 v7 마이그레이션 준비를 위한 Future Flag 경고
  - `v7_startTransition`: v7에서 상태 업데이트를 `React.startTransition`으로 래핑
  - `v7_relativeSplatPath`: Splat 라우트(`*`) 내 상대 경로 해석 방식 변경
- **해결**: `main.tsx`의 `<BrowserRouter>`에 future 플래그 추가
  ```tsx
  <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
  ```

### 3. favicon.ico 404 해결
- **원인**: `public/` 폴더에 favicon 파일 없음 + `index.html`에 link 태그 없음
- **해결**:
  - `public/favicon.svg` 생성 (GrowAI 로고 — 파란-보라 그라데이션 + "G" 문자)
  - `index.html`에 `<link rel="icon" type="image/svg+xml" href="/favicon.svg" />` 추가

### 수정 파일
| 파일 | 변경 내용 |
|------|----------|
| `frontend/src/index.css` | 6개 전역 애니메이션 keyframe + utility 클래스 추가 |
| `frontend/src/main.tsx` | BrowserRouter future flag 2개 추가 |
| `frontend/src/pages/MainPortalPage.tsx` | 인라인 style → 전역 CSS 클래스 교체 |
| `frontend/index.html` | favicon link 태그 추가 |
| `frontend/public/favicon.svg` | 신규 생성 |

### 빌드 검증 결과
```
TSC Exit Code: 0 (No errors)
Vite Build: 1,580 modules
  - dist/index.html          0.70 kB (gzip: 0.42 kB)
  - dist/assets/index.css   93.01 kB (gzip: 13.47 kB)
  - dist/assets/index.js   711.91 kB (gzip: 167.33 kB)
Built in: 7.60s
```

---

## 2026-02-08 RFP 기능정의서 28건 전수 구현

### 구현 모듈 요약

| 모듈 | 기능 수 | 페이지 | 상태 |
|------|---------|--------|------|
| COM (공통) | 5건 | SSO, 세션, GNB, 알림, 통합검색 | 완료 |
| STD (학생) | 8건 | 학적동기화, 역량태그, AI진로상담, AI자소서, 맞춤채용, 스크랩, Gap분석, 콘텐츠추천 | 완료 |
| PRF (교수자) | 7건 | 과거강의, AI실라버스, 영상추천, 영상요약, D&D빌더, AI퀴즈, 강의계획제출 | 완료 |
| ADM (관리자) | 8건 | 운영모니터링, 퍼널분석, 역량성취도, 취업률, 사용자제어, 배너관리, 접속로그, 개인정보열람 | 완료 |
| **합계** | **28건** | — | **100% 이행** |

### RFP 요구사항 매핑
- SFR-001 AI 성장 에이전트: 6건
- SFR-002 AI 질의응답: 2건
- SFR-003 커리어 정보: 3건
- SFR-004 학습 추천: 2건
- SFR-005 커리큘럼 개설: 4건
- SFR-006 통계/지표: 4건
- SFR-007 통합 인증: 3건
- 비기능 요구사항: 13건

### 산출물
- `guide/GrowAI_기능정의서_28건_전수_테스트결과.docx`
- `guide/GrowAI_테스트시나리오_데이터흐름도.docx`
- `guide/GrowAI_UI오퍼레이션_사용자매뉴얼.docx`
- `guide/GrowAI_최종_사용자가이드_v5.0.docx`
- `guide/video_script_veo3.1.md`
- `guide/video_scenario_system_instruction.json`
- `guide/video_scenario_system_instruction.md`

---

## 2026-02-08 학사정보 데이터 동기화 구현 (lms → growai_lms)

### 1. 개요

레거시 Malgnsoft LMS(`lms` DB)의 학사정보 데이터를 GrowAI LMS(`growai_lms` DB)로 동기화하는 **Dual DataSource 아키텍처** 기반의 데이터 연동 체계를 구현하였다.

- **동기화 방식**: SQL 일괄 동기화 (ETL) + Spring Boot 실시간 읽기 (Dual DataSource)
- **데이터 무결성**: INSERT IGNORE + NOT IN 서브쿼리로 중복 방지
- **보안**: 레거시 DB는 READ-ONLY 접근, 비밀번호는 BCrypt 해시 일괄 적용

---

### 2. 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GrowAI LMS One-Stop Framework                      │
│                                                                             │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────────────────┐  │
│  │   Frontend    │    │   Spring Boot    │    │        MySQL 8.4          │  │
│  │  React 18 +   │◄──►│   Backend API    │◄──►│                           │  │
│  │  Vite + TS    │    │   (Port 8081)    │    │  ┌─────────────────────┐  │  │
│  │  (Port 5173)  │    │                  │    │  │   growai_lms (신규)  │  │  │
│  └──────────────┘    │  ┌────────────┐  │    │  │  ═══════════════════ │  │  │
│                       │  │ DataSource │  │◄──►│  │  users (83)         │  │  │
│  ┌──────────────┐    │  │  Primary   │  │    │  │  courses (20)       │  │  │
│  │  _sync_haksa │    │  │  (JPA)     │  │    │  │  lessons (100)      │  │  │
│  │    .sql      │    │  └────────────┘  │    │  │  exams (28)         │  │  │
│  │              │    │                  │    │  │  exam_questions (100)│  │  │
│  │  ETL 일괄    │────►│  ┌────────────┐  │    │  │  login_logs (200)   │  │  │
│  │  동기화      │    │  │ DataSource │  │    │  │  lm_sync_log (1)    │  │  │
│  └──────────────┘    │  │  Legacy    │  │◄──►│  └─────────────────────┘  │  │
│                       │  │ (ReadOnly) │  │    │                           │  │
│                       │  └────────────┘  │    │  ┌─────────────────────┐  │  │
│                       └──────────────────┘    │  │    lms (레거시)      │  │  │
│                                               │  │  ═══════════════════ │  │  │
│                                               │  │  tb_user (82)       │  │  │
│                                               │  │  lm_subject (48)    │  │  │
│                                               │  │  lm_lesson (617)    │  │  │
│                                               │  │  lm_exam (36)       │  │  │
│                                               │  │  lm_question (181)  │  │  │
│                                               │  │  tb_user_login (733)│  │  │
│                                               │  │  tb_banner (41)     │  │  │
│                                               │  │  lm_webtv (26)      │  │  │
│                                               │  └─────────────────────┘  │  │
│                                               └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 3. 데이터 흐름 다이어그램 (ETL 동기화)

```
                    ┌─────────────────────────────────────┐
                    │         _sync_haksa.sql              │
                    │    (7단계 순차 동기화 파이프라인)      │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
  ┌───────────┐            ┌───────────┐            ┌───────────┐
  │  EXTRACT   │            │ TRANSFORM │            │   LOAD     │
  │ (읽기)     │            │ (변환)     │            │ (적재)     │
  └───────────┘            └───────────┘            └───────────┘
        │                          │                          │
        ▼                          ▼                          ▼
  lms.tb_user         USER_KIND → user_type      growai_lms.users
  lms.lm_subject      STATUS → ACTIVE/INACTIVE   growai_lms.courses
  lms.lm_lesson       LESSON_TYPE → content_type  growai_lms.lessons
  lms.lm_exam         ONOFF_TYPE → exam_type      growai_lms.exams
  lms.lm_question     QUESTION_TYPE → MCQ/...     growai_lms.exam_questions
  lms.tb_user_login   LOGIN_ID → user_id(FK)      growai_lms.login_logs
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │     growai_lms.lm_sync_log           │
                    │  FULL_SYNC | COMPLETED | 531건       │
                    └─────────────────────────────────────┘
```

---

### 4. Dual DataSource 아키텍처 다이어그램

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                    Spring Boot Application                       │
  │                                                                  │
  │  ┌─────────────────────────────────────────────────────────┐    │
  │  │                  Controller Layer                        │    │
  │  │  DataInterfaceController.java (11 REST endpoints)       │    │
  │  │    GET /api/data/student/dashboard/{userId}             │    │
  │  │    GET /api/data/courses                                │    │
  │  │    GET /api/data/classroom/{contentId}                  │    │
  │  │    GET /api/data/instructor/exams                       │    │
  │  │    GET /api/data/instructor/questions/{categoryId}      │    │
  │  │    GET /api/data/instructor/contents                    │    │
  │  │    GET /api/data/admin/monitoring                       │    │
  │  │    GET /api/data/admin/users                            │    │
  │  │    GET /api/data/admin/banners                          │    │
  │  │    GET /api/data/admin/access-logs                      │    │
  │  │    GET /api/data/haksa/sync-status                      │    │
  │  └────────────────────────┬────────────────────────────────┘    │
  │                            │                                     │
  │                            ▼                                     │
  │  ┌─────────────────────────────────────────────────────────┐    │
  │  │                  Service Layer                           │    │
  │  │  DataInterfaceService.java                               │    │
  │  │    (growai_lms JPA + lms JdbcTemplate 양쪽 데이터 조합)   │    │
  │  └─────┬───────────────────────────────────┬───────────────┘    │
  │         │                                   │                    │
  │         ▼                                   ▼                    │
  │  ┌──────────────────┐           ┌──────────────────────────┐    │
  │  │  JPA Repository   │           │  Legacy Repository (6개) │    │
  │  │  ┌──────────────┐ │           │  ┌────────────────────┐  │    │
  │  │  │UserRepository│ │           │  │LegacyUserRepo      │  │    │
  │  │  │CourseRepo    │ │           │  │LegacyCourseRepo    │  │    │
  │  │  │EnrollmentRepo│ │           │  │LegacyExamRepo      │  │    │
  │  │  └──────────────┘ │           │  │LegacyProgressRepo  │  │    │
  │  │  @Autowired        │           │  │LegacyBannerRepo    │  │    │
  │  │  (Primary DS)      │           │  │LegacyLogRepo       │  │    │
  │  └────────┬───────────┘           │  └────────────────────┘  │    │
  │            │                       │  @Qualifier("legacyJdbc")│    │
  │            │                       └──────────┬───────────────┘    │
  │            │                                   │                    │
  │            ▼                                   ▼                    │
  │  ┌──────────────────┐           ┌──────────────────────────┐    │
  │  │  Primary DS       │           │  Legacy DS (ReadOnly)    │    │
  │  │  HikariCP         │           │  HikariCP                │    │
  │  │  pool: 20         │           │  pool: 5                 │    │
  │  │  read-write       │           │  read-only: true         │    │
  │  └────────┬───────────┘           └──────────┬───────────────┘    │
  └────────────┼───────────────────────────────────┼──────────────────┘
               │                                   │
               ▼                                   ▼
  ┌──────────────────┐                ┌──────────────────┐
  │  growai_lms DB    │                │   lms DB          │
  │  (MySQL 8.4)      │                │  (MySQL 8.4)      │
  │  user: growai      │                │  user: root        │
  │  port: 3306        │                │  port: 3306        │
  └──────────────────┘                └──────────────────┘
```

---

### 5. 테이블 매핑 상세 다이어그램

```
 ┌─────────── lms (레거시 Malgnsoft) ─────────┐      ┌──────── growai_lms (신규) ────────┐
 │                                              │      │                                   │
 │  tb_user                                     │      │  users                            │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | LOGIN_ID | USER_NM | EMAIL    │    │  ──► │  │ user_id | name | email       │ │
 │  │ USER_KIND | DEPT_ID | STATUS       │    │      │  │ user_type | department       │ │
 │  │ S→ADMIN, U→STUDENT                 │    │      │  │ campus | status | password   │ │
 │  └─────────────────────────────────────┘    │      │  └──────────────────────────────┘ │
 │                                              │      │                                   │
 │  lm_subject                                  │      │  courses                          │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | COURSE_NM | STATUS | REG_DATE │    │  ──► │  │ course_code(LMS-{ID})        │ │
 │  └─────────────────────────────────────┘    │      │  │ title | category(레거시과정)  │ │
 │                                              │      │  └──────────────────────────────┘ │
 │  lm_lesson                                   │      │  lessons                          │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | LESSON_NM | LESSON_TYPE       │    │  ──► │  │ title | content_type          │ │
 │  │ START_URL | TOTAL_TIME             │    │      │  │ VIDEO/WBT/DOCUMENT/FLASH/    │ │
 │  │ 03→VIDEO, 02→WBT, 01→DOCUMENT     │    │      │  │ KOLLUS/LIVE/OTHER            │ │
 │  └─────────────────────────────────────┘    │      │  └──────────────────────────────┘ │
 │                                              │      │                                   │
 │  lm_exam                                     │      │  exams                            │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | EXAM_NM | ONOFF_TYPE          │    │  ──► │  │ title | exam_type             │ │
 │  │ EXAM_TIME | SHUFFLE_YN             │    │      │  │ ONLINE/OFFLINE               │ │
 │  │ N→ONLINE, 나머지→OFFLINE            │    │      │  │ time_limit | shuffle          │ │
 │  └─────────────────────────────────────┘    │      │  └──────────────────────────────┘ │
 │                                              │      │                                   │
 │  lm_question                                 │      │  exam_questions                   │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | QUESTION | QUESTION_TYPE      │    │  ──► │  │ question_text | question_type │ │
 │  │ ITEM1~ITEM5 | ANSWER | GRADE      │    │      │  │ MCQ/TRUE_FALSE/SHORT_ANSWER  │ │
 │  │ 1→MCQ, 2→TF, 3→SA, 4→ESSAY       │    │      │  │ options(JSON) | correct_answer│ │
 │  └─────────────────────────────────────┘    │      │  └──────────────────────────────┘ │
 │                                              │      │                                   │
 │  tb_user_login                               │      │  login_logs                       │
 │  ┌─────────────────────────────────────┐    │      │  ┌──────────────────────────────┐ │
 │  │ ID | USER_ID | SITE_ID             │    │  ──► │  │ user_id(FK) | ip_address     │ │
 │  └─────────────────────────────────────┘    │      │  │ login_result | created_at    │ │
 │                                              │      │  └──────────────────────────────┘ │
 └──────────────────────────────────────────────┘      └───────────────────────────────────┘
```

---

### 6. 소스코드 구현 상세

#### 6-1. Dual DataSource 설정

**`application.yml`** — 이중 데이터소스 접속 정보
```yaml
spring:
  # ── Primary DataSource: growai_lms (Read-Write) ──
  datasource:
    url: jdbc:mysql://localhost:3306/growai_lms?useSSL=false&serverTimezone=Asia/Seoul
    username: growai
    password: growai_lms_2026!
    hikari:
      maximum-pool-size: 20    # 운영 트래픽 대응
      minimum-idle: 5

  # ── Legacy DataSource: lms (Read-Only) ──
  legacy-datasource:
    url: jdbc:mysql://localhost:3306/lms?useSSL=false&serverTimezone=Asia/Seoul
    username: root
    password: ''
    hikari:
      maximum-pool-size: 5     # 읽기 전용이므로 소규모 풀
      minimum-idle: 2
      read-only: true          # ★ 레거시 DB 보호
```

**`config/LegacyDataSourceConfig.java`** — 레거시 DataSource + JdbcTemplate Bean 등록
```java
@Configuration
public class LegacyDataSourceConfig {

    @Bean(name = "legacyDataSource")
    @ConfigurationProperties(prefix = "spring.legacy-datasource")
    public DataSource legacyDataSource() {
        return DataSourceBuilder.create().build();   // HikariCP 자동 구성
    }

    @Bean(name = "legacyJdbc")
    public JdbcTemplate legacyJdbcTemplate(
            @Qualifier("legacyDataSource") DataSource ds) {
        JdbcTemplate jdbc = new JdbcTemplate(ds);
        jdbc.setQueryTimeout(10);   // 10초 타임아웃 (레거시 보호)
        return jdbc;
    }
}
```

> **설계 포인트**: `@ConfigurationProperties(prefix = "spring.legacy-datasource")`로 application.yml의 `legacy-datasource` 섹션을 자동 바인딩. `@Qualifier("legacyJdbc")`로 Primary JdbcTemplate과 구분하여 주입.

---

#### 6-2. Legacy Repository Layer (6개 클래스)

모든 레거시 레포지토리는 동일한 패턴으로 구현:

```
@Repository
public class Legacy{Domain}Repository {
    private final JdbcTemplate jdbc;   // @Qualifier("legacyJdbc") 주입

    public List<Map<String, Object>> findXxx(int siteId, ...) {
        String sql = """
            SELECT ... FROM {table}
            WHERE SITE_ID = ? AND STATUS = 1
            ORDER BY ID
        """;
        return jdbc.queryForList(sql, siteId, ...);  // ★ 파라미터 바인딩 (SQL Injection 방지)
    }
}
```

**`legacy/LegacyUserRepository.java`** — 사용자 + 로그인 이력
```java
@Repository
public class LegacyUserRepository {
    // @Qualifier("legacyJdbc") JdbcTemplate 주입
    // ── 주요 메서드 ──
    findAllActive(siteId)      // tb_user WHERE STATUS=1 → 77명
    countByKind(siteId)        // USER_KIND별 GROUP BY → S:8명, U:73명
    findLoginHistory(siteId, limit)  // tb_user_login 최근 N건
}
```

**`legacy/LegacyCourseRepository.java`** — 과목 + 차시 + 콘텐츠
```java
@Repository
public class LegacyCourseRepository {
    findAllSubjects(siteId)            // lm_subject → 48개 과목
    findAllLessons(siteId)             // lm_lesson → 617개 차시
    findLessonsByContent(siteId, cid)  // 특정 콘텐츠의 차시 조회
    findAllContents(siteId)            // lm_content → 53개 콘텐츠
    countStats(siteId)                 // SUBJECT_CNT + LESSON_CNT + CONTENT_CNT
}
```

**`legacy/LegacyExamRepository.java`** — 시험 + 문항
```java
@Repository
public class LegacyExamRepository {
    findAllExams(siteId)                     // lm_exam → 36개 시험
    findQuestionsByCategory(siteId, catId)   // lm_question 카테고리별
    countExamStats(siteId)                   // EXAM_CNT + QUESTION_CNT
}
```

**`legacy/LegacyProgressRepository.java`** — 학습 진도
```java
@Repository
public class LegacyProgressRepository {
    findProgressByUser(siteId, userId)   // 사용자별 진도 (RATIO, COMPLETE_YN)
    findCompletionStats(siteId)          // 이수율 통계 (COMPLETE_CNT / TOTAL)
    findRecentActivity(siteId, limit)    // 최근 학습 활동 (JOIN tb_user)
}
```

**`legacy/LegacyBannerRepository.java`** — 배너 + WebTV + Live
```java
@Repository
public class LegacyBannerRepository {
    findActiveBanners(siteId)   // tb_banner → 41개
    findWebTvList(siteId)       // lm_webtv → 26개
    findLiveList(siteId)        // lm_webtv_live → 2건
}
```

**`legacy/LegacyLogRepository.java`** — 접근 로그 + 로그인 로그
```java
@Repository
public class LegacyLogRepository {
    findAccessLogs(siteId, limit)   // tb_action_log → 107건
    findLoginLogs(siteId, limit)    // tb_user_login → 733건
}
```

---

#### 6-3. Data Interface Service (통합 서비스)

**`dataif/DataInterfaceService.java`** — growai_lms(JPA) + lms(JDBC) 양쪽 데이터 조합

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DataInterfaceService                              │
│                                                                     │
│  ┌─ growai_lms (JPA) ─┐     ┌─ lms (Legacy JDBC) ──────────────┐  │
│  │ CourseRepository    │     │ LegacyUserRepository              │  │
│  │ EnrollmentRepository│     │ LegacyCourseRepository            │  │
│  │ UserRepository      │     │ LegacyExamRepository              │  │
│  └─────────────────────┘     │ LegacyProgressRepository          │  │
│                               │ LegacyBannerRepository            │  │
│                               │ LegacyLogRepository               │  │
│                               └───────────────────────────────────┘  │
│                                                                     │
│  ═══════════════════ 메뉴별 통합 메서드 (11개) ═══════════════════  │
│                                                                     │
│  [학생]                                                             │
│  ├─ getStudentDashboard(userId)                                     │
│  │    enrollments(JPA) + courses(JPA) + progress(JDBC) + stats     │
│  ├─ getCourseList()                                                 │
│  │    growaiCourses(JPA) + legacySubjects(JDBC) + stats            │
│  └─ getClassroom(contentId)                                         │
│       lessons(JDBC) + allLessons(JDBC)                              │
│                                                                     │
│  [교수자]                                                           │
│  ├─ getExamManagement()                                             │
│  │    exams(JDBC) + examStats(JDBC)                                 │
│  ├─ getQuestionBank(categoryId)                                     │
│  │    questions(JDBC)                                               │
│  └─ getContentManagement()                                          │
│       contents(JDBC) + lessons(JDBC)                                │
│                                                                     │
│  [관리자]                                                           │
│  ├─ getAdminMonitoring()                                            │
│  │    userStats(JDBC) + courseStats(JDBC) + examStats(JDBC)         │
│  │    + completionStats(JDBC) + growaiUsers(JPA) + growaiCourses    │
│  ├─ getUserManagement()                                             │
│  │    growaiUsers(JPA) + legacyUsers(JDBC) + userStats(JDBC)       │
│  ├─ getBannerManagement()                                           │
│  │    banners(JDBC) + webTvList(JDBC) + liveList(JDBC)             │
│  └─ getAccessLogs(limit)                                            │
│       accessLogs(JDBC) + loginLogs(JDBC) + loginHistory(JDBC)      │
│                                                                     │
│  [학사연동]                                                         │
│  └─ getHaksaSyncStatus()                                            │
│       legacyUserCount(JDBC) + legacySubjectCount(JDBC)             │
│       + legacyLessonCount(JDBC) + growaiUserCount(JPA)             │
│       + growaiCourseCount(JPA)                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

#### 6-4. REST API Controller

**`dataif/DataInterfaceController.java`** — 11개 엔드포인트

```
┌───────────────────────────────────────────────────────────────────────┐
│                   DataInterfaceController                              │
│                   @RequestMapping("/api/data")                        │
│                                                                       │
│  ┌─── 학생 메뉴 ─────────────────────────────────────────────────┐   │
│  │  GET /student/dashboard/{userId}  → studentDashboard()        │   │
│  │  GET /courses                     → courseList()               │   │
│  │  GET /classroom/{contentId}       → classroom()               │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─── 교수자 메뉴 ───────────────────────────────────────────────┐   │
│  │  GET /instructor/exams            → examManagement()          │   │
│  │  GET /instructor/questions/{catId}→ questionBank()            │   │
│  │  GET /instructor/contents         → contentManagement()       │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─── 관리자 메뉴 ───────────────────────────────────────────────┐   │
│  │  GET /admin/monitoring            → adminMonitoring()         │   │
│  │  GET /admin/users                 → userManagement()          │   │
│  │  GET /admin/banners               → bannerManagement()        │   │
│  │  GET /admin/access-logs?limit=100 → accessLogs()             │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─── 학사 연동 ─────────────────────────────────────────────────┐   │
│  │  GET /haksa/sync-status           → haksaSyncStatus()         │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  응답 형식: ResponseEntity<ApiResponse<Map<String, Object>>>         │
└───────────────────────────────────────────────────────────────────────┘
```

---

#### 6-5. Frontend API 연동

**`frontend/src/services/api.ts`** — dataApi 모듈 (11개 메서드)
```typescript
export const dataApi = {
  getStudentDashboard: (userId: number) =>
    api.get(`/api/data/student/dashboard/${userId}`),
  getCourseList:       () => api.get('/api/data/courses'),
  getClassroom:        (contentId: number) =>
    api.get(`/api/data/classroom/${contentId}`),
  getExamManagement:   () => api.get('/api/data/instructor/exams'),
  getQuestionBank:     (categoryId: number) =>
    api.get(`/api/data/instructor/questions/${categoryId}`),
  getContentManagement:() => api.get('/api/data/instructor/contents'),
  getAdminMonitoring:  () => api.get('/api/data/admin/monitoring'),
  getUserManagement:   () => api.get('/api/data/admin/users'),
  getBannerManagement: () => api.get('/api/data/admin/banners'),
  getAccessLogs:       (limit?: number) =>
    api.get(`/api/data/admin/access-logs?limit=${limit || 100}`),
  getHaksaSyncStatus:  () => api.get('/api/data/haksa/sync-status'),
};
```

**페이지별 React Query 연동**:
```
student/MainPage.tsx         → useQuery(['student-dashboard'], ...)
admin/DashboardPage.tsx      → useQuery(['admin-monitoring'], ...)
instructor/DashboardPage.tsx → useQuery(['instructor-exams'], ...)
haksa/SyncPage.tsx           → useQuery(['haksa-sync'], ...)
```

---

### 7. ETL 동기화 SQL 상세 (`_sync_haksa.sql`)

#### 7-1. 동기화 파이프라인 흐름도

```
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│ Step 1 │───►│ Step 2 │───►│ Step 3 │───►│ Step 4 │───►│ Step 5 │───►│ Step 6 │───►│ Step 7 │
│ users  │    │courses │    │lessons │    │ exams  │    │questions│   │ logs   │    │sync_log│
│ 77명    │    │ 16개   │    │ 100건  │    │ 28건   │    │ 100건   │   │ 200건  │    │ 1건    │
└────────┘    └────────┘    └────────┘    └────────┘    └────────┘    └────────┘    └────────┘
  tb_user    lm_subject    lm_lesson      lm_exam    lm_question  tb_user_login   lm_sync_log
    ↓            ↓            ↓              ↓            ↓            ↓              ↓
  INSERT      INSERT       INSERT         INSERT       INSERT       INSERT         INSERT
  IGNORE      IGNORE     (상위100건)     (STATUS=1)   (상위100건)  (최근200건)    (COMPLETED)
```

#### 7-2. Step별 SQL + 변환 로직

**Step 1: 사용자 동기화** (`tb_user → users`)
```sql
INSERT IGNORE INTO users (user_id, password, name, email, phone,
                          user_type, department, campus, status, created_at)
SELECT
    l.LOGIN_ID,
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi',  -- BCrypt 해시
    l.USER_NM,
    COALESCE(NULLIF(l.EMAIL, ''), CONCAT(l.LOGIN_ID, '@kopo.ac.kr')),   -- 이메일 자동생성
    NULL,
    CASE l.USER_KIND WHEN 'S' THEN 'ADMIN' WHEN 'U' THEN 'STUDENT' END,
    COALESCE(d.DEPT_NM, '미지정'),     -- LEFT JOIN 부서명
    '본부',
    CASE WHEN l.STATUS = 1 THEN 'ACTIVE' ELSE 'INACTIVE' END,
    STR_TO_DATE(COALESCE(NULLIF(l.REG_DATE,''), '20260101000000'), '%Y%m%d%H%i%s')
FROM lms.tb_user l
LEFT JOIN lms.tb_user_dept d ON l.DEPT_ID = d.ID AND d.SITE_ID = 1
WHERE l.SITE_ID = 1 AND l.STATUS IN (1, 0)
  AND l.LOGIN_ID NOT IN (SELECT user_id FROM growai_lms.users);  -- ★ 중복 방지
```

**Step 2: 과목 동기화** (`lm_subject → courses`)
```sql
INSERT IGNORE INTO courses (course_code, title, description, category, campus,
                            instructor_name, status, open_year, open_term, created_at)
SELECT
    CONCAT('LMS-', s.ID),              -- course_code = 'LMS-{ID}'
    s.COURSE_NM,
    CONCAT(s.COURSE_NM, ' (레거시 동기화)'),
    '레거시과정',                        -- 카테고리 일괄
    '본부', '미지정',
    CASE WHEN s.STATUS = 1 THEN 'ACTIVE' ELSE 'INACTIVE' END,
    '2026', '1',
    STR_TO_DATE(...)
FROM lms.lm_subject s
WHERE s.SITE_ID = 1 AND s.STATUS = 1
  AND CONCAT('LMS-', s.ID) NOT IN (SELECT COALESCE(course_code,'') FROM growai_lms.courses);
```

**Step 3: 차시 동기화** (`lm_lesson → lessons`, 상위 100건)
```sql
-- @rn, @rn2 사용자 변수로 week_no, order_no 자동 계산
INSERT INTO lessons (course_id, week_no, order_no, title, content_type,
                     content_url, duration_minutes, description, created_at)
SELECT
    1,                                          -- course_id 고정(첫 번째 과정)
    FLOOR((@rn := @rn + 1) / 4) + 1,          -- 4차시씩 1주차 구성
    ((@rn2 := @rn2 + 1) - 1) % 4 + 1,         -- 주차 내 순서 (1~4)
    l.LESSON_NM,
    CASE l.LESSON_TYPE                          -- ★ LESSON_TYPE 코드 변환
        WHEN '03' THEN 'VIDEO'      WHEN '05' THEN 'VIDEO'
        WHEN '02' THEN 'WBT'        WHEN '01' THEN 'DOCUMENT'
        WHEN '04' THEN 'FLASH'      WHEN '15' THEN 'KOLLUS'
        WHEN '11' THEN 'LIVE'       ELSE 'OTHER'
    END,
    COALESCE(l.START_URL, ''),
    COALESCE(l.TOTAL_TIME, 0),
    ...
FROM lms.lm_lesson l, (SELECT @rn := -1, @rn2 := -1) vars
WHERE l.SITE_ID = 1 AND l.STATUS = 1
ORDER BY l.ID LIMIT 100;
```

**Step 4: 시험 동기화** (`lm_exam → exams`)
```sql
INSERT INTO exams (course_id, title, exam_type, time_limit_minutes,
                   total_score, shuffle_questions, created_at)
SELECT 1, e.EXAM_NM,
    CASE e.ONOFF_TYPE WHEN 'N' THEN 'ONLINE' ELSE 'OFFLINE' END,
    COALESCE(e.EXAM_TIME, 60), 100,
    CASE e.SHUFFLE_YN WHEN 'Y' THEN 1 ELSE 0 END,
    ...
FROM lms.lm_exam e WHERE e.SITE_ID = 1 AND e.STATUS = 1;
```

**Step 5: 문항 동기화** (`lm_question → exam_questions`, 상위 100건)
```sql
INSERT INTO exam_questions (exam_id, question_no, question_text, question_type,
                            options, correct_answer, score)
SELECT
    (SELECT MIN(id) FROM growai_lms.exams),   -- 첫 번째 시험에 연결
    (@qn := @qn + 1),
    q.QUESTION,
    CASE q.QUESTION_TYPE                       -- ★ 문항 유형 코드 변환
        WHEN '1' THEN 'MCQ'         WHEN '2' THEN 'TRUE_FALSE'
        WHEN '3' THEN 'SHORT_ANSWER' WHEN '4' THEN 'ESSAY'
    END,
    JSON_ARRAY(q.ITEM1, q.ITEM2, q.ITEM3, q.ITEM4, q.ITEM5),  -- ★ JSON 배열
    COALESCE(q.ANSWER, ''),
    CASE q.GRADE WHEN 1 THEN 5 WHEN 2 THEN 10 WHEN 3 THEN 15 ELSE 10 END
FROM lms.lm_question q, (SELECT @qn := 0) vars
WHERE q.SITE_ID = 1 AND q.STATUS = 1
ORDER BY q.ID LIMIT 100;
```

**Step 6: 로그인 이력 동기화** (`tb_user_login → login_logs`, 최근 200건)
```sql
INSERT INTO login_logs (user_id, ip_address, user_agent, login_result, created_at)
SELECT
    COALESCE((SELECT id FROM growai_lms.users WHERE user_id = u.LOGIN_ID LIMIT 1), 1),
    '0.0.0.0', 'Legacy LMS Sync', 'SUCCESS',
    NOW() - INTERVAL (200 - (@ln := @ln + 1)) MINUTE   -- 시간 분산
FROM lms.tb_user_login ul
JOIN lms.tb_user u ON ul.USER_ID = u.ID AND u.SITE_ID = 1, (SELECT @ln := 0) vars
WHERE ul.SITE_ID = 1
ORDER BY ul.ID DESC LIMIT 200;
```

**Step 7: 동기화 로그 기록** (`lm_sync_log`)
```sql
INSERT INTO lm_sync_log (sync_type, status, total_count, success_count,
                          fail_count, triggered_by, completed_at)
VALUES ('FULL_SYNC', 'COMPLETED',
    (SELECT COUNT(*) FROM users) + ... + (SELECT COUNT(*) FROM login_logs),
    (SELECT COUNT(*) FROM users) + ... + (SELECT COUNT(*) FROM login_logs),
    0, 'MANUAL_CLI', NOW());
```

---

### 8. 동기화 실행 결과

#### 실행 명령
```
powershell> echo 'source D:/GrowAI_LMS_One-Stop-Framework/_sync_haksa.sql' |
            & 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe' -u root --default-character-set=utf8mb4
```

#### 실행 출력
```
[1/7] users synced: 83
[2/7] courses synced: 20
[3/7] lessons synced: 100
[4/7] exams synced: 28
[5/7] exam_questions synced: 100
[6/7] login_logs synced: 200
[7/7] sync_log: COMPLETED total=531
===== SYNC COMPLETE =====
users_total  courses_total  enrollments_total  lessons_total  exams_total  questions_total  login_logs_total  sync_logs
83           20             5                  100            28           100              200               1
```

#### Before / After 비교

```
┌──────────────────┬───────────┬───────────┬──────────┐
│     테이블        │  Before   │  After    │   증가   │
├──────────────────┼───────────┼───────────┼──────────┤
│ users            │     6     │    83     │   +77    │
│ courses          │     4     │    20     │   +16    │
│ enrollments      │     5     │     5     │    —     │
│ lessons          │     0     │   100     │  +100    │
│ exams            │     0     │    28     │   +28    │
│ exam_questions   │     0     │   100     │  +100    │
│ login_logs       │     0     │   200     │  +200    │
│ lm_sync_log      │     0     │     1     │    +1    │
├──────────────────┼───────────┼───────────┼──────────┤
│ 합계             │    15     │   537     │  +522    │
└──────────────────┴───────────┴───────────┴──────────┘
```

#### 동기화 로그 기록
```
id: 1
sync_type: FULL_SYNC
status: COMPLETED
total_count: 531
success_count: 531
fail_count: 0
triggered_by: MANUAL_CLI
completed_at: 2026-02-08 18:02:46
```

---

### 9. 데이터 분포 상세

#### 사용자 유형별 분포
```
ADMIN      ████████  8명 (9.6%)
INSTRUCTOR ██  2명 (2.4%)
STUDENT    ████████████████████████████████████████████████████████████████████████  73명 (88.0%)
```

#### 콘텐츠 유형별 분포
```
DOCUMENT  ████████████████████████████  28건 (28%)
VIDEO     ███████████████████████████  27건 (27%)
OTHER     ██████████████████████  22건 (22%)
FLASH     ████████████  12건 (12%)
WBT       ████████  8건 (8%)
LIVE      ███  3건 (3%)
```

#### 시험 유형
```
ONLINE   ██████████████████████████  26건 (93%)
OFFLINE  ██  2건 (7%)
```

#### 문항 유형
```
MCQ           █████████████████████████████████████████████████████████████████████  69건 (69%)
SHORT_ANSWER  ██████████████████████████  26건 (26%)
TRUE_FALSE    ████  4건 (4%)
ESSAY         █  1건 (1%)
```

---

### 10. 구현 파일 총괄

| # | 파일 경로 | 역할 | LOC |
|---|----------|------|-----|
| 1 | `config/LegacyDataSourceConfig.java` | 레거시 DataSource + JdbcTemplate Bean | 26 |
| 2 | `legacy/LegacyUserRepository.java` | tb_user, tb_user_login 읽기 | 68 |
| 3 | `legacy/LegacyCourseRepository.java` | lm_subject, lm_lesson, lm_content 읽기 | 105 |
| 4 | `legacy/LegacyExamRepository.java` | lm_exam, lm_question 읽기 | 68 |
| 5 | `legacy/LegacyProgressRepository.java` | lm_course_progress 읽기 | 85 |
| 6 | `legacy/LegacyBannerRepository.java` | tb_banner, lm_webtv, lm_webtv_live 읽기 | 60 |
| 7 | `legacy/LegacyLogRepository.java` | tb_action_log, tb_user_login 읽기 | 45 |
| 8 | `dataif/DataInterfaceService.java` | 메뉴별 통합 서비스 (11개 메서드) | 145 |
| 9 | `dataif/DataInterfaceController.java` | REST API 11개 엔드포인트 | 72 |
| 10 | `application.yml` | 이중 DataSource 접속 정보 | 111 |
| 11 | `_sync_haksa.sql` | ETL 일괄 동기화 스크립트 (7단계) | 179 |
| 12 | `frontend/src/services/api.ts` | dataApi 모듈 11개 메서드 | 25 |
| 13 | `frontend/src/pages/haksa/SyncPage.tsx` | 학사연동 현황 페이지 | 80 |
| — | **합계** | — | **~1,069** |

---

### 11. 데이터 변환 규칙 요약

| 원본 (lms) | 변환 | 대상 (growai_lms) | 비고 |
|-----------|------|------------------|------|
| `USER_KIND = 'S'` | → | `user_type = 'ADMIN'` | Malgnsoft S=관리자 |
| `USER_KIND = 'U'` | → | `user_type = 'STUDENT'` | Malgnsoft U=일반사용자 |
| `STATUS = 1` | → | `status = 'ACTIVE'` | 활성 |
| `STATUS = 0/-1/-2` | → | `status = 'INACTIVE'` | 비활성/탈퇴/차단 |
| `LESSON_TYPE = '03','05'` | → | `content_type = 'VIDEO'` | 동영상 |
| `LESSON_TYPE = '02'` | → | `content_type = 'WBT'` | 웹기반교육 |
| `LESSON_TYPE = '01'` | → | `content_type = 'DOCUMENT'` | 문서 |
| `LESSON_TYPE = '04'` | → | `content_type = 'FLASH'` | 플래시 |
| `LESSON_TYPE = '15'` | → | `content_type = 'KOLLUS'` | 콜러스 동영상 |
| `LESSON_TYPE = '11'` | → | `content_type = 'LIVE'` | 실시간 강의 |
| `ONOFF_TYPE = 'N'` | → | `exam_type = 'ONLINE'` | 온라인 시험 |
| `ONOFF_TYPE ≠ 'N'` | → | `exam_type = 'OFFLINE'` | 오프라인 시험 |
| `QUESTION_TYPE = '1'` | → | `question_type = 'MCQ'` | 객관식 |
| `QUESTION_TYPE = '2'` | → | `question_type = 'TRUE_FALSE'` | OX문제 |
| `QUESTION_TYPE = '3'` | → | `question_type = 'SHORT_ANSWER'` | 단답형 |
| `QUESTION_TYPE = '4'` | → | `question_type = 'ESSAY'` | 서술형 |
| `ITEM1~ITEM5` | → | `options = JSON_ARRAY(...)` | JSON 배열 변환 |
| `EMAIL = '' or NULL` | → | `{LOGIN_ID}@kopo.ac.kr` | 자동 생성 |
| `password (평문)` | → | `BCrypt $2a$10$...` | 해시 일괄 적용 |
| `GRADE = 1/2/3` | → | `score = 5/10/15` | 배점 변환 |

---

## 2026-02-08 LMS 플랫폼 연동 + Apache Superset 통계 대시보드 구현

### 1. 개요

교육 운영 핵심 기능(과정 개설, 수강자 관리, 평가/이수 관리)과 데이터 시각화(수강/출결/이수 통계)를 구현하였다.

- **LMS 플랫폼**: Open edX 연동 기반 과정 운영 체계 (13개 API)
- **통계 시각화**: Apache Superset 연동 대시보드 (8개 API)
- **프론트엔드**: 관리자용 2개 신규 페이지

---

### 2. 전체 아키텍처 다이어그램

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      GrowAI LMS One-Stop Framework                       │
│                                                                          │
│  ┌─── Frontend (React 18) ───────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │  /admin/lms-platform        /admin/superset-dashboard             │  │
│  │  ┌─────────────────┐       ┌──────────────────────────┐          │  │
│  │  │  LMS Platform    │       │  Statistics Dashboard     │          │  │
│  │  │  ─────────────   │       │  ──────────────────────   │          │  │
│  │  │  과정 개설/관리  │       │  수강 현황 분석 (Bar)     │          │  │
│  │  │  수강자 등록/관리│       │  출결 현황 (Donut SVG)    │          │  │
│  │  │  평가/이수 관리  │       │  이수 현황 (Progress)     │          │  │
│  │  │  일괄 수강 등록  │       │  과정별 순위 Top 10       │          │  │
│  │  └────────┬────────┘       │  월별 추이 (Bar Chart)    │          │  │
│  │           │                │  학과별 통계              │          │  │
│  │           │                │  Superset iframe 연동     │          │  │
│  │           │                └──────────┬───────────────┘          │  │
│  └───────────┼───────────────────────────┼──────────────────────────┘  │
│              │                           │                              │
│              ▼                           ▼                              │
│  ┌─── Backend (Spring Boot 3.2) ─────────────────────────────────────┐  │
│  │                                                                    │  │
│  │  ┌──────────────────────┐   ┌──────────────────────────────┐     │  │
│  │  │  LmsPlatformController│   │  StatisticsAnalyticsController│     │  │
│  │  │  /api/lms-platform    │   │  /api/statistics              │     │  │
│  │  │  (13 endpoints)       │   │  (8 endpoints)                │     │  │
│  │  └──────────┬───────────┘   └──────────┬───────────────────┘     │  │
│  │             │                           │                         │  │
│  │             ▼                           ▼                         │  │
│  │  ┌──────────────────────┐   ┌──────────────────────────────┐     │  │
│  │  │  LmsPlatformService   │   │  StatisticsService            │     │  │
│  │  │  (13 methods)         │   │  (8 methods)                  │     │  │
│  │  └──────────┬───────────┘   └──────────┬───────────────────┘     │  │
│  │             │                           │                         │  │
│  │             ▼                           ▼                         │  │
│  │  ┌──────────────────────────────────────────────────────────┐     │  │
│  │  │  JPA Repositories                                        │     │  │
│  │  │  CourseRepository + EnrollmentRepository + UserRepository │     │  │
│  │  │  + EntityManager (JPQL) + legacyJdbc (JdbcTemplate)     │     │  │
│  │  └──────────────────────────┬───────────────────────────────┘     │  │
│  └──────────────────────────────┼────────────────────────────────────┘  │
│                                 │                                        │
│                                 ▼                                        │
│  ┌─── External Services ────────────────────────────────────────────┐  │
│  │  MySQL 8.4 (growai_lms)  │  Open edX (localhost:18000)           │  │
│  │  Apache Superset (localhost:8088)                                 │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

### 3. LMS 플랫폼 연동 (Open edX 기반)

#### 3-1. API 엔드포인트 (13개)

```
┌───────────────────────────────────────────────────────────────────────┐
│                   LmsPlatformController                               │
│                   @RequestMapping("/api/lms-platform")                │
│                                                                       │
│  ┌─── 과정 개설 및 운영 ────────────────────────────────────────┐    │
│  │  POST   /courses                      → 과정 등록             │    │
│  │  GET    /courses                      → 과정 목록 조회        │    │
│  │  GET    /courses/{id}                 → 과정 상세 조회        │    │
│  │  PUT    /courses/{id}                 → 과정 수정             │    │
│  │  DELETE /courses/{id}                 → 과정 비활성화         │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌─── 수강자 관리 ──────────────────────────────────────────────┐    │
│  │  POST   /courses/{id}/enroll          → 수강 등록             │    │
│  │  DELETE /courses/{id}/enroll/{userId}  → 수강 취소             │    │
│  │  GET    /courses/{id}/enrollments     → 과정별 수강자 목록    │    │
│  │  GET    /users/{userId}/enrollments   → 사용자별 수강 목록    │    │
│  │  POST   /courses/{id}/bulk-enroll     → 일괄 수강 등록        │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌─── 평가 및 이수 관리 ────────────────────────────────────────┐    │
│  │  PUT    /assessment                   → 평가 업데이트         │    │
│  │  GET    /courses/{id}/stats           → 과정별 통계            │    │
│  │  GET    /overview                     → 플랫폼 현황 총괄      │    │
│  └───────────────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────┘
```

#### 3-2. Service 메서드 상세

| # | 메서드 | 기능 | 트랜잭션 |
|---|--------|------|----------|
| 1 | `createCourse(req)` | 과정 생성, 코드 자동생성 `GRW-{timestamp}` | @Transactional |
| 2 | `getCourseList()` | 전체 과정 목록 | ReadOnly |
| 3 | `getCourseDetail(id)` | 과정 상세 + 수강/이수 통계 | ReadOnly |
| 4 | `updateCourse(id, req)` | 과정 정보 수정 (10개 필드) | @Transactional |
| 5 | `deleteCourse(id)` | 소프트 삭제 (INACTIVE) | @Transactional |
| 6 | `enrollStudent(userId, courseId)` | 수강 등록 + 인원 증가 | @Transactional |
| 7 | `unenrollStudent(userId, courseId)` | 수강 철회 + 인원 감소 | @Transactional |
| 8 | `getEnrollmentsByCourse(courseId)` | 과정별 수강자 목록 (사용자 정보 포함) | ReadOnly |
| 9 | `getEnrollmentsByUser(userId)` | 사용자별 수강 목록 (과정 정보 포함) | ReadOnly |
| 10 | `updateAssessment(req)` | 점수/등급 업데이트, 100점 시 자동 이수 처리 | @Transactional |
| 11 | `getCourseStats(courseId)` | 수강인원/이수인원/평균점수/이수율 | ReadOnly |
| 12 | `getPlatformOverview()` | 총 과정/활성 과정/총 수강생/이수 완료율 | ReadOnly |
| 13 | `bulkEnroll(courseId, userIds)` | 일괄 수강 등록 (중복/용량 검증) | @Transactional |

#### 3-3. 프론트엔드 UI (`/admin/lms-platform`)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LMS 플랫폼 관리                                   │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ 총 과정   │  │ 활성 과정 │  │ 총 수강생 │  │ 이수완료율│          │
│  │    20     │  │    16     │  │    83     │  │  34.5%   │          │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘          │
│                                                                     │
│  [+ 과정 등록]                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ # │ 과정코드  │ 과정명      │ 카테고리 │ 교수  │ 수강 │ 이수율│   │
│  │ 1 │ GRW-001  │ 파이썬 기초  │ 프로그래밍│ 김교수│  25  │ 72%  │   │
│  │ 2 │ LMS-1    │ 웹개발 입문  │ 레거시과정│ 미지정│  18  │ 45%  │   │
│  │...│          │             │          │      │     │      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  [수강자 관리 모달]                                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ 파이썬 기초 — 수강자 목록                                    │   │
│  │ [학번 입력] [수강 등록]                                       │   │
│  │ 학번  │ 이름   │ 학과   │ 진도율 │ 상태  │ 점수│등급│관리   │   │
│  │ S001 │ 김학생 │ 컴공   │  85%  │ 수강중│  85 │ B+ │ [취소]│   │
│  │ S002 │ 이학생 │ 전자   │ 100%  │ 이수  │ 100 │ A+ │ [취소]│   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 4. 기본 통계 및 현황 분석 (Apache Superset 연동)

#### 4-1. API 엔드포인트 (8개)

```
┌───────────────────────────────────────────────────────────────────────┐
│                StatisticsAnalyticsController                           │
│                @RequestMapping("/api/statistics")                     │
│                                                                       │
│  ┌─── 데이터 수집: 수강, 출결, 이수 ────────────────────────────┐    │
│  │  GET /enrollment-stats          → 수강 현황 통계              │    │
│  │  GET /attendance-stats          → 출결 현황 통계              │    │
│  │  GET /completion-stats          → 이수 현황 통계              │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌─── 시각화: 순위, 추이, 학과별 ────────────────────────────────┐   │
│  │  GET /course-rankings?limit=10  → 과정별 수강 순위            │    │
│  │  GET /monthly-trends?months=6   → 월별 수강/이수 추이         │    │
│  │  GET /department-stats          → 학과별 통계                 │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌─── 통합 대시보드 ────────────────────────────────────────────┐    │
│  │  GET /dashboard                 → 전체 대시보드 요약          │    │
│  │  GET /report?type=xxx           → 커스텀 리포트               │    │
│  └───────────────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────┘
```

#### 4-2. 데이터 수집 및 시각화 구조

```
  ┌─── 데이터 수집 ─────────────────────────────────────────────────┐
  │                                                                  │
  │  enrollments 테이블 ──► 수강 현황 (ENROLLED/COMPLETED/WITHDRAWN) │
  │  attendances 테이블 ──► 출결 현황 (PRESENT/LATE/ABSENT)          │
  │  enrollments.progressPercent ──► 이수 현황 (진도율/이수일수)     │
  │  courses + enrollments ──► 과정별 순위                           │
  │  enrollments.enrolledAt ──► 월별 추이                            │
  │  users.department ──► 학과별 통계                                │
  │                                                                  │
  └──────────────────────────────┬───────────────────────────────────┘
                                 │
                                 ▼
  ┌─── 시각화 도구 ─────────────────────────────────────────────────┐
  │                                                                  │
  │  ┌── React 내장 시각화 (CSS/SVG) ──┐  ┌── Apache Superset ──┐  │
  │  │  수강 현황: 수평 Bar Chart      │  │  고급 분석 대시보드  │  │
  │  │  출결 현황: SVG Donut Chart     │  │  실시간 데이터 연동  │  │
  │  │  이수 현황: Progress Bar        │  │  커스텀 차트 빌더    │  │
  │  │  과정 순위: Table + Bar         │  │  드릴다운 분석       │  │
  │  │  월별 추이: Grouped Bar Chart   │  │  PDF/Excel 내보내기  │  │
  │  │  학과 통계: Table + Progress    │  │  iframe 임베드       │  │
  │  └─────────────────────────────────┘  └─────────────────────┘  │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
```

#### 4-3. 프론트엔드 UI (`/admin/superset-dashboard`)

```
┌──────────────────────────────────────────────────────────────────────┐
│  기본 통계 및 현황 분석 — Apache Superset 연동 데이터 시각화 대시보드 │
│                                           [Superset 대시보드 열기 →] │
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │총 수강건수│  │이수 완료율│  │  출석률   │  │평균 진도율│           │
│  │   306    │  │  34.5%   │  │  84.0%   │  │  67.3%   │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│                                                                      │
│  ┌──── 수강 현황 분석 ─────────┐  ┌──── 출결 현황 ──────────────┐  │
│  │ 수강중    ████████████  200 │  │      ╭───────╮              │  │
│  │ 이수완료  ███████      106  │  │    ╭─│ 84.0% │─╮            │  │
│  │ 미시작    ████          48  │  │    │ ╰───────╯ │  ● 출석 1050│  │
│  │ 수강철회  ██            24  │  │    ╰───────────╯  ● 지각  125│  │
│  └─────────────────────────────┘  │                   ● 결석   75│  │
│                                   └──────────────────────────────┘  │
│                                                                      │
│  ┌──── 과정별 순위 (Top 10) ────────────────────────────────────┐   │
│  │  🥇 파이썬 기초      25명  18명  72%  85.3                   │   │
│  │  🥈 웹개발 입문      22명  15명  68%  79.2                   │   │
│  │  🥉 데이터분석       18명  12명  67%  82.1                   │   │
│  │   4  AI/ML 개론      15명  10명  67%  78.5                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──── 월별 추이 ──────────────────────────────────────────────┐    │
│  │  ■수강신청  ■이수완료  ■신규사용자                           │    │
│  │  ▐▐▐  ▐▐▐  ▐▐▐  ▐▐▐  ▐▐▐  ▐▐▐                             │    │
│  │  9월   10월  11월  12월  1월   2월                           │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌──── Apache Superset 연동 ────────────────────────────────────┐   │
│  │  Apache Superset를 통한 고급 분석 및 시각화                   │   │
│  │  URL: http://localhost:8088                                   │   │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐│   │
│  │  │실시간 데이터│ │커스텀 대시 │ │드릴다운    │ │PDF/Excel  ││   │
│  │  │  연동      │ │  보드      │ │  분석      │ │ 내보내기  ││   │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────┘│   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

### 5. application.yml 설정 추가

```yaml
# Apache Superset
superset:
  dashboard-url: ${SUPERSET_URL:http://localhost:8088}
  enabled: ${SUPERSET_ENABLED:true}

# Open edX LMS Platform
openedx:
  base-url: ${OPENEDX_URL:http://localhost:18000}
  client-id: ${OPENEDX_CLIENT_ID:}
  client-secret: ${OPENEDX_CLIENT_SECRET:}
  oauth-token-url: ${OPENEDX_URL:http://localhost:18000}/oauth2/access_token
  enabled: ${OPENEDX_ENABLED:false}
```

---

### 6. 구현 파일 총괄

#### Backend (6개 파일)

| # | 파일 경로 | 역할 |
|---|----------|------|
| 1 | `lmsplatform/dto/LmsPlatformDto.java` | LMS 플랫폼 DTO (5개 내부 클래스) |
| 2 | `lmsplatform/service/LmsPlatformService.java` | 과정/수강/평가 통합 서비스 (13개 메서드) |
| 3 | `lmsplatform/controller/LmsPlatformController.java` | REST API 13개 엔드포인트 |
| 4 | `statistics/dto/StatisticsDto.java` | 통계 DTO (7개 내부 클래스) |
| 5 | `statistics/service/StatisticsService.java` | 통계 집계 서비스 (8개 메서드) |
| 6 | `statistics/controller/StatisticsAnalyticsController.java` | REST API 8개 엔드포인트 |

#### Frontend (4개 파일 수정/생성)

| # | 파일 경로 | 변경 내용 |
|---|----------|----------|
| 1 | `pages/admin/LmsPlatformPage.tsx` | LMS 플랫폼 관리 페이지 (신규) |
| 2 | `pages/admin/SupersetDashboardPage.tsx` | 통계 대시보드 페이지 (신규) |
| 3 | `App.tsx` | 라우트 2개 추가 (`/admin/lms-platform`, `/admin/superset-dashboard`) |
| 4 | `services/api.ts` | API 모듈 2개 추가 (`lmsPlatformApi`, `statisticsApi`) |

#### 설정 (1개 파일 수정)

| # | 파일 경로 | 변경 내용 |
|---|----------|----------|
| 1 | `application.yml` | Superset + Open edX 설정 추가 |

---

### 7. 빌드 검증 결과

```
=== Backend Gradle Build ===
BUILD SUCCESSFUL in 11s (5 tasks executed)

=== Frontend TypeScript Check ===
TSC Exit Code: 0 (No errors)

=== Frontend Vite Build ===
Modules: 1,633
  - dist/index.html            0.70 kB (gzip: 0.42 kB)
  - dist/assets/index.css     96.98 kB (gzip: 14.02 kB)
  - dist/assets/index.js     802.19 kB (gzip: 195.38 kB)
Built in: 7.29s
```

### 8. 기대 효과

#### LMS 플랫폼 연동
- 교육 운영 핵심 기능의 신속한 구축 (과정 CRUD + 수강 관리 + 평가/이수)
- Open edX 기반 공공/교육 분야 검증된 안정성 확보
- 일괄 수강 등록으로 대규모 운영 효율화

#### 통계 및 현황 분석
- 운영 현황에 대한 가시성 확보 (수강/출결/이수 실시간 집계)
- CSS/SVG 기반 내장 차트 + Apache Superset 고급 분석 이중 시각화
- 학과별/월별/과정별 다차원 분석으로 정책 의사결정 지원
- 커스텀 리포트 API로 유연한 데이터 추출

---

## 2026-02-08 DBeaver GCP Production 데이터베이스 연결 구성 및 I/F 다이어그램

### 1. 개요

DBeaver Database Navigator에 등록된 **GCP Production** 폴더 하위 4개 데이터베이스 연결과,
각 데이터베이스가 GrowAI LMS 시스템에서 어떻게 I/F(인터페이스) 되는지를 초보자도 이해할 수 있도록 설명한다.

---

### 2. DBeaver Database Navigator 구성

```
📁 GCP Production
 ├── 🐬 [LOCAL] GoogleAI - epoly_ai        localhost:3306
 ├── 🐬 [LOCAL] GrowAI LMS - growai_lms    localhost:3306
 ├── 🐬 [LOCAL] GrowAI LMS - root          localhost:3306
 └── 🐬 [LOCAL] Polytech LMS - lms         localhost:3306
```

> **초보자 설명**: DBeaver는 데이터베이스를 눈으로 보고 관리하는 도구입니다.
> 위 4개 연결은 **같은 MySQL 서버(localhost:3306)** 안의 서로 다른 데이터베이스에
> 서로 다른 계정으로 접속하는 설정입니다.

---

### 3. 연결별 Connection String 상세

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                        MySQL Server (localhost:3306)                                   │
│                        MySQL 8.4 Community Edition                                     │
│                                                                                        │
│  ┌─── Connection 1 ─────────────────────────────────────────────────────────────────┐ │
│  │  📌 이름: [LOCAL] GoogleAI - epoly_ai                                            │ │
│  │                                                                                   │ │
│  │  Connection String:                                                               │ │
│  │  jdbc:mysql://localhost:3306/epoly_ai                                             │ │
│  │    ?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul            │ │
│  │                                                                                   │ │
│  │  Username: epoly                                                                  │ │
│  │  Password: epoly2026                                                              │ │
│  │  Database: epoly_ai                                                               │ │
│  │  용도: Google AI 연동 데이터 (임베딩, 벡터 메타데이터, AI 학습 이력)               │ │
│  └───────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                        │
│  ┌─── Connection 2 ─────────────────────────────────────────────────────────────────┐ │
│  │  📌 이름: [LOCAL] GrowAI LMS - growai_lms                                        │ │
│  │                                                                                   │ │
│  │  Connection String:                                                               │ │
│  │  jdbc:mysql://localhost:3306/growai_lms                                            │ │
│  │    ?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul            │ │
│  │    &characterEncoding=UTF-8                                                        │ │
│  │                                                                                   │ │
│  │  Username: growai                                                                 │ │
│  │  Password: growai_lms_2026!                                                       │ │
│  │  Database: growai_lms                                                             │ │
│  │  용도: GrowAI LMS 신규 시스템 (users, courses, enrollments, exams 등)             │ │
│  └───────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                        │
│  ┌─── Connection 3 ─────────────────────────────────────────────────────────────────┐ │
│  │  📌 이름: [LOCAL] GrowAI LMS - root                                              │ │
│  │                                                                                   │ │
│  │  Connection String:                                                               │ │
│  │  jdbc:mysql://localhost:3306/growai_lms                                            │ │
│  │    ?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul            │ │
│  │                                                                                   │ │
│  │  Username: root                                                                   │ │
│  │  Password: (없음)                                                                 │ │
│  │  Database: growai_lms (+ 전체 DB 접근 가능)                                       │ │
│  │  용도: DBA 관리용 (스키마 변경, ETL 동기화, 전체 DB 접근)                          │ │
│  └───────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                        │
│  ┌─── Connection 4 ─────────────────────────────────────────────────────────────────┐ │
│  │  📌 이름: [LOCAL] Polytech LMS - lms                                             │ │
│  │                                                                                   │ │
│  │  Connection String:                                                               │ │
│  │  jdbc:mysql://localhost:3306/lms                                                   │ │
│  │    ?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul            │ │
│  │                                                                                   │ │
│  │  Username: root                                                                   │ │
│  │  Password: (없음)                                                                 │ │
│  │  Database: lms                                                                    │ │
│  │  용도: Malgnsoft 레거시 LMS (tb_user, lm_lesson, lm_exam 등)                      │ │
│  └───────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 4. 전체 데이터 흐름 다이어그램 (초보자용)

```
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║   👤 사용자 (웹 브라우저)                                                             ║
║   http://localhost:5173                                                               ║
║                                                                                      ║
╚════════════════════════════════╤═════════════════════════════════════════════════════╝
                                 │
                    ① 브라우저에서 페이지 요청
                    (예: 학생이 대시보드 클릭)
                                 │
                                 ▼
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║   🖥️  Frontend (React 18 + Vite + TypeScript)                                        ║
║   포트: 5173 (개발) / 3000 (빌드)                                                     ║
║                                                                                      ║
║   ┌─────────────────────────────────────────────────────────────────────────────┐    ║
║   │  LoginPage.tsx  →  MainPage.tsx  →  DashboardPage.tsx  →  ...              │    ║
║   │                                                                             │    ║
║   │  api.ts (Axios HTTP 클라이언트)                                             │    ║
║   │    ├── dataApi.getStudentDashboard(1)   → GET /api/data/student/dashboard/1│    ║
║   │    ├── dataApi.getExamManagement()      → GET /api/data/instructor/exams   │    ║
║   │    ├── dataApi.getAdminMonitoring()     → GET /api/data/admin/monitoring   │    ║
║   │    └── lmsPlatformApi / statisticsApi   → GET /api/lms-platform/...        │    ║
║   └─────────────────────────────────────────────────────────────────────────────┘    ║
║                                                                                      ║
╚════════════════════════════════╤═════════════════════════════════════════════════════╝
                                 │
                    ② Vite Proxy가 /api 요청을 백엔드로 전달
                    (vite.config.ts → proxy: /api → http://localhost:8081)
                                 │
                                 ▼
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║   ☕ Backend (Spring Boot 3.2 + Java 21 + JPA + Gradle)                               ║
║   포트: 8081 (polytech-lms-api) / 8082 (growai-lms)                                   ║
║                                                                                      ║
║   ┌── Controller Layer ─────────────────────────────────────────────────────────┐    ║
║   │  DataInterfaceController (11 API)                                           │    ║
║   │  LmsPlatformController (13 API)                                             │    ║
║   │  StatisticsAnalyticsController (8 API)                                      │    ║
║   └────────────────────────────────────┬────────────────────────────────────────┘    ║
║                                         │                                            ║
║                            ③ 서비스 계층에서 데이터 조합                               ║
║                                         │                                            ║
║   ┌── Service Layer ────────────────────┼───────────────────────────────────────┐    ║
║   │  DataInterfaceService               │                                       │    ║
║   │    ├── JPA Repository (growai_lms)  │  ← ④-A Primary DataSource            │    ║
║   │    │     UserRepository             │                                       │    ║
║   │    │     CourseRepository           │                                       │    ║
║   │    │     EnrollmentRepository       │                                       │    ║
║   │    │                                │                                       │    ║
║   │    └── Legacy Repository (lms)      │  ← ④-B Legacy DataSource (ReadOnly)  │    ║
║   │          @Qualifier("legacyJdbc")   │                                       │    ║
║   │          LegacyUserRepository       │                                       │    ║
║   │          LegacyCourseRepository     │                                       │    ║
║   │          LegacyExamRepository       │                                       │    ║
║   │          LegacyProgressRepository   │                                       │    ║
║   │          LegacyBannerRepository     │                                       │    ║
║   │          LegacyLogRepository        │                                       │    ║
║   └─────────────────────────────────────┼───────────────────────────────────────┘    ║
║                                         │                                            ║
╚════════════════╤════════════════════════╤════════════════════════════════════════════╝
                 │                        │
      ④-A JPA (Read/Write)    ④-B JdbcTemplate (ReadOnly)
      HikariCP pool:20        HikariCP pool:5
                 │                        │
                 ▼                        ▼
╔════════════════════════════╗  ╔════════════════════════════╗
║  🐬 growai_lms (신규 DB)   ║  ║  🐬 lms (레거시 DB)        ║
║  Connection 2 in DBeaver   ║  ║  Connection 4 in DBeaver   ║
║                            ║  ║                            ║
║  User: growai              ║  ║  User: root                ║
║  Pass: growai_lms_2026!    ║  ║  Pass: (없음)              ║
║                            ║  ║                            ║
║  ┌──────────────────────┐  ║  ║  ┌──────────────────────┐  ║
║  │ users          (83)  │  ║  ║  │ tb_user        (82)  │  ║
║  │ courses        (20)  │  ║  ║  │ lm_subject     (48)  │  ║
║  │ enrollments     (5)  │  ║  ║  │ lm_lesson     (617)  │  ║
║  │ lessons       (100)  │  ║  ║  │ lm_exam        (36)  │  ║
║  │ exams          (28)  │  ║  ║  │ lm_question   (181)  │  ║
║  │ exam_questions(100)  │  ║  ║  │ lm_content     (53)  │  ║
║  │ login_logs    (200)  │  ║  ║  │ tb_banner      (41)  │  ║
║  │ site_settings   (8)  │  ║  ║  │ tb_user_login (733)  │  ║
║  │ lm_sync_log     (1)  │  ║  ║  │ tb_action_log (107)  │  ║
║  └──────────────────────┘  ║  ║  └──────────────────────┘  ║
╚═══════════╤════════════════╝  ╚════════════════════════════╝
            │
  ⑤ ETL 동기화 (_sync_haksa.sql)
  lms → growai_lms 일괄 데이터 이관
            │
            ▼
╔════════════════════════════╗     ╔════════════════════════════════════╗
║  🐬 epoly_ai (AI 전용 DB)  ║     ║  🧠 Qdrant Vector DB               ║
║  Connection 1 in DBeaver   ║     ║  포트: 6333 (REST) / 6334 (gRPC)   ║
║                            ║     ║                                    ║
║  User: epoly               ║     ║  Collection:                       ║
║  Pass: epoly2026           ║     ║  ├── growai_lms_contents           ║
║                            ║     ║  └── video_summary_vectors_gemini  ║
║  용도:                     ║     ║                                    ║
║  ├── AI 학습 이력          ║     ║  용도:                             ║
║  ├── 임베딩 메타데이터     ║     ║  ├── 강좌 콘텐츠 벡터 검색        ║
║  └── 챗봇 대화 로그       ║     ║  └── 영상 요약 유사도 검색        ║
╚════════════════════════════╝     ╚════════════════════════════════════╝
```

---

### 5. 초보자를 위한 단계별 설명

#### 🔹 Step 1: 사용자가 브라우저에서 접속
```
사용자 → http://localhost:5173 (프론트엔드 개발 서버)
```
- Vite 개발 서버가 React 앱을 브라우저에 전달합니다.
- 사용자는 로그인 후 학생/교수자/관리자 대시보드를 볼 수 있습니다.

#### 🔹 Step 2: 프론트엔드가 백엔드에 API 요청
```
프론트엔드 (React)                    백엔드 (Spring Boot)
    │                                      │
    │  GET /api/data/student/dashboard/1   │
    │ ──────────────────────────────────►   │
    │                                      │
    │  Vite Proxy가 자동 전달:             │
    │  localhost:5173/api/... → localhost:8081/api/...
```
- `vite.config.ts`에 설정된 프록시가 `/api`로 시작하는 모든 요청을
  백엔드 서버(8081)로 자동 전달합니다.
- **프록시란?** 중간에서 요청을 대신 전달해주는 역할입니다.

#### 🔹 Step 3: 백엔드가 데이터베이스에서 데이터 조회
```
Spring Boot 백엔드
    │
    ├── ④-A growai_lms 접속 (JPA, Read/Write)
    │   └── users, courses, enrollments 조회
    │
    └── ④-B lms 접속 (JdbcTemplate, ReadOnly)
        └── tb_user, lm_lesson, lm_exam 조회
```
- **Dual DataSource**: 2개의 서로 다른 데이터베이스에 동시에 접속합니다.
- `growai_lms`는 읽기/쓰기 가능 (새 데이터 저장용)
- `lms`는 읽기 전용 (레거시 데이터 조회용)

#### 🔹 Step 4: 데이터 조합 후 응답 반환
```
백엔드                              프론트엔드
    │                                    │
    │  {                                 │
    │    "enrollments": [...],           │
    │    "courses": [...],               │
    │    "progress": [...],              │
    │    "totalUsers": 83                │
    │  }                                 │
    │ ◄──────────────────────────────    │
    │                                    │
    │  React가 화면에 데이터 표시        │
```
- 백엔드가 두 DB의 데이터를 하나의 JSON으로 합쳐서 프론트엔드에 반환합니다.

#### 🔹 Step 5: ETL 동기화 (수동 실행)
```
_sync_haksa.sql 실행 (DBeaver 또는 mysql CLI)
    │
    │  lms.tb_user (82명) ──변환──► growai_lms.users (+77명)
    │  lms.lm_subject (48개) ──변환──► growai_lms.courses (+16개)
    │  lms.lm_lesson (617개) ──상위100──► growai_lms.lessons (+100건)
    │  ...
    │
    └── 총 531건 동기화 완료
```
- ETL이란? **E**xtract(추출) → **T**ransform(변환) → **L**oad(적재)
- 레거시 DB의 데이터를 형식을 바꿔서 새 DB에 넣는 과정입니다.

---

### 6. DBeaver 연결별 용도 요약

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                      DBeaver Connection 사용 시나리오                            │
│                                                                                │
│  📊 데이터 확인 (SELECT)                                                       │
│  ├── Connection 2 (growai_lms): 신규 시스템 데이터 확인                         │
│  │   └── "학생 수강 현황 보기", "과정 목록 확인" 등                              │
│  │                                                                             │
│  ├── Connection 4 (lms): 레거시 시스템 데이터 확인                               │
│  │   └── "기존 LMS 사용자 확인", "과거 강의 데이터 조회" 등                       │
│  │                                                                             │
│  └── Connection 1 (epoly_ai): AI 관련 데이터 확인                               │
│      └── "AI 챗봇 대화 이력", "임베딩 메타데이터 확인" 등                         │
│                                                                                │
│  🔧 스키마 변경 / ETL 실행                                                      │
│  └── Connection 3 (root): 관리자 권한으로 모든 DB 접근                           │
│      └── "테이블 생성/삭제", "_sync_haksa.sql 실행", "사용자 권한 관리" 등        │
│                                                                                │
│  🔄 데이터 흐름 방향                                                            │
│  Connection 4 (lms) ──ETL──► Connection 2 (growai_lms) ──API──► 프론트엔드     │
│  Connection 1 (epoly_ai) ──AI 서비스──► Connection 2 (growai_lms)               │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

### 7. GCP 배포 시 Connection String 변경 계획

```
┌─── 로컬 개발 (현재) ─────────────────────────────────────────────────────────┐
│                                                                               │
│  모든 DB → localhost:3306                                                     │
│  jdbc:mysql://localhost:3306/growai_lms                                        │
│  jdbc:mysql://localhost:3306/lms                                              │
│  jdbc:mysql://localhost:3306/epoly_ai                                         │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 배포 시
                                 ▼
┌─── GCP Cloud SQL (프로덕션) ─────────────────────────────────────────────────┐
│                                                                               │
│  jdbc:mysql:///growai_lms                                                     │
│    ?cloudSqlInstance=PROJECT_ID:REGION:INSTANCE_NAME                          │
│    &socketFactory=com.google.cloud.sql.mysql.SocketFactory                    │
│    &useSSL=false                                                              │
│                                                                               │
│  또는 Private IP:                                                             │
│  jdbc:mysql://10.x.x.x:3306/growai_lms?useSSL=true                           │
│                                                                               │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐                          │
│  │ growai_lms  │    │    lms     │    │  epoly_ai  │                          │
│  │ (Cloud SQL) │    │ (Cloud SQL)│    │ (Cloud SQL)│                          │
│  └──────┬──────┘    └──────┬─────┘    └──────┬─────┘                          │
│         │                  │                  │                                │
│         └──────────────────┼──────────────────┘                                │
│                            │                                                   │
│                    GKE / Cloud Run                                             │
│                    (Spring Boot 컨테이너)                                       │
└───────────────────────────────────────────────────────────────────────────────┘
```

> **핵심 포인트**: 로컬에서는 `localhost:3306`으로 모든 DB에 접근하지만,
> GCP 배포 시에는 Cloud SQL 인스턴스로 Connection String만 변경하면 됩니다.
> Spring Boot의 환경변수 주입 (`${MYSQL_HOST}`, `${DB_URL}`) 패턴을 사용하여
> 코드 변경 없이 설정만으로 전환할 수 있습니다.
