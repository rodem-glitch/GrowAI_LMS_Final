# 초보자를 위한 Gemini CLI 개발가이드
## MalgnLMS-미래형직업교육임차 프로젝트 실전 적용

---

# [파트 02] 제미나이 CLI 제대로 써먹는 핵심 비법

---

## 챕터 06. 효과적인 프롬프트 작성하기

### 프롬프트의 네 가지 핵심 구성요소

Gemini CLI에서 좋은 결과를 얻으려면 프롬프트를 체계적으로 작성해야 한다. MalgnLMS 프로젝트 실무에서 검증된 네 가지 구성요소는 다음과 같다.

**1. 역할(Role) 지정**

```
너는 eGovFrame 기반 LMS 시스템의 풀스택 엔지니어야.
```

MalgnLMS는 전자정부프레임워크 기반이므로, 이 컨텍스트를 명확히 해야 한다. 그냥 "개발자"가 아니라 구체적인 기술 스택과 도메인을 지정한다.

**2. 맥락(Context) 제공**

```
현재 No.88 채용 API 통합 작업 중이야.
잡코리아 연동은 완료됐고, 사람인은 승인 대기 상태야.
어댑터 패턴으로 통일해서 나중에 사람인 추가할 때 영향 최소화하고 싶어.
```

**3. 지시(Instruction) 명확화**

```
RecruitmentApiAdapter 인터페이스를 설계하고,
JobKoreaAdapter 구현체와 SaraminStubAdapter를 만들어줘.
```

**4. 출력 형식(Output Format) 지정**

```
결과물은 다음 형식으로 보여줘:
1. 변경 파일 목록
2. 핵심 변경 요약
3. 적용 후 확인 방법
```

### AI를 내 편으로 만드는 프롬프트 작성법

#### 실전 예시: No.42 관리자 IP 제한 기능

**나쁜 프롬프트:**

```
관리자 IP 제한 기능 만들어줘
```

**좋은 프롬프트:**

```
[역할]
너는 MalgnLMS 프로젝트의 백엔드 개발자야.

[맥락]
- No.42 이슈: 관리자 페이지 IP 제한 기능이 주석 처리되어 있음
- 영향 파일: AdminAccessFilter.java, application.yml, TB_ADMIN_IP_WHITELIST 테이블
- 원칙: 기존 세션 체크 로직은 유지, IP 검증만 추가 (diff 최소화)

[지시]
1. AdminAccessFilter에 IP 검증 로직 추가
2. 화이트리스트 IP는 DB에서 조회
3. JUnit 테스트 케이스 포함

[출력 형식]
- 변경 파일별 diff
- 테스트 실행 명령어
```

#### 프롬프트 템플릿 (MalgnLMS용)

```markdown
## 요청 개요
- 이슈 번호: No.{번호}
- 우선순위: {P0|P1|P2|P3}
- 기능 영역: {학생|교수|관리자} / {출결|채용|통계|...}

## 현재 상황
- 기존 구현: {있음|없음|주석처리됨}
- 관련 파일: {Controller, Service, DAO, JSP 등}
- 제약 사항: {API 승인 대기, 양식 미수령 등}

## 요청 사항
{구체적인 작업 내용}

## 기대 출력
{코드, 설계문서, 테스트 케이스 등}
```

---

## 챕터 07. 프로젝트 컨텍스트 작성하기

### GEMINI.md가 뭔가요?

GEMINI.md는 Gemini CLI가 프로젝트를 이해하도록 돕는 컨텍스트 파일이다. 프로젝트 루트에 위치하며, Gemini CLI 실행 시 자동으로 읽힌다.

MalgnLMS 프로젝트에서는 이 파일이 AI 코드 생성의 품질을 좌우한다.

### 좋은 컨텍스트 작성하기

MalgnLMS 프로젝트용 GEMINI.md 예시:

