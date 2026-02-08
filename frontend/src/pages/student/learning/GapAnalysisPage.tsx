// pages/student/learning/GapAnalysisPage.tsx — STD-L01: 역량 Gap 분석
import { useState } from 'react';
import {
  Target, AlertTriangle, CheckCircle2, ChevronRight, BookOpen,
  TrendingUp, BarChart3, Filter,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
interface NcsJob {
  code: string;
  name: string;
  category: string;
}

interface CompetencyItem {
  name: string;
  required: number;  // 0~100 요구 수준
  owned: number;     // 0~100 보유 수준
  gap: number;       // required - owned
  priority: '높음' | '보통' | '낮음';
}

const ncsJobs: NcsJob[] = [
  { code: '20010101', name: '응용SW엔지니어링', category: '정보통신' },
  { code: '20010203', name: 'DB엔지니어링', category: '정보통신' },
  { code: '20010302', name: '빅데이터분석', category: '정보통신' },
  { code: '20010401', name: 'IT시스템관리', category: '정보통신' },
  { code: '20010103', name: 'UI/UX엔지니어링', category: '정보통신' },
  { code: '20010402', name: '클라우드엔지니어링', category: '정보통신' },
  { code: '19010101', name: '전력설비운영', category: '전기전자' },
  { code: '15020101', name: '기계설계', category: '기계' },
];

// 직무별 역량 데이터
const competencyDataByJob: Record<string, CompetencyItem[]> = {
  '20010101': [
    { name: 'Java', required: 90, owned: 85, gap: 5, priority: '낮음' },
    { name: 'Spring Boot', required: 85, owned: 80, gap: 5, priority: '낮음' },
    { name: 'SQL/DB', required: 80, owned: 78, gap: 2, priority: '낮음' },
    { name: 'Git/협업도구', required: 75, owned: 88, gap: 0, priority: '낮음' },
    { name: 'RESTful API 설계', required: 85, owned: 70, gap: 15, priority: '보통' },
    { name: '테스트/TDD', required: 70, owned: 40, gap: 30, priority: '높음' },
    { name: 'Docker/컨테이너', required: 75, owned: 58, gap: 17, priority: '보통' },
    { name: 'CI/CD', required: 65, owned: 35, gap: 30, priority: '높음' },
    { name: 'AWS/클라우드', required: 70, owned: 45, gap: 25, priority: '높음' },
    { name: '시스템설계', required: 60, owned: 50, gap: 10, priority: '보통' },
  ],
  '20010302': [
    { name: 'Python', required: 95, owned: 90, gap: 5, priority: '낮음' },
    { name: 'SQL/DB', required: 90, owned: 78, gap: 12, priority: '보통' },
    { name: '통계학', required: 80, owned: 55, gap: 25, priority: '높음' },
    { name: '머신러닝', required: 85, owned: 68, gap: 17, priority: '보통' },
    { name: '데이터 전처리', required: 85, owned: 72, gap: 13, priority: '보통' },
    { name: '데이터 시각화', required: 75, owned: 60, gap: 15, priority: '보통' },
    { name: '딥러닝', required: 70, owned: 40, gap: 30, priority: '높음' },
    { name: 'Spark/빅데이터', required: 65, owned: 20, gap: 45, priority: '높음' },
    { name: 'BI 도구', required: 60, owned: 30, gap: 30, priority: '높음' },
    { name: '도메인 지식', required: 55, owned: 45, gap: 10, priority: '보통' },
  ],
};

// SVG 레이더 차트 컴포넌트
function RadarChart({ competencies }: { competencies: CompetencyItem[] }) {
  const size = 280;
  const center = size / 2;
  const maxRadius = 110;
  const items = competencies.slice(0, 8); // 최대 8개 표시
  const angleStep = (2 * Math.PI) / items.length;

  const getPoint = (index: number, value: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = (value / 100) * maxRadius;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  const requiredPoints = items.map((item, i) => getPoint(i, item.required));
  const ownedPoints = items.map((item, i) => getPoint(i, item.owned));

  const toPath = (points: { x: number; y: number }[]) =>
    points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ') + ' Z';

  return (
    <svg viewBox={`0 0 ${size} ${size}`} className="w-full max-w-[320px] mx-auto">
      {/* 배경 격자 */}
      {[20, 40, 60, 80, 100].map((level) => {
        const pts = items.map((_, i) => getPoint(i, level));
        return (
          <polygon
            key={level}
            points={pts.map(p => `${p.x},${p.y}`).join(' ')}
            fill="none"
            stroke="currentColor"
            className="text-gray-200 dark:text-slate-700"
            strokeWidth="0.5"
          />
        );
      })}

      {/* 축 선 */}
      {items.map((_, i) => {
        const end = getPoint(i, 100);
        return (
          <line
            key={i}
            x1={center} y1={center}
            x2={end.x} y2={end.y}
            stroke="currentColor"
            className="text-gray-200 dark:text-slate-700"
            strokeWidth="0.5"
          />
        );
      })}

      {/* 요구 수준 영역 */}
      <path
        d={toPath(requiredPoints)}
        fill="rgba(239, 68, 68, 0.1)"
        stroke="rgba(239, 68, 68, 0.6)"
        strokeWidth="1.5"
        strokeDasharray="4 2"
      />

      {/* 보유 수준 영역 */}
      <path
        d={toPath(ownedPoints)}
        fill="rgba(59, 130, 246, 0.15)"
        stroke="rgba(59, 130, 246, 0.8)"
        strokeWidth="2"
      />

      {/* 포인트 */}
      {ownedPoints.map((p, i) => (
        <circle key={`owned-${i}`} cx={p.x} cy={p.y} r="3" fill="#3B82F6" />
      ))}
      {requiredPoints.map((p, i) => (
        <circle key={`req-${i}`} cx={p.x} cy={p.y} r="2.5" fill="none" stroke="#EF4444" strokeWidth="1.5" />
      ))}

      {/* 라벨 */}
      {items.map((item, i) => {
        const labelPoint = getPoint(i, 120);
        return (
          <text
            key={`label-${i}`}
            x={labelPoint.x}
            y={labelPoint.y}
            textAnchor="middle"
            dominantBaseline="middle"
            className="fill-gray-500 dark:fill-slate-400"
            style={{ fontSize: '9px' }}
          >
            {item.name.length > 6 ? item.name.slice(0, 6) + '..' : item.name}
          </text>
        );
      })}
    </svg>
  );
}

function getGapColor(gap: number): string {
  if (gap >= 25) return 'text-danger-600';
  if (gap >= 10) return 'text-warning-600';
  return 'text-success-600';
}

function getGapBgColor(gap: number): string {
  if (gap >= 25) return 'bg-danger-50 dark:bg-danger-900/20 border-danger-100 dark:border-danger-800';
  if (gap >= 10) return 'bg-warning-50 dark:bg-warning-900/20 border-warning-100 dark:border-warning-800';
  return 'bg-success-50 dark:bg-success-900/20 border-success-100 dark:border-success-800';
}

export default function GapAnalysisPage() {
  const { t } = useTranslation();
  const [selectedJob, setSelectedJob] = useState('20010101');

  const currentJob = ncsJobs.find(j => j.code === selectedJob);
  const competencies = competencyDataByJob[selectedJob] || competencyDataByJob['20010101'];
  const avgGap = Math.round(competencies.reduce((sum, c) => sum + c.gap, 0) / competencies.length);
  const gapScore = Math.max(0, 100 - avgGap * 2);
  const highGapCount = competencies.filter(c => c.priority === '높음').length;
  const midGapCount = competencies.filter(c => c.priority === '보통').length;

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.gapAnalysisTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
            {t('student.gapAnalysisDesc')}
          </p>
        </div>
        <Link
          to="/learning/recommend"
          className="btn-primary text-xs flex items-center gap-1.5"
        >
          <BookOpen className="w-3.5 h-3.5" />
          추천 콘텐츠 보기
        </Link>
      </div>

      {/* 직무 선택 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row sm:items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-gray-500 shrink-0">
            <Filter className="w-3.5 h-3.5" />
            <span className="font-medium">NCS 직무 선택</span>
          </div>
          <select
            value={selectedJob}
            onChange={(e) => setSelectedJob(e.target.value)}
            className="input text-sm flex-1 max-w-md"
          >
            {ncsJobs.map(job => (
              <option key={job.code} value={job.code}>
                [{job.category}] {job.name} ({job.code})
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* 종합 점수 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-primary-50 dark:bg-primary-900/30">
              <Target className="w-4 h-4 text-primary-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">{gapScore}점</div>
          <div className="text-[10px] text-gray-500 mt-0.5">종합 준비도</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-danger-50 dark:bg-danger-900/30">
              <AlertTriangle className="w-4 h-4 text-danger-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-danger-600">{highGapCount}개</div>
          <div className="text-[10px] text-gray-500 mt-0.5">긴급 보완 역량</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-warning-50 dark:bg-warning-900/30">
              <BarChart3 className="w-4 h-4 text-warning-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-warning-600">{midGapCount}개</div>
          <div className="text-[10px] text-gray-500 mt-0.5">보통 Gap 역량</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-success-50 dark:bg-success-900/30">
              <TrendingUp className="w-4 h-4 text-success-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">{avgGap}%</div>
          <div className="text-[10px] text-gray-500 mt-0.5">평균 Gap</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 레이더 차트 */}
        <div className="card p-5 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">
              역량 레이더 차트 - {currentJob?.name}
            </h2>
          </div>
          <RadarChart competencies={competencies} />
          <div className="flex items-center justify-center gap-4">
            <div className="flex items-center gap-1.5 text-[10px] text-gray-500">
              <span className="w-3 h-0.5 bg-blue-500 rounded" />
              보유 수준
            </div>
            <div className="flex items-center gap-1.5 text-[10px] text-gray-500">
              <span className="w-3 h-0.5 bg-red-400 rounded border-dashed" style={{ borderTop: '1.5px dashed #EF4444' }} />
              요구 수준
            </div>
          </div>
        </div>

        {/* Gap 상세 리스트 */}
        <div className="card p-5 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">역량 Gap 상세</h2>
          <div className="space-y-2 max-h-[400px] overflow-y-auto">
            {[...competencies].sort((a, b) => b.gap - a.gap).map((item) => (
              <div
                key={item.name}
                className={`p-3 rounded-lg border ${getGapBgColor(item.gap)}`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-medium text-gray-900 dark:text-white">{item.name}</span>
                  <div className="flex items-center gap-2">
                    <span className={`text-[10px] font-bold ${getGapColor(item.gap)}`}>
                      {item.gap > 0 ? `Gap: -${item.gap}%` : '충족'}
                    </span>
                    <span className={`text-[9px] px-1.5 py-0.5 rounded-full ${
                      item.priority === '높음' ? 'bg-danger-100 text-danger-600 dark:bg-danger-900/30 dark:text-danger-400' :
                      item.priority === '보통' ? 'bg-warning-100 text-warning-600 dark:bg-warning-900/30 dark:text-warning-400' :
                      'bg-success-100 text-success-600 dark:bg-success-900/30 dark:text-success-400'
                    }`}>
                      {item.priority}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1">
                    <div className="flex justify-between text-[9px] text-gray-400 mb-0.5">
                      <span>보유: {item.owned}%</span>
                      <span>요구: {item.required}%</span>
                    </div>
                    <div className="relative w-full h-2 bg-gray-200 dark:bg-slate-700 rounded-full overflow-hidden">
                      <div
                        className="absolute h-full bg-blue-500 rounded-full"
                        style={{ width: `${item.owned}%` }}
                      />
                      <div
                        className="absolute h-full border-r-2 border-red-500"
                        style={{ width: `${item.required}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 개선 추천 */}
      <div className="card p-5 space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">Gap 해소 추천</h2>
          <Link
            to="/learning/recommend"
            className="text-xs text-primary-600 hover:underline flex items-center gap-1"
          >
            전체 추천 콘텐츠 <ChevronRight className="w-3 h-3" />
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {competencies
            .filter(c => c.priority === '높음')
            .map((item) => (
              <div
                key={item.name}
                className="p-3 border border-danger-100 dark:border-danger-800 bg-danger-50/50 dark:bg-danger-900/10 rounded-lg"
              >
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="w-3.5 h-3.5 text-danger-500" />
                  <span className="text-xs font-medium text-gray-900 dark:text-white">{item.name}</span>
                </div>
                <p className="text-[10px] text-gray-500 dark:text-slate-400 mb-2">
                  현재 {item.owned}% / 요구 {item.required}% (Gap: {item.gap}%)
                </p>
                <Link
                  to="/learning/recommend"
                  className="text-[10px] text-primary-600 hover:underline flex items-center gap-0.5"
                >
                  추천 학습 콘텐츠 보기 <ChevronRight className="w-2.5 h-2.5" />
                </Link>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
}
