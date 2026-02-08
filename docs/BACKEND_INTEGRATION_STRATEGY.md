# GrowAI-LMS Backend 통합 전략

> **작성일**: 2026-02-07
> **버전**: 1.0.0
> **대상**: Backend, Interface, Endpoint, Database, Vector Database
> **목표**: 성능최적화, 운영편리성, 확장성, NCP 완벽 호환

---

## Executive Summary

| 영역 | 현재 상태 | 목표 상태 (NCP) | 우선순위 |
|------|-----------|-----------------|----------|
| Database | MySQL 8.4 (로컬) | Cloud DB for MySQL | P0 |
| Vector DB | Qdrant 1.11 (로컬) | NCP VM + Qdrant Cloud | P0 |
| Backend API | Spring Boot 3.2.5 | NCP Container Registry + Kubernetes | P1 |
| Cache | 없음 | Redis (Cloud DB for Redis) | P1 |
| CDN/Storage | Kollus | NCP Object Storage + CDN+ | P2 |
| AI/Embedding | Google GenAI | NCP CLOVA (옵션) / Google GenAI | P2 |

---

## 1. 현재 아키텍처 분석

### 1.1 시스템 구성 (AS-IS)

```
┌─────────────────────────────────────────────────────────────────┐
│                        현재 로컬 환경                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Resin     │    │ Spring Boot │    │   MySQL     │         │
│  │   4.0.66    │───▶│   3.2.5     │───▶│   8.4.8     │         │
│  │  (Port 8080)│    │  (Port 8081)│    │  (Port 3306)│         │
│  └─────────────┘    └──────┬──────┘    └─────────────┘         │
│                            │                                    │
│                            ▼                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Kollus    │    │   Qdrant    │    │ Google GenAI│         │
│  │  (영상CDN)  │    │   1.11.4    │    │ (Embedding) │         │
│  │  (외부API)  │    │  (Port 6333)│    │  (외부API)  │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 기술 스택 현황

| 계층 | 기술 | 버전 | 파일 수 |
|------|------|------|---------|
| Frontend | React + Vite | 18.x + 6.x | - |
| Legacy | JSP + Resin | 4.0.66 | ~500 |
| Backend API | Spring Boot | 3.2.5 | 151 |
| ORM | JPA/Hibernate | 6.x | - |
| Database | MySQL | 8.4.8 | - |
| Vector DB | Qdrant | 1.11.4 | 4 collections |
| Embedding | Google GenAI | gemini-embedding-001 | 768차원 |
| AI/LLM | Gemini | gemini-3-flash | - |

### 1.3 외부 연동 API

| 서비스 | 용도 | 인증 방식 |
|--------|------|-----------|
| Kollus | 영상 스트리밍/전사 | API Token |
| Google GenAI | 임베딩/요약 | API Key |
| Work24 | 채용 공고 조회 | Auth Key |
| JobKorea | 채용 공고 조회 | API Key + OEM |
| KOSIS/SGIS | 통계 데이터 | Consumer Key/Secret |

---

## 2. NCP 서비스 매핑

### 2.1 인프라 매핑

| 현재 | NCP 서비스 | 장점 |
|------|------------|------|
| MySQL 로컬 | **Cloud DB for MySQL** | 자동 백업, HA, 모니터링 |
| Qdrant 로컬 | **Server (VM)** + Qdrant | GPU 옵션, 스케일업 |
| Spring Boot JAR | **Container Registry** + **Kubernetes Service** | 오토스케일링, 롤링 배포 |
| 없음 | **Cloud DB for Redis** | 세션/캐시, 성능 향상 |
| Kollus CDN | **Object Storage** + **CDN+** | 비용 절감, 국내 최적화 |

### 2.2 보안/네트워크 매핑

| 항목 | NCP 서비스 |
|------|------------|
| VPC | **VPC** (가상 사설 클라우드) |
| 방화벽 | **ACG** (Access Control Group) |
| SSL/TLS | **Certificate Manager** |
| 로드밸런서 | **Load Balancer** |
| DNS | **Global DNS** |
| WAF | **Web Security Checker** |

### 2.3 운영/모니터링 매핑

| 항목 | NCP 서비스 |
|------|------------|
| 로그 수집 | **Cloud Log Analytics** |
| 모니터링 | **Cloud Insight** |
| 알림 | **Cloud Insight + Event Rule** |
| 백업 | **Cloud DB 자동 백업** + **Backup** |

---

## 3. Database 전략

### 3.1 Cloud DB for MySQL 마이그레이션

#### 3.1.1 스펙 권장

| 환경 | 스펙 | vCPU | RAM | Storage |
|------|------|------|-----|---------|
| 개발/테스트 | Standard | 2 | 4GB | 100GB SSD |
| 스테이징 | Standard | 4 | 8GB | 200GB SSD |
| **운영** | **High Memory** | **8** | **32GB** | **500GB SSD** |

#### 3.1.2 HA 구성

```
┌─────────────────────────────────────────────────────────────┐
│                    NCP Cloud DB for MySQL                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐         ┌──────────────┐                │
│   │   Primary    │────────▶│   Standby    │                │
│   │   (Zone 1)   │  Sync   │   (Zone 2)   │                │
│   └──────┬───────┘         └──────────────┘                │
│          │                                                  │
│          │ Auto Failover                                    │
│          ▼                                                  │
│   ┌──────────────┐                                         │
│   │  Read Replica│  (Optional, 읽기 분산)                  │
│   │   (Zone 1)   │                                         │
│   └──────────────┘                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 3.1.3 연결 풀 최적화

