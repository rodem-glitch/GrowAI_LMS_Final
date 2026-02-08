// services/api.ts — API 클라이언트 (공통 오류코드 적용)
import axios from 'axios';
import type { ApiResponse, User, Course, Enrollment, Lesson, Grade, GradeCriteria, Post, FraudLog, SyncLog, AiRecommendation, AiChatMessage } from '@/types';
import { extractErrorMessage } from '@/utils/errorHandler';

const api = axios.create({ baseURL: '/api' });

// JWT 인터셉터
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('accessToken');
      window.location.href = '/login';
    }
    // 공통 오류코드 기반 사용자 친화적 메시지 추출
    err.userMessage = extractErrorMessage(err);
    return Promise.reject(err);
  }
);

// ── Auth ──
export const authApi = {
  login: (userId: string, password: string) =>
    api.post<ApiResponse<{ accessToken: string; refreshToken: string; userId: string; name: string; userType: string; campus: string; department: string }>>('/auth/login', { userId, password }),
  refresh: (refreshToken: string) =>
    api.post<ApiResponse<{ accessToken: string }>>('/auth/refresh', { refreshToken }),
};

// ── Users ──
export const userApi = {
  me: () => api.get<ApiResponse<User>>('/users/me'),
  getById: (id: number) => api.get<ApiResponse<User>>(`/users/${id}`),
  search: (keyword: string) => api.get<ApiResponse<User[]>>('/users/search', { params: { keyword } }),
  update: (id: number, data: Partial<User>) => api.put<ApiResponse<User>>(`/users/${id}`, data),
};

// ── Courses ──
export const courseApi = {
  list: (keyword?: string) => api.get<ApiResponse<Course[]>>('/courses', { params: { keyword } }),
  detail: (id: number) => api.get<ApiResponse<Course>>(`/courses/${id}`),
  top: () => api.get<ApiResponse<Course[]>>('/courses/top'),
  byGroup: (groupCode: string) => api.get<ApiResponse<Course[]>>(`/courses/group/${groupCode}`),
  enroll: (courseId: number) => api.post<ApiResponse<Enrollment>>(`/courses/${courseId}/enroll`),
  myEnrollments: (status?: string) => api.get<ApiResponse<Enrollment[]>>('/courses/my', { params: { status } }),
};

// ── Classroom ──
export const classroomApi = {
  lessons: (courseId: number) => api.get<ApiResponse<Lesson[]>>(`/classroom/courses/${courseId}/lessons`),
  validLessons: (courseId: number) => api.get<ApiResponse<Lesson[]>>(`/classroom/courses/${courseId}/lessons/valid`),
  updateProgress: (lessonId: number, data: { courseId: number; watchedSeconds: number; totalSeconds: number; fingerprint?: string }) =>
    api.post(`/classroom/lessons/${lessonId}/progress`, null, { params: data }),
  attendance: (courseId: number) => api.get(`/classroom/courses/${courseId}/attendance`),
  assignments: (courseId: number) => api.get(`/classroom/courses/${courseId}/assignments`),
  submitAssignment: (assignmentId: number, data: { content?: string; fileUrl?: string }) =>
    api.post(`/classroom/assignments/${assignmentId}/submit`, null, { params: data }),
  exams: (courseId: number) => api.get(`/classroom/courses/${courseId}/exams`),
};

// ── Grades ──
export const gradeApi = {
  my: () => api.get<ApiResponse<Grade[]>>('/grades/my'),
  myCourse: (courseId: number) => api.get<ApiResponse<Grade>>(`/grades/my/${courseId}`),
  courseGrades: (courseId: number) => api.get<ApiResponse<Grade[]>>(`/grades/courses/${courseId}`),
  save: (grade: Partial<Grade>) => api.post<ApiResponse<Grade>>('/grades', grade),
  getCriteria: (courseId: number) => api.get<ApiResponse<GradeCriteria>>(`/grades/criteria/${courseId}`),
  saveCriteria: (criteria: Partial<GradeCriteria>) => api.post<ApiResponse<GradeCriteria>>('/grades/criteria', criteria),
};

