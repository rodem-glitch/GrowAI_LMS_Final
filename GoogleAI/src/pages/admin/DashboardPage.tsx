// pages/admin/DashboardPage.tsx — 관리자 대시보드
import {
  Users, BookOpen, GraduationCap, BarChart3,
  TrendingUp, Activity, Shield, Database,
  RefreshCw, AlertCircle, CheckCircle2,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

const stats = [
  { icon: Users, label: '전체 회원', value: '3,842', change: '+156', trend: 'up' as const, iconColor: 'text-primary' },
  { icon: BookOpen, label: '운영 과정', value: 48, change: '+5', trend: 'up' as const, iconColor: 'text-secondary' },
  { icon: GraduationCap, label: '수료율', value: '87%', change: '+2.3%', trend: 'up' as const, iconColor: 'text-success' },
  { icon: Activity, label: '오늘 접속', value: 512, iconColor: 'text-info' },
];

const systemStatus = [
  { name: 'LMS 서버', status: 'up', uptime: '99.9%' },
  { name: 'API 서버', status: 'up', uptime: '99.8%' },
  { name: 'DB 서버', status: 'up', uptime: '100%' },
  { name: 'AI 서비스', status: 'up', uptime: '98.5%' },
  { name: 'Qdrant 벡터DB', status: 'up', uptime: '99.2%' },
];

const recentSync = [
  { type: '회원 동기화', time: '14:30', count: 3842, status: 'success' },
  { type: '강좌 동기화', time: '14:00', count: 48, status: 'success' },
  { type: '성적 동기화', time: '13:30', count: 1256, status: 'success' },
];

const topCourses = [
  { name: 'AI 머신러닝 입문', students: 52, completion: 85 },
  { name: 'Python 프로그래밍', students: 45, completion: 78 },
  { name: '웹 프론트엔드', students: 41, completion: 92 },
  { name: '데이터베이스 설계', students: 38, completion: 65 },
  { name: '정보보안 개론', students: 30, completion: 72 },
];

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">관리자 대시보드</h1>
        <p className="text-sm text-content-secondary mt-1">시스템 운영 현황 및 통계</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s) => <StatCard key={s.label} {...s} />)}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Top Courses */}
        <section className="lg:col-span-2 space-y-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">인기 강좌 TOP 5</h2>
          <div className="card space-y-4">
            {topCourses.map((c, i) => (
              <div key={i} className="flex items-center gap-4">
                <span className="w-6 h-6 rounded-full bg-primary-50 text-primary-700 flex items-center justify-center text-xs font-bold shrink-0">{i + 1}</span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium text-gray-800 dark:text-white truncate">{c.name}</span>
                    <span className="text-[10px] text-gray-400 shrink-0">{c.students}명</span>
                  </div>
                  <ProgressBar value={c.completion} showPercent={false} size="sm" />
                </div>
                <span className="text-xs font-medium text-gray-700 dark:text-slate-300 w-10 text-right">{c.completion}%</span>
              </div>
            ))}
          </div>

          {/* Sync Status */}
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">학사 연동 현황</h2>
          <div className="table-container">
            <table className="w-full">
              <thead className="table-head">
                <tr>
                  <th className="table-th">연동 유형</th>
                  <th className="table-th-center">시각</th>
                  <th className="table-th-center">건수</th>
                  <th className="table-th-center">상태</th>
                </tr>
              </thead>
              <tbody>
                {recentSync.map((s, i) => (
                  <tr key={i} className="table-row">
                    <td className="table-td font-medium">{s.type}</td>
                    <td className="table-td-center">{s.time}</td>
                    <td className="table-td-center">{s.count.toLocaleString()}</td>
                    <td className="table-td-center">
                      <span className="badge-sm badge-success"><CheckCircle2 className="w-3 h-3" /> 성공</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* System Status */}
        <section className="space-y-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">시스템 상태</h2>
          <div className="card space-y-3">
            {systemStatus.map((s) => (
              <div key={s.name} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="status-dot status-completed" />
                  <span className="text-sm text-gray-700 dark:text-slate-300">{s.name}</span>
                </div>
                <span className="text-xs text-success-600 font-medium">{s.uptime}</span>
              </div>
            ))}
          </div>

          <div className="card space-y-3">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">빠른 작업</h3>
            <div className="space-y-2">
              <button className="btn btn-sm w-full justify-start bg-blue-50 text-blue-700 hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400">
                <RefreshCw className="w-3 h-3" /> 회원 수동 동기화
              </button>
              <button className="btn btn-sm w-full justify-start bg-purple-50 text-purple-700 hover:bg-purple-100 dark:bg-purple-900/20 dark:text-purple-400">
                <Database className="w-3 h-3" /> 강좌 수동 동기화
              </button>
              <button className="btn btn-sm w-full justify-start bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-900/20 dark:text-emerald-400">
                <Shield className="w-3 h-3" /> 보안 점검
              </button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
