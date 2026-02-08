import { useState } from 'react';
import { Users, Activity, BookOpen, TrendingUp, Download } from 'lucide-react';
import { useTranslation } from '@/i18n';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

const periods = ['오늘', '이번주', '이번달', '이번학기'];
const campusStats = [
  { campus: '서울강서', students: 1240, active: 95 },
  { campus: '인천', students: 890, active: 88 },
  { campus: '대전', students: 650, active: 82 },
  { campus: '광주', students: 520, active: 79 },
  { campus: '부산', students: 542, active: 91 },
];

export default function StatisticsPage() {
  const { t } = useTranslation();
  const [period, setPeriod] = useState('이번달');
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.statisticsTitle')}</h1>
        <div className="flex items-center gap-2">
          <div className="filter-bar">{periods.map(p => <button key={p} onClick={() => setPeriod(p)} className={`filter-chip ${period === p ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{p}</button>)}</div>
          <button className="btn-secondary"><Download className="w-4 h-4" /> 리포트</button>
        </div>
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Users} label="전체 회원" value="3,842" change="+156" trend="up" />
        <StatCard icon={Activity} label="일평균 접속" value="450" change="+12%" trend="up" />
        <StatCard icon={BookOpen} label="수강 등록" value="1,256" />
        <StatCard icon={TrendingUp} label="평균 수료율" value="87%" change="+2.3%" trend="up" />
      </div>
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">캠퍼스별 현황</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head"><tr><th className="table-th">캠퍼스</th><th className="table-th-center">{t('common.people')}</th><th className="table-th-center">{t('common.status')}</th></tr></thead>
            <tbody>
              {campusStats.map(c => (
                <tr key={c.campus} className="table-row">
                  <td className="table-td font-medium">{c.campus}</td>
                  <td className="table-td-center">{c.students.toLocaleString()}</td>
                  <td className="table-td-center"><span className={c.active >= 90 ? 'text-success-600 font-medium' : 'text-gray-600'}>{c.active}%</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
