import { useState } from 'react';
import { Shield, AlertTriangle, CheckCircle, Eye } from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import { useTranslation } from '@/i18n';

const fraudLogs = [
  { id: 1, user: '이학생', type: 'MULTI_SESSION', severity: 'WARNING', ip: '10.10.5.42', detail: '동시 2개 세션 감지', time: '2026-02-08 14:23', resolved: false },
  { id: 2, user: '김학생', type: 'SPEED_HACK', severity: 'BLOCKED', ip: '10.20.3.18', detail: '영상 재생속도 4x 감지', time: '2026-02-08 11:05', resolved: false },
  { id: 3, user: '박학생', type: 'TAB_SWITCH', severity: 'WARNING', ip: '10.10.2.55', detail: '시험 중 탭 전환 3회', time: '2026-02-07 15:30', resolved: true },
  { id: 4, user: '최학생', type: 'IP_MISMATCH', severity: 'CRITICAL', ip: '203.45.67.89', detail: '캠퍼스 외부 IP 접속', time: '2026-02-07 10:15', resolved: false },
];

const typeLabels: Record<string, string> = {
  MULTI_SESSION: '동시접속', SPEED_HACK: '속도조작', TAB_SWITCH: '탭전환', IP_MISMATCH: 'IP불일치', MIN_TIME_FAIL: '최소시간미달'
};

export default function AntiFraudPage() {
  const { t } = useTranslation();
  const [filter, setFilter] = useState('전체');
  const filters = ['전체', '미해결', '해결'];
  const filtered = fraudLogs.filter(f => filter === '전체' || (filter === '미해결' && !f.resolved) || (filter === '해결' && f.resolved));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.antifraudTitle')}</h1>
        <p className="text-sm text-gray-500 mt-1">{t('admin.antifraudDesc')}</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Shield} label="총 감지" value="47" />
        <StatCard icon={AlertTriangle} label="미해결" value="3" change="-2" trend="down" />
        <StatCard icon={CheckCircle} label="해결됨" value="44" />
        <StatCard icon={Eye} label="모니터링중" value="15,000" />
      </div>

      <div className="filter-bar w-fit">
        {filters.map(f => <button key={f} onClick={() => setFilter(f)} className={`filter-chip ${filter === f ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{f}</button>)}
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">{t('common.user')}</th><th className="table-th-center">{t('common.type')}</th><th className="table-th-center">심각도</th><th className="table-th">{t('common.detail')}</th><th className="table-th-center">IP</th><th className="table-th-center">{t('common.date')}</th><th className="table-th-center">{t('common.status')}</th></tr></thead>
          <tbody>
            {filtered.map(f => (
              <tr key={f.id} className="table-row">
                <td className="table-td font-medium">{f.user}</td>
                <td className="table-td-center"><span className="badge-sm badge-gray">{typeLabels[f.type]}</span></td>
                <td className="table-td-center">
                  <span className={`badge-sm ${f.severity === 'CRITICAL' ? 'badge-danger' : f.severity === 'BLOCKED' ? 'badge-warning' : 'badge-info'}`}>{f.severity}</span>
                </td>
                <td className="table-td text-xs text-gray-500">{f.detail}</td>
                <td className="table-td-center font-mono text-xs">{f.ip}</td>
                <td className="table-td-center text-xs">{f.time}</td>
                <td className="table-td-center">
                  {f.resolved ? <span className="badge-sm badge-success">해결</span> : <button className="btn-sm btn-ghost text-primary-600 text-xs">해제</button>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
