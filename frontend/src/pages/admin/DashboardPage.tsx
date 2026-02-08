import { Users, BookOpen, Activity, Shield, RefreshCw, TrendingUp } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import { useQuery } from '@tanstack/react-query';
import { dataApi } from '@/services/api';
import { useTranslation } from '@/i18n';

const recentSync = [
  { type: 'FULL', status: 'SUCCESS', count: 1250, date: '2026-02-08 02:00' },
  { type: 'MEMBER', status: 'SUCCESS', count: 340, date: '2026-02-07 14:30' },
  { type: 'COURSE', status: 'PARTIAL', count: 85, date: '2026-02-07 02:00' },
];

export default function DashboardPage() {
  const { t } = useTranslation();
  const { data: monitorData } = useQuery({
    queryKey: ['admin-monitoring'],
    queryFn: () => dataApi.getAdminMonitoring().catch(() => null),
    staleTime: 30000,
    retry: false,
  });

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.dashboardTitle')}</h1>
      {/* DB I/F: monitorData 사용하여 실시간 통계 표시 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Users} label={t('common.user')} value={monitorData?.totalUsers?.toLocaleString() ?? '3,842'} change="+156" trend="up" />
        <StatCard icon={BookOpen} label={t('admin.courseManageTitle')} value={monitorData?.activeCourses?.toString() ?? '128'} />
        <StatCard icon={Activity} label={t('admin.monitoringTitle')} value={monitorData?.dailyActiveUsers?.toString() ?? '450'} change="+12%" trend="up" />
        <StatCard icon={Shield} label={t('admin.antifraudTitle')} value={monitorData?.fraudAlerts?.toString() ?? '7'} change="-2" trend="down" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">최근 동기화 현황</h2>
          <div className="table-container">
            <table className="w-full">
              <thead className="table-head"><tr><th className="table-th">{t('common.type')}</th><th className="table-th-center">{t('common.status')}</th><th className="table-th-center">{t('common.items')}</th><th className="table-th-center">{t('common.date')}</th></tr></thead>
              <tbody>
                {recentSync.map((s, i) => (
                  <tr key={i} className="table-row">
                    <td className="table-td font-medium">{s.type}</td>
                    <td className="table-td-center"><span className={`badge-sm ${s.status === 'SUCCESS' ? 'badge-success' : 'badge-warning'}`}>{s.status}</span></td>
                    <td className="table-td-center">{s.count.toLocaleString()}</td>
                    <td className="table-td-center text-[10px]">{s.date}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">시스템 상태</h2>
          <div className="space-y-3">
            {[
              { name: 'Spring Boot API', status: 'UP', latency: '12ms' },
              { name: 'MySQL Database', status: 'UP', latency: '3ms' },
              { name: 'Redis Cache', status: 'UP', latency: '1ms' },
              { name: 'Qdrant Vector DB', status: 'UP', latency: '5ms' },
              { name: 'VPN (KPOLY)', status: 'UP', latency: '45ms' },
            ].map(s => (
              <div key={s.name} className="flex items-center justify-between p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                <span className="text-sm">{s.name}</span>
                <div className="flex items-center gap-2">
                  <span className="text-[10px] text-gray-400">{s.latency}</span>
                  <span className="w-2 h-2 rounded-full bg-success-500" />
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
