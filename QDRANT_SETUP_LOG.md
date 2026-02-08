# Qdrant Vector Database Setup Log

> **작업일시**: 2026-02-07 18:00
> **작업자**: Claude AI
> **프로젝트**: GrowAI-LMS Backend Integration
> **상태**: ✅ 완료

---

## Executive Summary

| 항목 | 결과 |
|------|------|
| **Qdrant 버전** | 1.11.4 |
| **컬렉션 수** | 4개 |
| **총 벡터 수** | 20개 (각 컬렉션 5개) |
| **벡터 차원** | 768 (Google text-embedding-004 호환) |
| **거리 함수** | Cosine Similarity |
| **서비스 상태** | ✅ 정상 (Green) |

---

## 1. 설치 및 구성

### 1.1 Qdrant 실행 환경

| 항목 | 설정 |
|------|------|
| 실행 파일 | D:\qdrant\qdrant.exe |
| REST API | http://localhost:6333 |
| gRPC | localhost:6334 |
| Dashboard | http://localhost:6333/dashboard |

### 1.2 서비스 시작/종료

```batch
# 시작 (start_integrated.bat에 포함)
start /B "" D:\qdrant\qdrant.exe

# 종료 (stop_integrated.bat에 포함)
taskkill /F /IM qdrant.exe
```

---

## 2. 컬렉션 구성

### 2.1 lms_contents (학습 콘텐츠)

| 필드 | 설명 |
|------|------|
| **용도** | 동영상, 문서, 퀴즈 등 학습 콘텐츠 유사도 검색 |
| **벡터 차원** | 768 |
| **거리 함수** | Cosine |
| **인덱싱** | 5개 포인트 |

**Payload 스키마:**
```json
{
  "title": "string",
  "type": "video|document|quiz",
  "duration": "number (seconds)",
  "pages": "number",
  "category": "string"
}
```

### 2.2 lms_courses (교육과정)

| 필드 | 설명 |
|------|------|
| **용도** | 과정 추천, 유사 과정 탐색 |
| **벡터 차원** | 768 |
| **거리 함수** | Cosine |
| **인덱싱** | 5개 포인트 |

**Payload 스키마:**
```json
{
  "name": "string",
  "level": "beginner|intermediate|advanced",
  "weeks": "number",
  "instructor": "string"
}
```

### 2.3 lms_users (사용자 프로필)

| 필드 | 설명 |
|------|------|
| **용도** | 사용자 관심사 기반 매칭, 협업 필터링 |
| **벡터 차원** | 768 |
| **거리 함수** | Cosine |
| **인덱싱** | 5개 포인트 |

**Payload 스키마:**
```json
{
  "name": "string",
  "role": "student|instructor|admin",
  "interests": ["string"],
  "expertise": ["string"]
}
```

### 2.4 lms_recommendations (AI 추천)

| 필드 | 설명 |
|------|------|
| **용도** | 개인화 추천 결과 저장 및 검색 |
| **벡터 차원** | 768 |
| **거리 함수** | Cosine |
| **인덱싱** | 5개 포인트 |

**Payload 스키마:**
```json
{
  "user_id": "number",
  "course_id": "number",
  "score": "number (0-1)",
  "reason": "skill_match|interest_based|career_path|popular|collaborative"
}
```

---

## 3. 인덱싱 결과

### 3.1 컬렉션별 상태

| 컬렉션 | 상태 | 포인트 수 | 세그먼트 수 |
|--------|------|-----------|-------------|
| lms_contents | ✅ Green | 5 | 2 |
| lms_courses | ✅ Green | 5 | 8 |
| lms_users | ✅ Green | 5 | 8 |
| lms_recommendations | ✅ Green | 5 | 8 |

### 3.2 벡터 검색 테스트

**요청:**
```bash
curl -X POST "http://localhost:6333/collections/lms_contents/points/search" \
  -H "Content-Type: application/json" \
  -d '{"vector": [...768 dims...], "limit": 3, "with_payload": true}'
```

**응답:**
```json
{
  "result": [
    {"id": 5, "score": 0.0518, "payload": {"title": "AI 기초 이론", "category": "ai"}},
    {"id": 1, "score": 0.0429, "payload": {"title": "React 기초 과정", "category": "frontend"}},
    {"id": 2, "score": -0.0075, "payload": {"title": "Spring Boot 실전", "category": "backend"}}
  ],
  "status": "ok",
  "time": 0.0016
}
```

**결과:** ✅ 벡터 유사도 검색 정상 작동 (응답시간: 1.6ms)

---

## 4. 설정 파일

