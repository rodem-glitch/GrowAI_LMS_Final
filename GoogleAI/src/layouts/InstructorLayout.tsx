// layouts/InstructorLayout.tsx — 교수자 레이아웃 (헤더 + 사이드바 + 콘텐츠)
import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import type { SidebarSection } from '@/components/common/Sidebar';
import {
  LayoutDashboard, BookOpen, Users, ClipboardCheck,
  BarChart3, MessageSquare,
} from 'lucide-react';

const instructorSections: SidebarSection[] = [
  {
    title: '대시보드',
    items: [
      { label: '홈', path: '/instructor', icon: LayoutDashboard },
    ],
  },
  {
    title: '강좌 관리',
    items: [
      { label: '내 강좌', path: '/instructor/courses', icon: BookOpen },
      { label: '수강생 관리', path: '/instructor/students', icon: Users },
    ],
  },
];

export default function InstructorLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-surface-muted dark:bg-slate-950">
      <Header variant="instructor" onMenuToggle={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex">
        <Sidebar sections={instructorSections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 min-w-0 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
