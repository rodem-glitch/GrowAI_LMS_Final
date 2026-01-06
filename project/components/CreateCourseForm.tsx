import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Save, Info, BookOpen, ChevronRight, Search, Eye, X, Video } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';
import { OperationalPlan } from './OperationalPlan';
import { CreateSubjectWizard } from './CreateSubjectWizard';
import { ContentLibraryModal } from './ContentLibraryModal';
import { CurriculumEditor } from './CurriculumEditor';

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
  // OperationalPlan 호환용 필드
  classification: string;
  department: string;
  major: string;
  departmentName: string;
  trainingPeriod: string;
  trainingLevel: string;
  trainingTarget: string;
  trainingGoal: string;
  instructor: string;
  students: number;
  subjects: number;
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
  courseCategory: string;
  classification: string;
  courseName: string;
  department: string;
  major: string;
  departmentName: string;
  courseDescription: string;
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
      courseCategory: {
        value: params.courseCategory,
        label: params.courseCategory === 'regular' ? '정규과정' : params.courseCategory === 'non-regular' ? '비정규과정' : params.courseCategory,
      },
      classification: {
        value: params.classification,
        label: CLASSIFICATION_LABELS[params.classification] ?? params.classification,
      },
      courseName: params.courseName,
      department: params.department,
      major: params.major,
      departmentName: params.departmentName,
      courseDescription: params.courseDescription,
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

interface CreateCourseFormProps {
  onCreated?: () => void;
  initialStep?: Step;
  onStepChange?: (step: Step) => void;
}

