import React, { useState } from 'react';
import {
  Info,
  Users,
  List,
  CheckCircle,
  Upload,
  Search,
  Plus,
  X,
} from 'lucide-react';
import { ContentLibraryModal } from './ContentLibraryModal';
import { CourseSelectionModal } from './CourseSelectionModal';

type Step = 'basic' | 'learners' | 'curriculum' | 'confirm';

interface Course {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
}

interface FormData {
  // 기본 정보
  subjectName: string;
  selectedCourse: Course | null;
  category: string;
  year: string;
  semester: string;
  credits: string;
  hours: string;
  startDate: string;
  endDate: string;
  description: string;
  objectives: string;
  
  // 학습자
  selectedLearners: any[];
  
  // 차시
  sessions: {
    id: string;
    title: string;
    description: string;
    videos: {
      id: string;
      title: string;
      url: string;
    }[];
  }[];
}

export function CreateSubjectWizard() {
  const [currentStep, setCurrentStep] = useState<Step>('basic');
  const [formData, setFormData] = useState<FormData>({
    subjectName: '',
    selectedCourse: null,
    category: 'CLASSROOM',
    year: '2024',
    semester: '1학기',
    credits: '',
    hours: '',
    startDate: '',
    endDate: '',
    description: '',
    objectives: '',
    selectedLearners: [],
    sessions: [
      {
        id: '1',
        title: '',
        description: '',
        videos: [],
      },
    ],
  });

  const steps = [
    { id: 'basic' as Step, label: '기본 정보', icon: Info },
    { id: 'learners' as Step, label: '학습자 선택', icon: Users },
    { id: 'curriculum' as Step, label: '차시별 구성', icon: List },
    { id: 'confirm' as Step, label: '최종 확인', icon: CheckCircle },
  ];

  const currentStepIndex = steps.findIndex((s) => s.id === currentStep);

  const handleNext = () => {
    const nextIndex = currentStepIndex + 1;
    if (nextIndex < steps.length) {
      setCurrentStep(steps[nextIndex].id);
    }
  };

  const handlePrev = () => {
    const prevIndex = currentStepIndex - 1;
    if (prevIndex >= 0) {
      setCurrentStep(steps[prevIndex].id);
    }
  };

  const updateFormData = (updates: Partial<FormData>) => {
    setFormData((prev) => ({ ...prev, ...updates }));
  };

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">새 과목 개설</h2>
        <p className="text-gray-600">단계별로 교육과목을 개설하고 설정할 수 있습니다.</p>
      </div>

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
                      isActive ? 'text-blue-600' : isCompleted ? 'text-blue-600' : 'text-gray-500'
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
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
        {currentStep === 'basic' && (
          <BasicInfoStep formData={formData} updateFormData={updateFormData} />
        )}
        {currentStep === 'learners' && (
          <LearnersStep formData={formData} updateFormData={updateFormData} />
        )}
        {currentStep === 'curriculum' && (
          <CurriculumStep formData={formData} updateFormData={updateFormData} />
        )}
        {currentStep === 'confirm' && <ConfirmStep formData={formData} />}

        {/* Navigation Buttons */}
        <div className="flex items-center justify-between pt-8 mt-8 border-t border-gray-200">
          <button
            onClick={handlePrev}
            disabled={currentStepIndex === 0}
            className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            이전
          </button>
          {currentStepIndex < steps.length - 1 ? (
            <button
              onClick={handleNext}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              다음
            </button>
          ) : (
            <button className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
              과목 개설 완료
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// 기본 정보 입력 단계
function BasicInfoStep({
  formData,
  updateFormData,
}: {
  formData: FormData;
  updateFormData: (updates: Partial<FormData>) => void;
}) {
  const [isCourseModalOpen, setIsCourseModalOpen] = useState(false);

  const handleCourseSelect = (course: Course) => {
    updateFormData({ selectedCourse: course });
    setIsCourseModalOpen(false);
  };

  return (
    <div className="space-y-6">
      <h3 className="text-gray-900">기본 정보 입력</h3>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm text-gray-700 mb-2">소속 과정</label>
          <button
            onClick={() => setIsCourseModalOpen(true)}
            className="w-full px-4 py-2 bg-gray-100 border border-gray-300 rounded-lg text-left text-gray-700 hover:bg-gray-200 transition-colors flex items-center justify-between"
          >
            <span>
              {formData.selectedCourse ? formData.selectedCourse.name : '과정 선택'}
            </span>
            <Upload className="w-4 h-4" />
          </button>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">과정 카테고리</label>
          <input
            type="text"
            value={formData.category}
            onChange={(e) => updateFormData({ category: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm text-gray-700 mb-2">
            과목명 <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            value={formData.subjectName}
            onChange={(e) => updateFormData({ subjectName: e.target.value })}
            placeholder="예: AI 기초 프로그래밍"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">메인 이미지</label>
          <button className="w-full px-4 py-2 bg-gray-100 border border-gray-300 rounded-lg text-left text-gray-700 hover:bg-gray-200 transition-colors flex items-center justify-between">
            <span>파일 업로드</span>
            <Upload className="w-4 h-4" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div>
          <label className="block text-sm text-gray-700 mb-2">년도/학기</label>
          <div className="flex gap-2">
            <input
              type="text"
              value={formData.year}
              onChange={(e) => updateFormData({ year: e.target.value })}
              placeholder="2024"
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <select
              value={formData.semester}
              onChange={(e) => updateFormData({ semester: e.target.value })}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option>1학기</option>
              <option>2학기</option>
            </select>
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">시수</label>
          <input
            type="number"
            value={formData.hours}
            onChange={(e) => updateFormData({ hours: e.target.value })}
            placeholder="48"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">학점</label>
          <input
            type="number"
            value={formData.credits}
            onChange={(e) => updateFormData({ credits: e.target.value })}
            placeholder="3"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm text-gray-700 mb-2">수업시작일</label>
          <input
            type="date"
            value={formData.startDate}
            onChange={(e) => updateFormData({ startDate: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">학습기한</label>
          <input
            type="date"
            value={formData.endDate}
            onChange={(e) => updateFormData({ endDate: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm text-gray-700 mb-2">과목 소개</label>
        <textarea
          value={formData.description}
          onChange={(e) => updateFormData({ description: e.target.value })}
          placeholder="과목 소개"
          rows={4}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div>
        <label className="block text-sm text-gray-700 mb-2">과목 세부내용</label>
        <textarea
          value={formData.objectives}
          onChange={(e) => updateFormData({ objectives: e.target.value })}
          placeholder="과목 소개 내용"
          rows={4}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Course Selection Modal */}
      <CourseSelectionModal
        isOpen={isCourseModalOpen}
        onClose={() => setIsCourseModalOpen(false)}
        onSelect={handleCourseSelect}
        selectedCourse={formData.selectedCourse}
      />
    </div>
  );
}

// 학습자 선택 단계
function LearnersStep({
  formData,
  updateFormData,
}: {
  formData: FormData;
  updateFormData: (updates: Partial<FormData>) => void;
}) {
  const [searchTerm, setSearchTerm] = useState('');
  const [campus, setCampus] = useState('전체');
  const [major, setMajor] = useState('전체');

  // 샘플 학습자 데이터
  const allLearners = [
    { id: '1', name: '김학생', campus: '서울캠퍼스', major: '전자공학과' },
    { id: '2', name: '이학생', campus: '서울캠퍼스', major: '전산정보학과' },
    { id: '3', name: '박학생', campus: '부산캠퍼스', major: '전자공학과' },
    { id: '4', name: '최학생', campus: '대구캠퍼스', major: '기계공학과' },
    { id: '5', name: '정학생', campus: '서울캠퍼스', major: '전산정보학과' },
    { id: '6', name: '강학생', campus: '부산캠퍼스', major: '전자공학과' },
    { id: '7', name: '조학생', campus: '서울캠퍼스', major: '전산정보학과' },
    { id: '8', name: '윤학생', campus: '대구캠퍼스', major: '기계공학과' },
    { id: '9', name: '장학생', campus: '서울캠퍼스', major: '전자공학과' },
  ];

  const filteredLearners = allLearners.filter((learner) => {
    const matchesSearch = learner.name.includes(searchTerm);
    const matchesCampus = campus === '전체' || learner.campus === campus;
    const matchesMajor = major === '전체' || learner.major === major;
    return matchesSearch && matchesCampus && matchesMajor;
  });

  const toggleLearner = (learner: any) => {
    const isSelected = formData.selectedLearners.some((l) => l.id === learner.id);
    if (isSelected) {
      updateFormData({
        selectedLearners: formData.selectedLearners.filter((l) => l.id !== learner.id),
      });
    } else {
      updateFormData({
        selectedLearners: [...formData.selectedLearners, learner],
      });
    }
  };

  const selectAll = () => {
    updateFormData({ selectedLearners: [...filteredLearners] });
  };

  const deselectAll = () => {
    updateFormData({ selectedLearners: [] });
  };

  return (
    <div className="space-y-6">
      <h3 className="text-gray-900">학습자 선택</h3>

      {/* 검색 및 필터 */}
      <div className="bg-gray-50 p-4 rounded-lg space-y-4">
        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">이름 검색</label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="학습자 이름 검색..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">캠퍼스</label>
            <select
              value={campus}
              onChange={(e) => setCampus(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option>전체</option>
              <option>서울캠퍼스</option>
              <option>부산캠퍼스</option>
              <option>대구캠퍼스</option>
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">전공</label>
            <select
              value={major}
              onChange={(e) => setMajor(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option>전체</option>
              <option>전자공학과</option>
              <option>전산정보학과</option>
              <option>기계공학과</option>
            </select>
          </div>
        </div>

        <div className="flex items-center justify-between">
          <div className="flex gap-3">
            <button
              onClick={selectAll}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              전체 선택
            </button>
            <button
              onClick={deselectAll}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
            >
              현재 목록 전체 해제
            </button>
          </div>
          <div className="text-sm text-gray-600">
            검색 결과: {filteredLearners.length}명 / 선택된: {formData.selectedLearners.length}명
          </div>
        </div>
      </div>

      {/* 학습자 목록 */}
      <div className="grid grid-cols-3 gap-4">
        {filteredLearners.map((learner) => {
          const isSelected = formData.selectedLearners.some((l) => l.id === learner.id);
          return (
            <div
              key={learner.id}
              onClick={() => toggleLearner(learner)}
              className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                isSelected
                  ? 'border-blue-600 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="text-gray-900">{learner.name}</div>
                {isSelected && (
                  <div className="w-5 h-5 bg-blue-600 rounded-full flex items-center justify-center">
                    <CheckCircle className="w-3 h-3 text-white" />
                  </div>
                )}
              </div>
              <div className="text-sm text-gray-600">{learner.campus}</div>
              <div className="text-sm text-gray-600">{learner.major}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// 차시 구성 단계
function CurriculumStep({
  formData,
  updateFormData,
}: {
  formData: FormData;
  updateFormData: (updates: Partial<FormData>) => void;
}) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);

  const addSession = () => {
    const newSession = {
      id: String(formData.sessions.length + 1),
      title: '',
      description: '',
      videos: [],
    };
    updateFormData({ sessions: [...formData.sessions, newSession] });
  };

  const updateSession = (id: string, updates: Partial<typeof formData.sessions[0]>) => {
    const updatedSessions = formData.sessions.map((session) =>
      session.id === id ? { ...session, ...updates } : session
    );
    updateFormData({ sessions: updatedSessions });
  };

  const removeSession = (id: string) => {
    if (formData.sessions.length > 1) {
      updateFormData({
        sessions: formData.sessions.filter((session) => session.id !== id),
      });
    }
  };

  const addVideo = (sessionId: string) => {
    const session = formData.sessions.find((s) => s.id === sessionId);
    if (session) {
      const newVideo = {
        id: `${sessionId}-video-${Date.now()}-${Math.random()}`,
        title: '',
        url: '',
      };
      updateSession(sessionId, {
        videos: [...session.videos, newVideo],
      });
    }
  };

  const updateVideo = (sessionId: string, videoId: string, updates: { title?: string; url?: string }) => {
    const session = formData.sessions.find((s) => s.id === sessionId);
    if (session) {
      const updatedVideos = session.videos.map((video) =>
        video.id === videoId ? { ...video, ...updates } : video
      );
      updateSession(sessionId, { videos: updatedVideos });
    }
  };

  const removeVideo = (sessionId: string, videoId: string) => {
    const session = formData.sessions.find((s) => s.id === sessionId);
    if (session) {
      updateSession(sessionId, {
        videos: session.videos.filter((video) => video.id !== videoId),
      });
    }
  };

  const handleContentSelect = (content: any) => {
    if (currentSessionId) {
      const session = formData.sessions.find((s) => s.id === currentSessionId);
      if (session) {
        const newVideo = {
          id: `${currentSessionId}-video-${Date.now()}-${Math.random()}`,
          title: content.title,
          url: content.url || content.id,
        };
        updateSession(currentSessionId, {
          videos: [...session.videos, newVideo],
        });
      }
    }
    setIsModalOpen(false);
  };

  const openContentModal = (sessionId: string) => {
    setCurrentSessionId(sessionId);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">
      <h3 className="text-gray-900">차시별 구성</h3>

      <div className="space-y-6">
        {formData.sessions.map((session, index) => (
          <div key={session.id} className="border border-gray-200 rounded-lg p-6 relative">
            {formData.sessions.length > 1 && (
              <button
                onClick={() => removeSession(session.id)}
                className="absolute top-4 right-4 text-gray-400 hover:text-red-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            )}

            <h4 className="text-gray-900 mb-4">{index + 1}차시</h4>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-700 mb-2">차시 제목</label>
                <input
                  type="text"
                  value={session.title}
                  onChange={(e) => updateSession(session.id, { title: e.target.value })}
                  placeholder="예: Python 기초 문법"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">차시 설명</label>
                <textarea
                  value={session.description}
                  onChange={(e) => updateSession(session.id, { description: e.target.value })}
                  placeholder="이 차시에서 학습할 내용을 설명하세요"
                  rows={3}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* 강의 영상 목록 */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <label className="block text-sm text-gray-700">강의 영상 ({session.videos.length})</label>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => openContentModal(session.id)}
                      className="px-3 py-1.5 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                    >
                      콘텐츠 검색
                    </button>
                    <button
                      type="button"
                      onClick={() => addVideo(session.id)}
                      className="flex items-center gap-1 px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      <Plus className="w-4 h-4" />
                      영상 추가
                    </button>
                  </div>
                </div>

                {/* 영상 목록 */}
                {session.videos.length > 0 ? (
                  <div className="space-y-3">
                    {session.videos.map((video, videoIndex) => (
                      <div
                        key={video.id}
                        className="bg-gray-50 border border-gray-200 rounded-lg p-4"
                      >
                        <div className="flex items-start gap-3">
                          <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-700 rounded-lg text-sm shrink-0">
                            {videoIndex + 1}
                          </div>
                          <div className="flex-1 space-y-3">
                            <div>
                              <label className="block text-xs text-gray-600 mb-1">
                                영상 제목
                              </label>
                              <input
                                type="text"
                                value={video.title}
                                onChange={(e) =>
                                  updateVideo(session.id, video.id, { title: e.target.value })
                                }
                                placeholder="영상 제목을 입력하세요"
                                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                              />
                            </div>
                            <div>
                              <label className="block text-xs text-gray-600 mb-1">
                                키 또는 URL
                              </label>
                              <input
                                type="text"
                                value={video.url}
                                onChange={(e) =>
                                  updateVideo(session.id, video.id, { url: e.target.value })
                                }
                                placeholder="youtube.com 또는 키 입력"
                                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                              />
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => removeVideo(session.id, video.id)}
                            className="p-2 text-gray-400 hover:text-red-600 transition-colors shrink-0"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
                    <p className="text-sm text-gray-500">
                      영상을 추가해주세요
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      <button
        onClick={addSession}
        className="w-full py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-gray-400 hover:text-gray-700 transition-colors flex items-center justify-center gap-2"
      >
        <Plus className="w-5 h-5" />
        차시 추가
      </button>

      {/* Content Library Modal */}
      <ContentLibraryModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSelect={handleContentSelect}
      />
    </div>
  );
}

// 최종 확인 단계
function ConfirmStep({ formData }: { formData: FormData }) {
  return (
    <div className="space-y-8">
      <h3 className="text-gray-900">최종 확인</h3>

      <div className="space-y-6">
        {/* 기본 정보 */}
        <div>
          <h4 className="text-gray-900 mb-4 pb-2 border-b border-gray-200">기본 정보</h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-600">과목명:</span>
              <span className="ml-2 text-gray-900">{formData.subjectName || '-'}</span>
            </div>
            <div>
              <span className="text-gray-600">소속 과정:</span>
              <span className="ml-2 text-gray-900">
                {formData.selectedCourse ? formData.selectedCourse.name : '-'}
              </span>
            </div>
            <div>
              <span className="text-gray-600">카테고리:</span>
              <span className="ml-2 text-gray-900">{formData.category || '-'}</span>
            </div>
            <div>
              <span className="text-gray-600">년도/학기:</span>
              <span className="ml-2 text-gray-900">
                {formData.year} {formData.semester}
              </span>
            </div>
            <div>
              <span className="text-gray-600">시수:</span>
              <span className="ml-2 text-gray-900">{formData.hours || '-'}</span>
            </div>
            <div>
              <span className="text-gray-600">학점:</span>
              <span className="ml-2 text-gray-900">{formData.credits || '-'}</span>
            </div>
          </div>
        </div>

        {/* 학습자 정보 */}
        <div>
          <h4 className="text-gray-900 mb-4 pb-2 border-b border-gray-200">학습자</h4>
          <div className="text-sm">
            <span className="text-gray-600">선택된 학습자:</span>
            <span className="ml-2 text-gray-900">{formData.selectedLearners.length}명</span>
          </div>
          {formData.selectedLearners.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-2">
              {formData.selectedLearners.map((learner) => (
                <span
                  key={learner.id}
                  className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm"
                >
                  {learner.name}
                </span>
              ))}
            </div>
          )}
        </div>

        {/* 차시 정보 */}
        <div>
          <h4 className="text-gray-900 mb-4 pb-2 border-b border-gray-200">차시 구성</h4>
          <div className="text-sm mb-3">
            <span className="text-gray-600">총 차시:</span>
            <span className="ml-2 text-gray-900">{formData.sessions.length}차시</span>
          </div>
          <div className="space-y-3">
            {formData.sessions.map((session, index) => (
              <div key={session.id} className="p-4 bg-gray-50 rounded-lg">
                <div className="text-gray-900 mb-1">
                  {index + 1}차시: {session.title || '(제목 없음)'}
                </div>
                {session.description && (
                  <div className="text-sm text-gray-600 mb-2">{session.description}</div>
                )}
                {session.videos.length > 0 && (
                  <div className="mt-3 pl-4 border-l-2 border-blue-300">
                    <div className="text-sm text-gray-700 mb-2">
                      강의 영상 {session.videos.length}개
                    </div>
                    <div className="space-y-1">
                      {session.videos.map((video, videoIndex) => (
                        <div key={video.id} className="text-sm text-gray-600">
                          {videoIndex + 1}. {video.title || '(제목 없음)'}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p className="text-sm text-blue-900">
          위 내용을 확인하고 "과목 개설 완료" 버튼을 클릭하여 과목 개설을 완료하세요.
        </p>
      </div>
    </div>
  );
}