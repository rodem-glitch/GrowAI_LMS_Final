// src/pages/instructor/builder/CurriculumBuilderPage.tsx
// PRF-E01: Drag & Drop 커리큘럼 빌더 - 주차별 콘텐츠 배치 도구

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  GripVertical,
  Video,
  FileText,
  HelpCircle,
  Plus,
  ChevronUp,
  ChevronDown,
  X,
  Clock,
  LayoutGrid,
  Calculator,
  CheckCircle,
  AlertCircle,
  Pencil,
  Save,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

type ContentType = 'video' | 'document' | 'quiz';
type BuilderStatus = '작성중' | '완성' | '제출';

interface ContentItem {
  id: string;
  type: ContentType;
  title: string;
  duration: number; // 분 단위
}

interface WeekSlot {
  week: number;
  topic: string;
  items: ContentItem[];
}

// -- 아이콘 헬퍼 --------------------------------------------------------

function ContentIcon({ type }: { type: ContentType }) {
  switch (type) {
    case 'video':
      return <Video className="w-4 h-4 text-blue-500" />;
    case 'document':
      return <FileText className="w-4 h-4 text-green-500" />;
    case 'quiz':
      return <HelpCircle className="w-4 h-4 text-purple-500" />;
  }
}

function contentTypeBadge(type: ContentType): string {
  switch (type) {
    case 'video':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
    case 'document':
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    case 'quiz':
      return 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400';
  }
}

function contentTypeLabel(type: ContentType): string {
  switch (type) {
    case 'video':
      return '영상';
    case 'document':
      return '문서';
    case 'quiz':
      return '퀴즈';
  }
}

// -- Mock 데이터: 콘텐츠 라이브러리 (사이드바) ----------------------------

const contentLibrary: ContentItem[] = [
  { id: 'lib-1', type: 'video', title: '파이썬 소개 영상', duration: 25 },
  { id: 'lib-2', type: 'video', title: '변수와 자료형 강의', duration: 30 },
  { id: 'lib-3', type: 'video', title: '조건문 실습 영상', duration: 28 },
  { id: 'lib-4', type: 'video', title: '반복문 개념 설명', duration: 35 },
  { id: 'lib-5', type: 'video', title: '함수 정의 마스터', duration: 32 },
  { id: 'lib-6', type: 'document', title: '파이썬 기초 교안 (PDF)', duration: 15 },
  { id: 'lib-7', type: 'document', title: '실습 가이드 문서', duration: 10 },
  { id: 'lib-8', type: 'document', title: 'NCS 학습모듈 자료', duration: 20 },
  { id: 'lib-9', type: 'document', title: '코딩 컨벤션 가이드', duration: 8 },
  { id: 'lib-10', type: 'quiz', title: '1주차 확인 퀴즈', duration: 10 },
  { id: 'lib-11', type: 'quiz', title: '2주차 확인 퀴즈', duration: 10 },
  { id: 'lib-12', type: 'quiz', title: '조건문 평가 퀴즈', duration: 15 },
  { id: 'lib-13', type: 'quiz', title: '중간평가 모의테스트', duration: 30 },
];

// -- Mock 데이터: 초기 주차별 배치 (3-4주차 사전 배치) --------------------

