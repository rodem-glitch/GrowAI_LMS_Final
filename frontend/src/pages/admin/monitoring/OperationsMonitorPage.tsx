// pages/admin/monitoring/OperationsMonitorPage.tsx — ADM-001: 운영 현황 모니터링
import { useState, useEffect } from 'react';
import { useTranslation } from '@/i18n';
import { Activity, Users, Cpu, HardDrive, AlertTriangle, RefreshCw, Zap, Server } from 'lucide-react';
import StatCard from '@/components/common/StatCard';

/* ───── 시간별 접속자 데이터 (24시간) ───── */
const hourlyAccess = [
  { hour: '00', count: 32 }, { hour: '01', count: 18 }, { hour: '02', count: 12 },
  { hour: '03', count: 8 },  { hour: '04', count: 15 }, { hour: '05', count: 28 },
  { hour: '06', count: 65 }, { hour: '07', count: 120 },{ hour: '08', count: 198 },
  { hour: '09', count: 245 },{ hour: '10', count: 310 },{ hour: '11', count: 285 },
  { hour: '12', count: 195 },{ hour: '13', count: 260 },{ hour: '14', count: 320 },
  { hour: '15', count: 290 },{ hour: '16', count: 247 },{ hour: '17', count: 180 },
  { hour: '18', count: 130 },{ hour: '19', count: 95 }, { hour: '20', count: 78 },
  { hour: '21', count: 62 }, { hour: '22', count: 48 }, { hour: '23', count: 38 },
];

/* ───── 서버 리소스 ───── */
const serverResources = [
  { name: 'CPU 사용률', value: 45, icon: Cpu, color: 'text-blue-500', bgColor: 'text-blue-100' },
  { name: 'Memory 사용률', value: 62, icon: Server, color: 'text-purple-500', bgColor: 'text-purple-100' },
  { name: 'Disk 사용률', value: 38, icon: HardDrive, color: 'text-green-500', bgColor: 'text-green-100' },
];

/* ───── 최근 오류 로그 ───── */
const recentErrors = [
  { id: 1, time: '2026-02-08 16:42:18', level: 'ERROR', service: 'API Gateway', message: 'Connection timeout to upstream server (port 8080)', count: 3 },
  { id: 2, time: '2026-02-08 16:38:05', level: 'WARN', service: 'Auth Service', message: 'JWT token refresh failed - invalid refresh token', count: 12 },
  { id: 3, time: '2026-02-08 16:25:33', level: 'ERROR', service: 'File Storage', message: 'Disk quota exceeded on /data/uploads partition', count: 1 },
  { id: 4, time: '2026-02-08 15:58:41', level: 'WARN', service: 'Redis Cache', message: 'Memory usage above 80% threshold, eviction started', count: 5 },
  { id: 5, time: '2026-02-08 15:42:10', level: 'ERROR', service: 'DB Connection', message: 'Max pool size reached (50/50), queries queued', count: 2 },
];

/* ───── 반원형 게이지 SVG 컴포넌트 ───── */
function GaugeChart({ value, label, color }: { value: number; label: string; color: string }) {
  const radius = 60;
  const circumference = Math.PI * radius;
  const filled = (value / 100) * circumference;
  const strokeColor =
    value >= 80 ? '#ef4444' : value >= 60 ? '#f59e0b' : '#22c55e';

  return (
    <div className="flex flex-col items-center">
      <svg width="140" height="85" viewBox="0 0 140 85">
        {/* 배경 호 */}
        <path
          d="M 10 80 A 60 60 0 0 1 130 80"
          fill="none"
          stroke="#e5e7eb"
          strokeWidth="12"
          strokeLinecap="round"
          className="dark:stroke-slate-700"
        />
        {/* 값 호 */}
        <path
          d="M 10 80 A 60 60 0 0 1 130 80"
          fill="none"
          stroke={strokeColor}
          strokeWidth="12"
          strokeLinecap="round"
          strokeDasharray={`${filled} ${circumference}`}
        />
        {/* 값 텍스트 */}
        <text x="70" y="72" textAnchor="middle" className="fill-gray-900 dark:fill-white text-xl font-bold" fontSize="22">
          {value}%
        </text>
      </svg>
      <span className="text-xs text-gray-500 dark:text-slate-400 mt-1">{label}</span>
    </div>
  );
}

