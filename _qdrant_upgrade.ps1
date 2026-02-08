# Download official Qdrant 1.13.2 (latest with dashboard included)
$version = "v1.13.2"
$url = "https://github.com/qdrant/qdrant/releases/download/$version/qdrant-x86_64-pc-windows-msvc.zip"
$zipPath = "D:\qdrant\qdrant-new.zip"
$extractPath = "D:\qdrant\temp_extract"

Write-Host "=== Qdrant Upgrade to $version ==="
Write-Host ""

# Stop current Qdrant
Write-Host "[1/4] Stopping current Qdrant..."
Stop-Process -Name qdrant -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Write-Host "      Done"

# Download
Write-Host "[2/4] Downloading Qdrant $version..."
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Write-Host "      Downloaded: $zipPath"
} catch {
    Write-Host "      FAILED: $($_.Exception.Message)"
    exit 1
}

# Backup old and extract new
Write-Host "[3/4] Replacing binary..."
if (Test-Path "D:\qdrant\qdrant.exe") {
    Copy-Item "D:\qdrant\qdrant.exe" "D:\qdrant\qdrant_old.exe" -Force
    Write-Host "      Backed up old binary"
}

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$newExe = Get-ChildItem $extractPath -Recurse -Filter "qdrant.exe" | Select-Object -First 1
if ($newExe) {
    Copy-Item $newExe.FullName "D:\qdrant\qdrant.exe" -Force
    Write-Host "      Replaced with new binary"
} else {
    Write-Host "      ERROR: qdrant.exe not found in archive"
    exit 1
}

# Cleanup
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# Start new Qdrant
Write-Host "[4/4] Starting Qdrant $version..."
Start-Process -FilePath "D:\qdrant\qdrant.exe" -WorkingDirectory "D:\qdrant" -WindowStyle Hidden
Start-Sleep 5

# Verify
$proc = Get-Process qdrant -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "      [OK] Running - PID: $($proc.Id)"
} else {
    Write-Host "      [--] Not running"
}

$verOutput = & "D:\qdrant\qdrant.exe" --version 2>&1
Write-Host "      Version: $verOutput"

try {
    $r = Invoke-WebRequest -Uri "http://localhost:6333/dashboard" -UseBasicParsing -TimeoutSec 5
    Write-Host "      [OK] Dashboard: HTTP $($r.StatusCode)"
} catch {
    Write-Host "      [--] Dashboard: Still not available"
}

try {
    $r2 = Invoke-WebRequest -Uri "http://localhost:6333/collections" -UseBasicParsing -TimeoutSec 5
    Write-Host "      [OK] API: HTTP $($r2.StatusCode)"
} catch {
    Write-Host "      [--] API: Not responding"
}

Write-Host ""
Write-Host "=== Complete ==="
Write-Host "Dashboard: http://localhost:6333/dashboard"