```markdown
# MalgnLMS 프로젝트 컨텍스트

## 1. 프로젝트 개요
미래형직업교육임차 LMS 시스템
- 대상: 폴리텍대학 학생/교수/관리자
- 핵심 기능: 출결관리, 성적관리, 채용연계, 콘텐츠 요약

## 2. 기술 스택
- Backend: Java 8+, Spring, eGovFrame
- Frontend: JSP, JavaScript, jQuery
- Database: Oracle/PostgreSQL
- Build: Gradle/Maven
- CI: Jenkins

## 3. 디렉토리 구조
polytech-lms-api/
├── src/main/java/kr/polytech/lms/
│   ├── admin/          # 관리자 기능
│   ├── attendance/     # 출결 관리
│   ├── contentsummary/ # Kollus 영상 요약
│   ├── recruitment/    # 채용 API 연동
│   └── student/        # 학생 기능
├── src/main/webapp/WEB-INF/
│   └── jsp/            # JSP 뷰
└── src/test/java/      # JUnit 테스트

## 4. 코딩 컨벤션
- Controller: 요청/응답 매핑만 (비즈니스 로직 금지)
- Service: 비즈니스 규칙, 트랜잭션 처리
- DAO/Repository: 데이터 접근 전담
- 외부 API: Adapter 패턴으로 캡슐화 필수

## 5. 품질 기준
- 모든 핵심 로직에 JUnit 테스트 필수
- XSS/SQL Injection 예방 (프레임워크 표준 방식)
- 변경은 최소 diff 원칙
- 공통 코어/스키마 임의 변경 금지

## 6. 현재 진행 중인 이슈
- No.42: 관리자 IP 제한 (P0, 보류)
- No.72: 개인정보 동의 문구 (P0, 보류)
- No.88: 채용 API 통합 - 잡코리아 완료, 사람인 대기 (P0, 보류)
```

### 마크다운 알아보기

GEMINI.md 작성에 필요한 마크다운 기본 문법:

| 요소 | 문법 | 용도 |
|------|------|------|
| 제목 | `# ## ###` | 섹션 구분 |
| 목록 | `- ` 또는 `1. ` | 항목 나열 |
| 코드 | 백틱 1개 또는 3개 | 코드/명령어 표시 |
| 표 | `| a | b |` | 정보 정리 |
| 강조 | `**굵게**` `*기울임*` | 중요 내용 강조 |

### 컨텍스트 파일은 어떻게 동작하나요?

```
[프로젝트 루트]
├── GEMINI.md           ← 전역 컨텍스트 (항상 적용)
├── src/
│   └── recruitment/
│       └── GEMINI.md   ← 로컬 컨텍스트 (해당 디렉토리에서만)
```

Gemini CLI는 현재 작업 디렉토리부터 루트까지 모든 GEMINI.md를 읽어서 컨텍스트를 구성한다.

**채용 모듈 전용 컨텍스트 예시** (`src/recruitment/GEMINI.md`):

```markdown
# 채용 모듈 컨텍스트

## 외부 API 연동 현황
| API | 상태 | 어댑터 |
|-----|------|--------|
| 잡코리아 | 연동 완료 | JobKoreaAdapter |
| 사람인 | 승인 대기 | SaraminStubAdapter |

## 인터페이스 규격
- RecruitmentApiAdapter 인터페이스 준수
- 반환 타입: JobPostResponse
- 입력 타입: StudentProfile

## 주의사항
- 사람인은 Mock 데이터로 대응 (승인 전까지)
- 잡코리아 일반채용공고 500개 출력 확인됨
```

### 컨텍스트 작성을 위한 꿀팁

**1. 구체적인 제약사항 명시**

```markdown
## 금지 사항
- 임의로 공통 코어(egov-common)를 수정하지 마세요
- DB 스키마를 변경하려면 DBA 승인 필요
- 프로덕션 데이터를 테스트에 사용 금지
```

**2. 현재 이슈 상태 반영**

```markdown
## 블로커 (작업 불가)
- No.37: 성적 엑셀 양식 미수령 → 폴리텍 담당자 회신 대기

## 진행 가능
- No.42: IP 제한 주석 해제 + 설정화
- No.72: 개인정보 동의 문구 DB 조회로 변경
```

**3. 코드 생성 템플릿 제공**

```java
// Service 작성 템플릿
@Service
public class {Name}Service {
    @Autowired
    private {Name}Dao dao;
    
    public {ReturnType} {methodName}({Params}) {
        // 비즈니스 로직
        return dao.{daoMethod}();
    }
}
```

---

## 챕터 08. 내장 명령어 알아보기

### 슬래시 명령어가 뭔가요?

Gemini CLI에서 `/`로 시작하는 특수 명령어다. 대화 중에 빠르게 특정 기능을 실행할 수 있다.

