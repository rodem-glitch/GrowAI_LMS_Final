import { BookOpen, Users, TrendingUp } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';
import { useTranslation } from '@/i18n';

const courseStats = [
  { title: 'Python 프로그래밍 기초', enrolled: 35, avgProgress: 65, completion: 34 },
  { title: '데이터베이스 설계', enrolled: 28, avgProgress: 45, completion: 18 },
  { title: '머신러닝 입문', enrolled: 22, avgProgress: 80, completion: 64 },
  { title: '웹 개발 실무', enrolled: 38, avgProgress: 55, completion: 26 },
];

export default function LearningManagePage() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.learningManageTitle')}</h1>
      <div className="grid grid-cols-3 gap-4">
        <StatCard icon={BookOpen} label="운영 강좌" value="4" />
        <StatCard icon={Users} label="수강생" value="123" />
        <StatCard icon={TrendingUp} label="평균 진도율" value="61%" />
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">{t('common.name')}</th><th className="table-th-center">{t('common.people')}</th><th className="table-th-center">평균 진도율</th><th className="table-th-center">수료율</th></tr></thead>
          <tbody>
            {courseStats.map((c, i) => (
              <tr key={i} className="table-row">
                <td className="table-td font-medium">{c.title}</td>
                <td className="table-td-center">{c.enrolled}명</td>
                <td className="table-td-center w-40"><ProgressBar value={c.avgProgress} size="sm" /></td>
                <td className="table-td-center"><span className={c.completion >= 50 ? 'text-success-600 font-medium' : 'text-warning-600'}>{c.completion}%</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
