import { RefreshCw, CheckCircle, XCircle, Clock, Database } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import { useTranslation } from '@/i18n';

const syncLogs = [
  { id: 1, type: 'FULL', status: 'SUCCESS', total: 1580, success: 1580, fail: 0, started: '2026-02-08 02:00', completed: '2026-02-08 02:12', by: 'SCHEDULER' },
  { id: 2, type: 'MEMBER', status: 'SUCCESS', total: 340, success: 340, fail: 0, started: '2026-02-07 14:30', completed: '2026-02-07 14:32', by: 'MANUAL' },
  { id: 3, type: 'COURSE', status: 'PARTIAL', total: 128, success: 120, fail: 8, started: '2026-02-07 02:00', completed: '2026-02-07 02:05', by: 'SCHEDULER' },
  { id: 4, type: 'FULL', status: 'FAILED', total: 0, success: 0, fail: 0, started: '2026-02-06 02:00', completed: '2026-02-06 02:01', by: 'SCHEDULER' },
];

const viewTables = [
  { name: 'LMS_MEMBER_VIEW', columns: 22, records: 15240, lastSync: '02-08 02:03' },
  { name: 'LMS_COURSE_VIEW', columns: 28, records: 128, lastSync: '02-08 02:05' },
  { name: 'LMS_STUDENT_VIEW', columns: 10, records: 12850, lastSync: '02-08 02:07' },
  { name: 'LMS_PROFESSOR_VIEW', columns: 11, records: 245, lastSync: '02-08 02:08' },
  { name: 'LMS_LECTPLAN_VIEW', columns: 17, records: 2048, lastSync: '02-08 02:09' },
  { name: 'LMS_LECTPLAN_NCS_VIEW', columns: 22, records: 512, lastSync: '02-08 02:10' },
  { name: 'COURSE_INFO_VIEW', columns: 25, records: 128, lastSync: '02-08 02:11' },
  { name: '채용공고_VIEW', columns: 27, records: 856, lastSync: '02-08 02:12' },
];

export default function SyncDashboardPage() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.syncTitle')}</h1>
          <p className="text-sm text-gray-500 mt-1">{t('admin.syncDesc')}</p>
        </div>
        <button className="btn-primary"><RefreshCw className="w-4 h-4" /> 수동 동기화</button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Database} label="뷰테이블" value="8종" />
        <StatCard icon={CheckCircle} label="총 컬럼" value="162" />
        <StatCard icon={Clock} label="마지막 동기화" value="02:12" />
        <StatCard icon={RefreshCw} label="동기화 주기" value="매일 2시" />
      </div>

      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">8종 뷰테이블 현황</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head"><tr><th className="table-th">{t('common.name')}</th><th className="table-th-center">컬럼수</th><th className="table-th-center">레코드</th><th className="table-th-center">{t('common.date')}</th><th className="table-th-center">{t('common.status')}</th></tr></thead>
            <tbody>
              {viewTables.map(v => (
                <tr key={v.name} className="table-row">
                  <td className="table-td font-mono text-xs font-medium">{v.name}</td>
                  <td className="table-td-center">{v.columns}</td>
                  <td className="table-td-center">{v.records.toLocaleString()}</td>
                  <td className="table-td-center text-xs">{v.lastSync}</td>
                  <td className="table-td-center"><span className="w-2 h-2 rounded-full bg-success-500 inline-block" /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">동기화 이력</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head"><tr><th className="table-th">{t('common.type')}</th><th className="table-th-center">{t('common.status')}</th><th className="table-th-center">{t('common.completed')}</th><th className="table-th-center">실패</th><th className="table-th-center">시작</th><th className="table-th-center">{t('common.completed')}</th><th className="table-th-center">트리거</th></tr></thead>
            <tbody>
              {syncLogs.map(s => (
                <tr key={s.id} className="table-row">
                  <td className="table-td font-medium">{s.type}</td>
                  <td className="table-td-center">
                    <span className={`badge-sm ${s.status === 'SUCCESS' ? 'badge-success' : s.status === 'PARTIAL' ? 'badge-warning' : 'badge-danger'}`}>{s.status}</span>
                  </td>
                  <td className="table-td-center text-success-600">{s.success.toLocaleString()}</td>
                  <td className="table-td-center text-danger-600">{s.fail}</td>
                  <td className="table-td-center text-xs">{s.started}</td>
                  <td className="table-td-center text-xs">{s.completed}</td>
                  <td className="table-td-center"><span className={`badge-sm ${s.by === 'MANUAL' ? 'badge-info' : 'badge-gray'}`}>{s.by}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
