@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================
:: GrowAI LMS 서비스 관리 스크립트
:: 작성일: 2026-02-07
:: ============================================

set "TITLE=GrowAI LMS Service Manager"
title %TITLE%

:: 색상 정의
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "RESET=[0m"

:: 서비스 정보
set "RESIN_PORT=8080"
set "SPRING_PORT=8081"
set "PYTHON_PORT=8088"

:MENU
cls
echo.
echo %CYAN%============================================%RESET%
echo %CYAN%    GrowAI LMS 서비스 관리자%RESET%
echo %CYAN%============================================%RESET%
echo.
echo    [1] 서비스 상태 확인
echo    [2] 모든 서비스 시작
echo    [3] 모든 서비스 종료
echo    [4] 개별 서비스 관리
echo    [5] 포트 사용 현황
echo    [0] 종료
echo.
echo %CYAN%============================================%RESET%
echo.
set /p choice="선택하세요 (0-5): "

if "%choice%"=="1" goto STATUS
if "%choice%"=="2" goto START_ALL
if "%choice%"=="3" goto STOP_ALL
if "%choice%"=="4" goto INDIVIDUAL
if "%choice%"=="5" goto PORT_STATUS
if "%choice%"=="0" goto EXIT
goto MENU

:STATUS
cls
echo.
echo %CYAN%[ 서비스 상태 확인 ]%RESET%
echo.
echo ----------------------------------------
echo  포트    서비스          상태
echo ----------------------------------------

:: Resin WAS (8080)
call :CHECK_PORT %RESIN_PORT% RESIN_STATUS RESIN_PID
if "!RESIN_STATUS!"=="RUNNING" (
    echo  %RESIN_PORT%    Resin WAS       %GREEN%실행중%RESET% [PID: !RESIN_PID!]
) else (
    echo  %RESIN_PORT%    Resin WAS       %RED%중지됨%RESET%
)

:: Spring Boot (8081)
call :CHECK_PORT %SPRING_PORT% SPRING_STATUS SPRING_PID
if "!SPRING_STATUS!"=="RUNNING" (
    echo  %SPRING_PORT%    Spring Boot     %GREEN%실행중%RESET% [PID: !SPRING_PID!]
) else (
    echo  %SPRING_PORT%    Spring Boot     %RED%중지됨%RESET%
)

:: Python (8088)
call :CHECK_PORT %PYTHON_PORT% PYTHON_STATUS PYTHON_PID
if "!PYTHON_STATUS!"=="RUNNING" (
    echo  %PYTHON_PORT%    Python Server   %GREEN%실행중%RESET% [PID: !PYTHON_PID!]
) else (
    echo  %PYTHON_PORT%    Python Server   %RED%중지됨%RESET%
)

echo ----------------------------------------
echo.
pause
goto MENU

:CHECK_PORT
set "PORT=%1"
set "STATUS_VAR=%2"
set "PID_VAR=%3"
set "!STATUS_VAR!=STOPPED"
set "!PID_VAR!=N/A"

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%PORT%" ^| findstr "LISTENING" 2^>nul') do (
    set "!STATUS_VAR!=RUNNING"
    set "!PID_VAR!=%%a"
)
goto :eof

:START_ALL
cls
echo.
echo %CYAN%[ 모든 서비스 시작 ]%RESET%
echo.

:: Resin WAS 시작
call :CHECK_PORT %RESIN_PORT% STATUS PID
if "!STATUS!"=="STOPPED" (
    echo %YELLOW%Resin WAS 시작 중...%RESET%
    if exist "D:\Real_one_stop_service\start_integrated.bat" (
        start "" /B cmd /c "D:\Real_one_stop_service\start_integrated.bat"
        timeout /t 3 /nobreak >nul
        echo %GREEN%Resin WAS 시작 명령 전송됨%RESET%
    ) else (
        echo %RED%start_integrated.bat 파일을 찾을 수 없습니다%RESET%
    )
) else (
    echo %GREEN%Resin WAS 이미 실행 중 [PID: !PID!]%RESET%
)

:: Spring Boot 시작
call :CHECK_PORT %SPRING_PORT% STATUS PID
if "!STATUS!"=="STOPPED" (
    echo %YELLOW%Spring Boot 시작 중...%RESET%
    if exist "D:\Real_one_stop_service\polytech-lms-api" (
        start "" /B cmd /c "cd /d D:\Real_one_stop_service\polytech-lms-api && mvnw.cmd spring-boot:run"
        timeout /t 5 /nobreak >nul
        echo %GREEN%Spring Boot 시작 명령 전송됨%RESET%
    ) else (
        echo %RED%polytech-lms-api 폴더를 찾을 수 없습니다%RESET%
    )
) else (
    echo %GREEN%Spring Boot 이미 실행 중 [PID: !PID!]%RESET%
)

