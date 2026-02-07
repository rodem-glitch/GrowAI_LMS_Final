@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================
:: GrowAI LMS Service Manager v2.0
:: Usage: svc.bat [status|start|stop|restart|api|health]
:: ============================================

set "CMD=%~1"
if "%CMD%"=="" set "CMD=status"

if /i "%CMD%"=="status" goto STATUS
if /i "%CMD%"=="start" goto START
if /i "%CMD%"=="stop" goto STOP
if /i "%CMD%"=="restart" goto RESTART
if /i "%CMD%"=="api" goto API_CHECK
if /i "%CMD%"=="health" goto HEALTH_CHECK
if /i "%CMD%"=="help" goto HELP
goto HELP

:STATUS
echo.
echo ============================================
echo     GrowAI LMS Service Status
echo ============================================
echo.
echo ----------------------------------------
echo  Port    Service          Status    PID
echo ----------------------------------------

:: Check all services including Qdrant
for %%P in (6333 8080 8081 8088) do (
    set "STATUS=STOPPED"
    set "PID_NUM=-"
    set "PROC=-"

    for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":%%P " ^| findstr "LISTENING"') do (
        set "STATUS=RUNNING"
        set "PID_NUM=%%A"
        for /f "tokens=1" %%B in ('tasklist /FI "PID eq %%A" /FO TABLE /NH 2^>nul') do (
            set "PROC=%%B"
        )
    )

    if "%%P"=="6333" set "SVC=Qdrant VectorDB"
    if "%%P"=="8080" set "SVC=Resin WAS      "
    if "%%P"=="8081" set "SVC=Spring Boot    "
    if "%%P"=="8088" set "SVC=Python Server  "

    if "!STATUS!"=="RUNNING" (
        echo  %%P    !SVC! [OK]      !PID_NUM! ^(!PROC!^)
    ) else (
        echo  %%P    !SVC! [--]      -
    )
)

echo ----------------------------------------
echo.
echo  [OK] = Running / [--] = Stopped
echo.
goto END

:START
echo.
echo [START] Starting all services...
echo.

:: Start Qdrant
call :GET_PID 6333 PID
if "!PID!"=="-" (
    echo [6333] Starting Qdrant VectorDB...
    where qdrant >nul 2>&1
    if !errorlevel! equ 0 (
        start "" /B qdrant >nul 2>&1
        echo [6333] Qdrant start command sent
    ) else (
        echo [6333] INFO: Qdrant not in PATH - start manually or use Docker
        echo        docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant
    )
) else (
    echo [6333] Qdrant already running [PID: !PID!]
)

:: Start Resin WAS
call :GET_PID 8080 PID
if "!PID!"=="-" (
    echo [8080] Starting Resin WAS...
    if exist "D:\Real_one_stop_service\start_integrated.bat" (
        start "" /B cmd /c "D:\Real_one_stop_service\start_integrated.bat" >nul 2>&1
        echo [8080] Resin WAS start command sent
    ) else (
        echo [8080] ERROR: start_integrated.bat not found
    )
) else (
    echo [8080] Resin WAS already running [PID: !PID!]
)

:: Start Spring Boot
call :GET_PID 8081 PID
if "!PID!"=="-" (
    echo [8081] Starting Spring Boot...
    if exist "D:\Real_one_stop_service\polytech-lms-api\mvnw.cmd" (
        start "" /B cmd /c "cd /d D:\Real_one_stop_service\polytech-lms-api && mvnw.cmd spring-boot:run" >nul 2>&1
        echo [8081] Spring Boot start command sent
    ) else (
        echo [8081] ERROR: mvnw.cmd not found
    )
) else (
    echo [8081] Spring Boot already running [PID: !PID!]
)

echo.
echo [START] Complete. Use 'svc status' to verify.
echo.
goto END

:STOP
echo.
echo [STOP] Stopping all services...
echo.

for %%P in (6333 8080 8081 8088) do (
    call :GET_PID %%P PID
    if "!PID!"=="-" (
        if "%%P"=="6333" echo [%%P] Qdrant already stopped
        if "%%P"=="8080" echo [%%P] Resin WAS already stopped
        if "%%P"=="8081" echo [%%P] Spring Boot already stopped
        if "%%P"=="8088" echo [%%P] Python Server already stopped
    ) else (
        if "%%P"=="6333" echo [%%P] Stopping Qdrant [PID: !PID!]...
        if "%%P"=="8080" echo [%%P] Stopping Resin WAS [PID: !PID!]...
        if "%%P"=="8081" echo [%%P] Stopping Spring Boot [PID: !PID!]...
        if "%%P"=="8088" echo [%%P] Stopping Python Server [PID: !PID!]...
        taskkill /F /PID !PID! >nul 2>&1
        echo [%%P] Stopped
    )
)

echo.
echo [STOP] Complete.
echo.
goto END

:RESTART
echo.
echo [RESTART] Restarting all services...
echo.
call :STOP
timeout /t 3 /nobreak >nul
call :START
goto END

:API_CHECK
echo.
echo ============================================
echo     API Keys Configuration Status
echo ============================================
echo.
echo [Environment Variables]
echo ----------------------------------------

:: Check API keys from environment
if defined GOOGLE_API_KEY (
    echo  GOOGLE_API_KEY:    [OK] Set
) else (
    echo  GOOGLE_API_KEY:    [--] Not Set
)

