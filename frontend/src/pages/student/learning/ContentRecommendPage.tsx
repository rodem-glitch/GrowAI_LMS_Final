// pages/student/learning/ContentRecommendPage.tsx — STD-L02: 콘텐츠 추천
import { useState } from 'react';
import {
  BookOpen, Play, Monitor, Star, ChevronRight, Filter,
  Clock, Tag, ExternalLink, ThumbsUp, Eye,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
type ContentType = '교내강좌' | '이러닝' | '동영상';

interface RecommendedContent {
  id: number;
  title: string;
  type: ContentType;
  provider: string;
  thumbnailColor: string;
  relevanceScore: number;
  reason: string;
  gapTag: string;
  duration: string;
  level: '초급' | '중급' | '고급';
  rating: number;
  views: number;
  url?: string;
}

const mockRecommendations: RecommendedContent[] = [
  {
    id: 1,
    title: 'Spring Boot 기반 TDD 실전 가이드',
    type: '이러닝',
    provider: 'K-MOOC',
    thumbnailColor: 'from-green-400 to-emerald-600',
    relevanceScore: 96,
    reason: '테스트/TDD 역량 Gap(30%)을 직접적으로 해소할 수 있는 핵심 콘텐츠입니다. JUnit5, Mockito를 활용한 실습 중심 강좌입니다.',
    gapTag: '테스트/TDD',
    duration: '총 40시간',
    level: '중급',
    rating: 4.7,
    views: 3420,
  },
  {
    id: 2,
    title: 'GitHub Actions로 배우는 CI/CD 파이프라인',
    type: '동영상',
    provider: 'YouTube (생활코딩)',
    thumbnailColor: 'from-red-400 to-pink-600',
    relevanceScore: 93,
    reason: 'CI/CD 역량 Gap(30%)을 해소하기 위한 추천 콘텐츠입니다. GitHub Actions 실습을 통해 자동 빌드/배포를 학습합니다.',
    gapTag: 'CI/CD',
    duration: '12시간',
    level: '초급',
    rating: 4.8,
    views: 15600,
  },
  {
    id: 3,
    title: 'AWS 핵심 서비스 마스터 클래스',
    type: '이러닝',
    provider: '인프런',
    thumbnailColor: 'from-orange-400 to-amber-600',
    relevanceScore: 90,
    reason: 'AWS/클라우드 역량 Gap(25%)을 해소합니다. EC2, S3, RDS, Lambda 등 핵심 서비스를 실전 프로젝트로 학습합니다.',
    gapTag: 'AWS/클라우드',
    duration: '총 32시간',
    level: '중급',
    rating: 4.6,
    views: 8900,
  },
  {
    id: 4,
    title: 'Docker & Kubernetes 실무 입문',
    type: '이러닝',
    provider: 'Udemy (한글자막)',
    thumbnailColor: 'from-blue-400 to-cyan-600',
    relevanceScore: 87,
    reason: 'Docker/컨테이너 역량 Gap(17%)을 해소합니다. 컨테이너 기초부터 쿠버네티스 클러스터 운영까지 학습합니다.',
    gapTag: 'Docker/컨테이너',
    duration: '총 25시간',
    level: '초급',
    rating: 4.5,
    views: 12300,
  },
  {
    id: 5,
    title: 'REST API 설계 베스트 프랙티스',
    type: '교내강좌',
    provider: '한국폴리텍대학 (2026-1학기)',
    thumbnailColor: 'from-purple-400 to-violet-600',
    relevanceScore: 85,
    reason: 'RESTful API 설계 역량 Gap(15%)을 해소합니다. 실무에서 바로 적용 가능한 API 설계 원칙과 문서화를 배웁니다.',
    gapTag: 'RESTful API 설계',
    duration: '15주 (3학점)',
    level: '중급',
    rating: 4.3,
    views: 450,
  },
  {
    id: 6,
    title: '시스템 설계 면접 완벽 가이드',
    type: '동영상',
    provider: 'YouTube (코드없는 프로그래밍)',
    thumbnailColor: 'from-indigo-400 to-blue-600',
    relevanceScore: 80,
    reason: '시스템설계 역량 Gap(10%)을 보강합니다. 대규모 시스템 아키텍처 설계 패턴과 트레이드오프를 학습합니다.',
    gapTag: '시스템설계',
    duration: '8시간',
    level: '고급',
    rating: 4.9,
    views: 25400,
  },
  {
    id: 7,
    title: 'Java 중급 - 디자인 패턴과 리팩토링',
    type: '교내강좌',
    provider: '한국폴리텍대학 (2026-1학기)',
    thumbnailColor: 'from-teal-400 to-green-600',
    relevanceScore: 75,
    reason: 'Java 역량을 상급 수준으로 끌어올리기 위한 추천 강좌입니다. GoF 디자인 패턴과 코드 리팩토링 기법을 학습합니다.',
    gapTag: 'Java',
    duration: '15주 (3학점)',
    level: '고급',
    rating: 4.4,
    views: 380,
  },
  {
    id: 8,
    title: 'SQL 성능 최적화 실전',
    type: '이러닝',
    provider: '패스트캠퍼스',
    thumbnailColor: 'from-yellow-400 to-orange-600',
    relevanceScore: 72,
    reason: 'SQL/DB 역량을 심화 학습하여 데이터 처리 효율을 높입니다. 인덱싱, 쿼리 최적화, 실행 계획 분석을 다룹니다.',
    gapTag: 'SQL/DB',
    duration: '총 20시간',
    level: '중급',
    rating: 4.6,
    views: 5600,
  },
];

const contentTypes: { label: string; value: ContentType | 'ALL' }[] = [
  { label: '전체', value: 'ALL' },
  { label: '교내강좌', value: '교내강좌' },
  { label: '이러닝', value: '이러닝' },
  { label: '동영상', value: '동영상' },
];

const typeIcons: Record<ContentType, typeof BookOpen> = {
  '교내강좌': BookOpen,
  '이러닝': Monitor,
  '동영상': Play,
};

const typeBadgeColor: Record<ContentType, string> = {
  '교내강좌': 'badge-success',
  '이러닝': 'badge-info',
  '동영상': 'badge-warning',
};

function getScoreColor(score: number): string {
  if (score >= 90) return 'text-success-600';
  if (score >= 80) return 'text-primary-600';
  return 'text-warning-600';
}

export default function ContentRecommendPage() {
  const { t } = useTranslation();
  const [typeFilter, setTypeFilter] = useState<ContentType | 'ALL'>('ALL');
  const [sortBy, setSortBy] = useState<'relevance' | 'rating' | 'views'>('relevance');

  let filtered = mockRecommendations.filter(
    (item) => typeFilter === 'ALL' || item.type === typeFilter
  );

  // 정렬
  if (sortBy === 'relevance') {
    filtered.sort((a, b) => b.relevanceScore - a.relevanceScore);
  } else if (sortBy === 'rating') {
    filtered.sort((a, b) => b.rating - a.rating);
  } else if (sortBy === 'views') {
    filtered.sort((a, b) => b.views - a.views);
  }

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.contentRecommendTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
            {t('student.contentRecommendDesc')}
          </p>
        </div>
        <span className="badge-sm badge-info flex items-center gap-1">
          <BookOpen className="w-3 h-3" />
          {filtered.length}개 추천
        </span>
      </div>

      {/* 필터 & 정렬 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 text-xs text-gray-500">
              <Filter className="w-3.5 h-3.5" />
              <span>유형:</span>
            </div>
            <div className="filter-bar">
              {contentTypes.map((ct) => (
                <button
                  key={ct.value}
                  onClick={() => setTypeFilter(ct.value)}
                  className={`filter-chip ${typeFilter === ct.value ? 'filter-chip-active' : 'filter-chip-inactive'}`}
                >
                  {ct.value !== 'ALL' && (() => {
                    const Icon = typeIcons[ct.value as ContentType];
                    return <Icon className="w-3 h-3" />;
                  })()}
                  {ct.label}
                </button>
              ))}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-gray-400">정렬:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
              className="input text-xs py-1"
            >
              <option value="relevance">관련도순</option>
              <option value="rating">평점순</option>
              <option value="views">조회순</option>
            </select>
          </div>
        </div>
      </div>

      {/* 콘텐츠 카드 리스트 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.map((item) => {
          const TypeIcon = typeIcons[item.type];
          return (
            <div key={item.id} className="card p-0 overflow-hidden hover:shadow-card-hover transition-shadow">
              {/* 썸네일 */}
              <div className={`h-32 bg-gradient-to-br ${item.thumbnailColor} flex items-center justify-center relative`}>
                <TypeIcon className="w-10 h-10 text-white/50" />
                {/* 관련도 스코어 뱃지 */}
                <div className="absolute top-2 right-2 bg-white/90 dark:bg-slate-900/90 backdrop-blur-sm rounded-lg px-2 py-1 flex items-center gap-1">
                  <Star className={`w-3 h-3 ${getScoreColor(item.relevanceScore)}`} />
                  <span className={`text-xs font-bold ${getScoreColor(item.relevanceScore)}`}>
                    {item.relevanceScore}%
                  </span>
                </div>
                {/* 유형 뱃지 */}
                <div className="absolute top-2 left-2">
                  <span className={`badge-sm ${typeBadgeColor[item.type]}`}>
                    {item.type}
                  </span>
                </div>
                {/* Gap 태그 */}
                <div className="absolute bottom-2 left-2">
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-white/90 dark:bg-slate-900/90 text-gray-700 dark:text-slate-300 flex items-center gap-1 backdrop-blur-sm">
                    <Tag className="w-2.5 h-2.5" />
                    {item.gapTag}
                  </span>
                </div>
              </div>

              {/* 콘텐츠 정보 */}
              <div className="p-4 space-y-3">
                <div>
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                    {item.title}
                  </h3>
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[10px] text-gray-500 dark:text-slate-400">
                    <span>{item.provider}</span>
                    <span className="flex items-center gap-0.5">
                      <Clock className="w-2.5 h-2.5" />
                      {item.duration}
                    </span>
                    <span className={`px-1.5 py-0.5 rounded text-[9px] font-medium ${
                      item.level === '초급' ? 'bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400' :
                      item.level === '중급' ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400' :
                      'bg-purple-50 text-purple-600 dark:bg-purple-900/20 dark:text-purple-400'
                    }`}>
                      {item.level}
                    </span>
                  </div>
                </div>

                {/* 추천 사유 */}
                <div className="p-2.5 bg-surface-muted dark:bg-slate-800 rounded-lg">
                  <div className="flex items-start gap-1.5">
                    <ChevronRight className="w-3 h-3 text-primary-500 mt-0.5 shrink-0" />
                    <p className="text-[11px] text-gray-600 dark:text-slate-400 leading-relaxed">
                      {item.reason}
                    </p>
                  </div>
                </div>

                {/* 메타 정보 & 액션 */}
                <div className="flex items-center justify-between pt-2 border-t border-gray-50 dark:border-slate-800">
                  <div className="flex items-center gap-3 text-[10px] text-gray-400">
                    <span className="flex items-center gap-0.5">
                      <Star className="w-3 h-3 text-warning-400 fill-warning-400" />
                      {item.rating}
                    </span>
                    <span className="flex items-center gap-0.5">
                      <Eye className="w-3 h-3" />
                      {item.views.toLocaleString()}
                    </span>
                    <span className="flex items-center gap-0.5">
                      <ThumbsUp className="w-3 h-3" />
                      추천
                    </span>
                  </div>
                  <button className="btn-sm btn-primary text-[10px] flex items-center gap-1">
                    {item.type === '교내강좌' ? (
                      <>수강 신청 <ChevronRight className="w-3 h-3" /></>
                    ) : (
                      <>바로가기 <ExternalLink className="w-3 h-3" /></>
                    )}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {filtered.length === 0 && (
        <div className="card p-8 text-center">
          <BookOpen className="w-8 h-8 text-gray-300 mx-auto mb-2" />
          <p className="text-sm text-gray-500">해당 유형의 추천 콘텐츠가 없습니다.</p>
        </div>
      )}

      {/* 하단 안내 */}
      <div className="card p-4 bg-gradient-to-br from-primary-50 to-secondary-50 dark:from-primary-900/10 dark:to-secondary-900/10 border-primary-100 dark:border-primary-800">
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 rounded-lg bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center shrink-0">
            <Star className="w-4 h-4 text-primary-600" />
          </div>
          <div>
            <h3 className="text-xs font-semibold text-primary-700 dark:text-primary-400 mb-1">
              추천 알고리즘 안내
            </h3>
            <p className="text-[10px] text-gray-600 dark:text-slate-400 leading-relaxed">
              추천 콘텐츠는 NCS 역량 Gap 분석 결과, 학습 이력, 보유 역량 태그를 종합적으로 분석하여
              AI가 자동으로 선정합니다. 관련도 점수가 높을수록 역량 Gap 해소에 효과적인 콘텐츠입니다.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
