// components/common/NotificationPanel.tsx — COM-004: 통합 알림 패널
import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from '@/i18n';
import {
  Bell,
  Briefcase,
  CheckCircle2,
  FileText,
  ClipboardList,
  Settings,
  GraduationCap,
  HelpCircle,
  Check,
  X,
  ExternalLink,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

/**
 * 통합 알림 패널
 * - 벨 아이콘 클릭 시 드롭다운
 * - 알림 유형별 색상/아이콘 구분
 * - 읽음/안읽음 상태 관리
 * - "모두 읽음" 일괄 처리
 */

type NotificationType =
  | 'JOB_DEADLINE'
  | 'APPROVAL'
  | 'ASSIGNMENT'
  | 'EXAM'
  | 'SYSTEM'
  | 'GRADE'
  | 'QNA';

interface Notification {
  id: number;
  type: NotificationType;
  title: string;
  message: string;
  link: string;
  isRead: boolean;
  createdAt: string;
}

// 유형별 설정
const typeConfig: Record<
  NotificationType,
  { icon: LucideIcon; color: string; bgColor: string; label: string }
> = {
  JOB_DEADLINE: {
    icon: Briefcase,
    color: 'text-orange-600',
    bgColor: 'bg-orange-100 dark:bg-orange-900/30',
    label: '채용마감',
  },
  APPROVAL: {
    icon: CheckCircle2,
    color: 'text-green-600',
    bgColor: 'bg-green-100 dark:bg-green-900/30',
    label: '승인완료',
  },
  ASSIGNMENT: {
    icon: FileText,
    color: 'text-blue-600',
    bgColor: 'bg-blue-100 dark:bg-blue-900/30',
    label: '과제',
  },
  EXAM: {
    icon: ClipboardList,
    color: 'text-purple-600',
    bgColor: 'bg-purple-100 dark:bg-purple-900/30',
    label: '시험',
  },
  SYSTEM: {
    icon: Settings,
    color: 'text-gray-600',
    bgColor: 'bg-gray-100 dark:bg-gray-700',
    label: '시스템',
  },
  GRADE: {
    icon: GraduationCap,
    color: 'text-emerald-600',
    bgColor: 'bg-emerald-100 dark:bg-emerald-900/30',
    label: '성적',
  },
  QNA: {
    icon: HelpCircle,
    color: 'text-cyan-600',
    bgColor: 'bg-cyan-100 dark:bg-cyan-900/30',
    label: 'Q&A',
  },
};

// Mock 알림 데이터 (8개, 3개 미읽음)
const mockNotifications: Notification[] = [
  {
    id: 1,
    type: 'JOB_DEADLINE',
    title: '삼성전자 채용 마감 D-3',
    message:
      '삼성전자 2026년 상반기 신입사원 공개채용이 3일 후 마감됩니다. 지원서를 확인해 주세요.',
    link: '/student/job/apply/101',
    isRead: false,
    createdAt: '5분 전',
  },
  {
    id: 2,
    type: 'ASSIGNMENT',
    title: '파이썬 프로그래밍 과제 제출 마감',
    message:
      '[파이썬 프로그래밍 기초] 3주차 과제 제출 마감이 내일까지입니다.',
    link: '/student/classroom/CS101/homework/3',
    isRead: false,
    createdAt: '23분 전',
  },
  {
    id: 3,
    type: 'APPROVAL',
    title: '수강 신청 승인 완료',
    message:
      '[AI 머신러닝 실습] 수강 신청이 승인되었습니다. 강의실에서 확인하세요.',
    link: '/student/courses/AI201',
    isRead: false,
    createdAt: '1시간 전',
  },
  {
    id: 4,
    type: 'GRADE',
    title: '중간고사 성적 공개',
    message:
      '[데이터베이스 설계] 중간고사 성적이 등록되었습니다. 마이페이지에서 확인하세요.',
    link: '/student/mypage',
    isRead: true,
    createdAt: '3시간 전',
  },
  {
    id: 5,
    type: 'EXAM',
    title: '기말고사 일정 안내',
    message:
      '[웹 프로그래밍] 기말고사가 2026년 2월 20일로 확정되었습니다.',
    link: '/student/classroom/WEB301/exam/final',
    isRead: true,
    createdAt: '5시간 전',
  },
  {
    id: 6,
    type: 'QNA',
    title: 'Q&A 답변 등록',
    message:
      '[네트워크 보안] 게시판에 작성하신 질문에 교수님의 답변이 등록되었습니다.',
    link: '/student/board/42',
    isRead: true,
    createdAt: '어제',
  },
  {
    id: 7,
    type: 'SYSTEM',
    title: '시스템 점검 안내',
    message:
      '2026년 2월 10일(월) 02:00~06:00 시스템 정기 점검이 예정되어 있습니다.',
    link: '/student/board/notice',
    isRead: true,
    createdAt: '2일 전',
  },
  {
    id: 8,
    type: 'JOB_DEADLINE',
    title: 'LG CNS 인턴 채용 공고',
    message:
      'LG CNS 2026년 하계 인턴 채용 공고가 등록되었습니다. 관심 공고에 추가해 보세요.',
    link: '/student/job/apply/102',
    isRead: true,
    createdAt: '3일 전',
  },
];

export default function NotificationPanel() {
  const [isOpen, setIsOpen] = useState(false);
  const [notifications, setNotifications] =
    useState<Notification[]>(mockNotifications);
  const panelRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const { t } = useTranslation();

  const typeLabels: Record<NotificationType, string> = {
    JOB_DEADLINE: t('notification.jobDeadline'),
    APPROVAL: t('notification.approval'),
    ASSIGNMENT: t('notification.assignment'),
    EXAM: t('notification.exam'),
    SYSTEM: t('notification.system'),
    GRADE: t('notification.grade'),
    QNA: t('notification.qna'),
  };

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  // 외부 클릭 시 닫기
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  // 개별 읽음 처리
  const markAsRead = (id: number) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
    );
  };

  // 모두 읽음 처리
  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
  };

  // 알림 클릭 핸들러 — 읽음 처리 후 해당 페이지로 이동
  const handleClick = (notification: Notification) => {
    markAsRead(notification.id);
    setIsOpen(false);
    navigate(notification.link);
  };

  return (
    <div ref={panelRef} className="relative">
      {/* 벨 아이콘 버튼 */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
        aria-label={t('notification.title')}
      >
        <Bell className="w-5 h-5 text-gray-600 dark:text-slate-300" />
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] flex items-center justify-center rounded-full bg-red-500 text-white text-[10px] font-bold px-1 animate-pulse">
            {unreadCount}
          </span>
        )}
      </button>

      {/* 알림 드롭다운 패널 */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-96 bg-white dark:bg-slate-800 rounded-2xl shadow-2xl border border-gray-100 dark:border-slate-700 z-50 overflow-hidden">
          {/* 헤더 */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-slate-700">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                {t('notification.title')}
              </h3>
              {unreadCount > 0 && (
                <span className="inline-flex items-center justify-center min-w-[20px] h-5 rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 text-[10px] font-bold px-1.5">
                  {unreadCount}
                </span>
              )}
            </div>
            <div className="flex items-center gap-1">
              {unreadCount > 0 && (
                <button
                  onClick={markAllAsRead}
                  className="inline-flex items-center gap-1 px-2 py-1 rounded-md text-[11px] font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors"
                >
                  <Check className="w-3 h-3" />
                  {t('notification.markAllRead')}
                </button>
              )}
              <button
                onClick={() => setIsOpen(false)}
                className="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
              >
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
          </div>

          {/* 알림 목록 */}
          <div className="max-h-[420px] overflow-y-auto">
            {notifications.length === 0 ? (
              <div className="py-12 text-center">
                <Bell className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                <p className="text-sm text-gray-400">{t('notification.noNotifications')}</p>
              </div>
            ) : (
              notifications.map((notification) => {
                const config = typeConfig[notification.type];
                const Icon = config.icon;

                return (
                  <button
                    key={notification.id}
                    onClick={() => handleClick(notification)}
                    className={`w-full flex items-start gap-3 px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors border-b border-gray-50 dark:border-slate-700/50 last:border-b-0 ${
                      !notification.isRead
                        ? 'bg-blue-50/50 dark:bg-blue-900/10'
                        : ''
                    }`}
                  >
                    {/* 아이콘 */}
                    <div
                      className={`w-9 h-9 rounded-lg ${config.bgColor} flex items-center justify-center shrink-0 mt-0.5`}
                    >
                      <Icon className={`w-4 h-4 ${config.color}`} />
                    </div>

                    {/* 내용 */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span
                          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${config.bgColor} ${config.color}`}
                        >
                          {typeLabels[notification.type]}
                        </span>
                        {!notification.isRead && (
                          <span className="w-1.5 h-1.5 rounded-full bg-blue-500" />
                        )}
                      </div>
                      <h4
                        className={`text-sm leading-snug ${
                          !notification.isRead
                            ? 'font-bold text-gray-900 dark:text-white'
                            : 'font-medium text-gray-700 dark:text-slate-300'
                        }`}
                      >
                        {notification.title}
                      </h4>
                      <p className="text-[11px] text-gray-500 dark:text-slate-400 mt-0.5 line-clamp-2 leading-relaxed">
                        {notification.message}
                      </p>
                      <span className="text-[10px] text-gray-400 mt-1 block">
                        {notification.createdAt}
                      </span>
                    </div>

                    {/* 이동 아이콘 */}
                    <ExternalLink className="w-3.5 h-3.5 text-gray-300 shrink-0 mt-1" />
                  </button>
                );
              })
            )}
          </div>

          {/* 푸터 */}
          <div className="px-4 py-2.5 border-t border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/50">
            <button
              onClick={() => { setIsOpen(false); navigate('/student/board/notice'); }}
              className="w-full text-center text-[11px] font-medium text-blue-600 hover:text-blue-700 transition-colors"
            >
              {t('notification.viewAll')}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
