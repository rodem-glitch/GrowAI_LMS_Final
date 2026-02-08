// pages/admin/LmsPlatformPage.tsx — LMS 플랫폼 관리 (Open edX 연동)
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  BookOpen,
  Users,
  GraduationCap,
  CheckCircle,
  Plus,
  Eye,
  UserCog,
  X,
  UserPlus,
  Trash2,
  Save,
} from 'lucide-react';
import api from '../../services/api';
import StatCard from '@/components/common/StatCard';

// ── 타입 정의 ──

interface PlatformOverview {
  totalCourses: number;
  activeCourses: number;
  totalStudents: number;
  completionRate: number;
}

interface PlatformCourse {
  id: number;
  courseCode: string;
  courseName: string;
  category: string;
  instructor: string;
  enrolledCount: number;
  completionRate: number;
  status: 'ACTIVE' | 'INACTIVE';
}

interface CourseCreateForm {
  courseName: string;
  description: string;
  category: string;
  instructor: string;
  startDate: string;
  endDate: string;
  maxEnrollment: number;
  year: string;
  semester: string;
  campus: string;
}

interface EnrollmentRecord {
  id: number;
  studentId: string;
  studentName: string;
  department: string;
  progress: number;
  status: string;
}

interface AssessmentForm {
  enrollmentId: number;
  courseId: number;
  studentId: string;
  score: number;
  grade: string;
}

const CATEGORIES = [
  '프로그래밍',
  '데이터베이스',
  'AI-ML',
  '웹개발',
  '레거시과정',
];

const GRADES = ['A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'];

const INITIAL_FORM: CourseCreateForm = {
  courseName: '',
  description: '',
  category: '프로그래밍',
  instructor: '',
  startDate: '',
  endDate: '',
  maxEnrollment: 40,
  year: new Date().getFullYear().toString(),
  semester: '1',
  campus: '',
};

