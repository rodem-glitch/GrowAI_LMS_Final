# GrowAI LMS Service Status Checker
# Encoding: UTF-8

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    GrowAI LMS 서비스 상태" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "----------------------------------------"
Write-Host " 포트    서비스           상태      PID"
Write-Host "----------------------------------------"

$ports = @(8080, 8081, 8088)
$names = @{8080="Resin WAS"; 8081="Spring Boot"; 8088="Python Server"}

foreach ($port in $ports) {
    $name = $names[$port].PadRight(15)
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue

    if ($conn) {
        $procId = $conn.OwningProcess
        $procName = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName
        Write-Host " $port    $name " -NoNewline
        Write-Host "실행중" -ForegroundColor Green -NoNewline
        Write-Host "    $procId ($procName)"
    } else {
        Write-Host " $port    $name " -NoNewline
        Write-Host "중지됨" -ForegroundColor Red
    }
}

Write-Host "----------------------------------------"
Write-Host ""
