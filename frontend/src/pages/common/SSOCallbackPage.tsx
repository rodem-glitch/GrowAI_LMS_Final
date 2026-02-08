// pages/common/SSOCallbackPage.tsx — COM-001: SSO 통합 로그인 콜백
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Shield,
  CheckCircle2,
  XCircle,
  RefreshCw,
  Loader2,
  ArrowRight,
  KeyRound,
  Building2,
  Lock,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

/**
 * SSO 콜백 핸들러 페이지 (COM-001)
 * - Keycloak / SAML SSO 인증 후 리다이렉트 콜백 처리
 * - 로딩 스피너 + 인증 확인 중 메시지
 * - 성공: 메인 포탈로 리다이렉트
 * - 실패: 에러 메시지 + "다시 시도" 버튼
 * - 학사통합인증 로고 영역 + 진행 표시
 */

type SSOStep = 'INIT' | 'VALIDATING' | 'FETCHING_PROFILE' | 'SUCCESS' | 'ERROR';

interface StepInfo {
  label: string;
  description: string;
}

const steps: Record<Exclude<SSOStep, 'ERROR'>, StepInfo> = {
  INIT: {
    label: '연결 중',
    description: '학사통합인증 서버에 연결 중입니다...',
  },
  VALIDATING: {
    label: '토큰 검증',
    description: 'SSO 인증 토큰을 검증하고 있습니다...',
  },
  FETCHING_PROFILE: {
    label: '사용자 정보',
    description: '사용자 프로필 정보를 가져오고 있습니다...',
  },
  SUCCESS: {
    label: '인증 완료',
    description: '인증이 완료되었습니다. 잠시 후 이동합니다.',
  },
};

// Mock: 에러 타입
type ErrorType = 'TOKEN_EXPIRED' | 'TOKEN_INVALID' | 'SERVER_ERROR' | 'NETWORK_ERROR';

const errorMessages: Record<ErrorType, { title: string; message: string }> = {
  TOKEN_EXPIRED: {
    title: '인증 시간 초과',
    message: '인증 토큰이 만료되었습니다. 다시 로그인을 시도해 주세요.',
  },
  TOKEN_INVALID: {
    title: '인증 실패',
    message: '유효하지 않은 인증 토큰입니다. SSO 서버 상태를 확인해 주세요.',
  },
  SERVER_ERROR: {
    title: '서버 오류',
    message: '학사통합인증 서버에 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
  },
  NETWORK_ERROR: {
    title: '네트워크 오류',
    message: '네트워크 연결이 불안정합니다. 인터넷 연결 상태를 확인해 주세요.',
  },
};