export default function LmsPlatformPage() {
  const { t } = useTranslation();
  const queryClient = useQueryClient();

  // ── 모달 상태 ──
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [enrollmentCourse, setEnrollmentCourse] = useState<PlatformCourse | null>(null);
  const [createForm, setCreateForm] = useState<CourseCreateForm>({ ...INITIAL_FORM });
  const [newUserId, setNewUserId] = useState('');

  // ── 성적 편집 상태 ──
  const [editingAssessment, setEditingAssessment] = useState<Record<number, { score: number; grade: string }>>({});

  // ── 데이터 조회 ──
  const { data: overview } = useQuery<PlatformOverview>({
    queryKey: ['lms-platform-overview'],
    queryFn: () => api.get('/lms-platform/overview').then((r) => r.data.data ?? r.data),
    staleTime: 30000,
    retry: false,
  });

  const { data: courses, isLoading: coursesLoading } = useQuery<PlatformCourse[]>({
    queryKey: ['lms-platform-courses'],
    queryFn: () => api.get('/lms-platform/courses').then((r) => r.data.data ?? r.data),
    staleTime: 30000,
    retry: false,
  });

  const { data: enrollments, isLoading: enrollmentsLoading } = useQuery<EnrollmentRecord[]>({
    queryKey: ['lms-platform-enrollments', enrollmentCourse?.id],
    queryFn: () =>
      api
        .get(`/lms-platform/courses/${enrollmentCourse!.id}/enrollments`)
        .then((r) => r.data.data ?? r.data),
    enabled: !!enrollmentCourse,
    staleTime: 15000,
    retry: false,
  });

  // ── 뮤테이션 ──
  const createCourseMutation = useMutation({
    mutationFn: (data: CourseCreateForm) => api.post('/lms-platform/courses', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lms-platform-courses'] });
      queryClient.invalidateQueries({ queryKey: ['lms-platform-overview'] });
      setShowCreateModal(false);
      setCreateForm({ ...INITIAL_FORM });
    },
  });

  const enrollStudentMutation = useMutation({
    mutationFn: (data: { courseId: number; userId: string }) =>
      api.post(`/lms-platform/courses/${data.courseId}/enrollments`, { userId: data.userId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lms-platform-enrollments', enrollmentCourse?.id] });
      setNewUserId('');
    },
  });

  const unenrollStudentMutation = useMutation({
    mutationFn: (data: { courseId: number; enrollmentId: number }) =>
      api.delete(`/lms-platform/courses/${data.courseId}/enrollments/${data.enrollmentId}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lms-platform-enrollments', enrollmentCourse?.id] });
    },
  });

  const updateAssessmentMutation = useMutation({
    mutationFn: (data: AssessmentForm) => api.put('/lms-platform/assessment', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lms-platform-enrollments', enrollmentCourse?.id] });
    },
  });

  // ── 폼 핸들러 ──
  const handleCreateFormChange = (
    field: keyof CourseCreateForm,
    value: string | number,
  ) => {
    setCreateForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createCourseMutation.mutate(createForm);
  };

  const handleEnrollStudent = () => {
    if (!enrollmentCourse || !newUserId.trim()) return;
    enrollStudentMutation.mutate({ courseId: enrollmentCourse.id, userId: newUserId.trim() });
  };

  const handleUnenroll = (enrollmentId: number) => {
    if (!enrollmentCourse) return;
    unenrollStudentMutation.mutate({ courseId: enrollmentCourse.id, enrollmentId });
  };

  const handleAssessmentChange = (
    enrollmentId: number,
    field: 'score' | 'grade',
    value: string | number,
  ) => {
    setEditingAssessment((prev) => ({
      ...prev,
      [enrollmentId]: {
        score: prev[enrollmentId]?.score ?? 0,
        grade: prev[enrollmentId]?.grade ?? 'F',
        [field]: value,
      },
    }));
  };

  const handleAssessmentSave = (enrollment: EnrollmentRecord) => {
    if (!enrollmentCourse) return;
    const assessment = editingAssessment[enrollment.id];
    if (!assessment) return;
    updateAssessmentMutation.mutate({
      enrollmentId: enrollment.id,
      courseId: enrollmentCourse.id,
      studentId: enrollment.studentId,
      score: assessment.score,
      grade: assessment.grade,
    });
  };

  // ── 상태 배지 ──
  const statusBadge = (status: string) => {
    if (status === 'ACTIVE') {
      return <span className="badge-sm badge-success">활성</span>;
    }
    return <span className="badge-sm badge-gray">비활성</span>;
  };

  return (
    <div className="space-y-6">
      {/* ── 페이지 헤더 ── */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            {t('admin.lmsPlatformTitle')}
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Open edX 연동 과정 및 수강생 관리
          </p>
        </div>
      </div>

      {/* ── 1. 플랫폼 개요 통계 카드 ── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          icon={BookOpen}
          label="총 과정"
          value={overview?.totalCourses?.toLocaleString() ?? '0'}
        />
        <StatCard
          icon={CheckCircle}
          label="활성 과정"
          value={overview?.activeCourses?.toLocaleString() ?? '0'}
          change={overview ? `${Math.round((overview.activeCourses / Math.max(overview.totalCourses, 1)) * 100)}%` : undefined}
          trend="up"
        />
        <StatCard
          icon={Users}
          label="총 수강생"
          value={overview?.totalStudents?.toLocaleString() ?? '0'}
        />
        <StatCard
          icon={GraduationCap}
          label="이수 완료율"
          value={overview ? `${overview.completionRate}%` : '0%'}
          trend={overview && overview.completionRate >= 70 ? 'up' : 'down'}
        />
      </div>

      {/* ── 2. 과정 관리 테이블 ── */}
      <section className="card space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">
            과정 목록
          </h2>
          <button
            onClick={() => setShowCreateModal(true)}
            className="btn-primary"
          >
            <Plus className="w-4 h-4" /> 과정 등록
          </button>
        </div>

        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">#</th>
                <th className="table-th">과정코드</th>
                <th className="table-th">과정명</th>
                <th className="table-th-center">카테고리</th>
                <th className="table-th-center">담당교수</th>
                <th className="table-th-center">수강인원</th>
                <th className="table-th-center">이수율</th>
                <th className="table-th-center">상태</th>
                <th className="table-th-center">관리</th>
              </tr>
            </thead>
            <tbody>
              {coursesLoading ? (
                <tr>
                  <td colSpan={9} className="table-td-center py-12 text-gray-400 text-sm">
                    {t('common.loading')}
                  </td>
                </tr>
              ) : courses && courses.length > 0 ? (
                courses.map((course, idx) => (
                  <tr key={course.id} className="table-row">
                    <td className="table-td-center text-xs text-gray-400">
                      {idx + 1}
                    </td>
                    <td className="table-td font-mono text-xs">{course.courseCode}</td>
                    <td className="table-td font-medium">{course.courseName}</td>
                    <td className="table-td-center">
                      <span className="badge-sm badge-info">{course.category}</span>
                    </td>
                    <td className="table-td-center text-sm">{course.instructor}</td>
                    <td className="table-td-center">{course.enrolledCount}</td>
                    <td className="table-td-center">
                      <div className="flex items-center justify-center gap-2">
                        <div className="w-16 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${
                              course.completionRate >= 80
                                ? 'bg-green-500'
                                : course.completionRate >= 50
                                  ? 'bg-blue-500'
                                  : 'bg-amber-500'
                            }`}
                            style={{ width: `${course.completionRate}%` }}
                          />
                        </div>
                        <span className="text-xs text-gray-500">
                          {course.completionRate}%
                        </span>
                      </div>
                    </td>
                    <td className="table-td-center">{statusBadge(course.status)}</td>
                    <td className="table-td-center">
                      <div className="flex items-center justify-center gap-1">
                        <button
                          className="p-1 text-gray-400 hover:text-primary-600 transition-colors"
                          title="상세보기"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => setEnrollmentCourse(course)}
                          className="p-1 text-gray-400 hover:text-blue-600 transition-colors"
                          title="수강자관리"
                        >
                          <UserCog className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={9} className="table-td-center py-12 text-gray-400 text-sm">
                    {t('common.noData')}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* ── 3. 과정 등록 모달 ── */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
            {/* 모달 헤더 */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-full bg-blue-100 dark:bg-blue-900/40">
                  <Plus className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                    신규 과정 등록
                  </h3>
                  <p className="text-[10px] text-gray-500">
                    LMS 플랫폼에 새로운 과정을 등록합니다.
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  setCreateForm({ ...INITIAL_FORM });
                }}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* 과정 등록 폼 */}
            <form onSubmit={handleCreateSubmit} className="space-y-4">
              {/* 과정명 */}
              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                  과정명 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={createForm.courseName}
                  onChange={(e) => handleCreateFormChange('courseName', e.target.value)}
                  placeholder="과정명을 입력하세요"
                  className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>

              {/* 설명 */}
              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                  설명
                </label>
                <textarea
                  value={createForm.description}
                  onChange={(e) => handleCreateFormChange('description', e.target.value)}
                  placeholder="과정 설명을 입력하세요"
                  rows={3}
                  className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white resize-none focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>

              {/* 2컬럼 그리드: 카테고리 + 담당교수 */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    카테고리 <span className="text-red-500">*</span>
                  </label>
                  <select
                    required
                    value={createForm.category}
                    onChange={(e) => handleCreateFormChange('category', e.target.value)}
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    {CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    담당교수명 <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={createForm.instructor}
                    onChange={(e) => handleCreateFormChange('instructor', e.target.value)}
                    placeholder="교수명"
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              </div>

              {/* 2컬럼 그리드: 시작일 + 종료일 */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    시작일 <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={createForm.startDate}
                    onChange={(e) => handleCreateFormChange('startDate', e.target.value)}
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    종료일 <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={createForm.endDate}
                    onChange={(e) => handleCreateFormChange('endDate', e.target.value)}
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              </div>

              {/* 3컬럼 그리드: 최대수강인원, 개설년도, 학기 */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    최대수강인원
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={500}
                    value={createForm.maxEnrollment}
                    onChange={(e) =>
                      handleCreateFormChange('maxEnrollment', parseInt(e.target.value, 10) || 1)
                    }
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    개설년도
                  </label>
                  <input
                    type="text"
                    value={createForm.year}
                    onChange={(e) => handleCreateFormChange('year', e.target.value)}
                    placeholder="2026"
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                    학기
                  </label>
                  <select
                    value={createForm.semester}
                    onChange={(e) => handleCreateFormChange('semester', e.target.value)}
                    className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    <option value="1">1학기</option>
                    <option value="2">2학기</option>
                    <option value="summer">하계 계절학기</option>
                    <option value="winter">동계 계절학기</option>
                  </select>
                </div>
              </div>

              {/* 캠퍼스 */}
              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                  캠퍼스 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={createForm.campus}
                  onChange={(e) => handleCreateFormChange('campus', e.target.value)}
                  placeholder="예: 서울강서, 인천, 대전, 광주, 부산"
                  className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>

              {/* 에러 표시 */}
              {createCourseMutation.isError && (
                <div className="p-3 text-sm text-red-600 bg-red-50 dark:bg-red-900/20 dark:text-red-400 rounded-lg">
                  과정 등록 중 오류가 발생했습니다. 다시 시도해주세요.
                </div>
              )}

              {/* 액션 버튼 */}
              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    setShowCreateModal(false);
                    setCreateForm({ ...INITIAL_FORM });
                  }}
                  className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600"
                >
                  {t('common.cancel')}
                </button>
                <button
                  type="submit"
                  disabled={createCourseMutation.isPending}
                  className="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {createCourseMutation.isPending ? '등록 중...' : '과정 등록'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── 4. 수강자 관리 모달 (수강 등록 + 성적 관리 포함) ── */}
      {enrollmentCourse && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl p-6 w-full max-w-4xl mx-4 max-h-[90vh] overflow-y-auto">
            {/* 모달 헤더 */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-full bg-purple-100 dark:bg-purple-900/40">
                  <UserCog className="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                    수강자 관리
                  </h3>
                  <p className="text-[10px] text-gray-500">
                    {enrollmentCourse.courseCode} - {enrollmentCourse.courseName}
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setEnrollmentCourse(null);
                  setEditingAssessment({});
                  setNewUserId('');
                }}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* 수강 등록 입력 */}
            <div className="flex items-center gap-3 mb-6 p-4 bg-gray-50 dark:bg-slate-800 rounded-lg">
              <UserPlus className="w-4 h-4 text-blue-500 flex-shrink-0" />
              <input
                type="text"
                value={newUserId}
                onChange={(e) => setNewUserId(e.target.value)}
                placeholder="등록할 학번 (User ID) 입력"
                className="flex-1 p-2 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleEnrollStudent();
                  }
                }}
              />
              <button
                onClick={handleEnrollStudent}
                disabled={!newUserId.trim() || enrollStudentMutation.isPending}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
              >
                {enrollStudentMutation.isPending ? '등록 중...' : '수강 등록'}
              </button>
            </div>

            {enrollStudentMutation.isError && (
              <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 dark:bg-red-900/20 dark:text-red-400 rounded-lg">
                수강 등록 중 오류가 발생했습니다.
              </div>
            )}

            {/* 수강자 목록 + 성적 관리 테이블 */}
            <div className="table-container">
              <table className="w-full">
                <thead className="table-head">
                  <tr>
                    <th className="table-th">학번</th>
                    <th className="table-th">이름</th>
                    <th className="table-th-center">학과</th>
                    <th className="table-th-center">진도율</th>
                    <th className="table-th-center">상태</th>
                    <th className="table-th-center">점수 (0-100)</th>
                    <th className="table-th-center">등급</th>
                    <th className="table-th-center">관리</th>
                  </tr>
                </thead>
                <tbody>
                  {enrollmentsLoading ? (
                    <tr>
                      <td colSpan={8} className="table-td-center py-8 text-gray-400 text-sm">
                        수강자 정보를 불러오는 중...
                      </td>
                    </tr>
                  ) : enrollments && enrollments.length > 0 ? (
                    enrollments.map((enrollment) => {
                      const assessment = editingAssessment[enrollment.id];
                      return (
                        <tr key={enrollment.id} className="table-row">
                          <td className="table-td font-mono text-xs">
                            {enrollment.studentId}
                          </td>
                          <td className="table-td font-medium">{enrollment.studentName}</td>
                          <td className="table-td-center text-xs">
                            {enrollment.department}
                          </td>
                          <td className="table-td-center">
                            <div className="flex items-center justify-center gap-2">
                              <div className="w-12 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                                <div
                                  className={`h-full rounded-full ${
                                    enrollment.progress >= 80
                                      ? 'bg-green-500'
                                      : enrollment.progress >= 50
                                        ? 'bg-blue-500'
                                        : 'bg-amber-500'
                                  }`}
                                  style={{ width: `${enrollment.progress}%` }}
                                />
                              </div>
                              <span className="text-xs text-gray-500">
                                {enrollment.progress}%
                              </span>
                            </div>
                          </td>
                          <td className="table-td-center">
                            <span
                              className={`badge-sm ${
                                enrollment.status === 'ACTIVE' || enrollment.status === '수강중'
                                  ? 'badge-success'
                                  : enrollment.status === 'COMPLETED' || enrollment.status === '이수완료'
                                    ? 'badge-info'
                                    : 'badge-gray'
                              }`}
                            >
                              {enrollment.status}
                            </span>
                          </td>
                          {/* ── 5. 성적 입력 영역 ── */}
                          <td className="table-td-center">
                            <input
                              type="number"
                              min={0}
                              max={100}
                              value={assessment?.score ?? ''}
                              onChange={(e) =>
                                handleAssessmentChange(
                                  enrollment.id,
                                  'score',
                                  Math.min(100, Math.max(0, parseInt(e.target.value, 10) || 0)),
                                )
                              }
                              placeholder="--"
                              className="w-16 p-1 text-center text-xs border border-gray-300 dark:border-slate-700 rounded bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                            />
                          </td>
                          <td className="table-td-center">
                            <select
                              value={assessment?.grade ?? ''}
                              onChange={(e) =>
                                handleAssessmentChange(enrollment.id, 'grade', e.target.value)
                              }
                              className="w-16 p-1 text-center text-xs border border-gray-300 dark:border-slate-700 rounded bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                            >
                              <option value="">--</option>
                              {GRADES.map((g) => (
                                <option key={g} value={g}>
                                  {g}
                                </option>
                              ))}
                            </select>
                          </td>
                          <td className="table-td-center">
                            <div className="flex items-center justify-center gap-1">
                              {/* 성적 저장 버튼 */}
                              <button
                                onClick={() => handleAssessmentSave(enrollment)}
                                disabled={
                                  !assessment ||
                                  (!assessment.score && !assessment.grade) ||
                                  updateAssessmentMutation.isPending
                                }
                                className="p-1 text-gray-400 hover:text-green-600 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                                title="성적 저장"
                              >
                                <Save className="w-3.5 h-3.5" />
                              </button>
                              {/* 수강 취소 버튼 */}
                              <button
                                onClick={() => handleUnenroll(enrollment.id)}
                                disabled={unenrollStudentMutation.isPending}
                                className="p-1 text-gray-400 hover:text-red-600 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                                title="수강 취소"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  ) : (
                    <tr>
                      <td colSpan={8} className="table-td-center py-8 text-gray-400 text-sm">
                        {t('common.noData')}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* 모달 하단 닫기 */}
            <div className="flex justify-end mt-6">
              <button
                onClick={() => {
                  setEnrollmentCourse(null);
                  setEditingAssessment({});
                  setNewUserId('');
                }}
                className="px-6 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600"
              >
                {t('common.close')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
