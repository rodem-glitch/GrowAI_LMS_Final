import React, { useEffect, useMemo, useState } from 'react';
import { ArrowLeft, FileText, Printer } from 'lucide-react';
import { tutorLmsApi, type TutorProgramDetail } from '../api/tutorLmsApi';

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

type PlanCurriculumItem = {
  id?: string;
  type?: string;
  hours?: string;
  description?: string;
};

type PlanTeachingItem = {
  id?: string;
  courseName?: string;
  targetDepartment?: string;
  courseType?: string;
  trainingHours?: string;
  instructor?: string;
  goals?: string;
  textbook?: string;
  mainPlan?: string;
};

type PlanEvaluationItem = {
  id?: string;
  method?: string;
  area?: string;
};

type ProgramPlanV1 = {
  version?: number;
  basic?: {
    classification?: LabelValue;
    courseName?: string;
    department?: string;
    major?: string;
    departmentName?: string;
    instructor?: string;
  };
  training?: {
    trainingPeriodText?: string;
    startDateYmd?: string;
    endDateYmd?: string;
    trainingLevel?: LabelValue;
    trainingTarget?: string;
    trainingGoal?: string;
  };
  curriculum?: PlanCurriculumItem[];
  teachingPlans?: PlanTeachingItem[];
  evaluations?: PlanEvaluationItem[];
};

function safeParsePlanJson(raw: string | null | undefined): ProgramPlanV1 | null {
  // 왜: plan_json은 "문자열"로 저장되기 때문에, 조회 시점에는 항상 안전하게 JSON 파싱을 시도해야 합니다.
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed as ProgramPlanV1;
  } catch {
    return null;
  }
}

function curriculumTypeLabel(type?: string) {
  if (type === 'NCS') return 'NCS';
  if (type === 'non-NCS') return '비NCS';
  if (type === 'liberal-arts') return '교양';
  return type ?? '-';
}

function sumCurriculumHours(items: PlanCurriculumItem[]) {
  // 왜: "시수" 입력은 사람이 쓰는 값이라(예: 40, 40시간), 숫자만 뽑아 합계를 계산합니다.
  return items.reduce((sum, item) => {
    const raw = String(item.hours ?? '').trim();
    if (!raw) return sum;

    const numeric = Number(raw.replace(/[^0-9.]/g, ''));
    if (!Number.isFinite(numeric)) return sum;
    return sum + numeric;
  }, 0);
}

