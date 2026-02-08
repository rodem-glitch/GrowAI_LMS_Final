// components/common/UserGuideModal.tsx — 사용 가이드 영상 모달 (비디오형 자동재생)
import { useState, useEffect, useCallback, useRef } from 'react';
import {
  X, Play, Pause, SkipForward, SkipBack, Download,
  ChevronLeft, ChevronRight, Mouse, ArrowRight,
} from 'lucide-react';

export interface GuideStep {
  title: string;
  description: string;
  action: string;          // 액션 설명 (예: "좌측 메뉴에서 '수강 목록' 클릭")
  screen: string;          // 화면 경로 (예: "/student/courses")
  icon: React.ElementType; // 화면 대표 아이콘
  category: string;        // 카테고리 (예: "학습", "관리")
  highlight?: string;      // 강조할 UI 요소 설명
}

interface UserGuideModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  subtitle: string;
  steps: GuideStep[];
  accentColor?: string;    // 'blue' | 'emerald' | 'purple'
}

const STEP_DURATION = 5000; // 5초 per step

export default function UserGuideModal({
  isOpen,
  onClose,
  title,
  subtitle,
  steps,
  accentColor = 'blue',
}: UserGuideModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);
  const [progress, setProgress] = useState(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const progressRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const colorMap: Record<string, { bg: string; text: string; border: string; light: string; gradient: string }> = {
    blue: {
      bg: 'bg-blue-600',
      text: 'text-blue-600 dark:text-blue-400',
      border: 'border-blue-200 dark:border-blue-800',
      light: 'bg-blue-50 dark:bg-blue-900/30',
      gradient: 'from-blue-600 to-blue-800',
    },
    emerald: {
      bg: 'bg-emerald-600',
      text: 'text-emerald-600 dark:text-emerald-400',
      border: 'border-emerald-200 dark:border-emerald-800',
      light: 'bg-emerald-50 dark:bg-emerald-900/30',
      gradient: 'from-emerald-600 to-emerald-800',
    },
    purple: {
      bg: 'bg-purple-600',
      text: 'text-purple-600 dark:text-purple-400',
      border: 'border-purple-200 dark:border-purple-800',
      light: 'bg-purple-50 dark:bg-purple-900/30',
      gradient: 'from-purple-600 to-purple-800',
    },
  };

  const colors = colorMap[accentColor] || colorMap.blue;

  // 자동 재생 로직
  const startAutoPlay = useCallback(() => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    if (progressRef.current) clearInterval(progressRef.current);

    setProgress(0);

    // 진행바 업데이트 (50ms 간격)
    progressRef.current = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) return 100;
        return prev + (50 / STEP_DURATION) * 100;
      });
    }, 50);

    // 다음 스텝 이동
    intervalRef.current = setInterval(() => {
      setCurrentStep((prev) => {
        if (prev >= steps.length - 1) {
          setIsPlaying(false);
          if (intervalRef.current) clearInterval(intervalRef.current);
          if (progressRef.current) clearInterval(progressRef.current);
          return prev;
        }
        setProgress(0);
        return prev + 1;
      });
    }, STEP_DURATION);
  }, [steps.length]);

  const stopAutoPlay = useCallback(() => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    if (progressRef.current) clearInterval(progressRef.current);
  }, []);

  useEffect(() => {
    if (isPlaying && isOpen) {
      startAutoPlay();
    } else {
      stopAutoPlay();
    }
    return () => stopAutoPlay();
  }, [isPlaying, isOpen, currentStep, startAutoPlay, stopAutoPlay]);

  // 모달 열릴 때 초기화
  useEffect(() => {
    if (isOpen) {
      setCurrentStep(0);
      setIsPlaying(true);
      setProgress(0);
    }
  }, [isOpen]);

  const handlePrev = () => {
    setIsPlaying(false);
    setProgress(0);
    setCurrentStep((prev) => Math.max(0, prev - 1));
  };

  const handleNext = () => {
    setIsPlaying(false);
    setProgress(0);
    setCurrentStep((prev) => Math.min(steps.length - 1, prev + 1));
  };

  const handleTogglePlay = () => {
    if (!isPlaying && currentStep >= steps.length - 1) {
      setCurrentStep(0);
      setProgress(0);
    }
    setIsPlaying(!isPlaying);
  };

  const handleStepClick = (idx: number) => {
    setIsPlaying(false);
    setProgress(0);
    setCurrentStep(idx);
  };

  // PDF 다운로드 (프린트)
  const handlePrint = () => {
    setIsPlaying(false);
    const printContent = steps
      .map(
        (step, idx) =>
          `<div style="page-break-inside:avoid;margin-bottom:32px;padding:24px;border:1px solid #e5e7eb;border-radius:12px;">
            <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px;">
              <div style="width:36px;height:36px;border-radius:50%;background:#3b82f6;color:white;display:flex;align-items:center;justify-content:center;font-weight:bold;font-size:14px;">${idx + 1}</div>
              <div>
                <div style="font-size:10px;color:#6b7280;">${step.category}</div>
                <div style="font-size:16px;font-weight:700;">${step.title}</div>
              </div>
            </div>
            <p style="color:#374151;font-size:14px;line-height:1.8;margin-bottom:12px;">${step.description}</p>
            <div style="background:#f3f4f6;border-radius:8px;padding:12px 16px;">
              <div style="font-size:11px;color:#6b7280;margin-bottom:4px;">실행 액션</div>
              <div style="font-size:13px;font-weight:600;color:#1f2937;">${step.action}</div>
            </div>
            <div style="margin-top:8px;font-size:11px;color:#9ca3af;">화면 경로: ${step.screen}${step.highlight ? ' | 강조: ' + step.highlight : ''}</div>
          </div>`
      )
      .join('');

    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`<!DOCTYPE html><html><head><title>${title} - 사용자 매뉴얼</title>
        <style>
          body{font-family:'Pretendard','Apple SD Gothic Neo',sans-serif;max-width:800px;margin:0 auto;padding:40px 24px;color:#111827;}
          h1{font-size:28px;margin-bottom:4px;}
          h2{font-size:14px;color:#6b7280;font-weight:400;margin-bottom:32px;}
          .footer{text-align:center;font-size:11px;color:#9ca3af;margin-top:40px;padding-top:20px;border-top:1px solid #e5e7eb;}
          @media print{body{padding:20px;}}
        </style></head><body>
        <h1>${title}</h1>
        <h2>${subtitle}</h2>
        ${printContent}
        <div class="footer">GrowAI LMS - ${new Date().toLocaleDateString('ko-KR')} 생성</div>
        </body></html>`);
      printWindow.document.close();
      printWindow.print();
    }
  };

  if (!isOpen) return null;

  const step = steps[currentStep];
  const StepIcon = step?.icon;
  const totalProgress = ((currentStep / steps.length) * 100) + ((progress / 100) * (100 / steps.length));

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl w-full max-w-4xl mx-4 overflow-hidden flex flex-col"
        style={{ maxHeight: '90vh' }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* 상단 헤더 - 비디오 플레이어 스타일 */}
        <div className={`relative bg-gradient-to-r ${colors.gradient} px-6 py-4 text-white`}>
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold">{title}</h2>
              <p className="text-sm text-white/70">{subtitle}</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={handlePrint}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
                title="PDF 매뉴얼 다운로드"
              >
                <Download className="w-3.5 h-3.5" />
                PDF
              </button>
              <button
                onClick={onClose}
                className="p-1.5 rounded-lg hover:bg-white/20 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* 전체 진행바 */}
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/20">
            <div
              className="h-full bg-white/80 transition-all duration-100"
              style={{ width: `${totalProgress}%` }}
            />
          </div>
        </div>

        {/* 메인 콘텐츠 영역 */}
        <div className="flex flex-1 overflow-hidden">
          {/* 좌측 - 단계 목록 */}
          <div className="w-56 flex-shrink-0 border-r border-gray-200 dark:border-gray-700 overflow-y-auto bg-gray-50 dark:bg-gray-800/50">
            <div className="p-3">
              <div className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider px-2 py-2">
                전체 {steps.length}단계
              </div>
              {steps.map((s, idx) => {
                const Icon = s.icon;
                const isActive = idx === currentStep;
                const isDone = idx < currentStep;
                return (
                  <button
                    key={idx}
                    onClick={() => handleStepClick(idx)}
                    className={`w-full flex items-center gap-2.5 px-2.5 py-2 rounded-lg text-left transition-all mb-0.5 ${
                      isActive
                        ? `${colors.light} ${colors.text} font-semibold`
                        : isDone
                          ? 'text-gray-500 dark:text-gray-400'
                          : 'text-gray-400 dark:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700'
                    }`}
                  >
                    <div
                      className={`w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 text-[10px] font-bold ${
                        isActive
                          ? `${colors.bg} text-white`
                          : isDone
                            ? 'bg-green-500 text-white'
                            : 'bg-gray-200 dark:bg-gray-700 text-gray-400'
                      }`}
                    >
                      {isDone ? '✓' : idx + 1}
                    </div>
                    <span className="text-xs truncate">{s.title}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 우측 - 현재 단계 상세 */}
          <div className="flex-1 overflow-y-auto">
            {step && (
              <div className="p-6 space-y-5">
                {/* 단계 헤더 */}
                <div className="flex items-start gap-4">
                  <div className={`w-14 h-14 rounded-2xl ${colors.light} flex items-center justify-center flex-shrink-0`}>
                    <StepIcon className={`w-7 h-7 ${colors.text}`} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`text-[10px] font-bold uppercase tracking-wider ${colors.text}`}>
                        Step {currentStep + 1}/{steps.length}
                      </span>
                      <span className="text-[10px] text-gray-400 dark:text-gray-500">
                        {step.category}
                      </span>
                    </div>
                    <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                      {step.title}
                    </h3>
                  </div>
                </div>

                {/* 설명 */}
                <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                  {step.description}
                </p>

                {/* 액션 카드 - 화면 시뮬레이션 */}
                <div className={`rounded-xl border-2 ${colors.border} overflow-hidden`}>
                  {/* 페이지 네비게이션 */}
                  <div className="bg-gray-100 dark:bg-gray-800 px-3 py-2.5 flex items-center justify-between border-b border-gray-200 dark:border-gray-700">
                    <button
                      onClick={handlePrev}
                      disabled={currentStep === 0}
                      className="flex items-center gap-1 text-[11px] text-gray-300 dark:text-gray-600 hover:text-gray-500 dark:hover:text-gray-400 disabled:invisible transition-all min-w-0 max-w-[140px]"
                    >
                      <ChevronLeft className="w-3 h-3 flex-shrink-0" />
                      <span className="truncate opacity-60">{currentStep > 0 ? steps[currentStep - 1].title : ''}</span>
                    </button>
                    <div className={`flex items-center gap-1.5 text-xs font-bold ${colors.text} px-2`}>
                      <span className="text-[10px] opacity-60">{currentStep + 1}/{steps.length}</span>
                      <span className="mx-0.5 opacity-30">|</span>
                      <span>{step.title}</span>
                    </div>
                    <button
                      onClick={handleNext}
                      disabled={currentStep >= steps.length - 1}
                      className="flex items-center gap-1 text-[11px] text-gray-300 dark:text-gray-600 hover:text-gray-500 dark:hover:text-gray-400 disabled:invisible transition-all min-w-0 max-w-[140px] justify-end"
                    >
                      <span className="truncate opacity-60">{currentStep < steps.length - 1 ? steps[currentStep + 1].title : ''}</span>
                      <ChevronRight className="w-3 h-3 flex-shrink-0" />
                    </button>
                  </div>

                  {/* 액션 본문 */}
                  <div className="px-5 py-6 bg-white dark:bg-gray-900/50">
                    <div className="flex items-start gap-3 mb-4">
                      <div className={`w-8 h-8 rounded-lg ${colors.bg} text-white flex items-center justify-center flex-shrink-0`}>
                        <Mouse className="w-4 h-4" />
                      </div>
                      <div>
                        <div className="text-[10px] text-gray-400 dark:text-gray-500 font-medium mb-1">
                          실행 액션
                        </div>
                        <div className="text-sm font-semibold text-gray-900 dark:text-white">
                          {step.action}
                        </div>
                      </div>
                    </div>

                    {/* 강조 요소 */}
                    {step.highlight && (
                      <div className="mt-3 flex items-center gap-2">
                        <ArrowRight className={`w-3.5 h-3.5 ${colors.text} animate-pulse`} />
                        <span className={`text-xs font-medium ${colors.text}`}>
                          {step.highlight}
                        </span>
                      </div>
                    )}

                    {/* 다음 단계 미리보기 */}
                    {currentStep < steps.length - 1 && (
                      <div className="mt-4 pt-4 border-t border-gray-100 dark:border-gray-800">
                        <button
                          onClick={handleNext}
                          className="flex items-center gap-2 text-xs text-gray-300 dark:text-gray-600 hover:text-gray-500 dark:hover:text-gray-400 transition-colors"
                        >
                          <span className="opacity-60">다음:</span>
                          <span className="font-medium opacity-60">{steps[currentStep + 1].title}</span>
                          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                {/* 현재 스텝 진행바 */}
                <div className="flex items-center gap-3">
                  <div className="flex-1 h-1.5 bg-gray-100 dark:bg-gray-800 rounded-full overflow-hidden">
                    <div
                      className={`h-full ${colors.bg} transition-all duration-100 rounded-full`}
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                  <span className="text-[10px] text-gray-400 font-mono">
                    {Math.ceil((STEP_DURATION - (progress / 100) * STEP_DURATION) / 1000)}s
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* 하단 컨트롤바 - 비디오 플레이어 스타일 */}
        <div className="border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50 px-6 py-3">
          <div className="flex items-center justify-between">
            <span className="text-xs text-gray-500 dark:text-gray-400">
              {currentStep + 1} / {steps.length}단계
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={handlePrev}
                disabled={currentStep === 0}
                className="p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <SkipBack className="w-4 h-4 text-gray-600 dark:text-gray-400" />
              </button>
              <button
                onClick={handleTogglePlay}
                className={`p-2.5 rounded-full ${colors.bg} text-white hover:opacity-90 transition-opacity`}
              >
                {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
              </button>
              <button
                onClick={handleNext}
                disabled={currentStep >= steps.length - 1}
                className="p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <SkipForward className="w-4 h-4 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            <button
              onClick={handlePrint}
              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <Download className="w-3.5 h-3.5" />
              PDF 매뉴얼
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
