# GCP 서비스 설정 스크립트
# 실행 전 gcloud CLI가 설치되어 있고 인증이 완료되어 있어야 합니다.

param(
    [string]$ProjectId = "polytech-lms",
    [string]$Region = "asia-northeast3"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  GCP 서비스 설정 시작" -ForegroundColor Cyan
Write-Host "  Project: $ProjectId" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 1. gcloud 프로젝트 설정
Write-Host "`n[1/6] 프로젝트 설정..." -ForegroundColor Yellow
gcloud config set project $ProjectId

# 2. 필요한 API 활성화
Write-Host "`n[2/6] GCP API 활성화..." -ForegroundColor Yellow

$apis = @(
    "aiplatform.googleapis.com",       # Vertex AI
    "bigquery.googleapis.com",         # BigQuery
    "texttospeech.googleapis.com",     # Text-to-Speech
    "speech.googleapis.com",           # Speech-to-Text
    "storage.googleapis.com",          # Cloud Storage
    "cloudresourcemanager.googleapis.com"  # Resource Manager
)

foreach ($api in $apis) {
    Write-Host "  활성화: $api" -ForegroundColor Gray
    gcloud services enable $api --quiet
}

# 3. BigQuery 데이터셋 생성
Write-Host "`n[3/6] BigQuery 데이터셋 생성..." -ForegroundColor Yellow
$dataset = "lms_analytics"

$exists = bq ls --project_id=$ProjectId 2>&1 | Select-String $dataset
if (-not $exists) {
    bq mk --location=$Region "${ProjectId}:${dataset}"
    Write-Host "  데이터셋 생성됨: $dataset" -ForegroundColor Green
} else {
    Write-Host "  데이터셋 이미 존재: $dataset" -ForegroundColor Gray
}

# 4. BigQuery 테이블 생성 (학습 진도 통계용)
Write-Host "`n[4/6] BigQuery 테이블 생성..." -ForegroundColor Yellow

$tables = @{
    "student_progress" = @"
[
  {"name": "course_code", "type": "STRING"},
  {"name": "member_key", "type": "STRING"},
  {"name": "progress", "type": "FLOAT64"},
  {"name": "last_accessed", "type": "TIMESTAMP"}
]
"@
    "attendance_log" = @"
[
  {"name": "course_code", "type": "STRING"},
  {"name": "member_key", "type": "STRING"},
  {"name": "week", "type": "INT64"},
  {"name": "status", "type": "STRING"},
  {"name": "checked_at", "type": "TIMESTAMP"}
]
"@
    "grade_record" = @"
[
  {"name": "course_code", "type": "STRING"},
  {"name": "member_key", "type": "STRING"},
  {"name": "attendance", "type": "INT64"},
  {"name": "midterm", "type": "INT64"},
  {"name": "final_exam", "type": "INT64"},
  {"name": "assignment", "type": "INT64"},
  {"name": "total_score", "type": "FLOAT64"},
  {"name": "grade", "type": "STRING"}
]
"@
}

foreach ($table in $tables.Keys) {
    $schema = $tables[$table]
    $schemaFile = "$env:TEMP\${table}_schema.json"
    $schema | Out-File -FilePath $schemaFile -Encoding utf8

    $fullTableName = "${ProjectId}:${dataset}.${table}"
    $exists = bq show $fullTableName 2>&1 | Select-String "Not found"

    if ($exists) {
        bq mk --table $fullTableName $schemaFile
        Write-Host "  테이블 생성됨: $table" -ForegroundColor Green
    } else {
        Write-Host "  테이블 이미 존재: $table" -ForegroundColor Gray
    }

    Remove-Item $schemaFile -ErrorAction SilentlyContinue
}

# 5. 서비스 계정 생성 (선택)
Write-Host "`n[5/6] 서비스 계정 확인..." -ForegroundColor Yellow
$saName = "lms-api-service"
$saEmail = "$saName@$ProjectId.iam.gserviceaccount.com"

$exists = gcloud iam service-accounts list --filter="email:$saEmail" --format="value(email)" 2>&1
if (-not $exists) {
    Write-Host "  서비스 계정 생성: $saName" -ForegroundColor Green
    gcloud iam service-accounts create $saName --display-name="LMS API Service Account"

    # 역할 부여
    $roles = @(
        "roles/aiplatform.user",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/cloudtts.client",
        "roles/cloudspeech.client"
    )

    foreach ($role in $roles) {
        gcloud projects add-iam-policy-binding $ProjectId `
            --member="serviceAccount:$saEmail" `
            --role="$role" --quiet
    }
} else {
    Write-Host "  서비스 계정 이미 존재: $saEmail" -ForegroundColor Gray
}

# 6. 환경변수 설정 안내
Write-Host "`n[6/6] 환경변수 설정 안내" -ForegroundColor Yellow
Write-Host @"

다음 환경변수를 설정하세요:

# Windows PowerShell
`$env:GCP_PROJECT_ID = "$ProjectId"
`$env:GCP_LOCATION = "$Region"
`$env:GOOGLE_APPLICATION_CREDENTIALS = "path/to/service-account-key.json"

# 또는 application-local.yml에 추가
gcp:
  project-id: $ProjectId
  location: $Region
  credentials-path: path/to/service-account-key.json

"@ -ForegroundColor Gray

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  GCP 서비스 설정 완료!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

# API 상태 확인
Write-Host "`nAPI 활성화 상태:" -ForegroundColor Yellow
foreach ($api in $apis) {
    $status = gcloud services list --enabled --filter="name:$api" --format="value(name)" 2>&1
    if ($status -match $api) {
        Write-Host "  [O] $api" -ForegroundColor Green
    } else {
        Write-Host "  [X] $api" -ForegroundColor Red
    }
}
