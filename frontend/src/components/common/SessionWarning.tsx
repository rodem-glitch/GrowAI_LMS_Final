// components/common/SessionWarning.tsx — COM-002: 세션 만료 경고 팝업
import { useState, useEffect, useCallback } from 'react';
import { Clock, RefreshCw, LogOut, ShieldAlert } from 'lucide-react';
import { useTranslation } from '@/i18n';

/**
 * 세션 만료 경고 팝업
 * - 세션 만료 10분 전, 5분 전에 표시
 * - 남은 시간 카운트다운 (MM:SS)
 * - 연장 / 로그아웃 선택
 * - 진행 바로 남은 시간 시각 표시
 */

interface SessionWarningProps {
  /** 세션 전체 시간(초). 기본 30분 */
  totalSeconds?: number;
  /** 연장 버튼 클릭 핸들러 */
  onExtend?: () => void;
  /** 로그아웃 버튼 클릭 핸들러 */
  onLogout?: () => void;
}

export default function SessionWarning({
  totalSeconds = 1800,
  onExtend,
  onLogout,
}: SessionWarningProps) {
  const { t } = useTranslation();

  // Mock 상태: 4분 30초 남은 시점에서 시작
  const [timeLeft, setTimeLeft] = useState(270);
  const [visible, setVisible] = useState(true);
  const [extending, setExtending] = useState(false);

  // 카운트다운 타이머
  useEffect(() => {
    if (!visible || timeLeft <= 0) return;

    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [visible, timeLeft]);

  // 시간 포맷 (MM:SS)
  const formatTime = useCallback((seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }, []);

  // 남은 시간 비율 (경고 구간 10분 = 600초 기준)
  const warningWindow = 600; // 10분
  const progressPercent = Math.max(0, (timeLeft / warningWindow) * 100);

  // 긴급도에 따른 색상
  const isUrgent = timeLeft <= 60; // 1분 이하
  const isCritical = timeLeft <= 300; // 5분 이하
  const progressColor = isUrgent
    ? 'bg-red-500'
    : isCritical
      ? 'bg-orange-500'
      : 'bg-blue-500';
  const borderColor = isUrgent
    ? 'border-red-200 dark:border-red-800'
    : isCritical
      ? 'border-orange-200 dark:border-orange-800'
      : 'border-blue-200 dark:border-blue-800';

  // 연장 처리
  const handleExtend = () => {
    setExtending(true);
    setTimeout(() => {
      setTimeLeft(totalSeconds);
      setVisible(false);
      setExtending(false);
      onExtend?.();
    }, 800);
  };

  // 로그아웃 처리
  const handleLogout = () => {
    setVisible(false);
    onLogout?.();
  };

  // 세션 만료
  if (timeLeft <= 0 && visible) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm">
        <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-2xl p-6 w-full max-w-sm mx-4 text-center">
          <div className="w-14 h-14 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center mx-auto mb-4">
            <ShieldAlert className="w-7 h-7 text-red-600" />
          </div>
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
            {t('session.expired')}
          </h3>
          <p className="text-sm text-gray-500 dark:text-slate-400 mb-5">
            {t('session.expiredDesc')}
          </p>
          <button
            onClick={handleLogout}
            className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 transition-colors"
          >
            <LogOut className="w-4 h-4" />
            {t('session.goToLogin')}
          </button>
        </div>
      </div>
    );
  }

  if (!visible) return null;

  return (
    <div className="fixed bottom-6 right-6 z-[9999] animate-in slide-in-from-bottom-4 duration-300">
      <div
        className={`bg-white dark:bg-slate-800 rounded-2xl shadow-2xl border ${borderColor} w-80 overflow-hidden`}
      >
        {/* 진행 바 (상단) */}
        <div className="h-1.5 bg-gray-100 dark:bg-slate-700">
          <div
            className={`h-full ${progressColor} rounded-r-full transition-all duration-1000 ease-linear`}
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        <div className="p-4">
          {/* 헤더 */}
          <div className="flex items-center gap-3 mb-3">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center ${
                isUrgent
                  ? 'bg-red-100 dark:bg-red-900/30'
                  : isCritical
                    ? 'bg-orange-100 dark:bg-orange-900/30'
                    : 'bg-blue-100 dark:bg-blue-900/30'
              }`}
            >
              <Clock
                className={`w-5 h-5 ${
                  isUrgent
                    ? 'text-red-600 animate-pulse'
                    : isCritical
                      ? 'text-orange-600'
                      : 'text-blue-600'
                }`}
              />
            </div>
            <div className="flex-1">
              <h4 className="text-sm font-bold text-gray-900 dark:text-white">
                {t('session.expiringTitle')}
              </h4>
              <p className="text-[11px] text-gray-500 dark:text-slate-400">
                {isCritical
                  ? t('session.soonLogout')
                  : t('session.sessionExpiring')}
              </p>
            </div>
          </div>

          {/* 카운트다운 */}
          <div className="text-center mb-4">
            <div
              className={`text-3xl font-mono font-bold tracking-wider ${
                isUrgent
                  ? 'text-red-600'
                  : isCritical
                    ? 'text-orange-600'
                    : 'text-blue-600'
              }`}
            >
              {formatTime(timeLeft)}
            </div>
            <p className="text-[10px] text-gray-400 mt-1">{t('session.remaining')}</p>
          </div>

          {/* 상세 진행 바 */}
          <div className="mb-4">
            <div className="flex justify-between text-[10px] text-gray-400 mb-1">
              <span>{t('session.sessionRemain')}</span>
              <span>{Math.round(progressPercent)}%</span>
            </div>
            <div className="w-full h-2 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
              <div
                className={`h-full ${progressColor} rounded-full transition-all duration-1000 ease-linear`}
                style={{ width: `${progressPercent}%` }}
              />
            </div>
          </div>

          {/* 버튼 영역 */}
          <div className="flex gap-2">
            <button
              onClick={handleLogout}
              className="flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-600 text-sm font-medium text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
            >
              <LogOut className="w-3.5 h-3.5" />
              {t('common.logout')}
            </button>
            <button
              onClick={handleExtend}
              disabled={extending}
              className="flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 disabled:opacity-60 transition-colors"
            >
              <RefreshCw
                className={`w-3.5 h-3.5 ${extending ? 'animate-spin' : ''}`}
              />
              {extending ? t('session.extending') : t('session.extend')}
            </button>
          </div>

          {/* 안내 문구 */}
          <p className="text-[10px] text-gray-400 text-center mt-3">
            {t('session.autoLogoutMsg')}
          </p>
        </div>
      </div>
    </div>
  );
}
