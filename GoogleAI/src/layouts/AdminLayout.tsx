// layouts/AdminLayout.tsx — 관리자 레이아웃 (헤더 + 사이드바 + 콘텐츠)
import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import type { SidebarSection } from '@/components/common/Sidebar';
import {
  LayoutDashboard, BookOpen, Users, GraduationCap,
  FileText, BarChart3, Settings, Video, ClipboardCheck,
  Award, MessageSquare,
} from 'lucide-react';

const adminSections: SidebarSection[] = [
  {
    title: '대시보드',
    items: [
      { label: '홈', path: '/admin', icon: LayoutDashboard },
    ],
  },
  {
    title: '학습 관리',
    items: [
      { label: '과정 관리', path: '/admin/courses', icon: BookOpen },
      { label: '학습 관리', path: '/admin/learning', icon: GraduationCap },
      { label: '수료 관리', path: '/admin/completion', icon: Award },
    ],
  },
  {
    title: '회원 관리',
    items: [
      { label: '회원 목록', path: '/admin/users', icon: Users },
    ],
  },
  {
    title: '콘텐츠',
    items: [
      { label: '콘텐츠 관리', path: '/admin/content', icon: FileText },
    ],
  },
  {
    title: '분석',
    items: [
      { label: '통계', path: '/admin/statistics', icon: BarChart3 },
    ],
  },
  {
    title: '시스템',
    items: [
      { label: '사이트 설정', path: '/admin/settings', icon: Settings },
    ],
  },
];

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-surface-muted dark:bg-slate-950">
      <Header variant="admin" onMenuToggle={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex">
        <Sidebar sections={adminSections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 min-w-0 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
