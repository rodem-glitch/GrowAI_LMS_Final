import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Save, Info, BookOpen, ChevronRight, Search } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface CurriculumItem {
  id: string;
  type: 'NCS' | 'non-NCS' | 'liberal-arts';
  hours: string;
  description: string;
}

interface TeachingPlan {
  id: string;
  courseName: string;
  targetDepartment: string;
  courseType: string;
  trainingHours: string;
  instructor: string;
  goals: string;
  textbook: string;
  mainPlan: string;
}

interface Evaluation {
  id: string;
  method: string;
  area: string;
}

interface Subject {
  id: string;
  name: string;
  year: string;
  semester: string;
  credits: string;
}

type Step = 'basic' | 'subjects';

const CLASSIFICATION_LABELS: Record<string, string> = {
  'degree-major': '학위전공',
  'degree-major-advanced': '학위전공심화',
  'professional-tech': '전문기술',
  'high-tech': '하이테크',
  'master-craftsman': '기능장',
  'high-school-consignment': '고교위탁',
  'new-seniors': '신중년',
};

const TRAINING_LEVEL_LABELS: Record<string, string> = {
  beginner: '초급',
  intermediate: '중급',
  advanced: '고급',
};

function buildPlanJson(params: {
  classification: string;
  courseName: string;
  department: string;
  major: string;
  departmentName: string;
  trainingPeriodText: string;
  startDateYmd: string;
  endDateYmd: string;
  trainingLevel: string;
  trainingTarget: string;
  trainingGoal: string;
  curriculumItems: CurriculumItem[];
  teachingPlans: TeachingPlan[];
  evaluations: Evaluation[];
}) {
  return {
    version: 1,
    basic: {
      classification: {
        value: params.classification,
        label: CLASSIFICATION_LABELS[params.classification] ?? params.classification,
      },
      courseName: params.courseName,
      department: params.department,
      major: params.major,
      departmentName: params.departmentName,
    },
    training: {
      trainingPeriodText: params.trainingPeriodText,
      startDateYmd: params.startDateYmd,
      endDateYmd: params.endDateYmd,
      trainingLevel: {
        value: params.trainingLevel,
        label: TRAINING_LEVEL_LABELS[params.trainingLevel] ?? params.trainingLevel,
      },
      trainingTarget: params.trainingTarget,
      trainingGoal: params.trainingGoal,
    },
    curriculum: params.curriculumItems,
    teachingPlans: params.teachingPlans,
    evaluations: params.evaluations,
  };
}

function normalizeDateToYmd(input: string) {
  const digits = input.replace(/[^0-9]/g, '');
  return digits.length === 8 ? digits : '';
}

function parseTrainingPeriod(input: string) {
  const value = input.trim();
  if (!value) return null;

  const match = value.match(
    /(\d{4}[.\-\/]\d{2}[.\-\/]\d{2}|\d{8})\s*(?:-|~|–|—)\s*(\d{4}[.\-\/]\d{2}[.\-\/]\d{2}|\d{8})/
  );
  if (!match) return null;

  const start = normalizeDateToYmd(match[1]);
  const end = normalizeDateToYmd(match[2]);
  if (!start || !end) return null;

  return { start, end };
}

