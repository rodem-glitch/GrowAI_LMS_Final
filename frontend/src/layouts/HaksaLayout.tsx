// layouts/HaksaLayout.tsx — 학사정보 연동 레이아웃 (다국어 지원)
import { useState, useMemo } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import { useTranslation } from '@/i18n';
import {
  LayoutDashboard, Users, Award, ClipboardList,
  Calendar, RefreshCw, FileText
} from 'lucide-react';

export default function HaksaLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { t } = useTranslation();

  const sections = useMemo(() => [
    { title: t('nav.haksaIntegration'), items: [
      { label: t('nav.dashboard'), path: '/haksa', icon: LayoutDashboard },
      { label: t('nav.studentRecords'), path: '/haksa/student-records', icon: Users },
      { label: t('nav.gradeManage'), path: '/haksa/grades', icon: Award },
      { label: t('nav.enrollmentSync'), path: '/haksa/enrollment', icon: ClipboardList },
      { label: t('nav.academicCalendar'), path: '/haksa/calendar', icon: Calendar },
      { label: t('nav.dataSync'), path: '/haksa/sync', icon: RefreshCw },
      { label: t('nav.syncLog'), path: '/haksa/logs', icon: FileText },
    ]}
  ], [t]);

  return (
    <div className="min-h-screen flex flex-col bg-surface-muted dark:bg-surface-dark">
      <Header variant="admin" onToggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex flex-1">
        <Sidebar sections={sections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 page-container"><Outlet /></main>
      </div>
    </div>
  );
}
