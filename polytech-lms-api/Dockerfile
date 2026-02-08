# ============================================
# GrowAI LMS API - Multi-stage Dockerfile
# Docker Compose & Cloud Run Optimized
# ============================================

# Stage 1: Build
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Make gradlew executable
RUN chmod +x gradlew

# Download dependencies (cached layer)
RUN ./gradlew dependencies --no-daemon || true

# Copy source code
COPY src src

# Build application
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Install required packages
RUN apk add --no-cache tzdata curl

# Set timezone to KST
ENV TZ=Asia/Seoul

# Create non-root user for security
RUN addgroup -S lms && adduser -S lms -G lms

# Create log directory
RUN mkdir -p /var/log/lms && chown -R lms:lms /var/log/lms

# Copy built artifact from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Change ownership
RUN chown -R lms:lms /app

# Switch to non-root user
USER lms

# Default port (Docker Compose: 8081, Cloud Run: 8080)
ENV PORT=8081
EXPOSE 8081

# JVM options for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0 \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/actuator/health || exit 1

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --server.port=${PORT}"]
