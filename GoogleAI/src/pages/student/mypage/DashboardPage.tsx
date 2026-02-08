// pages/student/mypage/DashboardPage.tsx — 마이페이지 대시보드
import { Link } from 'react-router-dom';
import {
  BookOpen, Award, Clock, TrendingUp,
  ArrowRight, Calendar, FileText, MessageSquare,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

const stats = [
  { icon: BookOpen, label: '수강중', value: 5, iconColor: 'text-primary' },
  { icon: Award, label: '수료 완료', value: 12, iconColor: 'text-success' },
  { icon: Clock, label: '총 학습시간', value: '156h', iconColor: 'text-secondary' },
  { icon: TrendingUp, label: '평균 성적', value: 'A', iconColor: 'text-amber-500' },
];

const recentCourses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', progress: 85, lastAccess: '2시간 전' },
  { code: 'CS201', name: '데이터베이스 설계', progress: 62, lastAccess: '1일 전' },
  { code: 'AI301', name: 'AI 머신러닝 입문', progress: 45, lastAccess: '2일 전' },
];

const activities = [
  { type: 'video', text: 'Python 3주차 강의 수강 완료', time: '2시간 전' },
  { type: 'assignment', text: 'DB 설계 과제 제출', time: '1일 전' },
  { type: 'exam', text: 'AI 입문 퀴즈 응시 (85점)', time: '2일 전' },
  { type: 'forum', text: '웹개발 토론방 댓글 작성', time: '3일 전' },
];

export default function DashboardPage() {
  return (
    <div className="page-container space-y-6">
      {/* Title */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">마이페이지</h1>
        <p className="text-sm text-content-secondary mt-1">학습 현황 및 개인 정보 관리</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s) => (
          <StatCard key={s.label} {...s} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Courses (2/3) */}
        <section className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">최근 학습</h2>
            <Link to="/mypage/courses" className="text-sm text-primary hover:underline flex items-center gap-1">
              전체보기 <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="space-y-3">
            {recentCourses.map((c) => (
              <Link key={c.code} to={`/classroom/${c.code}`} className="card-compact flex items-center gap-4 group">
                <div className="w-12 h-12 rounded-xl bg-primary-50 flex items-center justify-center">
                  <BookOpen className="w-5 h-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-semibold text-gray-800 dark:text-white group-hover:text-primary transition-colors truncate">{c.name}</h3>
                  <p className="text-[10px] text-gray-400 mt-0.5">마지막 학습: {c.lastAccess}</p>
                </div>
                <div className="w-24 shrink-0">
                  <ProgressBar value={c.progress} size="sm" />
                </div>
              </Link>
            ))}
          </div>

          {/* Quick Links */}
          <div className="grid grid-cols-3 gap-3">
            <Link to="/mypage/certificates" className="card-compact text-center group">
              <Award className="w-5 h-5 text-amber-500 mx-auto mb-1" />
              <span className="text-xs text-gray-600 dark:text-slate-400">수료증</span>
            </Link>
            <Link to="/board" className="card-compact text-center group">
              <MessageSquare className="w-5 h-5 text-secondary mx-auto mb-1" />
              <span className="text-xs text-gray-600 dark:text-slate-400">1:1 문의</span>
            </Link>
            <Link to="#" className="card-compact text-center group">
              <Calendar className="w-5 h-5 text-info mx-auto mb-1" />
              <span className="text-xs text-gray-600 dark:text-slate-400">학습 일정</span>
            </Link>
          </div>
        </section>

        {/* Activity (1/3) */}
        <section className="space-y-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">최근 활동</h2>
          <div className="card space-y-4">
            {activities.map((a, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="w-2 h-2 rounded-full bg-primary mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs text-gray-700 dark:text-slate-300">{a.text}</p>
                  <p className="text-[10px] text-gray-400 mt-0.5">{a.time}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