```yaml
# application-ncp.yml
spring:
  datasource:
    url: jdbc:mysql://${NCP_DB_HOST}:3306/lms?useSSL=true&requireSSL=true
    username: ${NCP_DB_USER}
    password: ${NCP_DB_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 20000
      max-lifetime: 1200000
      leak-detection-threshold: 60000
```

#### 3.1.4 마이그레이션 절차

| 단계 | 작업 | 예상 시간 |
|------|------|-----------|
| 1 | Cloud DB 인스턴스 생성 | 10분 |
| 2 | 스키마 마이그레이션 (mysqldump) | 5분 |
| 3 | 데이터 마이그레이션 | 30분~2시간 |
| 4 | 애플리케이션 연결 테스트 | 30분 |
| 5 | DNS 전환 (무중단) | 5분 |

---

## 4. Vector Database 전략

### 4.1 Qdrant 운영 옵션 비교

| 옵션 | 장점 | 단점 | 비용 (월) |
|------|------|------|-----------|
| **NCP VM + Qdrant** | 완전 제어, NCP VPC 내부 | 관리 필요 | ~₩100,000 |
| Qdrant Cloud | 관리형, 글로벌 | 외부 네트워크 | ~$50 |
| Milvus on NCP | 오픈소스, 확장성 | 복잡한 설정 | ~₩150,000 |

### 4.2 권장 구성: NCP VM + Qdrant

#### 4.2.1 VM 스펙

| 환경 | 서버 타입 | vCPU | RAM | Storage |
|------|-----------|------|-----|---------|
| 개발 | Standard | 2 | 4GB | 50GB SSD |
| **운영** | **High Memory** | **4** | **16GB** | **200GB SSD** |

#### 4.2.2 Qdrant 설정 최적화

```yaml
# qdrant/config.yaml
storage:
  storage_path: /data/qdrant

service:
  grpc_port: 6334
  http_port: 6333

optimizers:
  default_segment_number: 4
  memmap_threshold_kb: 20480
  indexing_threshold_kb: 10240

performance:
  max_search_threads: 4
  max_optimization_threads: 2
```

#### 4.2.3 컬렉션 관리 전략

