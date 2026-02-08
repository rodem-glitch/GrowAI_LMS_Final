// layouts/StudentLayout.tsx — 학생 레이아웃 (헤더 + 콘텐츠 + 푸터)
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Footer from '@/components/common/Footer';

export default function StudentLayout() {
  return (
    <div className="min-h-screen flex flex-col bg-page-gradient dark:bg-slate-950">
      <Header variant="student" />
      <main className="flex-1">
        <Outlet />
      </main>
      <Footer />
    </div>
  );
}
