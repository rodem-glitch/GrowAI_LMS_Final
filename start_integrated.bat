@echo off
chcp 65001 >nul
title GrowAI-LMS Integrated Service
color 0A

echo ╔══════════════════════════════════════════════════════════════╗
echo ║         GrowAI-LMS 통합 서비스 시작                           ║
echo ║         Backend Integration v1.0                             ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set START_TIME=%TIME%

:: ========== 1. MySQL ==========
echo [1/4] MySQL 8.4.8...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I "mysqld.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo      [OK] 실행중
) else (
    start /B "" "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --datadir="D:\mysql_data"
    timeout /t 5 /nobreak >nul
    echo      [OK] 시작됨
)

:: ========== 2. Qdrant ==========
echo [2/4] Qdrant 1.11.4...
tasklist /FI "IMAGENAME eq qdrant.exe" 2>NUL | find /I "qdrant.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo      [OK] 실행중
) else (
    start /B "" D:\qdrant\qdrant.exe
    timeout /t 3 /nobreak >nul
    echo      [OK] 시작됨
)

:: ========== 3. Resin (Legacy + 교수자 LMS) ==========
echo [3/4] Resin 4.0.66 (Legacy JSP + React SPA)...
cd /d D:\resin_server\resin-4.0.66
call bin\start.bat >nul 2>&1
timeout /t 5 /nobreak >nul
echo      [OK] 시작됨 (Port 8080)

:: ========== 4. Backend API ==========
echo [4/4] Spring Boot Backend API...
if not defined GOOGLE_API_KEY (
    echo      [SKIP] GOOGLE_API_KEY 미설정 - 수동 시작 필요
    echo             set GOOGLE_API_KEY=your-key
    echo             java -jar polytech-lms-api-0.0.1-SNAPSHOT.jar
) else (
    cd /d D:\Real_Backend_Integration\polytech-lms-api
    start /B java -Dspring.datasource.url="jdbc:mysql://localhost:3306/lms?useSSL=false&allowPublicKeyRetrieval=true" -Dspring.datasource.username=lms -Dspring.datasource.password=lms123 -Dspring.ai.google.genai.embedding.api-key=%GOOGLE_API_KEY% -jar build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar
    echo      [OK] 시작됨 (Port 8081)
)

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    서비스 현황                                ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  [Legacy JSP]  http://localhost:8080                         ║
echo ║  [교수자 LMS]  http://localhost:8080/tutor_lms/app/          ║
echo ║  [학생 LMS]    http://localhost:8080/mypage/new_main/        ║
echo ║  [Backend API] http://localhost:8081 (API Key 필요)          ║
echo ║  [Qdrant]      http://localhost:6333                         ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 시작 시간: %START_TIME% → 완료: %TIME%
echo.

start http://localhost:8080/tutor_lms/app/
pause