// ── Board ──
export const boardApi = {
  list: (boardType: string, page = 0, size = 20) => api.get<ApiResponse<any>>('/boards', { params: { boardType, page, size } }),
  search: (keyword: string) => api.get<ApiResponse<any>>('/boards/search', { params: { keyword } }),
  detail: (id: number) => api.get<ApiResponse<Post>>(`/boards/${id}`),
  create: (post: Partial<Post>) => api.post<ApiResponse<Post>>('/boards', post),
  update: (id: number, post: Partial<Post>) => api.put<ApiResponse<Post>>(`/boards/${id}`, post),
  delete: (id: number) => api.delete(`/boards/${id}`),
  comments: (postId: number) => api.get(`/boards/${postId}/comments`),
  addComment: (postId: number, content: string) => api.post(`/boards/${postId}/comments`, { content }),
};

// ── AI ──
export const aiApi = {
  chat: (message: string, sessionId?: string, courseId?: number) =>
    api.post<ApiResponse<{ response: string; sessionId: string }>>('/ai/chat', { message, sessionId, courseId: courseId?.toString() }),
  summarize: (text: string) => api.post<ApiResponse<{ summary: string }>>('/ai/summarize', { text }),
  feedback: (assignmentContent: string, studentAnswer: string) =>
    api.post<ApiResponse<{ feedback: string }>>('/ai/feedback', { assignmentContent, studentAnswer }),
  recommendations: () => api.get<ApiResponse<AiRecommendation[]>>('/ai/recommendations'),
  clickRecommendation: (id: number) => api.post(`/ai/recommendations/${id}/click`),
  chatHistory: () => api.get<ApiResponse<AiChatMessage[]>>('/ai/chat/history'),
  courseAnalytics: (courseId: number) => api.get(`/ai/analytics/courses/${courseId}`),
  dashboardAnalytics: () => api.get('/ai/analytics/dashboard'),
};

// ── Instructor (교수자) ──
export const instructorApi = {
  dashboard: (instructorId: string) => api.get(`/instructor/dashboard/${instructorId}`),
  courses: (params?: { search?: string; category?: string }) => api.get('/instructor/courses', { params }),
  mySubjects: (instructorId: string, params?: { year?: string; term?: string; type?: string; status?: string }) =>
    api.get(`/instructor/subjects/${instructorId}`, { params }),
  subjectDetail: (subjectId: number) => api.get(`/instructor/subjects/detail/${subjectId}`),
  subjectCriteria: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/criteria`),
  saveCriteria: (subjectId: number, data: any) => api.post(`/instructor/subjects/${subjectId}/criteria`, data),
  lessons: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/lessons`),
  lessonVideos: (unitId: number) => api.get(`/instructor/lessons/${unitId}/videos`),
  students: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/students`),
  attendance: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/attendance`),
  assignments: (instructorId: string, params?: { status?: string; startDate?: string; endDate?: string }) =>
    api.get(`/instructor/assignments/${instructorId}`, { params }),
  subjectAssignments: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/assignments`),
  assignmentSubmissions: (assignmentId: number) => api.get(`/instructor/assignments/${assignmentId}/submissions`),
  qna: (instructorId: string, params?: { status?: string; startDate?: string; endDate?: string }) =>
    api.get(`/instructor/qna/${instructorId}`, { params }),
  subjectQna: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/qna`),
  replyQna: (postId: number, content: string) => api.post(`/instructor/qna/${postId}/reply`, { content }),
  examCategories: (instructorId: string) => api.get(`/instructor/exam/categories/${instructorId}`),
  createCategory: (data: any) => api.post('/instructor/exam/categories', data),
  examQuestions: (instructorId: string, params?: { categoryId?: number; type?: string }) =>
    api.get(`/instructor/exam/questions/${instructorId}`, { params }),
  exams: (instructorId: string) => api.get(`/instructor/exams/${instructorId}`),
  contents: (params?: { search?: string; type?: string }) => api.get('/instructor/contents', { params }),
  contentFavorites: (userId: string) => api.get(`/instructor/contents/favorites/${userId}`),
  grades: (subjectId: number) => api.get(`/instructor/subjects/${subjectId}/grades`),
  statistics: (instructorId: string) => api.get(`/instructor/statistics/${instructorId}`),
};

