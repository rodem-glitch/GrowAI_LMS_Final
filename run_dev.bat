@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ============================================
echo   GrowAILMS 개발 모드 실행
echo   Spring Boot DevTools 활성화
echo ============================================
echo.

set PROJECT_ROOT=%~dp0
set API_DIR=%PROJECT_ROOT%polytech-lms-api

:: 환경변수 로드
if exist "%PROJECT_ROOT%.env" (
    echo [INFO] 환경변수 로드 중...
    for /f "usebackq tokens=1,* delims==" %%a in ("%PROJECT_ROOT%.env") do (
        set "%%a=%%b"
    )
)

:: 정적 리소스 동기화
echo [INFO] 정적 리소스 동기화...
xcopy /E /Y /I "%PROJECT_ROOT%public_html\common\css" "%API_DIR%\src\main\resources\static\common\css" > nul 2>&1
xcopy /E /Y /I "%PROJECT_ROOT%public_html\common\js" "%API_DIR%\src\main\resources\static\common\js" > nul 2>&1
echo      완료

:: 개발 서버 실행
echo.
echo [INFO] 개발 서버 시작 (Hot Reload 활성화)...
echo [INFO] 포트: 8081
echo [INFO] API 문서: http://localhost:8081/actuator
echo [INFO] 종료: Ctrl+C
echo.

cd /d "%API_DIR%"
call gradlew.bat bootRun --args="--spring.devtools.restart.enabled=true"

cd /d "%PROJECT_ROOT%"
endlocal