| 컬렉션 | 용도 | 차원 | 예상 벡터 수 |
|--------|------|------|--------------|
| video_summary_vectors_gemini | 영상 요약 검색 | 768 | ~50,000 |
| course_vectors | 과정 추천 | 768 | ~5,000 |
| job_vectors | 채용 매칭 | 768 | ~100,000 |
| user_profile_vectors | 학습자 프로파일 | 768 | ~10,000 |

#### 4.2.4 인덱싱 최적화

```python
# 컬렉션 생성 최적화 설정
{
    "vectors": {
        "size": 768,
        "distance": "Cosine"
    },
    "optimizers_config": {
        "indexing_threshold": 10000,
        "memmap_threshold": 50000
    },
    "hnsw_config": {
        "m": 16,
        "ef_construct": 128,
        "full_scan_threshold": 10000
    }
}
```

---

## 5. Backend API 전략

### 5.1 컨테이너화 (Docker)

#### 5.1.1 Dockerfile 최적화

```dockerfile
# Multi-stage build for optimization
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY gradle gradle
COPY gradlew build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon
COPY src src
RUN ./gradlew bootJar --no-daemon -x test

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

#### 5.1.2 NCP Container Registry 배포

```bash
# 1. 이미지 빌드
docker build -t polytech-lms-api:1.0.0 .

# 2. NCP Registry 태그
docker tag polytech-lms-api:1.0.0 \
  ${NCP_REGISTRY}/polytech-lms-api:1.0.0

# 3. 푸시
docker push ${NCP_REGISTRY}/polytech-lms-api:1.0.0
```

### 5.2 Kubernetes 배포

#### 5.2.1 Deployment 설정

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: polytech-lms-api
  namespace: lms-prod
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: polytech-lms-api
  template:
    metadata:
      labels:
        app: polytech-lms-api
    spec:
      containers:
      - name: api
        image: ${NCP_REGISTRY}/polytech-lms-api:1.0.0
        ports:
        - containerPort: 8081
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 5
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "ncp"
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: lms-secrets
              key: db-url
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: lms-secrets
              key: db-password
        - name: GOOGLE_API_KEY
          valueFrom:
            secretKeyRef:
              name: lms-secrets
              key: google-api-key
```

#### 5.2.2 HPA (오토스케일링)

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: polytech-lms-api-hpa
  namespace: lms-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: polytech-lms-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## 6. Cache 전략 (Redis)

### 6.1 Cloud DB for Redis 구성

| 환경 | 노드 수 | 메모리 | 용도 |
|------|---------|--------|------|
| 개발 | 1 | 1GB | 세션, 캐시 |
| **운영** | **3 (클러스터)** | **4GB x 3** | 세션, 캐시, Rate Limit |

### 6.2 캐시 적용 대상

| 대상 | TTL | 예상 효과 |
|------|-----|-----------|
| 과정 목록 | 5분 | DB 쿼리 90% 감소 |
| 채용 공고 | 24시간 | API 호출 99% 감소 |
| 사용자 세션 | 30분 | Stateless 서버 |
| Vector 검색 결과 | 1시간 | 임베딩 호출 80% 감소 |

### 6.3 Spring Cache 설정

```yaml
# application-ncp.yml
spring:
  cache:
    type: redis
  data:
    redis:
      host: ${NCP_REDIS_HOST}
      port: 6379
      password: ${NCP_REDIS_PASSWORD}
      lettuce:
        pool:
          max-active: 10
          max-idle: 5
          min-idle: 2
```

```java
// 캐시 적용 예시
@Cacheable(value = "courses", key = "#categoryId", unless = "#result == null")
public List<CourseDto> getCoursesByCategory(Long categoryId) {
    return courseRepository.findByCategoryId(categoryId);
}

@Cacheable(value = "jobs", key = "#regionCode + '_' + #occupationCode",
           cacheManager = "longTermCacheManager")
public List<JobDto> searchJobs(String regionCode, String occupationCode) {
    return jobKoreaClient.searchJobs(regionCode, occupationCode);
}
```

---

