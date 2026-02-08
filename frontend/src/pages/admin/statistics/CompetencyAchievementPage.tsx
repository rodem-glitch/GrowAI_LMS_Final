// pages/admin/statistics/CompetencyAchievementPage.tsx — ADM-S02: 역량 성취도 분석
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { TrendingUp, Award, Brain, Target, Filter } from 'lucide-react';

/* ───── 역량 데이터 (입학시점 vs 졸업시점) ───── */
const competencies = [
  { name: '프로그래밍 기초', entry: 32, graduation: 85, improvement: 53 },
  { name: '데이터 분석', entry: 25, graduation: 78, improvement: 53 },
  { name: '문제 해결력', entry: 40, graduation: 88, improvement: 48 },
  { name: '팀워크/협업', entry: 55, graduation: 90, improvement: 35 },
  { name: '의사소통', entry: 50, graduation: 82, improvement: 32 },
  { name: 'AI 활용 능력', entry: 15, graduation: 75, improvement: 60 },
  { name: '프로젝트 관리', entry: 20, graduation: 72, improvement: 52 },
  { name: '보안 인식', entry: 30, graduation: 70, improvement: 40 },
];

/* ───── Top 10 역량 향상 ───── */
const topImprovements = [
  { rank: 1, name: 'AI 활용 능력', department: '인공지능학과', before: 15, after: 75, improvement: 60 },
  { rank: 2, name: '프로그래밍 기초', department: '소프트웨어공학과', before: 32, after: 85, improvement: 53 },
  { rank: 3, name: '데이터 분석', department: '데이터사이언스학과', before: 25, after: 78, improvement: 53 },
  { rank: 4, name: '프로젝트 관리', department: '소프트웨어공학과', before: 20, after: 72, improvement: 52 },
  { rank: 5, name: '문제 해결력', department: '정보보안학과', before: 40, after: 88, improvement: 48 },
  { rank: 6, name: '클라우드 기술', department: '인공지능학과', before: 18, after: 65, improvement: 47 },
  { rank: 7, name: 'DevOps 이해', department: '소프트웨어공학과', before: 12, after: 58, improvement: 46 },
  { rank: 8, name: '보안 인식', department: '정보보안학과', before: 30, after: 70, improvement: 40 },
  { rank: 9, name: '팀워크/협업', department: '디지털미디어학과', before: 55, after: 90, improvement: 35 },
  { rank: 10, name: 'UX 설계', department: '디지털미디어학과', before: 35, after: 68, improvement: 33 },
];

/* ───── AI 에이전트 활용도 vs 취업률 상관관계 ───── */
const correlationData = [
  { campus: '서울강서', aiUsage: 82, employRate: 76.5 },
  { campus: '인천', aiUsage: 75, employRate: 69.6 },
  { campus: '대전', aiUsage: 68, employRate: 70.5 },
  { campus: '광주', aiUsage: 55, employRate: 63.2 },
  { campus: '부산', aiUsage: 60, employRate: 56.0 },
  { campus: '충주', aiUsage: 48, employRate: 52.3 },
  { campus: '춘천', aiUsage: 72, employRate: 68.1 },
  { campus: '아산', aiUsage: 65, employRate: 64.8 },
];

const campusList = ['전체', '서울강서', '인천', '대전', '광주', '부산'];
const yearList = ['2026', '2025', '2024'];

