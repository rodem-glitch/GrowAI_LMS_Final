// pages/admin/statistics/EmploymentMatchPage.tsx — ADM-S03: 전공 일치 취업률
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Briefcase, TrendingUp, TrendingDown, Tag, Shield, Award, BarChart3, Building2 } from 'lucide-react';

/* ───── 전체 통계 ───── */
const overallStats = {
  employmentRate: 68.3,
  majorMatchRate: 72.5,
  insuranceRate: 91.2,
  avgSalary: 3250,
  fullTimeRate: 85.7,
};

/* ───── 학과별 취업 현황 ───── */
const departmentData = [
  { name: '소프트웨어공학과', total: 180, employed: 142, majorMatch: 118, matchRate: 83.1, prevMatchRate: 78.5 },
  { name: '인공지능학과', total: 150, employed: 112, majorMatch: 95, matchRate: 84.8, prevMatchRate: 72.3 },
  { name: '데이터사이언스학과', total: 120, employed: 88, majorMatch: 72, matchRate: 81.8, prevMatchRate: 76.1 },
  { name: '정보보안학과', total: 100, employed: 65, majorMatch: 52, matchRate: 80.0, prevMatchRate: 74.8 },
  { name: '디지털미디어학과', total: 130, employed: 78, majorMatch: 55, matchRate: 70.5, prevMatchRate: 68.2 },
  { name: '전자공학과', total: 110, employed: 72, majorMatch: 48, matchRate: 66.7, prevMatchRate: 65.3 },
  { name: '기계공학과', total: 95, employed: 58, majorMatch: 35, matchRate: 60.3, prevMatchRate: 58.9 },
  { name: '경영학과', total: 115, employed: 65, majorMatch: 38, matchRate: 58.5, prevMatchRate: 55.2 },
];

/* ───── 학생 기술태그 vs 기업 업종 매칭 ───── */
const tagMatches = [
  { studentTag: 'Python', matchIndustry: 'AI/ML 기업', matchCount: 85, color: '#3b82f6' },
  { studentTag: 'Java/Spring', matchIndustry: 'SI/SM 기업', matchCount: 72, color: '#6366f1' },
  { studentTag: 'React/TypeScript', matchIndustry: '웹 서비스 기업', matchCount: 68, color: '#8b5cf6' },
  { studentTag: '클라우드(AWS/GCP)', matchIndustry: '클라우드 서비스', matchCount: 55, color: '#22c55e' },
  { studentTag: '보안/네트워크', matchIndustry: '보안 전문기업', matchCount: 42, color: '#ef4444' },
  { studentTag: 'UI/UX 디자인', matchIndustry: '디자인 에이전시', matchCount: 38, color: '#f59e0b' },
  { studentTag: 'DevOps/CI-CD', matchIndustry: '플랫폼 기업', matchCount: 35, color: '#06b6d4' },
  { studentTag: '데이터 분석', matchIndustry: '데이터 기업', matchCount: 48, color: '#ec4899' },
];

/* ───── 연도별 비교 ───── */
const yearlyComparison = [
  { year: '2023', rate: 62.1, matchRate: 65.8 },
  { year: '2024', rate: 65.5, matchRate: 68.2 },
  { year: '2025', rate: 66.8, matchRate: 70.1 },
  { year: '2026', rate: 68.3, matchRate: 72.5 },
];

/* ───── 취업의 질 지표 ───── */
const qualityMetrics = [
  { label: '4대보험 가입률', value: '91.2%', icon: Shield, color: 'bg-blue-50 dark:bg-blue-900/30', textColor: 'text-blue-600' },
  { label: '평균 연봉', value: '3,250만원', icon: Award, color: 'bg-green-50 dark:bg-green-900/30', textColor: 'text-green-600' },
  { label: '정규직 비율', value: '85.7%', icon: Building2, color: 'bg-purple-50 dark:bg-purple-900/30', textColor: 'text-purple-600' },
  { label: '6개월 재직률', value: '88.4%', icon: Briefcase, color: 'bg-amber-50 dark:bg-amber-900/30', textColor: 'text-amber-600' },
];