// ── Haksa (학사정보 연동) ──
export const haksaApi = {
  dashboard: () => api.get('/haksa/dashboard'),
  studentRecords: (params?: { search?: string; department?: string }) =>
    api.get('/haksa/student-records', { params }),
  grades: (params?: { year?: string; term?: string; department?: string }) =>
    api.get('/haksa/grades', { params }),
  enrollment: () => api.get('/haksa/enrollment'),
  syncEnrollment: () => api.post('/haksa/enrollment/sync'),
  calendar: (params?: { year?: number; month?: number }) => api.get('/haksa/calendar', { params }),
  syncStatus: () => api.get('/haksa/sync/status'),
  executeSync: (module: string) => api.post('/haksa/sync/execute', { module }),
  logs: (params?: { level?: string; module?: string; startDate?: string; endDate?: string }) =>
    api.get('/haksa/logs', { params }),
};

// ── Conference (화상강의) ──
export const conferenceApi = {
  createRoom: (data: { courseId: number; title: string }) => api.post('/conference/rooms', data),
  joinRoom: (roomId: string) => api.get(`/conference/rooms/${roomId}/join`),
  courseRooms: (courseId: number) => api.get(`/conference/courses/${courseId}/rooms`),
};

// ── Anti-Fraud ──
export const antiFraudApi = {
  unresolved: (page = 0, size = 20) => api.get<ApiResponse<any>>('/antifraud/unresolved', { params: { page, size } }),
  stats: () => api.get('/antifraud/stats'),
  resolve: (id: number) => api.post(`/antifraud/${id}/resolve`),
  userHistory: (userId: number) => api.get<ApiResponse<FraudLog[]>>(`/antifraud/users/${userId}`),
};

// ── Admin ──
export const adminApi = {
  dashboard: () => api.get('/admin/dashboard'),
  users: (type?: string, keyword?: string) => api.get<ApiResponse<User[]>>('/admin/users', { params: { type, keyword } }),
  createUser: (user: Partial<User>) => api.post<ApiResponse<User>>('/admin/users', user),
  deactivateUser: (id: number) => api.delete(`/admin/users/${id}`),
  createCourse: (course: Partial<Course>) => api.post<ApiResponse<Course>>('/admin/courses', course),
  updateCourse: (id: number, course: Partial<Course>) => api.put<ApiResponse<Course>>(`/admin/courses/${id}`, course),
  triggerSync: () => api.post<ApiResponse<SyncLog>>('/admin/sync/trigger'),
  syncLogs: () => api.get<ApiResponse<SyncLog[]>>('/admin/sync/logs'),
};

// ── Common (COM-001~005) ──
export const commonApi = {
  // COM-001: SSO 로그인
  ssoCallback: (ssoToken: string) => api.post('/common/sso/callback', { ssoToken }),
  // COM-002: 세션 관리
  sessionStatus: () => api.get('/common/session/status'),
  sessionExtend: () => api.post('/common/session/extend'),
  // COM-003: GNB 메뉴
  menu: () => api.get('/common/menu'),
  // COM-004: 알림
  notifications: (page = 0, size = 20) => api.get('/common/notifications', { params: { page, size } }),
  notificationRead: (id: number) => api.post(`/common/notifications/${id}/read`),
  notificationReadAll: () => api.post('/common/notifications/read-all'),
  notificationUnreadCount: () => api.get('/common/notifications/unread-count'),
  // COM-005: 통합 검색
  search: (keyword: string, category?: string, page = 0) => api.get('/common/search', { params: { keyword, category, page } }),
  searchSuggestions: (keyword: string) => api.get('/common/search/suggestions', { params: { keyword } }),
};

