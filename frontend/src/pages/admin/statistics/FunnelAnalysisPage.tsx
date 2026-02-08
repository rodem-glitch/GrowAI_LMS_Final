// pages/admin/statistics/FunnelAnalysisPage.tsx — ADM-S01: 인재양성 퍼널 분석
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { TrendingUp, TrendingDown, Filter, ArrowDown, AlertTriangle, BarChart3 } from 'lucide-react';

/* ───── 퍼널 데이터 ───── */
const funnelData = [
  { stage: '입학', count: 1200, color: '#3b82f6', prevCount: 1150 },
  { stage: '교육 이수', count: 1100, color: '#6366f1', prevCount: 1080 },
  { stage: '수료', count: 980, color: '#8b5cf6', prevCount: 920 },
  { stage: '취업', count: 820, color: '#22c55e', prevCount: 750 },
];

/* ───── 캠퍼스별 퍼널 비교 ───── */
const campusComparison = [
  { campus: '서울강서', entry: 320, education: 305, completion: 280, employment: 245, prevEmployment: 220 },
  { campus: '인천', entry: 280, education: 260, completion: 230, employment: 195, prevEmployment: 180 },
  { campus: '대전', entry: 210, education: 195, completion: 175, employment: 148, prevEmployment: 135 },
  { campus: '광주', entry: 190, education: 172, completion: 150, employment: 120, prevEmployment: 108 },
  { campus: '부산', entry: 200, education: 168, completion: 145, employment: 112, prevEmployment: 107 },
];

const campusList = ['전체', '서울강서', '인천', '대전', '광주', '부산'];
const departmentList = ['전체', '소프트웨어공학과', '인공지능학과', '데이터사이언스학과', '정보보안학과', '디지털미디어학과'];
const yearList = ['2026', '2025', '2024', '2023'];

