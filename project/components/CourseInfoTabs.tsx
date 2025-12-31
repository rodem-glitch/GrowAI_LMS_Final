import React, { useEffect, useMemo, useState } from 'react';
import { Edit, Save } from 'lucide-react';
import { tutorLmsApi, type HaksaEvalSettings, type TutorCertificateTemplateRow, type TutorCourseInfoDetail } from '../api/tutorLmsApi';
import { CourseSelectionModal } from './CourseSelectionModal';
import { buildHaksaCourseKey } from '../utils/haksa';

type SubTab = 'basic' | 'evaluation' | 'completion' | 'certificate';

type ProgramOption = {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
};

function toInt(value: unknown, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

function toYn(value: unknown, fallback: 'Y' | 'N' = 'N'): 'Y' | 'N' {
  return value === 'Y' ? 'Y' : value === 'N' ? 'N' : fallback;
}

function clamp0to100(value: number) {
  if (!Number.isFinite(value)) return 0;
  return Math.min(100, Math.max(0, value));
}

function getFieldValue(row: unknown, key: string) {
  // 왜: 일부 API는 DataSet 컬럼명이 대문자(ASSIGN_PROGRESS)로 내려와서
  //     프론트에서 `assign_progress` 같은 소문자 키로 읽으면 undefined가 됩니다.
  //     그래서 "소문자 키/대문자 키" 둘 다 지원해서 실제 DB 값을 화면에 반영합니다.
  const normalized = Array.isArray(row) ? row[0] : row;
  if (!normalized || typeof normalized !== 'object') return undefined;
  const obj = normalized as Record<string, unknown>;
  return obj[key] ?? obj[key.toUpperCase()];
}

function getStr(row: unknown, key: string, fallback = '') {
  const v = getFieldValue(row, key);
  if (v === undefined || v === null) return fallback;
  return String(v);
}

function getInt(row: unknown, key: string, fallback = 0) {
  return toInt(getFieldValue(row, key), fallback);
}

function getYn(row: unknown, key: string, fallback: 'Y' | 'N' = 'N') {
  return toYn(getFieldValue(row, key), fallback);
}

// 과목정보 메인 탭
export function CourseInfoTab({
  course,
  onCourseUpdated,
  initialSubTab = 'basic',
}: {
  course: any;
  onCourseUpdated?: (nextCourse: any) => void;
  initialSubTab?: SubTab;
}) {
  const isHaksa = course?.sourceType === 'haksa' && !course?.mappedCourseId;
  const courseId = toInt(course?.mappedCourseId ?? course?.id, 0);
  const [subTab, setSubTab] = useState<SubTab>(initialSubTab);
  const [detail, setDetail] = useState<TutorCourseInfoDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const passYn = getYn(detail, 'pass_yn', 'N') === 'Y';

  const fetchCourseInfo = async () => {
    // 왜: 학사 데이터는 외부 시스템(e-poly) 연동이라 상세 정보 API가 없으므로, 목록에서 받은 정보만 표시합니다.
    if (isHaksa) {
      setDetail(null);
      setLoading(false);
      return;
    }

    // 왜: 목록에서 넘어온 `course`에는 과목소개/평가/증명서 같은 상세 컬럼이 없어서, 항상 DB에서 다시 조회해야 합니다.
    if (courseId <= 0) {
      setDetail(null);
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }

    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getCourseInfo({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setDetail(res.rst_data ?? null);
    } catch (e) {
      setDetail(null);
      setErrorMessage(e instanceof Error ? e.message : '과목 정보를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // 왜: 관리자에서 평가/수료 기준을 바꿔도 탭 이동 시 최신 값을 다시 불러오도록 합니다.
    void fetchCourseInfo();
  }, [courseId, subTab]);

  useEffect(() => {
    // 왜: 합격증 탭은 pass_yn=Y일 때만 의미가 있습니다.
    if (subTab === 'certificate' && !passYn) setSubTab('evaluation');
  }, [passYn, subTab]);

  // 왜: 좌측 사이드바에서 하위 탭을 선택하면 initialSubTab이 변경되므로, subTab 상태를 동기화합니다.
  useEffect(() => {
    setSubTab(initialSubTab);
  }, [initialSubTab]);

  return (
    <div className="space-y-6">
      {/* 왜: 하위 탭 네비게이션은 좌측 사이드바로 이동했으므로 제거합니다. */}

      {loading && (
        <div className="bg-white rounded-lg border border-gray-200 p-10 text-center text-gray-600">
          불러오는 중...
        </div>
      )}

      {!loading && errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      {!loading && !errorMessage && subTab === 'basic' && (
        <BasicInfoTab
          course={course}
          courseId={courseId}
          detail={detail}
          onReload={fetchCourseInfo}
          onCourseUpdated={onCourseUpdated}
          isHaksa={isHaksa}
        />
      )}

      {!loading && !errorMessage && subTab === 'evaluation' && (
        isHaksa ? (
          <HaksaEvaluationTab course={course} />
        ) : (
          <EvaluationTab courseId={courseId} detail={detail} onReload={fetchCourseInfo} />
        )
      )}

      {!loading && !errorMessage && !isHaksa && subTab === 'completion' && (
        <CompletionCertificateTab courseId={courseId} detail={detail} onReload={fetchCourseInfo} />
      )}

      {!loading && !errorMessage && !isHaksa && subTab === 'certificate' && passYn && (
        <PassCertificateTab courseId={courseId} detail={detail} onReload={fetchCourseInfo} />
      )}
    </div>
  );
}

// 기본 정보 탭
function BasicInfoTab({
  course,
  courseId,
  detail,
  onReload,
  onCourseUpdated,
  isHaksa = false,
}: {
  course: any;
  courseId: number;
  detail: TutorCourseInfoDetail | null;
  onReload: () => Promise<void> | void;
  onCourseUpdated?: (nextCourse: any) => void;
  isHaksa?: boolean;
}) {
  const [isCourseModalOpen, setIsCourseModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [content1, setContent1] = useState('');
  const [content2, setContent2] = useState('');
  
  // 편집 모드 상태
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState({
    courseName: '',
    courseType: '',
    programId: 0,
    programName: '',
  });

  useEffect(() => {
    setContent1(getStr(detail, 'content1', ''));
    setContent2(getStr(detail, 'content2', ''));
  }, [detail]);

  // 편집 모드 진입 시 폼 초기화
  const startEditing = () => {
    setEditForm({
      courseName: course?.subjectName ?? getStr(detail, 'course_nm', ''),
      courseType: course?.courseType ?? '',
      programId: toInt(course?.programId ?? 0, 0),
      programName: course?.programName ?? getStr(detail, 'program_nm', '-'),
    });
    setIsEditing(true);
  };

  const cancelEditing = () => {
    setIsEditing(false);
    setErrorMessage(null);
  };

  const selectedProgram: ProgramOption | null =
    isEditing && editForm.programId > 0
      ? {
          id: String(editForm.programId),
          classification: '과정',
          name: editForm.programName,
          department: '-',
          major: '-',
          departmentName: '-',
        }
      : course && 0 < toInt(course.programId, 0)
      ? {
          id: String(course.programId),
          classification: '과정',
          name: course.programName,
          department: '-',
          major: '-',
          departmentName: '-',
        }
      : null;

  const handleProgramSelect = async (program: ProgramOption | null) => {
    if (isEditing) {
      // 편집 모드에서는 폼 상태만 업데이트
      setEditForm(prev => ({
        ...prev,
        programId: program ? toInt(program.id, 0) : 0,
        programName: program ? program.name : '-',
      }));
      setIsCourseModalOpen(false);
      return;
    }

    // 기존 로직 (편집 모드 아닐 때)
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }

    const programId = program ? toInt(program.id, 0) : 0;
    if (program && !programId) {
      setErrorMessage('과정 ID가 올바르지 않습니다.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.setCourseProgram({ courseId, programId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      onCourseUpdated?.({
        ...course,
        programId,
        programName: program ? program.name : '-',
      });
      await onReload();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '소속 과정 변경 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
      setIsCourseModalOpen(false);
    }
  };

  // 편집 모드에서 저장
  const handleSaveEdit = async () => {
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      // 소속 과정 변경
      const currentProgramId = toInt(course?.programId ?? 0, 0);
      if (editForm.programId !== currentProgramId) {
        const res = await tutorLmsApi.setCourseProgram({ courseId, programId: editForm.programId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
      }

      onCourseUpdated?.({
        ...course,
        programId: editForm.programId,
        programName: editForm.programName,
      });
      await onReload();
      setIsEditing(false);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  const handleSaveContents = async () => {
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.updateCourseInfo({ courseId, content1, content2 });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      alert('저장되었습니다.');
      await onReload();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  const subjectName = course?.subjectName ?? detail?.course_nm ?? '-';
  const courseIdLabel =
    course?.courseId ??
    detail?.course_id_conv ??
    detail?.course_cd ??
    (detail?.id ? String(detail.id) : courseId ? String(courseId) : '-');

  const programName = course?.programName ?? detail?.program_nm ?? '-';
  const period = course?.period ?? detail?.period_conv ?? '-';
  const students = toInt(course?.students ?? detail?.student_cnt, 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-gray-900">과목 기본 정보</h3>
        {/* 왜: 학사 데이터는 외부 시스템(e-poly)에서 관리되므로 수정 버튼을 숨깁니다. */}
        {!isHaksa && !isEditing && (
          <button
            onClick={startEditing}
            disabled={saving}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <Edit className="w-4 h-4" />
            <span>수정</span>
          </button>
        )}
        {!isHaksa && isEditing && (
          <div className="flex items-center gap-2">
            <button
              onClick={cancelEditing}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-60"
            >
              <span>취소</span>
            </button>
            <button
              onClick={() => void handleSaveEdit()}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? '저장 중...' : '저장'}</span>
            </button>
          </div>
        )}
      </div>


      {/* 왜: 학사 연동 데이터임을 사용자에게 알려줍니다. */}
      {isHaksa && (
        <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm">
          <strong>학사 연동 과목</strong>: 이 과목은 학사 시스템(e-poly)에서 연동된 데이터입니다. 기본 정보는 읽기 전용으로 표시됩니다.
        </div>
      )}

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      {/* ===== 학사 과목: LMS_COURSE_VIEW 25개 필드 그룹별 표시 ===== */}
      {isHaksa ? (
        <div className="space-y-6">
          {/* 그룹 1: 기본 정보 */}
          <div className="border border-gray-200 rounded-lg p-5">
            <h4 className="text-gray-900 font-medium mb-4 pb-2 border-b border-gray-100">📚 기본 정보</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌명(한글)</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaCourseName || subjectName || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌명(영문)</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaCourseEname || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaCourseCode || courseIdLabel || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">분반코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaBunbanCode || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌형태</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaCategory || course?.courseType || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">폐강여부</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-sm">
                  <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${course?.haksaVisible === 'Y' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {course?.haksaVisible === 'Y' ? '정상' : course?.haksaVisible === 'N' ? '폐강' : course?.haksaVisible || '-'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* 그룹 2: 개설 정보 */}
          <div className="border border-gray-200 rounded-lg p-5">
            <h4 className="text-gray-900 font-medium mb-4 pb-2 border-b border-gray-100">📅 개설 정보</h4>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">개설연도</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaOpenYear || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">개설학기</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaOpenTerm || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">주차</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaWeek || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌시작일</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaStartdate || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강좌종료일</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaEnddate || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">대상학년</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaGrade ? `${course.haksaGrade}학년` : '-'}</div>
              </div>
            </div>
          </div>

          {/* 그룹 3: 학과/과정 정보 */}
          <div className="border border-gray-200 rounded-lg p-5">
            <h4 className="text-gray-900 font-medium mb-4 pb-2 border-b border-gray-100">🏫 학과/과정 정보</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">학과/전공명</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaDeptName || programName || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">학과/전공코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaDeptCode || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">단과대학명</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaGradName || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">단과대학코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaGradCode || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">과목구분명</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaCurriculumName || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">과목구분코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaCurriculumCode || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">학부/대학원 구분코드</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm font-mono">{course?.haksaGroupCode || '-'}</div>
              </div>
            </div>
          </div>

          {/* 그룹 4: 강의 정보 */}
          <div className="border border-gray-200 rounded-lg p-5">
            <h4 className="text-gray-900 font-medium mb-4 pb-2 border-b border-gray-100">🎓 강의 정보</h4>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">강의요일</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaDayCd || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강의시간</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaHour1 || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강의실</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaClassroom || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">영문강좌여부</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-sm">
                  <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${course?.haksaEnglish === 'Y' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}>
                    {course?.haksaEnglish === 'Y' ? '영문강좌' : course?.haksaEnglish === 'N' ? '국문강좌' : course?.haksaEnglish || '-'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* 그룹 5: 기타 정보 */}
          <div className="border border-gray-200 rounded-lg p-5">
            <h4 className="text-gray-900 font-medium mb-4 pb-2 border-b border-gray-100">📋 기타 정보</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">강의계획서 구분</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-gray-900 text-sm">{course?.haksaTypeSyllabus || '-'}</div>
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">강의계획서 존재여부</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-lg text-sm">
                  <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${course?.haksaIsSyllabus === 'Y' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                    {course?.haksaIsSyllabus === 'Y' ? '있음' : course?.haksaIsSyllabus === 'N' ? '없음' : course?.haksaIsSyllabus || '-'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : isEditing ? (
        /* ===== 프리즘 과목: 편집 모드 ===== */
        <div className="grid grid-cols-2 gap-6">
          <div>
            <label className="block text-sm text-gray-700 mb-2">과목명</label>
            <div className="px-4 py-3 bg-gray-100 rounded-lg text-gray-500">{subjectName}</div>
            <p className="text-xs text-gray-400 mt-1">과목명은 수정할 수 없습니다.</p>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정ID</label>
            <div className="px-4 py-3 bg-gray-100 rounded-lg text-gray-500">{courseIdLabel}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정구분</label>
            <div className="px-4 py-3 bg-gray-100 rounded-lg text-gray-500">{course?.courseType ?? '-'}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">소속 과정명</label>
            <button
              type="button"
              onClick={() => setIsCourseModalOpen(true)}
              className="w-full px-4 py-3 bg-white border border-gray-300 rounded-lg text-gray-900 text-left hover:border-blue-500 hover:ring-1 hover:ring-blue-500 transition-colors flex items-center justify-between"
            >
              <span>{editForm.programName}</span>
              <Edit className="w-4 h-4 text-gray-400" />
            </button>
            <p className="text-xs text-blue-600 mt-1">클릭하여 소속 과정을 변경할 수 있습니다.</p>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육기간</label>
            <div className="px-4 py-3 bg-gray-100 rounded-lg text-gray-500">{period}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">수강인원</label>
            <div className="px-4 py-3 bg-gray-100 rounded-lg text-gray-500">{students}명</div>
          </div>
        </div>
      ) : (
        /* ===== 프리즘 과목: 읽기 모드 ===== */
        <div className="grid grid-cols-2 gap-6">
          <div>
            <label className="block text-sm text-gray-700 mb-2">과목명</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{subjectName}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정ID</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{courseIdLabel}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정구분</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{course?.courseType ?? '-'}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">소속 과정명</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{programName}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육기간</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{period}</div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">수강인원</label>
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">{students}명</div>
          </div>
        </div>
      )}

      <CourseSelectionModal
        isOpen={isCourseModalOpen}
        onClose={() => setIsCourseModalOpen(false)}
        onSelect={(program) => {
          void handleProgramSelect(program as ProgramOption | null);
        }}
        selectedCourse={selectedProgram}
      />

      {/* 왜: 학사 데이터는 과목 소개/학습 목표를 수정할 수 없습니다. */}
      {!isHaksa && (
        <div className="border border-gray-200 rounded-lg p-6 space-y-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">과목 소개</label>
            <textarea
              value={content1}
              onChange={(e) => setContent1(e.target.value)}
              rows={6}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="과목 소개를 입력해 주세요."
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">학습 목표</label>
            <textarea
              value={content2}
              onChange={(e) => setContent2(e.target.value)}
              rows={6}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="학습 목표를 입력해 주세요."
            />
          </div>
          <div className="flex justify-end">
            <button
              onClick={() => void handleSaveContents()}
              disabled={saving}
              className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? '저장 중...' : '저장'}</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function EvaluationTab({
  courseId,
  detail,
  onReload,
}: {
  courseId: number;
  detail: TutorCourseInfoDetail | null;
  onReload: () => Promise<void> | void;
}) {
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [form, setForm] = useState({
    assignProgress: 100,
    assignExam: 0,
    assignHomework: 0,
    assignForum: 0,
    assignEtc: 0,

    limitTotalScore: 60,
    limitProgress: 60,


    completeLimitProgress: 60,
    completeLimitTotalScore: 60,

    assignSurveyYn: 'N' as 'Y' | 'N',
    pushSurveyYn: 'N' as 'Y' | 'N',
    passYn: 'N' as 'Y' | 'N',
  });

  useEffect(() => {
    // 왜: DB 값을 그대로 가져와서, 사용자가 “현재 설정”을 보고 수정할 수 있어야 합니다.
    if (!detail) return;
    setForm({
      assignProgress: getInt(detail, 'assign_progress', 100),
      assignExam: getInt(detail, 'assign_exam', 0),
      assignHomework: getInt(detail, 'assign_homework', 0),
      assignForum: getInt(detail, 'assign_forum', 0),
      assignEtc: getInt(detail, 'assign_etc', 0),

      limitTotalScore: getInt(detail, 'limit_total_score', 60),
      limitProgress: getInt(detail, 'limit_progress', 60),

      completeLimitProgress: getInt(detail, 'complete_limit_progress', 60),
      completeLimitTotalScore: getInt(detail, 'complete_limit_total_score', 60),

      assignSurveyYn: getYn(detail, 'assign_survey_yn', 'N'),
      pushSurveyYn: getYn(detail, 'push_survey_yn', 'N'),
      passYn: getYn(detail, 'pass_yn', 'N'),
    });
  }, [detail]);

  const totalAssignScore = useMemo(
    () => form.assignProgress + form.assignExam + form.assignHomework + form.assignForum + form.assignEtc,
    [form.assignEtc, form.assignExam, form.assignForum, form.assignHomework, form.assignProgress],
  );
  const passEnabled = form.passYn === 'Y';

  const handleSave = async () => {
    // 왜: 배점/기준은 수료 판정 및 성적/증명서 출력에 직접 영향을 주므로, DB에 저장해야 새로고침 후에도 유지됩니다.
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.updateCourseEvaluation({
        courseId,
        assignProgress: clamp0to100(form.assignProgress),
        assignExam: clamp0to100(form.assignExam),
        assignHomework: clamp0to100(form.assignHomework),
        assignForum: clamp0to100(form.assignForum),
        assignEtc: clamp0to100(form.assignEtc),

        assignSurveyYn: form.assignSurveyYn,
        pushSurveyYn: form.pushSurveyYn,
        passYn: form.passYn,

        limitTotalScore: clamp0to100(form.limitTotalScore),
        limitProgress: clamp0to100(form.limitProgress),

        completeLimitProgress: clamp0to100(form.completeLimitProgress),
        completeLimitTotalScore: clamp0to100(form.completeLimitTotalScore),
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      alert('저장되었습니다.');
      await onReload();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  const numberInputClass =
    'w-full px-3 py-2 border border-gray-300 rounded-lg text-right focus:outline-none focus:ring-2 focus:ring-blue-500';

  return (
    <div className="space-y-6">
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h4 className="text-gray-900 mb-1">배점 비율</h4>
            <p className="text-sm text-gray-600">총점 100점 기준으로 입력해 주세요. (권장: 합계 100)</p>
          </div>
          <div className={`text-sm ${totalAssignScore === 100 ? 'text-green-700' : 'text-orange-700'}`}>
            합계: {totalAssignScore}
          </div>
        </div>

        <div className="grid grid-cols-5 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">출석(진도)</label>
            <input
              type="number"
              value={form.assignProgress}
              onChange={(e) => setForm((prev) => ({ ...prev, assignProgress: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">시험</label>
            <input
              type="number"
              value={form.assignExam}
              onChange={(e) => setForm((prev) => ({ ...prev, assignExam: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과제</label>
            <input
              type="number"
              value={form.assignHomework}
              onChange={(e) => setForm((prev) => ({ ...prev, assignHomework: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">토론</label>
            <input
              type="number"
              value={form.assignForum}
              onChange={(e) => setForm((prev) => ({ ...prev, assignForum: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">기타</label>
            <input
              type="number"
              value={form.assignEtc}
              onChange={(e) => setForm((prev) => ({ ...prev, assignEtc: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
        </div>
      </div>

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <h4 className="text-gray-900">수료(합격) 기준</h4>
        <p className="text-sm text-gray-600">
          아래 기준은 수료/합격 판정 및 성적 상태 표시(미달/수료/합격)에 사용됩니다.
        </p>
        {!passEnabled && (
          <div className="bg-orange-50 border border-orange-200 text-orange-800 px-4 py-3 rounded-lg text-sm">
            합격 상태 사용이 꺼져 있어요. 그래서 지금은 “합격 기준” 입력칸을 잠가두었습니다. (수료 기준만 사용됩니다)
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">총점 기준</label>
            <input
              type="number"
              value={form.limitTotalScore}
              onChange={(e) => setForm((prev) => ({ ...prev, limitTotalScore: toInt(e.target.value, 0) }))}
              className={`${numberInputClass}${!passEnabled ? ' bg-gray-100 text-gray-500' : ''}`}
              disabled={!passEnabled}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">진도 기준(%)</label>
            <input
              type="number"
              value={form.limitProgress}
              onChange={(e) => setForm((prev) => ({ ...prev, limitProgress: toInt(e.target.value, 0) }))}
              className={`${numberInputClass}${!passEnabled ? ' bg-gray-100 text-gray-500' : ''}`}
              disabled={!passEnabled}
            />
          </div>
        </div>
      </div>

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <h4 className="text-gray-900">수료(완료) 기준</h4>
        <p className="text-sm text-gray-600">
          합격 상태를 사용하지 않는 환경에서는 “수료(완료)”가 최종 상태가 됩니다.
        </p>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">총점 기준</label>
            <input
              type="number"
              value={form.completeLimitTotalScore}
              onChange={(e) => setForm((prev) => ({ ...prev, completeLimitTotalScore: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">진도 기준(%)</label>
            <input
              type="number"
              value={form.completeLimitProgress}
              onChange={(e) => setForm((prev) => ({ ...prev, completeLimitProgress: toInt(e.target.value, 0) }))}
              className={numberInputClass}
            />
          </div>
        </div>
      </div>

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <h4 className="text-gray-900">옵션</h4>

        <div className="flex items-center justify-between">
          <div>
            <div className="text-gray-900">설문참여 포함</div>
            <div className="text-sm text-gray-600">수료 조건에 설문참여 여부를 포함합니다.</div>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={form.assignSurveyYn === 'Y'}
              onChange={(e) => setForm((prev) => ({ ...prev, assignSurveyYn: e.target.checked ? 'Y' : 'N' }))}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
          </label>
        </div>

        <div className="flex items-center justify-between">
          <div>
            <div className="text-gray-900">설문 독려</div>
            <div className="text-sm text-gray-600">설문 독려 메시지/표시 기능을 사용합니다.</div>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={form.pushSurveyYn === 'Y'}
              onChange={(e) => setForm((prev) => ({ ...prev, pushSurveyYn: e.target.checked ? 'Y' : 'N' }))}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
          </label>
        </div>

        <div className="flex items-center justify-between">
          <div>
            <div className="text-gray-900">합격 상태 사용</div>
            <div className="text-sm text-gray-600">합격 상태를 사용하면 “합격증” 발급이 가능합니다.</div>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={form.passYn === 'Y'}
              onChange={(e) => setForm((prev) => ({ ...prev, passYn: e.target.checked ? 'Y' : 'N' }))}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
          </label>
        </div>
      </div>

      <div className="flex justify-end">
        <button
          onClick={() => void handleSave()}
          disabled={saving}
          className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? '저장 중...' : '저장'}</span>
        </button>
      </div>
    </div>
  );
}

function selectTemplateLabel(row: TutorCertificateTemplateRow) {
  const name = (row.template_nm || '').trim();
  const cd = (row.template_cd || '').trim();
  if (name && cd) return `${name} (${cd})`;
  return name || cd || `템플릿 #${row.id}`;
}

function CompletionCertificateTab({
  courseId,
  detail,
  onReload,
}: {
  courseId: number;
  detail: TutorCourseInfoDetail | null;
  onReload: () => Promise<void> | void;
}) {
  const [templates, setTemplates] = useState<TutorCertificateTemplateRow[]>([]);
  const [loadingTemplates, setLoadingTemplates] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [certCompleteYn, setCertCompleteYn] = useState<'Y' | 'N'>('Y');
  const [certTemplateId, setCertTemplateId] = useState(0);
  const [completeNoYn, setCompleteNoYn] = useState<'Y' | 'N'>('N');
  const [completePrefix, setCompletePrefix] = useState('');
  const [postfixCnt, setPostfixCnt] = useState(0);
  const [postfixType, setPostfixType] = useState<'R' | 'C'>('R');
  const [postfixOrd, setPostfixOrd] = useState<'A' | 'D'>('A');

  useEffect(() => {
    let cancelled = false;
    const fetchTemplates = async () => {
      setLoadingTemplates(true);
      try {
        const res = await tutorLmsApi.getCertificateTemplates({ templateType: 'C' });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        if (!cancelled) setTemplates(res.rst_data ?? []);
      } catch {
        if (!cancelled) setTemplates([]);
      } finally {
        if (!cancelled) setLoadingTemplates(false);
      }
    };

    void fetchTemplates();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    // 왜: DB에서 내려온 현재 설정을 그대로 보여줘야 “어디가 문제인지/무엇이 바뀌는지” 사용자가 알 수 있습니다.
    if (!detail) return;
    setCertCompleteYn(getYn(detail, 'cert_complete_yn', 'Y'));
    setCertTemplateId(getInt(detail, 'cert_template_id', 0));
    setCompleteNoYn(getYn(detail, 'complete_no_yn', 'N'));
    setCompletePrefix(getStr(detail, 'complete_prefix', ''));
    setPostfixCnt(getInt(detail, 'postfix_cnt', 0));
    setPostfixType(getStr(detail, 'postfix_type', 'R') === 'C' ? 'C' : 'R');
    setPostfixOrd(getStr(detail, 'postfix_ord', 'A') === 'D' ? 'D' : 'A');
  }, [detail]);

  const handleSave = async () => {
    // 왜: 템플릿/번호 규칙은 “수료 처리”와 “증명서 출력”에 직접 영향을 주므로 DB에 저장해야 합니다.
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }
    if (!detail) {
      setErrorMessage('과목 정보를 먼저 불러와 주세요.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.updateCourseCertificateSettings({
        courseId,
        certCompleteYn,
        certTemplateId,
        // 왜: 수료증 탭에서 저장할 때 합격증 템플릿이 초기화되면 안 되므로, 현재 값을 함께 보냅니다.
        passCertTemplateId: getInt(detail, 'pass_cert_template_id', 0),
        completeNoYn,
        completePrefix,
        postfixCnt: Math.max(0, toInt(postfixCnt, 0)),
        postfixType,
        postfixOrd,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      alert('저장되었습니다.');
      await onReload();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-gray-900 mb-1">수료증 사용</h4>
            <p className="text-sm text-gray-600">수료증 출력 버튼을 사용할지 여부를 설정합니다.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={certCompleteYn === 'Y'}
              onChange={(e) => setCertCompleteYn(e.target.checked ? 'Y' : 'N')}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
          </label>
        </div>

        <div>
          <label className="block text-sm text-gray-700 mb-2">수료증 템플릿</label>
          <select
            value={certTemplateId}
            onChange={(e) => setCertTemplateId(toInt(e.target.value, 0))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg"
            disabled={loadingTemplates}
          >
            <option value={0}>미지정(사이트 기본 템플릿 사용)</option>
            {templates.map((t) => (
              <option key={t.id} value={t.id}>
                {selectTemplateLabel(t)}
              </option>
            ))}
          </select>
          {loadingTemplates && <p className="text-sm text-gray-500 mt-2">템플릿 불러오는 중...</p>}
        </div>
      </div>

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-gray-900 mb-1">수료번호 사용</h4>
            <p className="text-sm text-gray-600">수료 처리 시 수료번호를 생성/부여하는 규칙입니다.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={completeNoYn === 'Y'}
              onChange={(e) => setCompleteNoYn(e.target.checked ? 'Y' : 'N')}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
          </label>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">수료번호 앞자리(접두)</label>
            <input
              type="text"
              value={completePrefix}
              onChange={(e) => setCompletePrefix(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg"
              placeholder="예: 2025-"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">수료번호 뒷자리수</label>
            <input
              type="number"
              value={postfixCnt}
              onChange={(e) => setPostfixCnt(toInt(e.target.value, 0))}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-right"
              min={0}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">뒷자리 방식</label>
            <select
              value={postfixType}
              onChange={(e) => setPostfixType(e.target.value === 'C' ? 'C' : 'R')}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg"
            >
              <option value="R">수강순번</option>
              <option value="C">수강생아이디</option>
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">정렬 방식</label>
            <select
              value={postfixOrd}
              onChange={(e) => setPostfixOrd(e.target.value === 'D' ? 'D' : 'A')}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg"
            >
              <option value="A">오름차순</option>
              <option value="D">내림차순</option>
            </select>
          </div>
        </div>
      </div>

      <div className="flex justify-end">
        <button
          onClick={() => void handleSave()}
          disabled={saving}
          className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? '저장 중...' : '저장'}</span>
        </button>
      </div>
    </div>
  );
}

function PassCertificateTab({
  courseId,
  detail,
  onReload,
}: {
  courseId: number;
  detail: TutorCourseInfoDetail | null;
  onReload: () => Promise<void> | void;
}) {
  const [templates, setTemplates] = useState<TutorCertificateTemplateRow[]>([]);
  const [loadingTemplates, setLoadingTemplates] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [passCertTemplateId, setPassCertTemplateId] = useState(0);

  useEffect(() => {
    let cancelled = false;
    const fetchTemplates = async () => {
      setLoadingTemplates(true);
      try {
        const res = await tutorLmsApi.getCertificateTemplates({ templateType: 'P' });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        if (!cancelled) setTemplates(res.rst_data ?? []);
      } catch {
        if (!cancelled) setTemplates([]);
      } finally {
        if (!cancelled) setLoadingTemplates(false);
      }
    };

    void fetchTemplates();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!detail) return;
    setPassCertTemplateId(getInt(detail, 'pass_cert_template_id', 0));
  }, [detail]);

  const handleSave = async () => {
    if (!courseId) {
      setErrorMessage('과목 ID가 올바르지 않습니다.');
      return;
    }
    if (!detail) {
      setErrorMessage('과목 정보를 먼저 불러와 주세요.');
      return;
    }

    setSaving(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.updateCourseCertificateSettings({
        courseId,
        certCompleteYn: getYn(detail, 'cert_complete_yn', 'Y'),
        certTemplateId: getInt(detail, 'cert_template_id', 0),
        passCertTemplateId,
        completeNoYn: getYn(detail, 'complete_no_yn', 'N'),
        completePrefix: getStr(detail, 'complete_prefix', ''),
        postfixCnt: getInt(detail, 'postfix_cnt', 0),
        postfixType: getStr(detail, 'postfix_type', 'R') === 'C' ? 'C' : 'R',
        postfixOrd: getStr(detail, 'postfix_ord', 'A') === 'D' ? 'D' : 'A',
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      alert('저장되었습니다.');
      await onReload();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <h4 className="text-gray-900">합격증 템플릿</h4>
        <p className="text-sm text-gray-600">
          합격증 출력 시 사용할 템플릿을 선택합니다. (미지정이면 사이트 기본 템플릿을 사용합니다)
        </p>
        <select
          value={passCertTemplateId}
          onChange={(e) => setPassCertTemplateId(toInt(e.target.value, 0))}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg"
          disabled={loadingTemplates}
        >
          <option value={0}>미지정(사이트 기본 템플릿 사용)</option>
          {templates.map((t) => (
            <option key={t.id} value={t.id}>
              {selectTemplateLabel(t)}
            </option>
          ))}
        </select>
        {loadingTemplates && <p className="text-sm text-gray-500">템플릿 불러오는 중...</p>}
      </div>

      <div className="flex justify-end">
        <button
          onClick={() => void handleSave()}
          disabled={saving}
          className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? '저장 중...' : '저장'}</span>
        </button>
      </div>
    </div>
  );
}

// 학사 과목 평가/수료 기준 탭
function HaksaEvaluationTab({ course }: { course: any }) {
  const haksaKey = useMemo(
    () =>
      buildHaksaCourseKey({
        haksaCourseCode: course?.haksaCourseCode,
        haksaOpenYear: course?.haksaOpenYear,
        haksaOpenTerm: course?.haksaOpenTerm,
        haksaBunbanCode: course?.haksaBunbanCode,
        haksaGroupCode: course?.haksaGroupCode,
      }),
    [
      course?.haksaCourseCode,
      course?.haksaOpenYear,
      course?.haksaOpenTerm,
      course?.haksaBunbanCode,
      course?.haksaGroupCode,
    ]
  );
  const courseId = course?.id;
  
  // 배점 비율
  const [weights, setWeights] = useState({
    attendance: 20,
    exam: 40,
    assignment: 30,
    etc: 10,
  });

  // 성적 컷오프
  const [cutoffs, setCutoffs] = useState({
    A: 90,
    B: 80,
    C: 70,
    D: 60,
    F: 0, // F는 D 미만
  });

  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // DB에서 불러오기 (없으면 로컬스토리지 마이그레이션)
  useEffect(() => {
    if (!haksaKey) return;
    let cancelled = false;

    const fetchEval = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getHaksaCourseEval(haksaKey);
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        // 왜: DataSet은 배열 형태로 내려올 수 있으므로 첫 번째 행을 사용합니다.
        const payload = Array.isArray(res.rst_data) ? res.rst_data[0] : res.rst_data;
        const raw = payload?.eval_json || '';
        if (raw) {
          try {
            const parsed = JSON.parse(raw) as HaksaEvalSettings;
            if (!cancelled) {
              setWeights(parsed.weights);
              setCutoffs(parsed.cutoffs);
            }
            return;
          } catch {}
        }

        // 왜: 기존 로컬스토리지 데이터를 DB로 이전해 둡니다(이전 데이터 손실 방지).
        if (courseId) {
          try {
            const savedWeights = localStorage.getItem(`haksa_eval_weights_${courseId}`);
            const savedCutoffs = localStorage.getItem(`haksa_eval_cutoffs_${courseId}`);
            if (savedWeights && savedCutoffs) {
              const next = {
                weights: JSON.parse(savedWeights),
                cutoffs: JSON.parse(savedCutoffs),
              } as HaksaEvalSettings;
              if (!cancelled) {
                setWeights(next.weights);
                setCutoffs(next.cutoffs);
              }
              await tutorLmsApi.updateHaksaCourseEval({
                ...haksaKey,
                evalJson: JSON.stringify(next),
              });
            }
          } catch {}
        }
      } catch (e) {
        if (!cancelled) {
          setErrorMessage(e instanceof Error ? e.message : '평가 기준을 불러오는 중 오류가 발생했습니다.');
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void fetchEval();
    return () => {
      cancelled = true;
    };
  }, [haksaKey, courseId]);

  const totalWeight = weights.attendance + weights.exam + weights.assignment + weights.etc;

  const handleSave = () => {
    if (!haksaKey) {
      setErrorMessage('학사 과목 키가 올바르지 않습니다.');
      return;
    }
    setSaving(true);
    setErrorMessage(null);
    void (async () => {
      try {
        const payload: HaksaEvalSettings = { weights, cutoffs };
        const res = await tutorLmsApi.updateHaksaCourseEval({
          ...haksaKey,
          evalJson: JSON.stringify(payload),
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        alert('저장되었습니다.');
      } catch (e) {
        setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
      } finally {
        setSaving(false);
      }
    })();
  };

  const numberInputClass =
    'w-full px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500';

  return (
    <div className="space-y-6">
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
          {errorMessage}
        </div>
      )}

      {loading && (
        <div className="bg-white rounded-lg border border-gray-200 p-6 text-center text-gray-600">
          불러오는 중...
        </div>
      )}

      {/* 학사 과목 안내 */}
      <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm">
        <strong>학사 연동 과목</strong>: 아래 설정은 이 과목의 성적 판정 기준으로 사용됩니다.
      </div>

      {/* 배점 비율 */}
      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h4 className="text-gray-900 mb-1">배점 비율</h4>
            <p className="text-sm text-gray-600">총점 100점 기준으로 입력해 주세요.</p>
          </div>
          <div className={`text-sm font-medium ${totalWeight === 100 ? 'text-green-700' : 'text-orange-700'}`}>
            합계: {totalWeight}
          </div>
        </div>

        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">출석</label>
            <input
              type="number"
              value={weights.attendance}
              onChange={(e) => setWeights(prev => ({ ...prev, attendance: toInt(e.target.value, 0) }))}
              className={numberInputClass}
              min={0}
              max={100}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">시험</label>
            <input
              type="number"
              value={weights.exam}
              onChange={(e) => setWeights(prev => ({ ...prev, exam: toInt(e.target.value, 0) }))}
              className={numberInputClass}
              min={0}
              max={100}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과제</label>
            <input
              type="number"
              value={weights.assignment}
              onChange={(e) => setWeights(prev => ({ ...prev, assignment: toInt(e.target.value, 0) }))}
              className={numberInputClass}
              min={0}
              max={100}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">기타</label>
            <input
              type="number"
              value={weights.etc}
              onChange={(e) => setWeights(prev => ({ ...prev, etc: toInt(e.target.value, 0) }))}
              className={numberInputClass}
              min={0}
              max={100}
            />
          </div>
        </div>
      </div>

      {/* 성적 컷오프 */}
      <div className="border border-gray-200 rounded-lg p-6 space-y-4">
        <div>
          <h4 className="text-gray-900 mb-1">성적 등급 기준</h4>
          <p className="text-sm text-gray-600">각 등급의 최소 점수를 입력해 주세요. (해당 점수 이상이면 해당 등급)</p>
        </div>

        <div className="grid grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-blue-700 mb-2 text-center">A 등급</label>
            <div className="relative">
              <input
                type="number"
                value={cutoffs.A}
                onChange={(e) => setCutoffs(prev => ({ ...prev, A: toInt(e.target.value, 90) }))}
                className={`${numberInputClass} bg-blue-50 border-blue-200`}
                min={0}
                max={100}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">점 이상</span>
            </div>
            <p className="text-xs text-center text-gray-500 mt-1">~100점</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-green-700 mb-2 text-center">B 등급</label>
            <div className="relative">
              <input
                type="number"
                value={cutoffs.B}
                onChange={(e) => setCutoffs(prev => ({ ...prev, B: toInt(e.target.value, 80) }))}
                className={`${numberInputClass} bg-green-50 border-green-200`}
                min={0}
                max={100}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">점 이상</span>
            </div>
            <p className="text-xs text-center text-gray-500 mt-1">~{cutoffs.A - 1}점</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-yellow-700 mb-2 text-center">C 등급</label>
            <div className="relative">
              <input
                type="number"
                value={cutoffs.C}
                onChange={(e) => setCutoffs(prev => ({ ...prev, C: toInt(e.target.value, 70) }))}
                className={`${numberInputClass} bg-yellow-50 border-yellow-200`}
                min={0}
                max={100}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">점 이상</span>
            </div>
            <p className="text-xs text-center text-gray-500 mt-1">~{cutoffs.B - 1}점</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-orange-700 mb-2 text-center">D 등급</label>
            <div className="relative">
              <input
                type="number"
                value={cutoffs.D}
                onChange={(e) => setCutoffs(prev => ({ ...prev, D: toInt(e.target.value, 60) }))}
                className={`${numberInputClass} bg-orange-50 border-orange-200`}
                min={0}
                max={100}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">점 이상</span>
            </div>
            <p className="text-xs text-center text-gray-500 mt-1">~{cutoffs.C - 1}점</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-red-700 mb-2 text-center">F 등급</label>
            <div className="px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-center text-gray-700">
              {cutoffs.D - 1}점 이하
            </div>
            <p className="text-xs text-center text-gray-500 mt-1">0~{cutoffs.D - 1}점</p>
          </div>
        </div>

        {/* 등급 요약 */}
        <div className="mt-4 p-3 bg-gray-50 rounded-lg">
          <h5 className="text-sm font-medium text-gray-700 mb-2">등급 요약</h5>
          <div className="flex flex-wrap gap-3 text-sm">
            <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full">A: {cutoffs.A}~100점</span>
            <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full">B: {cutoffs.B}~{cutoffs.A - 1}점</span>
            <span className="px-3 py-1 bg-yellow-100 text-yellow-700 rounded-full">C: {cutoffs.C}~{cutoffs.B - 1}점</span>
            <span className="px-3 py-1 bg-orange-100 text-orange-700 rounded-full">D: {cutoffs.D}~{cutoffs.C - 1}점</span>
            <span className="px-3 py-1 bg-red-100 text-red-700 rounded-full">F: 0~{cutoffs.D - 1}점</span>
          </div>
        </div>
      </div>

      {/* 저장 버튼 */}
      <div className="flex justify-end">
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? '저장 중...' : '저장'}</span>
        </button>
      </div>
    </div>
  );
}
