@echo off
REM ============================================
REM GrowAI LMS 온프레미스 AI 서비스 중지 스크립트
REM ============================================

echo [AI] 온프레미스 AI 서비스 중지...

docker-compose -f docker-compose.ai.yml down

echo [AI] 모든 AI 서비스가 중지되었습니다.
pause
