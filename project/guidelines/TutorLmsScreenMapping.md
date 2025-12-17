# 교수자 LMS(`project`) 화면-항목-API 매핑표 (mock 제거 체크리스트)

## 왜 이 문서가 필요한가
- 화면을 “대충 돌아가게” 고치면, 나중에 특정 버튼/탭/필터가 빠져서 다시 mock이 생기기 쉽습니다.
- 그래서 화면에 보이는 **모든 항목(표 컬럼/필터/버튼/모달/탭/다운로드/출력)** 을 “체크리스트”로 만들어서, **하나도 빠짐없이** 실제 DB/API로 연결했는지 확인합니다.

## 사용 방법(중요)
- 구현/수정할 때마다 아래 체크박스를 하나씩 `✅`로 바꿔 주세요.
- 새 기능이 생기면, 반드시 이 문서에 **화면 항목 + API + 파라미터** 를 먼저 추가한 뒤 작업합니다(누락 방지).

---

## 0) 공통 규칙(모든 화면)
- [ ] 로그인/권한 실패(`rst_code=4010/4030/4031`)를 화면에서 동일한 방식으로 안내합니다.
- [ ] 로딩/에러/빈 목록 상태에서도 화면이 깨지지 않습니다.
- [ ] `site_id` 범위가 모든 API에서 강제됩니다(다른 사이트 데이터 노출 금지).
- [ ] 새로고침해도 데이터가 유지됩니다(프론트 state만으로 유지하는 mock 금지).
- [ ] `alert('추후…')` 같은 “동작 흉내”가 남지 않습니다(실제 동작 또는 비활성/숨김 처리).

---

## 1) 진입/메뉴

### `project/App.tsx`
- 목적: 좌측 메뉴로 화면 전환
- 체크
  - [ ] `대시보드` → `Dashboard`
  - [ ] `과정탐색` → `CourseExplorer`
  - [ ] `담당과목` → `MyCoursesList` → `CourseManagement`
  - [ ] `과정개설` → `CreateCourseForm`
  - [ ] `과목개설` → `CreateSubjectWizard`

---

## 2) 대시보드

### `project/components/Dashboard.tsx`
- 데이터 출처: **신규** `/tutor_lms/api/dashboard.jsp`
- API 요구사항(예시)
  - 진행중 과목 수(정의: 오늘이 `study_sdate~study_edate` 사이인 과목)
  - 미확인 과제 수(정의: `LM_HOMEWORK_USER.submit_yn='Y'` 이면서 `confirm_yn!='Y'`)
  - 미답변 Q&A 수(정의: Q&A 게시글 `proc_status != 1`)
  - 진행 중 과목 리스트(과목명/수강생수/평균진도/미확인과제/미답변Q&A)
  - 최근 과제 제출 리스트(학생/과목/과제/제출일/확인여부)
  - 최근 Q&A 리스트(학생/과목/제목/작성일/답변여부)
- 체크
  - [ ] 상단 통계 3개가 실데이터로 표시됩니다
  - [ ] “진행 중 과목” 목록이 실데이터로 표시됩니다
  - [ ] “최근 과제 제출” 목록이 실데이터로 표시됩니다
  - [ ] “최근 Q&A” 목록이 실데이터로 표시됩니다

---

## 3) 과정 탐색 / 운영계획서

### `project/components/CourseExplorer.tsx`
- API: `/tutor_lms/api/program_list.jsp`
- 비고: `plan_json`을 파싱해서 분류/학과/전공/목표 등 UI에 채웁니다(없으면 항목 숨김/대체 표시).
- 체크
  - [ ] 과정 목록이 실데이터로 표시됩니다
  - [ ] 검색이 실데이터 기준으로 동작합니다
  - [ ] 년도 필터가 실데이터 기반으로 동작합니다
  - [ ] “카드/리스트 뷰” 모두 정상 표시됩니다

### `project/components/OperationalPlan.tsx`
- API: `/tutor_lms/api/program_view.jsp`
- 체크
  - [ ] 운영계획서 상세가 실데이터로 표시됩니다(`plan_json` 포함)
  - [ ] `plan_json`이 없을 때 안내 문구가 정확히 표시됩니다
  - [ ] 인쇄/PDF 저장 버튼이 정상 동작합니다(브라우저 print)

---

## 4) 담당 과목

### `project/components/MyCoursesList.tsx`
- API: `/tutor_lms/api/course_list.jsp`
- 체크
  - [ ] 년도/검색으로 목록이 실데이터로 조회됩니다
  - [ ] 표 컬럼(과정ID/과목명/소속과정/기간/수강생/상태)이 의미에 맞게 표시됩니다
  - [ ] “관리” 클릭 시 실제 `course_id`로 과목관리 화면으로 진입합니다

---

## 5) 과목 관리(탭 전체)

### `project/components/CourseManagement.tsx` (메인 탭 컨테이너)
- 체크
  - [ ] 탭 전환 시 데이터가 유지/갱신 규칙대로 동작합니다
  - [ ] 과제 하위탭(과제 관리/피드백 관리) 전환이 정상 동작합니다

### 5-1) 과목정보 탭: `project/components/CourseInfoTabs.tsx`
- 조회 API: `/tutor_lms/api/course_info_get.jsp`
- 저장 API
  - 소개/목표: `/tutor_lms/api/course_info_update.jsp`
  - 평가/수료기준: `/tutor_lms/api/course_evaluation_update.jsp`
  - 증명서 설정(템플릿/번호): **신규** `/tutor_lms/api/course_certificate_update.jsp`
  - 소속 과정 변경: `/tutor_lms/api/course_set_program.jsp`