| 명령어 | 기능 | MalgnLMS 활용 예시 |
|--------|------|-------------------|
| `/help` | 도움말 표시 | 명령어 목록 확인 |
| `/clear` | 대화 초기화 | 새 이슈 작업 시작 시 |
| `/file` | 파일 첨부 | PRD 문서 첨부 |
| `/code` | 코드 모드 진입 | 집중 코딩 작업 |
| `/exit` | CLI 종료 | 작업 완료 시 |

### 실전 활용: 이슈별 세션 관리

```bash
# No.88 채용 API 작업 시작
gemini
> /clear
> /file docs/PRD_No88_채용API.md
> No.88 채용 API 통합 작업 시작할게. 어댑터 패턴으로 설계해줘.
```

### 셸 명령어를 바로 실행하는 셸 모드

Gemini CLI 안에서 `!` 접두사로 셸 명령어를 직접 실행할 수 있다.

```bash
# Gemini CLI 대화 중
> 현재 recruitment 패키지 구조 보여줘
AI: 네, 확인해볼게요.

> !tree src/main/java/kr/polytech/lms/recruitment
recruitment/
├── adapter/
│   ├── RecruitmentApiAdapter.java
│   ├── JobKoreaAdapter.java
│   └── SaraminStubAdapter.java
├── controller/
│   └── RecruitmentController.java
└── service/
    └── RecruitmentService.java

> 좋아, JobKoreaAdapter.java 내용 보여줘
> !cat src/main/java/kr/polytech/lms/recruitment/adapter/JobKoreaAdapter.java
```

### 외부 자료 참조를 위한 @ 명령어

`@` 명령어로 파일이나 URL을 직접 참조할 수 있다.

```bash
# 파일 참조
> @src/main/java/kr/polytech/lms/recruitment/adapter/JobKoreaAdapter.java
> 이 파일을 참고해서 SaraminAdapter 스텁을 만들어줘

# 여러 파일 동시 참조
> @src/.../RecruitmentApiAdapter.java @src/.../JobKoreaAdapter.java
> 이 인터페이스와 구현체를 분석해서 테스트 케이스 만들어줘

# URL 참조 (API 문서 등)
> @https://api.jobkorea.co.kr/docs
> 이 API 스펙에 맞게 에러 핸들링 추가해줘
```

**MalgnLMS 실전 조합 예시:**

```bash
> @docs/통합_개발가이드.md
> No.72 개인정보 동의 문구 미반영 이슈 해결해줘.
> 현재 join.jsp에 하드코딩된 문구를 DB 조회로 바꿔야 해.

AI: 가이드를 확인했습니다. 다음과 같이 수정하겠습니다...

> !grep -r "개인정보" src/main/webapp/WEB-INF/jsp/
> 여기 나온 파일들도 같이 수정해줘
```

---

## 챕터 09. 내장 도구 알아보기

### 내장 도구 작동 단계

Gemini CLI는 요청을 분석하고 적절한 도구를 자동 선택한다.

```
[사용자 요청] → [의도 분석] → [도구 선택] → [실행] → [결과 반환]
```

### 정확한 정보가 필요할 땐 검색 도구

```bash
> eGovFrame에서 트랜잭션 처리하는 표준 방법 검색해줘

AI: [검색 중...]
eGovFrame에서는 @Transactional 어노테이션을 사용합니다.
Service 레이어에 적용하는 것이 권장됩니다.
```

### 파일 관리를 위한 파일시스템 도구

| 도구 | 기능 | 예시 |
|------|------|------|
| `read_file` | 파일 읽기 | 코드 분석 |
| `write_file` | 파일 생성/수정 | 코드 생성 |
| `list_files` | 디렉토리 조회 | 구조 파악 |
| `search_files` | 파일 검색 | 관련 파일 찾기 |

**실전 활용:**

```bash
> No.42 관련 파일들 찾아줘. "AdminAccess"나 "IP" 포함된 Java 파일

AI: [파일 검색 중...]
찾은 파일:
- AdminAccessFilter.java
- AdminIpDao.java
- AdminIpService.java
```

### 다양한 내장 도구

**코드 실행 도구:**

```bash
> 이 JUnit 테스트 실행해봐
> !./gradlew test --tests AdminAccessFilterTest
```

**Git 도구:**

```bash
> 마지막 커밋 이후 변경된 파일 보여줘
> !git diff --name-only HEAD~1
```

### 제미나이 CLI 커맨드라인

터미널에서 직접 Gemini CLI에 명령을 전달할 수 있다.

