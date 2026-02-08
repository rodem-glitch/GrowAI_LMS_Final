// layouts/InstructorLayout.tsx — 교수자 레이아웃 (다국어 지원)
import { useState, useMemo } from 'react';
import { Outlet } from 'react-router-dom';
import Header from '@/components/common/Header';
import Sidebar from '@/components/common/Sidebar';
import UserGuideModal from '@/components/common/UserGuideModal';
import { instructorGuideSteps } from '@/data/guideSteps';
import { useTranslation } from '@/i18n';
import {
  GraduationCap, Compass, BookOpenCheck, ClipboardCheck,
  MessageSquare, PackagePlus, BarChart3, ClipboardList,
  PlusSquare, BarChart2, History, Brain, Video, FileCheck,
  GripVertical, Sparkles, Send, HelpCircle
} from 'lucide-react';

export default function InstructorLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [guideOpen, setGuideOpen] = useState(false);
  const { t } = useTranslation();

  const sections = useMemo(() => [
    { title: t('nav.instructor'), items: [
      { label: t('nav.dashboard'), path: '/instructor', icon: GraduationCap },
      { label: t('nav.courseSearch'), path: '/instructor/course-search', icon: Compass },
      { label: t('nav.myCourses'), path: '/instructor/my-courses', icon: BookOpenCheck },
      { label: t('nav.assignmentManage'), path: '/instructor/assignments', icon: ClipboardCheck },
      { label: t('nav.qnaManage'), path: '/instructor/qna', icon: MessageSquare },
      { label: t('nav.courseCreate'), path: '/instructor/course-create', icon: PackagePlus },
      {
        label: t('nav.contentLibrary'), path: '/instructor/content', icon: BarChart3,
        children: [
          { label: t('nav.allContent'), path: '/instructor/content/all' },
          { label: t('nav.favorites'), path: '/instructor/content/favorites' },
        ]
      },
      {
        label: t('nav.examManage'), path: '/instructor/exam', icon: ClipboardList,
        children: [
          { label: t('nav.questionCategory'), path: '/instructor/exam/categories' },
          { label: t('nav.questionBank'), path: '/instructor/exam/questions' },
          { label: t('nav.examManage'), path: '/instructor/exam/manage' },
        ]
      },
      { label: t('nav.subjectCreate'), path: '/instructor/subject-create', icon: PlusSquare },
      { label: t('nav.statistics'), path: '/instructor/statistics', icon: BarChart2 },
    ]},
    { title: t('nav.liveLecture'), items: [
      { label: t('nav.liveLectureMenu'), path: '/instructor/live-lecture', icon: Video },
    ]},
    { title: t('nav.aiTeachTool'), items: [
      { label: t('nav.pastLectures'), path: '/instructor/past-lectures', icon: History },
      { label: t('nav.aiSyllabus'), path: '/instructor/ai-syllabus', icon: Brain },
      { label: t('nav.videoRecommend'), path: '/instructor/video-recommend', icon: Video },
      { label: t('nav.videoSummary'), path: '/instructor/video-summary', icon: FileCheck },
      { label: t('nav.curriculumBuilder'), path: '/instructor/curriculum-builder', icon: GripVertical },
      { label: t('nav.aiQuiz'), path: '/instructor/ai-quiz', icon: Sparkles },
      { label: t('nav.syllabusSubmit'), path: '/instructor/syllabus-submit', icon: Send },
    ]},
  ], [t]);

  return (
    <div className="min-h-screen flex flex-col bg-surface-muted dark:bg-surface-dark">
      <Header variant="instructor" onToggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
      <div className="flex flex-1">
        <Sidebar sections={sections} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="flex-1 page-container"><Outlet /></main>
      </div>

      {/* 사용 가이드 플로팅 버튼 */}
      <button
        onClick={() => setGuideOpen(true)}
        className="fixed bottom-6 right-6 z-40 flex items-center gap-2 px-4 py-2.5 bg-emerald-600 text-white text-sm font-medium rounded-full shadow-lg hover:bg-emerald-700 hover:shadow-xl transition-all hover:scale-105"
      >
        <HelpCircle className="w-4 h-4" />
        사용 가이드
      </button>

      <UserGuideModal
        isOpen={guideOpen}
        onClose={() => setGuideOpen(false)}
        title="교수자 사용 가이드"
        subtitle="GrowAI LMS 교수자 포털 사용법을 안내합니다"
        steps={instructorGuideSteps}
        accentColor="emerald"
      />
    </div>
  );
}