## 7. API Endpoint 전략

### 7.1 API Gateway 패턴

```
┌─────────────────────────────────────────────────────────────────┐
│                     NCP Load Balancer                           │
│                    (SSL Termination)                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API Gateway Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  - Rate Limiting (Redis)                                        │
│  - Authentication (JWT)                                         │
│  - Request Logging                                              │
│  - Response Caching                                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │  Legacy   │   │  Backend  │   │  Vector   │
    │   API     │   │    API    │   │  Search   │
    │ (Resin)   │   │ (Spring)  │   │  (Qdrant) │
    └───────────┘   └───────────┘   └───────────┘
```

### 7.2 Endpoint 표준화

| 경로 패턴 | 용도 | 인증 |
|-----------|------|------|
| `/api/v1/public/*` | 공개 API | 없음 |
| `/api/v1/auth/*` | 인증 관련 | 없음 |
| `/api/v1/user/*` | 사용자 API | JWT |
| `/api/v1/admin/*` | 관리자 API | JWT + Role |
| `/api/v1/internal/*` | 내부 서비스 간 | API Key |
| `/actuator/*` | 헬스체크 | IP 제한 |

### 7.3 Rate Limiting

```java
// RateLimitConfig.java
@Configuration
public class RateLimitConfig {

    @Bean
    public RateLimiter publicApiLimiter(RedisTemplate<String, String> redis) {
        return RateLimiter.builder()
            .limit(100)
            .window(Duration.ofMinutes(1))
            .keyResolver(request -> request.getRemoteAddr())
            .storage(new RedisRateLimitStorage(redis))
            .build();
    }

    @Bean
    public RateLimiter embeddingApiLimiter(RedisTemplate<String, String> redis) {
        // 임베딩 API는 비용이 높으므로 더 엄격하게 제한
        return RateLimiter.builder()
            .limit(10)
            .window(Duration.ofMinutes(1))
            .keyResolver(request -> extractUserId(request))
            .storage(new RedisRateLimitStorage(redis))
            .build();
    }
}
```

---

## 8. 성능 최적화 전략

### 8.1 Database 최적화

| 항목 | 현재 | 최적화 | 예상 효과 |
|------|------|--------|-----------|
| 인덱스 | 기본 | 복합 인덱스 추가 | 쿼리 50% 개선 |
| 쿼리 | N+1 존재 | Fetch Join | 쿼리 수 90% 감소 |
| 페이징 | Offset | Cursor 기반 | 대량 조회 100배 개선 |
| 연결 풀 | 기본 (10) | 최적화 (20) | 동시성 2배 |

### 8.2 Vector Search 최적화

| 항목 | 현재 | 최적화 | 예상 효과 |
|------|------|--------|-----------|
| 인덱스 | HNSW 기본 | m=16, ef=128 | 정확도 10% 향상 |
| 배치 검색 | 개별 호출 | 배치 API | 지연시간 70% 감소 |
| 캐싱 | 없음 | Redis 캐시 | 반복 쿼리 95% 캐시 히트 |
| 필터링 | 후처리 | Pre-filter | 검색 범위 50% 감소 |

### 8.3 API 응답 최적화

```java
// 비동기 처리
@Async
@Cacheable(value = "recommendations", key = "#userId")
public CompletableFuture<List<RecommendationDto>> getRecommendations(Long userId) {
    return CompletableFuture.supplyAsync(() -> {
        // Vector 검색 + 필터링
        return vectorSearchService.searchSimilar(userId, 20);
    });
}

// 병렬 처리
public DashboardDto getDashboard(Long userId) {
    CompletableFuture<List<CourseDto>> courses = getCourses(userId);
    CompletableFuture<List<JobDto>> jobs = getRecommendedJobs(userId);
    CompletableFuture<StatisticsDto> stats = getStatistics(userId);

    CompletableFuture.allOf(courses, jobs, stats).join();

    return DashboardDto.builder()
        .courses(courses.get())
        .jobs(jobs.get())
        .statistics(stats.get())
        .build();
}
```

