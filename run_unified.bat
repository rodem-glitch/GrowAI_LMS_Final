@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ============================================
echo   GrowAILMS 통합 실행 스크립트
echo   Spring Boot 3.2.5 + Java 17
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

:: JAR 파일 확인
set JAR_FILE=%API_DIR%\build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar
if not exist "%JAR_FILE%" (
    echo [INFO] JAR 파일이 없습니다. 빌드를 먼저 실행합니다...
    call "%PROJECT_ROOT%build_unified.bat"
    if %ERRORLEVEL% neq 0 (
        echo [오류] 빌드 실패
        exit /b 1
    )
)

:: 애플리케이션 실행
echo.
echo [INFO] Spring Boot 애플리케이션 시작...
echo [INFO] 포트: 8081
echo [INFO] 종료: Ctrl+C
echo.

java -jar "%JAR_FILE%" ^
    --server.port=8081 ^
    --spring.profiles.active=default

endlocal
