// pages/instructor/DashboardPage.tsx — 교수자 대시보드
import { Link } from 'react-router-dom';
import {
  BookOpen, Users, ClipboardCheck, BarChart3,
  TrendingUp, ArrowRight, AlertCircle, CheckCircle2,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

const stats = [
  { icon: BookOpen, label: '담당 강좌', value: 3, iconColor: 'text-primary' },
  { icon: Users, label: '총 수강생', value: 126, change: '+8', trend: 'up' as const, iconColor: 'text-secondary' },
  { icon: ClipboardCheck, label: '미채점 과제', value: 14, iconColor: 'text-warning' },
  { icon: TrendingUp, label: '평균 출석률', value: '92%', iconColor: 'text-success' },
];

const myCourses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', students: 45, avgProgress: 72, pendingTasks: 5 },
  { code: 'CS201', name: '데이터베이스 설계', students: 38, avgProgress: 58, pendingTasks: 8 },
  { code: 'AI301', name: 'AI 머신러닝 입문', students: 43, avgProgress: 41, pendingTasks: 1 },
];

const recentAlerts = [
  { type: 'warning', text: 'CS201 과제 마감 3일 전 — 미제출 학생 12명', time: '1시간 전' },
  { type: 'info', text: 'AI301 3주차 출석률 85% (전주 대비 -3%)', time: '3시간 전' },
  { type: 'success', text: 'CS101 중간고사 채점 완료', time: '1일 전' },
];

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">교수자 대시보드</h1>
        <p className="text-sm text-content-secondary mt-1">강좌 운영 현황 한눈에 보기</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s) => <StatCard key={s.label} {...s} />)}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* My Courses */}
        <section className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">내 강좌</h2>
            <Link to="/instructor/courses" className="text-sm text-primary hover:underline flex items-center gap-1">
              전체보기 <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="space-y-3">
            {myCourses.map((c) => (
              <div key={c.code} className="card-hover">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <h3 className="text-sm font-semibold text-gray-800 dark:text-white">{c.name}</h3>
                    <p className="text-[10px] text-gray-400 mt-0.5">{c.code} | 수강생 {c.students}명</p>
                  </div>
                  {c.pendingTasks > 0 && (
                    <span className="badge-sm badge-warning">{c.pendingTasks}건 미채점</span>
                  )}
                </div>
                <ProgressBar value={c.avgProgress} label="평균 진도율" size="sm" />
              </div>
            ))}
          </div>
        </section>

        {/* Alerts */}
        <section className="space-y-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">알림</h2>
          <div className="card space-y-3">
            {recentAlerts.map((a, i) => (
              <div key={i} className={`alert ${
                a.type === 'warning' ? 'alert-warning' : a.type === 'success' ? 'alert-success' : 'alert-info'
              }`}>
                {a.type === 'warning' ? <AlertCircle className="w-4 h-4 shrink-0" /> :
                 a.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> :
                 <BarChart3 className="w-4 h-4 shrink-0" />}
                <div>
                  <p className="text-xs">{a.text}</p>
                  <p className="text-[10px] opacity-70 mt-0.5">{a.time}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