### 4.1 Qdrant 설정

**경로:** `D:\Real_Backend_Integration\config\qdrant.yaml`

```yaml
qdrant:
  host: localhost
  port: 6333
  grpc_port: 6334

collections:
  lms_contents:
    vector_size: 768
    distance: Cosine
  lms_courses:
    vector_size: 768
    distance: Cosine
  lms_users:
    vector_size: 768
    distance: Cosine
  lms_recommendations:
    vector_size: 768
    distance: Cosine

embedding:
  model: text-embedding-004
  dimensions: 768
```

### 4.2 인덱싱 데이터 파일

| 파일 | 용도 |
|------|------|
| qdrant_contents.json | 콘텐츠 벡터 데이터 |
| qdrant_courses.json | 과정 벡터 데이터 |
| qdrant_users.json | 사용자 벡터 데이터 |
| qdrant_recommendations.json | 추천 벡터 데이터 |
| qdrant_search.json | 검색 테스트 쿼리 |

---

## 5. API 사용 예제

### 5.1 벡터 추가

```bash
curl -X PUT "http://localhost:6333/collections/lms_contents/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [{
      "id": 100,
      "vector": [0.1, 0.2, ..., 0.768],
      "payload": {"title": "새 콘텐츠", "type": "video"}
    }]
  }'
```

### 5.2 벡터 검색

```bash
curl -X POST "http://localhost:6333/collections/lms_contents/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, ..., 0.768],
    "limit": 5,
    "with_payload": true,
    "filter": {
      "must": [{"key": "category", "match": {"value": "ai"}}]
    }
  }'
```

### 5.3 페이로드 필터링

```bash
curl -X POST "http://localhost:6333/collections/lms_courses/points/scroll" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "must": [{"key": "level", "match": {"value": "advanced"}}]
    },
    "limit": 10,
    "with_payload": true
  }'
```

---

## 6. 운영 가이드

### 6.1 모니터링

| 엔드포인트 | 용도 |
|------------|------|
| GET /collections | 컬렉션 목록 |
| GET /collections/{name} | 컬렉션 상태 |
| GET /metrics | Prometheus 메트릭 |
| GET /telemetry | 사용 통계 |

### 6.2 백업

```bash
# 스냅샷 생성
curl -X POST "http://localhost:6333/collections/lms_contents/snapshots"

# 스냅샷 목록
curl "http://localhost:6333/collections/lms_contents/snapshots"
```

### 6.3 성능 튜닝

| 파라미터 | 기본값 | 권장값 | 설명 |
|----------|--------|--------|------|
| m | 16 | 16-64 | HNSW 그래프 연결 수 |
| ef_construct | 100 | 100-400 | 인덱스 생성 정확도 |
| indexing_threshold | 20000 | 10000-50000 | 인덱싱 트리거 임계값 |

---

## 7. 다음 단계

| 우선순위 | 작업 | 상태 |
|----------|------|------|
| P0 | Google GenAI API Key 발급 | 대기 |
| P0 | 실 데이터 임베딩 생성 | 대기 |
| P1 | 대량 데이터 벌크 인덱싱 | 예정 |
| P1 | 검색 API 통합 테스트 | 예정 |
| P2 | 성능 벤치마크 | 예정 |

---

## 8. 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    Vector Search Architecture                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐     ┌──────────────────┐                   │
│  │  Spring Boot    │────▶│  Google GenAI    │                   │
│  │  Backend API    │     │  Embedding API   │                   │
│  │  (:8081)        │◀────│  768 dimensions  │                   │
│  └────────┬────────┘     └──────────────────┘                   │
│           │                                                      │
│           │ REST/gRPC                                            │
│           ▼                                                      │
│  ┌─────────────────────────────────────────────┐                │
│  │              Qdrant Vector DB               │                │
│  │              (:6333 / :6334)                │                │
│  ├─────────────────────────────────────────────┤                │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐  │                │
│  │  │lms_contents│ │lms_courses│ │lms_users │  │                │
│  │  │  5 pts    │ │  5 pts    │ │  5 pts   │  │                │
│  │  └───────────┘ └───────────┘ └───────────┘  │                │
│  │  ┌─────────────────────────────────────┐    │                │
│  │  │       lms_recommendations           │    │                │
│  │  │            5 pts                    │    │                │
│  │  └─────────────────────────────────────┘    │                │
│  └─────────────────────────────────────────────┘                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

**작성 완료**: 2026-02-07 18:05
**총 작업 시간**: 약 5분
**상태**: ✅ Qdrant 설치, 구성, 인덱싱 완료