---

## 9. 운영 편리성 전략

### 9.1 CI/CD 파이프라인

```yaml
# .github/workflows/ncp-deploy.yml
name: NCP Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Build with Gradle
      run: ./gradlew bootJar -x test

    - name: Build Docker Image
      run: docker build -t ${{ secrets.NCP_REGISTRY }}/polytech-lms-api:${{ github.sha }} .

    - name: Push to NCP Registry
      run: |
        echo ${{ secrets.NCP_REGISTRY_PASSWORD }} | docker login -u ${{ secrets.NCP_REGISTRY_USER }} --password-stdin ${{ secrets.NCP_REGISTRY }}
        docker push ${{ secrets.NCP_REGISTRY }}/polytech-lms-api:${{ github.sha }}

    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/polytech-lms-api \
          api=${{ secrets.NCP_REGISTRY }}/polytech-lms-api:${{ github.sha }} \
          --namespace=lms-prod
```

### 9.2 모니터링 대시보드

| 메트릭 | 임계값 | 알림 |
|--------|--------|------|
| CPU 사용률 | > 80% | Slack + Email |
| 메모리 사용률 | > 85% | Slack + Email |
| API 응답시간 (P99) | > 2초 | Slack |
| DB 연결 풀 | > 90% | Slack + PagerDuty |
| 에러율 | > 1% | Slack + PagerDuty |

### 9.3 로그 관리

```yaml
# logback-spring.xml (JSON 형식)
<encoder class="net.logstash.logback.encoder.LogstashEncoder">
  <customFields>
    {"service":"polytech-lms-api","environment":"${SPRING_PROFILES_ACTIVE}"}
  </customFields>
</encoder>
```

```sql
-- Cloud Log Analytics 쿼리 예시
SELECT
  timestamp,
  level,
  message,
  traceId
FROM logs
WHERE service = 'polytech-lms-api'
  AND level = 'ERROR'
  AND timestamp > NOW() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
LIMIT 100
```

---

## 10. 확장성 전략

### 10.1 수평 확장

| 컴포넌트 | 확장 방식 | 트리거 |
|----------|-----------|--------|
| Backend API | K8s HPA | CPU > 70% |
| Vector DB | Qdrant 클러스터 | 벡터 수 > 1M |
| Cache | Redis 클러스터 | 메모리 > 80% |
| Database | Read Replica | 읽기 쿼리 > 1000/s |

### 10.2 멀티 리전 (장기)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Global DNS (NCP)                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
    ┌───────────────┐               ┌───────────────┐
    │  KR Region    │               │  JP Region    │
    │  (Primary)    │◀─────────────▶│  (DR/Backup)  │
    │               │   Replication │               │
    │  - API x 3    │               │  - API x 2    │
    │  - DB Primary │               │  - DB Standby │
    │  - Redis x 3  │               │  - Redis x 2  │
    │  - Qdrant x 2 │               │  - Qdrant x 1 │
    └───────────────┘               └───────────────┘
```

### 10.3 마이크로서비스 분리 (장기)

| 서비스 | 책임 | 우선순위 |
|--------|------|----------|
| lms-gateway | 인증, 라우팅 | P1 |
| lms-course | 과정/강의 관리 | P2 |
| lms-user | 사용자 관리 | P2 |
| lms-recommendation | AI 추천 | P2 |
| lms-statistics | 통계/분석 | P3 |
| lms-job | 채용 연동 | P3 |

---

## 11. 보안 전략

### 11.1 NCP 보안 서비스 적용

| 서비스 | 적용 대상 | 설정 |
|--------|-----------|------|
| ACG | 모든 서버 | 최소 권한 원칙 |
| SSL VPN | 관리자 접근 | 2FA 필수 |
| WAF | API Gateway | OWASP Top 10 |
| KMS | API Keys, DB Password | 자동 로테이션 |

### 11.2 Secrets 관리

```yaml
# K8s Secret (NCP KMS 연동)
apiVersion: v1
kind: Secret
metadata:
  name: lms-secrets
  namespace: lms-prod
  annotations:
    ncp.com/kms-key-id: ${KMS_KEY_ID}