// ── Student Features (STD-001~L02) ──
export const studentFeatureApi = {
  // STD-001: 학적 정보
  profile: () => api.get('/student/profile'),
  syncProfile: () => api.post('/student/profile/sync'),
  // STD-002: 역량 태그
  competencies: () => api.get('/student/competencies'),
  competencyCloud: () => api.get('/student/competencies/cloud'),
  // STD-A01: AI 진로 상담
  careerChat: (sessionId: string, message: string) => api.post('/student/career/chat', { sessionId, message }),
  careerChatSessions: () => api.get('/student/career/chat/sessions'),
  careerChatMessages: (sessionId: string) => api.get(`/student/career/chat/sessions/${sessionId}/messages`),
  // STD-A02: AI 자소서
  generateCoverLetter: (company: string, position: string) => api.post('/student/cover-letter/generate', { company, position }),
  coverLetters: () => api.get('/student/cover-letters'),
  updateCoverLetter: (id: number, data: any) => api.put(`/student/cover-letters/${id}`, data),
  // STD-C01: 맞춤 공고 추천
  jobRecommendations: (params?: { location?: string; salary?: string; companySize?: string }) =>
    api.get('/student/jobs/recommendations', { params }),
  // STD-C02: 공고 스크랩
  jobDetail: (id: number) => api.get(`/student/jobs/${id}`),
  jobScrap: (id: number) => api.post(`/student/jobs/${id}/scrap`),
  jobScraps: () => api.get('/student/jobs/scraps'),
  // STD-L01: Gap 분석
  runGapAnalysis: (targetJobCode: string, targetJobName: string) =>
    api.post('/student/gap-analysis', { targetJobCode, targetJobName }),
  latestGapAnalysis: () => api.get('/student/gap-analysis/latest'),
  // STD-L02: 콘텐츠 추천
  contentRecommendations: (params?: { gapAnalysisId?: number; contentType?: string }) =>
    api.get('/student/content-recommendations', { params }),
};

// ── Instructor Features (PRF-001~002) ──
export const instructorFeatureApi = {
  // PRF-001: 과거 강의
  lectureHistory: (params?: { semester?: string; year?: number }) =>
    api.get('/instructor/lectures/history', { params }),
  importLecture: (lectureId: number) => api.post(`/instructor/lectures/import/${lectureId}`),
  // PRF-A01: AI 실라버스
  generateSyllabus: (subjectName: string, targetGrade: number, totalWeeks = 15) =>
    api.post('/instructor/syllabus/generate', { subjectName, targetGrade, totalWeeks }),
  getSyllabus: (id: number) => api.get(`/instructor/syllabus/${id}`),
  updateSyllabus: (id: number, data: any) => api.put(`/instructor/syllabus/${id}`, data),
  // PRF-A02: 영상 추천
  videoRecommend: (params: { subjectId?: number; weekNo?: number; keyword?: string }) =>
    api.get('/instructor/videos/recommend', { params }),
  // PRF-A03: 영상 요약
  videoSummarize: (videoUrl: string) => api.post('/instructor/videos/summarize', { videoUrl }),
  // PRF-E01: 커리큘럼 빌더
  createBuilder: (data: any) => api.post('/instructor/curriculum/builder', data),
  getBuilder: (id: number) => api.get(`/instructor/curriculum/builder/${id}`),
  updateBuilder: (id: number, data: any) => api.put(`/instructor/curriculum/builder/${id}`, data),
  addBuilderItem: (builderId: number, item: any) => api.post(`/instructor/curriculum/builder/${builderId}/items`, item),
  removeBuilderItem: (builderId: number, itemId: number) => api.delete(`/instructor/curriculum/builder/${builderId}/items/${itemId}`),
  // PRF-E02: AI 퀴즈
  generateQuiz: (sourceType: string, sourceText: string) =>
    api.post('/instructor/quiz/generate', { sourceType, sourceText }),
  registerQuiz: (id: number) => api.post(`/instructor/quiz/${id}/register`),
  // PRF-002: 강의계획서 제출
  submitSyllabus: (data: any) => api.post('/instructor/syllabus/submit', data),
  syllabusSubmissions: () => api.get('/instructor/syllabus/submissions'),
  syllabusSubmissionStatus: (id: number) => api.get(`/instructor/syllabus/submissions/${id}/status`),
};

