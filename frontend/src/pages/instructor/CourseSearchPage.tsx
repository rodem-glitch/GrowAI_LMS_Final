// src/pages/instructor/CourseSearchPage.tsx
// 과정탐색 - 교육 과정 검색 및 탐색 페이지

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Search,
  Grid3X3,
  List,
  Star,
  Users,
  Clock,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

// ── 타입 정의 ──────────────────────────────────────────────

interface CourseCard {
  id: number;
  title: string;
  instructor: string;
  category: string;
  type: '정규' | '비정규' | '특강';
  rating: number;
  reviewCount: number;
  studentCount: number;
  duration: string;
  gradient: string;
}

// ── Mock 데이터 ────────────────────────────────────────────

const categories = ['전체 카테고리', 'IT/프로그래밍', '데이터베이스', '네트워크', '디자인', '경영/회계'];
const courseTypes = ['전체 유형', '정규', '비정규', '특강'];

const mockCourses: CourseCard[] = [
  {
    id: 1,
    title: 'Python 프로그래밍 기초',
    instructor: '김교수',
    category: 'IT/프로그래밍',
    type: '정규',
    rating: 4.8,
    reviewCount: 124,
    studentCount: 350,
    duration: '16주',
    gradient: 'from-blue-400 to-purple-500',
  },
  {
    id: 2,
    title: '데이터베이스 설계 및 실습',
    instructor: '이교수',
    category: '데이터베이스',
    type: '정규',
    rating: 4.5,
    reviewCount: 87,
    studentCount: 210,
    duration: '16주',
    gradient: 'from-emerald-400 to-cyan-500',
  },
  {
    id: 3,
    title: '클라우드 컴퓨팅 입문',
    instructor: '박교수',
    category: 'IT/프로그래밍',
    type: '비정규',
    rating: 4.7,
    reviewCount: 56,
    studentCount: 180,
    duration: '8주',
    gradient: 'from-orange-400 to-pink-500',
  },
  {
    id: 4,
    title: 'React 웹 개발 마스터',
    instructor: '최교수',
    category: 'IT/프로그래밍',
    type: '정규',
    rating: 4.9,
    reviewCount: 203,
    studentCount: 420,
    duration: '16주',
    gradient: 'from-sky-400 to-indigo-500',
  },
  {
    id: 5,
    title: 'UI/UX 디자인 워크숍',
    instructor: '정교수',
    category: '디자인',
    type: '특강',
    rating: 4.3,
    reviewCount: 42,
    studentCount: 95,
    duration: '4주',
    gradient: 'from-fuchsia-400 to-rose-500',
  },
  {
    id: 6,
    title: '네트워크 보안 실무',
    instructor: '한교수',
    category: '네트워크',
    type: '비정규',
    rating: 4.6,
    reviewCount: 68,
    studentCount: 155,
    duration: '12주',
    gradient: 'from-teal-400 to-emerald-500',
  },
];

// ── 배지 스타일 헬퍼 ──────────────────────────────────────