export function OperationalPlan({ course, onBack }: OperationalPlanProps) {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [detail, setDetail] = useState<TutorProgramDetail | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchProgram = async () => {
      // 왜: 목록 API(program_list)는 "목록 표시" 중심이라, 상세 화면에서는 항상 program_view로 최신/전체 데이터를 다시 가져옵니다.
      setLoading(true);
      setErrorMessage(null);

      try {
        const id = Number(course.id);
        if (!Number.isFinite(id) || id <= 0) throw new Error('과정 ID가 올바르지 않습니다.');

        const res = await tutorLmsApi.getProgram(id);
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        if (!cancelled) setDetail(res.rst_data ?? null);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchProgram();
    return () => {
      cancelled = true;
    };
  }, [course.id]);

  const plan = useMemo(() => safeParsePlanJson(detail?.plan_json), [detail?.plan_json]);
  const curriculumItems = plan?.curriculum ?? [];
  const teachingPlans = plan?.teachingPlans ?? [];
  const evaluations = plan?.evaluations ?? [];
  const totalHours = useMemo(() => sumCurriculumHours(curriculumItems), [curriculumItems]);

  const title = detail?.course_nm ?? course.name;

  const handlePrint = () => {
    // 왜: 1차 목표는 "서버 PDF 생성"이 아니라, 브라우저 인쇄 기능(=PDF 저장 포함)로 대체하는 것입니다.
    window.print();
  };

  return (
    <div className="max-w-5xl mx-auto">
      <style>{`
        @media print {
          .tutor-print-hide { display: none !important; }
          body { background: white !important; }
        }
      `}</style>

      {/* Header */}
      <div className="mb-6 flex items-center justify-between tutor-print-hide">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="flex items-center gap-2 px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>목록으로</span>
          </button>
          <div>
            <h2 className="text-gray-900">운영계획서</h2>
            <p className="text-sm text-gray-600">{title}</p>
          </div>
        </div>
        <button
          onClick={handlePrint}
          disabled={loading || !detail}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
            loading || !detail
              ? 'bg-blue-300 text-white cursor-not-allowed'
              : 'bg-blue-600 text-white hover:bg-blue-700'
          }`}
        >
          <Printer className="w-5 h-5" />
          <span>인쇄 / PDF 저장</span>
        </button>
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
          운영계획서 정보를 찾을 수 없습니다.
        </div>
      )}

      {!loading && !errorMessage && detail && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          {/* Document Header */}
          <div className="bg-gray-50 border-b border-gray-200 p-8 text-center">
            <div className="mb-4">
              <FileText className="w-16 h-16 mx-auto text-blue-600 mb-2" />
            </div>
            <h1 className="text-3xl mb-2 text-gray-900">교육과정 운영계획서</h1>
            <p className="text-xl text-gray-700">{title}</p>
          </div>

          {/* Document Content */}
          <div className="p-8 space-y-8">
            {!plan && (
              <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded-lg">
                운영계획서 데이터(plan_json)가 아직 저장되지 않았습니다. "과정개설"에서 입력 후 저장해 주세요.
              </div>
            )}

            {/* 1. 기본 정보 */}
            <section>
              <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
                1. 기본 정보
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">과정 분류</span>
                  <span className="flex-1 text-gray-900">{plan?.basic?.classification?.label ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">과정명</span>
                  <span className="flex-1 text-gray-900">{title}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">계열</span>
                  <span className="flex-1 text-gray-900">{plan?.basic?.department ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">전공</span>
                  <span className="flex-1 text-gray-900">{plan?.basic?.major ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">학과명</span>
                  <span className="flex-1 text-gray-900">{plan?.basic?.departmentName ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-32 text-gray-700">담당교수</span>
                  <span className="flex-1 text-gray-900">{plan?.basic?.instructor ?? '-'}</span>
                </div>
              </div>
            </section>

            {/* 2. 교육훈련 정보 */}
            <section>
              <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
                2. 교육훈련 정보
              </h3>
              <div className="space-y-3">
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-40 text-gray-700">교육훈련기간</span>
                  <span className="flex-1 text-gray-900">
                    {plan?.training?.trainingPeriodText ?? detail.training_period ?? '-'}
                  </span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-40 text-gray-700">교육훈련수준</span>
                  <span className="flex-1 text-gray-900">{plan?.training?.trainingLevel?.label ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-40 text-gray-700">교육훈련대상자</span>
                  <span className="flex-1 text-gray-900">{plan?.training?.trainingTarget ?? '-'}</span>
                </div>
                <div className="flex border-b border-gray-200 py-3">
                  <span className="w-40 text-gray-700">교육훈련목표</span>
                  <span className="flex-1 text-gray-900 whitespace-pre-line">{plan?.training?.trainingGoal ?? '-'}</span>
                </div>
              </div>
            </section>

            {/* 3. 교육훈련 교과편성 총괄표 */}
            <section>
              <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
                3. 교육훈련 교과편성 총괄표
              </h3>
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                        구분
                      </th>
                      <th className="px-4 py-3 text-center text-sm text-gray-700 border-b border-gray-200">
                        시수
                      </th>
                      <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                        교과목/영역
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {curriculumItems.length > 0 ? (
                      curriculumItems.map((item, index) => (
                        <tr key={item.id ?? String(index)}>
                          <td className="px-4 py-3 text-sm text-gray-900">{curriculumTypeLabel(item.type)}</td>
                          <td className="px-4 py-3 text-sm text-gray-900 text-center">{item.hours ?? '-'}</td>
                          <td className="px-4 py-3 text-sm text-gray-600">{item.description ?? '-'}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={3} className="px-4 py-8 text-center text-sm text-gray-500">
                          등록된 교과편성 항목이 없습니다.
                        </td>
                      </tr>
                    )}
                  </tbody>
                  <tfoot className="bg-gray-50">
                    <tr>
                      <td className="px-4 py-3 text-sm text-gray-900 border-t border-gray-200">
                        합계
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900 text-center border-t border-gray-200">
                        {Number.isFinite(totalHours) ? (Number.isInteger(totalHours) ? totalHours : totalHours.toFixed(1)) : '-'}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-600 border-t border-gray-200">
                        -
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </section>

            {/* 4. 교수계획서 */}
            <section>
              <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
                4. 교수계획서
              </h3>
              {teachingPlans.length > 0 ? (
                <div className="space-y-4">
                  {teachingPlans.map((item, index) => (
                    <div key={item.id ?? String(index)} className="border border-gray-200 rounded-lg p-4">
                      <div className="grid grid-cols-2 gap-4 mb-4">
                        <div className="flex">
                          <span className="w-32 text-gray-700">과목명</span>
                          <span className="flex-1 text-gray-900">{item.courseName ?? '-'}</span>
                        </div>
                        <div className="flex">
                          <span className="w-32 text-gray-700">대상학과</span>
                          <span className="flex-1 text-gray-900">{item.targetDepartment ?? '-'}</span>
                        </div>
                        <div className="flex">
                          <span className="w-32 text-gray-700">과정구분</span>
                          <span className="flex-1 text-gray-900">{item.courseType ?? '-'}</span>
                        </div>
                        <div className="flex">
                          <span className="w-32 text-gray-700">교육훈련시수</span>
                          <span className="flex-1 text-gray-900">{item.trainingHours ?? '-'}</span>
                        </div>
                        <div className="flex">
                          <span className="w-32 text-gray-700">교수명</span>
                          <span className="flex-1 text-gray-900">{item.instructor ?? '-'}</span>
                        </div>
                        <div className="flex">
                          <span className="w-32 text-gray-700">교재</span>
                          <span className="flex-1 text-gray-900">{item.textbook ?? '-'}</span>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div>
                          <span className="text-gray-700">지도목표: </span>
                          <span className="text-gray-900 whitespace-pre-line">{item.goals ?? '-'}</span>
                        </div>
                        <div>
                          <span className="text-gray-700">주요 교수계획: </span>
                          <span className="text-gray-900 whitespace-pre-line">{item.mainPlan ?? '-'}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-gray-500">
                  등록된 교수계획서가 없습니다.
                </div>
              )}
            </section>

            {/* 5. 수행평가서 */}
            <section>
              <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
                5. 수행평가서
              </h3>
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                        평가방법
                      </th>
                      <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                        평가영역
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {evaluations.length > 0 ? (
                      evaluations.map((item, index) => (
                        <tr key={item.id ?? String(index)} className="border-b border-gray-200 last:border-b-0">
                          <td className="px-4 py-3 text-sm text-gray-900">{item.method ?? '-'}</td>
                          <td className="px-4 py-3 text-sm text-gray-600 whitespace-pre-line">{item.area ?? '-'}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={2} className="px-4 py-8 text-center text-sm text-gray-500">
                          등록된 수행평가 항목이 없습니다.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </section>

            {/* Footer */}
            <div className="pt-8 mt-8 border-t border-gray-200 text-center text-sm text-gray-600">
              <p>작성일: {detail.reg_date_conv ?? new Date().toLocaleDateString('ko-KR')}</p>
              <p className="mt-2">담당교수: {plan?.basic?.instructor ?? '-'}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
