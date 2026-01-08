# AGENTS.md (Repository Root)

## 목적 / 범위
- 이 문서는 MalgnLMS 저장소에서 에이전트가 작업할 때 지켜야 할 기본 규칙을 정의합니다.
- **[핵심 규칙] 모든 답변과 문서(진행 계획, md 파일 등)는 반드시 한글로 작성합니다.**
- 루트 `AGENTS.md` 규칙은 전체에 적용되며, 하위 폴더의 `AGENTS.md`가 있으면 해당 폴더 규칙이 우선합니다.

## 프로젝트 구조/아키텍처 요약
- MalgnLMS는 Malgnsoft 공통 라이브러리 기반의 JSP + DAO 레거시 구조입니다.
- 대부분의 기능은 `public_html/.../*.jsp`가 컨트롤러/로직 역할을 하고, DB 접근은 `src/dao/*Dao.java`가 담당합니다.
- 화면은 JSP에서 `Page p`에 변수/루프를 세팅한 뒤, 대응되는 `.html` 템플릿을 `p.display()`로 렌더링합니다.
- `malgnsoft.db`/`malgnsoft.util` 패키지는 JAR로 포함된 공통 라이브러리이며, `DataObject`, `DataSet`, `Page`, `Malgn`, `Form`, `Auth` 등이 핵심입니다.

## 주요 디렉터리 역할
- `src/dao/`: DB 테이블 단위 DAO. `DataObject` 상속 후 `table/PK` 설정, `find/query/insert/update`를 사용합니다. 일부 도메인 로직(복사/배치 등)이 DAO에 포함돼 있습니다.
- `public_html/`: 웹 루트
  - `public_html/init.jsp`: 사용자(프론트) 공통 초기화. `m`, `f`, `p`, `siteinfo`, `Auth` 등을 세팅합니다.
  - `public_html/sysop/`: 관리자(백오피스) 기능 JSP. 각 모듈(과정/수료증/게시판/주문 등)별 폴더가 있습니다.
  - `public_html/sysop/init.jsp`: sysop 공통 초기화/권한/세션 처리.
  - `public_html/html/`: 프론트용 HTML 템플릿.
  - `public_html/sysop/html/`: sysop용 HTML 템플릿.
  - `public_html/inc/`, `public_html/common/`: 공통 include, JS/CSS/이미지.
  - `public_html/api/`: 외부/내부 API용 JSP 엔드포인트.
  - `public_html/data/`: 업로드/생성 파일 저장 위치(실서버에서는 doc_root 하위).
- `var/log/malgnlms/`: 에러/접속 등 로그.
- `resin/`, `resin.xml`: Resin WAS 설정(로컬/배포 환경별).

## 요청 처리 흐름(일반 패턴)
- JSP 상단에서 `init.jsp` 포함 → 공통 객체/권한/사이트 정보를 준비합니다.
- 화면 로직:
  - GET: DAO로 데이터 조회 → `p.setVar()/p.setLoop()`로 템플릿 변수 세팅 → `p.display()` 호출.
  - POST: `Form f`로 입력 검증(`addElement/validate`) 및 파일 저장(`saveFile`) → DAO `item()` 세팅 후 `insert/update` 수행.
- sysop 권한은 주로 `Menu.accessible(menuId, userId, userKind)`로 체크하며, `userKind`는 `S(슈퍼)`, `A(관리자)`, `C(과정운영자)` 등 코드로 구분됩니다.

## 템플릿(HTML) 문법 메모
- sysop/프론트 템플릿은 Malgn Page 문법을 사용합니다.
  - 조건: `<!--@if(name)--> ... <!--/if(name)-->`, `<!--@nif(name)--> ...`
  - 포함: `<!--@include(/path/file.html)-->`
  - 루프/변수는 JSP에서 `p.setLoop()/p.setVar()`로 주입합니다.

## 레거시 작업 시 주의
- 이 프로젝트는 Service 레이어가 없는 구조가 많으므로, 새 기능/수정 시 기존 JSP+DAO 패턴을 우선 존중합니다.
- `status` 컬럼은 관례적으로 `1=정상`, `0=중지`, `-1=삭제`를 의미하는 경우가 많습니다.
- 멀티사이트 구조가 있어 대부분 테이블에 `site_id`가 존재하므로, 쿼리/수정 시 항상 `site_id` 범위를 확인합니다.

## 커뮤니케이션 규칙
- 모든 답변은 존댓말로 작성합니다.
- 변경/제안/수정 시, 먼저 “왜 필요한지/왜 하는지”를 쉬운 말로 1~2문단 설명합니다.
- 사용자가 이해하기 쉬운 순서(문제 → 원인 → 해결 → 영향)로 설명합니다.
- 코딩 처음하는 중학생도 이해할수있도록 말한다.
- 절대 오버엔지니어링 하지 않는다.

## 코드 작성 원칙
- 신규/수정 로직에는 한글 주석으로 의도와 흐름을 설명합니다.
  - 주석은 “무엇을 하는지”보다 “왜 하는지/어떤 가정을 하는지”에 초점을 둡니다.
- 메소드는 역할 단위로 분리하고, 의미 있는 메소드명으로 작성합니다.
  - 예: `validateCourseInput()`, `buildCertificateTemplate()`, `saveCourseAndRelatedData()`
- 긴 로직은 상위 메소드가 “목차”처럼 하위 메소드를 순서대로 호출하는 구조로 만듭니다.
  - 상위 메소드에는 흐름만 남기고, 상세 구현은 하위 메소드로 이동합니다.
- 레거시 코드에서는 기존 구조/네이밍/관례를 우선 존중하고, 새로 추가하거나 수정한 부분에 위 원칙을 점진적으로 적용합니다.
  - 사용자의 요청 없이 대규모 리팩터링(파일 이동, 광범위한 네이밍 변경, 구조 재편)은 하지 않습니다.
  project 폴더내 코드를 변경 했을때 npm run build로 작업을 마무리한다.

## (선택) 레이어/언어별 규칙
- Java: DAO는 DB 접근만 담당, 비즈니스 로직은 Service에 둡니다.
- JSP/HTML: 화면 로직과 서버 로직을 분리하고, 중복되는 스크립트는 공통화합니다.
- 기타 프로젝트 고유 규칙이 있다면 여기에 추가합니다.

## (선택) 작업 절차 / 검증
- 변경 시 관련 주석/문서도 함께 갱신합니다.
- 가능한 경우 로컬에서 최소 단위 테스트 또는 기능 확인을 수행합니다.
- 테스트/실행 명령이 있다면 여기에 기입합니다.
