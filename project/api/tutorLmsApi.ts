// 왜 필요한가:
// - `project` 화면(React)은 서버(JSP)에서 실제 데이터를 가져와서 즉시 보여줘야 합니다.
// - 그래서 화면마다 같은 fetch 코드를 복붙하지 않도록, 공통 API 호출 함수를 한 곳에 모읍니다.

export type TutorLmsApiResponse<T> = {
  rst_code: string;
  rst_message: string;
  rst_data?: T;
  rst_count?: number;
  rst_program_id?: number;
  rst_detached?: number;
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
};

export type TutorCourseRow = {
  id: number;
  course_nm: string;
  course_cd?: string;
  course_id_conv?: string;
  subject_nm_conv?: string;
  year?: string;
  program_id?: number;
  program_nm?: string;
  program_nm_conv?: string;
  period_conv?: string;
  student_cnt?: number;
  status_label?: string;
};

export const tutorLmsApi = {
  async getPrograms(params: { keyword?: string } = {}) {
    const url = `/tutor_lms/api/program_list.jsp${buildQuery({ s_keyword: params.keyword })}`;
    return requestJson<TutorProgramRow[]>(url);
  },

  async createProgram(payload: { courseName: string; startDate: string; endDate: string }) {
    const body = new URLSearchParams();
    body.set('course_nm', payload.courseName);
    body.set('start_date', payload.startDate);
    body.set('end_date', payload.endDate);

    return requestJson<number>(`/tutor_lms/api/program_insert.jsp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
  },

  async getMyCourses(params: { year?: string; keyword?: string } = {}) {
    const url = `/tutor_lms/api/course_list.jsp${buildQuery({ year: params.year, s_keyword: params.keyword })}`;
    return requestJson<TutorCourseRow[]>(url);
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
};