export default function FunnelAnalysisPage() {
  const { t } = useTranslation();
  const [campus, setCampus] = useState('전체');
  const [department, setDepartment] = useState('전체');
  const [year, setYear] = useState('2026');

  // 전환율 계산
  const conversionRates = funnelData.slice(1).map((stage, i) => {
    const prev = funnelData[i];
    const rate = ((stage.count / prev.count) * 100).toFixed(1);
    const dropoutRate = (100 - parseFloat(rate)).toFixed(1);
    return { from: prev.stage, to: stage.stage, rate, dropoutRate, isWarning: parseFloat(dropoutRate) > 10 };
  });

  // 퍼널 SVG 치수 계산
  const maxCount = funnelData[0].count;
  const funnelWidth = 500;
  const funnelHeight = 360;
  const stageHeight = 70;
  const gap = 20;

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.funnelTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{t('admin.funnelDesc')}</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <select
            value={year}
            onChange={e => setYear(e.target.value)}
            className="input-select text-xs"
          >
            {yearList.map(y => <option key={y} value={y}>{y}년</option>)}
          </select>
          <select
            value={campus}
            onChange={e => setCampus(e.target.value)}
            className="input-select text-xs"
          >
            {campusList.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
          <select
            value={department}
            onChange={e => setDepartment(e.target.value)}
            className="input-select text-xs"
          >
            {departmentList.map(d => <option key={d} value={d}>{d}</option>)}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* 퍼널 차트 */}
        <section className="card space-y-4 lg:col-span-3">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
            <BarChart3 className="w-4 h-4" /> 퍼널 차트
          </h2>
          <div className="flex justify-center overflow-x-auto">
            <svg viewBox={`0 0 ${funnelWidth} ${funnelHeight}`} className="w-full max-w-lg" preserveAspectRatio="xMidYMid meet">
              {funnelData.map((stage, i) => {
                const widthRatio = stage.count / maxCount;
                const barWidth = widthRatio * (funnelWidth - 100);
                const x = (funnelWidth - barWidth) / 2;
                const y = i * (stageHeight + gap);

                return (
                  <g key={stage.stage}>
                    {/* 퍼널 단계 바 */}
                    <rect
                      x={x} y={y}
                      width={barWidth} height={stageHeight}
                      rx="8"
                      fill={stage.color}
                      opacity="0.85"
                    />
                    {/* 단계 이름 + 인원수 */}
                    <text
                      x={funnelWidth / 2}
                      y={y + stageHeight / 2 - 8}
                      textAnchor="middle"
                      fill="white"
                      fontWeight="bold"
                      fontSize="15"
                    >
                      {stage.stage}
                    </text>
                    <text
                      x={funnelWidth / 2}
                      y={y + stageHeight / 2 + 14}
                      textAnchor="middle"
                      fill="white"
                      fontSize="13"
                      opacity="0.9"
                    >
                      {stage.count.toLocaleString()}명
                    </text>

                    {/* 전환율 화살표 (단계 사이) */}
                    {i < funnelData.length - 1 && (() => {
                      const cr = conversionRates[i];
                      const arrowY = y + stageHeight + gap / 2;
                      return (
                        <g>
                          {/* 화살표 */}
                          <line x1={funnelWidth / 2} y1={y + stageHeight + 2} x2={funnelWidth / 2} y2={y + stageHeight + gap - 2} stroke="#9ca3af" strokeWidth="1.5" markerEnd="url(#arrowhead)" className="dark:stroke-slate-500" />
                          {/* 전환율 텍스트 */}
                          <text x={funnelWidth / 2 + 50} y={arrowY + 4} textAnchor="start" fontSize="11" className="fill-gray-500 dark:fill-slate-400">
                            전환 {cr.rate}%
                          </text>
                          {/* 이탈률 경고 */}
                          {cr.isWarning && (
                            <text x={funnelWidth / 2 - 50} y={arrowY + 4} textAnchor="end" fontSize="11" fill="#ef4444" fontWeight="bold">
                              이탈 {cr.dropoutRate}%
                            </text>
                          )}
                        </g>
                      );
                    })()}
                  </g>
                );
              })}
              {/* 화살표 마커 정의 */}
              <defs>
                <marker id="arrowhead" markerWidth="8" markerHeight="6" refX="4" refY="3" orient="auto">
                  <polygon points="0 0, 8 3, 0 6" fill="#9ca3af" />
                </marker>
              </defs>
            </svg>
          </div>
        </section>

        {/* 전환율 카드 */}
        <section className="card space-y-4 lg:col-span-2">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">단계별 전환율</h2>
          <div className="space-y-3">
            {conversionRates.map(cr => (
              <div key={cr.from + cr.to} className="p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-medium text-gray-700 dark:text-slate-300">
                    {cr.from} → {cr.to}
                  </span>
                  {cr.isWarning && (
                    <span className="badge-sm badge-danger flex items-center gap-1">
                      <AlertTriangle className="w-3 h-3" /> 이탈 경고
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-3">
                  <div className="flex-1">
                    <div className="w-full h-2 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                      <div
                        className={`h-2 rounded-full ${cr.isWarning ? 'bg-red-500' : 'bg-green-500'}`}
                        style={{ width: `${cr.rate}%` }}
                      />
                    </div>
                  </div>
                  <span className={`text-sm font-bold ${cr.isWarning ? 'text-red-500' : 'text-green-600 dark:text-green-400'}`}>
                    {cr.rate}%
                  </span>
                </div>
                <div className="mt-1 text-[10px] text-gray-400">
                  이탈률: {cr.dropoutRate}%
                </div>
              </div>
            ))}

            {/* 전체 전환율 */}
            <div className="p-3 bg-primary-50 dark:bg-primary-900/30 rounded-lg border border-primary-200 dark:border-primary-800">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-primary-700 dark:text-primary-300">입학 → 취업 전체 전환율</span>
                <span className="text-lg font-bold text-primary-600 dark:text-primary-400">
                  {((funnelData[3].count / funnelData[0].count) * 100).toFixed(1)}%
                </span>
              </div>
            </div>
          </div>
        </section>
      </div>

      {/* 전년 대비 비교 테이블 */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">캠퍼스별 현황 (전년 대비)</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th">캠퍼스</th>
                <th className="table-th-center">입학</th>
                <th className="table-th-center">교육 이수</th>
                <th className="table-th-center">수료</th>
                <th className="table-th-center">취업</th>
                <th className="table-th-center">취업 전환율</th>
                <th className="table-th-center">전년 대비</th>
              </tr>
            </thead>
            <tbody>
              {campusComparison.map(c => {
                const rate = ((c.employment / c.entry) * 100).toFixed(1);
                const prevRate = ((c.prevEmployment / c.entry) * 100).toFixed(1);
                const diff = (parseFloat(rate) - parseFloat(prevRate)).toFixed(1);
                const isUp = parseFloat(diff) >= 0;
                return (
                  <tr key={c.campus} className="table-row">
                    <td className="table-td font-medium">{c.campus}</td>
                    <td className="table-td-center">{c.entry.toLocaleString()}</td>
                    <td className="table-td-center">{c.education.toLocaleString()}</td>
                    <td className="table-td-center">{c.completion.toLocaleString()}</td>
                    <td className="table-td-center font-medium">{c.employment.toLocaleString()}</td>
                    <td className="table-td-center">
                      <span className={`font-bold ${parseFloat(rate) >= 70 ? 'text-green-600 dark:text-green-400' : 'text-amber-600 dark:text-amber-400'}`}>
                        {rate}%
                      </span>
                    </td>
                    <td className="table-td-center">
                      <span className={`flex items-center justify-center gap-0.5 text-xs font-medium ${isUp ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                        {isUp ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                        {isUp ? '+' : ''}{diff}%p
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
