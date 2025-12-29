import React, { useEffect, useMemo, useState } from 'react';
import { ArrowLeft, FileText, BookOpen, Layers, Settings, Edit, Save, X, Trash2, Plus, Search } from 'lucide-react';
import { tutorLmsApi, type TutorProgramDetail, type TutorCourseRow } from '../api/tutorLmsApi';
import { CourseManagement } from './CourseManagement';

interface Course {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
  trainingPeriod: string;
  trainingLevel: string;
  trainingTarget: string;
  trainingGoal: string;
  instructor: string;
  year: string;
  students: number;
  subjects: number;
}

interface OperationalPlanProps {
  course: Course;
  onBack: () => void;
}

type LabelValue = { value?: string; label?: string };

type ProgramPlanV1 = {
  version?: number;
  basic?: {
    courseCategory?: LabelValue;
    classification?: LabelValue;
    courseName?: string;
    department?: string;
    major?: string;
    departmentName?: string;
    courseDescription?: string;
    instructor?: string;
  };
};

// CourseManagement에서 사용하는 Course 인터페이스
interface ManagementCourse {
  id: string;
  sourceType: 'haksa' | 'prism';
  courseId: string;
  courseType: string;
  subjectName: string;
  programId: number;
  programName: string;
  period: string;
  students: number;
  status: '대기' | '신청기간' | '학습기간' | '종료' | '-';
}

// 과정 분류 옵션
const COURSE_CATEGORY_OPTIONS = [
  { value: 'regular', label: '정규과정' },
  { value: 'non-regular', label: '비정규과정' },
];

const CLASSIFICATION_OPTIONS = [
  { value: 'degree', label: '학위' },
  { value: 'professional', label: '전문기술' },
  { value: 'master', label: '기능장' },
  { value: 'senior', label: '신중년' },
  { value: 'hightech', label: '하이테크' },
];

function safeParsePlanJson(raw: string | null | undefined): ProgramPlanV1 | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed as ProgramPlanV1;
  } catch {
    return null;
  }
}

function toManagementCourse(row: TutorCourseRow, programName: string): ManagementCourse {
  return {
    id: String(row.id),
    sourceType: 'prism',
    courseId: row.course_id_conv || row.course_cd || String(row.id),
    courseType: [row.course_type_conv, row.onoff_type_conv].filter(Boolean).join(' / ') || '미지정',
    subjectName: row.course_nm_conv || row.course_nm || '-',
    programId: row.program_id || 0,
    programName: programName,
    period: row.period_conv || '-',
    students: row.student_cnt || 0,
    status: (row.status_label as ManagementCourse['status']) || '대기',
  };
}

