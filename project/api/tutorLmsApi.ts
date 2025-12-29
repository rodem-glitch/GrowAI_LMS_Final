// 왜 필요한가:
// - `project` 화면(React)은 서버(JSP)에서 실제 데이터를 가져와서 즉시 보여줘야 합니다.
// - 그래서 화면마다 같은 fetch 코드를 복붙하지 않도록, 공통 API 호출 함수를 한 곳에 모읍니다.

export type TutorLmsApiResponse<T> = {
  rst_code: string;
  rst_message: string;
  rst_data?: T;
  rst_count?: number;
  rst_total?: number;
  rst_page?: number;
  rst_limit?: number;
  rst_channel?: string;
  rst_category?: string;
  rst_channels?: unknown;
  rst_categories?: unknown;
  rst_program_id?: number;
  rst_detached?: number;
  rst_skipped?: number;
  // 왜: 일부 API는 본문 외에 추가 정보를 같이 내려줍니다(exam/homework/course 등).
  rst_exam?: unknown;
  rst_homework?: unknown;
  rst_course?: unknown;
  // 왜: 대시보드처럼 여러 목록을 한 번에 내려주는 API가 있습니다.
  rst_courses?: unknown;
  rst_submissions?: unknown;
  rst_qna?: unknown;
};

function buildQuery(params: Record<string, string | number | undefined | null>) {
  const searchParams = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') return;
    searchParams.set(key, String(value));
  });
  const qs = searchParams.toString();
  return qs ? `?${qs}` : '';
}

async function requestJson<T>(url: string, options?: RequestInit): Promise<TutorLmsApiResponse<T>> {
  const response = await fetch(url, options);
  const json = (await response.json()) as TutorLmsApiResponse<T>;

  // 왜: 서버에서 오류를 내려도 화면에서는 항상 같은 방식으로 처리해야 합니다.
  if (!json || typeof json.rst_code !== 'string') {
    throw new Error('서버 응답 형식이 올바르지 않습니다.');
  }
  return json;
}

export type TutorProgramRow = {
  id: number;
  course_nm: string;
  start_date?: string;
  end_date?: string;
  training_period?: string;
  course_cnt?: number;
  plan_json?: string | null;
};

export type TutorCourseRow = {
  id: number;
  course_nm: string;
  // 왜: course_list_combined.jsp에서는 화면에서 쓰기 편하게 변환값을 같이 내려줍니다.
  course_nm_conv?: string;
  course_cd?: string;
  course_id_conv?: string;
  subject_nm_conv?: string;
  course_type?: string;
  onoff_type?: string;
  course_type_conv?: string;
  onoff_type_conv?: string;
  year?: string;
  program_id?: number;
  program_nm?: string;
  program_nm_conv?: string;
  period_conv?: string;
  student_cnt?: number;
  status_label?: string;
  // 왜: 담당과목(학사/프리즘) 탭 구분을 위해 서버에서 소스 타입을 내려줍니다.
  source_type?: 'prism' | 'haksa' | string;
  // ===== 학사 View 25개 필드 =====
  haksa_category?: string;        // 강좌형태
  haksa_dept_name?: string;       // 학과/전공 이름
  haksa_week?: string;            // 주차
  haksa_open_term?: string;       // 학기
  haksa_course_code?: string;     // 강좌코드
  haksa_visible?: string;         // 강좌 폐강 여부 (Y=정상, N=폐강)
  haksa_startdate?: string;       // 강좌시작일
  haksa_bunban_code?: string;     // 분반코드
  haksa_grade?: string;           // 학년
  haksa_grad_name?: string;       // 단과대학 이름
  haksa_day_cd?: string;          // 강의 요일
  haksa_classroom?: string;       // 강의실 정보
  haksa_curriculum_code?: string; // 과목구분 코드
  haksa_course_ename?: string;    // 강좌명(영문)
  haksa_type_syllabus?: string;   // 강의계획서 구분
  haksa_open_year?: string;       // 연도
  haksa_dept_code?: string;       // 학과/전공 코드
  haksa_course_name?: string;     // 강좌명(한글)
  haksa_group_code?: string;      // 학부/대학원 구분
  haksa_enddate?: string;         // 강좌종료일
  haksa_english?: string;         // 영문 강좌 여부
  haksa_hour1?: string;           // 강의 시간
  haksa_curriculum_name?: string; // 과목구분 이름
  haksa_grad_code?: string;       // 단과대학 코드
  haksa_is_syllabus?: string;     // 강의계획서 존재여부
};

export type TutorListRow = {
  user_id: number;
  tutor_nm: string;
};


// 통합 과목 타입 (API + 학사 View 모두 지원)
export type UnifiedCourseRow = {
  source: 'api' | 'poly';
  id: number | string;
  course_cd?: string;
  course_nm: string;
  course_id_conv?: string;
  subject_nm_conv?: string;
  year?: string;
  // API 전용 필드
  program_id?: number;
  program_nm_conv?: string;
  course_type?: string;
  onoff_type?: string;
  course_type_conv?: string;
  onoff_type_conv?: string;
  period_conv?: string;
  student_cnt?: number;
  status_label?: string;
  // 학사 View 전용 필드
  dept_code?: string;
  dept_name?: string;
  grad_code?: string;
  grad_name?: string;
  bunban_code?: string;
  curriculum_code?: string;
  curriculum_name?: string;
  grade?: string;
  open_term?: string;
  category?: string;
  visible?: string;
  course_ename?: string;
};

export type TutorCourseYearRow = {
  year: string;
};

export type TutorCourseCategoryRow = {
  id: number;
  category_nm: string;
  name_conv?: string;
  label?: string;
  parent_id?: number;
  depth?: number;
  display_yn?: 'Y' | 'N';
  status?: number;
};

