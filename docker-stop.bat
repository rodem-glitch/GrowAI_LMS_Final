@echo off
REM ============================================
REM GrowAI LMS Docker Compose 중지 스크립트
REM ============================================

echo [LMS] Docker Compose 중지...

docker-compose down

echo [LMS] 모든 서비스가 중지되었습니다.
pause
