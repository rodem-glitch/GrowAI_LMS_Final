import { BookOpen, Award, TrendingUp, Calendar } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';
import { Link } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';
import { useTranslation } from '@/i18n';

export default function DashboardPage() {
  const { t } = useTranslation();
  const { user } = useAuthStore();
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold">{t('student.dashboardTitle')}</h1>
      <div className="card p-5 flex items-center gap-4">
        <div className="w-14 h-14 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center">
          <span className="text-xl font-bold text-primary-600">{user?.name?.[0] || 'U'}</span>
        </div>
        <div>
          <div className="text-base font-semibold">{user?.name}</div>
          <div className="text-xs text-gray-500">{user?.campus} · {user?.department}</div>
          <div className="text-[10px] text-gray-400 mt-0.5">{user?.userId}</div>
        </div>
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={BookOpen} label="수강중" value="3" />
        <StatCard icon={Award} label="수료" value="12" />
        <StatCard icon={TrendingUp} label="평균 진도율" value="58%" />
        <StatCard icon={Calendar} label="출석률" value="92%" />
      </div>
      <div className="card p-5 space-y-4">
        <h2 className="text-sm font-semibold">수강중인 강좌</h2>
        {[{ title: 'Python 프로그래밍 기초', progress: 65 },{ title: '데이터베이스 설계', progress: 30 },{ title: '머신러닝 입문', progress: 80 }].map(c => (
          <div key={c.title}><div className="text-sm mb-1">{c.title}</div><ProgressBar value={c.progress} size="sm" /></div>
        ))}
      </div>
    </div>
  );
}
