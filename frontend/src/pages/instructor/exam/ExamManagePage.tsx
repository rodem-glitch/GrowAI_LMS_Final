// src/pages/instructor/exam/ExamManagePage.tsx
// 시험관리 페이지 - 시험을 생성하고 관리 (Mock 데이터)

import { useState, useMemo } from 'react';
import { useTranslation } from '@/i18n';
import { Plus, FileText, Search, Clock, Users, CheckCircle2 } from 'lucide-react';

interface Exam {
  id: number;
  title: string;
  courseName: string;
  questionCount: number;
  startDate: string;
  endDate: string;
  duration: number;
  participants: number;
  status: 'scheduled' | 'active' | 'completed';
}

const mockExams: Exam[] = [
  { id: 1, title: 'Python 중간고사', courseName: 'Python 프로그래밍 기초', questionCount: 25, startDate: '2026-03-15', endDate: '2026-03-15', duration: 60, participants: 35, status: 'scheduled' },
  { id: 2, title: 'DB 설계 퀴즈 1회', courseName: '데이터베이스 설계 및 구현', questionCount: 15, startDate: '2026-02-10', endDate: '2026-02-10', duration: 30, participants: 28, status: 'active' },
  { id: 3, title: '웹개발 기말 프로젝트 평가', courseName: '웹 개발 실무 프로젝트', questionCount: 10, startDate: '2025-12-15', endDate: '2025-12-15', duration: 90, participants: 38, status: 'completed' },
  { id: 4, title: 'Java OOP 퀴즈', courseName: 'Java 객체지향 프로그래밍', questionCount: 20, startDate: '2026-03-20', endDate: '2026-03-20', duration: 45, participants: 32, status: 'scheduled' },
  { id: 5, title: '네트워크 보안 평가', courseName: '정보보안 개론', questionCount: 30, startDate: '2026-02-01', endDate: '2026-02-01', duration: 60, participants: 25, status: 'completed' },
];

const statusConfig: Record<Exam['status'], { label: string; style: string }> = {
  scheduled: { label: '예정', style: 'badge-sm badge-warning' },
  active: { label: '진행중', style: 'badge-sm badge-success' },
  completed: { label: '완료', style: 'badge-sm badge-gray' },
};

export default function ExamManagePage() {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');

  const filtered = useMemo(() => {
    return mockExams.filter(e =>
      searchTerm === '' || e.title.includes(searchTerm) || e.courseName.includes(searchTerm)
    );
  }, [searchTerm]);

  return (
    <div className="space-y-6">
      {/* 헤더 영역 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.examManageTitle')}</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t('instructor.examManageDesc')}
          </p>
        </div>
        <button className="btn-primary">
          <Plus className="w-4 h-4" />
          {t('instructor.createExam')}
        </button>
      </div>

      {/* 검색 바 */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={t('ui.searchExam')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input-with-icon"
          />
        </div>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          {t('common.total')} {filtered.length}{t('common.items')}
        </span>
      </div>

      {/* 시험 목록 */}
      <div className="card">
        <div className="flex items-center gap-2 border-b border-gray-200 dark:border-slate-700 px-5 py-4">
          <FileText className="w-5 h-5 text-blue-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('instructor.examList')}</h2>
        </div>

        {filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <FileText className="w-10 h-10 text-gray-300 dark:text-gray-600 mb-2" />
            <p className="text-sm text-gray-400 dark:text-gray-500">{t('common.noData')}</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100 dark:divide-slate-700">
            {filtered.map((exam) => {
              const sc = statusConfig[exam.status];
              return (
                <div key={exam.id} className="flex items-center justify-between px-5 py-4 hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors cursor-pointer">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-gray-900 dark:text-white">{exam.title}</span>
                      <span className={sc.style}>{sc.label}</span>
                    </div>
                    <div className="mt-1 text-xs text-gray-400 dark:text-slate-500">
                      {exam.courseName}
                    </div>
                    <div className="flex items-center gap-4 mt-1.5 text-[11px] text-gray-400 dark:text-slate-500">
                      <span className="flex items-center gap-1"><CheckCircle2 className="w-3 h-3" /> {exam.questionCount}문제</span>
                      <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> {exam.duration}분</span>
                      <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {exam.participants}명</span>
                      <span>{exam.startDate}</span>
                    </div>
                  </div>
                  <button className="text-xs text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300 shrink-0">
                    {t('common.detail')}
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