```bash
# 단일 질문
gemini "No.88 채용 API 어댑터 패턴 설계해줘"

# 파일과 함께 질문
gemini -f src/recruitment/adapter/RecruitmentApiAdapter.java "이 인터페이스 구현체 만들어줘"

# 출력을 파일로 저장
gemini "SaraminStubAdapter.java 코드 생성해줘" > SaraminStubAdapter.java

# 파이프라인 활용
cat docs/PRD_No88.md | gemini "이 PRD 분석해서 태스크 목록 만들어줘"
```

---

## 챕터 10. 깃 & 깃허브 함께 사용하기

### 깃과 깃허브가 뭔가요?

MalgnLMS 프로젝트에서 Git은 필수다. 모든 변경사항을 추적하고, 이슈별로 브랜치를 관리한다.

### 첫 번째 깃 저장소 만들기

MalgnLMS 프로젝트는 이미 Git으로 관리되고 있다. 초보자가 알아야 할 핵심 워크플로우:

**1. 이슈별 브랜치 생성**

```bash
# No.88 채용 API 작업용 브랜치
git checkout -b feature/no88-recruitment-api
```

**2. Gemini CLI로 코드 생성 후 커밋**

```bash
# Gemini CLI로 작업
gemini
> No.88 SaraminStubAdapter 만들어줘

# 생성된 파일 확인
git status

# 스테이징 및 커밋
git add src/recruitment/adapter/SaraminStubAdapter.java
git commit -m "feat(No.88): add SaraminStubAdapter for mock data"
```

**3. 작은 단위로 자주 커밋**

```bash
# 좋은 예시
git commit -m "feat(No.88): define RecruitmentApiAdapter interface"
git commit -m "feat(No.88): implement JobKoreaAdapter"
git commit -m "feat(No.88): add SaraminStubAdapter"
git commit -m "test(No.88): add adapter unit tests"

# 나쁜 예시
git commit -m "No.88 작업 완료"  # 뭘 했는지 모름
```

**4. PR 전 테스트 확인**

```bash
# 테스트 실행
./gradlew test

# 통과 후 푸시
git push origin feature/no88-recruitment-api
```

---

# [파트 03] 나만의 제미나이 CLI를 만드는 AI 개인화

---

## 챕터 11. 설정 파일 알아보기

### 제미나이 CLI 설정

설정 파일 위치:
- Windows: `%USERPROFILE%\.gemini\settings.json`
- Mac/Linux: `~/.gemini/settings.json`

### 나를 위한 도구를 만드는 settings.json

MalgnLMS 프로젝트에 최적화된 설정:

```json
{
  "model": "gemini-2.0-flash",
  "temperature": 0.3,
  "maxTokens": 8192,
  "systemPrompt": "너는 eGovFrame 기반 MalgnLMS 프로젝트의 풀스택 엔지니어야.",
  "outputFormat": {
    "codeBlocks": true,
    "language": "ko"
  },
  "defaultContext": [
    "./GEMINI.md",
    "./docs/통합_개발가이드.md"
  ],
  "aliases": {
    "분석": "이 코드를 분석하고 개선점을 제안해줘",
    "테스트": "이 코드에 대한 JUnit 테스트를 작성해줘",
    "리팩터": "이 코드를 eGovFrame 표준에 맞게 리팩터링해줘"
  }
}
```

**설정 항목 설명:**

| 항목 | 설명 | MalgnLMS 권장값 |
|------|------|----------------|
| `model` | 사용할 모델 | `gemini-2.0-flash` (빠른 응답) |
| `temperature` | 창의성 수준 | `0.3` (일관된 코드 생성) |
| `systemPrompt` | 기본 역할 | eGovFrame 개발자 역할 |
| `defaultContext` | 자동 로드 파일 | 프로젝트 가이드 문서 |

### .env에 환경 변수 설정하기

프로젝트 루트에 `.env` 파일 생성:

```bash
# .env
GEMINI_API_KEY=your-api-key-here
GEMINI_MODEL=gemini-2.0-flash

# MalgnLMS 프로젝트 변수
PROJECT_NAME=MalgnLMS
JAVA_VERSION=8
SPRING_PROFILE=dev
```

**.gitignore에 추가 (필수):**

```
.env
*.env.local
```

---

## 챕터 12. 안전하게 작업하기

### 체크포인트가 뭔가요?

체크포인트는 작업 상태를 저장하는 지점이다. MalgnLMS 프로젝트에서는 Git 커밋이 체크포인트 역할을 한다.

