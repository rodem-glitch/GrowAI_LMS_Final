// layouts/StudentLayout.tsx — 학생 레이아웃 (다국어 지원)
import { useState, useMemo } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import Footer from '@/components/common/Footer';
import UserGuideModal from '@/components/common/UserGuideModal';
import { studentGuideSteps } from '@/data/guideSteps';
import { useTranslation } from '@/i18n';
import {
  Home, BookOpen, GraduationCap, User,
  Award, MessageSquare, Bot, Tags, Briefcase,
  Target, Lightbulb, FileEdit, HelpCircle
} from 'lucide-react';

export default function StudentLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [guideOpen, setGuideOpen] = useState(false);
  const { t } = useTranslation();

  const sections = useMemo(() => [
    { title: t('nav.learning'), items: [
      { label: t('nav.main'), path: '/student', icon: Home },
      { label: t('nav.browseCourses'), path: '/student/courses', icon: BookOpen },
    ]},
    { title: t('nav.myLearning'), items: [
      { label: t('nav.myPage'), path: '/student/mypage', icon: User },
      { label: t('nav.courseList'), path: '/student/mypage/courses', icon: GraduationCap },
      { label: t('nav.certificate'), path: '/student/mypage/certificates', icon: Award },
      { label: t('nav.studentProfile'), path: '/student/profile', icon: User },
    ]},
    { title: t('nav.aiService'), items: [
      { label: t('nav.aiLearningHelper'), path: '/student/ai-chat', icon: Bot },
      { label: t('nav.aiCareerChat'), path: '/student/career-chat', icon: Bot },
      { label: t('nav.aiCoverLetter'), path: '/student/cover-letter', icon: FileEdit },
    ]},
    { title: t('nav.competencyCareer'), items: [
      { label: t('nav.competencyTag'), path: '/student/competency', icon: Tags },
      { label: t('nav.jobMatch'), path: '/student/jobs', icon: Briefcase },
      { label: t('nav.gapAnalysis'), path: '/student/gap-analysis', icon: Target },
      { label: t('nav.contentRecommend'), path: '/student/content-recommend', icon: Lightbulb },
    ]},
    { title: t('nav.community'), items: [
      { label: t('nav.board'), path: '/student/board', icon: MessageSquare },
    ]},
  ], [t]);

  return (
    <div className="min-h-screen flex flex-col bg-surface-muted dark:bg-surface-dark">
      <Header variant="student" onToggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex flex-1">
        <Sidebar sections={sections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 page-container"><Outlet /></main>
      </div>
      <Footer />

      {/* 사용 가이드 플로팅 버튼 */}
      <button
        onClick={() => setGuideOpen(true)}
        className="fixed bottom-6 right-6 z-40 flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white text-sm font-medium rounded-full shadow-lg hover:bg-blue-700 hover:shadow-xl transition-all hover:scale-105"
      >
        <HelpCircle className="w-4 h-4" />
        사용 가이드
      </button>

      <UserGuideModal
        isOpen={guideOpen}
        onClose={() => setGuideOpen(false)}
        title="학생 사용 가이드"
        subtitle="GrowAI LMS 학생 포털 사용법을 안내합니다"
        steps={studentGuideSteps}
        accentColor="blue"
      />
    </div>
  );
}