const initialWeeks: WeekSlot[] = [
  {
    week: 1,
    topic: '파이썬 소개 및 개발환경 구축',
    items: [
      { id: 'w1-1', type: 'video', title: '파이썬 소개 영상', duration: 25 },
      { id: 'w1-2', type: 'document', title: '파이썬 기초 교안 (PDF)', duration: 15 },
      { id: 'w1-3', type: 'quiz', title: '1주차 확인 퀴즈', duration: 10 },
    ],
  },
  {
    week: 2,
    topic: '변수, 자료형, 입출력',
    items: [
      { id: 'w2-1', type: 'video', title: '변수와 자료형 강의', duration: 30 },
      { id: 'w2-2', type: 'document', title: '실습 가이드 문서', duration: 10 },
      { id: 'w2-3', type: 'quiz', title: '2주차 확인 퀴즈', duration: 10 },
    ],
  },
  {
    week: 3,
    topic: '조건문과 반복문',
    items: [
      { id: 'w3-1', type: 'video', title: '조건문 실습 영상', duration: 28 },
      { id: 'w3-2', type: 'video', title: '반복문 개념 설명', duration: 35 },
      { id: 'w3-3', type: 'quiz', title: '조건문 평가 퀴즈', duration: 15 },
    ],
  },
  {
    week: 4,
    topic: '함수와 모듈',
    items: [
      { id: 'w4-1', type: 'video', title: '함수 정의 마스터', duration: 32 },
    ],
  },
  { week: 5, topic: '리스트와 딕셔너리', items: [] },
  { week: 6, topic: '파일 입출력', items: [] },
  { week: 7, topic: '객체지향 프로그래밍', items: [] },
  { week: 8, topic: '중간고사', items: [] },
  { week: 9, topic: '예외처리와 디버깅', items: [] },
  { week: 10, topic: '정규표현식', items: [] },
  { week: 11, topic: '웹 크롤링 기초', items: [] },
  { week: 12, topic: '데이터 시각화', items: [] },
  { week: 13, topic: 'API 활용', items: [] },
  { week: 14, topic: '미니 프로젝트', items: [] },
  { week: 15, topic: '기말고사', items: [] },
];

// -- 메인 컴포넌트 -------------------------------------------------------

