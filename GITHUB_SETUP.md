# GitHub Repository 설정 가이드

**Repository**: https://github.com/lindsey00/GrowAI
**프로젝트**: GrowAI-MAP
**날짜**: 2026년 2월 1일

---

## 📋 목차

- [Repository 초기 설정](#repository-초기-설정)
- [GitHub Secrets 설정](#github-secrets-설정)
- [Branch 전략](#branch-전략)
- [CI/CD 워크플로우](#cicd-워크플로우)
- [첫 배포 실행](#첫-배포-실행)
- [협업 가이드](#협업-가이드)

---

## Repository 초기 설정

### 1. 로컬 Git 설정

```bash
cd D:\Workspace\GrowAI-MAP_260130\GrowAI-MAP

# Git 초기화 (이미 되어있지 않은 경우)
git init

# Remote 추가
git remote add origin https://github.com/lindsey00/GrowAI.git

# 현재 상태 확인
git status
```

### 2. .gitignore 확인

현재 프로젝트의 `.gitignore`가 다음을 포함하는지 확인:

```gitignore
# Backend
backend/build/
backend/.gradle/
backend/out/
*.jar
*.war
*.class

# Frontend
frontend/node_modules/
frontend/dist/
frontend/.vite/
frontend/npm-debug.log*

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
*.log

# GCP
gcp-config.env
*-key.json
```

### 3. 첫 커밋 및 푸시

```bash
# 현재 브랜치 확인 및 main으로 변경
git branch -M main

# 모든 파일 스테이징
git add .

# 커밋
git commit -m "feat: 초기 GrowAI-MAP 프로젝트 구성

- CI/CD 파이프라인 구축 (GitHub Actions, Jenkins)
- Kubernetes 배포 매니페스트 생성
- Docker 멀티스테이지 빌드 설정
- 프로덕션 준비 완료

Co-Authored-By: Claude Code <noreply@anthropic.com>"

# 원격 저장소에 푸시
git push -u origin main
```

---

## GitHub Secrets 설정

### 필수 Secrets

GitHub Repository → Settings → Secrets and variables → Actions 에서 설정:

#### 1. GCP_PROJECT_ID
```
Name: GCP_PROJECT_ID
Secret: your-gcp-project-id
```

**획득 방법**:
```bash
gcloud config get-value project
```

#### 2. GCP_SA_KEY
```
Name: GCP_SA_KEY
Secret: <service-account-key-json-content>
```

**획득 방법**:
```bash
# setup-gcp.sh 실행 후 생성된 키 파일
cat ~/growai-key.json
```

전체 JSON 내용을 복사하여 Secret에 붙여넣기:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "growai-deployer@your-project-id.iam.gserviceaccount.com",
  ...
}
```

#### 3. SLACK_WEBHOOK_URL (선택사항)
```
Name: SLACK_WEBHOOK_URL
Secret: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**획득 방법**:
1. Slack Workspace → Apps → Incoming Webhooks
2. Add to Slack
3. Channel 선택
4. Webhook URL 복사

#### 4. SONAR_TOKEN (선택사항)
```
Name: SONAR_TOKEN
Secret: your-sonarcloud-token
```

**획득 방법**:
1. https://sonarcloud.io 접속
2. My Account → Security → Generate Token
3. Token 복사

### Secrets 검증

```bash
# GitHub CLI 사용 (설치된 경우)
gh secret list

# Expected output:
# GCP_PROJECT_ID    Updated 2026-02-01
# GCP_SA_KEY        Updated 2026-02-01
# SLACK_WEBHOOK_URL Updated 2026-02-01
# SONAR_TOKEN       Updated 2026-02-01
```

---

## Branch 전략

### Branch 구조

```
main           → Production 환경
  ↑
develop        → Staging 환경
  ↑
feature/*      → 기능 개발
  ↑
hotfix/*       → 긴급 수정
```

### Branch 생성

```bash
# develop 브랜치 생성 및 푸시
git checkout -b develop
git push -u origin develop

# develop을 기본 브랜치로 설정 (GitHub에서)
# Settings → Branches → Default branch → develop
```

### 보호 규칙 설정

**Settings → Branches → Add branch protection rule**

#### main 브랜치 보호
```
Branch name pattern: main

✅ Require a pull request before merging
   ✅ Require approvals (1)
   ✅ Dismiss stale pull request approvals when new commits are pushed

✅ Require status checks to pass before merging
   ✅ Require branches to be up to date before merging
   Required checks:
      - backend-test
      - frontend-test
      - docker-build
      - security-scan

✅ Require conversation resolution before merging

✅ Do not allow bypassing the above settings
```

#### develop 브랜치 보호
```
Branch name pattern: develop

✅ Require a pull request before merging
   ✅ Require approvals (1)

✅ Require status checks to pass before merging
   Required checks:
      - backend-test
      - frontend-test
```

---

## CI/CD 워크플로우

### GitHub Actions 워크플로우

#### 1. CI Workflow (ci.yml)

**트리거**:
- Push to `main`, `develop`
- Pull Request to `main`, `develop`

**Jobs**:
1. Backend Build & Test
2. Frontend Build & Test
3. Docker Build Test
4. Security Scan
5. Code Quality Check

**실행 확인**:
```
https://github.com/lindsey00/GrowAI/actions
```

#### 2. Deploy Workflow (build-deploy.yml)

**트리거**:
- Push to `main` → Production 배포
- Push to `develop` → Staging 배포
- Manual dispatch (workflow_dispatch)

**Jobs**:
1. Build & Push Docker Images to GCR
2. Deploy to Staging (develop)
3. Deploy to Production (main)
4. Smoke Tests
5. Notifications (Slack)

---

## 첫 배포 실행

### Staging 환경 배포

```bash
# 1. develop 브랜치로 전환
git checkout develop

# 2. 변경사항 커밋
git add .
git commit -m "feat: Staging 환경 배포 준비"

# 3. 푸시 (자동으로 CI/CD 트리거)
git push origin develop
```

**배포 프로세스**:
1. GitHub Actions CI 워크플로우 실행
2. 테스트 통과 확인
3. Docker 이미지 빌드 및 GCR 푸시
4. GKE Staging 네임스페이스에 배포
5. 스모크 테스트 실행
6. Slack 알림 (성공/실패)

**확인**:
```bash
# GitHub Actions 로그
https://github.com/lindsey00/GrowAI/actions

# GKE 배포 상태
kubectl get all -n staging
```

### Production 환경 배포

```bash
# 1. develop → main PR 생성
git checkout develop
git pull origin develop
gh pr create --base main --head develop \
  --title "Release: v1.0.0" \
  --body "Production 릴리스 배포"

# 또는 GitHub 웹에서:
# https://github.com/lindsey00/GrowAI/compare/main...develop
```

**배포 프로세스**:
1. PR 리뷰 및 승인
2. PR 머지
3. GitHub Actions Deploy 워크플로우 자동 실행
4. Docker 이미지 빌드 및 GCR 푸시
5. **GitHub Environment 승인 대기** (Manual Gate)
6. 승인 후 Production 배포
7. 스모크 테스트 실행
8. 릴리스 태그 자동 생성
9. Slack 알림

---

## 워크플로우 상태 배지

README.md에 추가:

```markdown
# GrowAI-MAP

[![CI](https://github.com/lindsey00/GrowAI/actions/workflows/ci.yml/badge.svg)](https://github.com/lindsey00/GrowAI/actions/workflows/ci.yml)
[![Deploy](https://github.com/lindsey00/GrowAI/actions/workflows/build-deploy.yml/badge.svg)](https://github.com/lindsey00/GrowAI/actions/workflows/build-deploy.yml)
```

---

## 협업 가이드

### Feature 개발 워크플로우

```bash
# 1. develop에서 feature 브랜치 생성
git checkout develop
git pull origin develop
git checkout -b feature/add-user-profile

# 2. 개발 및 커밋
git add .
git commit -m "feat: 사용자 프로필 기능 추가"

# 3. 원격에 푸시
git push origin feature/add-user-profile

# 4. PR 생성
gh pr create --base develop --head feature/add-user-profile \
  --title "feat: 사용자 프로필 기능 추가" \
  --body "## 변경사항
- 사용자 프로필 API 추가
- 프로필 페이지 UI 구현

## 테스트
- [x] 단위 테스트
- [x] 통합 테스트
- [x] E2E 테스트"

# 5. CI 통과 확인 및 리뷰 요청
# 6. 승인 후 머지
```

### Hotfix 워크플로우

```bash
# 1. main에서 hotfix 브랜치 생성
git checkout main
git pull origin main
git checkout -b hotfix/fix-login-bug

# 2. 버그 수정 및 커밋
git add .
git commit -m "fix: 로그인 버그 수정"

# 3. PR 생성 (main으로)
git push origin hotfix/fix-login-bug
gh pr create --base main --head hotfix/fix-login-bug \
  --title "hotfix: 로그인 버그 긴급 수정" \
  --label "hotfix"

# 4. 긴급 승인 및 머지
# 5. develop에도 반영
git checkout develop
git merge hotfix/fix-login-bug
git push origin develop
```

### 커밋 메시지 규칙

**Format**: `<type>: <subject>`

**Types**:
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅
- `refactor`: 리팩토링
- `test`: 테스트 추가
- `chore`: 빌드/설정 변경

**Examples**:
```
feat: 사용자 인증 기능 추가
fix: 로그인 세션 만료 버그 수정
docs: API 문서 업데이트
refactor: 데이터베이스 연결 로직 개선
test: 사용자 서비스 테스트 추가
chore: Gradle 버전 업그레이드
```

---

## GitHub Issues & Projects

### Issue 템플릿

**.github/ISSUE_TEMPLATE/bug_report.md**:
```markdown
---
name: Bug Report
about: 버그 제보
title: '[BUG] '
labels: bug
assignees: ''
---

## 버그 설명
버그에 대한 명확한 설명

## 재현 단계
1. '...' 페이지로 이동
2. '....' 클릭
3. '....' 스크롤
4. 에러 발생

## 예상 동작
정상적으로 동작해야 하는 내용

## 스크린샷
가능하면 스크린샷 첨부

## 환경
- OS: [예: Windows 11]
- Browser: [예: Chrome 120]
- Version: [예: v1.2.3]
```

**.github/ISSUE_TEMPLATE/feature_request.md**:
```markdown
---
name: Feature Request
about: 새로운 기능 제안
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## 기능 설명
추가하고 싶은 기능에 대한 명확한 설명

## 동기
이 기능이 왜 필요한가?

## 제안하는 해결책
어떻게 구현되어야 하는가?

## 대안
고려한 다른 방법들
```

### GitHub Projects 설정

**Settings → Projects → Link a project**

**Kanban Board**:
```
Columns:
- 📋 Backlog
- 🔜 To Do
- 🏗️ In Progress
- 👀 In Review
- ✅ Done
```

---

## 릴리스 관리

### 릴리스 태그 생성

```bash
# 버전 태그 생성
git tag -a v1.0.0 -m "Release v1.0.0

주요 변경사항:
- 초기 프로덕션 릴리스
- CI/CD 파이프라인 구축
- Kubernetes 배포 인프라"

# 태그 푸시
git push origin v1.0.0
```

### GitHub Release 생성

**GitHub → Releases → Draft a new release**

```markdown
Tag: v1.0.0
Title: GrowAI-MAP v1.0.0

## 🎉 주요 변경사항

### 새로운 기능
- ✨ 완전한 CI/CD 파이프라인 구축
- ✨ Kubernetes 배포 자동화
- ✨ 프로덕션 환경 구성

### 개선사항
- 🚀 Docker 멀티스테이지 빌드로 이미지 크기 50% 감소
- 🔒 보안 스캔 자동화
- 📊 모니터링 대시보드 구축

### 버그 수정
- 🐛 (없음 - 초기 릴리스)

## 📝 배포 가이드

[GITHUB_SETUP.md](./GITHUB_SETUP.md) 참조

## 🔗 관련 문서

- [CI/CD 배포 테스트 보고서](./docs/CICD_TEST_REPORT.md)
- [Kubernetes 배포 가이드](./k8s/README.md)
```

---

## 모니터링 및 알림

### GitHub Actions 실패 시

**자동 알림**:
- Slack 채널에 실패 메시지
- 이메일 알림 (GitHub 설정)

**대응 절차**:
1. GitHub Actions 로그 확인
2. 실패한 Job 및 Step 파악
3. 로컬에서 재현 및 수정
4. 수정 커밋 및 푸시
5. 재실행 확인

### 배포 모니터링

```bash
# 실시간 배포 상태 확인
kubectl rollout status deployment/growai-backend -n staging

# Pod 로그 확인
kubectl logs -f deployment/growai-backend -n staging

# 이벤트 확인
kubectl get events -n staging --sort-by='.lastTimestamp'
```

---

## 보안 고려사항

### 1. Secret 관리
- ✅ GitHub Secrets 사용 (절대 코드에 포함 금지)
- ✅ Service Account 키 파일 `.gitignore` 추가
- ✅ 환경변수로만 민감정보 주입

### 2. 코드 스캔
- ✅ Dependabot 활성화 (취약한 의존성 자동 감지)
- ✅ CodeQL 활성화 (코드 보안 스캔)
- ✅ Trivy 스캔 (Docker 이미지)

**Settings → Security → Code security and analysis**:
- Dependabot alerts: Enabled
- Dependabot security updates: Enabled
- Code scanning: CodeQL enabled

### 3. 접근 제한
- ✅ Branch protection rules 설정
- ✅ 2FA (Two-Factor Authentication) 필수
- ✅ Personal Access Token 대신 SSH 키 사용

---

## 트러블슈팅

### 문제: GitHub Actions 워크플로우가 실행되지 않음

**원인**: Secrets 미설정

**해결**:
```bash
# Secrets 확인
gh secret list

# 누락된 Secret 추가
gh secret set GCP_PROJECT_ID --body "your-project-id"
```

### 문제: GCR 이미지 푸시 실패

**원인**: Service Account 권한 부족

**해결**:
```bash
# GCP에서 권한 확인 및 추가
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/storage.admin"
```

### 문제: Kubernetes 배포 실패

**원인**: 리소스 부족, 이미지 풀 실패

**해결**:
```bash
# 노드 리소스 확인
kubectl top nodes

# 이벤트 확인
kubectl describe pod POD_NAME -n staging

# 이미지 경로 확인
kubectl get deployment DEPLOYMENT_NAME -n staging -o yaml | grep image
```

---

## 체크리스트

### 초기 설정
- [ ] GitHub Repository 생성 완료
- [ ] 로컬 Git Remote 설정
- [ ] `.gitignore` 확인
- [ ] 첫 커밋 및 푸시
- [ ] GitHub Secrets 등록 (GCP_PROJECT_ID, GCP_SA_KEY)
- [ ] Branch protection rules 설정
- [ ] develop 브랜치 생성

### CI/CD 확인
- [ ] CI 워크플로우 정상 실행 확인
- [ ] Deploy 워크플로우 정상 실행 확인
- [ ] Slack 알림 수신 확인
- [ ] 보안 스캔 정상 작동 확인

### 배포 확인
- [ ] Staging 환경 배포 성공
- [ ] Production 환경 배포 성공
- [ ] DNS 설정 완료
- [ ] SSL 인증서 활성화
- [ ] 헬스체크 정상

---

## 참고 자료

- [GitHub Actions 문서](https://docs.github.com/actions)
- [GitHub Secrets 관리](https://docs.github.com/actions/security-guides/encrypted-secrets)
- [GitHub Protected Branches](https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Repository**: https://github.com/lindsey00/GrowAI
**최종 업데이트**: 2026년 2월 1일
**작성자**: Claude Code