echo.
echo %GREEN%서비스 시작 완료%RESET%
echo.
pause
goto MENU

:STOP_ALL
cls
echo.
echo %CYAN%[ 모든 서비스 종료 ]%RESET%
echo.

:: Resin WAS 종료
call :CHECK_PORT %RESIN_PORT% STATUS PID
if "!STATUS!"=="RUNNING" (
    echo %YELLOW%Resin WAS 종료 중... [PID: !PID!]%RESET%
    taskkill /F /PID !PID! >nul 2>&1
    echo %GREEN%Resin WAS 종료됨%RESET%
) else (
    echo %YELLOW%Resin WAS 이미 중지됨%RESET%
)

:: Spring Boot 종료
call :CHECK_PORT %SPRING_PORT% STATUS PID
if "!STATUS!"=="RUNNING" (
    echo %YELLOW%Spring Boot 종료 중... [PID: !PID!]%RESET%
    taskkill /F /PID !PID! >nul 2>&1
    echo %GREEN%Spring Boot 종료됨%RESET%
) else (
    echo %YELLOW%Spring Boot 이미 중지됨%RESET%
)

:: Python 종료
call :CHECK_PORT %PYTHON_PORT% STATUS PID
if "!STATUS!"=="RUNNING" (
    echo %YELLOW%Python Server 종료 중... [PID: !PID!]%RESET%
    taskkill /F /PID !PID! >nul 2>&1
    echo %GREEN%Python Server 종료됨%RESET%
) else (
    echo %YELLOW%Python Server 이미 중지됨%RESET%
)

echo.
echo %GREEN%모든 서비스 종료 완료%RESET%
echo.
pause
goto MENU

:INDIVIDUAL
cls
echo.
echo %CYAN%[ 개별 서비스 관리 ]%RESET%
echo.
echo    [1] Resin WAS (8080)
echo    [2] Spring Boot (8081)
echo    [3] Python Server (8088)
echo    [0] 메인 메뉴
echo.
set /p svc_choice="선택하세요: "

if "%svc_choice%"=="1" (
    set "SVC_NAME=Resin WAS"
    set "SVC_PORT=%RESIN_PORT%"
)
if "%svc_choice%"=="2" (
    set "SVC_NAME=Spring Boot"
    set "SVC_PORT=%SPRING_PORT%"
)
if "%svc_choice%"=="3" (
    set "SVC_NAME=Python Server"
    set "SVC_PORT=%PYTHON_PORT%"
)
if "%svc_choice%"=="0" goto MENU

call :CHECK_PORT !SVC_PORT! STATUS PID
echo.
echo %CYAN%[ !SVC_NAME! - 포트 !SVC_PORT! ]%RESET%
if "!STATUS!"=="RUNNING" (
    echo 현재 상태: %GREEN%실행중%RESET% [PID: !PID!]
    echo.
    set /p action="종료하시겠습니까? (y/n): "
    if /i "!action!"=="y" (
        taskkill /F /PID !PID! >nul 2>&1
        echo %GREEN%!SVC_NAME! 종료됨%RESET%
    )
) else (
    echo 현재 상태: %RED%중지됨%RESET%
    echo.
    set /p action="시작하시겠습니까? (y/n): "
    if /i "!action!"=="y" (
        echo %YELLOW%시작 기능은 수동으로 실행해주세요%RESET%
    )
)
echo.
pause
goto INDIVIDUAL

:PORT_STATUS
cls
echo.
echo %CYAN%[ 포트 사용 현황 ]%RESET%
echo.
echo ----------------------------------------
echo  포트      PID       프로세스
echo ----------------------------------------

for %%p in (8080 8081 8088 3000 3001 5173) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p " ^| findstr "LISTENING" 2^>nul') do (
        for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /FO TABLE /NH 2^>nul') do (
            echo  %%p      %%a      %%b
        )
    )
)

echo ----------------------------------------
echo.
echo %YELLOW%[ 상세 네트워크 상태 ]%RESET%
echo.
netstat -ano | findstr "LISTENING" | findstr ":80"
echo.
pause
goto MENU

:EXIT
cls
echo.
echo %GREEN%GrowAI LMS Service Manager 종료%RESET%
echo.
endlocal
exit /b 0
