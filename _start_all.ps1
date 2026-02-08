chcp 65001 | Out-Null
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================="
Write-Host "  GrowAI LMS - Service Startup"
Write-Host "=========================================="
Write-Host ""

# 1. MySQL
Write-Host "[1/4] MySQL..."
$mysql = Get-Process mysqld -ErrorAction SilentlyContinue
if ($mysql) {
    Write-Host "      [OK] Already running (PID: $($mysql.Id))"
} else {
    $mysqldPath = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe"
    if (Test-Path $mysqldPath) {
        Start-Process -FilePath $mysqldPath -ArgumentList '--datadir=D:\mysql_data' -WindowStyle Hidden
        Start-Sleep -Seconds 5
        $mysql = Get-Process mysqld -ErrorAction SilentlyContinue
        if ($mysql) {
            Write-Host "      [OK] Started (PID: $($mysql.Id))"
        } else {
            Write-Host "      [FAIL] Could not start"
        }
    } else {
        # Try as Windows service
        $svc = Get-Service *mysql* -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "      Found service: $($svc.Name) - Status: $($svc.Status)"
            if ($svc.Status -ne 'Running') {
                Start-Service $svc.Name -ErrorAction SilentlyContinue
                Write-Host "      [OK] Service started"
            }
        } else {
            Write-Host "      [SKIP] MySQL not found at expected path"
        }
    }
}

# 2. Qdrant
Write-Host "[2/4] Qdrant..."
$qdrant = Get-Process qdrant -ErrorAction SilentlyContinue
if ($qdrant) {
    Write-Host "      [OK] Already running (PID: $($qdrant.Id))"
} else {
    $qdrantPath = "D:\qdrant\qdrant.exe"
    if (Test-Path $qdrantPath) {
        Start-Process -FilePath $qdrantPath -WindowStyle Hidden
        Start-Sleep -Seconds 3
        $qdrant = Get-Process qdrant -ErrorAction SilentlyContinue
        if ($qdrant) {
            Write-Host "      [OK] Started (PID: $($qdrant.Id))"
        } else {
            Write-Host "      [FAIL] Could not start"
        }
    } else {
        Write-Host "      [SKIP] Qdrant not found at $qdrantPath"
    }
}

# 3. Resin
Write-Host "[3/4] Resin WAS..."
$resinListening = netstat -ano 2>$null | Select-String ":8080\s.*LISTENING"
if ($resinListening) {
    $pid = ($resinListening -split '\s+')[-1]
    Write-Host "      [OK] Already running on port 8080 (PID: $pid)"
} else {
    $resinStart = "D:\resin_server\resin-4.0.66\bin\start.bat"
    if (Test-Path $resinStart) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"cd /d D:\resin_server\resin-4.0.66 && bin\start.bat`"" -WindowStyle Hidden
        Start-Sleep -Seconds 5
        $resinListening = netstat -ano 2>$null | Select-String ":8080\s.*LISTENING"
        if ($resinListening) {
            Write-Host "      [OK] Started on port 8080"
        } else {
            Write-Host "      [WAIT] Start command sent, may need more time..."
        }
    } else {
        Write-Host "      [SKIP] Resin not found at $resinStart"
    }
}

# 4. Spring Boot API
Write-Host "[4/4] Spring Boot API..."
$apiListening = netstat -ano 2>$null | Select-String ":8081\s.*LISTENING"
if ($apiListening) {
    $pid = ($apiListening -split '\s+')[-1]
    Write-Host "      [OK] Already running on port 8081 (PID: $pid)"
} else {
    $jarPath = "D:\Real_one_stop_service\polytech-lms-api\build\libs\polytech-lms-api-0.0.1-SNAPSHOT.jar"
    if (Test-Path $jarPath) {
        $env:GOOGLE_API_KEY = "AIzaSyAaeMOy5n-G59uDCfUt1xflKe3X_gMuxW8"
        $env:GEMINI_API_KEY = $env:GOOGLE_API_KEY
        $javaArgs = @(
            "-Dspring.datasource.url=jdbc:mysql://localhost:3306/lms?useSSL=false&allowPublicKeyRetrieval=true",
            "-Dspring.datasource.username=lms",
            "-Dspring.datasource.password=lms123",
            "-Dspring.ai.google.genai.embedding.api-key=$($env:GOOGLE_API_KEY)",
            "-Dgemini.api-key=$($env:GEMINI_API_KEY)",
            "-jar", $jarPath
        )
        Start-Process -FilePath "java" -ArgumentList $javaArgs -WindowStyle Hidden
        Start-Sleep -Seconds 3
        Write-Host "      [OK] Start command sent (Port 8081)"
    } else {
        Write-Host "      [SKIP] JAR not found at $jarPath"
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "  Service Status Summary"
Write-Host "=========================================="

Start-Sleep -Seconds 2

# Final port check
foreach ($port in @(3306, 6333, 8080, 8081)) {
    $listening = netstat -ano 2>$null | Select-String ":$port\s.*LISTENING"
    if ($listening) {
        $pid = ($listening -split '\s+')[-1]
        switch ($port) {
            3306 { $name = "MySQL" }
            6333 { $name = "Qdrant" }
            8080 { $name = "Resin WAS" }
            8081 { $name = "Spring Boot" }
        }
        Write-Host "  [OK] $name (Port $port) - PID: $pid"
    } else {
        switch ($port) {
            3306 { $name = "MySQL" }
            6333 { $name = "Qdrant" }
            8080 { $name = "Resin WAS" }
            8081 { $name = "Spring Boot" }
        }
        Write-Host "  [--] $name (Port $port) - Not listening"
    }
}

Write-Host ""
Write-Host "  Legacy JSP:   http://localhost:8080"
Write-Host "  Tutor LMS:    http://localhost:8080/tutor_lms/app/"
Write-Host "  Student LMS:  http://localhost:8080/mypage/new_main/"
Write-Host "  Backend API:  http://localhost:8081"
Write-Host "  Qdrant:       http://localhost:6333"
Write-Host "=========================================="
