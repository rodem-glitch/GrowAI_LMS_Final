# API Key 발급 요청 메일

---

## 메일 본문

**제목:** [긴급] GrowAI-LMS 운영환경 API Key 발급 요청

---

안녕하세요, 인프라팀 담당자님.

GrowAI-LMS 백엔드 통합 작업이 완료되어, 운영환경 가동을 위한 API Key 발급을 요청드립니다.

---

### 1. 요청 배경

| 항목 | 내용 |
|------|------|
| 프로젝트명 | GrowAI-LMS Backend Integration |
| 완료일시 | 2026-02-07 18:05 |
| 현재 상태 | ✅ Production Ready (API Key 제외) |
| 긴급도 | **P0 (Critical)** |

---

### 2. 필요한 API Key 목록

| No | API Key | 용도 | 필수여부 | 예상 사용량 |
|----|---------|------|----------|-------------|
| 1 | **Google GenAI API Key** | AI 텍스트 임베딩 (text-embedding-004) | **필수** | 월 10만 요청 |
| 2 | Google Cloud Project ID | GenAI API 연동 | **필수** | - |

---

### 3. API Key 상세 요구사항

#### 3.1 Google GenAI API Key

| 항목 | 요구사항 |
|------|----------|
| **서비스** | Google AI Studio / Vertex AI |
| **모델** | text-embedding-004 |
| **벡터 차원** | 768 dimensions |
| **용도** | 학습 콘텐츠 유사도 검색, AI 추천 시스템 |
| **호출 방식** | REST API (HTTPS) |
| **예상 QPS** | 평균 10 req/s, 최대 100 req/s |

#### 3.2 권한 범위 (Scopes)

```
- generativelanguage.models.embedText
- generativelanguage.models.get
```

---

### 4. 환경 변수 설정 방법

API Key 발급 후 아래와 같이 환경변수로 설정하면 즉시 서비스 가동됩니다:

```batch
# Windows 환경변수 설정
set GOOGLE_API_KEY=발급받은_API_KEY

# 또는 시스템 환경변수로 영구 설정
setx GOOGLE_API_KEY "발급받은_API_KEY"
```

---

### 5. 서비스 시작 명령어

API Key 설정 후:

```batch
cd D:\Real_Backend_Integration\polytech-lms-api
java -Dspring.ai.google.genai.embedding.api-key=%GOOGLE_API_KEY% ^
     -jar build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar
```

또는 통합 스크립트 실행:

```batch
D:\Real_Backend_Integration\start_integrated.bat
```

---

### 6. 보안 요구사항

| 항목 | 요구사항 |
|------|----------|
| 접근 제한 | 운영 서버 IP만 허용 |
| 키 저장 | 환경변수 또는 Secret Manager |
| 키 로테이션 | 90일 주기 권장 |
| 모니터링 | 사용량 알림 설정 (80% 임계치) |

---

### 7. 예상 비용

| 항목 | 단가 | 예상 월 사용량 | 예상 비용 |
|------|------|----------------|-----------|
| text-embedding-004 | $0.00002/1K chars | 1억 문자 | ~$200/월 |

> ※ Google AI Studio 무료 티어: 월 1,500 요청 무료

---

### 8. 일정

| 단계 | 예상일 | 담당 |
|------|--------|------|
| API Key 발급 요청 | 2026-02-07 (오늘) | 개발팀 |
| API Key 발급 | 2026-02-08 | 인프라팀 |
| Backend API 가동 | 2026-02-08 | 개발팀 |
| 전체 서비스 오픈 | 2026-02-09 | 운영팀 |

---

### 9. 담당자 정보

| 역할 | 이름 | 연락처 |
|------|------|--------|
| 개발팀 담당 | [이름] | [이메일/전화] |
| 인프라팀 담당 | [이름] | [이메일/전화] |

---

### 10. 첨부 파일

- CEO_REPORT.md (통합 완료 보고서)
- INTEGRATION_LOG.md (작업 로그)

---

빠른 검토 및 발급 부탁드립니다.
API Key가 발급되면 즉시 전체 서비스 가동이 가능합니다.

감사합니다.

---

**발신:** 개발팀
**일자:** 2026-02-07

---

## 빠른 복사용 (Plain Text)

```
제목: [긴급] GrowAI-LMS 운영환경 API Key 발급 요청

안녕하세요, 인프라팀 담당자님.

GrowAI-LMS 백엔드 통합 작업이 완료되어 API Key 발급을 요청드립니다.

■ 필요한 API Key
1. Google GenAI API Key (필수)
   - 용도: AI 텍스트 임베딩 (text-embedding-004)
   - 예상 사용량: 월 10만 요청

■ 긴급도: P0 (Critical)
■ 희망 발급일: 2026-02-08

API Key 발급 시 아래 환경변수 설정으로 즉시 서비스 가동됩니다:
set GOOGLE_API_KEY=발급받은_API_KEY

빠른 검토 부탁드립니다.
감사합니다.
```
