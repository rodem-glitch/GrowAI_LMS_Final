// src/pages/instructor/AssignmentManagePage.tsx
// 과제 통합관리 - 모든 담당 과목의 과제를 통합 관리 (i18n + 이벤트 + 다크모드)

import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, ChevronLeft, ChevronRight, FileText } from 'lucide-react';
import { useTranslation } from '@/i18n';

interface AssignmentSubmission {
  id: number;
  courseKey: string;
  assignmentKey: string;
  submitterKey: string;
  submittedDate: string;
  statusKey: string;
  score: string;
}

const mockSubmissions: AssignmentSubmission[] = [
  { id: 1, courseKey: 'pythonBasic', assignmentKey: 'listDict', submitterKey: 'park', submittedDate: '2026-02-05', statusKey: 'submitted', score: '-' },
  { id: 2, courseKey: 'dbDesign', assignmentKey: 'erdProject', submitterKey: 'choi', submittedDate: '-', statusKey: 'notSubmitted', score: '-' },
  { id: 3, courseKey: 'webDev', assignmentKey: 'reactComponent', submitterKey: 'jung', submittedDate: '2026-02-03', statusKey: 'graded', score: '92' },
];

export default function AssignmentManagePage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);

  const statusMap: Record<string, string> = {
    submitted: t('mockStatus.submitted'),
    notSubmitted: t('mockStatus.notSubmitted'),
    graded: t('mockStatus.graded'),
  };

  const statusStyle: Record<string, string> = {
    submitted: 'badge-sm badge-info',
    notSubmitted: 'badge-sm badge-danger',
    graded: 'badge-sm badge-success',
  };

  const resolvedData = useMemo(() => mockSubmissions.map(s => ({
    ...s,
    courseName: t(`mock.courses.${s.courseKey}`),
    assignmentName: t(`mock.assignments.${s.assignmentKey}`),
    submitter: t(`mock.students.${s.submitterKey}`),
    status: statusMap[s.statusKey],
  })), [t]);

  const filtered = resolvedData.filter((s) => {
    const matchSearch = search === '' || s.courseName.includes(search) || s.assignmentName.includes(search) || s.submitter.includes(search);
    const matchStatus = statusFilter === 'all' || s.statusKey === statusFilter;
    const matchStartDate = startDate === '' || s.submittedDate === '-' || s.submittedDate >= startDate;
    const matchEndDate = endDate === '' || s.submittedDate === '-' || s.submittedDate <= endDate;
    return matchSearch && matchStatus && matchStartDate && matchEndDate;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / itemsPerPage));
  const paged = filtered.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);
  const isEmpty = paged.length === 0;

  const handleSearch = () => setCurrentPage(1);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.assignmentsTitle')}</h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-slate-400">{t('instructor.assignmentsDesc')}</p>
      </div>

      {/* 필터 바 */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={t('ui.searchAssignment')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            className="input-with-icon"
          />
        </div>
        <select value={itemsPerPage} onChange={(e) => { setItemsPerPage(Number(e.target.value)); setCurrentPage(1); }}
          className="input w-auto">
          {[10, 20, 50].map(n => <option key={n} value={n}>{n}{t('ui.itemsPerPage')}</option>)}
        </select>
        <button onClick={handleSearch} className="btn-primary">{t('common.search')}</button>
      </div>

      {/* 날짜 + 상태 필터 */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2">
          <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="input w-auto" />
          <span className="text-sm text-gray-500 dark:text-slate-400">~</span>
          <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} className="input w-auto" />
        </div>
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setCurrentPage(1); }} className="input w-auto">
          <option value="all">{t('common.status')}: {t('common.all')}</option>
          <option value="submitted">{t('mockStatus.submitted')}</option>
          <option value="notSubmitted">{t('mockStatus.notSubmitted')}</option>
          <option value="graded">{t('mockStatus.graded')}</option>
        </select>
      </div>

      {/* 테이블 카드 */}
      <div className="card">
        <div className="flex items-center gap-2 border-b border-gray-200 dark:border-slate-700 px-5 py-4">
          <FileText className="w-5 h-5 text-blue-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('ui.submissionList')}</h2>
          <span className="ml-auto text-xs text-gray-500 dark:text-slate-400">
            {t('common.total')} {filtered.length}{t('common.items')}
          </span>
        </div>

        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center w-12">{t('common.no')}</th>
                <th className="table-th">{t('ui.courseName')}</th>
                <th className="table-th">{t('ui.assignmentName')}</th>
                <th className="table-th-center">{t('ui.submitter')}</th>
                <th className="table-th-center">{t('common.date')}</th>
                <th className="table-th-center w-20">{t('common.status')}</th>
                <th className="table-th-center w-16">{t('ui.score')}</th>
                <th className="table-th-center w-16">{t('common.action')}</th>
              </tr>
            </thead>
            <tbody>
              {!isEmpty ? paged.map((s, i) => (
                <tr key={s.id} className="table-row cursor-pointer" onClick={() => navigate(`/instructor/assignment/${s.id}`)}>
                  <td className="table-td-center text-xs text-gray-500 dark:text-slate-400">{(currentPage - 1) * itemsPerPage + i + 1}</td>
                  <td className="table-td text-sm">{s.courseName}</td>
                  <td className="table-td font-medium text-sm text-gray-900 dark:text-white">{s.assignmentName}</td>
                  <td className="table-td-center text-xs">{s.submitter}</td>
                  <td className="table-td-center text-xs whitespace-nowrap">{s.submittedDate}</td>
                  <td className="table-td-center"><span className={statusStyle[s.statusKey]}>{s.status}</span></td>
                  <td className="table-td-center text-sm font-medium">
                    {s.score === '-' ? <span className="text-gray-400">-</span> : <span className="text-blue-600 dark:text-blue-400">{s.score}</span>}
                  </td>
                  <td className="table-td-center">
                    <button onClick={(e) => { e.stopPropagation(); navigate(`/instructor/assignment/${s.id}`); }}
                      className="text-xs text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300">
                      {t('common.detail')}
                    </button>
                  </td>
                </tr>
              )) : (
                <tr><td colSpan={8} className="px-4 py-16 text-center">
                  <div className="flex flex-col items-center gap-2">
                    <FileText className="w-10 h-10 text-gray-300 dark:text-slate-600" />
                    <p className="text-sm text-gray-400 dark:text-slate-500">{t('common.noData')}</p>
                  </div>
                </td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 페이지네이션 */}
      {!isEmpty && (
        <div className="flex items-center justify-center gap-1">
          <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-slate-400 dark:hover:bg-slate-700">
            <ChevronLeft className="w-4 h-4" />{t('common.previous')}
          </button>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
            <button key={page} onClick={() => setCurrentPage(page)}
              className={`min-w-[36px] rounded-md px-3 py-2 text-sm font-medium transition-colors ${currentPage === page ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100 dark:text-slate-400 dark:hover:bg-slate-700'}`}>
              {page}
            </button>
          ))}
          <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-slate-400 dark:hover:bg-slate-700">
            {t('common.next')}<ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}
