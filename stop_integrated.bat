@echo off
chcp 65001 >nul
title GrowAI-LMS Service Stopper
color 0C

echo ╔══════════════════════════════════════════════════════════════╗
echo ║         GrowAI-LMS 통합 서비스 종료                           ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo [1/4] Backend API 종료...
taskkill /F /IM java.exe /FI "WINDOWTITLE eq polytech*" 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8081 ^| findstr LISTENING') do taskkill /F /PID %%a 2>nul
echo      [OK]

echo [2/4] Resin 종료...
cd /d D:\resin_server\resin-4.0.66
call bin\stop.bat >nul 2>&1
echo      [OK]

echo [3/4] Qdrant 종료...
taskkill /F /IM qdrant.exe 2>nul
echo      [OK]

echo [4/4] MySQL 종료...
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqladmin.exe" -u root shutdown 2>nul
if "%ERRORLEVEL%" NEQ "0" taskkill /F /IM mysqld.exe 2>nul
echo      [OK]

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║              모든 서비스가 종료되었습니다                      ║
echo ╚══════════════════════════════════════════════════════════════╝
pause
