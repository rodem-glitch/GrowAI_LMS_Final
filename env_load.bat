@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================
:: GrowAI LMS Environment Loader
:: Usage: env_load.bat [load|set|show]
:: ============================================

set "CMD=%~1"
if "%CMD%"=="" set "CMD=load"

set "ENV_FILE=D:\Real_one_stop_service\.env"

if /i "%CMD%"=="load" goto LOAD
if /i "%CMD%"=="set" goto SET_PERMANENT
if /i "%CMD%"=="show" goto SHOW
if /i "%CMD%"=="help" goto HELP
goto HELP

:LOAD
echo.
echo ============================================
echo     Loading Environment Variables
echo ============================================
echo.

if not exist "%ENV_FILE%" (
    echo [ERROR] .env file not found: %ENV_FILE%
    echo.
    echo Please create .env file first:
    echo   copy .env.example .env
    echo.
    goto END
)

set "COUNT=0"
for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
    set "LINE=%%A"
    if not "!LINE:~0,1!"=="#" (
        if not "%%B"=="" (
            set "%%A=%%B"
            set /a COUNT+=1
        )
    )
)

echo [OK] Loaded !COUNT! environment variables
echo.
echo Variables loaded:
echo ----------------------------------------
if defined GOOGLE_API_KEY echo  GOOGLE_API_KEY: Set
if defined GEMINI_API_KEY echo  GEMINI_API_KEY: Set
if defined GEMINI_MODEL echo  GEMINI_MODEL: %GEMINI_MODEL%
if defined QDRANT_HOST echo  QDRANT_HOST: %QDRANT_HOST%
if defined QDRANT_PORT echo  QDRANT_PORT: %QDRANT_PORT%
echo ----------------------------------------
echo.
echo NOTE: These variables are only set for this session.
echo       Use 'env_load set' to make them permanent.
echo.
goto END

:SET_PERMANENT
echo.
echo ============================================
echo     Setting Permanent Environment Variables
echo ============================================
echo.

if not exist "%ENV_FILE%" (
    echo [ERROR] .env file not found
    goto END
)

echo [WARNING] This will set environment variables permanently.
set /p CONFIRM="Continue? (y/n): "
if /i not "%CONFIRM%"=="y" goto END

for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
    set "LINE=%%A"
    if not "!LINE:~0,1!"=="#" (
        if not "%%B"=="" (
            echo Setting %%A...
            setx %%A "%%B" >nul 2>&1
        )
    )
)

echo.
echo [OK] Environment variables set permanently.
echo      Please restart your terminal to apply changes.
echo.
goto END

:SHOW
echo.
echo ============================================
echo     Current Environment Variables
echo ============================================
echo.
echo [Google Cloud / Gemini]
if defined GOOGLE_API_KEY (echo  GOOGLE_API_KEY: [SET]) else (echo  GOOGLE_API_KEY: [NOT SET])
if defined GEMINI_API_KEY (echo  GEMINI_API_KEY: [SET]) else (echo  GEMINI_API_KEY: [NOT SET])
if defined GEMINI_MODEL (echo  GEMINI_MODEL: %GEMINI_MODEL%) else (echo  GEMINI_MODEL: [NOT SET])
echo.
echo [Qdrant]
if defined QDRANT_HOST (echo  QDRANT_HOST: %QDRANT_HOST%) else (echo  QDRANT_HOST: [NOT SET])
if defined QDRANT_PORT (echo  QDRANT_PORT: %QDRANT_PORT%) else (echo  QDRANT_PORT: [NOT SET])
echo.
echo [External APIs]
if defined JOBKOREA_API_KEY (echo  JOBKOREA_API_KEY: [SET]) else (echo  JOBKOREA_API_KEY: [NOT SET])
if defined KEIS_API_KEY (echo  KEIS_API_KEY: [SET]) else (echo  KEIS_API_KEY: [NOT SET])
echo.
goto END

:HELP
echo.
echo ============================================
echo     GrowAI LMS Environment Loader
echo ============================================
echo.
echo Usage: env_load.bat [command]
echo.
echo Commands:
echo   load  - Load .env to current session (default)
echo   set   - Set environment variables permanently
echo   show  - Show current environment variables
echo   help  - Show this help
echo.
echo Files:
echo   .env         - Environment variables (edit this)
echo   .env.example - Template file
echo.
goto END

:END
endlocal
