# Stop existing Qdrant
Write-Host "Stopping Qdrant..."
Stop-Process -Name qdrant -Force -ErrorAction SilentlyContinue
Start-Sleep 2

# Set environment variable to enable static content (dashboard)
$env:QDRANT__SERVICE__ENABLE_STATIC_CONTENT = "true"

# Start Qdrant with static content enabled
Write-Host "Starting Qdrant with dashboard enabled..."
Start-Process -FilePath "D:\qdrant\qdrant.exe" -WorkingDirectory "D:\qdrant" -WindowStyle Hidden

Start-Sleep 5

# Verify
$proc = Get-Process qdrant -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[OK] Qdrant running - PID: $($proc.Id)"
} else {
    Write-Host "[--] Qdrant not running"
}

try {
    $r = Invoke-WebRequest -Uri "http://localhost:6333/dashboard" -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] Dashboard: HTTP $($r.StatusCode)"
} catch [System.Net.WebException] {
    $status = $_.Exception.Response
    if ($status) {
        $code = [int]$status.StatusCode
        Write-Host "[--] Dashboard: HTTP $code - not available in this build"
        Write-Host ""
        Write-Host "This Qdrant binary was compiled without static content."
        Write-Host "Use the official release or Qdrant Web UI separately."
    } else {
        Write-Host "[--] Dashboard: Connection refused"
    }
} catch {
    Write-Host "[--] Dashboard: Error"
}

# API still works
try {
    $r2 = Invoke-WebRequest -Uri "http://localhost:6333/collections" -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] API: HTTP $($r2.StatusCode) - $($r2.Content)"
} catch {
    Write-Host "[--] API: Not responding"
}