export type TutorCourseInfoDetail = {
  id: number;
  course_nm: string;
  course_cd?: string;
  course_id_conv?: string;
  course_type?: string;
  onoff_type?: string;
  subject_id?: number;
  program_nm?: string;
  program_start_date?: string;
  program_end_date?: string;
  period_conv?: string;
  student_cnt?: number;

  content1_title?: string;
  content1?: string;
  content2_title?: string;
  content2?: string;

  // 평가/수료 기준
  assign_progress?: number;
  assign_exam?: number;
  assign_homework?: number;
  assign_forum?: number;
  assign_etc?: number;
  assign_survey_yn?: 'Y' | 'N';
  push_survey_yn?: 'Y' | 'N';
  pass_yn?: 'Y' | 'N';

  limit_total_score?: number;
  limit_progress?: number;
  limit_exam?: number;
  limit_homework?: number;
  limit_forum?: number;
  limit_etc?: number;
  complete_limit_progress?: number;
  complete_limit_total_score?: number;

  // 증명서
  cert_complete_yn?: 'Y' | 'N';
  cert_template_id?: number;
  pass_cert_template_id?: number;
  complete_no_yn?: 'Y' | 'N';
  complete_prefix?: string;
  postfix_cnt?: number;
  postfix_type?: 'R' | 'C';
  postfix_ord?: 'A' | 'D';
};

export type TutorCertificateTemplateRow = {
  id: number;
  template_nm?: string;
  template_cd?: string;
  template_type?: string;
  background_file?: string;
  reg_date?: string;
  status?: number;
};

// 문제 카테고리 타입 (교수자용)
export type TutorQuestionCategoryRow = {
  id: number;
  category_nm: string;
  parent_id: number;
  depth?: number;
  sort?: number;
  manager_id?: number;
  name_conv?: string; // 경로명 (예: "프로그래밍 > Java > 기초")
  label?: string; // 프론트엔드용 라벨
  status?: number;
};

// 문제은행 문제 타입 (교수자용)
export type TutorQuestionBankRow = {
  id: number;
  category_id?: number;
  category_nm?: string;
  question_type: number; // 1=단일선택, 2=다중선택, 3=단답형, 4=서술형
  question_type_conv?: string;
  question: string;
  question_text?: string;
  grade?: number; // 난이도 (1=A ~ 6=F)
  grade_conv?: string;
  item_cnt?: number;
  item1?: string;
  item2?: string;
  item3?: string;
  item4?: string;
  item5?: string;
  answer?: string;
  description?: string;
  score?: number; // 배점
  manager_id?: number;
  reg_date?: string;
  reg_date_conv?: string;
  status?: number;
  choices?: { id: string; text: string; file?: string }[];
};

// 시험 템플릿 타입 (교수자용)
export type TutorExamTemplateRow = {
  id: number;
  exam_nm: string;
  exam_time?: number;
  question_cnt?: number;
  shuffle_yn?: string;
  auto_complete_yn?: string;
  content?: string;
  range_idx?: string; // 선택된 문제 ID 목록 (쉼표 구분)
  assign1?: number; // 합격 점수로 활용
  total_points?: number; // 계산된 총점
  manager_id?: number;
  reg_date?: string;
  reg_date_conv?: string;
  status?: number;
};

export type TutorLearnerRow = {
  id: number;
  name?: string;
  student_id?: string;
  email?: string;
  dept_nm?: string;
  dept_path?: string;
};

export type TutorCourseImageUploadResult = {
  file_name: string;
  file_url: string;
  course_id?: number;
};

export type TutorProgramDetail = {
  id: number;
  site_id?: number;
  user_id?: number;
  course_nm: string;
  start_date?: string;
  end_date?: string;
  reg_date?: string;
  status?: number;
  plan_json?: string | null;
  course_nm_conv?: string;
  reg_date_conv?: string;
  start_date_conv?: string;
  end_date_conv?: string;
  training_period?: string;
};

export type TutorKollusRow = {
  id?: string;
  media_content_key: string;
  title: string;
  category_nm?: string;
  category_key?: string;
  duration?: string;
  total_time?: number;
  content_width?: number;
  content_height?: number;
  snapshot_url?: string;
  thumbnail?: string;
  original_file_name?: string;
  use_encryption_conv?: string;
  is_favorite?: boolean;
  media_id?: number;
};

export type TutorKollusChannelRow = {
  key: string;
  name: string;
  count?: number;
};

export type TutorKollusCategoryRow = {
  key: string;
  name: string;
};

export type TutorCurriculumRow = {
  course_id: number;
  section_id: number;
  section_nm?: string;
  lesson_id: number;
  chapter: number;
  lesson_nm?: string;
  lesson_type?: string;
  total_time?: number;
  duration_conv?: string;
};

export type TutorCourseStudentRow = {
  course_user_id: number;
  user_id: number;
  course_id: number;
  student_id?: string;
  name?: string;
  email?: string;
  progress?: number;
  progress_ratio?: number;
};

export type HaksaCourseStudentRow = {
  student_id?: string;
  name?: string;
  email?: string;
  mobile?: string;
  visible?: string;
  course_code?: string;
  open_year?: string;
  open_term?: string;
  bunban_code?: string;
  group_code?: string;
};

export type TutorProgressSummaryRow = {
  chapter: number;
  section_id: number;
  section_nm?: string;
  lesson_id: number;
  lesson_nm?: string;
  lesson_type?: string;
  total_time?: number;
  duration_conv?: string;
  student_cnt?: number;
  complete_cnt?: number;
  complete_rate?: number;
  avg_ratio?: number;
  last_date_conv?: string;
};

export type TutorProgressStudentRow = {
  course_user_id: number;
  user_id: number;
  student_id?: string;
  name?: string;
  email?: string;
  ratio?: number;
  study_time?: number;
  study_time_conv?: string;
  complete_yn?: 'Y' | 'N';
  complete_date_conv?: string;
  last_date_conv?: string;
};

export type TutorProgressDetailRow = {
  course_user_id: number;
  user_id: number;
  student_id?: string;
  name?: string;
  email?: string;
  chapter?: number;
  lesson_id: number;
  lesson_nm?: string;
  lesson_type?: string;
  total_time?: number;
  complete_time?: number;
  ratio?: number;
  study_time?: number;
  study_time_conv?: string;
  curr_time?: number;
  last_time?: number;
  view_cnt?: number;
  curr_page?: string;
  study_page?: number;
  complete_yn?: 'Y' | 'N';
  complete_date_conv?: string;
  last_date_conv?: string;
};

