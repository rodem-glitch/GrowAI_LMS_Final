// pages/MainPortalPage.tsx — 메인 포털 페이지 (역할별 자동이동 애니메이션)
import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';
import { useTranslation } from '@/i18n';
import {
  GraduationCap, BookOpen, Shield, Database, ChevronRight,
  LogOut, Bot, Briefcase, Brain, Activity, Search,
  X, CheckCircle2, ExternalLink
} from 'lucide-react';
import NotificationPanel from '@/components/common/NotificationPanel';

interface SectionCard {
  title: string;
  description: string;
  path: string;
  icon: React.ElementType;
  bgClass: string;
  features: string[];
  functionCount: number;
  roleKey?: string;
}

const quickActions = [
  { label: 'AI 진로 상담', path: '/student/career-chat', icon: Bot, color: 'text-blue-500', roles: ['student', 'admin'] },
  { label: '맞춤 채용', path: '/student/jobs', icon: Briefcase, color: 'text-green-500', roles: ['student', 'admin'] },
  { label: 'AI 실라버스', path: '/instructor/ai-syllabus', icon: Brain, color: 'text-purple-500', roles: ['instructor', 'admin'] },
  { label: '운영 현황', path: '/admin/monitoring', icon: Activity, color: 'text-red-500', roles: ['admin'] },
];

// RFP 기능요구사항 상세 데이터
interface RfpSubItem {
  id: string;
  name: string;
  module: string;
  path: string;
  status: 'completed';
}

interface RfpItem {
  key: string;
  label: string;
  count: string;
  color: string;
  bgColor: string;
  borderColor: string;
  description: string;
  subItems: RfpSubItem[];
}

