import React, { useEffect, useMemo, useState } from 'react';
import { Edit, Save } from 'lucide-react';
import { tutorLmsApi, type TutorCertificateTemplateRow, type TutorCourseInfoDetail } from '../api/tutorLmsApi';
import { CourseSelectionModal } from './CourseSelectionModal';

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

// 과목정보 메인 탭
export function CourseInfoTab({
  course,
  onCourseUpdated,
}: {
  course: any;
  onCourseUpdated?: (nextCourse: any) => void;
}) {
  const courseId = toInt(course?.id, 0);
  const [subTab, setSubTab] = useState<SubTab>('basic');
  const [detail, setDetail] = useState<TutorCourseInfoDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const passYn = toYn(detail?.pass_yn, 'N') === 'Y';

  const fetchCourseInfo = async () => {
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
    void fetchCourseInfo();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId]);

  useEffect(() => {
    // 왜: 합격증 탭은 pass_yn=Y일 때만 의미가 있습니다.
    if (subTab === 'certificate' && !passYn) setSubTab('evaluation');
  }, [passYn, subTab]);

  return (
    <div className="space-y-6">
      {/* 하위 탭 네비게이션 */}
      <div className="flex gap-2 border-b border-gray-200">
        <button
          onClick={() => setSubTab('basic')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'basic'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          기본 정보
        </button>
        <button
          onClick={() => setSubTab('evaluation')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'evaluation'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          평가/수료 기준
        </button>
        <button
          onClick={() => setSubTab('completion')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'completion'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          수료증
        </button>
        {passYn && (
          <button
            onClick={() => setSubTab('certificate')}
            className={`px-4 py-2 transition-colors ${
              subTab === 'certificate'
                ? 'border-b-2 border-blue-600 text-blue-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            합격증
          </button>
        )}
      </div>

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
        />
      )}

      {!loading && !errorMessage && subTab === 'evaluation' && (
        <EvaluationTab courseId={courseId} detail={detail} onReload={fetchCourseInfo} />
      )}

      {!loading && !errorMessage && subTab === 'completion' && (
        <CompletionCertificateTab courseId={courseId} detail={detail} onReload={fetchCourseInfo} />
      )}

      {!loading && !errorMessage && subTab === 'certificate' && passYn && (
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
}: {
  course: any;
  courseId: number;
  detail: TutorCourseInfoDetail | null;
  onReload: () => Promise<void> | void;
  onCourseUpdated?: (nextCourse: any) => void;
}) {
  const [isCourseModalOpen, setIsCourseModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [content1, setContent1] = useState('');
  const [content2, setContent2] = useState('');

  useEffect(() => {
    setContent1(detail?.content1 ?? '');
    setContent2(detail?.content2 ?? '');
  }, [detail?.content1, detail?.content2]);

  const selectedProgram: ProgramOption | null =
    course && 0 < toInt(course.programId, 0)
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
        <button
          onClick={() => setIsCourseModalOpen(true)}
          disabled={saving}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Edit className="w-4 h-4" />
          <span>{saving ? '저장 중...' : '소속 과정 변경'}</span>
        </button>
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

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

      <CourseSelectionModal
        isOpen={isCourseModalOpen}
        onClose={() => setIsCourseModalOpen(false)}
        onSelect={(program) => {
          void handleProgramSelect(program as ProgramOption | null);
        }}
        selectedCourse={selectedProgram}
      />

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
    limitExam: 0,
    limitHomework: 0,
    limitForum: 0,
    limitEtc: 0,

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
      assignProgress: toInt(detail.assign_progress, 100),
      assignExam: toInt(detail.assign_exam, 0),
      assignHomework: toInt(detail.assign_homework, 0),
      assignForum: toInt(detail.assign_forum, 0),
      assignEtc: toInt(detail.assign_etc, 0),

      limitTotalScore: toInt(detail.limit_total_score, 60),
      limitProgress: toInt(detail.limit_progress, 60),
      limitExam: toInt(detail.limit_exam, 0),
      limitHomework: toInt(detail.limit_homework, 0),
      limitForum: toInt(detail.limit_forum, 0),
      limitEtc: toInt(detail.limit_etc, 0),

      completeLimitProgress: toInt(detail.complete_limit_progress, 60),
      completeLimitTotalScore: toInt(detail.complete_limit_total_score, 60),

      assignSurveyYn: toYn(detail.assign_survey_yn, 'N'),
      pushSurveyYn: toYn(detail.push_survey_yn, 'N'),
      passYn: toYn(detail.pass_yn, 'N'),
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
        limitExam: clamp0to100(form.limitExam),
        limitHomework: clamp0to100(form.limitHomework),
        limitForum: clamp0to100(form.limitForum),
        limitEtc: clamp0to100(form.limitEtc),

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

        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">시험 기준</label>
            <input
              type="number"
              value={form.limitExam}
              onChange={(e) => setForm((prev) => ({ ...prev, limitExam: toInt(e.target.value, 0) }))}
              className={`${numberInputClass}${!passEnabled ? ' bg-gray-100 text-gray-500' : ''}`}
              disabled={!passEnabled}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과제 기준</label>
            <input
              type="number"
              value={form.limitHomework}
              onChange={(e) => setForm((prev) => ({ ...prev, limitHomework: toInt(e.target.value, 0) }))}
              className={`${numberInputClass}${!passEnabled ? ' bg-gray-100 text-gray-500' : ''}`}
              disabled={!passEnabled}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">토론 기준</label>
            <input
              type="number"
              value={form.limitForum}
              onChange={(e) => setForm((prev) => ({ ...prev, limitForum: toInt(e.target.value, 0) }))}
              className={`${numberInputClass}${!passEnabled ? ' bg-gray-100 text-gray-500' : ''}`}
              disabled={!passEnabled}
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">기타 기준</label>
            <input
              type="number"
              value={form.limitEtc}
              onChange={(e) => setForm((prev) => ({ ...prev, limitEtc: toInt(e.target.value, 0) }))}
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
    setCertCompleteYn(toYn(detail.cert_complete_yn, 'Y'));
    setCertTemplateId(toInt(detail.cert_template_id, 0));
    setCompleteNoYn(toYn(detail.complete_no_yn, 'N'));
    setCompletePrefix(detail.complete_prefix ?? '');
    setPostfixCnt(toInt(detail.postfix_cnt, 0));
    setPostfixType(detail.postfix_type === 'C' ? 'C' : 'R');
    setPostfixOrd(detail.postfix_ord === 'D' ? 'D' : 'A');
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
        passCertTemplateId: toInt(detail.pass_cert_template_id, 0),
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
    setPassCertTemplateId(toInt(detail.pass_cert_template_id, 0));
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
        certCompleteYn: toYn(detail.cert_complete_yn, 'Y'),
        certTemplateId: toInt(detail.cert_template_id, 0),
        passCertTemplateId,
        completeNoYn: toYn(detail.complete_no_yn, 'N'),
        completePrefix: detail.complete_prefix ?? '',
        postfixCnt: toInt(detail.postfix_cnt, 0),
        postfixType: detail.postfix_type === 'C' ? 'C' : 'R',
        postfixOrd: detail.postfix_ord === 'D' ? 'D' : 'A',
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