const yearList = ['2026', '2025', '2024', '2023'];

export default function EmploymentMatchPage() {
  const { t } = useTranslation();
  const [year, setYear] = useState('2026');

  // 연도별 차트 계산
  const chartWidth = 500;
  const chartHeight = 200;
  const cPad = { top: 20, right: 20, bottom: 30, left: 40 };
  const cPlotW = chartWidth - cPad.left - cPad.right;
  const cPlotH = chartHeight - cPad.top - cPad.bottom;
  const barGroupWidth = cPlotW / yearlyComparison.length;

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.employmentTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{t('admin.employmentDesc')}</p>
        </div>
        <select value={year} onChange={e => setYear(e.target.value)} className="input-select text-xs">
          {yearList.map(y => <option key={y} value={y}>{y}년</option>)}
        </select>
      </div>

      {/* 전체 통계 + 취업의 질 */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-primary-50 dark:bg-primary-900/30"><Briefcase className="w-4 h-4 text-primary-600" /></div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">{overallStats.employmentRate}%</div>
          <div className="text-[10px] text-gray-500">전체 취업률</div>
          <div className="flex items-center gap-1 mt-1 text-[10px] text-green-600"><TrendingUp className="w-3 h-3" />+1.5%p (전년 대비)</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-green-50 dark:bg-green-900/30"><Tag className="w-4 h-4 text-green-600" /></div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">{overallStats.majorMatchRate}%</div>
          <div className="text-[10px] text-gray-500">전공일치 취업률</div>
          <div className="flex items-center gap-1 mt-1 text-[10px] text-green-600"><TrendingUp className="w-3 h-3" />+2.4%p (전년 대비)</div>
        </div>
        <div className="card p-4 col-span-2 lg:col-span-1">
          <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300 mb-3">취업의 질 지표</h3>
          <div className="grid grid-cols-2 gap-2">
            {qualityMetrics.map(m => (
              <div key={m.label} className={`p-2 rounded-lg ${m.color} flex flex-col items-center`}>
                <m.icon className={`w-4 h-4 ${m.textColor} mb-1`} />
                <span className={`text-sm font-bold ${m.textColor}`}>{m.value}</span>
                <span className="text-[9px] text-gray-500 dark:text-slate-400 text-center">{m.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 학과별 전공일치 취업률 */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
          <BarChart3 className="w-4 h-4" /> 학과별 전공일치 취업 현황
        </h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th">학과</th>
                <th className="table-th-center">졸업생</th>
                <th className="table-th-center">취업자</th>
                <th className="table-th-center">전공일치</th>
                <th className="table-th">전공일치도</th>
                <th className="table-th-center">전년 대비</th>
              </tr>
            </thead>
            <tbody>
              {departmentData.map(d => {
                const diff = (d.matchRate - d.prevMatchRate).toFixed(1);
                const isUp = parseFloat(diff) >= 0;
                return (
                  <tr key={d.name} className="table-row">
                    <td className="table-td font-medium">{d.name}</td>
                    <td className="table-td-center">{d.total}</td>
                    <td className="table-td-center">{d.employed}</td>
                    <td className="table-td-center font-medium">{d.majorMatch}</td>
                    <td className="table-td">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2.5 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                          <div
                            className={`h-2.5 rounded-full ${d.matchRate >= 80 ? 'bg-green-500' : d.matchRate >= 65 ? 'bg-blue-500' : 'bg-amber-500'}`}
                            style={{ width: `${d.matchRate}%` }}
                          />
                        </div>
                        <span className="text-xs font-bold min-w-[40px] text-right">{d.matchRate}%</span>
                      </div>
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 기술태그 매칭 시각화 */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
            <Tag className="w-4 h-4" /> 학생 기술태그 vs 취업기업 업종
          </h2>
          <div className="space-y-3">
            {tagMatches.map(t => (
              <div key={t.studentTag} className="flex items-center gap-3">
                {/* 학생 태그 */}
                <div className="flex-shrink-0 w-36">
                  <span
                    className="inline-block px-2 py-1 rounded-full text-[10px] font-medium text-white truncate max-w-full"
                    style={{ backgroundColor: t.color }}
                  >
                    {t.studentTag}
                  </span>
                </div>
                {/* 연결선 + 매칭 수 */}
                <div className="flex-1 flex items-center gap-2">
                  <div className="flex-1 h-1.5 rounded-full overflow-hidden bg-gray-100 dark:bg-slate-700">
                    <div className="h-1.5 rounded-full" style={{ width: `${(t.matchCount / 85) * 100}%`, backgroundColor: t.color, opacity: 0.7 }} />
                  </div>
                  <span className="text-[10px] font-bold text-gray-600 dark:text-slate-400 min-w-[30px] text-right">{t.matchCount}건</span>
                </div>
                {/* 기업 업종 */}
                <div className="flex-shrink-0 w-28">
                  <span className="text-[10px] text-gray-500 dark:text-slate-400">{t.matchIndustry}</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* 연도별 비교 차트 */}
        <section className="card space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">연도별 취업률 추이</h2>
          <div className="flex justify-center overflow-x-auto">
            <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} className="w-full max-w-[500px]" preserveAspectRatio="xMidYMid meet">
              {/* Y축 가이드 */}
              {[0, 20, 40, 60, 80, 100].map(v => {
                const y = cPad.top + cPlotH - (v / 100) * cPlotH;
                return (
                  <g key={v}>
                    <line x1={cPad.left} y1={y} x2={cPad.left + cPlotW} y2={y} stroke="#f3f4f6" strokeWidth="0.5" className="dark:stroke-slate-700" />
                    <text x={cPad.left - 5} y={y + 3} textAnchor="end" fontSize="8" className="fill-gray-400 dark:fill-slate-500">{v}%</text>
                  </g>
                );
              })}

              {/* 바 그룹 */}
              {yearlyComparison.map((item, i) => {
                const groupX = cPad.left + i * barGroupWidth + barGroupWidth * 0.15;
                const barW = barGroupWidth * 0.3;
                const h1 = (item.rate / 100) * cPlotH;
                const h2 = (item.matchRate / 100) * cPlotH;
                const y1 = cPad.top + cPlotH - h1;
                const y2 = cPad.top + cPlotH - h2;

                return (
                  <g key={item.year}>
                    {/* 취업률 바 */}
                    <rect x={groupX} y={y1} width={barW} height={h1} rx="3" fill="#3b82f6" opacity="0.8" />
                    <text x={groupX + barW / 2} y={y1 - 5} textAnchor="middle" fontSize="8" className="fill-blue-600 dark:fill-blue-400" fontWeight="bold">{item.rate}%</text>

                    {/* 전공일치 취업률 바 */}
                    <rect x={groupX + barW + 4} y={y2} width={barW} height={h2} rx="3" fill="#22c55e" opacity="0.8" />
                    <text x={groupX + barW + 4 + barW / 2} y={y2 - 5} textAnchor="middle" fontSize="8" className="fill-green-600 dark:fill-green-400" fontWeight="bold">{item.matchRate}%</text>

                    {/* X축 라벨 */}
                    <text x={groupX + barW + 2} y={cPad.top + cPlotH + 16} textAnchor="middle" fontSize="10" className="fill-gray-500 dark:fill-slate-400">{item.year}</text>
                  </g>
                );
              })}
            </svg>
          </div>
          <div className="flex items-center justify-center gap-6 text-xs">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded bg-blue-500" />
              <span className="text-gray-600 dark:text-slate-400">전체 취업률</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded bg-green-500" />
              <span className="text-gray-600 dark:text-slate-400">전공일치 취업률</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