// ----- 마감 운영(시험/과제/자료/Q&A/성적/수료/증명서) -----
export type TutorExamRow = {
  exam_id: number;
  exam_nm: string;
  exam_time?: number;
  question_cnt?: number;
  onoff_type?: string;
  assign_score?: number;
  start_date?: string;
  end_date?: string;
  start_date_conv?: string;
  end_date_conv?: string;
  total_cnt?: number;
  submitted_cnt?: number;
  confirmed_cnt?: number;
};

export type TutorExamUserRow = {
  course_user_id: number;
  user_id: number;
  login_id: string;
  user_nm: string;
  submitted?: boolean;
  submitted_at?: string;
  confirm?: boolean;
  confirm_at?: string;
  marking_score?: number;
  marking_score_conv?: string;
  score_conv?: string;
};

export type TutorHomeworkRow = {
  homework_id: number;
  homework_nm?: string;
  module_nm?: string;
  assign_score?: number;
  start_date?: string;
  end_date?: string;
  start_date_conv?: string;
  end_date_conv?: string;
  total_cnt?: number;
  submitted_cnt?: number;
  confirmed_cnt?: number;
};

export type TutorHomeworkUserRow = {
  course_user_id: number;
  user_id: number;
  login_id: string;
  user_nm: string;
  submitted?: boolean;
  submitted_at?: string;
  confirm?: boolean;
  confirm_at?: string;
  marking_score?: number;
  marking_score_conv?: string;
  score_conv?: string;
  feedback?: string;
  task_cnt?: number;
};

export type TutorMaterialRow = {
  library_id: number;
  library_nm: string;
  content?: string;
  library_file?: string;
  library_link?: string;
  file_url?: string;
  file_size_conv?: string;
  upload_date_conv?: string;
};

export type TutorQnaRow = {
  id: number;
  subject: string;
  question_conv?: string;
  user_nm?: string;
  login_id?: string;
  reg_date_conv?: string;
  answered?: boolean;
  proc_status?: number;
};

export type TutorQnaDetail = {
  question_id: number;
  subject: string;
  question_content: string;
  question_user_nm: string;
  question_login_id: string;
  question_reg_date_conv?: string;
  answered?: boolean;
  answer_id?: number;
  answer_content?: string;
  answer_user_nm?: string;
  answer_login_id?: string;
  answer_reg_date_conv?: string;
};

export type TutorGradeRow = {
  course_user_id: number;
  user_id: number;
  login_id: string;
  user_nm: string;
  progress_ratio?: number;
  exam_score?: number;
  homework_score?: number;
  etc_score?: number;
  total_score?: number;
  status_label?: string;
};

export type TutorCompletionRow = {
  course_user_id: number;
  user_id: number;
  login_id: string;
  user_nm: string;
  progress_ratio?: number;
  total_score?: number;
  complete_status?: string;
  complete_yn?: string;
  complete_no?: string;
  complete_date_conv?: string;
  close_yn?: string;
  close_date_conv?: string;
  status_label?: string;
};

export type TutorDashboardStats = {
  active_course_cnt: number;
  pending_homework_cnt: number;
  unanswered_qna_cnt: number;
  today?: string;
};

export type TutorDashboardCourseRow = {
  id: number;
  course_cd?: string;
  course_nm: string;
  course_id_conv?: string;
  period_conv?: string;
  student_cnt?: number;
  avg_progress_ratio?: number;
  avg_progress_ratio_conv?: string;
  pending_homework_cnt?: number;
  unanswered_qna_cnt?: number;
};

export type TutorDashboardSubmissionRow = {
  course_id: number;
  course_id_conv?: string;
  course_nm: string;
  homework_id: number;
  homework_nm: string;
  course_user_id: number;
  user_nm?: string;
  login_id?: string;
  submit_date?: string;
  submitted_at?: string;
  confirm_yn?: string;
  confirmed?: boolean;
};

export type TutorDashboardQnaRow = {
  post_id: number;
  course_id: number;
  course_nm: string;
  subject: string;
  reg_date?: string;
  reg_date_conv?: string;
  proc_status?: number;
  answered?: boolean;
  user_nm?: string;
  login_id?: string;
};

