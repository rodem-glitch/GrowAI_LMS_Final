@echo off
REM ============================================
REM GrowAI LMS 온프레미스 AI 서비스 시작 스크립트
REM ============================================

echo [AI] 온프레미스 AI 서비스 시작...
echo.

REM GPU 확인
nvidia-smi >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] NVIDIA GPU가 감지되지 않습니다!
    echo GPU 드라이버를 확인하세요.
    pause
    exit /b 1
)

echo [OK] NVIDIA GPU 감지됨
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo.

REM Docker 확인
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker가 설치되지 않았습니다!
    pause
    exit /b 1
)

REM NVIDIA Container Toolkit 확인
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] NVIDIA Container Toolkit 설정이 필요할 수 있습니다.
)

REM 네트워크 생성 (없으면)
docker network create lms-network 2>nul

REM 1. Qdrant 시작
echo [1/4] Qdrant 벡터 DB 시작...
docker-compose -f docker-compose.yml up -d qdrant
timeout /t 5 /nobreak >nul

REM 2. 임베딩 서비스 시작
echo [2/4] BGE-M3 임베딩 서비스 시작...
docker-compose -f docker-compose.ai.yml up -d embedding
timeout /t 10 /nobreak >nul

REM 3. vLLM 시작 (Gemma 2)
echo [3/4] vLLM + Gemma 2 시작 (최초 실행 시 모델 다운로드 필요)...
docker-compose -f docker-compose.ai.yml up -d vllm
echo     모델 로딩에 2-5분 소요될 수 있습니다.

REM 4. GPU 모니터링
echo [4/4] GPU 모니터링 시작...
docker-compose -f docker-compose.ai.yml up -d nvidia-dcgm-exporter 2>nul

echo.
echo ============================================
echo [AI] 서비스 시작 완료!
echo ============================================
echo.
echo 접속 정보:
echo   - vLLM API: http://localhost:8000
echo   - 임베딩 API: http://localhost:8001
echo   - Qdrant: http://localhost:6333
echo   - GPU 메트릭: http://localhost:9400/metrics
echo.
echo 상태 확인:
echo   curl http://localhost:8000/health
echo   curl http://localhost:8001/health
echo   curl http://localhost:6333/
echo.
echo 로그 확인:
echo   docker-compose -f docker-compose.ai.yml logs -f vllm
echo.

pause