const rfpItems: RfpItem[] = [
  {
    key: 'SFR-001', label: 'SFR-001 AI 성장 에이전트', count: '6건',
    color: 'text-blue-600', bgColor: 'bg-blue-50 dark:bg-blue-900/20', borderColor: 'border-blue-200 dark:border-blue-800',
    description: 'AI 기반 학습자 성장 지원 에이전트 — 진로상담, 자소서 작성, 역량 분석, Gap 분석, 실라버스/퀴즈 자동 생성',
    subItems: [
      { id: 'STD-A01', name: 'AI 진로 상담 챗봇', module: '학생', path: '/student/career-chat', status: 'completed' },
      { id: 'STD-A02', name: 'AI 자기소개서 생성', module: '학생', path: '/student/cover-letter', status: 'completed' },
      { id: 'STD-002', name: '역량 태그 관리', module: '학생', path: '/student/competency', status: 'completed' },
      { id: 'STD-L01', name: 'Gap 분석 (역량 격차)', module: '학생', path: '/student/gap-analysis', status: 'completed' },
      { id: 'PRF-A01', name: 'AI 실라버스 생성', module: '교수자', path: '/instructor/ai-syllabus', status: 'completed' },
      { id: 'PRF-E02', name: 'AI 퀴즈 자동 생성', module: '교수자', path: '/instructor/ai-quiz', status: 'completed' },
    ],
  },
  {
    key: 'SFR-002', label: 'SFR-002 AI 질의응답', count: '2건',
    color: 'text-purple-600', bgColor: 'bg-purple-50 dark:bg-purple-900/20', borderColor: 'border-purple-200 dark:border-purple-800',
    description: 'AI 기반 영상 요약 검증 및 맞춤형 콘텐츠 추천 질의응답 시스템',
    subItems: [
      { id: 'PRF-A03', name: '영상 요약 및 검증', module: '교수자', path: '/instructor/video-summary', status: 'completed' },
      { id: 'STD-L02', name: '맞춤 콘텐츠 추천', module: '학생', path: '/student/content-recommend', status: 'completed' },
    ],
  },
  {
    key: 'SFR-003', label: 'SFR-003 커리어 정보', count: '3건',
    color: 'text-green-600', bgColor: 'bg-green-50 dark:bg-green-900/20', borderColor: 'border-green-200 dark:border-green-800',
    description: '전공 일치 맞춤 채용정보 추천 및 스크랩, 취업률 분석 시스템',
    subItems: [
      { id: 'STD-C01', name: '맞춤 채용 추천', module: '학생', path: '/student/jobs', status: 'completed' },
      { id: 'STD-C02', name: '채용 상세 및 스크랩', module: '학생', path: '/student/jobs', status: 'completed' },
      { id: 'ADM-S03', name: '전공일치 취업률 분석', module: '관리자', path: '/admin/employment-match', status: 'completed' },
    ],
  },
  {
    key: 'SFR-004', label: 'SFR-004 학습 추천', count: '2건',
    color: 'text-amber-600', bgColor: 'bg-amber-50 dark:bg-amber-900/20', borderColor: 'border-amber-200 dark:border-amber-800',
    description: 'AI 기반 학습 콘텐츠 추천 및 교수자 영상 자료 추천 시스템',
    subItems: [
      { id: 'STD-L02', name: '맞춤 콘텐츠 추천', module: '학생', path: '/student/content-recommend', status: 'completed' },
      { id: 'PRF-A02', name: '강의 영상 추천', module: '교수자', path: '/instructor/video-recommend', status: 'completed' },
    ],
  },
  {
    key: 'SFR-005', label: 'SFR-005 커리큘럼 개설', count: '4건',
    color: 'text-red-600', bgColor: 'bg-red-50 dark:bg-red-900/20', borderColor: 'border-red-200 dark:border-red-800',
    description: '과거 강의 불러오기, D&D 커리큘럼 빌더, 강의계획서 제출, 운영 모니터링',
    subItems: [
      { id: 'PRF-001', name: '과거 강의 불러오기', module: '교수자', path: '/instructor/past-lectures', status: 'completed' },
      { id: 'PRF-E01', name: '커리큘럼 D&D 빌더', module: '교수자', path: '/instructor/curriculum-builder', status: 'completed' },
      { id: 'PRF-002', name: '강의계획서 제출', module: '교수자', path: '/instructor/syllabus-submit', status: 'completed' },
      { id: 'ADM-001', name: '운영 모니터링 대시보드', module: '관리자', path: '/admin/monitoring', status: 'completed' },
    ],
  },
  {
    key: 'SFR-006', label: 'SFR-006 통계/지표', count: '4건',
    color: 'text-indigo-600', bgColor: 'bg-indigo-50 dark:bg-indigo-900/20', borderColor: 'border-indigo-200 dark:border-indigo-800',
    description: '인재양성 퍼널 분석, NCS 역량 성취도, 취업률 매칭, 실시간 운영 모니터링',
    subItems: [
      { id: 'ADM-S01', name: '인재양성 퍼널 분석', module: '관리자', path: '/admin/funnel', status: 'completed' },
      { id: 'ADM-S02', name: 'NCS 역량 성취도', module: '관리자', path: '/admin/competency-achievement', status: 'completed' },
      { id: 'ADM-S03', name: '전공일치 취업률', module: '관리자', path: '/admin/employment-match', status: 'completed' },
      { id: 'ADM-001', name: '운영 모니터링', module: '관리자', path: '/admin/monitoring', status: 'completed' },
    ],
  },
  {
    key: 'SFR-007', label: 'SFR-007 통합 인증', count: '3건',
    color: 'text-pink-600', bgColor: 'bg-pink-50 dark:bg-pink-900/20', borderColor: 'border-pink-200 dark:border-pink-800',
    description: 'SSO 통합 로그인, 세션 관리 및 타임아웃 경고, GNB 메가메뉴 네비게이션',
    subItems: [
      { id: 'COM-001', name: 'SSO 통합 로그인', module: '공통', path: '/login', status: 'completed' },
      { id: 'COM-002', name: '세션 관리 및 타임아웃', module: '공통', path: '/', status: 'completed' },
      { id: 'COM-003', name: 'GNB 메가메뉴', module: '공통', path: '/', status: 'completed' },
    ],
  },
  {
    key: 'NFR', label: '비기능 요구사항', count: '13건',
    color: 'text-gray-600', bgColor: 'bg-gray-50 dark:bg-slate-700/50', borderColor: 'border-gray-200 dark:border-slate-600',
    description: '보안, 성능, 운영 관리, 접근 제어, 개인정보 보호, 알림, 통합 검색 등 비기능 요구사항',
    subItems: [
      { id: 'COM-004', name: '실시간 알림 패널', module: '공통', path: '/', status: 'completed' },
      { id: 'COM-005', name: '통합 검색', module: '공통', path: '/search', status: 'completed' },
      { id: 'STD-001', name: '학적정보 동기화', module: '학생', path: '/student/profile', status: 'completed' },
      { id: 'ADM-M01', name: '사용자 제어 (잠금/해제)', module: '관리자', path: '/admin/user-control', status: 'completed' },
      { id: 'ADM-O01', name: '배너/팝업 관리', module: '관리자', path: '/admin/banners', status: 'completed' },
      { id: 'ADM-Y01', name: '접속 로그 관리', module: '관리자', path: '/admin/access-logs', status: 'completed' },
      { id: 'ADM-Y02', name: '개인정보 열람 이력', module: '관리자', path: '/admin/privacy-logs', status: 'completed' },
      { id: 'NFR-01', name: 'HTTPS/TLS 암호화 통신', module: '인프라', path: '/', status: 'completed' },
      { id: 'NFR-02', name: 'JWT 토큰 인증', module: '인프라', path: '/', status: 'completed' },
      { id: 'NFR-03', name: 'XSS/CSRF 방어', module: '인프라', path: '/', status: 'completed' },
      { id: 'NFR-04', name: 'SQL Injection 방어', module: '인프라', path: '/', status: 'completed' },
      { id: 'NFR-05', name: '동시 접속 1,000명 성능', module: '인프라', path: '/', status: 'completed' },
      { id: 'NFR-06', name: '시스템 가용성 99.9%', module: '인프라', path: '/', status: 'completed' },
    ],
  },
];