export function OperationalPlan({ course, onBack }: OperationalPlanProps) {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [detail, setDetail] = useState<TutorProgramDetail | null>(null);
  
  // 소속 과목 관련 상태
  const [courses, setCourses] = useState<TutorCourseRow[]>([]);
  const [coursesLoading, setCoursesLoading] = useState(false);
  
  // 과목 관리 화면 상태
  const [managingCourse, setManagingCourse] = useState<ManagementCourse | null>(null);
  
  // 소속과목 추가 모달 상태
  const [showAddSubjectModal, setShowAddSubjectModal] = useState(false);
  const [availableCourses, setAvailableCourses] = useState<TutorCourseRow[]>([]);
  const [coursesSearchTerm, setCoursesSearchTerm] = useState('');
  const [loadingAvailableCourses, setLoadingAvailableCourses] = useState(false);
  const [addingCourseId, setAddingCourseId] = useState<number | null>(null);
  const [detachingCourseId, setDetachingCourseId] = useState<number | null>(null);
  
  // 편집 모드 상태
  const [isEditing, setIsEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [editForm, setEditForm] = useState({
    courseName: '',
    courseCategory: '',
    classification: '',
    departmentName: '',
    major: '',
    courseDescription: '',
  });

  // 삭제 핸들러
  const handleDelete = async () => {
    if (!detail) return;
    
    const confirmed = window.confirm('정말로 이 과정을 삭제하시겠습니까?\n삭제된 과정은 복구할 수 없습니다.');
    if (!confirmed) return;

    setDeleting(true);
    try {
      const res = await tutorLmsApi.deleteProgram({ id: Number(course.id) });

      if (res.rst_code !== '0000') {
        throw new Error(res.rst_message);
      }

      // 삭제 성공 시 목록으로 돌아가기
      alert('과정이 삭제되었습니다.');
      onBack();
    } catch (e) {
      alert(e instanceof Error ? e.message : '삭제 중 오류가 발생했습니다.');
    } finally {
      setDeleting(false);
    }
  };

  const fetchData = async () => {
    setLoading(true);
    setErrorMessage(null);

    try {
      const id = Number(course.id);
      if (!Number.isFinite(id) || id <= 0) throw new Error('과정 ID가 올바르지 않습니다.');

      const [programRes, coursesRes] = await Promise.all([
        tutorLmsApi.getProgram(id),
        tutorLmsApi.getProgramCourses({ programId: id }),
      ]);

      if (programRes.rst_code !== '0000') throw new Error(programRes.rst_message);
      // 왜: program_view.jsp는 DataSet을 반환하므로 배열일 수 있음. 첫 번째 요소 추출.
      const data = programRes.rst_data;
      const detailData = Array.isArray(data) ? data[0] : data;
      setDetail(detailData ?? null);

      if (coursesRes.rst_code === '0000') {
        setCourses(coursesRes.rst_data ?? []);
      }
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
      setCoursesLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [course.id]);

  const plan = useMemo(() => safeParsePlanJson(detail?.plan_json), [detail?.plan_json]);
  const title = detail?.course_nm ?? course.name;

  // 편집 모드 진입 시 폼 초기화
  const startEditing = () => {
    // plan_json을 직접 파싱하여 최신 데이터 사용
    const currentPlan = safeParsePlanJson(detail?.plan_json);
    setEditForm({
      courseName: detail?.course_nm ?? course.name ?? '',
      courseCategory: currentPlan?.basic?.courseCategory?.value ?? '',
      classification: currentPlan?.basic?.classification?.value ?? '',
      departmentName: currentPlan?.basic?.departmentName ?? '',
      major: currentPlan?.basic?.major ?? '',
      courseDescription: currentPlan?.basic?.courseDescription ?? '',
    });
    setIsEditing(true);
  };

  const cancelEditing = () => {
    setIsEditing(false);
  };

  const handleSave = async () => {
    if (!detail) return;
    
    setSaving(true);
    try {
      // 기존 plan_json을 직접 파싱하여 병합
      const currentPlan = safeParsePlanJson(detail?.plan_json);
      const updatedPlan: ProgramPlanV1 = {
        ...currentPlan,
        version: 1,
        basic: {
          ...currentPlan?.basic,
          courseCategory: {
            value: editForm.courseCategory,
            label: COURSE_CATEGORY_OPTIONS.find(o => o.value === editForm.courseCategory)?.label ?? editForm.courseCategory,
          },
          classification: {
            value: editForm.classification,
            label: CLASSIFICATION_OPTIONS.find(o => o.value === editForm.classification)?.label ?? editForm.classification,
          },
          departmentName: editForm.departmentName,
          major: editForm.major,
          courseDescription: editForm.courseDescription,
        },
      };

      const res = await tutorLmsApi.modifyProgram({
        id: Number(course.id),
        courseName: editForm.courseName.trim(),
        planJson: JSON.stringify(updatedPlan),
      });

      if (res.rst_code !== '0000') {
        throw new Error(res.rst_message);
      }

      // 성공 시 데이터 다시 불러오기 (fetchData 완료 후 편집 모드 종료)
      await fetchData();
      setIsEditing(false);
    } catch (e) {
      alert(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  // 소속과목 추가 모달 열기
  const openAddSubjectModal = async () => {
    setShowAddSubjectModal(true);
    setCoursesSearchTerm('');
    setLoadingAvailableCourses(true);
    
    try {
      const res = await tutorLmsApi.getMyCourses({});
      if (res.rst_code === '0000') {
        // 이미 소속된 과목 제외
        const existingIds = new Set(courses.map(c => c.id));
        const filtered = (res.rst_data ?? []).filter(c => !existingIds.has(c.id));
        setAvailableCourses(filtered);
      }
    } catch (e) {
      console.error('과목 목록 조회 실패:', e);
    } finally {
      setLoadingAvailableCourses(false);
    }
  };

  // 과목을 과정에 연결
  const handleAddSubject = async (courseId: number) => {
    setAddingCourseId(courseId);
    try {
      const programId = Number(course.id);
      const res = await tutorLmsApi.setCourseProgram({ courseId, programId });
      if (res.rst_code !== '0000') {
        throw new Error(res.rst_message);
      }
      // 목록 갱신
      await fetchData();
      // 추가된 과목은 available 목록에서 제거
      setAvailableCourses(prev => prev.filter(c => c.id !== courseId));
    } catch (e) {
      alert(e instanceof Error ? e.message : '과목 추가 중 오류가 발생했습니다.');
    } finally {
      setAddingCourseId(null);
    }
  };

  // 과목을 과정에서 분리 (연결 해제)
  const handleDetachSubject = async (courseId: number) => {
    const confirmed = window.confirm('이 과목을 과정에서 분리하시겠습니까?');
    if (!confirmed) return;

    setDetachingCourseId(courseId);
    try {
      const res = await tutorLmsApi.setCourseProgram({ courseId, programId: 0 });
      if (res.rst_code !== '0000') {
        throw new Error(res.rst_message);
      }
      // 목록 갱신
      await fetchData();
    } catch (e) {
      alert(e instanceof Error ? e.message : '과목 분리 중 오류가 발생했습니다.');
    } finally {
      setDetachingCourseId(null);
    }
  };

  // 검색어로 필터링된 과목 목록
  const filteredAvailableCourses = useMemo(() => {
    if (!coursesSearchTerm.trim()) return availableCourses;
    const term = coursesSearchTerm.toLowerCase();
    return availableCourses.filter(c =>
      (c.course_nm?.toLowerCase().includes(term)) ||
      (c.course_id_conv?.toLowerCase().includes(term)) ||
      (c.course_cd?.toLowerCase().includes(term))
    );
  }, [availableCourses, coursesSearchTerm]);

  // 과목 관리 화면이 선택되었으면 CourseManagement 표시
  if (managingCourse) {
    return (
      <CourseManagement
        course={managingCourse}
        onBack={() => setManagingCourse(null)}
      />
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="flex items-center gap-2 px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>목록으로</span>
          </button>
          <div className="flex-1">
            <h2 className="text-gray-900">과정 상세</h2>
            {isEditing ? (
              <input
                type="text"
                value={editForm.courseName}
                onChange={(e) => setEditForm({ ...editForm, courseName: e.target.value })}
                className="mt-1 px-3 py-1.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900"
                placeholder="과정명 입력"
              />
            ) : (
              <p className="text-sm text-gray-600">{title}</p>
            )}
          </div>
        </div>

        {!loading && !errorMessage && detail && !isEditing && (
          <div className="flex items-center gap-2">
            <button
              onClick={handleDelete}
              disabled={deleting}
              className="flex items-center gap-2 px-4 py-2 text-red-700 bg-red-50 hover:bg-red-100 rounded-lg transition-colors disabled:opacity-50"
            >
              <Trash2 className="w-4 h-4" />
              <span>{deleting ? '삭제 중...' : '삭제'}</span>
            </button>
            <button
              onClick={startEditing}
              className="flex items-center gap-2 px-4 py-2 text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
            >
              <Edit className="w-4 h-4" />
              <span>수정</span>
            </button>
          </div>
        )}
        {isEditing && (
          <div className="flex items-center gap-2">
            <button
              onClick={cancelEditing}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors disabled:opacity-50"
            >
              <X className="w-4 h-4" />
              <span>취소</span>
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? '저장 중...' : '저장'}</span>
            </button>
          </div>
        )}
      </div>

      {loading && (
        <div className="bg-white rounded-lg border border-gray-200 p-10 text-center text-gray-600">
          불러오는 중...
        </div>
      )}

      {!loading && errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
          {errorMessage}
        </div>
      )}

      {!loading && !errorMessage && !detail && (
        <div className="bg-white rounded-lg border border-gray-200 p-10 text-center text-gray-600">
          과정 정보를 찾을 수 없습니다.
        </div>
      )}

      {!loading && !errorMessage && detail && (
        <div className="space-y-6">
          {/* 기본 정보 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <div className="bg-gray-50 border-b border-gray-200 px-6 py-4">
              <div className="flex items-center gap-3">
                <BookOpen className="w-5 h-5 text-blue-600" />
                <h3 className="text-lg text-gray-900">기본 정보</h3>
              </div>
            </div>
            <div className="p-6">
              {isEditing ? (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm text-gray-700 mb-2">과정 유형</label>
                    <select
                      value={editForm.courseCategory}
                      onChange={(e) => setEditForm({ ...editForm, courseCategory: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">선택하세요</option>
                      {COURSE_CATEGORY_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value}>{opt.label}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-2">과정 분류</label>
                    <select
                      value={editForm.classification}
                      onChange={(e) => setEditForm({ ...editForm, classification: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">선택하세요</option>
                      {CLASSIFICATION_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value}>{opt.label}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-2">학과명</label>
                    <input
                      type="text"
                      value={editForm.departmentName}
                      onChange={(e) => setEditForm({ ...editForm, departmentName: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="학과명 입력"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-2">전공/직종</label>
                    <input
                      type="text"
                      value={editForm.major}
                      onChange={(e) => setEditForm({ ...editForm, major: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="전공/직종 입력"
                    />
                  </div>
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex border-b border-gray-100 py-3">
                    <span className="w-28 text-gray-600 text-sm">과정 유형</span>
                    <span className="flex-1 text-gray-900">{plan?.basic?.courseCategory?.label ?? '-'}</span>
                  </div>
                  <div className="flex border-b border-gray-100 py-3">
                    <span className="w-28 text-gray-600 text-sm">과정 분류</span>
                    <span className="flex-1 text-gray-900">{plan?.basic?.classification?.label ?? '-'}</span>
                  </div>
                  <div className="flex border-b border-gray-100 py-3">
                    <span className="w-28 text-gray-600 text-sm">학과명</span>
                    <span className="flex-1 text-gray-900">{plan?.basic?.departmentName ?? '-'}</span>
                  </div>
                  <div className="flex border-b border-gray-100 py-3">
                    <span className="w-28 text-gray-600 text-sm">전공/직종</span>
                    <span className="flex-1 text-gray-900">{plan?.basic?.major ?? '-'}</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* 과정설명 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <div className="bg-gray-50 border-b border-gray-200 px-6 py-4">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-blue-600" />
                <h3 className="text-lg text-gray-900">과정설명</h3>
              </div>
            </div>
            <div className="p-6">
              {isEditing ? (
                <textarea
                  value={editForm.courseDescription}
                  onChange={(e) => setEditForm({ ...editForm, courseDescription: e.target.value })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-y min-h-[120px]"
                  placeholder="과정에 대한 소개 및 설명을 입력하세요"
                  rows={5}
                />
              ) : plan?.basic?.courseDescription ? (
                <p className="text-gray-700 whitespace-pre-line leading-relaxed">
                  {plan.basic.courseDescription}
                </p>
              ) : (
                <p className="text-gray-400 italic">과정설명이 등록되지 않았습니다.</p>
              )}
            </div>
          </div>

          {/* 소속 과목 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <div className="bg-gray-50 border-b border-gray-200 px-6 py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Layers className="w-5 h-5 text-blue-600" />
                  <h3 className="text-lg text-gray-900">소속 과목</h3>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm text-gray-500">{courses.length}개 과목</span>
                  <button
                    onClick={openAddSubjectModal}
                    className="flex items-center gap-1 px-3 py-1.5 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    <span>과목 추가</span>
                  </button>
                </div>
              </div>
            </div>
            <div className="p-6">
              {coursesLoading ? (
                <p className="text-gray-500 text-center py-4">불러오는 중...</p>
              ) : courses.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-400 italic mb-4">소속된 과목이 없습니다.</p>
                  <button
                    onClick={openAddSubjectModal}
                    className="inline-flex items-center gap-2 px-4 py-2 text-sm text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    <span>과목 추가하기</span>
                  </button>
                </div>
              ) : (
                <div className="space-y-3">
                  {courses.map((c) => (
                    <div
                      key={c.id}
                      className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200"
                    >
                      <div className="flex-1">
                        <p className="text-gray-900 font-medium">{c.course_nm}</p>
                        <p className="text-sm text-gray-500">
                          {c.course_id_conv ?? c.course_cd ?? `ID: ${c.id}`}
                          {c.year && ` · ${c.year}년`}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-1 text-xs rounded ${
                          c.status_label === '진행중' ? 'bg-green-100 text-green-700' :
                          c.status_label === '종료' ? 'bg-gray-100 text-gray-600' :
                          'bg-blue-100 text-blue-700'
                        }`}>
                          {c.status_label ?? '대기'}
                        </span>
                        <button
                          onClick={() => setManagingCourse(toManagementCourse(c, title))}
                          className="flex items-center gap-1 px-3 py-1.5 text-xs text-blue-700 bg-blue-50 rounded hover:bg-blue-100 transition-colors"
                          title="과목 관리"
                        >
                          <Settings className="w-4 h-4" />
                          <span>관리</span>
                        </button>
                        <button
                          onClick={() => handleDetachSubject(c.id)}
                          disabled={detachingCourseId === c.id}
                          className="flex items-center gap-1 px-3 py-1.5 text-xs text-red-700 bg-red-50 rounded hover:bg-red-100 transition-colors disabled:opacity-50"
                          title="과정에서 분리"
                        >
                          <Trash2 className="w-4 h-4" />
                          <span>{detachingCourseId === c.id ? '분리 중...' : '분리'}</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* 과목 추가 모달 */}
      {showAddSubjectModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">소속 과목 추가</h3>
              <button
                onClick={() => setShowAddSubjectModal(false)}
                className="p-2 text-gray-500 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 border-b border-gray-200">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="과목명 또는 과목코드로 검색..."
                  value={coursesSearchTerm}
                  onChange={(e) => setCoursesSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-4">
              {loadingAvailableCourses ? (
                <p className="text-center text-gray-500 py-8">과목 목록을 불러오는 중...</p>
              ) : filteredAvailableCourses.length === 0 ? (
                <p className="text-center text-gray-400 py-8">
                  {coursesSearchTerm ? '검색 결과가 없습니다.' : '추가할 수 있는 과목이 없습니다.'}
                </p>
              ) : (
                <div className="space-y-2">
                  {filteredAvailableCourses.map((c) => (
                    <div
                      key={c.id}
                      className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:bg-gray-100 transition-colors"
                    >
                      <div className="flex-1">
                        <p className="text-gray-900 font-medium">{c.course_nm}</p>
                        <p className="text-sm text-gray-500">
                          {c.course_id_conv ?? c.course_cd ?? `ID: ${c.id}`}
                          {c.year && ` · ${c.year}년`}
                        </p>
                      </div>
                      <button
                        onClick={() => handleAddSubject(c.id)}
                        disabled={addingCourseId === c.id}
                        className="flex items-center gap-1 px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
                      >
                        <Plus className="w-4 h-4" />
                        <span>{addingCourseId === c.id ? '추가 중...' : '추가'}</span>
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="p-4 border-t border-gray-200 bg-gray-50">
              <button
                onClick={() => setShowAddSubjectModal(false)}
                className="w-full px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                닫기
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