export function CreateCourseForm() {
  const [currentStep, setCurrentStep] = useState<Step>('basic');
  const [courseCategory, setCourseCategory] = useState('');
  const [classification, setClassification] = useState('');
  const [courseName, setCourseName] = useState('');
  const [department, setDepartment] = useState('');
  const [major, setMajor] = useState('');
  const [departmentName, setDepartmentName] = useState('');
  const [trainingPeriod, setTrainingPeriod] = useState('');
  const [trainingLevel, setTrainingLevel] = useState('');
  const [trainingTarget, setTrainingTarget] = useState('');
  const [trainingGoal, setTrainingGoal] = useState('');
  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [curriculumItems, setCurriculumItems] = useState<CurriculumItem[]>([]);
  const [teachingPlans, setTeachingPlans] = useState<TeachingPlan[]>([]);
  const [evaluations, setEvaluations] = useState<Evaluation[]>([]);
  
  // 과목 관련 상태
  const [selectedSubjects, setSelectedSubjects] = useState<Subject[]>([]);
  const [availableSubjects, setAvailableSubjects] = useState<Subject[]>([]);
  const [subjectSearchTerm, setSubjectSearchTerm] = useState('');
  const [loadingSubjects, setLoadingSubjects] = useState(false);

  const steps = [
    { id: 'basic' as Step, label: '기본 정보', icon: Info },
    { id: 'subjects' as Step, label: '소속 과목', icon: BookOpen },
  ];

  const currentStepIndex = steps.findIndex((s) => s.id === currentStep);

  // 과목 목록 불러오기
  useEffect(() => {
    if (currentStep === 'subjects') {
      loadAvailableSubjects();
    }
  }, [currentStep]);

  const loadAvailableSubjects = async () => {
    setLoadingSubjects(true);
    try {
      const res = await tutorLmsApi.getCourses({ page: 1, limit: 100 });
      if (res.rst_code === '0000' && res.rst_data) {
        const subjects: Subject[] = res.rst_data.map((row: any) => ({
          id: String(row.id || row.course_id),
          name: String(row.course_nm || row.name || ''),
          year: String(row.year || ''),
          semester: String(row.semester || ''),
          credits: String(row.credit || ''),
        }));
        setAvailableSubjects(subjects);
      }
    } catch (e) {
      console.error('과목 목록 조회 실패:', e);
    } finally {
      setLoadingSubjects(false);
    }
  };

  const addCurriculumItem = () => {
    setCurriculumItems([
      ...curriculumItems,
      { id: Date.now().toString(), type: 'NCS', hours: '', description: '' },
    ]);
  };

  const removeCurriculumItem = (id: string) => {
    setCurriculumItems(curriculumItems.filter((item) => item.id !== id));
  };

  const updateCurriculumItem = (id: string, field: keyof CurriculumItem, value: string) => {
    setCurriculumItems(
      curriculumItems.map((item) =>
        item.id === id ? { ...item, [field]: value } : item
      )
    );
  };

  const addTeachingPlan = () => {
    setTeachingPlans([
      ...teachingPlans,
      {
        id: Date.now().toString(),
        courseName: '',
        targetDepartment: '',
        courseType: '',
        trainingHours: '',
        instructor: '',
        goals: '',
        textbook: '',
        mainPlan: '',
      },
    ]);
  };

  const removeTeachingPlan = (id: string) => {
    setTeachingPlans(teachingPlans.filter((plan) => plan.id !== id));
  };

  const updateTeachingPlan = (id: string, field: keyof TeachingPlan, value: string) => {
    setTeachingPlans(
      teachingPlans.map((plan) =>
        plan.id === id ? { ...plan, [field]: value } : plan
      )
    );
  };

  const addEvaluation = () => {
    setEvaluations([
      ...evaluations,
      { id: Date.now().toString(), method: '', area: '' },
    ]);
  };

  const removeEvaluation = (id: string) => {
    setEvaluations(evaluations.filter((evalItem) => evalItem.id !== id));
  };

  const updateEvaluation = (id: string, field: keyof Evaluation, value: string) => {
    setEvaluations(
      evaluations.map((evalItem) =>
        evalItem.id === id ? { ...evalItem, [field]: value } : evalItem
      )
    );
  };

  const validateBasicInfo = (): boolean => {
    setErrorMessage(null);

    if (!classification) {
      setErrorMessage('과정 분류를 선택해 주세요.');
      return false;
    }

    if (!courseName.trim()) {
      setErrorMessage('과정명을 입력해 주세요.');
      return false;
    }

    const parsed = parseTrainingPeriod(trainingPeriod);
    if (!parsed) {
      setErrorMessage('교육훈련기간을 "YYYY.MM.DD - YYYY.MM.DD" 형식으로 입력해 주세요.');
      return false;
    }

    return true;
  };

  const handleNext = () => {
    if (currentStep === 'basic') {
      if (!validateBasicInfo()) return;
      setCurrentStep('subjects');
    }
  };

  const handlePrev = () => {
    if (currentStep === 'subjects') {
      setCurrentStep('basic');
    }
  };

  const addSubject = (subject: Subject) => {
    if (!selectedSubjects.find((s) => s.id === subject.id)) {
      setSelectedSubjects([...selectedSubjects, subject]);
    }
  };

  const removeSubject = (id: string) => {
    setSelectedSubjects(selectedSubjects.filter((s) => s.id !== id));
  };

  const filteredSubjects = availableSubjects.filter(
    (subject) =>
      subject.name.toLowerCase().includes(subjectSearchTerm.toLowerCase()) &&
      !selectedSubjects.find((s) => s.id === subject.id)
  );

  const handleSubmit = async () => {
    setErrorMessage(null);

    const parsed = parseTrainingPeriod(trainingPeriod);
    if (!parsed) {
      setErrorMessage('교육훈련기간이 올바르지 않습니다.');
      return;
    }

    setSaving(true);
    try {
      const planJson = JSON.stringify(buildPlanJson({
        classification,
        courseName: courseName.trim(),
        department: department.trim(),
        major: major.trim(),
        departmentName: departmentName.trim(),
        trainingPeriodText: trainingPeriod.trim(),
        startDateYmd: parsed.start,
        endDateYmd: parsed.end,
        trainingLevel,
        trainingTarget: trainingTarget.trim(),
        trainingGoal: trainingGoal.trim(),
        curriculumItems,
        teachingPlans,
        evaluations,
      }));

      const res = await tutorLmsApi.createProgram({
        courseName: courseName.trim(),
        startDate: parsed.start,
        endDate: parsed.end,
        planJson,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      // TODO: 선택된 과목들을 과정에 연결하는 API 호출 (추후 구현)
      // const programId = res.rst_data;
      // for (const subject of selectedSubjects) {
      //   await tutorLmsApi.linkCourseToProgram({ programId, courseId: subject.id });
      // }

      alert('과정이 개설되었습니다.');
      resetForm();
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  const resetForm = () => {
    setCurrentStep('basic');
    setCourseCategory('');
    setClassification('');
    setCourseName('');
    setDepartment('');
    setMajor('');
    setDepartmentName('');
    setTrainingPeriod('');
    setTrainingLevel('');
    setTrainingTarget('');
    setTrainingGoal('');
    setCurriculumItems([]);
    setTeachingPlans([]);
    setEvaluations([]);
    setSelectedSubjects([]);
  };

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">과정 개설</h2>
        <p className="text-gray-600">새로운 교육 과정을 개설합니다.</p>
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
          {errorMessage}
        </div>
      )}

      {/* Stepper */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const isActive = step.id === currentStep;
            const isCompleted = index < currentStepIndex;

            return (
              <React.Fragment key={step.id}>
                <div className="flex items-center">
                  <div
                    className={`flex items-center justify-center w-10 h-10 rounded-full ${
                      isActive || isCompleted
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-200 text-gray-600'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                  </div>
                  <span
                    className={`ml-3 ${
                      isActive ? 'text-blue-600 font-medium' : isCompleted ? 'text-blue-600' : 'text-gray-500'
                    }`}
                  >
                    {step.label}
                  </span>
                </div>
                {index < steps.length - 1 && (
                  <div
                    className={`flex-1 h-0.5 mx-4 ${
                      isCompleted ? 'bg-blue-600' : 'bg-gray-200'
                    }`}
                  />
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>

      {/* Step Content */}
      {currentStep === 'basic' && (
        <BasicInfoStep
          courseCategory={courseCategory}
          setCourseCategory={setCourseCategory}
          classification={classification}
          setClassification={setClassification}
          courseName={courseName}
          setCourseName={setCourseName}
          departmentName={departmentName}
          setDepartmentName={setDepartmentName}
          major={major}
          setMajor={setMajor}
          trainingPeriod={trainingPeriod}
          setTrainingPeriod={setTrainingPeriod}
          trainingLevel={trainingLevel}
          setTrainingLevel={setTrainingLevel}
          trainingTarget={trainingTarget}
          setTrainingTarget={setTrainingTarget}
          trainingGoal={trainingGoal}
          setTrainingGoal={setTrainingGoal}
          curriculumItems={curriculumItems}
          addCurriculumItem={addCurriculumItem}
          removeCurriculumItem={removeCurriculumItem}
          updateCurriculumItem={updateCurriculumItem}
          teachingPlans={teachingPlans}
          addTeachingPlan={addTeachingPlan}
          removeTeachingPlan={removeTeachingPlan}
          updateTeachingPlan={updateTeachingPlan}
          evaluations={evaluations}
          addEvaluation={addEvaluation}
          removeEvaluation={removeEvaluation}
          updateEvaluation={updateEvaluation}
        />
      )}

      {currentStep === 'subjects' && (
        <SubjectsStep
          selectedSubjects={selectedSubjects}
          availableSubjects={filteredSubjects}
          searchTerm={subjectSearchTerm}
          setSearchTerm={setSubjectSearchTerm}
          addSubject={addSubject}
          removeSubject={removeSubject}
          loading={loadingSubjects}
          courseName={courseName}
        />
      )}

      {/* Navigation Buttons */}
      <div className="flex items-center justify-between pt-6 mt-6">
        <button
          onClick={handlePrev}
          disabled={currentStepIndex === 0}
          className="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          이전
        </button>
        {currentStep === 'basic' ? (
          <button
            onClick={handleNext}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <span>다음</span>
            <ChevronRight className="w-5 h-5" />
          </button>
        ) : (
          <button
            onClick={handleSubmit}
            disabled={saving}
            className="flex items-center gap-2 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <Save className="w-5 h-5" />
            <span>{saving ? '저장 중...' : '과정 개설 완료'}</span>
          </button>
        )}
      </div>
    </div>
  );
}

// 기본 정보 입력 단계
function BasicInfoStep({
  courseCategory,
  setCourseCategory,
  classification,
  setClassification,
  courseName,
  setCourseName,
  departmentName,
  setDepartmentName,
  major,
  setMajor,
  trainingPeriod,
  setTrainingPeriod,
  trainingLevel,
  setTrainingLevel,
  trainingTarget,
  setTrainingTarget,
  trainingGoal,
  setTrainingGoal,
  curriculumItems,
  addCurriculumItem,
  removeCurriculumItem,
  updateCurriculumItem,
  teachingPlans,
  addTeachingPlan,
  removeTeachingPlan,
  updateTeachingPlan,
  evaluations,
  addEvaluation,
  removeEvaluation,
  updateEvaluation,
}: {
  courseCategory: string;
  setCourseCategory: (v: string) => void;
  classification: string;
  setClassification: (v: string) => void;
  courseName: string;
  setCourseName: (v: string) => void;
  departmentName: string;
  setDepartmentName: (v: string) => void;
  major: string;
  setMajor: (v: string) => void;
  trainingPeriod: string;
  setTrainingPeriod: (v: string) => void;
  trainingLevel: string;
  setTrainingLevel: (v: string) => void;
  trainingTarget: string;
  setTrainingTarget: (v: string) => void;
  trainingGoal: string;
  setTrainingGoal: (v: string) => void;
  curriculumItems: CurriculumItem[];
  addCurriculumItem: () => void;
  removeCurriculumItem: (id: string) => void;
  updateCurriculumItem: (id: string, field: keyof CurriculumItem, value: string) => void;
  teachingPlans: TeachingPlan[];
  addTeachingPlan: () => void;
  removeTeachingPlan: (id: string) => void;
  updateTeachingPlan: (id: string, field: keyof TeachingPlan, value: string) => void;
  evaluations: Evaluation[];
  addEvaluation: () => void;
  removeEvaluation: (id: string) => void;
  updateEvaluation: (id: string, field: keyof Evaluation, value: string) => void;
}) {
  return (
    <>
      {/* 기본 정보 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h3 className="text-gray-900 mb-4">기본 정보</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">
              과정 유형 <span className="text-red-500">*</span>
            </label>
            <select
              value={courseCategory}
              onChange={(e) => {
                const newCategory = e.target.value;
                setCourseCategory(newCategory);
                const nonRegularClassifications = ['professional-tech', 'master-craftsman', 'new-seniors', 'high-tech'];
                if (newCategory === 'non-regular' && classification && !nonRegularClassifications.includes(classification)) {
                  setClassification('');
                }
              }}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              <option value="regular" disabled className="text-gray-400">정규과정</option>
              <option value="non-regular">비정규과정</option>
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">
              과정 분류 <span className="text-red-500">*</span>
            </label>
            <select
              value={classification}
              onChange={(e) => setClassification(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={!courseCategory}
            >
              <option value="">선택하세요</option>
              {courseCategory === 'regular' && (
                <>
                  <option value="degree-major">학위전공</option>
                  <option value="degree-major-advanced">학위전공심화</option>
                  <option value="professional-tech">전문기술</option>
                  <option value="high-tech">하이테크</option>
                  <option value="master-craftsman">기능장</option>
                  <option value="high-school-consignment">고교위탁</option>
                  <option value="new-seniors">신중년</option>
                </>
              )}
              {courseCategory === 'non-regular' && (
                <>
                  <option value="professional-tech">전문기술</option>
                  <option value="master-craftsman">기능장</option>
                  <option value="new-seniors">신중년</option>
                  <option value="high-tech">하이테크</option>
                </>
              )}
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">학과명</label>
            <input
              type="text"
              value={departmentName}
              onChange={(e) => setDepartmentName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="학과명을 입력하세요"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">전공/직종</label>
            <input
              type="text"
              value={major}
              onChange={(e) => setMajor(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="전공/직종을 입력하세요"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정명</label>
            <input
              type="text"
              value={courseName}
              onChange={(e) => setCourseName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="과정명을 입력하세요"
            />
          </div>
        </div>
      </div>

      {/* 교육훈련 정보 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h3 className="text-gray-900 mb-4">교육훈련 정보</h3>
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육훈련기간</label>
            <input
              type="text"
              value={trainingPeriod}
              onChange={(e) => setTrainingPeriod(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="예: 2024.03.01 - 2024.12.31"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육훈련수준</label>
            <select
              value={trainingLevel}
              onChange={(e) => setTrainingLevel(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              <option value="beginner">초급</option>
              <option value="intermediate">중급</option>
              <option value="advanced">고급</option>
            </select>
          </div>
        </div>
        <div className="mb-4">
          <label className="block text-sm text-gray-700 mb-2">교육훈련대상자</label>
          <input
            type="text"
            value={trainingTarget}
            onChange={(e) => setTrainingTarget(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="교육훈련대상자를 입력하세요"
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">교육훈련목표</label>
          <textarea
            rows={4}
            value={trainingGoal}
            onChange={(e) => setTrainingGoal(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="교육훈련목표를 입력하세요"
          />
        </div>
      </div>

      {/* 교육훈련 교과편성 총괄표 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">교육훈련 교과편성 총괄표</h3>
          <button
            type="button"
            onClick={addCurriculumItem}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>항목 추가</span>
          </button>
        </div>
        {curriculumItems.length > 0 ? (
          <div className="space-y-3">
            {curriculumItems.map((item) => (
              <div key={item.id} className="flex gap-3 items-start p-4 bg-gray-50 rounded-lg">
                <div className="flex-1 grid grid-cols-3 gap-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">구분</label>
                    <select
                      value={item.type}
                      onChange={(e) => updateCurriculumItem(item.id, 'type', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="NCS">NCS</option>
                      <option value="non-NCS">비NCS</option>
                      <option value="liberal-arts">교양</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">시수</label>
                    <input
                      type="text"
                      value={item.hours}
                      onChange={(e) => updateCurriculumItem(item.id, 'hours', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="시수"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">설명</label>
                    <input
                      type="text"
                      value={item.description}
                      onChange={(e) => updateCurriculumItem(item.id, 'description', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="설명"
                    />
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => removeCurriculumItem(item.id)}
                  className="mt-6 p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>교과편성 항목을 추가해주세요</p>
          </div>
        )}
      </div>

      {/* 교수계획서 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">교수계획서</h3>
          <button
            type="button"
            onClick={addTeachingPlan}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>계획서 추가</span>
          </button>
        </div>
        {teachingPlans.length > 0 ? (
          <div className="space-y-4">
            {teachingPlans.map((plan) => (
              <div key={plan.id} className="p-4 bg-gray-50 rounded-lg">
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교과목명</label>
                    <input
                      type="text"
                      value={plan.courseName}
                      onChange={(e) => updateTeachingPlan(plan.id, 'courseName', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교과목명"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">대상학과</label>
                    <input
                      type="text"
                      value={plan.targetDepartment}
                      onChange={(e) => updateTeachingPlan(plan.id, 'targetDepartment', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="대상학과"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교과구분</label>
                    <input
                      type="text"
                      value={plan.courseType}
                      onChange={(e) => updateTeachingPlan(plan.id, 'courseType', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교과구분"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교육훈련시간</label>
                    <input
                      type="text"
                      value={plan.trainingHours}
                      onChange={(e) => updateTeachingPlan(plan.id, 'trainingHours', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교육훈련시간"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교수명</label>
                    <input
                      type="text"
                      value={plan.instructor}
                      onChange={(e) => updateTeachingPlan(plan.id, 'instructor', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교수명"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교재</label>
                    <input
                      type="text"
                      value={plan.textbook}
                      onChange={(e) => updateTeachingPlan(plan.id, 'textbook', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교재"
                    />
                  </div>
                </div>
                <div className="mb-3">
                  <label className="block text-sm text-gray-700 mb-1">지도목표</label>
                  <textarea
                    rows={2}
                    value={plan.goals}
                    onChange={(e) => updateTeachingPlan(plan.id, 'goals', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="지도목표"
                  />
                </div>
                <div className="mb-3">
                  <label className="block text-sm text-gray-700 mb-1">주요 교수계획</label>
                  <textarea
                    rows={3}
                    value={plan.mainPlan}
                    onChange={(e) => updateTeachingPlan(plan.id, 'mainPlan', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="주요 교수계획"
                  />
                </div>
                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={() => removeTeachingPlan(plan.id)}
                    className="flex items-center gap-2 px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                    <span>삭제</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>교수계획서를 추가해주세요</p>
          </div>
        )}
      </div>

      {/* 수행평가서 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">수행평가서</h3>
          <button
            type="button"
            onClick={addEvaluation}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>평가 추가</span>
          </button>
        </div>
        {evaluations.length > 0 ? (
          <div className="space-y-3">
            {evaluations.map((evaluation) => (
              <div key={evaluation.id} className="flex gap-3 items-start p-4 bg-gray-50 rounded-lg">
                <div className="flex-1 grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">평가방법</label>
                    <input
                      type="text"
                      value={evaluation.method}
                      onChange={(e) => updateEvaluation(evaluation.id, 'method', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: 필기시험, 실기평가, 과제"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">평가영역</label>
                    <input
                      type="text"
                      value={evaluation.area}
                      onChange={(e) => updateEvaluation(evaluation.id, 'area', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: 이론, 실습, 태도"
                    />
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => removeEvaluation(evaluation.id)}
                  className="mt-6 p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>수행평가 항목을 추가해주세요</p>
          </div>
        )}
      </div>
    </>
  );
}

// 소속 과목 추가 단계
function SubjectsStep({
  selectedSubjects,
  availableSubjects,
  searchTerm,
  setSearchTerm,
  addSubject,
  removeSubject,
  loading,
  courseName,
}: {
  selectedSubjects: Subject[];
  availableSubjects: Subject[];
  searchTerm: string;
  setSearchTerm: (v: string) => void;
  addSubject: (subject: Subject) => void;
  removeSubject: (id: string) => void;
  loading: boolean;
  courseName: string;
}) {
  return (
    <div className="space-y-6">
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p className="text-blue-800">
          <strong>"{courseName}"</strong> 과정에 포함될 과목을 선택하세요.
        </p>
      </div>

      {/* 선택된 과목 목록 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-gray-900 mb-4">선택된 소속 과목 ({selectedSubjects.length}개)</h3>
        {selectedSubjects.length > 0 ? (
          <div className="space-y-2">
            {selectedSubjects.map((subject) => (
              <div
                key={subject.id}
                className="flex items-center justify-between p-4 bg-green-50 border border-green-200 rounded-lg"
              >
                <div>
                  <p className="font-medium text-gray-900">{subject.name}</p>
                  <p className="text-sm text-gray-500">
                    {subject.year} {subject.semester} {subject.credits && `• ${subject.credits}학점`}
                  </p>
                </div>
                <button
                  onClick={() => removeSubject(subject.id)}
                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <BookOpen className="w-12 h-12 mx-auto mb-3 opacity-50" />
            <p>선택된 과목이 없습니다.</p>
            <p className="text-sm">아래에서 과목을 검색하여 추가하세요.</p>
          </div>
        )}
      </div>

      {/* 과목 검색 및 추가 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-gray-900 mb-4">과목 검색</h3>
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="과목명으로 검색..."
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {loading ? (
          <div className="text-center py-8 text-gray-500">
            <p>과목 목록을 불러오는 중...</p>
          </div>
        ) : availableSubjects.length > 0 ? (
          <div className="space-y-2 max-h-80 overflow-y-auto">
            {availableSubjects.map((subject) => (
              <div
                key={subject.id}
                className="flex items-center justify-between p-4 bg-gray-50 border border-gray-200 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-900">{subject.name}</p>
                  <p className="text-sm text-gray-500">
                    {subject.year} {subject.semester} {subject.credits && `• ${subject.credits}학점`}
                  </p>
                </div>
                <button
                  onClick={() => addSubject(subject)}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>추가</span>
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>검색 결과가 없습니다.</p>
          </div>
        )}
      </div>
    </div>
  );
}
