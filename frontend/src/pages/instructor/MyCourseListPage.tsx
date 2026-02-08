// src/pages/instructor/MyCourseListPage.tsx
// 담당과목 - 교수자 담당 과목 목록 관리 페이지

import { useState } from 'react';
import { Search, ChevronLeft, ChevronRight, BookOpenCheck } from 'lucide-react';
import { useTranslation } from '@/i18n';

type TabType = '정규' | '비정규';

interface Course {
  id: number;
  request: string;
  courseId: string;
  type: string;
  courseName: string;
  department: string;
  period: string;
  students: number;
  status: '진행중' | '대기' | '종료';
}

const mockCourses: Course[] = [
  {
    id: 1,
    request: '승인',
    courseId: 'CS2026-001',
    type: '정규',
    courseName: 'Python 프로그래밍 기초',
    department: '컴퓨터공학과',
    period: '2026.03.02 ~ 2026.06.20',
    students: 35,
    status: '진행중',
  },
  {
    id: 2,
    request: '승인',
    courseId: 'CS2026-002',
    type: '정규',
    courseName: '데이터베이스 설계 및 구현',
    department: '소프트웨어학과',
    period: '2026.03.02 ~ 2026.06.20',
    students: 28,
    status: '대기',
  },
  {
    id: 3,
    request: '완료',
    courseId: 'CS2025-015',
    type: '정규',
    courseName: '웹 개발 실무 프로젝트',
    department: '컴퓨터공학과',
    period: '2025.09.01 ~ 2025.12.19',
    students: 38,
    status: '종료',
  },
];

const statusStyle: Record<Course['status'], string> = {
  '진행중': 'badge-sm badge-success',
  '대기': 'badge-sm badge-warning',
  '종료': 'badge-sm badge-gray',
};

export default function MyCourseListPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabType>('정규');
  const [year, setYear] = useState('2026');
  const [type, setType] = useState('전체');
  const [college, setCollege] = useState('전체');
  const [category, setCategory] = useState('전체');
  const [sort, setSort] = useState('최신순');
  const [search, setSearch] = useState('');
  const [itemsPerPage, setItemsPerPage] = useState('10');
  const [currentPage, setCurrentPage] = useState(1);

  const tabs: TabType[] = ['정규', '비정규'];

  const tabLabels: Record<TabType, string> = {
    '정규': t('instructor.regular'),
    '비정규': t('instructor.irregular'),
  };

  // 필터링 로직
  const filtered = mockCourses.filter((c) => {
    const matchTab = c.type === activeTab;
    const matchSearch =
      search === '' ||
      c.courseName.includes(search) ||
      c.courseId.includes(search) ||
      c.department.includes(search);
    const matchType = type === '전체' || c.type === type;
    return matchTab && matchSearch && matchType;
  });

  const isEmpty = filtered.length === 0;

  return (
    <div className="space-y-6">
      {/* 페이지 제목 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.myCoursesTitle')}</h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {t('instructor.myCoursesDesc')}
        </p>
      </div>

      {/* 검색 바 - 과제 통합관리와 동일 패턴 */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={`${t('instructor.courseName')}, ${t('instructor.courseId')}...`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-with-icon"
          />
        </div>
        <select
          value={itemsPerPage}
          onChange={(e) => setItemsPerPage(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
        >
          <option value="10">10개씩</option>
          <option value="20">20개씩</option>
          <option value="50">50개씩</option>
        </select>
        <button
          onClick={() => setCurrentPage(1)}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          {t('common.search')}
        </button>
      </div>

      {/* 필터 행 - 탭 + 드롭다운 */}
      <div className="flex flex-wrap items-center gap-3">
        {/* 탭 버튼 */}
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`rounded-md px-3 py-2 text-sm font-medium transition-colors ${
              activeTab === tab
                ? 'bg-blue-600 text-white'
                : 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
            }`}
          >
            {tabLabels[tab]}
          </button>
        ))}

        <select
          value={year}
          onChange={(e) => setYear(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
        >
          <option value="2024">2024년도</option>
          <option value="2025">2025년도</option>
          <option value="2026">2026년도</option>
        </select>

        <select
          value={college}
          onChange={(e) => setCollege(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
        >
          <option value="전체">{`${t('instructor.college')}: ${t('common.all')}`}</option>
        </select>

        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
        >
          <option value="전체">{`${t('instructor.courseType')}: ${t('common.all')}`}</option>
        </select>

        <select
          value={sort}
          onChange={(e) => setSort(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
        >
          <option value="최신순">{t('common.sortLatest')}</option>
          <option value="이름순">{t('common.sortName')}</option>
        </select>
      </div>

      {/* 과목 목록 카드 */}
      <div className="card">
        <div className="flex items-center gap-2 border-b border-gray-200 px-5 py-4 dark:border-gray-700">
          <BookOpenCheck className="w-5 h-5 text-blue-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">과목 목록</h2>
          <span className="ml-auto text-xs text-gray-500 dark:text-gray-400">
            총 {filtered.length}건
          </span>
        </div>

        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th w-12">{t('common.no')}</th>
                <th className="table-th-center w-16">{t('instructor.request')}</th>
                <th className="table-th-center">{t('instructor.courseId')}</th>
                <th className="table-th-center w-16">{t('common.type')}</th>
                <th className="table-th">{t('instructor.courseName')}</th>
                <th className="table-th-center">{t('instructor.department')}</th>
                <th className="table-th-center">{t('common.period')}</th>
                <th className="table-th-center w-16">{t('instructor.students')}</th>
                <th className="table-th-center w-20">{t('common.status')}</th>
                <th className="table-th-center w-16">{t('common.action')}</th>
              </tr>
            </thead>
            <tbody>
              {!isEmpty ? (
                filtered.map((course, index) => (
                  <tr key={course.id} className="table-row">
                    <td className="table-td text-center text-xs text-gray-500">
                      {index + 1}
                    </td>
                    <td className="table-td-center text-xs">{course.request}</td>
                    <td className="table-td-center font-mono text-xs">{course.courseId}</td>
                    <td className="table-td-center text-xs">{course.type}</td>
                    <td className="table-td font-medium text-sm">{course.courseName}</td>
                    <td className="table-td-center text-xs">{course.department}</td>
                    <td className="table-td-center text-xs whitespace-nowrap">{course.period}</td>
                    <td className="table-td-center text-sm font-medium">{course.students}명</td>
                    <td className="table-td-center">
                      <span className={statusStyle[course.status]}>{course.status}</span>
                    </td>
                    <td className="table-td-center">
                      <button className="text-xs text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300">
                        {t('common.detail')}
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={10} className="px-4 py-16 text-center">
                    <div className="flex flex-col items-center gap-2">
                      <BookOpenCheck className="w-10 h-10 text-gray-300 dark:text-gray-600" />
                      <p className="text-sm text-gray-400 dark:text-gray-500">
                        {t('common.noData')}
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 페이지네이션 */}
      {!isEmpty && (
        <div className="flex items-center justify-center gap-1">
          <button
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
          >
            <ChevronLeft className="w-4 h-4" />
            {t('common.previous')}
          </button>
          {[1, 2, 3].map((page) => (
            <button
              key={page}
              onClick={() => setCurrentPage(page)}
              className={`min-w-[36px] rounded-md px-3 py-2 text-sm font-medium transition-colors ${
                currentPage === page
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
              }`}
            >
              {page}
            </button>
          ))}
          <button
            onClick={() => setCurrentPage((p) => Math.min(3, p + 1))}
            disabled={currentPage === 3}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
          >
            {t('common.next')}
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}
