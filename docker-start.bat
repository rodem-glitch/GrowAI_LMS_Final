@echo off
REM ============================================
REM GrowAI LMS Docker Compose 시작 스크립트
REM ============================================

echo [LMS] Docker Compose 시작...

REM 1. 환경 변수 확인
if not exist ".env" (
    echo [WARN] .env 파일이 없습니다. .env.example을 복사합니다.
    copy ".env.example" ".env" 2>nul
)

REM 2. SSL 인증서 확인
if not exist "docker\nginx\ssl\fullchain.pem" (
    echo [WARN] SSL 인증서가 없습니다. 자체 서명 인증서를 생성합니다.
    mkdir "docker\nginx\ssl" 2>nul
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
        -keyout docker\nginx\ssl\privkey.pem ^
        -out docker\nginx\ssl\fullchain.pem ^
        -subj "/CN=localhost"
)

REM 3. Docker Compose 실행
echo [LMS] 서비스 시작 중...
docker-compose up -d

REM 4. 상태 확인
echo.
echo [LMS] 서비스 상태:
docker-compose ps

echo.
echo [LMS] 접속 정보:
echo   - LMS API: http://localhost:8081
echo   - Nginx: http://localhost:80
echo   - Grafana: http://localhost:3000 (admin/admin)
echo   - Prometheus: http://localhost:9090
echo   - OpenSearch: http://localhost:9200
echo   - Superset: http://localhost:8088 (admin/admin)
echo.
echo [LMS] 로그 확인: docker-compose logs -f lms-api

pause
