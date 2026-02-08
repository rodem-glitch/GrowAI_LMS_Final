// layouts/AdminLayout.tsx — 관리자 레이아웃 (다국어 지원)
import { useState, useMemo } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import UserGuideModal from '@/components/common/UserGuideModal';
import { adminGuideSteps } from '@/data/guideSteps';
import { useTranslation } from '@/i18n';
import {
  LayoutDashboard, BookOpen, GraduationCap, Award, Users,
  FileText, BarChart3, Settings, RefreshCw, Shield,
  Activity, TrendingDown, Target, Briefcase, UserCog,
  Image, FileSearch, Lock, HelpCircle
} from 'lucide-react';

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [guideOpen, setGuideOpen] = useState(false);
  const { t } = useTranslation();

  const sections = useMemo(() => [
    { title: t('nav.dashboard'), items: [
      { label: t('nav.dashboard'), path: '/admin', icon: LayoutDashboard },
      { label: t('nav.operationsMonitor'), path: '/admin/monitoring', icon: Activity },
    ]},
    { title: t('nav.learningManage'), items: [
      { label: t('nav.courseManage'), path: '/admin/courses', icon: BookOpen },
      { label: t('nav.learningStatus'), path: '/admin/learning', icon: GraduationCap },
      { label: t('nav.completionManage'), path: '/admin/completion', icon: Award },
    ]},
    { title: t('nav.memberManage'), items: [
      { label: t('nav.userList'), path: '/admin/users', icon: Users },
      { label: t('nav.userControl'), path: '/admin/user-control', icon: UserCog },
    ]},
    { title: t('nav.contentCms'), items: [
      { label: t('nav.contentManage'), path: '/admin/content', icon: FileText },
      { label: t('nav.bannerManage'), path: '/admin/banners', icon: Image },
    ]},
    { title: t('nav.statsAnalysis'), items: [
      { label: t('nav.statistics'), path: '/admin/statistics', icon: BarChart3 },
      { label: t('nav.funnelAnalysis'), path: '/admin/funnel', icon: TrendingDown },
      { label: t('nav.competencyAchieve'), path: '/admin/competency-achievement', icon: Target },
      { label: t('nav.employmentMatch'), path: '/admin/employment-match', icon: Briefcase },
    ]},
    { title: t('nav.systemOps'), items: [
      { label: t('nav.haksaSync'), path: '/admin/sync', icon: RefreshCw },
      { label: t('nav.antifraud'), path: '/admin/antifraud', icon: Shield },
      { label: t('nav.siteSettings'), path: '/admin/settings', icon: Settings },
    ]},
    { title: t('nav.securityAudit'), items: [
      { label: t('nav.accessLog'), path: '/admin/access-logs', icon: FileSearch },
      { label: t('nav.privacyLog'), path: '/admin/privacy-logs', icon: Lock },
    ]},
  ], [t]);

  return (
    <div className="min-h-screen flex flex-col bg-surface-muted dark:bg-surface-dark">
      <Header variant="admin" onToggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex flex-1">
        <Sidebar sections={sections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 page-container"><Outlet /></main>
      </div>

      {/* 사용 가이드 플로팅 버튼 */}
      <button
        onClick={() => setGuideOpen(true)}
        className="fixed bottom-6 right-6 z-40 flex items-center gap-2 px-4 py-2.5 bg-purple-600 text-white text-sm font-medium rounded-full shadow-lg hover:bg-purple-700 hover:shadow-xl transition-all hover:scale-105"
      >
        <HelpCircle className="w-4 h-4" />
        사용 가이드
      </button>

      <UserGuideModal
        isOpen={guideOpen}
        onClose={() => setGuideOpen(false)}
        title="관리자 사용 가이드"
        subtitle="GrowAI LMS 관리자 포털 사용법을 안내합니다"
        steps={adminGuideSteps}
        accentColor="purple"
      />
    </div>
  );
}