- 체크
  - [ ] “과목 개요/학습 목표”가 DB 텍스트로 표시되고 수정/저장됩니다
  - [ ] 평가 배점/기준이 DB 값으로 표시되고 수정/저장됩니다
  - [ ] 수료증/합격증 템플릿 선택이 DB에 저장되고, 출력에 반영됩니다
  - [ ] 수료번호 규칙(접두/뒷자리수/방식/정렬)이 DB에 저장됩니다

### 5-2) 강의목차: `project/components/courseManagement/CurriculumTab.tsx`
- API: `/tutor_lms/api/curriculum_list.jsp`, `curriculum_section_*`, `curriculum_lesson_*`, `/tutor_lms/api/lesson_list.jsp`
- 체크
  - [ ] 차시 목록/레슨 목록이 실데이터로 표시됩니다
  - [ ] 차시 추가/수정/삭제가 DB에 반영됩니다
  - [ ] 레슨 추가/삭제(레슨ID/외부URL)가 DB에 반영됩니다

### 5-3) 수강생: `project/components/courseManagement/StudentsTab.tsx`
- API: `/tutor_lms/api/course_students_list.jsp`, `course_students_add.jsp`, `course_students_remove.jsp`
- 체크
  - [ ] 목록/검색이 정상 동작합니다
  - [ ] 추가/제외가 DB에 반영됩니다
  - [ ] 엑셀(또는 CSV) 다운로드가 실제 파일로 내려갑니다

### 5-4) 진도/출석: `project/components/courseManagement/AttendanceTab.tsx`
- API: `/tutor_lms/api/progress_summary.jsp`, `progress_students.jsp`, `progress_detail.jsp`
- 체크
  - [ ] 요약/학생별/상세 조회가 실데이터로 표시됩니다
  - [ ] 빈 데이터(학습로그 없음)에서도 안내가 정상 표시됩니다

### 5-5) 시험: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/exam_list.jsp`, `exam_insert.jsp`, `exam_modify.jsp`, `exam_delete.jsp`, `exam_users.jsp`, `exam_score_update.jsp`
- 체크
  - [ ] 시험 목록 조회가 실데이터로 표시됩니다
  - [ ] 시험 등록/수정/삭제가 DB에 반영됩니다
  - [ ] 응시자 제출현황/점수 수정이 DB에 반영됩니다
  - [ ] 엑셀(또는 CSV) 다운로드가 실제 파일로 내려갑니다

### 5-6) 과제: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/homework_list.jsp`, `homework_insert.jsp`, `homework_modify.jsp`, `homework_delete.jsp`, `homework_users.jsp`, `homework_feedback_update.jsp`, `homework_task_append.jsp`
- 체크
  - [ ] 과제 목록 조회가 실데이터로 표시됩니다
  - [ ] 등록/수정/삭제가 DB에 반영됩니다
  - [ ] 제출현황/피드백 저장/추가과제 부여가 DB에 반영됩니다

### 5-7) 자료: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/materials_list.jsp`, `materials_upload.jsp`, `materials_delete.jsp`
- 체크
  - [ ] 자료 목록이 실데이터로 표시됩니다
  - [ ] 업로드/삭제가 DB에 반영됩니다
  - [ ] 다운로드(파일/링크)가 정상 동작합니다

### 5-8) Q&A: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/qna_list.jsp`, `qna_view.jsp`, `qna_answer.jsp`
- 체크
  - [ ] 목록/검색/상세가 정상 동작합니다
  - [ ] 답변 저장이 DB에 반영되고 상태가 갱신됩니다

### 5-9) 성적관리: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/grades_list.jsp`, `grades_recalc.jsp`
- 체크
  - [ ] 성적 목록이 실데이터로 표시됩니다
  - [ ] 재계산이 정상 동작합니다
  - [ ] 성적표 다운로드가 실제 파일(CSV 등)로 내려갑니다

### 5-10) 수료관리: `CourseManagement.tsx` 내부 탭
- API: `/tutor_lms/api/completion_list.jsp`, `completion_update.jsp`, `certificate_issue.jsp`
- 체크
  - [ ] 수료/합격/미달 상태가 실데이터로 표시됩니다
  - [ ] 수료/합격 처리 및 마감 처리(닫기/열기)가 DB에 반영됩니다
  - [ ] 수료증/합격증 출력(개별/일괄)이 정상 동작합니다

---

## 6) 과정/과목 개설

### `project/components/CreateCourseForm.tsx` (과정개설)
- API: `/tutor_lms/api/program_insert.jsp`
- 체크
  - [ ] 입력값 검증이 정상 동작합니다(기간 형식 포함)
  - [ ] 저장 후 `CourseExplorer`/`OperationalPlan`에서 실데이터로 확인됩니다

### `project/components/CreateSubjectWizard.tsx` (과목개설)
- API: `/tutor_lms/api/course_insert.jsp`, `course_students_add.jsp`, `curriculum_section_insert.jsp`, `curriculum_lesson_add.jsp`, `learner_list.jsp`, `lesson_list.jsp`, `course_image_upload.jsp`
- 체크
  - [ ] 과목 생성 → 수강생 등록 → 차시/레슨 등록이 순서대로 DB에 반영됩니다
  - [ ] 콘텐츠 라이브러리(레슨 검색/즐겨찾기)가 정상 동작합니다
  - [ ] 과정 선택 모달이 실데이터로 동작합니다

