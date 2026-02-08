@echo off
:: Resin 설정 업데이트 스크립트
:: Real_one_stop_service 폴더용

echo Resin 설정을 Real_one_stop_service로 변경합니다...

:: resin.xml 백업
copy /Y "D:\resin_server\resin-4.0.66\conf\resin.xml" "D:\resin_server\resin-4.0.66\conf\resin.xml.bak" >nul

:: sed 대신 PowerShell로 경로 변경
powershell -Command "(Get-Content 'D:\resin_server\resin-4.0.66\conf\resin.xml') -replace 'D:/Real/public_html', 'D:/Real_one_stop_service/public_html' | Set-Content 'D:\resin_server\resin-4.0.66\conf\resin.xml'"

echo [OK] Resin 설정이 업데이트되었습니다.
echo     root-directory: D:/Real_one_stop_service/public_html
pause
