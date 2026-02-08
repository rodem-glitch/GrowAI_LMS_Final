@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ============================================
echo   GrowAILMS 통합 빌드 스크립트
echo   Spring Boot 3.2.5 + Java 17
echo ============================================
echo.

set PROJECT_ROOT=%~dp0
set API_DIR=%PROJECT_ROOT%polytech-lms-api

:: 환경변수 로드
if exist "%PROJECT_ROOT%.env" (
    echo [1/5] 환경변수 로드 중...
    for /f "usebackq tokens=1,* delims==" %%a in ("%PROJECT_ROOT%.env") do (
        set "%%a=%%b"
    )
    echo      완료
) else (
    echo [경고] .env 파일이 없습니다. 기본값 사용
)

:: Gradle 빌드
echo.
echo [2/5] Gradle 빌드 시작...
cd /d "%API_DIR%"

call gradlew.bat clean build -x test --no-daemon
if %ERRORLEVEL% neq 0 (
    echo [오류] Gradle 빌드 실패
    exit /b 1
)
echo      빌드 성공

:: JAR 파일 확인
echo.
echo [3/5] 빌드 결과 확인...
set JAR_FILE=%API_DIR%\build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar
if not exist "%JAR_FILE%" (
    echo [오류] JAR 파일을 찾을 수 없습니다: %JAR_FILE%
    exit /b 1
)
echo      JAR 파일: %JAR_FILE%

:: 정적 리소스 동기화
echo.
echo [4/5] 정적 리소스 동기화...
xcopy /E /Y /I "%PROJECT_ROOT%public_html\common\css" "%API_DIR%\src\main\resources\static\common\css" > nul 2>&1
xcopy /E /Y /I "%PROJECT_ROOT%public_html\common\js" "%API_DIR%\src\main\resources\static\common\js" > nul 2>&1
xcopy /E /Y /I "%PROJECT_ROOT%public_html\html" "%API_DIR%\src\main\resources\static\html" > nul 2>&1
echo      완료

:: 완료 메시지
echo.
echo [5/5] 빌드 완료!
echo ============================================
echo   실행 명령어:
echo   java -jar "%JAR_FILE%"
echo.
echo   또는 개발 모드:
echo   cd polytech-lms-api ^&^& gradlew bootRun
echo ============================================

cd /d "%PROJECT_ROOT%"
endlocal