/* ───── 레이더 차트 SVG ───── */
function RadarChart({ data, size = 280 }: { data: typeof competencies; size?: number }) {
  const center = size / 2;
  const radius = size / 2 - 40;
  const angleStep = (2 * Math.PI) / data.length;

  const getPoint = (value: number, index: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = (value / 100) * radius;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  const entryPoints = data.map((d, i) => getPoint(d.entry, i));
  const gradPoints = data.map((d, i) => getPoint(d.graduation, i));

  const entryPath = entryPoints.map(p => `${p.x},${p.y}`).join(' ');
  const gradPath = gradPoints.map(p => `${p.x},${p.y}`).join(' ');

  return (
    <svg viewBox={`0 0 ${size} ${size}`} className="w-full max-w-[300px]">
      {/* 배경 그리드 */}
      {[20, 40, 60, 80, 100].map(level => {
        const points = data.map((_, i) => {
          const p = getPoint(level, i);
          return `${p.x},${p.y}`;
        }).join(' ');
        return (
          <polygon key={level} points={points} fill="none" stroke="#e5e7eb" strokeWidth="0.5" className="dark:stroke-slate-700" />
        );
      })}

      {/* 축 라인 */}
      {data.map((_, i) => {
        const p = getPoint(100, i);
        return (
          <line key={i} x1={center} y1={center} x2={p.x} y2={p.y} stroke="#e5e7eb" strokeWidth="0.5" className="dark:stroke-slate-700" />
        );
      })}

      {/* 입학시점 (빨간색) */}
      <polygon points={entryPath} fill="rgba(239,68,68,0.15)" stroke="#ef4444" strokeWidth="2" />
      {entryPoints.map((p, i) => (
        <circle key={`entry-${i}`} cx={p.x} cy={p.y} r="3" fill="#ef4444" />
      ))}

      {/* 졸업시점 (파란색) */}
      <polygon points={gradPath} fill="rgba(59,130,246,0.15)" stroke="#3b82f6" strokeWidth="2" />
      {gradPoints.map((p, i) => (
        <circle key={`grad-${i}`} cx={p.x} cy={p.y} r="3" fill="#3b82f6" />
      ))}

      {/* 라벨 */}
      {data.map((d, i) => {
        const p = getPoint(115, i);
        return (
          <text
            key={`label-${i}`}
            x={p.x}
            y={p.y}
            textAnchor="middle"
            dominantBaseline="central"
            className="fill-gray-600 dark:fill-slate-400"
            fontSize="9"
          >
            {d.name}
          </text>
        );
      })}
    </svg>
  );
}

export default function CompetencyAchievementPage() {
  const { t } = useTranslation();
  const [campus, setCampus] = useState('전체');
  const [year, setYear] = useState('2026');

  // 산점도 계산
  const scatterWidth = 400;
  const scatterHeight = 280;
  const sPad = { top: 20, right: 20, bottom: 35, left: 45 };
  const sPlotW = scatterWidth - sPad.left - sPad.right;
  const sPlotH = scatterHeight - sPad.top - sPad.bottom;

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.competencyTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{t('admin.competencyDesc')}</p>
        </div>
        <div className="flex items-center gap-2">
          <select value={year} onChange={e => setYear(e.target.value)} className="input-select text-xs">
            {yearList.map(y => <option key={y} value={y}>{y}년</option>)}
          </select>
          <select value={campus} onChange={e => setCampus(e.target.value)} className="input-select text-xs">
            {campusList.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>

      {/* 요약 카드 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/30"><Target className="w-4 h-4 text-blue-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">78.2</div>
          <div className="text-[10px] text-gray-500">평균 졸업 역량 점수</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-green-50 dark:bg-green-900/30"><TrendingUp className="w-4 h-4 text-green-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">+45.3</div>
          <div className="text-[10px] text-gray-500">평균 역량 향상 점수</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-purple-50 dark:bg-purple-900/30"><Brain className="w-4 h-4 text-purple-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">68.2%</div>
          <div className="text-[10px] text-gray-500">AI 에이전트 활용률</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-amber-50 dark:bg-amber-900/30"><Award className="w-4 h-4 text-amber-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">AI 활용 능력</div>
          <div className="text-[10px] text-gray-500">최대 향상 역량</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 레이더 차트: Before / After */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">입학 vs 졸업 역량 비교</h2>
          <div className="flex justify-center">
            <RadarChart data={competencies} />
          </div>
          <div className="flex items-center justify-center gap-6 text-xs">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-red-500" />
              <span className="text-gray-600 dark:text-slate-400">입학시점</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-blue-500" />
              <span className="text-gray-600 dark:text-slate-400">졸업시점</span>
            </div>
          </div>
        </section>

        {/* 산점도: AI 활용도 vs 취업률 */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">AI 에이전트 활용도 vs 취업률 상관관계</h2>
          <div className="flex justify-center overflow-x-auto">
            <svg viewBox={`0 0 ${scatterWidth} ${scatterHeight}`} className="w-full max-w-[420px]" preserveAspectRatio="xMidYMid meet">
              {/* X축, Y축 */}
              <line x1={sPad.left} y1={sPad.top} x2={sPad.left} y2={sPad.top + sPlotH} stroke="#d1d5db" strokeWidth="1" className="dark:stroke-slate-600" />
              <line x1={sPad.left} y1={sPad.top + sPlotH} x2={sPad.left + sPlotW} y2={sPad.top + sPlotH} stroke="#d1d5db" strokeWidth="1" className="dark:stroke-slate-600" />

              {/* 그리드 */}
              {[0, 25, 50, 75, 100].map(v => {
                const x = sPad.left + (v / 100) * sPlotW;
                const y = sPad.top + sPlotH - (v / 100) * sPlotH;
                return (
                  <g key={v}>
                    <line x1={sPad.left} y1={y} x2={sPad.left + sPlotW} y2={y} stroke="#f3f4f6" strokeWidth="0.5" className="dark:stroke-slate-700" />
                    <line x1={x} y1={sPad.top} x2={x} y2={sPad.top + sPlotH} stroke="#f3f4f6" strokeWidth="0.5" className="dark:stroke-slate-700" />
                    <text x={sPad.left - 5} y={y + 3} textAnchor="end" fontSize="8" className="fill-gray-400 dark:fill-slate-500">{v}%</text>
                    <text x={x} y={sPad.top + sPlotH + 14} textAnchor="middle" fontSize="8" className="fill-gray-400 dark:fill-slate-500">{v}%</text>
                  </g>
                );
              })}

              {/* 추세선 (간단한 선형) */}
              {(() => {
                const xMin = 40, xMax = 90, yMin = 48, yMax = 80;
                const x1 = sPad.left + (xMin / 100) * sPlotW;
                const y1 = sPad.top + sPlotH - (yMin / 100) * sPlotH;
                const x2 = sPad.left + (xMax / 100) * sPlotW;
                const y2 = sPad.top + sPlotH - (yMax / 100) * sPlotH;
                return <line x1={x1} y1={y1} x2={x2} y2={y2} stroke="#f59e0b" strokeWidth="1.5" strokeDasharray="4 2" opacity="0.6" />;
              })()}

              {/* 데이터 포인트 */}
              {correlationData.map((d, i) => {
                const x = sPad.left + (d.aiUsage / 100) * sPlotW;
                const y = sPad.top + sPlotH - (d.employRate / 100) * sPlotH;
                return (
                  <g key={i}>
                    <circle cx={x} cy={y} r="6" fill="#3b82f6" opacity="0.7" stroke="white" strokeWidth="1.5" className="dark:stroke-slate-800" />
                    <text x={x} y={y - 10} textAnchor="middle" fontSize="8" className="fill-gray-600 dark:fill-slate-400">
                      {d.campus}
                    </text>
                  </g>
                );
              })}

              {/* 축 라벨 */}
              <text x={sPad.left + sPlotW / 2} y={scatterHeight - 2} textAnchor="middle" fontSize="10" className="fill-gray-500 dark:fill-slate-400">
                AI 에이전트 활용도 (%)
              </text>
              <text x={12} y={sPad.top + sPlotH / 2} textAnchor="middle" fontSize="10" className="fill-gray-500 dark:fill-slate-400" transform={`rotate(-90 12 ${sPad.top + sPlotH / 2})`}>
                취업률 (%)
              </text>
            </svg>
          </div>
          <div className="text-center text-[10px] text-gray-400">
            상관계수 r = 0.87 (강한 양의 상관관계)
          </div>
        </section>
      </div>

      {/* Top 10 역량 향상 테이블 */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">Top 10 최대 향상 역량</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">순위</th>
                <th className="table-th">역량</th>
                <th className="table-th">학과</th>
                <th className="table-th-center">입학 점수</th>
                <th className="table-th-center">졸업 점수</th>
                <th className="table-th-center">향상도</th>
                <th className="table-th">향상 바</th>
              </tr>
            </thead>
            <tbody>
              {topImprovements.map(item => (
                <tr key={item.rank} className="table-row">
                  <td className="table-td-center">
                    <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-[10px] font-bold ${
                      item.rank <= 3 ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400' : 'bg-gray-100 text-gray-600 dark:bg-slate-700 dark:text-slate-400'
                    }`}>
                      {item.rank}
                    </span>
                  </td>
                  <td className="table-td font-medium">{item.name}</td>
                  <td className="table-td text-xs text-gray-500">{item.department}</td>
                  <td className="table-td-center text-red-500 font-medium">{item.before}</td>
                  <td className="table-td-center text-blue-600 dark:text-blue-400 font-medium">{item.after}</td>
                  <td className="table-td-center">
                    <span className="flex items-center justify-center gap-0.5 text-green-600 dark:text-green-400 font-bold text-xs">
                      <TrendingUp className="w-3 h-3" /> +{item.improvement}
                    </span>
                  </td>
                  <td className="table-td w-32">
                    <div className="w-full h-2 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                      <div
                        className="h-2 bg-gradient-to-r from-red-400 via-amber-400 to-green-500 rounded-full"
                        style={{ width: `${item.improvement}%` }}
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