// ── Admin Features (ADM-001~Y02) ──
export const adminFeatureApi = {
  // ADM-001: 운영 모니터링
  monitoringMetrics: () => api.get('/admin/monitoring/metrics'),
  monitoringResources: () => api.get('/admin/monitoring/resources'),
  monitoringSessions: () => api.get('/admin/monitoring/sessions'),
  // ADM-S01: 퍼널 분석
  funnelStats: (params?: { year?: number; campus?: string }) =>
    api.get('/admin/statistics/funnel', { params }),
  // ADM-S02: 역량 성취도
  competencyAchievement: (params?: { year?: number; campus?: string }) =>
    api.get('/admin/statistics/competency-achievement', { params }),
  aiCorrelation: () => api.get('/admin/statistics/ai-correlation'),
  // ADM-S03: 전공 일치 취업률
  employmentStats: (params?: { year?: number; campus?: string }) =>
    api.get('/admin/statistics/employment', { params }),
  employmentByDept: () => api.get('/admin/statistics/employment/department'),
  // ADM-M01: 사용자 제어
  userSearch: (keyword: string, status?: string) =>
    api.get('/admin/users/search', { params: { keyword, status } }),
  userActivity: (id: number) => api.get(`/admin/users/${id}/activity`),
  forceLogout: (id: number) => api.post(`/admin/users/${id}/force-logout`),
  blockUser: (id: number, reason: string) => api.post(`/admin/users/${id}/block`, { reason }),
  unblockUser: (id: number) => api.post(`/admin/users/${id}/unblock`),
  // ADM-O01: 배너/팝업
  banners: () => api.get('/admin/banners'),
  createBanner: (data: any) => api.post('/admin/banners', data),
  updateBanner: (id: number, data: any) => api.put(`/admin/banners/${id}`, data),
  deleteBanner: (id: number) => api.delete(`/admin/banners/${id}`),
  popups: () => api.get('/admin/popups'),
  createPopup: (data: any) => api.post('/admin/popups', data),
  updatePopup: (id: number, data: any) => api.put(`/admin/popups/${id}`, data),
  deletePopup: (id: number) => api.delete(`/admin/popups/${id}`),
  // ADM-Y01: 접속 로그
  accessLogs: (params?: { startDate?: string; endDate?: string; ip?: string; page?: number; size?: number }) =>
    api.get('/admin/logs/access', { params }),
  accessLogStats: () => api.get('/admin/logs/access/stats'),
  // ADM-Y02: 개인정보 열람 로그
  privacyLogs: (params?: { accessorId?: number; startDate?: string; endDate?: string }) =>
    api.get('/admin/logs/privacy', { params }),
  recordPrivacyAccess: (data: { targetUserId: number; accessReason: string; accessedFields: string[] }) =>
    api.post('/admin/logs/privacy', data),
  privacyAnomalies: () => api.get('/admin/logs/privacy/anomalies'),
};

