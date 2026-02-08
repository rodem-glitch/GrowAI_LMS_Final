// pages/admin/statistics/StatisticsPage.tsx — 통계 페이지
import { useState } from 'react';
import {
  BarChart3, Users, BookOpen, TrendingUp,
  Calendar, Download, Activity,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

const periods = ['오늘', '이번주', '이번달', '이번학기'];

const accessStats = [
  { date: '02/02', count: 312 },
  { date: '02/03', count: 425 },
  { date: '02/04', count: 389 },
  { date: '02/05', count: 502 },
  { date: '02/06', count: 478 },
  { date: '02/07', count: 534 },
  { date: '02/08', count: 512 },
];

const campusStats = [
  { campus: '서울강서', students: 1240, active: 95 },
  { campus: '인천', students: 890, active: 88 },
  { campus: '대전', students: 650, active: 82 },
  { campus: '광주', students: 520, active: 79 },
  { campus: '부산', students: 542, active: 91 },
];

const deptStats = [
  { dept: '컴퓨터공학과', enrolled: 320, completion: 85 },
  { dept: '전자공학과', enrolled: 280, completion: 78 },
  { dept: '기계공학과', enrolled: 250, completion: 72 },
  { dept: '데이터과학과', enrolled: 190, completion: 88 },
  { dept: '디자인학과', enrolled: 160, completion: 81 },
];

export default function StatisticsPage() {
  const [period, setPeriod] = useState('이번달');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">통계</h1>
          <p className="text-sm text-content-secondary mt-1">접속 통계, 학습 통계, 캠퍼스별 현황</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="filter-bar">
            {periods.map((p) => (
              <button key={p} onClick={() => setPeriod(p)} className={`filter-chip ${period === p ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{p}</button>
            ))}
          </div>
          <button className="btn-secondary"><Download className="w-4 h-4" /> 리포트</button>
        </div>
      </div>

      {/* Overview */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Users} label="전체 회원" value="3,842" change="+156" trend="up" />
        <StatCard icon={Activity} label="일평균 접속" value="450" change="+12%" trend="up" />
        <StatCard icon={BookOpen} label="수강 등록" value="1,256" />
        <StatCard icon={TrendingUp} label="평균 수료율" value="87%" change="+2.3%" trend="up" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Access Chart (placeholder) */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">일별 접속자 추이</h2>
          <div className="space-y-2">
            {accessStats.map((d) => (
              <div key={d.date} className="flex items-center gap-3">
                <span className="text-xs text-gray-500 w-10">{d.date}</span>
                <div className="flex-1 h-6 bg-gray-100 dark:bg-slate-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-primary-500 to-secondary-500 rounded-full transition-all"
                    style={{ width: `${(d.count / 600) * 100}%` }}
                  />
                </div>
                <span className="text-xs font-medium text-gray-700 dark:text-slate-300 w-10 text-right">{d.count}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Campus Stats */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">캠퍼스별 현황</h2>
          <div className="table-container">
            <table className="w-full">
              <thead className="table-head">
                <tr>
                  <th className="table-th">캠퍼스</th>
                  <th className="table-th-center">수강생</th>
                  <th className="table-th-center">활동률</th>
                </tr>
              </thead>
              <tbody>
                {campusStats.map((c) => (
                  <tr key={c.campus} className="table-row">
                    <td className="table-td font-medium">{c.campus}</td>
                    <td className="table-td-center">{c.students.toLocaleString()}</td>
                    <td className="table-td-center">
                      <span className={c.active >= 90 ? 'text-success-600 font-medium' : 'text-gray-600'}>{c.active}%</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>

      {/* Dept Stats */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">학과별 수료율</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          {deptStats.map((d) => (
            <div key={d.dept} className="card-muted p-4 text-center">
              <div className="text-xs text-gray-500 mb-2">{d.dept}</div>
              <div className="text-lg font-bold text-gray-900 dark:text-white mb-1">{d.completion}%</div>
              <ProgressBar value={d.completion} showPercent={false} size="sm" variant={d.completion >= 80 ? 'success' : 'default'} />
              <div className="text-[10px] text-gray-400 mt-1">{d.enrolled}명 수강</div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
