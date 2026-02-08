@echo off
chcp 65001 >nul
title Resin Cache Clear & Restart
color 0A

echo ╔══════════════════════════════════════════════════════════════╗
echo ║         Resin Server Cache Clear ^& Restart                  ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set RESIN_HOME=D:\resin_server\resin-4.0.66

:: ========== 1. Stop Resin ==========
echo [1/5] Resin 서버 중지...
cd /d %RESIN_HOME%
call bin\stop.bat >nul 2>&1
timeout /t 3 /nobreak >nul

:: Force kill if still running
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    echo       Forcing stop PID: %%A
    taskkill /F /PID %%A >nul 2>&1
)
timeout /t 2 /nobreak >nul
echo       [OK] 중지 완료

:: ========== 2. Clear Resin Cache ==========
echo [2/5] Resin 캐시 삭제...

:: resin-data (main cache directory)
if exist "%RESIN_HOME%\resin-data" (
    rd /s /q "%RESIN_HOME%\resin-data" 2>nul
    mkdir "%RESIN_HOME%\resin-data" 2>nul
    echo       [OK] resin-data 삭제됨
)

:: watchdog-data
if exist "%RESIN_HOME%\watchdog-data" (
    rd /s /q "%RESIN_HOME%\watchdog-data" 2>nul
    mkdir "%RESIN_HOME%\watchdog-data" 2>nul
    echo       [OK] watchdog-data 삭제됨
)

:: tmp directory
if exist "%RESIN_HOME%\tmp" (
    rd /s /q "%RESIN_HOME%\tmp" 2>nul
    mkdir "%RESIN_HOME%\tmp" 2>nul
    echo       [OK] tmp 삭제됨
)

:: work directory (compiled JSP cache)
if exist "%RESIN_HOME%\work" (
    rd /s /q "%RESIN_HOME%\work" 2>nul
    mkdir "%RESIN_HOME%\work" 2>nul
    echo       [OK] work 삭제됨
)

:: webapp cache
if exist "%RESIN_HOME%\webapps\ROOT\WEB-INF\work" (
    rd /s /q "%RESIN_HOME%\webapps\ROOT\WEB-INF\work" 2>nul
    echo       [OK] webapps work 삭제됨
)

:: ========== 3. Clear Log Files ==========
echo [3/5] 로그 파일 정리...
if exist "%RESIN_HOME%\log" (
    del /q "%RESIN_HOME%\log\*.log" 2>nul
    echo       [OK] 로그 삭제됨
)

:: ========== 4. Clear Browser Cache Headers ==========
echo [4/5] 정적 파일 캐시 갱신...
:: Touch CSS files to update timestamp (forces browser cache invalidation)
copy /b "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\unified-theme.css"+,, "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\unified-theme.css" >nul 2>&1
copy /b "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\phase2-components.css"+,, "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\phase2-components.css" >nul 2>&1
copy /b "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\dark-override.css"+,, "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\dark-override.css" >nul 2>&1
copy /b "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\phase3-pages.css"+,, "%RESIN_HOME%\..\Real_one_stop_service\public_html\common\css\phase3-pages.css" >nul 2>&1
copy /b "%RESIN_HOME%\..\Real_one_stop_service\public_html\html\css\custom.css"+,, "%RESIN_HOME%\..\Real_one_stop_service\public_html\html\css\custom.css" >nul 2>&1
echo       [OK] CSS 타임스탬프 갱신

:: ========== 5. Restart Resin ==========
echo [5/5] Resin 서버 재시작...
cd /d %RESIN_HOME%
call bin\start.bat >nul 2>&1
timeout /t 8 /nobreak >nul

:: Verify
for /f "tokens=5" %%A in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    echo       [OK] Resin 시작됨 - Port 8080 ^(PID: %%A^)
    goto DONE
)
echo       [WAIT] 시작 중... 잠시 후 확인하세요

:DONE
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║  캐시 초기화 완료                                             ║
echo ║                                                              ║
echo ║  브라우저에서 Ctrl+Shift+R (강력 새로고침) 하세요              ║
echo ║  http://localhost:8080/mypage/new_main/                      ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
pause