// ── LMS Platform API ──
export const lmsPlatformApi = {
  overview: () => api.get('/lms-platform/overview'),
  courses: () => api.get('/lms-platform/courses'),
  courseDetail: (id: number) => api.get(`/lms-platform/courses/${id}`),
  createCourse: (data: any) => api.post('/lms-platform/courses', data),
  updateCourse: (id: number, data: any) => api.put(`/lms-platform/courses/${id}`, data),
  deleteCourse: (id: number) => api.delete(`/lms-platform/courses/${id}`),
  enrollStudent: (courseId: number, userId: number) =>
    api.post(`/lms-platform/courses/${courseId}/enroll`, { userId }),
  unenrollStudent: (courseId: number, userId: number) =>
    api.delete(`/lms-platform/courses/${courseId}/enroll/${userId}`),
  enrollments: (courseId: number) =>
    api.get(`/lms-platform/courses/${courseId}/enrollments`),
  userEnrollments: (userId: number) =>
    api.get(`/lms-platform/users/${userId}/enrollments`),
  updateAssessment: (data: any) => api.put('/lms-platform/assessment', data),
  courseStats: (courseId: number) => api.get(`/lms-platform/courses/${courseId}/stats`),
  bulkEnroll: (courseId: number, userIds: number[]) =>
    api.post(`/lms-platform/courses/${courseId}/bulk-enroll`, userIds),
};

// ── Statistics / Apache Superset API ──
export const statisticsApi = {
  enrollmentStats: () => api.get('/statistics/enrollment-stats'),
  attendanceStats: () => api.get('/statistics/attendance-stats'),
  completionStats: () => api.get('/statistics/completion-stats'),
  courseRankings: (limit = 10) => api.get('/statistics/course-rankings', { params: { limit } }),
  monthlyTrends: (months = 6) => api.get('/statistics/monthly-trends', { params: { months } }),
  departmentStats: () => api.get('/statistics/department-stats'),
  dashboard: () => api.get('/statistics/dashboard'),
  customReport: (type: string, params?: Record<string, string>) =>
    api.get('/statistics/report', { params: { type, ...params } }),
};

// ── Data Interface API (DB I/F) ──
export const dataApi = {
  // 학생 메뉴
  getStudentDashboard: (userId: number) =>
    api.get(`/data/student/dashboard/${userId}`).then(r => r.data.data),
  getCourseList: () =>
    api.get('/data/courses').then(r => r.data.data),
  getClassroom: (contentId: number) =>
    api.get(`/data/classroom/${contentId}`).then(r => r.data.data),

  // 교수자 메뉴
  getExamManagement: () =>
    api.get('/data/instructor/exams').then(r => r.data.data),
  getQuestionBank: (categoryId: number) =>
    api.get(`/data/instructor/questions/${categoryId}`).then(r => r.data.data),
  getContentManagement: () =>
    api.get('/data/instructor/contents').then(r => r.data.data),

  // 관리자 메뉴
  getAdminMonitoring: () =>
    api.get('/data/admin/monitoring').then(r => r.data.data),
  getUserManagement: () =>
    api.get('/data/admin/users').then(r => r.data.data),
  getBannerManagement: () =>
    api.get('/data/admin/banners').then(r => r.data.data),
  getAccessLogs: (limit = 100) =>
    api.get('/data/admin/access-logs', { params: { limit } }).then(r => r.data.data),

  // 학사 연동
  getHaksaSyncStatus: () =>
    api.get('/data/haksa/sync-status').then(r => r.data.data),
};

// ── Recommendation Engine API (Apache PredictionIO) ──
export const recommendationApi = {
  dashboard: () => api.get('/recommendation/dashboard'),
  courses: (userId: number, limit = 10, category = '') =>
    api.get('/recommendation/courses', { params: { userId, limit, category: category || undefined } }),
  contents: (userId: number) => api.get('/recommendation/contents', { params: { userId } }),
  trainingStatus: () => api.get('/recommendation/training-status'),
};

export default api;