if defined GEMINI_API_KEY (
    echo  GEMINI_API_KEY:    [OK] Set
) else (
    echo  GEMINI_API_KEY:    [--] Not Set
)

if defined OPENAI_API_KEY (
    echo  OPENAI_API_KEY:    [OK] Set
) else (
    echo  OPENAI_API_KEY:    [--] Not Set
)

if defined ANTHROPIC_API_KEY (
    echo  ANTHROPIC_API_KEY: [OK] Set
) else (
    echo  ANTHROPIC_API_KEY: [--] Not Set
)

if defined QDRANT_API_KEY (
    echo  QDRANT_API_KEY:    [OK] Set
) else (
    echo  QDRANT_API_KEY:    [--] Not Set (localhost no auth)
)

if defined JOBKOREA_API_KEY (
    echo  JOBKOREA_API_KEY:  [OK] Set
) else (
    echo  JOBKOREA_API_KEY:  [--] Not Set
)

if defined KEIS_API_KEY (
    echo  KEIS_API_KEY:      [OK] Set
) else (
    echo  KEIS_API_KEY:      [--] Not Set
)

if defined YOUTUBE_API_KEY (
    echo  YOUTUBE_API_KEY:   [OK] Set
) else (
    echo  YOUTUBE_API_KEY:   [--] Not Set
)

echo ----------------------------------------
echo.
echo [Config Files]
if exist "D:\Real_one_stop_service\config\api-keys.yaml" (
    echo  api-keys.yaml:  [OK] Found
) else (
    echo  api-keys.yaml:  [--] Not Found
)

if exist "D:\Real_one_stop_service\config\qdrant.yaml" (
    echo  qdrant.yaml:    [OK] Found
) else (
    echo  qdrant.yaml:    [--] Not Found
)

echo.
goto END

:HEALTH_CHECK
echo.
echo ============================================
echo     Service Health Check
echo ============================================
echo.

:: Check Google Cloud / Gemini API
echo [CLOUD] Google Gemini API
curl -s -o nul -w "" "https://generativelanguage.googleapis.com/v1beta/models" >nul 2>&1
if !errorlevel! equ 0 (
    echo   Endpoint: REACHABLE
) else (
    echo   Endpoint: UNREACHABLE
)
if defined GOOGLE_API_KEY (
    echo   API Key: CONFIGURED
) else (
    echo   API Key: NOT SET
)
echo.

:: Check YouTube Data API
echo [CLOUD] YouTube Data API
curl -s -o nul "https://www.googleapis.com/youtube/v3/videos" 2>nul
if !errorlevel! equ 0 (
    echo   Endpoint: REACHABLE
) else (
    echo   Endpoint: UNREACHABLE
)
if defined YOUTUBE_API_KEY (
    echo   API Key: CONFIGURED
) else (
    echo   API Key: NOT SET
)
echo.

:: Check Qdrant REST API
echo [6333] Qdrant VectorDB
call :GET_PID 6333 PID
if "!PID!"=="-" (
    echo   Status: STOPPED
) else (
    curl -s http://localhost:6333/readyz >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Status: HEALTHY
        for /f "delims=" %%C in ('curl -s http://localhost:6333/collections 2^>nul ^| findstr /C:"\"name\""') do (
            echo   %%C
        )
    ) else (
        echo   Status: RUNNING but not responding
    )
)
echo.

:: Check Spring Boot
echo [8081] Spring Boot API
call :GET_PID 8081 PID
if "!PID!"=="-" (
    echo   Status: STOPPED
) else (
    curl -s http://localhost:8081/actuator/health >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Status: HEALTHY
    ) else (
        curl -s http://localhost:8081/ >nul 2>&1
        if !errorlevel! equ 0 (
            echo   Status: RUNNING
        ) else (
            echo   Status: RUNNING but not responding
        )
    )
)
echo.

:: Check Resin WAS
echo [8080] Resin WAS (Legacy LMS)
call :GET_PID 8080 PID
if "!PID!"=="-" (
    echo   Status: STOPPED
) else (
    curl -s http://localhost:8080/ >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Status: HEALTHY
    ) else (
        echo   Status: RUNNING but not responding
    )
)
echo.

:: Check Python Server
echo [8088] Python Server
call :GET_PID 8088 PID
if "!PID!"=="-" (
    echo   Status: STOPPED
) else (
    curl -s http://localhost:8088/ >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Status: HEALTHY
    ) else (
        echo   Status: RUNNING but not responding
    )
)
echo.
goto END

:HELP
echo.
echo ============================================
echo     GrowAI LMS Service Manager v2.0
echo ============================================
echo.
echo Usage: svc.bat [command]
echo.
echo Commands:
echo   status   - Show service status (default)
echo   start    - Start all services
echo   stop     - Stop all services
echo   restart  - Restart all services
echo   api      - Check API keys configuration
echo   health   - Service health check (HTTP)
echo   help     - Show this help
echo.
echo Services:
echo   6333 - Qdrant VectorDB (REST API)
echo   8080 - Resin WAS (Legacy JSP)
echo   8081 - Spring Boot API
echo   8088 - Python Server
echo.
echo Config Files:
echo   D:\Real_one_stop_service\config\api-keys.yaml
echo   D:\Real_one_stop_service\config\qdrant.yaml
echo.
goto END

:GET_PID
set "PORT=%~1"
set "VAR=%~2"
set "!VAR!=-"
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
    set "!VAR!=%%A"
)
goto :eof

:END
endlocal