export function CreateCourseForm({ onCreated, initialStep, onStepChange }: CreateCourseFormProps = {}) {
  const [currentStep, setCurrentStep] = useState<Step>(initialStep ?? 'basic');
  useEffect(() => {
    // 왜: URL(부모)에서 내려온 step을 로컬 state에 "한 번만" 동기화해야 합니다.
    //     currentStep을 의존성에 넣으면, 사용자가 다음/이전으로 step을 바꾸는 순간
    //     아직 URL이 갱신되기 전(같은 커밋)에는 initialStep 값이 이전 단계로 남아 있어서
    //     화면이 잠깐 바뀌었다가 원래 단계로 되돌아오는 "깜빡임/되돌림"이 생길 수 있습니다.
    const nextStep: Step = initialStep ?? 'basic';
    setCurrentStep((prev) => (prev === nextStep ? prev : nextStep));
  }, [initialStep]);

  useEffect(() => {
    // 왜: 단계 변경을 주소와 동기화하기 위해 바깥에 알려줍니다.
    onStepChange?.(currentStep);
  }, [currentStep, onStepChange]);
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
  const [courseDescription, setCourseDescription] = useState('');
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
      // PLISM 과정탐색과 동일하게 getPrograms API 사용
      const res = await tutorLmsApi.getPrograms();
      if (res.rst_code === '0000' && res.rst_data) {
        const subjects: Subject[] = res.rst_data.map((row: any) => {
          // plan_json 파싱
          let plan: any = null;
          try {
            if (row.plan_json) {
              plan = JSON.parse(row.plan_json);
            }
          } catch {}
          
          // 연도 추출
          let year = '-';
          const startDate = plan?.training?.startDateYmd || row.start_date || '';
          if (startDate && startDate.length >= 4) {
            year = startDate.substring(0, 4);
          }

          const trainingPeriod = plan?.training?.trainingPeriodText || row.training_period || '-';
          
          return {
            id: String(row.id),
            name: row.course_nm || plan?.basic?.courseName || `과정 ${row.id}`,
            year,
            semester: '',
            credits: '',
            // OperationalPlan 호환 필드
            classification: plan?.basic?.classification?.label || plan?.basic?.classification?.value || '미분류',
            department: plan?.basic?.department || '',
            major: plan?.basic?.major || '',
            departmentName: plan?.basic?.departmentName || '',
            trainingPeriod,
            trainingLevel: plan?.training?.trainingLevel?.label || plan?.training?.trainingLevel?.value || '-',
            trainingTarget: plan?.training?.trainingTarget || '',
            trainingGoal: plan?.training?.trainingGoal || '',
            instructor: plan?.basic?.instructor || '',
            students: 0,
            subjects: Number(row.course_cnt ?? 0),
          };
        });
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

    if (!courseCategory) {
      setErrorMessage('과정 유형을 선택해 주세요.');
      return false;
    }

    if (!classification) {
      setErrorMessage('과정 분류를 선택해 주세요.');
      return false;
    }

    if (!courseName.trim()) {
      setErrorMessage('과정명을 입력해 주세요.');
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

    // 교육훈련기간은 선택사항으로 처리
    const parsed = parseTrainingPeriod(trainingPeriod);

    setSaving(true);
    try {
      const planJson = JSON.stringify(buildPlanJson({
        courseCategory,
        classification,
        courseName: courseName.trim(),
        department: department.trim(),
        major: major.trim(),
        departmentName: departmentName.trim(),
        courseDescription: courseDescription.trim(),
        trainingPeriodText: trainingPeriod.trim(),
        startDateYmd: parsed?.start || '',
        endDateYmd: parsed?.end || '',
        trainingLevel,
        trainingTarget: trainingTarget.trim(),
        trainingGoal: trainingGoal.trim(),
        curriculumItems,
        teachingPlans,
        evaluations,
      }));

      const res = await tutorLmsApi.createProgram({
        courseName: courseName.trim(),
        startDate: parsed?.start || '',
        endDate: parsed?.end || '',
        planJson,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      // 왜: 과정 생성 직후 선택된 과목을 소속 과정으로 연결합니다.
      const programId = Number(res.rst_data ?? 0);
      if (programId > 0 && selectedSubjects.length > 0) {
        for (const subject of selectedSubjects) {
          const courseId = Number(subject.id);
          if (!courseId) continue;
          const linkRes = await tutorLmsApi.setCourseProgram({ courseId, programId });
          if (linkRes.rst_code !== '0000') throw new Error(linkRes.rst_message);
        }
      }

      alert('과정이 개설되었습니다.');
      onCreated?.();
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
    setCourseDescription('');
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
          courseDescription={courseDescription}
          setCourseDescription={setCourseDescription}
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
  courseDescription,
  setCourseDescription,
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
  courseDescription: string;
  setCourseDescription: (v: string) => void;
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

      {/* 과정설명 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h3 className="text-gray-900 mb-4">과정설명</h3>
        <div>
          <label className="block text-sm text-gray-700 mb-2">과정 소개</label>
          <textarea
            value={courseDescription}
            onChange={(e) => setCourseDescription(e.target.value)}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-y min-h-[120px]"
            placeholder="과정에 대한 소개 및 설명을 입력하세요"
            rows={5}
          />
          <p className="text-sm text-gray-500 mt-2">과정의 목적, 대상, 특징 등을 자유롭게 작성해 주세요.</p>
        </div>
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
  // 왜: 학사 탭은 현재 사용하지 않으므로 기본 탭을 'plism'으로 설정합니다.
  const [activeTab, setActiveTab] = React.useState<'haksa' | 'plism'>('plism');
  const [detailSubject, setDetailSubject] = React.useState<Subject | null>(null);
  const [showNewSubjectForm, setShowNewSubjectForm] = React.useState(false);
  
  // PLISM 과목 검색 관련 state
  const [plismCourses, setPlismCourses] = React.useState<Subject[]>([]);
  const [plismLoading, setPlismLoading] = React.useState(false);
  const [plismError, setPlismError] = React.useState<string | null>(null);
  const [plismSearchTerm, setPlismSearchTerm] = React.useState('');

  // 과목 복사 모달 관련 state
  const [isCopyModalOpen, setIsCopyModalOpen] = React.useState(false);
  const [copySourceCourse, setCopySourceCourse] = React.useState<Subject | null>(null);
  const [copyCourseName, setCopyCourseName] = React.useState('');
  const [copyTutorId, setCopyTutorId] = React.useState<number | ''>('');
  const [copySaving, setCopySaving] = React.useState(false);
  const [tutorOptions, setTutorOptions] = React.useState<Array<{ id: number; name: string }>>([]);
  const [tutorLoading, setTutorLoading] = React.useState(false);
  const [tutorError, setTutorError] = React.useState<string | null>(null);

  // 차시 편집 관련 state
  const [editingCourse, setEditingCourse] = React.useState<Subject | null>(null);
  const [curriculumData, setCurriculumData] = React.useState<any[]>([]);
  const [originalCurriculumData, setOriginalCurriculumData] = React.useState<any[]>([]); // 원본 데이터 (삭제 비교용)
  const [curriculumLoading, setCurriculumLoading] = React.useState(false);
  const [curriculumSaving, setCurriculumSaving] = React.useState(false);
  const [curriculumError, setCurriculumError] = React.useState<string | null>(null);
  
  // 영상 추가 모달 관련 state
  const [isContentModalOpen, setIsContentModalOpen] = React.useState(false);
  const [currentSectionId, setCurrentSectionId] = React.useState<number | null>(null);

  // 차시 편집을 위해 과목 선택 시 차시 불러오기
  const handleEditCurriculum = async (course: Subject) => {
    // 왜: 원본 과목을 직접 편집하지 않도록 복사 모달을 먼저 띄웁니다.
    setCopySourceCourse(course);
    setCopyCourseName(`${course.name} (복사본)`);
    setCopyTutorId('');
    setTutorError(null);
    setIsCopyModalOpen(true);
  };

  // 차시 편집 닫기
  const closeCurriculumEditor = () => {
    setEditingCourse(null);
    setCurriculumData([]);
    setOriginalCurriculumData([]);
    setCurriculumError(null);
  };

  // 과목 복사 모달 닫기
  const closeCopyModal = () => {
    setIsCopyModalOpen(false);
    setCopySourceCourse(null);
    setCopyCourseName('');
    setCopyTutorId('');
    setTutorError(null);
  };

  // 담당 교수/강사 목록 로드
  React.useEffect(() => {
    if (!isCopyModalOpen) return;
    let cancelled = false;

    const fetchTutors = async () => {
      setTutorLoading(true);
      setTutorError(null);
      try {
        const res = await tutorLmsApi.getTutors();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        const rows = res.rst_data ?? [];
        const mapped = rows.map((row: any) => ({
          id: Number(row.user_id),
          name: String(row.tutor_nm || ''),
        }));
        if (!cancelled) setTutorOptions(mapped);
      } catch (e) {
        if (!cancelled) setTutorError(e instanceof Error ? e.message : '교수/강사 목록 조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setTutorLoading(false);
      }
    };

    fetchTutors();
    return () => {
      cancelled = true;
    };
  }, [isCopyModalOpen]);

  // 과목 복사 실행
  const submitCopyCourse = async () => {
    if (!copySourceCourse) return;
    if (!copyCourseName.trim()) {
      alert('새 과목명을 입력해 주세요.');
      return;
    }
    if (!copyTutorId) {
      alert('담당 교수/강사를 선택해 주세요.');
      return;
    }

    setCopySaving(true);
    try {
      const res = await tutorLmsApi.copyCourse({
        sourceCourseId: Number(copySourceCourse.id),
        courseName: copyCourseName.trim(),
        tutorId: Number(copyTutorId),
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const newCourse: Subject = {
        ...copySourceCourse,
        id: String(res.rst_data),
        name: copyCourseName.trim(),
        instructor: tutorOptions.find((t) => t.id === Number(copyTutorId))?.name ?? '',
      };

      closeCopyModal();
      setEditingCourse(newCourse);
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : '과목 복사 중 오류가 발생했습니다.';
      setTutorError(errorMsg);
      alert(errorMsg);
    } finally {
      setCopySaving(false);
    }
  };

  // 섹션 추가
  const addSection = () => {
    const newSection = {
      sectionId: Date.now(), // 임시 ID (음수로 표시하여 신규임을 구분)
      sectionName: `${curriculumData.length + 1}차시`,
      lessons: [],
      isNew: true,
    };
    setCurriculumData([...curriculumData, newSection]);
  };

  // 섹션명 수정
  const updateSectionName = (sectionId: number, name: string) => {
    setCurriculumData(curriculumData.map(s => 
      s.sectionId === sectionId ? { ...s, sectionName: name } : s
    ));
  };

  // 섹션 삭제
  const removeSection = (sectionId: number) => {
    setCurriculumData(curriculumData.filter(s => s.sectionId !== sectionId));
  };

  // 영상 추가 모달 열기
  const openContentModal = (sectionId: number) => {
    setCurrentSectionId(sectionId);
    setIsContentModalOpen(true);
  };

  // 영상 선택 시 해당 섹션에 추가 (단일)
  const handleContentSelect = (content: any) => {
    if (currentSectionId !== null) {
      addLessonToSection(currentSectionId, content);
    }
    setIsContentModalOpen(false);
    setCurrentSectionId(null);
  };

  // 다중 영상 선택 시 해당 섹션에 추가
  const handleMultiContentSelect = (contents: any[]) => {
    if (currentSectionId !== null) {
      contents.forEach(content => addLessonToSection(currentSectionId, content));
    }
    setIsContentModalOpen(false);
    setCurrentSectionId(null);
  };

  // 섹션에 레슨 추가 헬퍼
  const addLessonToSection = (sectionId: number, content: any) => {
    setCurriculumData(prev => prev.map(section => {
      if (section.sectionId === sectionId) {
        // 중복 체크
        if (section.lessons.find((l: any) => String(l.lessonId) === String(content.id))) {
          return section;
        }
        const newLesson = {
          lessonId: content.id,
          lessonName: content.title,
          lessonType: content.lessonType || content.lesson_type || 'VIDEO',
          lessonTypeConv: content.category || '',
          totalTime: content.totalTime || 0,
          completeTime: content.totalTime || 0, // 기본값은 학습시간과 동일
          duration: content.duration || '',
          isNew: true,
        };
        return { ...section, lessons: [...section.lessons, newLesson] };
      }
      return section;
    }));
  };

  // 레슨 삭제
  const removeLesson = (sectionId: number, lessonId: number) => {
    setCurriculumData(curriculumData.map(section => {
      if (section.sectionId === sectionId) {
        return { ...section, lessons: section.lessons.filter((l: any) => l.lessonId !== lessonId) };
      }
      return section;
    }));
  };

  // 인정시간 수정
  const updateLessonCompleteTime = (sectionId: number, lessonId: number, time: number) => {
    setCurriculumData(curriculumData.map(section => {
      if (section.sectionId === sectionId) {
        return {
          ...section,
          lessons: section.lessons.map((l: any) =>
            l.lessonId === lessonId ? { ...l, completeTime: time } : l
          ),
        };
      }
      return section;
    }));
  };

  // 레슨 순서 변경 (위로)
  const moveLessonUp = (sectionId: number, lessonIndex: number) => {
    if (lessonIndex === 0) return;
    setCurriculumData(curriculumData.map(section => {
      if (section.sectionId === sectionId) {
        const lessons = [...section.lessons];
        [lessons[lessonIndex - 1], lessons[lessonIndex]] = [lessons[lessonIndex], lessons[lessonIndex - 1]];
        return { ...section, lessons };
      }
      return section;
    }));
  };

  // 레슨 순서 변경 (아래로)
  const moveLessonDown = (sectionId: number, lessonIndex: number) => {
    setCurriculumData(curriculumData.map(section => {
      if (section.sectionId === sectionId) {
        if (lessonIndex >= section.lessons.length - 1) return section;
        const lessons = [...section.lessons];
        [lessons[lessonIndex], lessons[lessonIndex + 1]] = [lessons[lessonIndex + 1], lessons[lessonIndex]];
        return { ...section, lessons };
      }
      return section;
    }));
  };

  // 차시 저장
  const saveCurriculum = async () => {
    if (!editingCourse) return;
    
    setCurriculumSaving(true);
    setCurriculumError(null);
    
    try {
      const courseId = Number(editingCourse.id);
      console.log('[saveCurriculum] courseId:', courseId);
      console.log('[saveCurriculum] curriculumData:', JSON.stringify(curriculumData, null, 2));
      console.log('[saveCurriculum] originalCurriculumData:', JSON.stringify(originalCurriculumData, null, 2));
      
      // 0. 삭제된 레슨 확인 및 삭제
      const originalLessonIds = new Set<number>();
      for (const section of originalCurriculumData) {
        for (const lesson of section.lessons) {
          originalLessonIds.add(Number(lesson.lessonId));
        }
      }
      
      const currentLessonIds = new Set<number>();
      for (const section of curriculumData) {
        for (const lesson of section.lessons) {
          if (!lesson.isNew) {
            currentLessonIds.add(Number(lesson.lessonId));
          }
        }
      }
      
      // 원본에는 있지만 현재에는 없는 레슨 삭제
      for (const lessonId of originalLessonIds) {
        if (!currentLessonIds.has(lessonId)) {
          console.log('[saveCurriculum] 레슨 삭제:', lessonId);
          const res = await tutorLmsApi.deleteCurriculumLesson({
            courseId,
            lessonId,
          });
          console.log('[saveCurriculum] 레슨 삭제 응답:', res);
          if (res.rst_code !== '0000') throw new Error(res.rst_message);
        }
      }
      
      // 0-1. 삭제된 섹션 확인 및 삭제
      const originalSectionIds = new Set(originalCurriculumData.map(s => s.sectionId));
      const currentSectionIds = new Set(curriculumData.filter(s => !s.isNew).map(s => s.sectionId));
      
      for (const sectionId of originalSectionIds) {
        if (!currentSectionIds.has(sectionId) && sectionId !== 0) {
          console.log('[saveCurriculum] 섹션 삭제:', sectionId);
          const res = await tutorLmsApi.deleteCurriculumSection({
            courseId,
            sectionId,
          });
          console.log('[saveCurriculum] 섹션 삭제 응답:', res);
          // 섹션 삭제 실패는 무시 (이미 삭제된 경우 등)
        }
      }
      
      // 1. 새 섹션 추가
      for (const section of curriculumData) {
        if (section.isNew) {
          console.log('[saveCurriculum] 새 섹션 추가:', section.sectionName);
          const res = await tutorLmsApi.insertCurriculumSection({
            courseId,
            sectionName: section.sectionName,
          });
          console.log('[saveCurriculum] 섹션 추가 응답:', res);
          if (res.rst_code !== '0000') throw new Error(res.rst_message);
          // 섹션 ID 업데이트 (서버에서 반환된 ID)
          section.sectionId = res.rst_data || section.sectionId;
          section.isNew = false;
        }
      }
      
      // 2. 각 섹션의 신규 레슨 추가
      for (const section of curriculumData) {
        for (const lesson of section.lessons) {
          if (lesson.isNew) {
            console.log('[saveCurriculum] 레슨 추가:', lesson.lessonName, 'sectionId:', section.sectionId, 'lessonId:', lesson.lessonId);
            const res = await tutorLmsApi.addCurriculumLesson({
              courseId,
              sectionId: section.sectionId,
              lessonId: Number(lesson.lessonId),
            });
            console.log('[saveCurriculum] 레슨 추가 응답:', res);
            if (res.rst_code !== '0000') throw new Error(res.rst_message);
            lesson.isNew = false;
          }
        }
      }
      
      // 3. 기존 레슨 순서(chapter) 및 인정시간(completeTime) 업데이트
      let chapterOrder = 0;
      for (const section of curriculumData) {
        for (const lesson of section.lessons) {
          chapterOrder++;
          // 원본에서 해당 레슨 찾기
          let originalLesson: any = null;
          for (const origSection of originalCurriculumData) {
            originalLesson = origSection.lessons.find((l: any) => l.lessonId === lesson.lessonId);
            if (originalLesson) break;
          }
          
          // 순서 또는 인정시간이 변경되었는지 확인
          const needsUpdate = 
            (originalLesson && originalLesson.chapter !== chapterOrder) ||
            (originalLesson && originalLesson.completeTime !== lesson.completeTime) ||
            !lesson.isNew; // 기존 레슨은 항상 순서 업데이트
          
          if (needsUpdate && !lesson.isNew) {
            console.log('[saveCurriculum] 레슨 업데이트:', lesson.lessonName, 'chapter:', chapterOrder, 'completeTime:', lesson.completeTime);
            const res = await tutorLmsApi.updateCurriculumLesson({
              courseId,
              lessonId: Number(lesson.lessonId),
              chapter: chapterOrder,
              sectionId: section.sectionId,
              completeTime: lesson.completeTime,
            });
            console.log('[saveCurriculum] 레슨 업데이트 응답:', res);
            // 업데이트 실패는 무시 (신규 추가된 레슨 등)
          }
        }
      }
      
      alert('차시가 저장되었습니다.');
      addSubject(editingCourse);
      closeCurriculumEditor();
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.';
      console.error('[saveCurriculum] 에러:', errorMsg);
      alert('저장 실패: ' + errorMsg);
      setCurriculumError(errorMsg);
    } finally {
      setCurriculumSaving(false);
    }
  };

  // PLISM 탭이 활성화될 때 과목 목록 불러오기
  React.useEffect(() => {
    if (activeTab !== 'plism') return;

    let cancelled = false;
    const fetchPlismCourses = async () => {
      setPlismLoading(true);
      setPlismError(null);
      try {
        const res = await tutorLmsApi.getMyCoursesCombined({ 
          tab: 'prism',
          keyword: plismSearchTerm || undefined 
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const mapped: Subject[] = rows.map((row: any) => ({
          id: String(row.courseId || row.id),
          name: String(row.subjectName || row.course_nm || ''),
          year: String(row.period || row.year || '-').split('-')[0],
          semester: '',
          credits: '',
          // 호환 필드
          classification: String(row.courseType || row.category_nm || '미분류'),
          department: String(row.programName || row.dept_nm || ''),
          major: '',
          departmentName: String(row.programName || ''),
          trainingPeriod: String(row.period || '-'),
          trainingLevel: '-',
          trainingTarget: '',
          trainingGoal: '',
          instructor: '',
          students: Number(row.student_cnt || 0),
          subjects: 0,
        }));

        if (!cancelled) setPlismCourses(mapped);
      } catch (e) {
        if (!cancelled) setPlismError(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setPlismLoading(false);
      }
    };

    const timer = setTimeout(fetchPlismCourses, 300);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [activeTab, plismSearchTerm]);

  // PLISM 검색 결과 필터링 (이미 선택된 과목 제외)
  const filteredPlismCourses = plismCourses.filter(
    (course) => !selectedSubjects.find((s) => s.id === course.id)
  );

  return (
    <>
      {/* 과목 복사 모달 */}
      {isCopyModalOpen && copySourceCourse && (
        <div className="fixed inset-0 bg-gray-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">과목 복사</h3>
                <p className="text-sm text-gray-600">원본: {copySourceCourse.name}</p>
              </div>
              <button onClick={closeCopyModal} className="p-2 hover:bg-gray-100 rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 space-y-4">
              <div>
                <label className="block text-sm text-gray-700 mb-2">새 과목명</label>
                <input
                  type="text"
                  value={copyCourseName}
                  onChange={(e) => setCopyCourseName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="새 과목명을 입력해 주세요."
                />
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">담당 교수/강사</label>
                <select
                  value={copyTutorId}
                  onChange={(e) => setCopyTutorId(e.target.value ? Number(e.target.value) : '')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  disabled={tutorLoading}
                >
                  <option value="">선택해 주세요</option>
                  {tutorOptions.map((tutor) => (
                    <option key={tutor.id} value={tutor.id}>
                      {tutor.name}
                    </option>
                  ))}
                </select>
                {tutorLoading && <p className="text-xs text-gray-500 mt-2">목록을 불러오는 중...</p>}
                {tutorError && <p className="text-xs text-red-600 mt-2">{tutorError}</p>}
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 p-4 border-t border-gray-200">
              <button
                type="button"
                onClick={closeCopyModal}
                className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg"
                disabled={copySaving}
              >
                취소
              </button>
              <button
                type="button"
                onClick={submitCopyCourse}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                disabled={copySaving}
              >
                복사 후 차시 편집
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 차시 편집 - CurriculumEditor 공통 컴포넌트 사용 */}
      {editingCourse && (
        <CurriculumEditor
          courseId={Number(editingCourse.id)}
          courseName={editingCourse.name}
          onClose={closeCurriculumEditor}
          onSaveComplete={() => {
            // 왜: 복사본 차시 저장이 끝나면 선택 과목에 반영하고 모달을 닫습니다.
            addSubject(editingCourse);
            closeCurriculumEditor();
          }}
        />
      )}

      {/* 신규 과목 개설 전체 화면 */}
      {showNewSubjectForm && (
        <div className="fixed inset-0 bg-white z-50 overflow-y-auto">
          {/* 상단 액션 바 */}
          <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10 shadow-sm">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowNewSubjectForm(false)}
                className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
                <span>닫기</span>
              </button>
              <span className="text-gray-400">|</span>
              <h2 className="text-lg font-semibold text-gray-900">소속 과목 신규 개설</h2>
            </div>
          </div>
          {/* CreateSubjectWizard 표시 */}
          <div className="p-6">
            <CreateSubjectWizard />
          </div>
        </div>
      )}
      {/* 상세보기: 운영계획서 전체 화면 */}
      {detailSubject && (
        <div className="fixed inset-0 bg-white z-50 overflow-y-auto">
          {/* 상단 액션 바 */}
          <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10 shadow-sm">
            <button
              onClick={() => setDetailSubject(null)}
              className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <X className="w-5 h-5" />
              <span>닫기</span>
            </button>
            <button
              onClick={() => {
                addSubject(detailSubject);
                setDetailSubject(null);
              }}
              className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus className="w-5 h-5" />
              <span>이 과정 추가</span>
            </button>
          </div>
          {/* 운영계획서 표시 */}
          <div className="p-6">
            <OperationalPlan
              course={{
                id: detailSubject.id,
                name: detailSubject.name,
                classification: detailSubject.classification,
                department: detailSubject.department,
                major: detailSubject.major,
                departmentName: detailSubject.departmentName,
                trainingPeriod: detailSubject.trainingPeriod,
                trainingLevel: detailSubject.trainingLevel,
                trainingTarget: detailSubject.trainingTarget,
                trainingGoal: detailSubject.trainingGoal,
                instructor: detailSubject.instructor,
                year: detailSubject.year,
                students: detailSubject.students,
                subjects: detailSubject.subjects,
              }}
              onBack={() => setDetailSubject(null)}
            />
          </div>
        </div>
      )}

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
        {/* 헤더: 제목 */}
        <div className="flex items-center mb-4">
          <h3 className="text-gray-900">과목 검색</h3>
        </div>

        {/* 학사 / PLISM 탭 - 학사 탭은 현재 숨김 처리 (나중에 필요시 주석 해제) */}
        <div className="flex border-b border-gray-200 mb-4">
          {/* 학사 탭 버튼 - 현재 미사용으로 숨김 처리
          <button
            type="button"
            onClick={() => setActiveTab('haksa')}
            className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'haksa'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            학사
          </button>
          */}
          <button
            type="button"
            onClick={() => setActiveTab('plism')}
            className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'plism'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            PLISM
          </button>
        </div>

        {/* 탭 콘텐츠 - 학사 탭 콘텐츠는 현재 숨김 처리 (나중에 필요시 주석 해제)
        {activeTab === 'haksa' ? (
          <div className="text-center py-12 text-gray-500">
            <BookOpen className="w-16 h-16 mx-auto mb-4 opacity-50" />
            <p className="text-lg font-medium text-gray-600">학사 과목 검색</p>
            <p className="text-sm mt-2">추후 생성 예정입니다.</p>
          </div>
        ) : ( */}
        {/* PLISM 탭 콘텐츠 */}
        {activeTab === 'plism' && (
          <div className="space-y-4">
            {/* 검색 입력 */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={plismSearchTerm}
                onChange={(e) => setPlismSearchTerm(e.target.value)}
                placeholder="과목명으로 검색..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 로딩/에러/목록 상태 */}
            {plismError ? (
              <div className="text-center py-8 text-red-500">
                <p>{plismError}</p>
              </div>
            ) : plismLoading ? (
              <div className="text-center py-8 text-gray-500">
                <p>불러오는 중...</p>
              </div>
            ) : filteredPlismCourses.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <BookOpen className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p>검색 결과가 없습니다.</p>
                <p className="text-sm mt-1">다른 검색어를 시도하거나 "신규 개설"을 클릭하세요.</p>
              </div>
            ) : (
              <div className="max-h-80 overflow-y-auto space-y-2">
                {filteredPlismCourses.map((course) => (
                  <div
                    key={course.id}
                    className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors"
                  >
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">
                          {course.classification}
                        </span>
                        <span className="text-sm text-gray-500">{course.year}</span>
                      </div>
                      <p className="font-medium text-gray-900">{course.name}</p>
                      <p className="text-sm text-gray-500">
                        {course.departmentName || course.department || '-'} 
                        {course.students > 0 && ` • 수강생 ${course.students}명`}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => addSubject(course)}
                        className="flex items-center gap-1 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                        title="과목 바로 추가"
                      >
                        <Plus className="w-4 h-4" />
                        <span>추가</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => handleEditCurriculum(course)}
                        className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                        title="차시 편집 후 추가"
                      >
                        <span>차시 편집</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
        {/* 학사 탭 콘텐츠 닫는 괄호 - 나중에 필요시 주석 해제
        )}
        */}
      </div>
    </div>
    </>
  );
}
