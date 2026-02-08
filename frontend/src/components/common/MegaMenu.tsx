// components/common/MegaMenu.tsx — COM-003: GNB 메가 메뉴
import { useState, useRef, useEffect, useMemo } from 'react';
import { useTranslation } from '@/i18n';
import {
  BookOpen,
  Bot,
  Briefcase,
  Users,
  FileText,
  ClipboardList,
  BarChart3,
  Settings,
  Shield,
  GraduationCap,
  Monitor,
  MessageSquare,
  Layers,
  Database,
  Award,
  ChevronDown,
  ChevronRight,
  Menu,
  X,
  Home,
  Lightbulb,
  Brain,
  Target,
  Megaphone,
  Wrench,
  Lock,
  PieChart,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

/**
 * GNB 메가 메뉴 (COM-003)
 * - 데스크톱: hover로 드롭다운 메가 메뉴
 * - 모바일: 햄버거 메뉴 → 드로어
 * - 역할별 메뉴 표시 (학생/교수자/관리자)
 */

type UserRole = 'student' | 'instructor' | 'admin';

interface MenuItem {
  label: string;
  path: string;
  icon: LucideIcon;
  description?: string;
}

interface MenuSection {
  title: string;
  icon: LucideIcon;
  items: MenuItem[];
}

interface MegaMenuProps {
  role?: UserRole;
}

// 역할별 메뉴 정의
const menuByRole: Record<UserRole, MenuSection[]> = {
  student: [
    {
      title: '내 학습',
      icon: BookOpen,
      items: [
        {
          label: '내 강좌',
          path: '/student/mypage/courses',
          icon: BookOpen,
          description: '수강 중인 강좌 목록',
        },
        {
          label: '수강 신청',
          path: '/student/courses',
          icon: GraduationCap,
          description: '전체 강좌 탐색 및 신청',
        },
        {
          label: '학습 대시보드',
          path: '/student/mypage',
          icon: BarChart3,
          description: '학습 현황 및 통계',
        },
        {
          label: '수료증 관리',
          path: '/student/mypage/certificates',
          icon: Award,
          description: '취득 수료증 확인 및 출력',
        },
        {
          label: '강의실',
          path: '/student/classroom',
          icon: Monitor,
          description: '동영상 학습, 과제, 시험',
        },
      ],
    },
    {
      title: 'AI 서비스',
      icon: Bot,
      items: [
        {
          label: 'AI 학습 도우미',
          path: '/student/ai-chat',
          icon: Bot,
          description: 'AI 기반 1:1 학습 질문 답변',
        },
        {
          label: 'AI 학습 추천',
          path: '/student/ai-recommend',
          icon: Lightbulb,
          description: '맞춤형 강좌/콘텐츠 추천',
        },
        {
          label: 'AI 학습 분석',
          path: '/student/ai-analytics',
          icon: Brain,
          description: '학습 패턴 분석 및 인사이트',
        },
      ],
    },
    {
      title: '취업/진로',
      icon: Briefcase,
      items: [
        {
          label: '채용공고',
          path: '/student/job/list',
          icon: Briefcase,
          description: '최신 채용 정보 모아보기',
        },
        {
          label: 'AI 직무매칭',
          path: '/student/job/match',
          icon: Target,
          description: 'AI 기반 맞춤 직무 추천',
        },
        {
          label: '이력서 관리',
          path: '/student/job/resume',
          icon: FileText,
          description: '이력서 작성 및 관리',
        },
        {
          label: '진로 상담',
          path: '/student/job/counsel',
          icon: MessageSquare,
          description: '온라인 진로 상담 신청',
        },
      ],
    },
    {
      title: '커뮤니티',
      icon: Users,
      items: [
        {
          label: '공지사항',
          path: '/student/board?type=notice',
          icon: Megaphone,
          description: '학교 및 학과 공지',
        },
        {
          label: 'Q&A 게시판',
          path: '/student/board?type=qna',
          icon: MessageSquare,
          description: '학습 관련 질의응답',
        },
        {
          label: '자유게시판',
          path: '/student/board?type=free',
          icon: FileText,
          description: '자유 주제 게시글',
        },
      ],
    },
  ],
  instructor: [
    {
      title: '강의관리',
      icon: BookOpen,
      items: [
        {
          label: '담당과목',
          path: '/instructor/my-courses',
          icon: BookOpen,
          description: '담당 과목 목록 관리',
        },
        {
          label: '강좌 개설',
          path: '/instructor/course-create',
          icon: Layers,
          description: '새 강좌 개설 및 설정',
        },
        {
          label: '과제 관리',
          path: '/instructor/assignments',
          icon: ClipboardList,
          description: '과제 출제 및 채점',
        },
        {
          label: 'Q&A 관리',
          path: '/instructor/qna',
          icon: MessageSquare,
          description: '학생 질문 답변 관리',
        },
        {
          label: '수강생 관리',
          path: '/instructor/students',
          icon: Users,
          description: '수강생 현황 및 관리',
        },
      ],
    },
    {
      title: 'AI 도구',
      icon: Bot,
      items: [
        {
          label: 'AI 콘텐츠 생성',
          path: '/instructor/ai/content',
          icon: Bot,
          description: 'AI 기반 교안 자동 생성',
        },
        {
          label: 'AI 문제 출제',
          path: '/instructor/ai/question',
          icon: Brain,
          description: 'AI 자동 문제 생성',
        },
        {
          label: 'AI 채점 보조',
          path: '/instructor/ai/grading',
          icon: Lightbulb,
          description: 'AI 기반 자동 채점 지원',
        },
      ],
    },
    {
      title: '시험관리',
      icon: ClipboardList,
      items: [
        {
          label: '시험 관리',
          path: '/instructor/exam/manage',
          icon: ClipboardList,
          description: '시험 일정 및 설정',
        },
        {
          label: '문제은행',
          path: '/instructor/exam/questions',
          icon: Database,
          description: '문제 등록 및 관리',
        },
        {
          label: '유형 관리',
          path: '/instructor/exam/categories',
          icon: Layers,
          description: '시험 유형별 분류',
        },
      ],
    },
    {
      title: '콘텐츠',
      icon: Monitor,
      items: [
        {
          label: '전체 콘텐츠',
          path: '/instructor/content/all',
          icon: Monitor,
          description: '강의 영상/자료 관리',
        },
        {
          label: '즐겨찾기',
          path: '/instructor/content/favorites',
          icon: Award,
          description: '즐겨찾기한 콘텐츠',
        },
        {
          label: '통계',
          path: '/instructor/statistics',
          icon: BarChart3,
          description: '수강 통계 및 분석',
        },
      ],
    },
  ],
  admin: [
    {
      title: '사용자관리',
      icon: Users,
      items: [
        {
          label: '사용자 목록',
          path: '/admin/users',
          icon: Users,
          description: '전체 사용자 조회 및 관리',
        },
        {
          label: '권한 관리',
          path: '/admin/users/roles',
          icon: Shield,
          description: '역할 및 권한 설정',
        },
        {
          label: '접속 현황',
          path: '/admin/users/sessions',
          icon: Monitor,
          description: '실시간 접속 모니터링',
        },
      ],
    },
    {
      title: '통계분석',
      icon: BarChart3,
      items: [
        {
          label: '학습 통계',
          path: '/admin/statistics',
          icon: BarChart3,
          description: '학습 현황 대시보드',
        },
        {
          label: '수료 관리',
          path: '/admin/completion',
          icon: Award,
          description: '수료 현황 및 통계',
        },
        {
          label: '부정행위 탐지',
          path: '/admin/antifraud',
          icon: Shield,
          description: 'AI 부정행위 감시',
        },
        {
          label: '데이터 동기화',
          path: '/admin/sync',
          icon: Database,
          description: '학사 데이터 연동 현황',
        },
      ],
    },
    {
      title: '시스템설정',
      icon: Settings,
      items: [
        {
          label: '사이트 설정',
          path: '/admin/settings',
          icon: Settings,
          description: 'LMS 시스템 기본 설정',
        },
        {
          label: '강좌 관리',
          path: '/admin/courses',
          icon: BookOpen,
          description: '전체 강좌 관리',
        },
        {
          label: '콘텐츠 관리',
          path: '/admin/content',
          icon: Layers,
          description: '콘텐츠 등록 및 관리',
        },
        {
          label: '학습 관리',
          path: '/admin/learning',
          icon: PieChart,
          description: '학습 과정 운영 관리',
        },
      ],
    },
    {
      title: '보안',
      icon: Lock,
      items: [
        {
          label: '보안 설정',
          path: '/admin/security',
          icon: Lock,
          description: '보안 정책 설정',
        },
        {
          label: '접근 로그',
          path: '/admin/logs',
          icon: FileText,
          description: '시스템 접근 로그 조회',
        },
        {
          label: '시스템 도구',
          path: '/admin/tools',
          icon: Wrench,
          description: '캐시 관리, 배치 작업 등',
        },
      ],
    },
  ],
};

export default function MegaMenu({ role = 'student' }: MegaMenuProps) {
  const { t } = useTranslation();

  const roleLabels = useMemo<Record<UserRole, string>>(() => ({
    student: t('portal.roleStudent'),
    instructor: t('portal.roleInstructor'),
    admin: t('portal.roleAdmin'),
  }), [t]);
  const [activeSection, setActiveSection] = useState<string | null>(null);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [mobileExpandedSection, setMobileExpandedSection] = useState<
    string | null
  >(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const sections = menuByRole[role];

  // 마우스 진입
  const handleMouseEnter = (title: string) => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    setActiveSection(title);
  };

  // 마우스 이탈 (딜레이)
  const handleMouseLeave = () => {
    timeoutRef.current = setTimeout(() => {
      setActiveSection(null);
    }, 200);
  };

  // 외부 클릭 시 닫기
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setActiveSection(null);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  // 모바일 서브메뉴 토글
  const toggleMobileSection = (title: string) => {
    setMobileExpandedSection((prev) => (prev === title ? null : title));
  };

  return (
    <div ref={menuRef}>
      {/* ─── 데스크톱 메가 메뉴 ─── */}
      <nav className="hidden lg:block bg-white dark:bg-slate-800 border-b border-gray-100 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-center h-11 gap-1">
            {/* 홈 */}
            <a
              href="/"
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
            >
              <Home className="w-4 h-4" />
              {t('megamenu.home')}
            </a>

            <span className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />

            {/* 메뉴 섹션 */}
            {sections.map((section) => {
              const SectionIcon = section.icon;
              const isActive = activeSection === section.title;

              return (
                <div
                  key={section.title}
                  className="relative"
                  onMouseEnter={() => handleMouseEnter(section.title)}
                  onMouseLeave={handleMouseLeave}
                >
                  <button
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                        : 'text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                    }`}
                  >
                    <SectionIcon className="w-4 h-4" />
                    {section.title}
                    <ChevronDown
                      className={`w-3 h-3 transition-transform ${
                        isActive ? 'rotate-180' : ''
                      }`}
                    />
                  </button>

                  {/* 드롭다운 패널 */}
                  {isActive && (
                    <div
                      className="absolute left-0 top-full pt-1 z-50"
                      onMouseEnter={() => handleMouseEnter(section.title)}
                      onMouseLeave={handleMouseLeave}
                    >
                      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-2xl border border-gray-100 dark:border-slate-700 p-4 min-w-[320px]">
                        <div className="flex items-center gap-2 mb-3 px-1">
                          <SectionIcon className="w-4 h-4 text-blue-600" />
                          <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                            {section.title}
                          </h3>
                        </div>
                        <div className="space-y-0.5">
                          {section.items.map((item) => {
                            const ItemIcon = item.icon;
                            return (
                              <a
                                key={item.path}
                                href={item.path}
                                className="flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors group"
                              >
                                <div className="w-8 h-8 rounded-lg bg-gray-100 dark:bg-slate-700 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-colors">
                                  <ItemIcon className="w-4 h-4 text-gray-500 group-hover:text-blue-600 transition-colors" />
                                </div>
                                <div className="flex-1">
                                  <div className="text-sm font-medium text-gray-900 dark:text-white group-hover:text-blue-600 transition-colors">
                                    {item.label}
                                  </div>
                                  {item.description && (
                                    <div className="text-[10px] text-gray-400 mt-0.5">
                                      {item.description}
                                    </div>
                                  )}
                                </div>
                                <ChevronRight className="w-3.5 h-3.5 text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity" />
                              </a>
                            );
                          })}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}

            {/* 역할 뱃지 */}
            <div className="ml-auto">
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 text-[10px] font-bold">
                <Shield className="w-3 h-3" />
                {roleLabels[role]}
              </span>
            </div>
          </div>
        </div>
      </nav>

      {/* ─── 모바일 햄버거 + 드로어 ─── */}
      <div className="lg:hidden">
        {/* 햄버거 버튼 */}
        <button
          onClick={() => setMobileOpen(true)}
          className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
          aria-label={t('megamenu.openMenu')}
        >
          <Menu className="w-5 h-5 text-gray-600 dark:text-slate-300" />
        </button>

        {/* 오버레이 */}
        {mobileOpen && (
          <div
            className="fixed inset-0 bg-black/40 z-50"
            onClick={() => setMobileOpen(false)}
          />
        )}

        {/* 드로어 */}
        <div
          className={`fixed top-0 left-0 z-50 w-80 h-full bg-white dark:bg-slate-800 shadow-2xl transform transition-transform duration-300 ${
            mobileOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
        >
          {/* 드로어 헤더 */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-slate-700">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
                <Bot className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-sm font-bold text-gray-900 dark:text-white">
                  GrowAI LMS
                </h2>
                <span className="text-[10px] text-gray-400">
                  {`${roleLabels[role]} ${t('megamenu.menu')}`}
                </span>
              </div>
            </div>
            <button
              onClick={() => setMobileOpen(false)}
              className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          {/* 드로어 메뉴 목록 */}
          <div className="overflow-y-auto h-[calc(100%-60px)] p-3">
            {/* 홈 링크 */}
            <a
              href="/"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors mb-2"
            >
              <Home className="w-4 h-4" />
              {t('megamenu.goHome')}
            </a>

            <div className="space-y-2">
              {sections.map((section) => {
                const SectionIcon = section.icon;
                const isExpanded = mobileExpandedSection === section.title;

                return (
                  <div key={section.title}>
                    <button
                      onClick={() => toggleMobileSection(section.title)}
                      className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                        isExpanded
                          ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                          : 'text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                      }`}
                    >
                      <SectionIcon className="w-4 h-4 shrink-0" />
                      <span className="flex-1 text-left">{section.title}</span>
                      <ChevronDown
                        className={`w-4 h-4 shrink-0 transition-transform ${
                          isExpanded ? 'rotate-180' : ''
                        }`}
                      />
                    </button>

                    {isExpanded && (
                      <div className="mt-1 ml-3 space-y-0.5">
                        {section.items.map((item) => {
                          const ItemIcon = item.icon;
                          return (
                            <a
                              key={item.path}
                              href={item.path}
                              onClick={() => setMobileOpen(false)}
                              className="flex items-center gap-2.5 pl-4 pr-3 py-2 rounded-lg text-sm text-gray-600 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
                            >
                              <ItemIcon className="w-3.5 h-3.5 shrink-0" />
                              {item.label}
                            </a>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
