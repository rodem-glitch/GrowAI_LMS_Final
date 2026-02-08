# ============================================
# epoly AI Backend - Multi-stage Dockerfile
# ============================================

# Stage 1: Build
FROM gradle:8-jdk17 AS builder

WORKDIR /app

# Gradle 빌드 파일을 먼저 복사하여 의존성 레이어를 캐싱합니다.
COPY build.gradle settings.gradle ./
COPY gradle gradle

# 의존성 다운로드 (캐시 레이어)
RUN gradle dependencies --no-daemon || true

# 소스 코드 복사
COPY src src

# 애플리케이션 빌드 (테스트 스킵)
RUN gradle bootJar --no-daemon -x test

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# 필수 패키지 설치
RUN apk add --no-cache tzdata curl

# 타임존을 한국 표준시(KST)로 설정
ENV TZ=Asia/Seoul

# 보안을 위해 non-root 사용자 생성
RUN addgroup -S epoly && adduser -S epoly -G epoly

# 로그 디렉토리 생성
RUN mkdir -p /var/log/epoly && chown -R epoly:epoly /var/log/epoly

# 빌드 스테이지에서 JAR 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 파일 소유권 변경
RUN chown -R epoly:epoly /app

# non-root 사용자로 전환
USER epoly

# 포트 노출
EXPOSE 8081

# 컨테이너 환경에 최적화된 JVM 옵션
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0 \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom"

# 헬스 체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