function typeBadgeClass(type: string): string {
  switch (type) {
    case '정규':
      return 'bg-blue-100 text-blue-700';
    case '비정규':
      return 'bg-green-100 text-green-700';
    case '특강':
      return 'bg-amber-100 text-amber-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

// ── 별점 렌더링 컴포넌트 ──────────────────────────────────

function RatingStars({ rating }: { rating: number }) {
  const fullStars = Math.floor(rating);
  const hasHalf = rating - fullStars >= 0.5;
  const emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);

  return (
    <div className="flex items-center gap-0.5">
      {Array.from({ length: fullStars }).map((_, i) => (
        <Star
          key={`full-${i}`}
          className="w-3.5 h-3.5 fill-yellow-400 text-yellow-400"
        />
      ))}
      {hasHalf && (
        <div className="relative w-3.5 h-3.5">
          <Star className="absolute w-3.5 h-3.5 text-gray-300 dark:text-gray-600" />
          <div className="absolute overflow-hidden w-[50%]">
            <Star className="w-3.5 h-3.5 fill-yellow-400 text-yellow-400" />
          </div>
        </div>
      )}
      {Array.from({ length: emptyStars }).map((_, i) => (
        <Star
          key={`empty-${i}`}
          className="w-3.5 h-3.5 text-gray-300 dark:text-gray-600"
        />
      ))}
    </div>
  );
}

// ── 메인 컴포넌트 ─────────────────────────────────────────

export default function CourseSearchPage() {
  const { t } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('전체 카테고리');
  const [selectedType, setSelectedType] = useState('전체 유형');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [currentPage, setCurrentPage] = useState(1);

  // 필터링 로직
  const filteredCourses = mockCourses.filter((course) => {
    const matchesSearch =
      searchQuery === '' ||
      course.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      course.instructor.includes(searchQuery);
    const matchesCategory =
      selectedCategory === '전체 카테고리' ||
      course.category === selectedCategory;
    const matchesType =
      selectedType === '전체 유형' || course.type === selectedType;
    return matchesSearch && matchesCategory && matchesType;
  });

  const totalPages = Math.max(1, Math.ceil(filteredCourses.length / 6));

  return (
    <div className="space-y-6">
      {/* 페이지 타이틀 */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {t('instructor.courseSearchTitle')}
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {t('instructor.courseSearchDesc')}
        </p>
      </div>

      {/* 검색 및 필터 영역 */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        {/* 검색 입력 */}
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={t('common.searchPlaceholder')}
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full pl-10 pr-4 py-2.5 text-sm bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all placeholder-gray-400"
          />
        </div>

        {/* 카테고리 셀렉트 */}
        <select
          value={selectedCategory}
          onChange={(e) => {
            setSelectedCategory(e.target.value);
            setCurrentPage(1);
          }}
          className="px-4 py-2.5 text-sm bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-700 dark:text-gray-300 cursor-pointer"
        >
          {categories.map((cat) => (
            <option key={cat} value={cat}>
              {cat}
            </option>
          ))}
        </select>

        {/* 유형 셀렉트 */}
        <select
          value={selectedType}
          onChange={(e) => {
            setSelectedType(e.target.value);
            setCurrentPage(1);
          }}
          className="px-4 py-2.5 text-sm bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-700 dark:text-gray-300 cursor-pointer"
        >
          {courseTypes.map((ct) => (
            <option key={ct} value={ct}>
              {ct}
            </option>
          ))}
        </select>

        {/* 그리드/리스트 토글 */}
        <div className="flex items-center border border-gray-200 dark:border-gray-700 rounded-xl overflow-hidden">
          <button
            onClick={() => setViewMode('grid')}
            className={`p-2.5 transition-colors ${
              viewMode === 'grid'
                ? 'bg-blue-500 text-white'
                : 'bg-white dark:bg-gray-800 text-gray-500 hover:text-gray-700 dark:text-gray-400'
            }`}
            aria-label="그리드 보기"
          >
            <Grid3X3 className="w-4 h-4" />
          </button>
          <button
            onClick={() => setViewMode('list')}
            className={`p-2.5 transition-colors ${
              viewMode === 'list'
                ? 'bg-blue-500 text-white'
                : 'bg-white dark:bg-gray-800 text-gray-500 hover:text-gray-700 dark:text-gray-400'
            }`}
            aria-label="리스트 보기"
          >
            <List className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* 검색 결과 수 */}
      <p className="text-sm text-gray-500 dark:text-gray-400">
        {t('common.total')} <span className="font-semibold text-gray-900 dark:text-white">{filteredCourses.length}</span>{t('common.items')}
      </p>

      {/* 과정 카드 그리드 */}
      {filteredCourses.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-gray-400">
          <Search className="w-12 h-12 mb-4" />
          <p className="text-sm">{t('common.noData')}</p>
          <p className="text-xs mt-1">다른 검색어나 필터를 사용해 보세요.</p>
        </div>
      ) : viewMode === 'grid' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredCourses.map((course) => (
            <div
              key={course.id}
              className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden hover:shadow-md transition-shadow cursor-pointer group"
            >
              {/* 이미지 플레이스홀더 */}
              <div
                className={`h-40 bg-gradient-to-br ${course.gradient} rounded-t-xl flex items-center justify-center relative`}
              >
                <span className="text-white/80 text-4xl font-bold opacity-30 group-hover:opacity-50 transition-opacity select-none">
                  {course.title.charAt(0)}
                </span>
                <span
                  className={`absolute top-3 right-3 px-2 py-0.5 text-xs font-medium rounded-full ${typeBadgeClass(course.type)}`}
                >
                  {course.type}
                </span>
              </div>

              {/* 카드 본문 */}
              <div className="p-4 space-y-3">
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white line-clamp-2 leading-snug">
                  {course.title}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {course.instructor}
                </p>

                {/* 별점 */}
                <div className="flex items-center gap-2">
                  <RatingStars rating={course.rating} />
                  <span className="text-xs font-medium text-gray-700 dark:text-gray-300">
                    {course.rating}
                  </span>
                  <span className="text-xs text-gray-400">
                    ({course.reviewCount})
                  </span>
                </div>

                {/* 메타 정보 */}
                <div className="flex items-center gap-4 text-xs text-gray-400 pt-1 border-t border-gray-100 dark:border-gray-700">
                  <span className="flex items-center gap-1">
                    <Users className="w-3.5 h-3.5" />
                    {course.studentCount}명
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    {course.duration}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* 리스트 뷰 */
        <div className="space-y-3">
          {filteredCourses.map((course) => (
            <div
              key={course.id}
              className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 flex items-center gap-4 hover:shadow-md transition-shadow cursor-pointer"
            >
              {/* 축소 이미지 */}
              <div
                className={`w-20 h-20 rounded-xl bg-gradient-to-br ${course.gradient} flex items-center justify-center flex-shrink-0`}
              >
                <span className="text-white/80 text-2xl font-bold opacity-40 select-none">
                  {course.title.charAt(0)}
                </span>
              </div>

              {/* 정보 */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                    {course.title}
                  </h3>
                  <span
                    className={`flex-shrink-0 px-2 py-0.5 text-xs font-medium rounded-full ${typeBadgeClass(course.type)}`}
                  >
                    {course.type}
                  </span>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400 mb-1.5">
                  {course.instructor}
                </p>
                <div className="flex items-center gap-3">
                  <RatingStars rating={course.rating} />
                  <span className="text-xs font-medium text-gray-700 dark:text-gray-300">
                    {course.rating}
                  </span>
                  <span className="text-xs text-gray-400">
                    ({course.reviewCount})
                  </span>
                  <span className="text-xs text-gray-400 flex items-center gap-1">
                    <Users className="w-3 h-3" />
                    {course.studentCount}명
                  </span>
                  <span className="text-xs text-gray-400 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {course.duration}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 페이지네이션 */}
      <div className="flex items-center justify-center gap-2 pt-4">
        <button
          onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
          disabled={currentPage === 1}
          className="p-2 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-500 hover:text-gray-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          aria-label="이전 페이지"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>

        {Array.from({ length: totalPages }).map((_, i) => {
          const page = i + 1;
          return (
            <button
              key={page}
              onClick={() => setCurrentPage(page)}
              className={`w-9 h-9 rounded-lg text-sm font-medium transition-colors ${
                currentPage === page
                  ? 'bg-blue-500 text-white shadow-sm'
                  : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-750'
              }`}
            >
              {page}
            </button>
          );
        })}

        <button
          onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
          disabled={currentPage === totalPages}
          className="p-2 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-500 hover:text-gray-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          aria-label="다음 페이지"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
