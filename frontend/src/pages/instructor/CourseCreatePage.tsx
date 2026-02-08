// src/pages/instructor/CourseCreatePage.tsx
// 과정개설 페이지 - 단계별 스텝퍼 폼으로 교육과정 개설

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from '@/i18n';
import { Check, ChevronLeft, ChevronRight, CheckCircle } from 'lucide-react';

const steps = [
  { label: '기본 정보' },
  { label: '소속 과목' },
];

export default function CourseCreatePage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);

  // 기본 정보 폼 상태
  const [courseType, setCourseType] = useState('');
  const [courseCategory, setCourseCategory] = useState('');
  const [departmentName, setDepartmentName] = useState('');
  const [majorJob, setMajorJob] = useState('');
  const [courseName, setCourseName] = useState('');
  const [courseDescription, setCourseDescription] = useState('');

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleComplete = () => {
    setShowSuccess(true);
    setTimeout(() => navigate('/instructor'), 1500);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 제목 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.courseCreateTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          {t('instructor.courseCreateDesc')}
        </p>
      </div>

      {/* 스텝 인디케이터 */}
      <div className="card p-6">
        <div className="flex items-center justify-center">
          {steps.map((step, index) => (
            <div key={index} className="flex items-center">
              {/* 스텝 원 */}
              <div className="flex flex-col items-center">
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                    index < currentStep
                      ? 'bg-primary-600 text-white'
                      : index === currentStep
                      ? 'bg-primary-600 text-white'
                      : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
                  }`}
                >
                  {index < currentStep ? (
                    <Check className="w-5 h-5" />
                  ) : (
                    index + 1
                  )}
                </div>
                <span
                  className={`mt-2 text-xs font-medium ${
                    index <= currentStep
                      ? 'text-primary-600 dark:text-primary-400'
                      : 'text-gray-400 dark:text-gray-500'
                  }`}
                >
                  {step.label}
                </span>
              </div>

              {/* 연결선 */}
              {index < steps.length - 1 && (
                <div
                  className={`w-24 h-0.5 mx-3 mb-6 transition-colors ${
                    index < currentStep
                      ? 'bg-primary-600'
                      : 'bg-gray-200 dark:bg-gray-700'
                  }`}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* 폼 컨텐츠 */}
      <div className="card p-6">
        {currentStep === 0 && (
          <div>
            <h2 className="text-base font-semibold text-gray-900 dark:text-white mb-5">
              기본 정보
            </h2>
            <div className="grid grid-cols-2 gap-4">
              {/* 과정 유형 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  과정 유형<span className="text-red-500 ml-0.5">*</span>
                </label>
                <select
                  value={courseType}
                  onChange={(e) => setCourseType(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                >
                  <option value="">선택하세요</option>
                  <option value="정규">정규</option>
                  <option value="비정규">비정규</option>
                  <option value="특별">특별</option>
                </select>
              </div>

              {/* 과정 분류 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  과정 분류<span className="text-red-500 ml-0.5">*</span>
                </label>
                <select
                  value={courseCategory}
                  onChange={(e) => setCourseCategory(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                >
                  <option value="">선택하세요</option>
                  <option value="전공">전공</option>
                  <option value="교양">교양</option>
                  <option value="자격증">자격증</option>
                </select>
              </div>

              {/* 학과명 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  학과명
                </label>
                <input
                  type="text"
                  value={departmentName}
                  onChange={(e) => setDepartmentName(e.target.value)}
                  placeholder="학과명을 입력하세요"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                />
              </div>

              {/* 전공/직종 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  전공/직종
                </label>
                <input
                  type="text"
                  value={majorJob}
                  onChange={(e) => setMajorJob(e.target.value)}
                  placeholder="전공 또는 직종을 입력하세요"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                />
              </div>

              {/* 과정명 - 전체 너비 */}
              <div className="col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  과정명<span className="text-red-500 ml-0.5">*</span>
                </label>
                <input
                  type="text"
                  value={courseName}
                  onChange={(e) => setCourseName(e.target.value)}
                  placeholder="과정명을 입력하세요"
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                />
              </div>

              {/* 과정설명 - 전체 너비 */}
              <div className="col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  과정설명
                </label>
                <textarea
                  value={courseDescription}
                  onChange={(e) => setCourseDescription(e.target.value)}
                  placeholder="과정에 대한 설명을 입력하세요"
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent resize-none"
                />
              </div>
            </div>
          </div>
        )}

        {currentStep === 1 && (
          <div>
            <h2 className="text-base font-semibold text-gray-900 dark:text-white mb-5">
              소속 과목
            </h2>
            <div className="flex items-center justify-center py-16 text-sm text-gray-400 dark:text-gray-500 border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-lg">
              소속 과목을 설정합니다.
            </div>
          </div>
        )}
      </div>

      {/* 성공 토스트 메시지 */}
      {showSuccess && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-green-600 text-white px-5 py-3 rounded-xl shadow-lg animate-[slideUp_0.3s_ease-out]">
          <CheckCircle className="w-5 h-5" />
          <span className="text-sm font-medium">과정이 성공적으로 개설되었습니다.</span>
        </div>
      )}

      {/* 하단 네비게이션 버튼 */}
      <div className="flex items-center justify-between">
        <button
          onClick={handlePrev}
          disabled={currentStep === 0}
          className={`flex items-center gap-2 px-5 py-2.5 text-sm font-medium rounded-lg border transition-colors ${
            currentStep === 0
              ? 'border-gray-200 dark:border-gray-700 text-gray-300 dark:text-gray-600 cursor-not-allowed'
              : 'border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800'
          }`}
        >
          <ChevronLeft className="w-4 h-4" />
          {t('common.previous')}
        </button>

        {currentStep < steps.length - 1 ? (
          <button
            onClick={handleNext}
            className="flex items-center gap-2 px-5 py-2.5 text-sm font-medium rounded-lg bg-primary-600 text-white hover:bg-primary-700 transition-colors"
          >
            {t('common.next')}
            <ChevronRight className="w-4 h-4" />
          </button>
        ) : (
          <button
            onClick={handleComplete}
            className="flex items-center gap-2 px-5 py-2.5 text-sm font-medium rounded-lg bg-primary-600 text-white hover:bg-primary-700 transition-colors"
          >
            {t('common.confirm')}
            <Check className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  );
}
