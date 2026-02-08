// src/pages/instructor/QnaManagePage.tsx
// Q&A 통합관리 페이지 - 교수자가 담당 과목의 Q&A를 통합 관리

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { MessageSquare, Search, ChevronLeft, ChevronRight } from 'lucide-react';

type QnaStatus = '답변완료' | '대기중';

interface QnaItem {
  id: number;
  courseName: string;
  title: string;
  author: string;
  createdAt: string;
  status: QnaStatus;
}

const mockQnaData: QnaItem[] = [
  {
    id: 1,
    courseName: 'Python 프로그래밍 기초',
    title: '과제 제출 기한 연장 요청드립니다',
    author: '박학생',
    createdAt: '2026-02-05',
    status: '답변완료',
  },
  {
    id: 2,
    courseName: '데이터베이스 설계',
    title: 'ERD 과제 관련 질문입니다',
    author: '최학생',
    createdAt: '2026-02-06',
    status: '대기중',
  },
  {
    id: 3,
    courseName: '웹 개발 실무',
    title: 'React 라우터 설정 오류 문의',
    author: '정학생',
    createdAt: '2026-02-07',
    status: '대기중',
  },
];

export default function QnaManagePage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [perPage, setPerPage] = useState(10);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [statusFilter, setStatusFilter] = useState<'전체' | QnaStatus>('전체');

  // 필터링 로직
  const filtered = mockQnaData.filter((item) => {
    const matchSearch =
      item.title.includes(search) ||
      item.courseName.includes(search) ||
      item.author.includes(search);
    const matchStatus = statusFilter === '전체' || item.status === statusFilter;
    const matchStart = !startDate || item.createdAt >= startDate;
    const matchEnd = !endDate || item.createdAt <= endDate;
    return matchSearch && matchStatus && matchStart && matchEnd;
  });

  return (
    <div className="space-y-6">
      {/* 페이지 제목 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.qnaTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          {t('instructor.qnaDesc')}
        </p>
      </div>

      {/* 필터 바 - 검색 + 표시 개수 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          {/* 검색 입력 */}
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="제목, 과목명, 작성자 검색..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
          </div>

          {/* 표시 개수 */}
          <select
            value={perPage}
            onChange={(e) => setPerPage(Number(e.target.value))}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
          >
            <option value={10}>10개씩</option>
            <option value={20}>20개씩</option>
          </select>

          {/* 검색 버튼 */}
          <button className="px-4 py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors">
            {t('common.search')}
          </button>
        </div>

        {/* 날짜 범위 + 상태 필터 */}
        <div className="flex flex-col sm:flex-row gap-3 mt-3">
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600 dark:text-gray-400 whitespace-nowrap">시작일</label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
            />
            <span className="text-gray-400">~</span>
            <label className="text-sm text-gray-600 dark:text-gray-400 whitespace-nowrap">종료일</label>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
            />
          </div>

          {/* 상태 필터 */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as '전체' | QnaStatus)}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
          >
            <option value="전체">전체</option>
            <option value="답변완료">답변완료</option>
            <option value="대기중">대기중</option>
          </select>
        </div>
      </div>

      {/* Q&A 목록 카드 */}
      <div className="card">
        {/* 카드 헤더 */}
        <div className="flex items-center gap-2 px-5 py-4 border-b border-gray-200 dark:border-gray-700">
          <MessageSquare className="w-5 h-5 text-primary-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">Q&A 목록</h2>
          <span className="text-xs text-gray-400 ml-1">총 {filtered.length}건</span>
        </div>

        {/* 테이블 */}
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center w-14">No</th>
                <th className="table-th">{t('instructor.courseName')}</th>
                <th className="table-th">{t('common.name')}</th>
                <th className="table-th-center">{t('common.name')}</th>
                <th className="table-th-center">{t('common.date')}</th>
                <th className="table-th-center">{t('common.status')}</th>
                <th className="table-th-center">{t('common.manage')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((item, index) => (
                <tr key={item.id} className="table-row">
                  <td className="table-td-center text-xs text-gray-500">{index + 1}</td>
                  <td className="table-td text-sm">{item.courseName}</td>
                  <td className="table-td text-sm font-medium">{item.title}</td>
                  <td className="table-td-center text-sm">{item.author}</td>
                  <td className="table-td-center text-xs text-gray-500">{item.createdAt}</td>
                  <td className="table-td-center">
                    <span
                      className={`badge-sm ${
                        item.status === '답변완료' ? 'badge-success' : 'badge-warning'
                      }`}
                    >
                      {item.status}
                    </span>
                  </td>
                  <td className="table-td-center">
                    {item.status === '대기중' ? (
                      <button className="px-3 py-1 text-xs font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 transition-colors">
                        답변
                      </button>
                    ) : (
                      <button className="px-3 py-1 text-xs font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors">
                        보기
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-8 text-sm text-gray-400">
                    {t('common.noData')}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* 페이지네이션 */}
        <div className="flex items-center justify-center gap-1 px-5 py-4 border-t border-gray-200 dark:border-gray-700">
          <button className="p-2 rounded-md text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
            <ChevronLeft className="w-4 h-4" />
          </button>
          <button className="w-8 h-8 flex items-center justify-center text-xs font-medium rounded-md bg-primary-600 text-white">
            1
          </button>
          <button className="w-8 h-8 flex items-center justify-center text-xs font-medium rounded-md text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
            2
          </button>
          <button className="w-8 h-8 flex items-center justify-center text-xs font-medium rounded-md text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
            3
          </button>
          <button className="p-2 rounded-md text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
