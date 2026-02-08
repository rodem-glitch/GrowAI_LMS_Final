Start-Sleep 15

Write-Host "=========================================="
Write-Host "  GrowAI LMS - Final Service Status"
Write-Host "=========================================="
Write-Host ""

Write-Host "--- Port Check ---"
foreach ($port in @(3306, 6333, 8080, 8081)) {
    $listening = netstat -ano 2>$null | Select-String ":$port\s.*LISTENING"
    if ($listening) {
        $parts = ($listening -split '\s+')
        $portPid = $parts[-1]
        switch ($port) {
            3306 { $name = "MySQL       " }
            6333 { $name = "Qdrant      " }
            8080 { $name = "Resin WAS   " }
            8081 { $name = "Spring Boot " }
        }
        Write-Host "  [OK] $name (Port $port) - PID: $portPid"
    } else {
        switch ($port) {
            3306 { $name = "MySQL       " }
            6333 { $name = "Qdrant      " }
            8080 { $name = "Resin WAS   " }
            8081 { $name = "Spring Boot " }
        }
        Write-Host "  [--] $name (Port $port) - Not listening"
    }
}

Write-Host ""
Write-Host "--- HTTP Health Check ---"

# Qdrant
try {
    $r = Invoke-WebRequest -Uri "http://localhost:6333/readyz" -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] Qdrant        - Status: $($r.StatusCode)"
} catch {
    Write-Host "  [--] Qdrant        - Not responding"
}

# Resin
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] Resin WAS     - Status: $($r.StatusCode)"
} catch {
    Write-Host "  [--] Resin WAS     - Not responding"
}

# Spring Boot
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] Spring Boot   - Status: $($r.StatusCode) $($r.Content)"
} catch {
    try {
        $r2 = Invoke-WebRequest -Uri "http://localhost:8081/" -UseBasicParsing -TimeoutSec 5
        Write-Host "  [OK] Spring Boot   - Status: $($r2.StatusCode) (actuator N/A)"
    } catch {
        Write-Host "  [--] Spring Boot   - Not responding (may still be starting)"
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "  Access URLs:"
Write-Host "  Legacy JSP:   http://localhost:8080"
Write-Host "  Tutor LMS:    http://localhost:8080/tutor_lms/app/"
Write-Host "  Student LMS:  http://localhost:8080/mypage/new_main/"
Write-Host "  Backend API:  http://localhost:8081"
Write-Host "  Qdrant:       http://localhost:6333/dashboard"
Write-Host "=========================================="