export default function OperationsMonitorPage() {
  const { t } = useTranslation();
  const [refreshCount, setRefreshCount] = useState(30);
  const [lastRefresh, setLastRefresh] = useState('2026-02-08 16:45:00');

  // 자동 새로고침 카운트다운 시뮬레이션
  useEffect(() => {
    const timer = setInterval(() => {
      setRefreshCount(prev => {
        if (prev <= 1) {
          setLastRefresh(new Date().toLocaleString('ko-KR'));
          return 30;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // 접속자 차트 계산
  const maxCount = Math.max(...hourlyAccess.map(h => h.count));
  const chartWidth = 700;
  const chartHeight = 180;
  const padding = { top: 10, right: 10, bottom: 30, left: 40 };
  const plotWidth = chartWidth - padding.left - padding.right;
  const plotHeight = chartHeight - padding.top - padding.bottom;

  const points = hourlyAccess.map((h, i) => {
    const x = padding.left + (i / (hourlyAccess.length - 1)) * plotWidth;
    const y = padding.top + plotHeight - (h.count / maxCount) * plotHeight;
    return `${x},${y}`;
  });
  const linePath = points.join(' ');
  const areaPath = `${padding.left},${padding.top + plotHeight} ${linePath} ${padding.left + plotWidth},${padding.top + plotHeight}`;

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.monitoringTitle')}</h1>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-slate-400">
            <div className="flex items-center gap-1">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500" />
              </span>
              실시간
            </div>
            <span>|</span>
            <span>다음 갱신: {refreshCount}초</span>
          </div>
          <button
            onClick={() => { setRefreshCount(30); setLastRefresh(new Date().toLocaleString('ko-KR')); }}
            className="btn-secondary"
          >
            <RefreshCw className="w-4 h-4" /> 새로고침
          </button>
        </div>
      </div>

      {/* 통계 카드 4개 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Activity} label="실시간 접속자" value="247" change="+18" trend="up" />
        <StatCard icon={Users} label="총 가입자" value="15,234" change="+52" trend="up" />
        <StatCard icon={Zap} label="AI 토큰 사용량" value="1.2M" change="+15%" trend="up" />
        <StatCard icon={AlertTriangle} label="오류율" value="0.3%" change="-0.1%" trend="down" />
      </div>

      {/* 시간별 접속자 차트 + 서버 리소스 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 접속자 라인 차트 */}
        <section className="card space-y-4 lg:col-span-2">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">시간별 접속자 추이</h2>
            <span className="text-[10px] text-gray-400">최근 24시간</span>
          </div>
          <div className="overflow-x-auto">
            <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} className="w-full min-w-[500px]" preserveAspectRatio="xMidYMid meet">
              {/* Y축 가이드라인 */}
              {[0, 0.25, 0.5, 0.75, 1].map((ratio, i) => {
                const y = padding.top + plotHeight * (1 - ratio);
                return (
                  <g key={i}>
                    <line x1={padding.left} y1={y} x2={padding.left + plotWidth} y2={y} stroke="#e5e7eb" strokeWidth="0.5" className="dark:stroke-slate-700" />
                    <text x={padding.left - 5} y={y + 4} textAnchor="end" className="fill-gray-400 dark:fill-slate-500" fontSize="9">
                      {Math.round(maxCount * ratio)}
                    </text>
                  </g>
                );
              })}
              {/* 면적 */}
              <polygon points={areaPath} fill="url(#areaGradient)" opacity="0.3" />
              {/* 그라데이션 정의 */}
              <defs>
                <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.4" />
                  <stop offset="100%" stopColor="#3b82f6" stopOpacity="0.05" />
                </linearGradient>
              </defs>
              {/* 라인 */}
              <polyline points={linePath} fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
              {/* 데이터 포인트 + X축 라벨 */}
              {hourlyAccess.map((h, i) => {
                const x = padding.left + (i / (hourlyAccess.length - 1)) * plotWidth;
                const y = padding.top + plotHeight - (h.count / maxCount) * plotHeight;
                return (
                  <g key={i}>
                    <circle cx={x} cy={y} r="3" fill="#3b82f6" stroke="white" strokeWidth="1.5" className="dark:stroke-slate-800" />
                    {i % 3 === 0 && (
                      <text x={x} y={padding.top + plotHeight + 18} textAnchor="middle" className="fill-gray-400 dark:fill-slate-500" fontSize="9">
                        {h.hour}시
                      </text>
                    )}
                  </g>
                );
              })}
            </svg>
          </div>
        </section>

        {/* 서버 리소스 게이지 */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">서버 리소스</h2>
          <div className="flex flex-col items-center gap-4">
            {serverResources.map(r => (
              <GaugeChart key={r.name} value={r.value} label={r.name} color={r.color} />
            ))}
          </div>
        </section>
      </div>

      {/* 최근 오류 로그 */}
      <section className="card space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">최근 오류 로그</h2>
          <span className="text-[10px] text-gray-400">마지막 갱신: {lastRefresh}</span>
        </div>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">레벨</th>
                <th className="table-th">서비스</th>
                <th className="table-th">메시지</th>
                <th className="table-th-center">발생횟수</th>
                <th className="table-th-center">시각</th>
              </tr>
            </thead>
            <tbody>
              {recentErrors.map(err => (
                <tr key={err.id} className="table-row">
                  <td className="table-td-center">
                    <span className={`badge-sm ${err.level === 'ERROR' ? 'badge-danger' : 'badge-warning'}`}>
                      {err.level}
                    </span>
                  </td>
                  <td className="table-td font-medium text-xs">{err.service}</td>
                  <td className="table-td text-xs text-gray-600 dark:text-slate-400 max-w-xs truncate">{err.message}</td>
                  <td className="table-td-center">
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-[10px] font-bold">
                      {err.count}
                    </span>
                  </td>
                  <td className="table-td-center text-[10px] text-gray-400">{err.time}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* 자동 갱신 안내 */}
      <div className="flex items-center justify-center gap-2 text-xs text-gray-400 dark:text-slate-500">
        <RefreshCw className="w-3 h-3 animate-spin" />
        <span>30초마다 자동 갱신됩니다</span>
      </div>
    </div>
  );
}