export default function MainPortalPage() {
  const { user, role, logout } = useAuthStore();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [selectedCard, setSelectedCard] = useState<string | null>(null);
  const [fadeOthers, setFadeOthers] = useState(false);
  const [navigating, setNavigating] = useState(false);
  const hasAutoNavigated = useRef(false);
  const [rfpModal, setRfpModal] = useState<RfpItem | null>(null);

  const roleLabelMap: Record<string, string> = {
    student: t('portal.roleStudent'),
    instructor: t('portal.roleInstructor'),
    admin: t('portal.roleAdmin'),
  };

  const sections: SectionCard[] = [
    {
      title: t('portal.roleStudent'),
      description: 'AI 진로상담, 역량 분석, 맞춤 채용, 학습 추천',
      path: '/student',
      icon: GraduationCap,
      bgClass: 'bg-gradient-to-br from-blue-500 to-blue-700',
      features: ['AI 진로상담', '역량 태그', '맞춤 채용', 'Gap 분석', 'AI 자소서', '콘텐츠 추천'],
      functionCount: 8,
      roleKey: 'student',
    },
    {
      title: t('portal.roleInstructor'),
      description: 'AI 실라버스, 영상추천, 퀴즈생성, 커리큘럼 빌더',
      path: '/instructor',
      icon: BookOpen,
      bgClass: 'bg-gradient-to-br from-purple-500 to-purple-700',
      features: ['AI 실라버스', '영상추천', 'AI 퀴즈', 'D&D 빌더', '강의계획 제출', '과목관리'],
      functionCount: 7,
      roleKey: 'instructor',
    },
    {
      title: t('portal.roleAdmin'),
      description: '운영 모니터링, 퍼널 분석, 취업률, 보안 감사',
      path: '/admin',
      icon: Shield,
      bgClass: 'bg-gradient-to-br from-emerald-500 to-emerald-700',
      features: ['운영 모니터링', '퍼널 분석', '역량 성취도', '취업률', '배너관리', '보안 감사'],
      functionCount: 8,
      roleKey: 'admin',
    },
    {
      title: t('portal.haksaIntegration'),
      description: 'Oracle DB 8종 뷰테이블, 실시간 동기화',
      path: '/haksa',
      icon: Database,
      bgClass: 'bg-gradient-to-br from-amber-500 to-amber-700',
      features: ['학적관리', '성적연동', '수강신청', '학사일정', '데이터동기화'],
      functionCount: 5,
    },
  ];

  // 역할별 카드 필터링: 학생→학생만, 교수자→교수자만, 관리자→전체
  const visibleSections = role === 'admin'
    ? sections
    : sections.filter(s => s.roleKey === role || !s.roleKey);

  const visibleQuickActions = quickActions.filter(a => a.roles.includes(role));

  // 역할별 자동 이동 애니메이션
  useEffect(() => {
    // 관리자는 자동이동 없음 — 모든 카드 표시
    if (role === 'admin' || hasAutoNavigated.current) return;

    // 학생/교수자만 자동이동
    const targetRole = role; // 'student' | 'instructor'
    hasAutoNavigated.current = true;

    // Step 1: 800ms 후 해당 카드 하이라이트
    const highlightTimer = setTimeout(() => {
      setSelectedCard(targetRole);
      setFadeOthers(true);
    }, 600);

    // Step 2: 1800ms 후 자동 이동
    const navigateTimer = setTimeout(() => {
      setNavigating(true);
      const targetPath = targetRole === 'student' ? '/student' : '/instructor';
      setTimeout(() => navigate(targetPath), 300);
    }, 1800);

    return () => {
      clearTimeout(highlightTimer);
      clearTimeout(navigateTimer);
    };
  }, [role, navigate]);

  return (
    <div className={`min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-slate-900 dark:to-slate-800 flex flex-col transition-opacity duration-500 ${navigating ? 'opacity-0' : 'opacity-100'}`}>
      {/* 상단 헤더 */}
      <header className="bg-white dark:bg-slate-900 shadow-sm border-b border-gray-100 dark:border-slate-800">
        <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white tracking-tight">
              {t('common.appName')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-0.5">
              {t('portal.subtitle')}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <Link to="/search" className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800">
              <Search className="w-5 h-5 text-gray-500" />
            </Link>
            <NotificationPanel />
            <button
              onClick={() => { logout(); navigate('/login'); }}
              className="inline-flex items-center gap-2 rounded-lg border border-gray-300 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2 text-sm font-medium text-gray-700 dark:text-slate-300 shadow-sm transition hover:bg-gray-50 dark:hover:bg-slate-700"
            >
              <LogOut className="h-4 w-4" />
              로그아웃
            </button>
          </div>
        </div>
      </header>

      {/* 사용자 정보 바 */}
      <div className="bg-white dark:bg-slate-900 border-b border-gray-200 dark:border-slate-800">
        <div className="max-w-6xl mx-auto px-6 py-3 flex items-center gap-4 text-sm text-gray-600 dark:text-slate-400">
          <span className="font-semibold text-gray-900 dark:text-white">{user?.name ?? '사용자'}</span>
          {user?.campus && <><span className="text-gray-300">|</span><span>{user.campus}</span></>}
          {user?.department && <><span className="text-gray-300">|</span><span>{user.department}</span></>}
          <span className="ml-auto inline-flex items-center rounded-full bg-indigo-100 dark:bg-indigo-900 px-3 py-0.5 text-xs font-medium text-indigo-700 dark:text-indigo-300">
            {roleLabelMap[role] ?? role}
          </span>
        </div>
      </div>

      <main className="flex-1 max-w-6xl w-full mx-auto px-6 py-8 space-y-8">
        {/* AI 빠른 실행 */}
        <div className={`transition-all duration-500 ${fadeOthers ? 'opacity-30 blur-[2px]' : 'opacity-100'}`}>
          <h2 className="text-sm font-medium text-gray-500 dark:text-slate-400 mb-3">AI 빠른 실행</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {visibleQuickActions.map(a => (
              <Link key={a.path} to={a.path}
                className="flex items-center gap-3 p-3 rounded-xl bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 shadow-sm hover:shadow-md transition">
                <a.icon className={`w-5 h-5 ${a.color}`} />
                <span className="text-sm font-medium text-gray-700 dark:text-slate-300">{a.label}</span>
              </Link>
            ))}
          </div>
        </div>

        {/* 섹션 카드 그리드 */}
        <div className={`grid gap-6 ${visibleSections.length === 1 ? 'grid-cols-1 max-w-xl mx-auto' : 'grid-cols-1 md:grid-cols-2'}`}>
          {visibleSections.map(section => {
            const Icon = section.icon;
            const isSelected = selectedCard === section.roleKey;
            const shouldFade = fadeOthers && !isSelected;

            return (
              <Link key={section.path} to={section.path}
                className={`
                  group relative flex items-start gap-5 rounded-2xl ${section.bgClass} p-6 text-white shadow-lg
                  transition-all duration-700 ease-out
                  ${isSelected ? 'scale-105 shadow-2xl ring-4 ring-white/60 ring-offset-2 z-10 animate-portal-pulse' : ''}
                  ${shouldFade ? 'animate-portal-fade-out' : ''}
                  ${!fadeOthers ? 'hover:scale-[1.02] hover:shadow-xl' : ''}
                  animate-portal-card-enter portal-card-delay-${sections.indexOf(section) + 1}
                `}
              >
                {/* 선택 표시 체크마크 */}
                {isSelected && (
                  <div className="absolute -top-3 -right-3 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center animate-bounce z-20">
                    <ChevronRight className="w-5 h-5 text-blue-600" />
                  </div>
                )}

                <div className={`flex-shrink-0 flex items-center justify-center h-14 w-14 rounded-xl bg-white/20 transition-all duration-500 ${isSelected ? 'bg-white/40 scale-110' : ''}`}>
                  <Icon className="h-7 w-7 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h2 className="text-xl font-bold">{section.title}</h2>
                    <span className="text-xs bg-white/25 rounded-full px-2 py-0.5">{section.functionCount}개 기능</span>
                    {isSelected && (
                      <span className="text-xs bg-white/40 rounded-full px-2 py-0.5 animate-pulse">이동 중...</span>
                    )}
                  </div>
                  <p className="mt-1 text-sm text-white/80">{section.description}</p>
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {section.features.map(f => (
                      <span key={f} className="inline-block rounded-full bg-white/20 px-2.5 py-0.5 text-[11px] font-medium">{f}</span>
                    ))}
                  </div>
                </div>
                <ChevronRight className={`absolute bottom-4 right-4 h-5 w-5 text-white/60 transition-transform ${isSelected ? 'animate-portal-slide-right text-white' : 'group-hover:translate-x-1'}`} />
              </Link>
            );
          })}
        </div>

        {/* RFP 요약 카드 — 클릭 시 상세 모달 */}
        <div className={`rounded-2xl bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 p-6 shadow-sm transition-all duration-500 ${fadeOthers ? 'opacity-30 blur-[2px]' : 'opacity-100'}`}>
          <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">{t('portal.rfpTitle')}</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {rfpItems.map(item => (
              <button
                key={item.key}
                onClick={() => setRfpModal(item)}
                className="text-center p-3 rounded-lg bg-gray-50 dark:bg-slate-700 cursor-pointer
                  hover:shadow-md hover:scale-[1.03] hover:ring-2 hover:ring-offset-1
                  hover:ring-current transition-all duration-200 active:scale-95"
              >
                <div className={`text-2xl font-bold ${item.color}`}>{item.count}</div>
                <div className="text-[11px] text-gray-500 dark:text-slate-400 mt-1">{item.label}</div>
              </button>
            ))}
          </div>
          <div className="mt-4 flex items-center justify-between text-sm">
            <span className="text-gray-500 dark:text-slate-400">{t('portal.rfpTotal')}</span>
            <span className="text-green-600 font-medium">{t('portal.rfpComplete')}</span>
          </div>
        </div>
      </main>

      <footer className="py-6 text-center">
        <p className="text-sm text-gray-400 dark:text-slate-600">
          {t('portal.footer')}
        </p>
      </footer>

      {/* 애니메이션 CSS는 index.css 전역 스타일에 정의 */}

      {/* RFP 상세 모달 — 정중앙 */}
      {rfpModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          onClick={() => setRfpModal(null)}
        >
          {/* 오버레이 */}
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

          {/* 모달 본체 */}
          <div
            className={`relative w-full max-w-2xl max-h-[85vh] overflow-hidden rounded-2xl bg-white dark:bg-slate-800 shadow-2xl border ${rfpModal.borderColor} animate-[modalIn_0.25s_ease-out]`}
            onClick={e => e.stopPropagation()}
          >
            {/* 헤더 */}
            <div className={`px-6 py-4 ${rfpModal.bgColor} border-b ${rfpModal.borderColor}`}>
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className={`text-xs font-mono font-bold ${rfpModal.color} bg-white dark:bg-slate-900 px-2 py-0.5 rounded`}>
                      {rfpModal.key}
                    </span>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                      {rfpModal.label.replace(`${rfpModal.key} `, '')}
                    </h3>
                  </div>
                  <p className="text-sm text-gray-600 dark:text-slate-400 mt-1">{rfpModal.description}</p>
                </div>
                <button
                  onClick={() => setRfpModal(null)}
                  className="flex-shrink-0 p-2 rounded-lg hover:bg-white/60 dark:hover:bg-slate-700 transition"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            </div>

            {/* 본문 — 기능 목록 */}
            <div className="overflow-y-auto max-h-[55vh] p-6">
              <div className="flex items-center gap-2 mb-4">
                <span className={`text-sm font-semibold ${rfpModal.color}`}>{t('portal.implementedFeatures')} {rfpModal.subItems.length}건</span>
                <span className="text-xs text-green-600 bg-green-50 dark:bg-green-900/30 px-2 py-0.5 rounded-full font-medium">{t('portal.allComplete')}</span>
              </div>

              <div className="space-y-2">
                {rfpModal.subItems.map((sub, idx) => (
                  <div
                    key={`${sub.id}-${idx}`}
                    className={`flex items-center gap-3 p-3 rounded-xl border ${rfpModal.borderColor} bg-white dark:bg-slate-800 hover:shadow-sm transition group`}
                  >
                    <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono text-gray-400">{sub.id}</span>
                        <span className="text-sm font-medium text-gray-900 dark:text-white">{sub.name}</span>
                      </div>
                      <span className="text-[11px] text-gray-400 dark:text-slate-500">{t('portal.module')}: {sub.module}</span>
                    </div>
                    {sub.path !== '/' && (
                      <button
                        onClick={() => { setRfpModal(null); navigate(sub.path); }}
                        className="flex-shrink-0 flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium
                          bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300
                          hover:bg-indigo-100 hover:text-indigo-700 dark:hover:bg-indigo-900 dark:hover:text-indigo-300
                          opacity-0 group-hover:opacity-100 transition-all"
                      >
                        <ExternalLink className="w-3 h-3" />
                        {t('common.move')}
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* 푸터 */}
            <div className={`px-6 py-3 ${rfpModal.bgColor} border-t ${rfpModal.borderColor} flex items-center justify-between`}>
              <span className="text-xs text-gray-500 dark:text-slate-400">
                {t('portal.rfpMapping')}
              </span>
              <button
                onClick={() => setRfpModal(null)}
                className="px-4 py-1.5 rounded-lg bg-white dark:bg-slate-700 text-sm font-medium text-gray-700 dark:text-slate-300 shadow-sm hover:shadow transition"
              >
                {t('common.close')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
