Write-Host "=== Qdrant Diagnostic ==="
Write-Host ""

# Process check
$proc = Get-Process qdrant -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[OK] Qdrant process running - PID: $($proc.Id)"
} else {
    Write-Host "[--] Qdrant process NOT running"
}

# Port check
$listening = netstat -ano 2>$null | Select-String ":6333\s.*LISTENING"
if ($listening) {
    Write-Host "[OK] Port 6333 listening"
} else {
    Write-Host "[--] Port 6333 NOT listening"
}

$listening2 = netstat -ano 2>$null | Select-String ":6334\s.*LISTENING"
if ($listening2) {
    Write-Host "[OK] Port 6334 listening (gRPC)"
} else {
    Write-Host "[--] Port 6334 NOT listening"
}

Write-Host ""

# HTTP checks
$urls = @(
    "http://localhost:6333",
    "http://localhost:6333/readyz",
    "http://localhost:6333/collections",
    "http://localhost:6333/dashboard"
)

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        Write-Host "[OK] $url -> $($response.StatusCode)"
    } catch [System.Net.WebException] {
        $status = $_.Exception.Response
        if ($status) {
            $code = [int]$status.StatusCode
            Write-Host "[--] $url -> HTTP $code"
        } else {
            Write-Host "[--] $url -> Connection refused"
        }
    } catch {
        Write-Host "[--] $url -> Error: $($_.Exception.GetType().Name)"
    }
}

Write-Host ""

# Qdrant version
Write-Host "=== Qdrant version ==="
$qdrantPath = "D:\qdrant\qdrant.exe"
if (Test-Path $qdrantPath) {
    Write-Host "Qdrant location: $qdrantPath"
    $verOutput = & $qdrantPath --version 2>&1
    Write-Host $verOutput
} else {
    $qdrantWhere = where.exe qdrant 2>$null
    if ($qdrantWhere) {
        Write-Host "Qdrant location: $qdrantWhere"
    } else {
        Write-Host "Qdrant not found in expected locations"
    }
}

# Check if static UI is enabled
Write-Host ""
Write-Host "=== Config check ==="
$configPath = "D:\qdrant\config\config.yaml"
if (Test-Path $configPath) {
    Write-Host "Config found: $configPath"
    Get-Content $configPath | Select-String -Pattern "static|dashboard|ui|enable"
} else {
    Write-Host "No config.yaml found - using defaults"
    Write-Host "Dashboard requires Qdrant 1.3+ with --enable-static-content flag or config"
}