**작업 전 체크포인트 생성:**

```bash
# 현재 상태 저장
git add -A
git stash save "체크포인트: No.88 작업 전"

# Gemini CLI 작업 진행
gemini
> 어댑터 패턴으로 리팩터링해줘

# 결과가 마음에 안 들면 복원
git stash pop
```

**배치 스크립트로 자동화 (Windows):**

```batch
@echo off
echo [체크포인트] 현재 상태 저장 중...
git add -A
git stash save "auto-checkpoint-%date%-%time%"
echo OK: 체크포인트 생성 완료
```

### 보안 강화를 위한 격리 환경, 샌드박싱

Gemini CLI가 생성한 코드를 바로 실행하지 말고, 먼저 검토하는 습관을 들이자.

**안전한 작업 흐름:**

```
1. Gemini CLI로 코드 생성
   ↓
2. 생성된 코드 리뷰 (직접 눈으로 확인)
   ↓
3. 테스트 환경에서 실행
   ↓
4. 테스트 통과 후 메인 브랜치 머지
```

**위험한 명령 필터링:**

```json
{
  "safety": {
    "blockPatterns": [
      "rm -rf",
      "DROP TABLE",
      "DELETE FROM.*WHERE 1=1",
      "sudo"
    ],
    "requireConfirmation": [
      "파일 삭제",
      "DB 수정",
      "프로덕션 배포"
    ]
  }
}
```

---

## 챕터 13. 커스텀 도구 만들기

### 커스텀 도구 알아보기

Gemini CLI의 기능을 확장하는 사용자 정의 도구다. MalgnLMS 프로젝트에 맞는 도구를 만들 수 있다.

### 간단한 커스텀 도구 생성하기

**예시: 이슈 분석 도구**

`tools/analyze-issue.js`:

```javascript
/**
 * MalgnLMS 이슈 분석 도구
 * 통합_수정사항 리스트에서 이슈 정보를 조회한다
 */
const fs = require('fs');
const path = require('path');

module.exports = {
  name: 'analyze-issue',
  description: 'MalgnLMS 이슈 번호로 상세 정보 조회',
  
  parameters: {
    issueNo: {
      type: 'string',
      description: '이슈 번호 (예: No.88)',
      required: true
    }
  },
  
  execute: async ({ issueNo }) => {
    const mappingFile = path.join(
      __dirname, 
      '../docs/통합_수정사항_실데이터_매핑표.md'
    );
    
    const content = fs.readFileSync(mappingFile, 'utf-8');
    const pattern = new RegExp(`## ${issueNo}[\\s\\S]*?(?=## No\\.|$)`, 'i');
    const match = content.match(pattern);
    
    if (match) {
      return {
        success: true,
        data: match[0].trim()
      };
    }
    
    return {
      success: false,
      message: `이슈 ${issueNo}를 찾을 수 없습니다.`
    };
  }
};
```

**도구 등록 (`settings.json`):**

```json
{
  "tools": {
    "custom": [
      "./tools/analyze-issue.js"
    ]
  }
}
```

**사용 예시:**

```bash
gemini
> No.88 이슈 정보 알려줘

AI: [analyze-issue 도구 실행 중...]
No.88 (P0) 학생 / 채용 / API
- 상태: 보류
- 이슈: 외부 API 잡코리아, 사람인 통합
- 잡코리아: 추가 완료
- 사람인: 발급 승인 대기중
- 담당: 승훈
```

---

## 챕터 14. MCP로 제미나이 CLI 확장하기

### MCP 이해하기

MCP(Model Context Protocol)는 Gemini CLI를 외부 시스템과 연결하는 표준 프로토콜이다.

MalgnLMS 프로젝트에서 유용한 MCP 활용:
- 젠킨스 빌드 상태 조회
- Jira/Redmine 이슈 연동
- DB 스키마 조회

### 옵시디언 MCP 사용하기

프로젝트 문서를 옵시디언으로 관리한다면:

```json
{
  "mcp": {
    "servers": {
      "obsidian": {
        "command": "npx",
        "args": ["-y", "@anthropic/mcp-obsidian"],
        "env": {
          "OBSIDIAN_VAULT": "/path/to/MalgnLMS-docs"
        }
      }
    }
  }
}
```

**활용 예시:**

```bash
gemini
> No.88 관련 회의록 찾아줘

