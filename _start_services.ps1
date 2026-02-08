# One-Stop Service 통합 시작 스크립트
# RFP 8개 항목 + GCP 서비스 (Vertex AI, BigQuery, TTS, STT)

param(
    [switch]$SkipBuild,
    [switch]$SkipDocker,
    [int]$ApiPort = 8081
)

$ErrorActionPreference = "Continue"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host @"
======================================================
   One-Stop Service 통합 시작
   RFP 8개 항목 + GCP AI 서비스
======================================================
"@ -ForegroundColor Cyan

# 1. 환경 확인
Write-Host "`n[1/5] 환경 확인..." -ForegroundColor Yellow

$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host "  Java: $javaVersion" -ForegroundColor Gray

$gradleExists = Test-Path "$scriptRoot\polytech-lms-api\gradlew.bat"
Write-Host "  Gradle Wrapper: $(if($gradleExists){'OK'}else{'Missing'})" -ForegroundColor $(if($gradleExists){'Green'}else{'Red'})

# 2. Docker 서비스 확인/시작
if (-not $SkipDocker) {
    Write-Host "`n[2/5] Docker 서비스 시작..." -ForegroundColor Yellow

    # Qdrant (벡터 DB)
    $qdrantRunning = docker ps --filter "name=qdrant" --format "{{.Names}}" 2>$null
    if (-not $qdrantRunning) {
        Write-Host "  Qdrant 시작 중..." -ForegroundColor Gray
        docker run -d --name qdrant -p 6333:6333 -p 6334:6334 `
            -v qdrant_storage:/qdrant/storage qdrant/qdrant 2>$null

        if ($LASTEXITCODE -ne 0) {
            docker start qdrant 2>$null
        }
    } else {
        Write-Host "  Qdrant 이미 실행 중" -ForegroundColor Gray
    }

    Start-Sleep -Seconds 2
    Write-Host "  Docker 서비스 상태:" -ForegroundColor Gray
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null | Select-Object -First 5
} else {
    Write-Host "`n[2/5] Docker 건너뛰기 (-SkipDocker)" -ForegroundColor Gray
}

# 3. API 빌드
if (-not $SkipBuild) {
    Write-Host "`n[3/5] API 빌드..." -ForegroundColor Yellow
    Push-Location "$scriptRoot\polytech-lms-api"

    Write-Host "  Gradle compileJava..." -ForegroundColor Gray
    & .\gradlew.bat compileJava --no-daemon -q

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  빌드 성공!" -ForegroundColor Green
    } else {
        Write-Host "  빌드 실패!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Host "`n[3/5] 빌드 건너뛰기 (-SkipBuild)" -ForegroundColor Gray
}

# 4. 환경변수 설정
Write-Host "`n[4/5] 환경변수 설정..." -ForegroundColor Yellow

# 기본값 설정 (환경변수가 없으면)
if (-not $env:GCP_PROJECT_ID) { $env:GCP_PROJECT_ID = "polytech-lms" }
if (-not $env:GCP_LOCATION) { $env:GCP_LOCATION = "asia-northeast3" }
if (-not $env:QDRANT_HOST) { $env:QDRANT_HOST = "localhost" }

Write-Host "  GCP_PROJECT_ID: $env:GCP_PROJECT_ID" -ForegroundColor Gray
Write-Host "  GCP_LOCATION: $env:GCP_LOCATION" -ForegroundColor Gray
Write-Host "  QDRANT_HOST: $env:QDRANT_HOST" -ForegroundColor Gray

# 5. API 서버 시작
Write-Host "`n[5/5] API 서버 시작 (포트: $ApiPort)..." -ForegroundColor Yellow
Push-Location "$scriptRoot\polytech-lms-api"

# 기존 프로세스 종료
$existingProcess = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "  기존 프로세스 종료 (포트: $ApiPort)" -ForegroundColor Gray
    Stop-Process -Id $existingProcess.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "  Spring Boot 애플리케이션 시작..." -ForegroundColor Gray
Start-Process -FilePath ".\gradlew.bat" -ArgumentList "bootRun --no-daemon" -NoNewWindow

Pop-Location

# 서버 시작 대기
Write-Host "`n서버 시작 대기 중..." -ForegroundColor Yellow
$maxWait = 60
$waited = 0

while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 2
    $waited += 2

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$ApiPort/actuator/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "`n서버 시작 완료!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "." -NoNewline
    }
}

if ($waited -ge $maxWait) {
    Write-Host "`n서버 시작 타임아웃 (${maxWait}초)" -ForegroundColor Yellow
    Write-Host "수동으로 확인하세요: http://localhost:$ApiPort/actuator/health" -ForegroundColor Gray
}

# API 엔드포인트 목록
Write-Host @"

======================================================
   서비스 시작 완료!
======================================================

API 엔드포인트:
  - 헬스체크: http://localhost:$ApiPort/actuator/health
  - 학사 API: http://localhost:$ApiPort/api/haksa
  - GCP API:  http://localhost:$ApiPort/api/gcp

학사 API (RFP 8개 항목):
  GET  /api/haksa/courses              - 전체 강좌 목록
  GET  /api/haksa/courses/{code}       - 강좌 상세
  POST /api/haksa/courses/sync         - 개설정보 동기화
  GET  /api/haksa/syllabus/{code}      - 강좌 계획서
  GET  /api/haksa/syllabus/{code}/pdf  - 계획서 PDF
  POST /api/haksa/attendance/check     - 출석 체크
  GET  /api/haksa/attendance/validity/{code}/{week}  - 차시 유효기간
  POST /api/haksa/antifraud/validate-session  - 대리출석 방지
  GET  /api/haksa/grade/criteria/{code}  - 성적 기준 조회
  PUT  /api/haksa/grade/criteria/{code}  - 성적 기준 수정
  POST /api/haksa/grade/criteria/{code}/lock  - 성적 기준 잠금

GCP AI 서비스:
  POST /api/gcp/vertex-ai/embedding   - 임베딩 생성
  POST /api/gcp/vertex-ai/rag         - RAG 질의응답
  POST /api/gcp/bigquery/query        - BigQuery 쿼리
  GET  /api/gcp/bigquery/stats/progress/{code}  - 학습 진도 통계
  POST /api/gcp/tts/synthesize        - 텍스트→음성
  POST /api/gcp/stt/recognize         - 음성→텍스트
  GET  /api/gcp/health                - GCP 서비스 상태

프론트엔드:
  학생 대시보드:  file:///$scriptRoot/public_html/html/haksa/student_dashboard.html
  교수자 대시보드: file:///$scriptRoot/public_html/html/haksa/professor_dashboard.html
  관리자 대시보드: file:///$scriptRoot/public_html/html/haksa/admin_dashboard.html

"@ -ForegroundColor Cyan
