# Real One-Stop Service

> **브랜치**: feature/one-stop-service-20260207
> **생성일**: 2026-02-07 18:15
> **상태**: ✅ 작업 준비 완료

---

## Quick Start

### 1. Resin 설정 변경 (최초 1회)

```batch
D:\Real_one_stop_service\resin-config.bat
```

### 2. 전체 서비스 시작

```batch
D:\Real_one_stop_service\start_integrated.bat
```

### 3. 전체 서비스 종료

```batch
D:\Real_one_stop_service\stop_integrated.bat
```

---

## 서비스 URL

| 서비스 | URL |
|--------|-----|
| Legacy JSP | http://localhost:8080 |
| 교수자 LMS | http://localhost:8080/tutor_lms/app/ |
| 학생 LMS | http://localhost:8080/mypage/new_main/ |
| Backend API | http://localhost:8081 |
| Qdrant | http://localhost:6333/dashboard |

---

## 폴더 구조

```
D:\Real_one_stop_service\
├── start_integrated.bat      ← 전체 서비스 시작
├── stop_integrated.bat       ← 전체 서비스 종료
├── resin-config.bat          ← Resin 설정 변경
├── README_ONE_STOP.md        ← 본 문서
│
├── project/                  ← Frontend 소스 (React + Vite)
├── polytech-lms-api/         ← Backend API (Spring Boot)
├── public_html/              ← 웹 루트
│   ├── WEB-INF/
│   │   └── classes/dao/      ← DAO 클래스
│   ├── mypage/               ← 학생 LMS
│   └── tutor_lms/app/        ← 교수자 LMS (React SPA)
│
├── config/                   ← 설정 파일
│   └── qdrant.yaml
│
└── docs/                     ← 문서
```

---

## Git 정보

| 항목 | 값 |
|------|-----|
| Remote | git@github.com:rodem-glitch/GrowAI_LMS_Backup.git |
| Branch | feature/one-stop-service-20260207 |
| Clone 경로 | D:\Real_one_stop_service |

---

## API Key (자동 적용됨)

| 환경변수 | 상태 |
|----------|------|
| GOOGLE_API_KEY | ✅ start_integrated.bat에 설정됨 |
| GEMINI_API_KEY | ✅ (동일) |
| DB_PASSWORD | ✅ lms123 |

---

**작업 준비 완료**: 2026-02-07 18:15
