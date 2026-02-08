@echo off
REM ============================================
REM GrowAI LMS 테스트 실행 스크립트
REM ============================================

echo [TEST] 테스트 실행...
echo.

cd /d "%~dp0polytech-lms-api"

REM 1. 단위 테스트
echo [1/3] 단위 테스트 실행...
call gradlew.bat test --no-daemon

if %errorlevel% neq 0 (
    echo [FAIL] 단위 테스트 실패!
    exit /b 1
)
echo [PASS] 단위 테스트 성공

REM 2. AI 서비스 연결 확인
echo.
echo [2/3] AI 서비스 연결 확인...

curl -s http://localhost:6333/ >nul 2>&1
if %errorlevel% equ 0 (
    echo   Qdrant: OK
) else (
    echo   Qdrant: 연결 안됨 (선택사항)
)

curl -s http://localhost:8001/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   임베딩 서비스: OK
) else (
    echo   임베딩 서비스: 연결 안됨 (선택사항)
)

curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   vLLM: OK
) else (
    echo   vLLM: 연결 안됨 (선택사항)
)

REM 3. 통합 테스트 (AI 서비스 연결 시에만)
echo.
echo [3/3] 통합 테스트...

set QDRANT_ENABLED=false
set VLLM_ENABLED=false
set EMBEDDING_ENABLED=false

curl -s http://localhost:6333/ >nul 2>&1
if %errorlevel% equ 0 set QDRANT_ENABLED=true

curl -s http://localhost:8001/health >nul 2>&1
if %errorlevel% equ 0 set EMBEDDING_ENABLED=true

curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 set VLLM_ENABLED=true

call gradlew.bat test --tests "*IntegrationTest" --no-daemon -DQDRANT_ENABLED=%QDRANT_ENABLED% -DVLLM_ENABLED=%VLLM_ENABLED% -DEMBEDDING_ENABLED=%EMBEDDING_ENABLED%

echo.
echo ============================================
echo [TEST] 테스트 완료!
echo ============================================
echo 결과 확인: polytech-lms-api\build\reports\tests\test\index.html
echo.

pause