type: Opaque
stringData:
  db-url: ${ENCRYPTED_DB_URL}
  db-password: ${ENCRYPTED_DB_PASSWORD}
  google-api-key: ${ENCRYPTED_GOOGLE_API_KEY}
```

### 11.3 공공기관 보안 요건

| 요건 | 대응 방안 |
|------|-----------|
| 망분리 | NCP VPC + Private Subnet |
| 접근통제 | ACG + IAM + 감사 로그 |
| 암호화 | 전송(TLS 1.3) + 저장(AES-256) |
| 백업 | 일일 자동 백업 + 90일 보관 |
| 감사 | Cloud Activity Tracer |

---

## 12. 구현 로드맵

### Phase 1: 인프라 구축 (1주)

| 일자 | 작업 | 담당 |
|------|------|------|
| Day 1 | VPC, Subnet, ACG 구성 | 인프라 |
| Day 2 | Cloud DB for MySQL 생성 | 인프라 |
| Day 3 | DB 마이그레이션 | DBA |
| Day 4 | Qdrant VM 구성 | 인프라 |
| Day 5 | Redis 클러스터 구성 | 인프라 |

### Phase 2: 애플리케이션 배포 (1주)

| 일자 | 작업 | 담당 |
|------|------|------|
| Day 1 | Dockerfile 최적화 | 개발 |
| Day 2 | K8s 매니페스트 작성 | DevOps |
| Day 3 | CI/CD 파이프라인 구축 | DevOps |
| Day 4 | 스테이징 배포/테스트 | QA |
| Day 5 | 프로덕션 배포 | DevOps |

### Phase 3: 최적화/안정화 (1주)

| 일자 | 작업 | 담당 |
|------|------|------|
| Day 1-2 | 성능 테스트/튜닝 | QA + 개발 |
| Day 3 | 모니터링/알림 설정 | DevOps |
| Day 4 | 문서화/운영 가이드 | 전체 |
| Day 5 | 보안 점검/취약점 조치 | 보안 |

---

## 13. 예상 비용 (월간)

| 서비스 | 스펙 | 예상 비용 |
|--------|------|-----------|
| Cloud DB for MySQL | 8vCPU/32GB, HA | ₩450,000 |
| Server (Qdrant) | 4vCPU/16GB | ₩150,000 |
| Kubernetes Service | 3 Pods (2vCPU/4GB) | ₩300,000 |
| Cloud DB for Redis | 4GB x 3 클러스터 | ₩200,000 |
| Load Balancer | Standard | ₩50,000 |
| Object Storage | 500GB | ₩25,000 |
| Cloud Insight | 기본 | ₩0 |
| **합계** | | **~₩1,175,000** |

---

## 14. 첨부: 환경변수 템플릿

```bash
# .env.ncp.template
# ===== Database =====
NCP_DB_HOST=xxxxx.mysql.ncloud.com
NCP_DB_USER=lms_admin
NCP_DB_PASSWORD=

# ===== Redis =====
NCP_REDIS_HOST=xxxxx.redis.ncloud.com
NCP_REDIS_PASSWORD=

# ===== Qdrant =====
QDRANT_HOST=10.x.x.x
QDRANT_GRPC_PORT=6334
QDRANT_COLLECTION=video_summary_vectors_gemini

# ===== Google AI =====
GOOGLE_API_KEY=
GOOGLE_EMBEDDING_MODEL=gemini-embedding-001

# ===== External APIs =====
KOLLUS_ACCESS_TOKEN=
WORK24_AUTH_KEY=
JOBKOREA_API_KEY=
```

---

**문서 작성 완료**: 2026-02-07
**다음 단계**: Phase 1 인프라 구축 착수
