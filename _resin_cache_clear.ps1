Write-Host "=== Resin Cache Clear & Restart ==="
Write-Host ""

$resinHome = "D:\resin_server\resin-4.0.66"

# 1. Stop Resin
Write-Host "[1/4] Stopping Resin..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d $resinHome && bin\stop.bat" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
Start-Sleep 3

$listening = netstat -ano 2>$null | Select-String ":8080\s.*LISTENING"
if ($listening) {
    $parts = ($listening -split '\s+')
    $pidVal = $parts[-1]
    taskkill /F /PID $pidVal 2>$null | Out-Null
    Start-Sleep 2
}
Write-Host "      [OK] Stopped"

# 2. Clear cache directories
Write-Host "[2/4] Clearing cache..."
$cacheDirs = @("resin-data", "watchdog-data", "tmp", "work")
foreach ($dir in $cacheDirs) {
    $dirPath = Join-Path $resinHome $dir
    if (Test-Path $dirPath) {
        Remove-Item $dirPath -Recurse -Force -ErrorAction SilentlyContinue
        New-Item $dirPath -ItemType Directory -Force | Out-Null
        Write-Host "      Cleared: $dir"
    }
}

# 3. Clear logs
Write-Host "[3/4] Clearing logs..."
$logPath = Join-Path $resinHome "log"
if (Test-Path $logPath) {
    Get-ChildItem $logPath -Filter "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "      [OK] Logs cleared"
}

# 4. Restart Resin
Write-Host "[4/4] Starting Resin..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d $resinHome && bin\start.bat" -WindowStyle Hidden
Start-Sleep 10

$listening2 = netstat -ano 2>$null | Select-String ":8080\s.*LISTENING"
if ($listening2) {
    Write-Host "      [OK] Resin running on port 8080"
} else {
    Write-Host "      [WAIT] Starting up... check again in a few seconds"
}

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Refresh browser: Ctrl+Shift+R"
Write-Host "URL: http://localhost:8080/mypage/new_main/"