export default function CurriculumBuilderPage() {
  const { t } = useTranslation();
  const [weeks, setWeeks] = useState<WeekSlot[]>(initialWeeks);
  const [status, setStatus] = useState<BuilderStatus>('작성중');
  const [expandedWeeks, setExpandedWeeks] = useState<number[]>([1, 2, 3, 4]);
  const [sidebarFilter, setSidebarFilter] = useState<ContentType | 'all'>('all');

  // 총 시간 계산
  const totalDuration = weeks.reduce(
    (sum, w) => sum + w.items.reduce((s, item) => s + item.duration, 0),
    0
  );
  const totalItems = weeks.reduce((sum, w) => sum + w.items.length, 0);
  const filledWeeks = weeks.filter((w) => w.items.length > 0).length;

  // 학습인정시간 (분 → 시간:분)
  const hours = Math.floor(totalDuration / 60);
  const mins = totalDuration % 60;

  // 주차 토글
  const toggleWeek = (week: number) => {
    setExpandedWeeks((prev) =>
      prev.includes(week) ? prev.filter((w) => w !== week) : [...prev, week]
    );
  };

  // 콘텐츠 추가 (클릭으로 시뮬레이션)
  const handleAddContent = (weekNum: number, item: ContentItem) => {
    const newItem: ContentItem = {
      ...item,
      id: `w${weekNum}-${Date.now()}`,
    };
    setWeeks((prev) =>
      prev.map((w) =>
        w.week === weekNum ? { ...w, items: [...w.items, newItem] } : w
      )
    );
    if (!expandedWeeks.includes(weekNum)) {
      setExpandedWeeks((prev) => [...prev, weekNum]);
    }
  };

  // 콘텐츠 삭제
  const handleRemoveContent = (weekNum: number, itemId: string) => {
    setWeeks((prev) =>
      prev.map((w) =>
        w.week === weekNum
          ? { ...w, items: w.items.filter((i) => i.id !== itemId) }
          : w
      )
    );
  };

  // 순서 변경 (위/아래)
  const handleMoveItem = (weekNum: number, itemId: string, direction: 'up' | 'down') => {
    setWeeks((prev) =>
      prev.map((w) => {
        if (w.week !== weekNum) return w;
        const idx = w.items.findIndex((i) => i.id === itemId);
        if (idx === -1) return w;
        const newItems = [...w.items];
        const targetIdx = direction === 'up' ? idx - 1 : idx + 1;
        if (targetIdx < 0 || targetIdx >= newItems.length) return w;
        [newItems[idx], newItems[targetIdx]] = [newItems[targetIdx], newItems[idx]];
        return { ...w, items: newItems };
      })
    );
  };

  // 필터된 라이브러리
  const filteredLibrary =
    sidebarFilter === 'all'
      ? contentLibrary
      : contentLibrary.filter((c) => c.type === sidebarFilter);

  // 상태 배지 색상
  const statusBadge = {
    '작성중': 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
    '완성': 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    '제출': 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-teal-500 to-cyan-600 flex items-center justify-center">
            <LayoutGrid className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.curriculumBuilderTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.curriculumBuilderDesc')}
            </p>
          </div>
        </div>
        <span className={`px-3 py-1.5 text-xs font-medium rounded-full ${statusBadge[status]}`}>
          {status}
        </span>
      </div>

      {/* 요약 통계 */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-2 mb-1">
            <Calculator className="w-4 h-4 text-blue-500" />
            <span className="text-xs text-gray-400">총 콘텐츠 수</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">{totalItems}개</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-2 mb-1">
            <Clock className="w-4 h-4 text-green-500" />
            <span className="text-xs text-gray-400">총 학습 시간</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {hours}시간 {mins}분
          </p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-2 mb-1">
            <CheckCircle className="w-4 h-4 text-emerald-500" />
            <span className="text-xs text-gray-400">배치 완료 주차</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">{filledWeeks}/15</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-2 mb-1">
            <Clock className="w-4 h-4 text-purple-500" />
            <span className="text-xs text-gray-400">학습인정시간</span>
          </div>
          <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
            {Math.round(totalDuration * 0.75)}분
          </p>
          <p className="text-xs text-gray-400 mt-0.5">총 시간의 75%</p>
        </div>
      </div>

      {/* 메인 영역: 사이드바 + 주차 타임라인 */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* 왼쪽 사이드바: 콘텐츠 라이브러리 */}
        <div className="lg:col-span-1">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-4 sticky top-6">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              콘텐츠 라이브러리
            </h3>
            {/* 필터 */}
            <div className="flex flex-wrap gap-1.5 mb-3">
              {(['all', 'video', 'document', 'quiz'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setSidebarFilter(f)}
                  className={`px-2.5 py-1 text-xs rounded-full transition-colors ${
                    sidebarFilter === f
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
                  }`}
                >
                  {f === 'all' ? '전체' : contentTypeLabel(f)}
                </button>
              ))}
            </div>
            {/* 콘텐츠 목록 */}
            <div className="space-y-1.5 max-h-[500px] overflow-y-auto">
              {filteredLibrary.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center gap-2 p-2.5 rounded-lg border border-gray-100 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-700 hover:bg-blue-50 dark:hover:bg-blue-900/20 cursor-grab transition-all group"
                >
                  <GripVertical className="w-3.5 h-3.5 text-gray-300 dark:text-gray-600 group-hover:text-blue-400" />
                  <ContentIcon type={item.type} />
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-medium text-gray-700 dark:text-gray-300 truncate">
                      {item.title}
                    </p>
                    <p className="text-xs text-gray-400">{item.duration}분</p>
                  </div>
                  <span
                    className={`px-1.5 py-0.5 text-[10px] font-medium rounded ${contentTypeBadge(item.type)}`}
                  >
                    {contentTypeLabel(item.type)}
                  </span>
                </div>
              ))}
            </div>
            <p className="text-xs text-gray-400 mt-3 text-center">
              항목을 클릭하여 주차에 추가하세요
            </p>
          </div>
        </div>

        {/* 오른쪽: 15주차 타임라인 */}
        <div className="lg:col-span-3 space-y-3">
          {weeks.map((week) => {
            const isExpanded = expandedWeeks.includes(week.week);
            const weekDuration = week.items.reduce((s, i) => s + i.duration, 0);
            return (
              <div
                key={week.week}
                className={`bg-white dark:bg-gray-800 rounded-xl shadow-sm border transition-all ${
                  week.items.length > 0
                    ? 'border-blue-200 dark:border-blue-800'
                    : 'border-gray-100 dark:border-gray-700'
                }`}
              >
                {/* 주차 헤더 */}
                <button
                  onClick={() => toggleWeek(week.week)}
                  className="w-full flex items-center justify-between p-4 hover:bg-gray-50 dark:hover:bg-gray-700/30 rounded-xl transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`inline-flex items-center justify-center w-8 h-8 rounded-lg text-xs font-bold ${
                        week.items.length > 0
                          ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                          : 'bg-gray-100 text-gray-400 dark:bg-gray-700 dark:text-gray-500'
                      }`}
                    >
                      {week.week}
                    </span>
                    <div className="text-left">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white">
                        {week.topic}
                      </p>
                      <p className="text-xs text-gray-400">
                        {week.items.length > 0
                          ? `${week.items.length}개 콘텐츠 | ${weekDuration}분`
                          : '콘텐츠 없음'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {week.items.length > 0 && (
                      <CheckCircle className="w-4 h-4 text-emerald-500" />
                    )}
                    {week.items.length === 0 && (
                      <AlertCircle className="w-4 h-4 text-gray-300 dark:text-gray-600" />
                    )}
                    {isExpanded ? (
                      <ChevronUp className="w-4 h-4 text-gray-400" />
                    ) : (
                      <ChevronDown className="w-4 h-4 text-gray-400" />
                    )}
                  </div>
                </button>

                {/* 콘텐츠 목록 (확장 시) */}
                {isExpanded && (
                  <div className="px-4 pb-4">
                    {week.items.length > 0 ? (
                      <div className="space-y-2">
                        {week.items.map((item, idx) => (
                          <div
                            key={item.id}
                            className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg group"
                          >
                            <GripVertical className="w-4 h-4 text-gray-300 dark:text-gray-600 cursor-grab" />
                            <ContentIcon type={item.type} />
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 truncate">
                                {item.title}
                              </p>
                              <div className="flex items-center gap-2 mt-0.5">
                                <span
                                  className={`px-1.5 py-0.5 text-[10px] font-medium rounded ${contentTypeBadge(item.type)}`}
                                >
                                  {contentTypeLabel(item.type)}
                                </span>
                                <span className="text-xs text-gray-400">{item.duration}분</span>
                              </div>
                            </div>
                            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                              <button
                                onClick={() => handleMoveItem(week.week, item.id, 'up')}
                                disabled={idx === 0}
                                className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-30 transition-colors"
                                title="위로 이동"
                              >
                                <ChevronUp className="w-3.5 h-3.5 text-gray-500" />
                              </button>
                              <button
                                onClick={() => handleMoveItem(week.week, item.id, 'down')}
                                disabled={idx === week.items.length - 1}
                                className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-30 transition-colors"
                                title="아래로 이동"
                              >
                                <ChevronDown className="w-3.5 h-3.5 text-gray-500" />
                              </button>
                              <button
                                onClick={() => handleRemoveContent(week.week, item.id)}
                                className="p-1 rounded hover:bg-red-100 dark:hover:bg-red-900/30 text-gray-400 hover:text-red-500 transition-colors"
                                title="삭제"
                              >
                                <X className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-6 text-sm text-gray-400 dark:text-gray-500">
                        아래에서 콘텐츠를 선택하여 추가하세요
                      </div>
                    )}

                    {/* 콘텐츠 빠른 추가 버튼 */}
                    <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                      <p className="text-xs text-gray-400 mb-2">빠른 추가:</p>
                      <div className="flex flex-wrap gap-1.5">
                        {contentLibrary.slice(0, 5).map((item) => (
                          <button
                            key={item.id}
                            onClick={() => handleAddContent(week.week, item)}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 rounded-lg transition-colors"
                          >
                            <Plus className="w-3 h-3" />
                            {item.title.length > 12 ? item.title.slice(0, 12) + '...' : item.title}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* 하단 액션 바 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
            <span>총 {totalItems}개 콘텐츠</span>
            <span className="inline-block w-1 h-1 rounded-full bg-gray-300" />
            <span>{hours}시간 {mins}분</span>
            <span className="inline-block w-1 h-1 rounded-full bg-gray-300" />
            <span>학습인정시간: {Math.round(totalDuration * 0.75)}분</span>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setStatus('작성중')}
              className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              <Pencil className="w-4 h-4" />
              임시저장
            </button>
            <button
              onClick={() => setStatus('완성')}
              className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-sm"
            >
              <Save className="w-4 h-4" />
              {t('common.save')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
