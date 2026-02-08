# install-ai.ps1
# GrowAI LMS 온프레미스 AI 환경 설치 스크립트

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "GrowAI LMS 온프레미스 AI 설치" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[WARN] 관리자 권한으로 실행하는 것을 권장합니다." -ForegroundColor Yellow
}

# 1. NVIDIA 드라이버 확인
Write-Host "[1/6] NVIDIA GPU 확인..." -ForegroundColor Green
try {
    $nvidiaSmi = nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    Write-Host "  GPU 감지됨: $nvidiaSmi" -ForegroundColor White
} catch {
    Write-Host "  [ERROR] NVIDIA GPU가 감지되지 않습니다!" -ForegroundColor Red
    Write-Host "  https://www.nvidia.com/drivers 에서 드라이버를 설치하세요." -ForegroundColor Yellow
    exit 1
}

# 2. Docker 확인
Write-Host "[2/6] Docker 확인..." -ForegroundColor Green
try {
    $dockerVersion = docker --version
    Write-Host "  $dockerVersion" -ForegroundColor White
} catch {
    Write-Host "  [ERROR] Docker가 설치되지 않았습니다!" -ForegroundColor Red
    Write-Host "  https://docs.docker.com/desktop/install/windows-install/ 에서 설치하세요." -ForegroundColor Yellow
    exit 1
}

# 3. NVIDIA Container Toolkit 확인
Write-Host "[3/6] NVIDIA Container Toolkit 확인..." -ForegroundColor Green
try {
    docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi 2>$null | Out-Null
    Write-Host "  NVIDIA Container Toolkit 정상" -ForegroundColor White
} catch {
    Write-Host "  [WARN] NVIDIA Container Toolkit 설정이 필요합니다." -ForegroundColor Yellow
    Write-Host "  Docker Desktop > Settings > Resources > WSL Integration 확인" -ForegroundColor Yellow
}

# 4. Docker 네트워크 생성
Write-Host "[4/6] Docker 네트워크 설정..." -ForegroundColor Green
docker network create lms-network 2>$null
Write-Host "  네트워크 'lms-network' 준비 완료" -ForegroundColor White

# 5. 디렉토리 생성
Write-Host "[5/6] 데이터 디렉토리 생성..." -ForegroundColor Green
$dirs = @(
    "docker/qdrant",
    "docker/prometheus",
    "docker/grafana/provisioning/datasources",
    "docker/grafana/provisioning/dashboards/json",
    "data/vllm",
    "data/embedding",
    "data/qdrant"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "  디렉토리 생성 완료" -ForegroundColor White

# 6. Docker 이미지 풀
Write-Host "[6/6] Docker 이미지 다운로드 (시간이 소요됩니다)..." -ForegroundColor Green
$images = @(
    "qdrant/qdrant:latest",
    "ghcr.io/huggingface/text-embeddings-inference:1.2",
    "prom/prometheus:latest",
    "grafana/grafana:latest"
)

foreach ($image in $images) {
    Write-Host "  다운로드: $image" -ForegroundColor Gray
    docker pull $image 2>$null
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "설치 완료!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  1. ai-start.bat 실행하여 서비스 시작"
Write-Host "  2. vLLM 모델 다운로드 대기 (최초 5-10분 소요)"
Write-Host "  3. http://localhost:8000/health 로 상태 확인"
Write-Host ""
Write-Host "GPU 메모리 요구사항:" -ForegroundColor Yellow
Write-Host "  - Gemma 2 9B: 최소 16GB VRAM"
Write-Host "  - BGE-M3: 추가 2GB VRAM"
Write-Host "  - 총 권장: 24GB VRAM (RTX 3090/4090, A10/A100)"
Write-Host ""