export default function SSOCallbackPage() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [currentStep, setCurrentStep] = useState<SSOStep>('INIT');
  const [progress, setProgress] = useState(0);
  const [errorType, setErrorType] = useState<ErrorType | null>(null);
  // Demo 모드: true이면 성공 흐름, false이면 에러 흐름
  const [demoSuccess, setDemoSuccess] = useState(true);

  // SSO 인증 시뮬레이션
  useEffect(() => {
    if (currentStep === 'ERROR' || currentStep === 'SUCCESS') return;

    const stepSequence: SSOStep[] = [
      'INIT',
      'VALIDATING',
      'FETCHING_PROFILE',
      'SUCCESS',
    ];
    const currentIdx = stepSequence.indexOf(currentStep);
    const progressValues = [10, 40, 70, 100];

    // 진행률 애니메이션
    const progressTimer = setInterval(() => {
      setProgress((prev) => {
        const target = progressValues[currentIdx] || 0;
        if (prev >= target) {
          clearInterval(progressTimer);
          return target;
        }
        return prev + 2;
      });
    }, 50);

    // 다음 단계로 전환
    const stepTimer = setTimeout(() => {
      if (currentIdx < stepSequence.length - 1) {
        // 마지막 단계 전에 에러 시뮬레이션 여부 확인
        if (!demoSuccess && currentIdx === 1) {
          setCurrentStep('ERROR');
          setErrorType('TOKEN_EXPIRED');
          setProgress(40);
        } else {
          setCurrentStep(stepSequence[currentIdx + 1]);
        }
      }
    }, 1500);

    return () => {
      clearInterval(progressTimer);
      clearTimeout(stepTimer);
    };
  }, [currentStep, demoSuccess]);

  // 성공 시 리다이렉트 (데모에서는 알림만)
  useEffect(() => {
    if (currentStep === 'SUCCESS') {
      const timer = setTimeout(() => {
        navigate('/');
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [currentStep]);

  // 다시 시도
  const handleRetry = () => {
    setCurrentStep('INIT');
    setProgress(0);
    setErrorType(null);
    setDemoSuccess(true);
  };

  // 에러 시뮬레이션 토글
  const toggleDemoMode = () => {
    setDemoSuccess((prev) => !prev);
    setCurrentStep('INIT');
    setProgress(0);
    setErrorType(null);
  };

  // 단계 표시 아이콘
  const getStepStatus = (stepKey: string) => {
    const stepOrder = ['INIT', 'VALIDATING', 'FETCHING_PROFILE', 'SUCCESS'];
    const currentIdx = stepOrder.indexOf(currentStep);
    const stepIdx = stepOrder.indexOf(stepKey);

    if (currentStep === 'ERROR' && stepIdx >= stepOrder.indexOf('VALIDATING')) {
      return stepIdx === stepOrder.indexOf('VALIDATING') ? 'error' : 'pending';
    }

    if (stepIdx < currentIdx) return 'completed';
    if (stepIdx === currentIdx) return 'active';
    return 'pending';
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 dark:from-slate-900 dark:via-slate-900 dark:to-slate-800 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* 학사통합인증 로고 영역 */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-700 shadow-lg shadow-blue-500/25 mb-4">
            <Shield className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            학사통합인증
          </h1>
          <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">
            한국폴리텍대학 SSO 통합 로그인
          </p>
        </div>

        {/* 메인 카드 */}
        <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl border border-gray-100 dark:border-slate-700 overflow-hidden">
          {/* 진행 바 */}
          <div className="h-1.5 bg-gray-100 dark:bg-slate-700">
            <div
              className={`h-full rounded-r-full transition-all duration-500 ease-out ${
                currentStep === 'ERROR'
                  ? 'bg-red-500'
                  : currentStep === 'SUCCESS'
                    ? 'bg-green-500'
                    : 'bg-blue-500'
              }`}
              style={{ width: `${progress}%` }}
            />
          </div>

          <div className="p-6">
            {/* 에러 상태 */}
            {currentStep === 'ERROR' && errorType ? (
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center mx-auto mb-4">
                  <XCircle className="w-8 h-8 text-red-600" />
                </div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
                  {errorMessages[errorType].title}
                </h2>
                <p className="text-sm text-gray-500 dark:text-slate-400 mb-6 leading-relaxed">
                  {errorMessages[errorType].message}
                </p>

                <div className="space-y-2">
                  <button
                    onClick={handleRetry}
                    className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 transition-colors"
                  >
                    <RefreshCw className="w-4 h-4" />
                    다시 시도
                  </button>
                  <a
                    href="/login"
                    className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-gray-200 dark:border-slate-600 text-sm font-medium text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
                  >
                    일반 로그인으로 이동
                  </a>
                </div>

                {/* 에러 상세 (접힘 가능) */}
                <div className="mt-4 p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50 text-left">
                  <p className="text-[10px] text-gray-400 dark:text-slate-500 font-mono">
                    Error Code: SSO_{errorType}
                    <br />
                    Timestamp: {new Date().toISOString()}
                    <br />
                    Session: demo-session-id-xxx
                  </p>
                </div>
              </div>
            ) : currentStep === 'SUCCESS' ? (
              /* 성공 상태 */
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center mx-auto mb-4">
                  <CheckCircle2 className="w-8 h-8 text-green-600" />
                </div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
                  {t('common.completed')}
                </h2>
                <p className="text-sm text-gray-500 dark:text-slate-400 mb-4">
                  로그인이 완료되었습니다. 메인 포탈로 이동합니다.
                </p>

                {/* 사용자 정보 미리보기 */}
                <div className="bg-gray-50 dark:bg-slate-700/50 rounded-xl p-4 mb-4 text-left">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                      <Building2 className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <div className="text-sm font-bold text-gray-900 dark:text-white">
                        박학생
                      </div>
                      <div className="text-[11px] text-gray-500 dark:text-slate-400">
                        서울강서캠퍼스 | 컴퓨터공학과
                      </div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 mt-3">
                    <div className="bg-white dark:bg-slate-800 rounded-lg p-2 text-center">
                      <div className="text-[10px] text-gray-400">학번</div>
                      <div className="text-xs font-bold text-gray-900 dark:text-white">
                        2024110001
                      </div>
                    </div>
                    <div className="bg-white dark:bg-slate-800 rounded-lg p-2 text-center">
                      <div className="text-[10px] text-gray-400">권한</div>
                      <div className="text-xs font-bold text-blue-600">학생</div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-center gap-2 text-sm text-blue-600">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  메인 포탈로 이동 중...
                </div>
              </div>
            ) : (
              /* 로딩 상태 (INIT, VALIDATING, FETCHING_PROFILE) */
              <div className="text-center">
                {/* 스피너 */}
                <div className="w-16 h-16 rounded-full bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center mx-auto mb-5 relative">
                  <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
                  <div className="absolute inset-0 rounded-full border-2 border-blue-200 dark:border-blue-800 animate-pulse" />
                </div>

                <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-1">
                  {t('common.loading')}
                </h2>
                <p className="text-sm text-gray-500 dark:text-slate-400 mb-6">
                  {steps[currentStep as Exclude<SSOStep, 'ERROR'>]?.description}
                </p>

                {/* 단계 표시 */}
                <div className="space-y-3 text-left mb-2">
                  {(
                    Object.entries(steps) as [
                      Exclude<SSOStep, 'ERROR'>,
                      StepInfo,
                    ][]
                  ).map(([key, step]) => {
                    const status = getStepStatus(key);
                    const stepIcons: Record<string, React.ElementType> = {
                      INIT: Lock,
                      VALIDATING: KeyRound,
                      FETCHING_PROFILE: Building2,
                      SUCCESS: CheckCircle2,
                    };
                    const StepIcon = stepIcons[key] || Shield;

                    return (
                      <div
                        key={key}
                        className={`flex items-center gap-3 px-3 py-2 rounded-lg transition-colors ${
                          status === 'active'
                            ? 'bg-blue-50 dark:bg-blue-900/20'
                            : status === 'completed'
                              ? 'bg-green-50/50 dark:bg-green-900/10'
                              : ''
                        }`}
                      >
                        <div
                          className={`w-7 h-7 rounded-full flex items-center justify-center shrink-0 ${
                            status === 'completed'
                              ? 'bg-green-100 dark:bg-green-900/30'
                              : status === 'active'
                                ? 'bg-blue-100 dark:bg-blue-900/30'
                                : status === 'error'
                                  ? 'bg-red-100 dark:bg-red-900/30'
                                  : 'bg-gray-100 dark:bg-slate-700'
                          }`}
                        >
                          {status === 'completed' ? (
                            <CheckCircle2 className="w-4 h-4 text-green-600" />
                          ) : status === 'active' ? (
                            <Loader2 className="w-4 h-4 text-blue-600 animate-spin" />
                          ) : status === 'error' ? (
                            <XCircle className="w-4 h-4 text-red-600" />
                          ) : (
                            <StepIcon className="w-3.5 h-3.5 text-gray-400" />
                          )}
                        </div>
                        <div className="flex-1">
                          <div
                            className={`text-sm font-medium ${
                              status === 'completed'
                                ? 'text-green-700 dark:text-green-400'
                                : status === 'active'
                                  ? 'text-blue-700 dark:text-blue-400'
                                  : 'text-gray-400 dark:text-slate-500'
                            }`}
                          >
                            {step.label}
                          </div>
                        </div>
                        {status === 'completed' && (
                          <span className="text-[10px] text-green-500 font-medium">
                            완료
                          </span>
                        )}
                        {status === 'active' && (
                          <span className="text-[10px] text-blue-500 font-medium animate-pulse">
                            처리 중
                          </span>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>

          {/* 데모 컨트롤 (개발용) */}
          <div className="px-6 py-3 border-t border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/50">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-gray-400">Demo 모드</span>
              <div className="flex items-center gap-2">
                <button
                  onClick={toggleDemoMode}
                  className={`px-2.5 py-1 rounded-md text-[10px] font-medium transition-colors ${
                    demoSuccess
                      ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                      : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                  }`}
                >
                  {demoSuccess ? '성공 흐름' : '에러 흐름'}
                </button>
                <button
                  onClick={handleRetry}
                  className="px-2.5 py-1 rounded-md bg-gray-200 dark:bg-slate-700 text-[10px] font-medium text-gray-600 dark:text-slate-300 hover:bg-gray-300 transition-colors"
                >
                  재시작
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* 하단 안내 */}
        <div className="text-center mt-6">
          <div className="flex items-center justify-center gap-2 mb-2">
            <Lock className="w-3 h-3 text-gray-400" />
            <span className="text-[10px] text-gray-400">
              SSL 암호화 보안 연결
            </span>
          </div>
          <p className="text-[10px] text-gray-400">
            한국폴리텍대학 학사통합인증 시스템 (Keycloak SSO)
          </p>
          <p className="text-[10px] text-gray-400 mt-0.5">
            문의: 정보화팀 02-3668-0100
          </p>
        </div>
      </div>
    </div>
  );
}
