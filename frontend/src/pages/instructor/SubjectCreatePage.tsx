// src/pages/instructor/SubjectCreatePage.tsx
// 교수자 새 과목 개설 - 단계별 Stepper 폼 페이지

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from '@/i18n';
import {
  Info,
  Users,
  List,
  CheckCircle,
  Check,
  Upload,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

// ── 스텝 정의 ──────────────────────────────────────────────

interface Step {
  label: string;
  icon: React.ElementType;
}

const steps: Step[] = [
  { label: '기본 정보', icon: Info },
  { label: '학습자 선택', icon: Users },
  { label: '차시별 구성', icon: List },
  { label: '최종 확인', icon: CheckCircle },
];

// ── Stepper 컴포넌트 ────────────────────────────────────────

function Stepper({
  currentStep,
}: {
  currentStep: number;
}) {
  return (
    <div className="flex items-center justify-center w-full">
      {steps.map((step, idx) => {
        const Icon = step.icon;
        const isCompleted = idx < currentStep;
        const isActive = idx === currentStep;
        const isUpcoming = idx > currentStep;

        return (
          <div key={step.label} className="flex items-center">
            {/* 스텝 원형 + 라벨 */}
            <div className="flex flex-col items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                  isCompleted
                    ? 'bg-blue-600 text-white'
                    : isActive
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-200 text-gray-400 dark:bg-gray-700 dark:text-gray-500'
                }`}
              >
                {isCompleted ? (
                  <Check className="w-5 h-5" />
                ) : (
                  <Icon className="w-5 h-5" />
                )}
              </div>
              <span
                className={`mt-2 text-xs font-medium ${
                  isActive
                    ? 'text-blue-600 dark:text-blue-400'
                    : isCompleted
                      ? 'text-blue-600 dark:text-blue-400'
                      : 'text-gray-400 dark:text-gray-500'
                }`}
              >
                {step.label}
              </span>
            </div>

            {/* 연결 선 (마지막 스텝 제외) */}
            {idx < steps.length - 1 && (
              <div
                className={`w-16 sm:w-24 h-0.5 mx-2 mb-6 ${
                  idx < currentStep
                    ? 'bg-blue-600'
                    : 'bg-gray-200 dark:bg-gray-700'
                }`}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ── Step 1: 기본 정보 입력 폼 ─────────────────────────────────

function StepBasicInfo() {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
        기본 정보 입력
      </h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
        {/* Row 1: 소속 과정 + 과정 카테고리 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            소속 과정
          </label>
          <div className="relative">
            <input
              type="text"
              placeholder="과정 선택"
              className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 pr-10 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
              readOnly
            />
            <Upload className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            과정 카테고리
          </label>
          <select className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors">
            <option>[미지정]</option>
            <option>전공</option>
            <option>교양</option>
          </select>
        </div>

        {/* Row 2: 과목명 + 메인 이미지 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            과목명 <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            placeholder="예: AI 기초 프로그래밍"
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            메인 이미지
          </label>
          <div className="relative">
            <input
              type="text"
              placeholder="파일 업로드"
              className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 pr-10 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
              readOnly
            />
            <Upload className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          </div>
        </div>

        {/* Row 3: 년도/학기 + 시수 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            년도 / 학기
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              defaultValue="2024"
              className="w-1/2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            />
            <select className="w-1/2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors">
              <option>1학기</option>
              <option>2학기</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            시수
          </label>
          <input
            type="number"
            defaultValue={15}
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
          />
        </div>

        {/* Row 4: 수업 기간 (full width) */}
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            수업 기간
          </label>
          <div className="flex items-center gap-2">
            <input
              type="date"
              className="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            />
            <span className="text-gray-400 dark:text-gray-500 text-sm">~</span>
            <input
              type="date"
              className="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            />
          </div>
        </div>

        {/* Row 5: 과목 소개 (full width) */}
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            과목 소개
          </label>
          <textarea
            rows={3}
            placeholder="과목 소개"
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors resize-none"
          />
        </div>

        {/* Row 6: 과목 세부내용 (full width) */}
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            과목 세부내용
          </label>
          <textarea
            rows={4}
            placeholder="과목 소개 내용"
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors resize-none"
          />
        </div>
      </div>
    </div>
  );
}

// ── Step 2: 학습자 선택 (Placeholder) ────────────────────────

function StepStudentSelect() {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
      <div className="flex flex-col items-center justify-center py-16 text-gray-400 dark:text-gray-500">
        <Users className="w-12 h-12 mb-4" />
        <p className="text-sm font-medium">학습자를 선택하고 배정합니다.</p>
      </div>
    </div>
  );
}

// ── Step 3: 차시별 구성 (Placeholder) ────────────────────────

function StepLessonConfig() {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
      <div className="flex flex-col items-center justify-center py-16 text-gray-400 dark:text-gray-500">
        <List className="w-12 h-12 mb-4" />
        <p className="text-sm font-medium">차시별 학습 구성을 설정합니다.</p>
      </div>
    </div>
  );
}

// ── Step 4: 최종 확인 (Placeholder) ──────────────────────────

function StepFinalReview() {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
      <div className="flex flex-col items-center justify-center py-16 text-gray-400 dark:text-gray-500">
        <CheckCircle className="w-12 h-12 mb-4" />
        <p className="text-sm font-medium">설정 내용을 최종 확인합니다.</p>
      </div>
    </div>
  );
}

// ── 메인 컴포넌트 ─────────────────────────────────────────────

export default function SubjectCreatePage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);

  const handlePrev = () => {
    if (currentStep > 0) setCurrentStep(currentStep - 1);
  };

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      setShowSuccess(true);
      setTimeout(() => navigate('/instructor'), 1500);
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case 0:
        return <StepBasicInfo />;
      case 1:
        return <StepStudentSelect />;
      case 2:
        return <StepLessonConfig />;
      case 3:
        return <StepFinalReview />;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-8">
      {/* 페이지 타이틀 */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {t('instructor.subjectCreateTitle')}
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {t('instructor.subjectCreateDesc')}
        </p>
      </div>

      {/* Stepper */}
      <Stepper currentStep={currentStep} />

      {/* 스텝 콘텐츠 */}
      {renderStepContent()}

      {/* 성공 토스트 메시지 */}
      {showSuccess && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-green-600 text-white px-5 py-3 rounded-xl shadow-lg animate-[slideUp_0.3s_ease-out]">
          <CheckCircle className="w-5 h-5" />
          <span className="text-sm font-medium">과목이 성공적으로 개설되었습니다.</span>
        </div>
      )}

      {/* 하단 네비게이션 */}
      <div className="flex items-center justify-between">
        {/* 이전 버튼 */}
        {currentStep > 0 ? (
          <button
            onClick={handlePrev}
            className="flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            {t('common.previous')}
          </button>
        ) : (
          <div />
        )}

        {/* 다음 / 완료 버튼 */}
        <button
          onClick={handleNext}
          className="flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
        >
          {currentStep < steps.length - 1 ? (
            <>
              {t('common.next')}
              <ChevronRight className="w-4 h-4" />
            </>
          ) : (
            <>
              <CheckCircle className="w-4 h-4" />
              {t('common.confirm')}
            </>
          )}
        </button>
      </div>
    </div>
  );
}