export const tutorLmsApi = {
  // =========================
  // 대시보드
  // =========================
  async getDashboard() {
    const url = `/tutor_lms/api/dashboard.jsp`;
    return requestJson<TutorDashboardStats>(url) as Promise<
      TutorLmsApiResponse<TutorDashboardStats> & {
        rst_courses?: TutorDashboardCourseRow[];
        rst_submissions?: TutorDashboardSubmissionRow[];
        rst_qna?: TutorDashboardQnaRow[];
      }
    >;
  },

  async getPrograms(params: { keyword?: string } = {}) {
    const url = `/tutor_lms/api/program_list.jsp${buildQuery({ s_keyword: params.keyword })}`;
    return requestJson<TutorProgramRow[]>(url);
  },

  async getProgram(id: number) {
    const url = `/tutor_lms/api/program_view.jsp${buildQuery({ id })}`;
    return requestJson<TutorProgramDetail>(url);
  },

  async createProgram(payload: { courseName: string; startDate: string; endDate: string; planJson: string }) {
    const body = new URLSearchParams();
    body.set('course_nm', payload.courseName);
    body.set('start_date', payload.startDate);
    body.set('end_date', payload.endDate);
    body.set('plan_json', payload.planJson);

    return requestJson<number>(`/tutor_lms/api/program_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getProgramCourses(params: { programId: number }) {
    const url = `/tutor_lms/api/program_course_list.jsp${buildQuery({ program_id: params.programId })}`;
    return requestJson<TutorCourseRow[]>(url);
  },

  async modifyProgram(payload: { id: number; courseName: string; startDate?: string; endDate?: string; planJson?: string }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));
    body.set('course_nm', payload.courseName);
    if (payload.startDate !== undefined) body.set('start_date', payload.startDate);
    if (payload.endDate !== undefined) body.set('end_date', payload.endDate);
    if (payload.planJson !== undefined) body.set('plan_json', payload.planJson);

    return requestJson<number>(`/tutor_lms/api/program_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteProgram(payload: { id: number }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));

    return requestJson<number>(`/tutor_lms/api/program_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getCourseYears(params: { tutorId?: number } = {}) {
    const url = `/tutor_lms/api/course_years.jsp${buildQuery({ tutor_id: params.tutorId })}`;
    return requestJson<TutorCourseYearRow[]>(url);
  },

  async getMyCourses(params: { year?: string; keyword?: string } = {}) {
    const url = `/tutor_lms/api/course_list.jsp${buildQuery({ year: params.year, s_keyword: params.keyword })}`;
    return requestJson<TutorCourseRow[]>(url);
  },

  // 왜: 학사 시스템(View) 과목을 별도 목록으로 조회할 때 사용합니다.
  async getPolyCourses(params: { year?: string } = {}) {
    const url = `/tutor_lms/api/course_list_poly.jsp${buildQuery({ year: params.year })}`;
    return requestJson<UnifiedCourseRow[]>(url);
  },

  // 왜: 담당과목 화면에서 학사/프리즘 탭을 분리하여 조회하기 위함
  async getMyCoursesCombined(params: {
    tab: 'prism' | 'haksa';
    year?: string;
    keyword?: string;
    page?: number;
    pageSize?: number;
    haksaCategory?: string;
    haksaGrad?: string;
    haksaCurriculum?: string;
    sortOrder?: 'asc' | 'desc';
  } = { tab: 'prism' }) {
    const url = `/tutor_lms/api/course_list_combined.jsp${buildQuery({
      tab: params.tab,
      year: params.year,
      s_keyword: params.keyword,
      page: params.page,
      page_size: params.pageSize,
      haksa_category: params.haksaCategory,
      haksa_grad: params.haksaGrad,
      haksa_curriculum: params.haksaCurriculum,
      sort_order: params.sortOrder,
    })}`;
    return requestJson<TutorCourseRow[]>(url);
  },

  // 왜: 과목 복사 시 담당 교수/강사 선택 목록을 만들기 위함
  async getTutors() {
    const url = `/tutor_lms/api/tutor_list.jsp`;
    return requestJson<TutorListRow[]>(url);
  },

  // 왜: 원본 과목을 복사해서 새 과목을 만들고 차시 편집으로 이어가기 위함
  async copyCourse(payload: { sourceCourseId: number; courseName: string; tutorId: number }) {
    const body = new URLSearchParams();
    body.set('source_course_id', String(payload.sourceCourseId));
    body.set('course_nm', payload.courseName);
    body.set('tutor_id', String(payload.tutorId));

    return requestJson<number>(`/tutor_lms/api/course_copy.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async setCourseProgram(payload: { courseId: number; programId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('program_id', String(payload.programId));

    return requestJson<number>(`/tutor_lms/api/course_set_program.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 과목정보(소개/목표/평가/증명서 설정)
  // =========================
  async getCourseInfo(params: { courseId: number }) {
    const url = `/tutor_lms/api/course_info_get.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorCourseInfoDetail>(url);
  },

  async updateCourseInfo(payload: { courseId: number; content1: string; content2: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('content1', payload.content1);
    body.set('content2', payload.content2);

    return requestJson<number>(`/tutor_lms/api/course_info_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateCourseEvaluation(payload: {
    courseId: number;
    assignProgress: number;
    assignExam: number;
    assignHomework: number;
    assignForum: number;
    assignEtc: number;
    assignSurveyYn: 'Y' | 'N';
    pushSurveyYn: 'Y' | 'N';
    passYn: 'Y' | 'N';
    limitTotalScore: number;
    limitProgress: number;
    limitExam: number;
    limitHomework: number;
    limitForum: number;
    limitEtc: number;
    completeLimitProgress: number;
    completeLimitTotalScore: number;
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));

    body.set('assign_progress', String(payload.assignProgress));
    body.set('assign_exam', String(payload.assignExam));
    body.set('assign_homework', String(payload.assignHomework));
    body.set('assign_forum', String(payload.assignForum));
    body.set('assign_etc', String(payload.assignEtc));

    body.set('assign_survey_yn', payload.assignSurveyYn);
    body.set('push_survey_yn', payload.pushSurveyYn);
    body.set('pass_yn', payload.passYn);

    body.set('limit_total_score', String(payload.limitTotalScore));
    body.set('limit_progress', String(payload.limitProgress));
    body.set('limit_exam', String(payload.limitExam));
    body.set('limit_homework', String(payload.limitHomework));
    body.set('limit_forum', String(payload.limitForum));
    body.set('limit_etc', String(payload.limitEtc));

    body.set('complete_limit_progress', String(payload.completeLimitProgress));
    body.set('complete_limit_total_score', String(payload.completeLimitTotalScore));

    return requestJson<number>(`/tutor_lms/api/course_evaluation_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateCourseCertificateSettings(payload: {
    courseId: number;
    certCompleteYn: 'Y' | 'N';
    certTemplateId: number;
    passCertTemplateId: number;
    completeNoYn: 'Y' | 'N';
    completePrefix: string;
    postfixCnt: number;
    postfixType: 'R' | 'C';
    postfixOrd: 'A' | 'D';
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('cert_complete_yn', payload.certCompleteYn);
    body.set('cert_template_id', String(payload.certTemplateId));
    body.set('pass_cert_template_id', String(payload.passCertTemplateId));

    body.set('complete_no_yn', payload.completeNoYn);
    body.set('complete_prefix', payload.completePrefix);
    body.set('postfix_cnt', String(payload.postfixCnt));
    body.set('postfix_type', payload.postfixType);
    body.set('postfix_ord', payload.postfixOrd);

    return requestJson<number>(`/tutor_lms/api/course_certificate_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // ----- 과목개설(CreateSubjectWizard) -----
  async createCourse(payload: {
    courseName: string;
    year: string;
    studyStartDate: string;
    studyEndDate: string;
    programId?: number;
    categoryId?: number;
    semester?: string;
    credit?: string | number;
    lessonTime?: string | number;
    content1?: string;
    content2?: string;
    courseFile?: string;
  }) {
    const body = new URLSearchParams();
    body.set('course_nm', payload.courseName);
    body.set('year', payload.year);
    body.set('study_sdate', payload.studyStartDate);
    body.set('study_edate', payload.studyEndDate);
    if (payload.programId) body.set('program_id', String(payload.programId));
    if (payload.categoryId) body.set('category_id', String(payload.categoryId));
    if (payload.semester) body.set('semester', payload.semester);
    if (payload.credit !== undefined && payload.credit !== null && String(payload.credit) !== '') body.set('credit', String(payload.credit));
    if (payload.lessonTime !== undefined && payload.lessonTime !== null && String(payload.lessonTime) !== '') body.set('lesson_time', String(payload.lessonTime));
    if (payload.content1) body.set('content1', payload.content1);
    if (payload.content2) body.set('content2', payload.content2);
    if (payload.courseFile) body.set('course_file', payload.courseFile);

    return requestJson<number>(`/tutor_lms/api/course_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getCourseCategories() {
    // 왜: "과정 카테고리"를 관리자(sysop)와 같은 기준(LM_CATEGORY)으로 보여주기 위해 필요합니다.
    return requestJson<TutorCourseCategoryRow[]>(`/tutor_lms/api/course_categories.jsp`);
  },

  async getLearners(params: { keyword?: string; deptId?: number; deptKeyword?: string; page?: number; limit?: number } = {}) {
    const url = `/tutor_lms/api/learner_list.jsp${buildQuery({
      s_keyword: params.keyword,
      dept_id: params.deptId,
      s_dept: params.deptKeyword,
      page: params.page,
      limit: params.limit,
    })}`;
    return requestJson<TutorLearnerRow[]>(url);
  },

  async uploadCourseImage(payload: { file: File; courseId?: number }) {
    const formData = new FormData();
    formData.set('course_file', payload.file);
    if (payload.courseId) formData.set('course_id', String(payload.courseId));

    return requestJson<TutorCourseImageUploadResult>(`/tutor_lms/api/course_image_upload.jsp`, {
      method: 'POST',
      body: formData,
    });
  },

  // ----- 콘텐츠(콜러스 목록) -----
  async getKollusList(params: { keyword?: string; channelKey?: string; categoryKey?: string; page?: number; limit?: number; version?: number } = {}) {
    const url = `/tutor_lms/api/kollus_list.jsp${buildQuery({
      s_keyword: params.keyword,
      s_channel: params.channelKey,
      s_category: params.categoryKey,
      page: params.page,
      limit: params.limit,
      version: params.version,
    })}`;
    return requestJson<TutorKollusRow[]>(url);
  },

  async getKollusWishlistList(params: { keyword?: string; page?: number; limit?: number } = {}) {
    const url = `/tutor_lms/api/kollus_wishlist_list.jsp${buildQuery({
      s_keyword: params.keyword,
      page: params.page,
      limit: params.limit,
    })}`;
    return requestJson<TutorKollusRow[]>(url);
  },

  async toggleKollusWishlist(payload: {
    mediaContentKey: string;
    title?: string;
    snapshotUrl?: string;
    categoryKey?: string;
    categoryName?: string;
    originalFileName?: string;
    totalTime?: number;
    contentWidth?: number;
    contentHeight?: number;
  }) {
    const body = new URLSearchParams();
    body.set('media_content_key', payload.mediaContentKey);
    if (payload.title) body.set('title', payload.title);
    if (payload.snapshotUrl) body.set('snapshot_url', payload.snapshotUrl);
    if (payload.categoryKey) body.set('category_key', payload.categoryKey);
    if (payload.categoryName) body.set('category_nm', payload.categoryName);
    if (payload.originalFileName) body.set('original_file_name', payload.originalFileName);
    if (payload.totalTime !== undefined) body.set('total_time', String(payload.totalTime));
    if (payload.contentWidth !== undefined) body.set('content_width', String(payload.contentWidth));
    if (payload.contentHeight !== undefined) body.set('content_height', String(payload.contentHeight));

    return requestJson<number>(`/tutor_lms/api/kollus_wishlist_toggle.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async upsertKollusLesson(payload: { mediaContentKey: string; title?: string; totalTime?: number; contentWidth?: number; contentHeight?: number }) {
    const body = new URLSearchParams();
    body.set('media_content_key', payload.mediaContentKey);
    if (payload.title) body.set('title', payload.title);
    if (payload.totalTime !== undefined) body.set('total_time', String(payload.totalTime));
    if (payload.contentWidth !== undefined) body.set('content_width', String(payload.contentWidth));
    if (payload.contentHeight !== undefined) body.set('content_height', String(payload.contentHeight));

    return requestJson<number>(`/tutor_lms/api/kollus_lesson_upsert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },


  // ----- 강의목차(curriculum_*) -----
  async getCurriculum(params: { courseId: number }) {
    const url = `/tutor_lms/api/curriculum_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorCurriculumRow[]>(url);
  },


  async insertCurriculumSection(payload: { courseId: number; sectionName: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('section_nm', payload.sectionName);

    return requestJson<number>(`/tutor_lms/api/curriculum_section_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async modifyCurriculumSection(payload: { courseId: number; sectionId: number; sectionName: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('section_id', String(payload.sectionId));
    body.set('section_nm', payload.sectionName);

    return requestJson<number>(`/tutor_lms/api/curriculum_section_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteCurriculumSection(payload: { courseId: number; sectionId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('section_id', String(payload.sectionId));

    return requestJson<number>(`/tutor_lms/api/curriculum_section_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async addCurriculumLesson(payload: { courseId: number; sectionId: number; lessonId?: number; url?: string; title?: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('section_id', String(payload.sectionId));
    if (payload.lessonId) body.set('lesson_id', String(payload.lessonId));
    if (payload.url) body.set('url', payload.url);
    if (payload.title) body.set('title', payload.title);

    return requestJson<number>(`/tutor_lms/api/curriculum_lesson_add.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteCurriculumLesson(payload: { courseId: number; lessonId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('lesson_id', String(payload.lessonId));

    return requestJson<number>(`/tutor_lms/api/curriculum_lesson_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateCurriculumLesson(payload: {
    courseId: number;
    lessonId: number;
    chapter?: number;
    sectionId?: number;
    completeTime?: number;
    tutorId?: number;
    startDate?: string;
    endDate?: string;
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('lesson_id', String(payload.lessonId));
    if (payload.chapter !== undefined) body.set('chapter', String(payload.chapter));
    if (payload.sectionId !== undefined) body.set('section_id', String(payload.sectionId));
    if (payload.completeTime !== undefined) body.set('complete_time', String(payload.completeTime));
    if (payload.tutorId !== undefined) body.set('tutor_id', String(payload.tutorId));
    if (payload.startDate !== undefined) body.set('start_date', payload.startDate);
    if (payload.endDate !== undefined) body.set('end_date', payload.endDate);

    return requestJson<number>(`/tutor_lms/api/curriculum_lesson_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // ----- 수강생(course_students_*) -----
  async getCourseStudents(params: { courseId: number; keyword?: string }) {
    const url = `/tutor_lms/api/course_students_list.jsp${buildQuery({ course_id: params.courseId, s_keyword: params.keyword })}`;
    return requestJson<TutorCourseStudentRow[]>(url);
  },

  // ----- 학사 수강생(읽기 전용) -----
  async getHaksaCourseStudents(params: {
    courseCode: string;
    openYear?: string;
    openTerm?: string;
    bunbanCode?: string;
    groupCode?: string;
    keyword?: string;
  }) {
    const url = `/tutor_lms/api/haksa_students_list.jsp${buildQuery({
      course_code: params.courseCode,
      open_year: params.openYear,
      open_term: params.openTerm,
      bunban_code: params.bunbanCode,
      group_code: params.groupCode,
      s_keyword: params.keyword,
    })}`;
    return requestJson<HaksaCourseStudentRow[]>(url);
  },

  async addCourseStudents(payload: { courseId: number; userIds: number[] }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('user_ids', payload.userIds.join(','));

    return requestJson<number>(`/tutor_lms/api/course_students_add.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async removeCourseStudent(payload: { courseId: number; userId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('user_id', String(payload.userId));

    return requestJson<number>(`/tutor_lms/api/course_students_remove.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // ----- 진도(progress_*) -----
  async getProgressSummary(params: { courseId: number }) {
    const url = `/tutor_lms/api/progress_summary.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorProgressSummaryRow[]>(url);
  },

  async getProgressStudents(params: { courseId: number; lessonId: number }) {
    const url = `/tutor_lms/api/progress_students.jsp${buildQuery({ course_id: params.courseId, lesson_id: params.lessonId })}`;
    return requestJson<TutorProgressStudentRow[]>(url);
  },

  async getProgressDetail(params: { courseId: number; courseUserId: number; lessonId: number }) {
    const url = `/tutor_lms/api/progress_detail.jsp${buildQuery({
      course_id: params.courseId,
      course_user_id: params.courseUserId,
      lesson_id: params.lessonId,
    })}`;
    return requestJson<TutorProgressDetailRow>(url);
  },

  // =========================
  // 마감 운영: 시험
  // =========================
  async getExams(params: { courseId: number }) {
    const url = `/tutor_lms/api/exam_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorExamRow[]>(url);
  },

  async createExam(payload: {
    courseId: number;
    title: string;
    description?: string;
    examDate: string;
    examTime: string;
    duration: number;
    questionCount?: number;
    totalScore?: number;
    allowRetake?: boolean;
    showResults?: boolean;
    onoffType?: 'N' | 'F';
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('title', payload.title);
    body.set('description', payload.description ?? '');
    body.set('examDate', payload.examDate);
    body.set('examTime', payload.examTime);
    body.set('duration', String(payload.duration));
    body.set('questionCount', String(payload.questionCount ?? 0));
    body.set('totalScore', String(payload.totalScore ?? 100));
    body.set('allowRetake', String(Boolean(payload.allowRetake)));
    body.set('showResults', String(payload.showResults ?? true));
    body.set('onoff_type', payload.onoffType ?? 'F');

    return requestJson<number>(`/tutor_lms/api/exam_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateExam(payload: {
    courseId: number;
    examId: number;
    title: string;
    description?: string;
    examDate: string;
    examTime: string;
    duration: number;
    questionCount?: number;
    totalScore?: number;
    allowRetake?: boolean;
    showResults?: boolean;
    onoffType?: 'N' | 'F';
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('exam_id', String(payload.examId));
    body.set('title', payload.title);
    body.set('description', payload.description ?? '');
    body.set('examDate', payload.examDate);
    body.set('examTime', payload.examTime);
    body.set('duration', String(payload.duration));
    body.set('questionCount', String(payload.questionCount ?? 0));
    body.set('totalScore', String(payload.totalScore ?? 100));
    body.set('allowRetake', String(Boolean(payload.allowRetake)));
    body.set('showResults', String(payload.showResults ?? true));
    body.set('onoff_type', payload.onoffType ?? 'F');

    return requestJson<number>(`/tutor_lms/api/exam_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteExam(payload: { courseId: number; examId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('exam_id', String(payload.examId));

    return requestJson<number>(`/tutor_lms/api/exam_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getExamUsers(params: { courseId: number; examId: number }) {
    const url = `/tutor_lms/api/exam_users.jsp${buildQuery({ course_id: params.courseId, exam_id: params.examId })}`;
    return requestJson<TutorExamUserRow[]>(url);
  },

  async updateExamScore(payload: { courseId: number; examId: number; courseUserId: number; markingScore: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('exam_id', String(payload.examId));
    body.set('course_user_id', String(payload.courseUserId));
    body.set('marking_score', String(payload.markingScore));

    return requestJson<number>(`/tutor_lms/api/exam_score_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 마감 운영: 과제
  // =========================
  async getHomeworks(params: { courseId: number }) {
    const url = `/tutor_lms/api/homework_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorHomeworkRow[]>(url);
  },

  async createHomework(payload: {
    courseId: number;
    title: string;
    description: string;
    dueDate: string;
    dueTime: string;
    totalScore: number;
    onoffType?: 'N' | 'F';
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('title', payload.title);
    body.set('description', payload.description);
    body.set('dueDate', payload.dueDate);
    body.set('dueTime', payload.dueTime);
    body.set('totalScore', String(payload.totalScore));
    body.set('onoff_type', payload.onoffType ?? 'N');

    return requestJson<number>(`/tutor_lms/api/homework_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateHomework(payload: {
    courseId: number;
    homeworkId: number;
    title: string;
    description: string;
    dueDate: string;
    dueTime: string;
    totalScore: number;
    onoffType?: 'N' | 'F';
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('homework_id', String(payload.homeworkId));
    body.set('title', payload.title);
    body.set('description', payload.description);
    body.set('dueDate', payload.dueDate);
    body.set('dueTime', payload.dueTime);
    body.set('totalScore', String(payload.totalScore));
    body.set('onoff_type', payload.onoffType ?? 'N');

    return requestJson<number>(`/tutor_lms/api/homework_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteHomework(payload: { courseId: number; homeworkId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('homework_id', String(payload.homeworkId));

    return requestJson<number>(`/tutor_lms/api/homework_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getHomeworkUsers(params: { courseId: number; homeworkId: number }) {
    const url = `/tutor_lms/api/homework_users.jsp${buildQuery({ course_id: params.courseId, homework_id: params.homeworkId })}`;
    return requestJson<TutorHomeworkUserRow[]>(url);
  },

  async updateHomeworkFeedback(payload: {
    courseId: number;
    homeworkId: number;
    courseUserId: number;
    markingScore: number;
    feedback: string;
  }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('homework_id', String(payload.homeworkId));
    body.set('course_user_id', String(payload.courseUserId));
    body.set('marking_score', String(payload.markingScore));
    body.set('feedback', payload.feedback);

    return requestJson<number>(`/tutor_lms/api/homework_feedback_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async appendHomeworkTask(payload: { courseId: number; homeworkId: number; courseUserId: number; task: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('homework_id', String(payload.homeworkId));
    body.set('course_user_id', String(payload.courseUserId));
    body.set('task', payload.task);

    return requestJson<number>(`/tutor_lms/api/homework_task_append.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 마감 운영: 자료
  // =========================
  async getMaterials(params: { courseId: number }) {
    const url = `/tutor_lms/api/materials_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorMaterialRow[]>(url);
  },

  async uploadMaterial(payload: { courseId: number; title: string; content?: string; link?: string; file?: File | null }) {
    const body = new FormData();
    body.set('course_id', String(payload.courseId));
    body.set('title', payload.title);
    body.set('content', payload.content ?? '');
    body.set('library_link', payload.link ?? '');
    if (payload.file) body.set('library_file', payload.file);

    return requestJson<number>(`/tutor_lms/api/materials_upload.jsp`, {
      method: 'POST',
      body,
    });
  },

  async deleteMaterial(payload: { courseId: number; libraryId: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('library_id', String(payload.libraryId));

    return requestJson<number>(`/tutor_lms/api/materials_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 마감 운영: Q&A
  // =========================
  async getQnas(params: { courseId: number; keyword?: string }) {
    const url = `/tutor_lms/api/qna_list.jsp${buildQuery({ course_id: params.courseId, s_keyword: params.keyword })}`;
    return requestJson<TutorQnaRow[]>(url);
  },

  async getQnaDetail(params: { courseId: number; postId: number }) {
    const url = `/tutor_lms/api/qna_view.jsp${buildQuery({ course_id: params.courseId, post_id: params.postId })}`;
    return requestJson<TutorQnaDetail>(url);
  },

  async answerQna(payload: { courseId: number; postId: number; content: string }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('post_id', String(payload.postId));
    body.set('content', payload.content);

    return requestJson<number>(`/tutor_lms/api/qna_answer.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 마감 운영: 성적/수료/증명서
  // =========================
  async getGrades(params: { courseId: number }) {
    const url = `/tutor_lms/api/grades_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorGradeRow[]>(url);
  },

  async recalcGrades(payload: { courseId: number; courseUserId?: number }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    if (payload.courseUserId) body.set('course_user_id', String(payload.courseUserId));

    return requestJson<number>(`/tutor_lms/api/grades_recalc.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getCompletions(params: { courseId: number }) {
    const url = `/tutor_lms/api/completion_list.jsp${buildQuery({ course_id: params.courseId })}`;
    return requestJson<TutorCompletionRow[]>(url);
  },

  async updateCompletion(payload: { courseId: number; action: 'complete_y' | 'complete_n' | 'close_y' | 'close_n'; courseUserIds: number[] }) {
    const body = new URLSearchParams();
    body.set('course_id', String(payload.courseId));
    body.set('action', payload.action);
    body.set('course_user_ids', payload.courseUserIds.join(','));

    return requestJson<number>(`/tutor_lms/api/completion_update.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getCertificateTemplates(params: { templateType?: 'C' | 'P' } = {}) {
    const url = `/tutor_lms/api/certificate_templates.jsp${buildQuery({ template_type: params.templateType })}`;
    return requestJson<TutorCertificateTemplateRow[]>(url);
  },

  async issueCertificate(payload: { courseUserId: number; type: 'C' | 'P' }) {
    const url = `/tutor_lms/api/certificate_issue.jsp${buildQuery({ course_user_id: payload.courseUserId, type: payload.type })}`;
    return requestJson<string>(url);
  },

  // =========================
  // 문제 카테고리 (교수자용)
  // =========================
  async getQuestionCategories() {
    const url = `/tutor_lms/api/question_category_list.jsp`;
    return requestJson<TutorQuestionCategoryRow[]>(url);
  },

  async createQuestionCategory(payload: { categoryName: string; parentId?: number }) {
    const body = new URLSearchParams();
    body.set('category_nm', payload.categoryName);
    if (payload.parentId !== undefined) body.set('parent_id', String(payload.parentId));

    return requestJson<number>(`/tutor_lms/api/question_category_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateQuestionCategory(payload: { id: number; categoryName: string; parentId?: number }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));
    body.set('category_nm', payload.categoryName);
    if (payload.parentId !== undefined) body.set('parent_id', String(payload.parentId));

    return requestJson<number>(`/tutor_lms/api/question_category_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteQuestionCategory(payload: { id: number }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));

    return requestJson<number>(`/tutor_lms/api/question_category_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 문제은행 (교수자용)
  // =========================
  async getQuestionBankList(params: {
    categoryId?: number;
    questionType?: number;
    keyword?: string;
    page?: number;
    limit?: number;
  } = {}) {
    const url = `/tutor_lms/api/question_bank_list.jsp${buildQuery({
      category_id: params.categoryId,
      question_type: params.questionType,
      s_keyword: params.keyword,
      page: params.page,
      limit: params.limit,
    })}`;
    return requestJson<TutorQuestionBankRow[]>(url);
  },

  async createQuestion(payload: {
    categoryId?: number;
    questionType: number; // 1=단일선택, 2=다중선택, 3=단답형, 4=서술형
    question: string;
    questionText?: string;
    grade?: number;
    answer: string;
    description?: string;
    points?: number;
    items?: string[]; // 객관식 보기 (최대 5개)
  }) {
    const body = new URLSearchParams();
    if (payload.categoryId) body.set('category_id', String(payload.categoryId));
    body.set('question_type', String(payload.questionType));
    body.set('question', payload.question);
    if (payload.questionText) body.set('question_text', payload.questionText);
    if (payload.grade) body.set('grade', String(payload.grade));
    body.set('answer', payload.answer);
    if (payload.description) body.set('description', payload.description);
    if (payload.points) body.set('points', String(payload.points));
    // 객관식 보기 처리
    if (payload.items) {
      payload.items.forEach((item, idx) => {
        body.set(`item${idx + 1}`, item);
      });
    }

    return requestJson<number>(`/tutor_lms/api/question_bank_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateQuestion(payload: {
    id: number;
    categoryId?: number;
    questionType?: number;
    question?: string;
    questionText?: string;
    grade?: number;
    answer?: string;
    description?: string;
    points?: number;
    items?: string[];
  }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));
    if (payload.categoryId !== undefined) body.set('category_id', String(payload.categoryId));
    if (payload.questionType !== undefined) body.set('question_type', String(payload.questionType));
    if (payload.question !== undefined) body.set('question', payload.question);
    if (payload.questionText !== undefined) body.set('question_text', payload.questionText);
    if (payload.grade !== undefined) body.set('grade', String(payload.grade));
    if (payload.answer !== undefined) body.set('answer', payload.answer);
    if (payload.description !== undefined) body.set('description', payload.description);
    if (payload.points !== undefined) body.set('points', String(payload.points));
    if (payload.items) {
      payload.items.forEach((item, idx) => {
        body.set(`item${idx + 1}`, item);
      });
    }

    return requestJson<number>(`/tutor_lms/api/question_bank_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteQuestion(payload: { id: number }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));

    return requestJson<number>(`/tutor_lms/api/question_bank_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  // =========================
  // 시험 템플릿 (교수자용)
  // =========================
  async getExamTemplates(params: { page?: number; limit?: number } = {}) {
    const url = `/tutor_lms/api/exam_template_list.jsp${buildQuery({
      page: params.page,
      limit: params.limit,
    })}`;
    return requestJson<TutorExamTemplateRow[]>(url);
  },

  async createExamTemplate(payload: {
    examName: string;
    examTime?: number;
    questionCnt?: number;
    shuffleYn?: boolean;
    showResultYn?: boolean;
    passingScore?: number;
    questionIds?: string[];
    content?: string;
  }) {
    const body = new URLSearchParams();
    body.set('exam_nm', payload.examName);
    if (payload.examTime) body.set('exam_time', String(payload.examTime));
    if (payload.questionCnt !== undefined) body.set('question_cnt', String(payload.questionCnt));
    if (payload.shuffleYn !== undefined) body.set('shuffle_yn', payload.shuffleYn ? 'Y' : 'N');
    if (payload.showResultYn !== undefined) body.set('show_result_yn', payload.showResultYn ? 'Y' : 'N');
    if (payload.passingScore !== undefined) body.set('passing_score', String(payload.passingScore));
    if (payload.questionIds) body.set('question_ids', payload.questionIds.join(','));
    if (payload.content) body.set('content', payload.content);

    return requestJson<number>(`/tutor_lms/api/exam_template_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async updateExamTemplate(payload: {
    id: number;
    examName?: string;
    examTime?: number;
    questionCnt?: number;
    shuffleYn?: boolean;
    showResultYn?: boolean;
    passingScore?: number;
    questionIds?: string[];
    content?: string;
  }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));
    if (payload.examName) body.set('exam_nm', payload.examName);
    if (payload.examTime) body.set('exam_time', String(payload.examTime));
    if (payload.questionCnt !== undefined) body.set('question_cnt', String(payload.questionCnt));
    if (payload.shuffleYn !== undefined) body.set('shuffle_yn', payload.shuffleYn ? 'Y' : 'N');
    if (payload.showResultYn !== undefined) body.set('show_result_yn', payload.showResultYn ? 'Y' : 'N');
    if (payload.passingScore !== undefined) body.set('passing_score', String(payload.passingScore));
    if (payload.questionIds) body.set('question_ids', payload.questionIds.join(','));
    if (payload.content !== undefined) body.set('content', payload.content);

    return requestJson<number>(`/tutor_lms/api/exam_template_modify.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async deleteExamTemplate(payload: { id: number }) {
    const body = new URLSearchParams();
    body.set('id', String(payload.id));

    return requestJson<number>(`/tutor_lms/api/exam_template_delete.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },
};