AI: [Obsidian MCP 검색 중...]
찾은 문서:
- 2026-01-22 채용API 연동 회의록.md
- 잡코리아 API 스펙 정리.md
```

### 다양한 MCP 기능 확인하기

**Jenkins MCP 설정:**

```json
{
  "mcp": {
    "servers": {
      "jenkins": {
        "command": "npx",
        "args": ["-y", "mcp-jenkins"],
        "env": {
          "JENKINS_URL": "http://jenkins.malgnlms.local",
          "JENKINS_TOKEN": "${JENKINS_API_TOKEN}"
        }
      }
    }
  }
}
```

**활용:**

```bash
gemini
> 마지막 빌드 상태 확인해줘

AI: [Jenkins MCP 조회 중...]
MalgnLMS-main #142
- 상태: SUCCESS
- 소요시간: 3분 24초
- 테스트: 247/247 통과
```

---

## 챕터 15. 확장 기능 정의하기

### 확장 기능의 구조와 동작 원리

확장 기능은 Gemini CLI의 동작을 커스터마이징하는 플러그인이다.

```
[확장 기능 구조]
my-extension/
├── gemini-extension.json   # 확장 메타데이터
├── tools/                  # 커스텀 도구
├── prompts/                # 프롬프트 템플릿
└── hooks/                  # 라이프사이클 훅
```

### gemini-extension.json

MalgnLMS 프로젝트용 확장:

```json
{
  "name": "malgnlms-extension",
  "version": "1.0.0",
  "description": "MalgnLMS 프로젝트 전용 Gemini CLI 확장",
  
  "tools": [
    {
      "name": "analyze-issue",
      "path": "./tools/analyze-issue.js"
    },
    {
      "name": "check-coverage",
      "path": "./tools/check-coverage.js"
    }
  ],
  
  "prompts": {
    "분석": "./prompts/analyze.md",
    "구현": "./prompts/implement.md",
    "테스트": "./prompts/test.md"
  },
  
  "hooks": {
    "beforeGenerate": "./hooks/validate-context.js",
    "afterGenerate": "./hooks/format-output.js"
  },
  
  "context": {
    "include": [
      "GEMINI.md",
      "docs/통합_개발가이드.md",
      "docs/System-Instructions.md"
    ]
  }
}
```

### 확장 기능과 settings.json의 차이

| 구분 | settings.json | gemini-extension.json |
|------|---------------|----------------------|
| 범위 | 사용자 전역 설정 | 프로젝트/팀 특화 |
| 위치 | 홈 디렉토리 | 프로젝트 루트 |
| 공유 | 개인 설정 | Git으로 팀 공유 가능 |
| 용도 | API 키, 기본 모델 | 도구, 훅, 프롬프트 |

**MalgnLMS 권장 구성:**

```
[settings.json - 개인 설정]
- API 키
- 개인 선호 모델
- 로컬 경로

[gemini-extension.json - 팀 공유]
- 프로젝트 컨텍스트
- 코딩 컨벤션 강제
- 팀 공통 도구
```

---

# 부록: MalgnLMS 프로젝트 빠른 시작

## Windows 환경 설정 스크립트

```batch
@echo off
chcp 65001 >nul
echo === MalgnLMS Gemini CLI 환경 점검 ===

where git >nul 2>nul || (echo ERROR: git 미설치 && exit /b 1)
where java >nul 2>nul || (echo ERROR: java 미설치 && exit /b 1)
where gemini >nul 2>nul || (echo ERROR: gemini 미설치 && exit /b 1)

echo OK: 모든 도구 확인됨
echo.
echo 다음 단계:
echo 1. git clone [저장소URL]
echo 2. cd MalgnLMS
echo 3. gemini
```

## 일일 워크플로우

```bash
# 1. 저장소 동기화
git fetch --all
git pull origin main

# 2. 이슈 브랜치 생성
git checkout -b feature/no{번호}-{설명}

# 3. Gemini CLI로 작업
gemini
> @docs/통합_개발가이드.md
> No.{번호} 이슈 작업 시작

# 4. 테스트 실행
./gradlew test

# 5. 커밋 및 푸시
git add -A
git commit -m "feat(No.{번호}): {변경내용}"
git push origin feature/no{번호}-{설명}
```

---

*본 가이드는 MalgnLMS-미래형직업교육임차 프로젝트의 실제 구조와 이슈를 기반으로 작성되었습니다.*
