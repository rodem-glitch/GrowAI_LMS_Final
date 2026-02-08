// services/api.ts — Axios 인스턴스 및 API 서비스

import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

// 요청 인터셉터: JWT 토큰 자동 첨부
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 응답 인터셉터: 401 → 로그인 리다이렉트
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('accessToken');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  },
);

// ==================== 학사 API ====================
export const haksaApi = {
  getCourses: () => api.get('/haksa/courses'),
  getCourse: (code: string) => api.get(`/haksa/courses/${code}`),
  getStudentsByCourse: (code: string) => api.get(`/haksa/courses/${code}/students`),
  getSyllabus: (code: string) => api.get(`/haksa/syllabus/${code}`),
  getLectPlans: (code: string) => api.get(`/haksa/lectplan/${code}`),
  getStudentDashboard: (key: string) => api.get(`/haksa/dashboard/student/${key}`),
  getProfessorDashboard: (key: string) => api.get(`/haksa/dashboard/professor/${key}`),
  getAdminDashboard: () => api.get('/haksa/dashboard/admin'),
  checkAttendance: (data: Record<string, unknown>) => api.post('/haksa/attendance/check', data),
  getStudentAttendance: (code: string, key: string) => api.get(`/haksa/attendance/student/${code}/${key}`),
  getStudentGrade: (code: string, key: string) => api.get(`/haksa/grade/student/${code}/${key}`),
  getCourseGrades: (code: string) => api.get(`/haksa/grade/course/${code}`),
  syncCourses: () => api.post('/haksa/courses/sync'),
  syncMembers: () => api.post('/haksa/members/sync'),
  getMemberSyncStatus: () => api.get('/haksa/members/sync/status'),
};

// ==================== AI API ====================
export const aiApi = {
  recommend: (memberKey: string) => api.get(`/ai/recommend/${memberKey}`),
  chat: (message: string) => api.post('/ai/chat', { message }),
};

export default api;
