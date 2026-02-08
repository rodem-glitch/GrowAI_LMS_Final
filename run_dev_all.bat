@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ============================================
echo   GrowAILMS 개발 모드 실행
echo   Frontend: http://localhost:3000
echo   Backend:  http://localhost:8081
echo ============================================
echo.

set PROJECT_ROOT=%~dp0

:: 환경변수 로드
if exist "%PROJECT_ROOT%.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%PROJECT_ROOT%.env") do (
        set "%%a=%%b"
    )
)

:: Backend 시작 (백그라운드)
echo [1/2] Backend 시작 중...
start "Spring Boot" cmd /c "cd /d "%PROJECT_ROOT%polytech-lms-api" && gradlew bootRun"

:: 잠시 대기
timeout /t 5 /nobreak > nul

:: Frontend 시작
echo [2/2] Frontend 시작 중...
cd /d "%PROJECT_ROOT%frontend"

if not exist "node_modules" (
    echo      npm install 실행 중...
    call npm install
)

call npm run dev

endlocal
