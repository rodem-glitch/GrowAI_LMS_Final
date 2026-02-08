@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ============================================
echo   GrowAILMS 통합 빌드
echo   Frontend: React + Vite
echo   Backend: Spring Boot 3.2.5
echo ============================================
echo.

set PROJECT_ROOT=%~dp0
set FRONTEND_DIR=%PROJECT_ROOT%frontend
set BACKEND_DIR=%PROJECT_ROOT%polytech-lms-api

:: 환경변수 로드
if exist "%PROJECT_ROOT%.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%PROJECT_ROOT%.env") do (
        set "%%a=%%b"
    )
)

:: Frontend 빌드
echo [1/4] Frontend 빌드 (React + Vite)...
cd /d "%FRONTEND_DIR%"

if not exist "node_modules" (
    echo      npm install 실행 중...
    call npm install
    if %ERRORLEVEL% neq 0 (
        echo [오류] npm install 실패
        exit /b 1
    )
)

call npm run build
if %ERRORLEVEL% neq 0 (
    echo [오류] Frontend 빌드 실패
    exit /b 1
)
echo      Frontend 빌드 성공

:: Backend 빌드
echo.
echo [2/4] Backend 빌드 (Spring Boot)...
cd /d "%BACKEND_DIR%"
call gradlew.bat clean build -x test --no-daemon
if %ERRORLEVEL% neq 0 (
    echo [오류] Backend 빌드 실패
    exit /b 1
)
echo      Backend 빌드 성공

:: JAR 확인
echo.
echo [3/4] 빌드 결과 확인...
set JAR_FILE=%BACKEND_DIR%\build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar
if not exist "%JAR_FILE%" (
    echo [오류] JAR 파일을 찾을 수 없습니다
    exit /b 1
)
echo      JAR: %JAR_FILE%

:: 완료
echo.
echo [4/4] 빌드 완료!
echo ============================================
echo   실행 명령어:
echo   java -jar "%JAR_FILE%"
echo.
echo   개발 모드 (Hot Reload):
echo   Backend: cd polytech-lms-api ^& gradlew bootRun
echo   Frontend: cd frontend ^& npm run dev
echo ============================================

cd /d "%PROJECT_ROOT%"
endlocal
