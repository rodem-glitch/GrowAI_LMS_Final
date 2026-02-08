import { useState } from 'react';
import { BookOpen, Users, Award, TrendingUp, Bot, ChevronRight, Bell } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';
import { Link } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';
import { useQuery } from '@tanstack/react-query';
import { dataApi } from '@/services/api';
import { useTranslation } from '@/i18n';

const myCourses = [
  { id: 1, title: 'Python 프로그래밍 기초', instructor: '김교수', progress: 65, campus: '서울강서' },
  { id: 2, title: '데이터베이스 설계', instructor: '김교수', progress: 30, campus: '서울강서' },
  { id: 3, title: '머신러닝 입문', instructor: '이교수', progress: 80, campus: '인천' },
];

const notices = [
  { id: 1, title: '2026학년도 1학기 수강신청 안내', date: '2026-02-08', pinned: true },
  { id: 2, title: 'GrowAI LMS 시스템 점검 안내 (2/10)', date: '2026-02-07' },
  { id: 3, title: '온라인 강의 출석 인정 기준 변경', date: '2026-02-05' },
];

export default function MainPage() {
  const { t } = useTranslation();
  const { user } = useAuthStore();

  const { data: dbData } = useQuery({
    queryKey: ['student-dashboard'],
    queryFn: () => dataApi.getStudentDashboard(1).catch(() => null),
    staleTime: 60000,
    retry: false,
  });

  return (
    <div className="space-y-6">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-primary-600 via-primary-500 to-secondary-500 p-6 text-white">
        <div className="relative z-10">
          <h1 className="text-xl font-bold">{t('student.mainTitle')}</h1>
          <p className="text-primary-100 mt-1 text-sm">{t('student.mainDesc')}</p>
          <div className="flex gap-3 mt-4">
            <Link to="/student/ai-chat" className="btn bg-white/20 hover:bg-white/30 text-white text-xs backdrop-blur-sm">
              <Bot className="w-4 h-4" /> AI 학습 도우미
            </Link>
            <Link to="/student/courses" className="btn bg-white/20 hover:bg-white/30 text-white text-xs backdrop-blur-sm">
              <BookOpen className="w-4 h-4" /> 강좌 둘러보기
            </Link>
          </div>
        </div>
      </div>

      {/* DB I/F: enrollments={dbData?.enrollments} courses={dbData?.courses} */}

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={BookOpen} label="수강중 강좌" value="3" />
        <StatCard icon={TrendingUp} label="평균 진도율" value="58%" change="+5%" trend="up" />
        <StatCard icon={Award} label="수료 강좌" value="12" />
        <StatCard icon={Users} label="출석률" value="92%" change="+2%" trend="up" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* My Courses */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">내 수강 강좌</h2>
            <Link to="/student/mypage/courses" className="text-xs text-primary-600 hover:underline flex items-center gap-1">{t('common.viewAll')} <ChevronRight className="w-3 h-3" /></Link>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {myCourses.map((c) => (
              <Link key={c.id} to={`/student/classroom/${c.id}`} className="card p-4 hover:shadow-card-hover transition-shadow">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-8 h-8 rounded-lg bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center">
                    <BookOpen className="w-4 h-4 text-primary-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-gray-900 dark:text-white text-truncate">{c.title}</div>
                    <div className="text-[10px] text-gray-400">{c.instructor} · {c.campus}</div>
                  </div>
                </div>
                <ProgressBar value={c.progress} size="sm" label="진도율" />
              </Link>
            ))}
          </div>
        </div>

        {/* Notices + AI */}
        <div className="space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">공지사항</h2>
          <div className="card p-0 divide-y divide-gray-50 dark:divide-slate-800">
            {notices.map((n) => (
              <Link key={n.id} to={`/student/board/${n.id}`} className="flex items-center gap-2 px-4 py-3 hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors">
                {n.pinned && <Bell className="w-3 h-3 text-danger-500 shrink-0" />}
                <span className="text-sm text-truncate flex-1">{n.title}</span>
                <span className="text-[10px] text-gray-400 shrink-0">{n.date}</span>
              </Link>
            ))}
          </div>

          <div className="card bg-gradient-to-br from-secondary-50 to-primary-50 dark:from-secondary-900/20 dark:to-primary-900/20 border-secondary-100 dark:border-secondary-800">
            <div className="flex items-center gap-2 mb-2">
              <Bot className="w-5 h-5 text-secondary-600" />
              <span className="text-sm font-semibold text-secondary-700 dark:text-secondary-400">AI 추천</span>
            </div>
            <p className="text-xs text-gray-600 dark:text-slate-400">학습 이력을 분석하여 맞춤형 강좌를 추천합니다.</p>
            <Link to="/student/ai-chat" className="btn-sm btn bg-secondary-100 text-secondary-700 hover:bg-secondary-200 mt-3 text-xs dark:bg-secondary-900/50 dark:text-secondary-400">추천 받기</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
