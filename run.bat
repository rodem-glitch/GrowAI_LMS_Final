@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================
:: GrowAI LMS - One-Click Runner
:: Usage: run.bat [check|start|stop|full]
:: ============================================

set "CMD=%~1"
if "%CMD%"=="" set "CMD=check"

set "BASE_DIR=D:\Real_one_stop_service"
set "ENV_FILE=%BASE_DIR%\.env"

echo.
echo ============================================
echo     GrowAI LMS - One-Click Runner
echo ============================================
echo.

:: Step 1: Load Environment Variables
echo [1/4] Loading Environment Variables...
if exist "%ENV_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        set "LINE=%%A"
        if not "!LINE:~0,1!"=="#" (
            if not "%%B"=="" (
                set "%%A=%%B"
            )
        )
    )
    echo       [OK] .env loaded
) else (
    echo       [WARN] .env not found - using system env
)

if /i "%CMD%"=="check" goto CHECK
if /i "%CMD%"=="start" goto START
if /i "%CMD%"=="stop" goto STOP
if /i "%CMD%"=="full" goto FULL
goto CHECK

:CHECK
echo.
echo [2/4] Checking Services...
echo.
echo ----------------------------------------
echo  Port    Service          Status    PID
echo ----------------------------------------

for %%P in (6333 8080 8081 8088) do (
    set "STATUS=--"
    set "PID_NUM=-"
    set "PROC=-"

    for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":%%P " ^| findstr "LISTENING"') do (
        set "STATUS=OK"
        set "PID_NUM=%%A"
        for /f "tokens=1" %%B in ('tasklist /FI "PID eq %%A" /FO TABLE /NH 2^>nul') do (
            set "PROC=%%B"
        )
    )

    if "%%P"=="6333" set "SVC=Qdrant VectorDB"
    if "%%P"=="8080" set "SVC=Resin WAS      "
    if "%%P"=="8081" set "SVC=Spring Boot    "
    if "%%P"=="8088" set "SVC=Python Server  "

    echo  %%P    !SVC! [!STATUS!]      !PID_NUM!
)
echo ----------------------------------------

echo.
echo [3/4] Checking API Keys...
echo ----------------------------------------
if defined GOOGLE_API_KEY (echo  GOOGLE_API_KEY:  [OK]) else (echo  GOOGLE_API_KEY:  [-])
if defined GEMINI_API_KEY (echo  GEMINI_API_KEY:  [OK]) else (echo  GEMINI_API_KEY:  [-])
if defined YOUTUBE_API_KEY (echo  YOUTUBE_API_KEY: [OK]) else (echo  YOUTUBE_API_KEY: [-])
if defined QDRANT_HOST (echo  QDRANT_HOST:     %QDRANT_HOST%) else (echo  QDRANT_HOST:     [-])
echo ----------------------------------------

echo.
echo [4/4] Health Check...
echo ----------------------------------------

:: Gemini API
curl -s -o nul "https://generativelanguage.googleapis.com/v1beta/models" 2>nul
if !errorlevel! equ 0 (echo  Gemini API:      [OK] Reachable) else (echo  Gemini API:      [-] Unreachable)

:: YouTube API
curl -s -o nul "https://www.googleapis.com/youtube/v3/videos" 2>nul
if !errorlevel! equ 0 (echo  YouTube API:     [OK] Reachable) else (echo  YouTube API:     [-] Unreachable)

:: Qdrant
curl -s http://localhost:6333/readyz >nul 2>&1
if !errorlevel! equ 0 (echo  Qdrant:          [OK] Healthy) else (echo  Qdrant:          [-] Not responding)

:: Spring Boot
curl -s http://localhost:8081/actuator/health >nul 2>&1
if !errorlevel! equ 0 (echo  Spring Boot:     [OK] Healthy) else (echo  Spring Boot:     [-] Not responding)

:: Resin
curl -s http://localhost:8080/ >nul 2>&1
if !errorlevel! equ 0 (echo  Resin WAS:       [OK] Healthy) else (echo  Resin WAS:       [-] Not responding)

:: Python
curl -s http://localhost:8088/ >nul 2>&1
if !errorlevel! equ 0 (echo  Python Server:   [OK] Healthy) else (echo  Python Server:   [-] Not responding)

echo ----------------------------------------
echo.
echo [DONE] All checks complete.
echo.
goto END

:START
echo.
echo [2/4] Starting All Services...
echo.

:: Start Qdrant
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":6333 " ^| findstr "LISTENING"') do set "Q_PID=%%A"
if not defined Q_PID (
    echo  [6333] Starting Qdrant...
    where qdrant >nul 2>&1
    if !errorlevel! equ 0 (
        start "" /B qdrant >nul 2>&1
        echo         Started
    ) else (
        echo         Not in PATH - start manually
    )
) else (
    echo  [6333] Qdrant already running
)

:: Start Resin
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do set "R_PID=%%A"
if not defined R_PID (
    echo  [8080] Starting Resin WAS...
    if exist "%BASE_DIR%\start_integrated.bat" (
        start "" /B cmd /c "%BASE_DIR%\start_integrated.bat" >nul 2>&1
        echo         Started
    )
) else (
    echo  [8080] Resin already running
)

:: Start Spring Boot
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":8081 " ^| findstr "LISTENING"') do set "S_PID=%%A"
if not defined S_PID (
    echo  [8081] Starting Spring Boot...
    if exist "%BASE_DIR%\polytech-lms-api\mvnw.cmd" (
        start "" /B cmd /c "cd /d %BASE_DIR%\polytech-lms-api && mvnw.cmd spring-boot:run" >nul 2>&1
        echo         Started
    )
) else (
    echo  [8081] Spring Boot already running
)

echo.
echo [3/4] Waiting for services to start...
timeout /t 5 /nobreak >nul

echo.
echo [4/4] Verifying...
goto CHECK

:STOP
echo.
echo [2/4] Stopping All Services...
echo.

for %%P in (6333 8080 8081 8088) do (
    for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":%%P " ^| findstr "LISTENING"') do (
        echo  [%%P] Stopping PID %%A...
        taskkill /F /PID %%A >nul 2>&1
    )
)

echo.
echo [3/4] Verifying...
timeout /t 2 /nobreak >nul

echo.
echo [4/4] Status Check...
goto CHECK

:FULL
echo.
echo [FULL] Complete System Check + Start
echo.
call :START
goto END

:END
endlocal
