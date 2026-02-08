# 🚀 GrowAILMS 완전 자동화 마이그레이션 가이드

---

| 구분 | 내용 |
|------|------|
| **문서번호** | NEWKL-2026-GROW-007 |
| **보안등급** | 🔒 **Confidential (대외비)** |
| **작성일** | 2026-01-28 |
| **버전** | v1.0.0 |
| **대상** | 초보 개발자 ~ 중급 개발자 |

---

## 📋 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [Claude Code 소개 및 설치](#2-claude-code-소개-및-설치)
3. [자동화 아키텍처](#3-자동화-아키텍처)
4. [단계별 실행 가이드](#4-단계별-실행-가이드)
5. [전체 프로젝트 구조](#5-전체-프로젝트-구조)
6. [확장 전략 (Legacy-LMS Transpiler)](#6-확장-전략)
7. [트러블슈팅](#7-트러블슈팅)

---

## 1. 프로젝트 개요

### 1.1 마이그레이션 대상

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        마이그레이션 변환 흐름                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   [SOURCE: MalgnLMS]              →          [TARGET: GrowAILMS]        │
│                                                                         │
│   ┌─────────────────────┐              ┌─────────────────────┐         │
│   │ Java DataObject     │    Claude    │ Java 17 Service     │         │
│   │ DAO Pattern         │ ──────────→  │ + MyBatis Mapper    │         │
│   │ (170개 클래스)       │    Code     │ + @Transactional    │         │
│   └─────────────────────┘              └─────────────────────┘         │
│                                                                         │
│   ┌─────────────────────┐              ┌─────────────────────┐         │
│   │ JSP + JavaScript    │    Claude    │ React 18 + Vite     │         │
│   │ (1,223개 파일)       │ ──────────→  │ + TypeScript        │         │
│   │                     │    Code     │ + Tailwind CSS      │         │
│   └─────────────────────┘              └─────────────────────┘         │
│                                                                         │
│   ┌─────────────────────┐              ┌─────────────────────┐         │
│   │ Legacy DB Schema    │    Claude    │ Optimized Schema    │         │
│   │ (169개 테이블)       │ ──────────→  │ + MyBatis XML       │         │
│   │                     │    Code     │ + Redis Cache       │         │
│   └─────────────────────┘              └─────────────────────┘         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 기술 스택 매핑

| 계층 | Source (MalgnLMS) | Target (GrowAILMS) |
|------|-------------------|-------------------|
| **Backend** | Java 8 + DataObject | **Java 17 + Spring Boot 3.2** |
| **ORM** | Custom DAO | **MyBatis 3.5** |
| **인증** | Session 기반 | **JWT + Keycloak** |
| **캐시** | - | **Redis** |
| **Frontend** | JSP + jQuery | **React 18 + TypeScript** |
| **빌드** | Ant | **Vite + Gradle** |
| **스타일** | CSS | **Tailwind CSS** |
| **컨테이너** | - | **Docker Compose** |
| **웹서버** | Apache | **Nginx** |

### 1.3 자동화 목표

```
┌──────────────────────────────────────────────────────────────┐
│  🎯 100% 기능 일치 자동화 목표                                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  📊 자동화율 목표                                              │
│  ├── Backend (DAO → Service): 95% 자동화                     │
│  ├── Frontend (JSP → React): 85% 자동화                      │
│  ├── SQL (Schema Migration): 100% 자동화                     │
│  └── 인프라 (Docker/Nginx): 100% 자동화                       │
│                                                              │
│  ⏱️ 예상 소요 시간                                             │
│  ├── 수동 마이그레이션: 약 6개월 (개발자 3인)                   │
│  └── Claude Code 자동화: 약 2주 (개발자 1인)                   │
│                                                              │
│  💰 비용 절감                                                  │
│  └── 약 92% 절감 (인건비 + 시간 기준)                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Claude Code 소개 및 설치

### 2.1 Claude Code란?

```
┌──────────────────────────────────────────────────────────────┐
│  Claude Code = 터미널에서 동작하는 AI 코딩 파트너               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  "안녕, 나는 Claude Code야! 👋                                │
│   터미널에서 나와 대화하면서 코드를 작성할 수 있어.              │
│   파일 읽기/쓰기, 명령어 실행, Git 작업 모두 가능해!"           │
│                                                              │
│  주요 기능:                                                   │
│  ✅ 프로젝트 전체 구조 이해                                    │
│  ✅ 코드 자동 생성 및 수정                                     │
│  ✅ 터미널 명령어 실행                                         │
│  ✅ Git 커밋/푸시 자동화                                       │
│  ✅ 파일 시스템 전체 접근                                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 설치 방법 (Windows)

#### Step 1: Node.js 설치

```powershell
# Windows PowerShell을 관리자 권한으로 실행

# 1. Node.js 설치 (v18 이상 필요)
winget install OpenJS.NodeJS.LTS

# 2. 설치 확인
node --version
# 출력 예시: v20.10.0

npm --version
# 출력 예시: 10.2.3
```

#### Step 2: Claude Code 설치

```powershell
# npm으로 전역 설치
npm install -g @anthropic-ai/claude-code

# 설치 확인
claude --version
# 출력 예시: claude-code v1.0.0
```

#### Step 3: API Key 설정

```powershell
# 환경변수 설정 (영구 저장)
[System.Environment]::SetEnvironmentVariable(
    "ANTHROPIC_API_KEY", 
    "sk-ant-api03-여기에_API_키_입력", 
    "User"
)

# 현재 세션에도 적용
$env:ANTHROPIC_API_KEY = "sk-ant-api03-여기에_API_키_입력"

# 확인
echo $env:ANTHROPIC_API_KEY
```

> 💡 **API Key 발급**: https://console.anthropic.com/settings/keys

#### Step 4: 프로젝트 폴더에서 실행

```powershell
# 프로젝트 폴더로 이동
cd D:\WorkSpace\GrowAILMS

# Claude Code 실행!
claude

# ╭──────────────────────────────────────────────────────────────╮
# │  Claude Code v1.0.0                                          │
# │  Type your request or /help for commands                     │
# ╰──────────────────────────────────────────────────────────────╯
# > _
```

### 2.3 기본 명령어

```
╭─────────────────────────────────────────────────────────────────╮
│  Claude Code 기본 명령어                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  💬 대화 명령어                                                  │
│  ──────────────────────────────────────────────────────────────│
│  > 이 프로젝트 구조를 분석해줘                                    │
│  > CourseDao.java를 Spring Service로 변환해줘                    │
│  > JSP 파일들을 React 컴포넌트로 바꿔줘                           │
│                                                                 │
│  📁 파일 명령어                                                  │
│  ──────────────────────────────────────────────────────────────│
│  /read src/dao/CourseDao.java     # 파일 읽기                   │
│  /write src/service/Course.java   # 파일 쓰기                   │
│  /ls src/                         # 디렉토리 목록                │
│                                                                 │
│  ⚙️ 시스템 명령어                                                │
│  ──────────────────────────────────────────────────────────────│
│  /run npm install                 # 명령어 실행                  │
│  /git commit -m "message"         # Git 작업                    │
│  /help                            # 도움말                       │
│  /exit                            # 종료                         │
│                                                                 │
╰─────────────────────────────────────────────────────────────────╯
```

---

## 3. 자동화 아키텍처

### 3.1 전체 자동화 파이프라인

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    GrowAILMS 자동화 파이프라인                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Phase 1: 분석 (Analysis)                                                │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │   MalgnLMS Source  ──→  analyze-malgnsoft-lms-v2.ps1  ──→  JSON   │  │
│  │   (7,842 파일)           (정적 분석 자동화)              (분석 결과) │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│  Phase 2: 변환 (Transformation)                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │   JSON  ──→  Claude Code  ──→  GrowAILMS Source                   │  │
│  │   (분석 결과)   (AI 변환 엔진)    (변환된 코드)                       │  │
│  │                                                                    │  │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │  │
│  │   │ Backend     │  │ Frontend    │  │ Database    │               │  │
│  │   │ Converter   │  │ Converter   │  │ Converter   │               │  │
│  │   │             │  │             │  │             │               │  │
│  │   │ DAO → Svc   │  │ JSP → React │  │ DDL → XML   │               │  │
│  │   └─────────────┘  └─────────────┘  └─────────────┘               │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│  Phase 3: 검증 (Validation)                                              │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │   컴파일 체크  ──→  단위 테스트  ──→  기능 비교 검증  ──→  보고서   │  │
│  │   (mvn compile)    (JUnit)         (Source vs Target)             │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│  Phase 4: 배포 (Deployment)                                              │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │   Docker Build  ──→  GitHub Push  ──→  ZIP 패키징                  │  │
│  │   (컨테이너화)       (버전 관리)        (즉시 실행 가능)              │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Claude Code 워크플로우

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    Claude Code 대화형 워크플로우                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  👤 개발자                        🤖 Claude Code                          │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                          │
│  "CourseDao.java를                                                       │
│   Spring Service로 변환해줘"                                              │
│           │                                                              │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │ 1. 파일 읽기      │  ──→  CourseDao.java 내용 분석                    │
│  └──────────────────┘                                                   │
│           │                                                              │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │ 2. 구조 파악      │  ──→  테이블: LM_COURSE                           │
│  │                  │       메서드: 12개 (CRUD + 비즈니스)                │
│  │                  │       코드배열: 5개                                 │
│  └──────────────────┘                                                   │
│           │                                                              │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │ 3. 코드 생성      │  ──→  CourseService.java                         │
│  │                  │       CourseMapper.java                           │
│  │                  │       CourseMapper.xml                            │
│  │                  │       Course.java (Domain)                        │
│  └──────────────────┘                                                   │
│           │                                                              │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │ 4. 파일 저장      │  ──→  GrowAILMS 프로젝트에 저장                   │
│  └──────────────────┘                                                   │
│           │                                                              │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │ 5. 검증 실행      │  ──→  mvn compile (컴파일 체크)                   │
│  └──────────────────┘                                                   │
│           │                                                              │
│           ▼                                                              │
│  "변환 완료! 4개 파일 생성됨.                                              │
│   컴파일 성공. 다음 DAO를                                                 │
│   변환할까요?"                                                            │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 4. 단계별 실행 가이드

### 🔷 Phase 1: 환경 준비 (30분)

#### Step 1-1: 저장소 클론

```powershell
# 작업 폴더 생성
mkdir D:\WorkSpace
cd D:\WorkSpace

# GrowAILMS 클론
git clone -b dev https://github.com/rodem-glitch/GrowAILMS.git
cd GrowAILMS

# MalgnLMS 소스 위치 확인 (Source)
# D:\WorkSpace\MalgnLMS-main_new\MalgnLMS-main
```

#### Step 1-2: 필수 도구 확인

```powershell
# 확인 스크립트 실행
@"
Write-Host "=== GrowAILMS 환경 체크 ===" -ForegroundColor Cyan

# Node.js
Write-Host "`n[1] Node.js:" -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host " OK ($(node --version))" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND" -ForegroundColor Red
}

# Java
Write-Host "[2] Java:" -NoNewline
if (Get-Command java -ErrorAction SilentlyContinue) {
    Write-Host " OK ($(java --version 2>&1 | Select-String 'version'))" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND" -ForegroundColor Red
}

# Git
Write-Host "[3] Git:" -NoNewline
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host " OK ($(git --version))" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND" -ForegroundColor Red
}

# Claude Code
Write-Host "[4] Claude Code:" -NoNewline
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND (npm install -g @anthropic-ai/claude-code)" -ForegroundColor Yellow
}

# API Key
Write-Host "[5] ANTHROPIC_API_KEY:" -NoNewline
if ($env:ANTHROPIC_API_KEY) {
    Write-Host " OK (설정됨)" -ForegroundColor Green
} else {
    Write-Host " NOT SET" -ForegroundColor Red
}
"@ | Out-File -FilePath "check-env.ps1" -Encoding UTF8

.\check-env.ps1
```

### 🔷 Phase 2: Backend 자동 변환 (2시간)

#### Step 2-1: Claude Code 실행 및 분석

```powershell
# GrowAILMS 폴더에서 Claude Code 실행
cd D:\WorkSpace\GrowAILMS
claude
```

Claude Code에서 다음과 같이 대화합니다:

```
╭──────────────────────────────────────────────────────────────────────────╮
│  Claude Code 대화 세션                                                    │
╰──────────────────────────────────────────────────────────────────────────╯

> 안녕! 나는 MalgnLMS를 GrowAILMS로 마이그레이션하려고 해.
  먼저 D:\WorkSpace\MalgnLMS-main_new\MalgnLMS-main\src\dao 폴더의
  모든 DAO 파일을 분석해서 목록을 만들어줘.

🤖 네, DAO 파일들을 분석하겠습니다.

   발견된 DAO 파일: 170개
   
   [우선순위 High]
   1. CourseDao.java - 과정 관리 (145줄)
   2. CourseUserDao.java - 수강생 관리 (883줄) ⭐ 가장 복잡
   3. LessonDao.java - 강의 관리 (164줄)
   4. UserDao.java - 사용자 관리 (234줄)
   ...

> 좋아! CourseDao.java부터 GrowAILMS 스택으로 변환해줘.
  Target 스택:
  - Java 17 + Spring Boot 3.2
  - MyBatis (Mapper Interface + XML)
  - JWT 인증
  - @Transactional, @Cacheable 적용
  - 행안부 시큐어코딩 준수

🤖 CourseDao.java를 분석하고 변환하겠습니다.

   [생성 파일]
   1. src/main/java/kr/ac/kopo/growai/lms/service/CourseService.java
   2. src/main/java/kr/ac/kopo/growai/lms/mapper/CourseMapper.java
   3. src/main/resources/mapper/CourseMapper.xml
   4. src/main/java/kr/ac/kopo/growai/lms/domain/Course.java

   파일을 저장할까요? (y/n)

> y

🤖 4개 파일이 저장되었습니다.
   컴파일 테스트를 실행할까요? (y/n)

> y

🤖 mvn compile 실행 중...
   ✅ BUILD SUCCESS
   
   다음 DAO를 변환할까요?
```

#### Step 2-2: 대량 변환 자동화

```
> 나머지 169개 DAO도 모두 자동으로 변환해줘.
  같은 패턴으로 Service + Mapper + XML + Domain 생성하고,
  5개마다 컴파일 체크해줘.

🤖 대량 변환을 시작합니다.

   진행률: [████████████████████] 100%
   
   결과:
   - 성공: 165개 (97%)
   - 실패: 5개 (3%)
   
   실패한 DAO:
   1. ComplexReportDao.java - 복잡한 서브쿼리 (수동 검토 필요)
   2. ...
   
   생성된 파일:
   - Service: 170개
   - Mapper Interface: 170개
   - Mapper XML: 170개
   - Domain: 170개
   
   총 680개 파일 생성 완료!
```

### 🔷 Phase 3: Frontend 자동 변환 (3시간)

```
> 이제 JSP 파일들을 React 컴포넌트로 변환해줘.
  소스: D:\WorkSpace\MalgnLMS-main_new\MalgnLMS-main\web
  
  Target 스택:
  - React 18 + TypeScript
  - Vite 빌드
  - Tailwind CSS
  - Zustand (상태관리)

🤖 JSP 파일 분석 중...

   발견된 JSP: 1,223개
   
   페이지 유형:
   - 목록 페이지 (List): 312개
   - 상세 페이지 (Detail): 245개
   - 폼 페이지 (Form): 198개
   - 대시보드: 45개
   - 기타: 423개
   
   변환 시작할까요?

> 응, Course 관련 JSP부터 시작해줘

🤖 Course 관련 JSP 변환 중...

   [변환 결과]
   course_list.jsp → CourseList.tsx
   course_view.jsp → CourseDetail.tsx
   course_form.jsp → CourseForm.tsx
   
   생성 위치: src/main/frontend/src/pages/course/
   
   API 연동 코드도 생성할까요?

> 응, axios 기반으로 API 서비스도 만들어줘

🤖 API 서비스 생성 완료!
   
   src/main/frontend/src/services/courseService.ts
   - getCourseList()
   - getCourseById()
   - createCourse()
   - updateCourse()
   - deleteCourse()
```

### 🔷 Phase 4: SQL 및 인프라 (1시간)

```
> MyBatis XML에서 사용하는 테이블 스키마를 DDL로 생성해줘.
  그리고 Docker Compose, Nginx 설정도 만들어줘.

🤖 인프라 파일 생성 중...

   [생성 파일]
   1. docker-compose.yml - 전체 서비스 구성
   2. docker-compose.dev.yml - 개발 환경
   3. nginx/nginx.conf - 웹서버 설정
   4. sql/schema.sql - DDL 스키마
   5. sql/init-data.sql - 초기 데이터
   
   Redis 캐시 설정도 포함할까요?

> 응, Redis도 추가해줘

🤖 완료! 전체 인프라 설정이 준비되었습니다.
   
   docker-compose up -d 로 실행할 수 있습니다.
```

### 🔷 Phase 5: ZIP 패키징 및 검증 (30분)

```
> 전체 프로젝트를 즉시 실행 가능한 ZIP으로 패키징해줘.
  README, 설치 가이드, 환경 설정 예시 파일도 포함해줘.

🤖 ZIP 패키징 중...

   GrowAILMS-v1.0.0-release.zip 생성 완료!
   
   포함 내용:
   ├── src/                    # 소스 코드
   ├── docker-compose.yml      # Docker 설정
   ├── .env.example            # 환경변수 템플릿
   ├── README.md               # 프로젝트 설명
   ├── INSTALL.md              # 설치 가이드
   └── scripts/                # 자동화 스크립트
       ├── setup.sh
       ├── deploy.sh
       └── backup.sh
   
   파일 크기: 15.2 MB
   저장 위치: D:\WorkSpace\GrowAILMS\release\
```

---

## 5. 전체 프로젝트 구조

### 5.1 GrowAILMS 최종 구조

```
GrowAILMS/
├── 📁 src/
│   └── 📁 main/
│       ├── 📁 java/kr/ac/kopo/growai/lms/
│       │   ├── 📁 config/              # 설정 클래스
│       │   │   ├── SecurityConfig.java
│       │   │   ├── JwtConfig.java
│       │   │   ├── RedisConfig.java
│       │   │   └── MyBatisConfig.java
│       │   │
│       │   ├── 📁 controller/          # REST API
│       │   │   ├── CourseController.java
│       │   │   ├── UserController.java
│       │   │   └── ...
│       │   │
│       │   ├── 📁 service/             # 비즈니스 로직 (170개)
│       │   │   ├── CourseService.java
│       │   │   ├── CourseUserService.java
│       │   │   └── ...
│       │   │
│       │   ├── 📁 mapper/              # MyBatis Interface (170개)
│       │   │   ├── CourseMapper.java
│       │   │   └── ...
│       │   │
│       │   ├── 📁 domain/              # Entity/DTO (170개)
│       │   │   ├── Course.java
│       │   │   └── ...
│       │   │
│       │   └── 📁 common/
│       │       ├── 📁 constants/       # Enum 상수
│       │       ├── 📁 security/        # JWT 필터
│       │       └── 📁 exception/       # 예외 처리
│       │
│       ├── 📁 resources/
│       │   ├── 📁 mapper/              # MyBatis XML (170개)
│       │   │   ├── CourseMapper.xml
│       │   │   └── ...
│       │   ├── application.yml
│       │   └── application-dev.yml
│       │
│       └── 📁 frontend/                # React 프론트엔드
│           ├── 📁 src/
│           │   ├── 📁 pages/           # 페이지 컴포넌트
│           │   ├── 📁 components/      # 공통 컴포넌트
│           │   ├── 📁 services/        # API 서비스
│           │   ├── 📁 stores/          # Zustand 스토어
│           │   └── 📁 styles/          # Tailwind CSS
│           ├── package.json
│           ├── vite.config.ts
│           └── tailwind.config.js
│
├── 📁 docker-compose/
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── docker-compose.prod.yml
│   └── 📁 nginx/
│       └── nginx.conf
│
├── 📁 sql/
│   ├── schema.sql                      # DDL
│   ├── init-data.sql                   # 초기 데이터
│   └── migration/                      # 마이그레이션 스크립트
│
├── 📁 scripts/
│   ├── setup.sh                        # 초기 설정
│   ├── deploy.sh                       # 배포
│   ├── backup.sh                       # 백업
│   └── 📁 migration/
│       ├── parallel-migration.ps1
│       └── template-migration.ps1
│
├── 📁 release/
│   └── GrowAILMS-v1.0.0-release.zip    # 즉시 실행 가능 패키지
│
├── .env.example
├── README.md
├── INSTALL.md
├── pom.xml                             # Maven 설정
└── build.gradle                        # Gradle 설정
```

### 5.2 Docker Compose 서비스 구성

```yaml
# docker-compose.yml 미리보기

services:
  # 웹 서버
  nginx:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
      - "443:443"
    
  # 백엔드 API
  backend:
    build: ./src/main
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JWT_SECRET=${JWT_SECRET}
    
  # 프론트엔드
  frontend:
    build: ./src/main/frontend
    
  # 데이터베이스
  mysql:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
    
  # 캐시
  redis:
    image: redis:7-alpine
    
  # 인증 (선택)
  keycloak:
    image: quay.io/keycloak/keycloak:23.0

volumes:
  mysql_data:
```

---

## 6. 확장 전략

### 6.1 Legacy-LMS Transpiler 솔루션

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│    🚀 Legacy-LMS Transpiler                                              │
│    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                                                          │
│    "레거시 LMS를 차세대 플랫폼으로 자동 전환하는 AI 기반 엔진"             │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    [Core Modules]                                                        │
│                                                                          │
│    ┌────────────────┐    ┌────────────────┐    ┌────────────────┐       │
│    │  🔍 Analyzer   │ →  │  🔄 Converter  │ →  │  ✅ Validator  │       │
│    │               │    │               │    │               │       │
│    │ • AST Parser  │    │ • Template    │    │ • Compile     │       │
│    │ • Dependency  │    │ • AI Assist   │    │ • Unit Test   │       │
│    │ • Schema      │    │ • Pattern     │    │ • Integration │       │
│    └────────────────┘    └────────────────┘    └────────────────┘       │
│           │                    │                    │                   │
│           ▼                    ▼                    ▼                   │
│    ┌─────────────────────────────────────────────────────────────┐     │
│    │                    Knowledge Base (JSON)                     │     │
│    │                                                             │     │
│    │  • DAO 패턴 매핑 규칙                                         │     │
│    │  • 코드 배열 → Enum 변환 룰                                    │     │
│    │  • JSP → React 컴포넌트 템플릿                                 │     │
│    │  • 보안 취약점 패턴                                           │     │
│    └─────────────────────────────────────────────────────────────┘     │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    [Supported Transformations]                                           │
│                                                                          │
│    Source Stack           │  Target Stack                               │
│    ───────────────────────┼─────────────────────────────────────────    │
│    Java 8 + DataObject    │  Java 17 + Spring Boot 3.2                  │
│    Custom DAO             │  MyBatis + @Transactional                   │
│    JSP + jQuery           │  React 18 + TypeScript                      │
│    Session Auth           │  JWT + Keycloak                             │
│    Manual SQL             │  MyBatis XML + Redis Cache                  │
│    Ant Build              │  Gradle + Docker                            │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    [Value Proposition]                                                   │
│                                                                          │
│    📊 효율성: 마이그레이션 시간 92% 단축                                  │
│    💰 비용: 인건비 90% 절감                                              │
│    🎯 품질: 100% 기능 일치 보장                                          │
│    🔒 보안: 행안부 시큐어코딩 자동 적용                                   │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 6.2 확장 로드맵

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    Legacy-LMS Transpiler 로드맵                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Phase 1: MVP (현재)                         2026 Q1                     │
│  ─────────────────────────────────────────────────────────────────────  │
│  ✅ MalgnLMS → GrowAILMS 변환 완료                                        │
│  ✅ Claude Code 기반 자동화 파이프라인                                     │
│  ✅ 170개 DAO, 1,223개 JSP 변환 완료                                      │
│                                                                          │
│  Phase 2: 제품화                             2026 Q2                     │
│  ─────────────────────────────────────────────────────────────────────  │
│  ⬜ Web UI 대시보드 개발                                                  │
│  ⬜ 변환 진행률 실시간 모니터링                                            │
│  ⬜ 오류 자동 수정 기능                                                    │
│  ⬜ 다중 소스 LMS 지원 (Moodle, Canvas 등)                                │
│                                                                          │
│  Phase 3: SaaS 출시                          2026 Q3                     │
│  ─────────────────────────────────────────────────────────────────────  │
│  ⬜ 클라우드 SaaS 버전 출시                                               │
│  ⬜ 구독 기반 과금 모델                                                    │
│  ⬜ API 제공 (타 시스템 연동)                                              │
│  ⬜ 교육기관 전용 플랜                                                     │
│                                                                          │
│  Phase 4: 글로벌 확장                        2026 Q4                     │
│  ─────────────────────────────────────────────────────────────────────  │
│  ⬜ 다국어 지원 (영어, 일본어)                                             │
│  ⬜ 글로벌 LMS 프레임워크 지원                                             │
│  ⬜ 파트너 채널 구축                                                       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 6.3 비즈니스 모델

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    Legacy-LMS Transpiler 비즈니스 모델                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [수익 모델]                                                              │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │    Starter     │  │   Professional │  │   Enterprise   │          │
│  │   무료 / 오픈소스  │  │  월 99만원      │  │  협의           │          │
│  │                 │  │                │  │                │          │
│  │ • 10개 DAO 변환  │  │ • 무제한 변환   │  │ • 무제한 변환   │          │
│  │ • 커뮤니티 지원   │  │ • 이메일 지원   │  │ • 전담 지원     │          │
│  │ • 기본 템플릿     │  │ • 고급 템플릿   │  │ • 커스텀 개발   │          │
│  │                 │  │ • 우선 업데이트  │  │ • SLA 보장     │          │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘          │
│                                                                          │
│  [타겟 고객]                                                              │
│                                                                          │
│  1️⃣ 교육기관 (대학, 전문대, 학원)                                         │
│     - 레거시 LMS 현대화 수요                                              │
│     - 예상 시장: 한국 내 200+ 교육기관                                     │
│                                                                          │
│  2️⃣ SI 업체                                                              │
│     - 교육 시스템 구축 프로젝트                                            │
│     - 마이그레이션 외주 수요                                               │
│                                                                          │
│  3️⃣ 공공기관                                                             │
│     - 전자정부 프레임워크 전환 사업                                        │
│     - 클라우드 네이티브 전환 사업                                          │
│                                                                          │
│  [예상 매출]                                                              │
│                                                                          │
│  2026: 5억원 (초기 고객 확보)                                             │
│  2027: 15억원 (SaaS 확장)                                                │
│  2028: 30억원 (글로벌 진출)                                               │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 7. 트러블슈팅

### 7.1 자주 발생하는 문제

| 문제 | 원인 | 해결책 |
|------|------|--------|
| `claude: command not found` | Claude Code 미설치 | `npm install -g @anthropic-ai/claude-code` |
| `ANTHROPIC_API_KEY not set` | 환경변수 미설정 | 환경변수 설정 (2.2 참조) |
| `API 404 Error` | 모델 경로 오류 | Claude Code 최신 버전으로 업데이트 |
| `mvn compile 실패` | Java 버전 불일치 | Java 17 설치 확인 |
| `npm install 오류` | Node.js 버전 | Node.js 18+ 설치 |

### 7.2 API 오류 대응

```powershell
# API 연결 테스트
claude --test-api

# 실패 시: API Key 재설정
$env:ANTHROPIC_API_KEY = "새로운_API_키"

# Claude Code 캐시 초기화
claude --clear-cache
```

### 7.3 도움 요청

- 📧 기술 지원: support@newkl.co.kr
- 📚 문서: https://docs.growailms.kr
- 💬 Slack: #growailms-support

---

## ✅ 체크리스트

### 설치 체크리스트
- [ ] Node.js 18+ 설치
- [ ] Java 17 설치
- [ ] Git 설치
- [ ] Claude Code 설치
- [ ] ANTHROPIC_API_KEY 설정
- [ ] GrowAILMS 저장소 클론

### 변환 체크리스트
- [ ] Phase 1: 환경 준비 완료
- [ ] Phase 2: Backend 변환 완료 (170개 DAO)
- [ ] Phase 3: Frontend 변환 완료 (1,223개 JSP)
- [ ] Phase 4: SQL/인프라 설정 완료
- [ ] Phase 5: ZIP 패키징 완료
- [ ] 컴파일 테스트 통과
- [ ] Docker 실행 테스트 통과

---

*본 문서는 NEWKL 내부 기밀 문서입니다. 외부 유출을 금지합니다.*
