// pages/student/learning/GapAnalysisPage.tsx — STD-L01: 역량 Gap 분석
import { useState } from 'react';
import {
  Target, AlertTriangle, CheckCircle2, ChevronRight, BookOpen,
  TrendingUp, BarChart3, Filter, X, ExternalLink, Clock, Star, Play,
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

// 역량별 추천 학습 콘텐츠 상세 데이터
interface RecommendContent {
  id: number;
  title: string;
  provider: string;
  type: '강좌' | '자격증' | '실습' | '도서';
  duration: string;
  rating: number;
  level: '입문' | '초급' | '중급' | '고급';
  url: string;
  description: string;
}

const recommendBySkill: Record<string, RecommendContent[]> = {
  '테스트/TDD': [
    { id: 1, title: 'JUnit5와 Mockito로 배우는 TDD', provider: 'Inflearn', type: '강좌', duration: '24시간', rating: 4.8, level: '중급', url: 'https://inflearn.com', description: '단위 테스트, 통합 테스트, TDD 사이클을 실무 프로젝트와 함께 학습합니다.' },
    { id: 2, title: 'Spring Boot 테스트 전략', provider: 'FastCampus', type: '강좌', duration: '18시간', rating: 4.6, level: '중급', url: 'https://fastcampus.co.kr', description: 'Spring Boot 환경에서의 슬라이스 테스트, MockMvc, TestContainers 활용법을 배웁니다.' },
    { id: 3, title: '클린 코드를 위한 테스트 기법', provider: 'YES24', type: '도서', duration: '약 2주', rating: 4.7, level: '초급', url: 'https://yes24.com', description: '테스트 주도 개발의 이론과 실제를 예제와 함께 학습할 수 있는 도서입니다.' },
    { id: 4, title: 'ISTQB CTFL 자격증 대비', provider: 'KSTQB', type: '자격증', duration: '40시간', rating: 4.5, level: '초급', url: 'https://kstqb.org', description: '국제 소프트웨어 테스팅 자격 기초 레벨 시험 대비 과정입니다.' },
  ],
  'CI/CD': [
    { id: 5, title: 'GitHub Actions 마스터 클래스', provider: 'Udemy', type: '강좌', duration: '16시간', rating: 4.7, level: '중급', url: 'https://udemy.com', description: 'GitHub Actions를 활용한 CI/CD 파이프라인 구축과 자동 배포를 학습합니다.' },
    { id: 6, title: 'Jenkins & Docker CI/CD 파이프라인', provider: 'Inflearn', type: '강좌', duration: '20시간', rating: 4.5, level: '중급', url: 'https://inflearn.com', description: 'Jenkins와 Docker를 연동하여 실무 CI/CD 환경을 구축하는 과정입니다.' },
    { id: 7, title: 'DevOps 실습 프로젝트', provider: 'KPOLY', type: '실습', duration: '30시간', rating: 4.9, level: '고급', url: '#', description: '실제 프로젝트에 CI/CD, 모니터링, IaC를 적용하는 종합 실습 과정입니다.' },
  ],
  'AWS/클라우드': [
    { id: 8, title: 'AWS SAA 자격증 완벽 대비', provider: 'Inflearn', type: '자격증', duration: '35시간', rating: 4.8, level: '중급', url: 'https://inflearn.com', description: 'AWS Solutions Architect Associate 시험 대비 핵심 서비스 학습 과정입니다.' },
    { id: 9, title: 'AWS로 시작하는 클라우드 입문', provider: 'FastCampus', type: '강좌', duration: '22시간', rating: 4.6, level: '입문', url: 'https://fastcampus.co.kr', description: 'EC2, S3, RDS 등 핵심 서비스와 VPC 네트워크 설계를 학습합니다.' },
    { id: 10, title: 'GCP 클라우드 엔지니어 과정', provider: 'Coursera', type: '강좌', duration: '40시간', rating: 4.7, level: '중급', url: 'https://coursera.org', description: 'Google Cloud Platform의 핵심 인프라 서비스를 학습하는 과정입니다.' },
    { id: 11, title: '클라우드 네이티브 아키텍처', provider: 'YES24', type: '도서', duration: '약 3주', rating: 4.4, level: '고급', url: 'https://yes24.com', description: '마이크로서비스, 컨테이너, 서버리스 아키텍처를 포괄하는 클라우드 네이티브 설계 가이드입니다.' },
  ],
  'Docker/컨테이너': [
    { id: 12, title: 'Docker & Kubernetes 실전 가이드', provider: 'Udemy', type: '강좌', duration: '28시간', rating: 4.8, level: '중급', url: 'https://udemy.com', description: 'Docker 기초부터 Kubernetes 클러스터 운영까지 실전 위주로 학습합니다.' },
    { id: 13, title: '컨테이너 인프라 환경 구축을 위한 쿠버네티스', provider: 'YES24', type: '도서', duration: '약 3주', rating: 4.6, level: '중급', url: 'https://yes24.com', description: 'Kubernetes 기반 인프라 환경 구축의 A to Z를 다루는 도서입니다.' },
  ],
  'RESTful API 설계': [
    { id: 14, title: 'RESTful API 설계 Best Practice', provider: 'Inflearn', type: '강좌', duration: '12시간', rating: 4.7, level: '초급', url: 'https://inflearn.com', description: 'REST 아키텍처 원칙, HTTP 메서드, 상태 코드, HATEOAS 등을 학습합니다.' },
    { id: 15, title: 'Spring REST Docs로 API 문서 자동화', provider: 'KPOLY', type: '실습', duration: '8시간', rating: 4.5, level: '중급', url: '#', description: 'Spring REST Docs를 활용한 API 문서 자동 생성 실습 과정입니다.' },
  ],
  '통계학': [
    { id: 16, title: '데이터 분석을 위한 통계학 입문', provider: 'Coursera', type: '강좌', duration: '30시간', rating: 4.6, level: '입문', url: 'https://coursera.org', description: '기술 통계, 확률 분포, 가설 검정 등 데이터 분석에 필요한 통계 기초를 학습합니다.' },
    { id: 17, title: '파이썬으로 배우는 통계분석', provider: 'Inflearn', type: '강좌', duration: '20시간', rating: 4.5, level: '초급', url: 'https://inflearn.com', description: 'NumPy, SciPy를 활용한 통계 분석 실습 과정입니다.' },
  ],
  '딥러닝': [
    { id: 18, title: 'PyTorch로 시작하는 딥러닝', provider: 'FastCampus', type: '강좌', duration: '35시간', rating: 4.7, level: '중급', url: 'https://fastcampus.co.kr', description: 'CNN, RNN, Transformer 등 핵심 딥러닝 모델을 PyTorch로 구현합니다.' },
    { id: 19, title: '딥러닝 논문 리뷰 스터디', provider: 'KPOLY', type: '실습', duration: '16시간', rating: 4.8, level: '고급', url: '#', description: '최신 딥러닝 논문을 읽고 구현하는 세미나 형식의 스터디 과정입니다.' },
  ],
  'Spark/빅데이터': [
    { id: 20, title: 'Apache Spark 완벽 가이드', provider: 'Udemy', type: '강좌', duration: '25시간', rating: 4.6, level: '중급', url: 'https://udemy.com', description: 'Spark Core, Spark SQL, Spark Streaming을 실습 중심으로 학습합니다.' },
    { id: 21, title: '빅데이터 파이프라인 구축 실습', provider: 'KPOLY', type: '실습', duration: '40시간', rating: 4.7, level: '고급', url: '#', description: 'Kafka, Spark, Airflow를 연동한 데이터 파이프라인 구축 실습입니다.' },
  ],
  'BI 도구': [
    { id: 22, title: 'Tableau 데이터 시각화 마스터', provider: 'Coursera', type: '강좌', duration: '20시간', rating: 4.5, level: '초급', url: 'https://coursera.org', description: 'Tableau를 활용한 대시보드 설계와 인터랙티브 시각화를 학습합니다.' },
    { id: 23, title: 'Power BI 실무 활용', provider: 'Inflearn', type: '강좌', duration: '15시간', rating: 4.4, level: '초급', url: 'https://inflearn.com', description: 'Microsoft Power BI를 활용한 비즈니스 데이터 분석 및 리포트 작성 과정입니다.' },
  ],
};

function getTypeIcon(type: string) {
  switch (type) {
    case '강좌': return Play;
    case '자격증': return Star;
    case '실습': return Target;
    case '도서': return BookOpen;
    default: return BookOpen;
  }
}

function getTypeBadgeStyle(type: string) {
  switch (type) {
    case '강좌': return 'bg-primary-50 text-primary-600 dark:bg-primary-900/20 dark:text-primary-400';
    case '자격증': return 'bg-warning-50 text-warning-600 dark:bg-warning-900/20 dark:text-warning-400';
    case '실습': return 'bg-success-50 text-success-600 dark:bg-success-900/20 dark:text-success-400';
    case '도서': return 'bg-purple-50 text-purple-600 dark:bg-purple-900/20 dark:text-purple-400';
    default: return 'bg-gray-50 text-gray-600';
  }
}

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
  const [popupSkill, setPopupSkill] = useState<string | null>(null);

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
                <button
                  onClick={() => setPopupSkill(item.name)}
                  className="text-[10px] text-primary-600 hover:underline flex items-center gap-0.5 cursor-pointer"
                >
                  추천 학습 콘텐츠 보기 <ChevronRight className="w-2.5 h-2.5" />
                </button>
              </div>
            ))}
        </div>
      </div>

      {/* 추천 콘텐츠 상세 팝업 */}
      {popupSkill && (
        <div className="fixed inset-0 z-[100] flex items-start justify-center pt-16 bg-black/40 backdrop-blur-sm"
          onClick={() => setPopupSkill(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-2xl mx-4 max-h-[80vh] flex flex-col animate-in slide-in-from-top-4 fade-in duration-300"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700 shrink-0">
              <h2 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-danger-500" />
                <span>{popupSkill}</span>
                <span className="text-[10px] font-normal text-gray-400 ml-1">Gap 해소 추천 콘텐츠</span>
              </h2>
              <button onClick={() => setPopupSkill(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            {/* 역량 현황 요약 */}
            {(() => {
              const comp = competencies.find(c => c.name === popupSkill);
              if (!comp) return null;
              return (
                <div className="px-6 py-3 bg-danger-50/50 dark:bg-danger-900/10 border-b border-gray-100 dark:border-gray-700">
                  <div className="flex items-center justify-between text-xs">
                    <div className="flex items-center gap-4">
                      <span className="text-gray-600 dark:text-slate-400">보유: <strong className="text-primary-600">{comp.owned}%</strong></span>
                      <span className="text-gray-600 dark:text-slate-400">요구: <strong className="text-danger-600">{comp.required}%</strong></span>
                      <span className="text-danger-600 font-bold">Gap: -{comp.gap}%</span>
                    </div>
                    <span className="text-[9px] px-2 py-0.5 rounded-full bg-danger-100 text-danger-600 dark:bg-danger-900/30 dark:text-danger-400 font-medium">
                      우선순위: {comp.priority}
                    </span>
                  </div>
                  <div className="relative w-full h-2 bg-gray-200 dark:bg-slate-700 rounded-full overflow-hidden mt-2">
                    <div className="absolute h-full bg-primary-500 rounded-full transition-all duration-500" style={{ width: `${comp.owned}%` }} />
                    <div className="absolute h-full border-r-2 border-danger-500" style={{ width: `${comp.required}%` }} />
                  </div>
                </div>
              );
            })()}

            <div className="overflow-y-auto flex-1 px-6 py-4 space-y-3">
              {(recommendBySkill[popupSkill] || []).map((rec) => {
                const TypeIcon = getTypeIcon(rec.type);
                return (
                  <div key={rec.id} className="p-4 rounded-xl border border-gray-100 dark:border-slate-700 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-800 transition-all group">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <div className="p-1.5 rounded-lg bg-primary-50 dark:bg-primary-900/30">
                          <TypeIcon className="w-3.5 h-3.5 text-primary-600" />
                        </div>
                        <div>
                          <h3 className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">{rec.title}</h3>
                          <div className="flex items-center gap-2 mt-0.5">
                            <span className="text-[10px] text-gray-400">{rec.provider}</span>
                            <span className={`text-[9px] px-1.5 py-0.5 rounded-full font-medium ${getTypeBadgeStyle(rec.type)}`}>{rec.type}</span>
                          </div>
                        </div>
                      </div>
                      {rec.url !== '#' && (
                        <a href={rec.url} target="_blank" rel="noopener noreferrer"
                          className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors opacity-0 group-hover:opacity-100">
                          <ExternalLink className="w-3.5 h-3.5 text-gray-400" />
                        </a>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-slate-400 leading-relaxed mb-2">{rec.description}</p>
                    <div className="flex items-center gap-3 text-[10px] text-gray-400">
                      <span className="flex items-center gap-0.5"><Clock className="w-3 h-3" />{rec.duration}</span>
                      <span className="flex items-center gap-0.5"><Star className="w-3 h-3 text-warning-400" />{rec.rating}</span>
                      <span className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-slate-700 text-gray-500 dark:text-slate-400">{rec.level}</span>
                    </div>
                  </div>
                );
              })}
              {(!recommendBySkill[popupSkill] || recommendBySkill[popupSkill].length === 0) && (
                <div className="text-center py-8 text-sm text-gray-400">
                  <BookOpen className="w-8 h-8 mx-auto mb-2 text-gray-300" />
                  추천 콘텐츠 준비 중입니다.
                </div>
              )}
            </div>

            <div className="px-6 py-3 border-t border-gray-100 dark:border-gray-700 shrink-0 flex items-center justify-between">
              <span className="text-[10px] text-gray-400">
                {(recommendBySkill[popupSkill] || []).length}개 추천 콘텐츠
              </span>
              <div className="flex items-center gap-2">
                <Link to="/learning/recommend" className="btn-sm btn-secondary text-xs flex items-center gap-1"
                  onClick={() => setPopupSkill(null)}>
                  <BookOpen className="w-3 h-3" />전체 추천 보기
                </Link>
                <button onClick={() => setPopupSkill(null)} className="btn-primary text-xs px-4">닫기</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
