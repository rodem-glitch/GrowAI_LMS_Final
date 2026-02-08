// pages/common/SearchPage.tsx — COM-005: 통합 검색 페이지
import { useState, useMemo, useRef, useEffect } from 'react';
import {
  Search,
  BookOpen,
  Briefcase,
  MessageSquare,
  HelpCircle,
  X,
  Clock,
  TrendingUp,
  ArrowRight,
  SlidersHorizontal,
  Sparkles,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

/**
 * 통합 검색 페이지
 * - 검색 입력 + 자동완성 드롭다운
 * - 카테고리 탭 필터 (전체/강좌/채용공고/게시판/도움말)
 * - 결과 카테고리별 그룹핑
 * - 추천 검색어 칩
 * - 최근 검색 기록
 */

type Category = 'ALL' | 'COURSE' | 'JOB' | 'BOARD' | 'HELP';

interface SearchResult {
  id: number;
  category: Category;
  title: string;
  snippet: string;
  link: string;
  matchHighlight: string; // 매칭 하이라이트 키워드
  date?: string;
}

interface CategoryTab {
  key: Category;
  label: string;
  icon: React.ElementType;
  count: number;
}

// Mock 검색 결과 (12개)
const mockResults: SearchResult[] = [
  {
    id: 1,
    category: 'COURSE',
    title: 'AI 머신러닝 실습 - 기초부터 응용까지',
    snippet:
      '인공지능의 핵심 알고리즘인 머신러닝을 실습 중심으로 학습합니다. Python과 TensorFlow를 활용한 프로젝트 포함.',
    link: '/student/courses/AI201',
    matchHighlight: 'AI',
    date: '2026학년도 1학기',
  },
  {
    id: 2,
    category: 'COURSE',
    title: '파이썬 프로그래밍 기초',
    snippet:
      '프로그래밍 입문자를 위한 파이썬 기초 과정. 변수, 조건문, 반복문부터 함수, 클래스까지 단계별 학습.',
    link: '/student/courses/CS101',
    matchHighlight: '파이썬',
    date: '2026학년도 1학기',
  },
  {
    id: 3,
    category: 'COURSE',
    title: 'AI 딥러닝 프로젝트',
    snippet:
      'CNN, RNN, Transformer 등 딥러닝 모델을 직접 구현하고 실제 데이터에 적용하는 프로젝트형 수업.',
    link: '/student/courses/AI302',
    matchHighlight: 'AI',
    date: '2026학년도 1학기',
  },
  {
    id: 4,
    category: 'JOB',
    title: '삼성전자 2026 상반기 신입 공채',
    snippet:
      'DX 부문 소프트웨어 개발 직군 모집. AI/ML, 클라우드, 임베디드 분야. 지원 마감 D-3.',
    link: '/student/job/apply/101',
    matchHighlight: 'AI',
    date: '~2026.02.11',
  },
  {
    id: 5,
    category: 'JOB',
    title: 'LG CNS 하계 인턴 모집',
    snippet:
      'IT 서비스 분야 인턴 모집. AI 솔루션 개발, 데이터 분석 직무. 서류 전형 → 코딩테스트 → 면접.',
    link: '/student/job/apply/102',
    matchHighlight: 'AI',
    date: '~2026.03.01',
  },
  {
    id: 6,
    category: 'JOB',
    title: '네이버 클라우드 경력/신입 상시 채용',
    snippet:
      'NCP 관련 백엔드, 프론트엔드, DevOps 엔지니어 상시 모집. AI 플랫폼 개발팀 포함.',
    link: '/student/job/apply/103',
    matchHighlight: 'AI',
    date: '상시',
  },
  {
    id: 7,
    category: 'BOARD',
    title: '[Q&A] AI 과제 제출 형식 문의',
    snippet:
      '머신러닝 실습 3주차 과제 제출 시 주피터 노트북(.ipynb) 형식으로 제출해야 하나요?',
    link: '/student/board/42',
    matchHighlight: 'AI',
    date: '2026.02.07',
  },
  {
    id: 8,
    category: 'BOARD',
    title: '[공지] AI 특강 안내 - ChatGPT 활용법',
    snippet:
      '2026년 2월 15일 14:00 ~ 16:00 온라인 특강이 진행됩니다. AI 도구를 학습에 활용하는 방법을 안내합니다.',
    link: '/student/board/43',
    matchHighlight: 'AI',
    date: '2026.02.06',
  },
  {
    id: 9,
    category: 'BOARD',
    title: '[후기] AI 교육 수강 후기 및 학습 팁 공유',
    snippet:
      'AI 머신러닝 실습을 수강한 학생의 후기입니다. 학습 자료 추천과 효율적인 학습 방법을 공유합니다.',
    link: '/student/board/44',
    matchHighlight: 'AI',
    date: '2026.02.05',
  },
  {
    id: 10,
    category: 'HELP',
    title: 'AI 학습 도우미 사용 가이드',
    snippet:
      'GrowAI LMS의 AI 챗봇 학습 도우미 사용법을 안내합니다. 질문 작성법, 코드 리뷰 요청 방법 등.',
    link: '/help/ai-assistant',
    matchHighlight: 'AI',
    date: '',
  },
  {
    id: 11,
    category: 'HELP',
    title: '강좌 수강신청 방법 안내',
    snippet:
      '수강신청 절차, 수강 변경 및 취소 방법, 수강료 환불 규정 등을 안내합니다.',
    link: '/help/enrollment',
    matchHighlight: '수강',
    date: '',
  },
  {
    id: 12,
    category: 'HELP',
    title: 'NCS 자격증 취득 로드맵',
    snippet:
      'NCS 기반 국가 자격증 취득을 위한 단계별 학습 로드맵과 추천 과정을 안내합니다.',
    link: '/help/ncs-roadmap',
    matchHighlight: '자격증',
    date: '',
  },
];

// 추천 검색어
const suggestedKeywords = [
  'AI교육',
  '파이썬',
  '취업',
  'NCS',
  '자격증',
  '데이터분석',
  '클라우드',
  '정보보안',
];

// 자동완성 목록
const autocompleteSuggestions = [
  'AI 머신러닝',
  'AI 딥러닝',
  'AI 학습 도우미',
  'AI 교육 과정',
  'AI 채용 공고',
];

// 최근 검색 기록
const recentSearches = [
  '파이썬 기초',
  '삼성전자 채용',
  'AI 과제',
  '수강신청 방법',
];

// 카테고리 설정
const categoryConfig: Record<
  Exclude<Category, 'ALL'>,
  { icon: React.ElementType; color: string; bgColor: string; label: string }
> = {
  COURSE: {
    icon: BookOpen,
    color: 'text-blue-600',
    bgColor: 'bg-blue-100 dark:bg-blue-900/30',
    label: '강좌',
  },
  JOB: {
    icon: Briefcase,
    color: 'text-orange-600',
    bgColor: 'bg-orange-100 dark:bg-orange-900/30',
    label: '채용공고',
  },
  BOARD: {
    icon: MessageSquare,
    color: 'text-green-600',
    bgColor: 'bg-green-100 dark:bg-green-900/30',
    label: '게시판',
  },
  HELP: {
    icon: HelpCircle,
    color: 'text-purple-600',
    bgColor: 'bg-purple-100 dark:bg-purple-900/30',
    label: '도움말',
  },
};

export default function SearchPage() {
  const { t } = useTranslation();
  const [query, setQuery] = useState('AI');
  const [activeTab, setActiveTab] = useState<Category>('ALL');
  const [showAutocomplete, setShowAutocomplete] = useState(false);
  const [searches, setSearches] = useState<string[]>(recentSearches);
  const inputRef = useRef<HTMLInputElement>(null);

  // 탭별 카운트 계산
  const tabs: CategoryTab[] = useMemo(() => {
    const courseCount = mockResults.filter((r) => r.category === 'COURSE').length;
    const jobCount = mockResults.filter((r) => r.category === 'JOB').length;
    const boardCount = mockResults.filter((r) => r.category === 'BOARD').length;
    const helpCount = mockResults.filter((r) => r.category === 'HELP').length;
    return [
      { key: 'ALL', label: '전체', icon: Search, count: mockResults.length },
      { key: 'COURSE', label: '강좌', icon: BookOpen, count: courseCount },
      { key: 'JOB', label: '채용공고', icon: Briefcase, count: jobCount },
      { key: 'BOARD', label: '게시판', icon: MessageSquare, count: boardCount },
      { key: 'HELP', label: '도움말', icon: HelpCircle, count: helpCount },
    ];
  }, []);

  // 필터된 결과
  const filteredResults = useMemo(() => {
    if (activeTab === 'ALL') return mockResults;
    return mockResults.filter((r) => r.category === activeTab);
  }, [activeTab]);

  // 카테고리별 그룹핑 (전체 탭에서)
  const groupedResults = useMemo(() => {
    if (activeTab !== 'ALL') return null;
    const groups: Record<string, SearchResult[]> = {};
    mockResults.forEach((r) => {
      if (!groups[r.category]) groups[r.category] = [];
      groups[r.category].push(r);
    });
    return groups;
  }, [activeTab]);

  // 자동완성 필터
  const filteredSuggestions = autocompleteSuggestions.filter((s) =>
    s.toLowerCase().includes(query.toLowerCase())
  );

  // 검색어 선택 핸들러
  const handleSelectSuggestion = (term: string) => {
    setQuery(term);
    setShowAutocomplete(false);
    if (!searches.includes(term)) {
      setSearches((prev) => [term, ...prev].slice(0, 5));
    }
  };

  // 최근 검색 삭제
  const removeRecentSearch = (term: string) => {
    setSearches((prev) => prev.filter((s) => s !== term));
  };

  // 외부 클릭 시 자동완성 닫기
  useEffect(() => {
    const handler = () => setShowAutocomplete(false);
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, []);

  // 제목에서 검색어 하이라이트
  const highlightMatch = (text: string, keyword: string) => {
    if (!keyword) return text;
    const idx = text.toLowerCase().indexOf(keyword.toLowerCase());
    if (idx === -1) return text;
    return (
      <>
        {text.slice(0, idx)}
        <mark className="bg-yellow-200 dark:bg-yellow-700 text-inherit rounded px-0.5">
          {text.slice(idx, idx + keyword.length)}
        </mark>
        {text.slice(idx + keyword.length)}
      </>
    );
  };

  // 결과 아이템 렌더링
  const renderResultItem = (result: SearchResult) => {
    const config = categoryConfig[result.category as Exclude<Category, 'ALL'>];
    const Icon = config.icon;

    return (
      <a
        key={result.id}
        href={result.link}
        className="flex items-start gap-3 p-4 rounded-xl hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors group"
      >
        {/* 아이콘 */}
        <div
          className={`w-10 h-10 rounded-lg ${config.bgColor} flex items-center justify-center shrink-0`}
        >
          <Icon className={`w-5 h-5 ${config.color}`} />
        </div>

        {/* 내용 */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span
              className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${config.bgColor} ${config.color}`}
            >
              {config.label}
            </span>
            {result.date && (
              <span className="text-[10px] text-gray-400">{result.date}</span>
            )}
          </div>
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 transition-colors">
            {highlightMatch(result.title, query)}
          </h4>
          <p className="text-[12px] text-gray-500 dark:text-slate-400 mt-0.5 line-clamp-2 leading-relaxed">
            {result.snippet}
          </p>
        </div>

        {/* 화살표 */}
        <ArrowRight className="w-4 h-4 text-gray-300 shrink-0 mt-3 opacity-0 group-hover:opacity-100 transition-opacity" />
      </a>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* 검색 헤더 */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-100 dark:border-slate-700">
        <div className="max-w-4xl mx-auto px-4 py-8">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-1">
            {t('common.search')}
          </h1>
          <p className="text-sm text-gray-500 dark:text-slate-400 mb-6">
            강좌, 채용공고, 게시판, 도움말을 한 곳에서 검색합니다
          </p>

          {/* 검색 입력 */}
          <div className="relative" onClick={(e) => e.stopPropagation()}>
            <div className="relative flex items-center">
              <Search className="absolute left-4 w-5 h-5 text-gray-400" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onFocus={() => setShowAutocomplete(true)}
                placeholder="검색어를 입력하세요..."
                className="w-full pl-12 pr-24 py-3.5 rounded-xl bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              />
              <div className="absolute right-2 flex items-center gap-1.5">
                {query && (
                  <button
                    onClick={() => setQuery('')}
                    className="p-1 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600"
                  >
                    <X className="w-4 h-4 text-gray-400" />
                  </button>
                )}
                <button
                  onClick={() => query && handleSelectSuggestion(query)}
                  className="px-3 py-1.5 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 transition-colors"
                >
                  {t('common.search')}
                </button>
              </div>
            </div>

            {/* 자동완성 드롭다운 */}
            {showAutocomplete && query && filteredSuggestions.length > 0 && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-gray-100 dark:border-slate-700 z-50 overflow-hidden">
                {filteredSuggestions.map((suggestion, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSelectSuggestion(suggestion)}
                    className="w-full flex items-center gap-3 px-4 py-2.5 text-left hover:bg-gray-50 dark:hover:bg-slate-700 text-sm text-gray-700 dark:text-slate-300 transition-colors"
                  >
                    <Search className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                    {highlightMatch(suggestion, query)}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* 추천 검색어 */}
          <div className="flex items-center gap-2 mt-4 flex-wrap">
            <Sparkles className="w-3.5 h-3.5 text-amber-500 shrink-0" />
            <span className="text-[11px] text-gray-500 shrink-0">추천 검색어</span>
            {suggestedKeywords.map((kw) => (
              <button
                key={kw}
                onClick={() => handleSelectSuggestion(kw)}
                className="px-2.5 py-1 rounded-full bg-gray-100 dark:bg-slate-700 text-[11px] font-medium text-gray-600 dark:text-slate-300 hover:bg-blue-100 hover:text-blue-700 dark:hover:bg-blue-900/30 dark:hover:text-blue-400 transition-colors"
              >
                {kw}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6">
        <div className="flex flex-col lg:flex-row gap-6">
          {/* 메인 결과 영역 */}
          <div className="flex-1">
            {/* 카테고리 탭 */}
            <div className="flex items-center gap-1 mb-6 overflow-x-auto pb-1">
              {tabs.map((tab) => {
                const TabIcon = tab.icon;
                return (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key)}
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
                      activeTab === tab.key
                        ? 'bg-blue-600 text-white shadow-sm'
                        : 'bg-white dark:bg-slate-800 text-gray-600 dark:text-slate-300 hover:bg-gray-100 dark:hover:bg-slate-700 border border-gray-200 dark:border-slate-600'
                    }`}
                  >
                    <TabIcon className="w-3.5 h-3.5" />
                    {tab.label}
                    <span
                      className={`text-[10px] px-1.5 py-0.5 rounded-full ${
                        activeTab === tab.key
                          ? 'bg-white/20'
                          : 'bg-gray-100 dark:bg-slate-700'
                      }`}
                    >
                      {tab.count}
                    </span>
                  </button>
                );
              })}
            </div>

            {/* 검색 결과 정보 */}
            <div className="flex items-center justify-between mb-4">
              <p className="text-sm text-gray-500 dark:text-slate-400">
                <span className="font-bold text-gray-900 dark:text-white">
                  &quot;{query}&quot;
                </span>
                에 대한 검색결과{' '}
                <span className="font-semibold text-blue-600">
                  {filteredResults.length}건
                </span>
              </p>
              <button
                onClick={() => setActiveTab(activeTab === 'ALL' ? 'COURSE' : 'ALL')}
                className="flex items-center gap-1 text-[11px] text-gray-500 hover:text-gray-700 dark:text-slate-400 transition-colors"
              >
                <SlidersHorizontal className="w-3.5 h-3.5" />
                {t('common.filter')}
              </button>
            </div>

            {/* 결과 목록 */}
            <div className="space-y-2">
              {activeTab === 'ALL' && groupedResults
                ? Object.entries(groupedResults).map(([cat, results]) => {
                    const config =
                      categoryConfig[cat as Exclude<Category, 'ALL'>];
                    return (
                      <div key={cat} className="mb-6">
                        <div className="flex items-center gap-2 mb-2 px-1">
                          <config.icon
                            className={`w-4 h-4 ${config.color}`}
                          />
                          <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                            {config.label}
                          </h3>
                          <span className="text-[10px] text-gray-400">
                            {results.length}건
                          </span>
                        </div>
                        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-100 dark:border-slate-700 divide-y divide-gray-50 dark:divide-slate-700/50">
                          {results.map(renderResultItem)}
                        </div>
                      </div>
                    );
                  })
                : (
                    <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-100 dark:border-slate-700 divide-y divide-gray-50 dark:divide-slate-700/50">
                      {filteredResults.map(renderResultItem)}
                    </div>
                  )}
            </div>
          </div>

          {/* 사이드바 — 최근 검색 */}
          <div className="lg:w-72 shrink-0">
            <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-100 dark:border-slate-700 p-4 sticky top-20">
              <div className="flex items-center gap-2 mb-3">
                <Clock className="w-4 h-4 text-gray-400" />
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  최근 검색
                </h3>
              </div>
              {searches.length === 0 ? (
                <p className="text-[11px] text-gray-400 py-2">
                  최근 검색 기록이 없습니다
                </p>
              ) : (
                <div className="space-y-1">
                  {searches.map((term) => (
                    <div
                      key={term}
                      className="flex items-center gap-2 group"
                    >
                      <button
                        onClick={() => handleSelectSuggestion(term)}
                        className="flex-1 flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors text-left"
                      >
                        <Clock className="w-3 h-3 text-gray-300 shrink-0" />
                        {term}
                      </button>
                      <button
                        onClick={() => removeRecentSearch(term)}
                        className="p-1 rounded-md opacity-0 group-hover:opacity-100 hover:bg-gray-100 dark:hover:bg-slate-700 transition-all"
                      >
                        <X className="w-3 h-3 text-gray-400" />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {/* 인기 검색어 */}
              <div className="mt-6 pt-4 border-t border-gray-100 dark:border-slate-700">
                <div className="flex items-center gap-2 mb-3">
                  <TrendingUp className="w-4 h-4 text-orange-500" />
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                    인기 검색어
                  </h3>
                </div>
                <ol className="space-y-1">
                  {['AI 교육', '파이썬', '삼성전자 채용', '자격증', '취업 상담'].map(
                    (term, idx) => (
                      <li key={term}>
                        <button
                          onClick={() => handleSelectSuggestion(term)}
                          className="w-full flex items-center gap-2.5 px-2 py-1.5 rounded-lg text-sm text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors text-left"
                        >
                          <span
                            className={`w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold ${
                              idx < 3
                                ? 'bg-blue-600 text-white'
                                : 'bg-gray-100 dark:bg-slate-700 text-gray-500'
                            }`}
                          >
                            {idx + 1}
                          </span>
                          {term}
                        </button>
                      </li>
                    )
                  )}
                </ol>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
