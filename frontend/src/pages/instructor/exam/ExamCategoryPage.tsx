// src/pages/instructor/exam/ExamCategoryPage.tsx
// 문제 카테고리 관리 페이지 - 시험 문제를 분류할 카테고리 CRUD (Mock 데이터)

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Plus, Layers, FolderOpen } from 'lucide-react';

interface Category {
  id: number;
  name: string;
  description: string;
  questionCount: number;
  color: string;
}

const mockCategories: Category[] = [
  { id: 1, name: 'Python', description: 'Python 프로그래밍 기초 및 심화 문제', questionCount: 45, color: 'bg-blue-500' },
  { id: 2, name: 'DB', description: '데이터베이스 설계, SQL, 정규화 관련 문제', questionCount: 32, color: 'bg-emerald-500' },
  { id: 3, name: 'Frontend', description: 'HTML/CSS/JS, React 등 프론트엔드 문제', questionCount: 28, color: 'bg-purple-500' },
  { id: 4, name: '네트워크', description: 'TCP/IP, HTTP, DNS 등 네트워크 관련 문제', questionCount: 18, color: 'bg-orange-500' },
  { id: 5, name: '보안', description: 'OWASP, XSS, SQL Injection 등 보안 문제', questionCount: 22, color: 'bg-red-500' },
  { id: 6, name: 'Java', description: 'Java OOP, Spring Framework 관련 문제', questionCount: 38, color: 'bg-cyan-500' },
  { id: 7, name: 'DevOps', description: 'Docker, CI/CD, Git 등 DevOps 관련 문제', questionCount: 15, color: 'bg-yellow-500' },
  { id: 8, name: 'API', description: 'REST API, GraphQL 등 API 설계 문제', questionCount: 12, color: 'bg-indigo-500' },
];

export default function ExamCategoryPage() {
  const { t } = useTranslation();
  const [categories] = useState<Category[]>(mockCategories);

  const totalQuestions = categories.reduce((sum, c) => sum + c.questionCount, 0);

  return (
    <div className="space-y-6">
      {/* 헤더 영역 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.examCategoryTitle')}</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t('instructor.examCategoryDesc')}
          </p>
        </div>
        <button className="btn-primary">
          <Plus className="w-4 h-4" />
          {t('instructor.addCategory')}
        </button>
      </div>

      {/* 요약 카드 */}
      <div className="flex items-center gap-4">
        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 px-5 py-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
            <Layers className="w-5 h-5 text-blue-600 dark:text-blue-400" />
          </div>
          <div>
            <div className="text-lg font-bold text-gray-900 dark:text-white">{categories.length}</div>
            <div className="text-xs text-gray-500 dark:text-gray-400">{t('instructor.totalCategories')}</div>
          </div>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 px-5 py-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
            <FolderOpen className="w-5 h-5 text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <div className="text-lg font-bold text-gray-900 dark:text-white">{totalQuestions}</div>
            <div className="text-xs text-gray-500 dark:text-gray-400">{t('instructor.totalQuestions')}</div>
          </div>
        </div>
      </div>

      {/* 카테고리 그리드 */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {categories.map((cat) => (
          <div key={cat.id} className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-5 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center gap-3 mb-3">
              <div className={`w-3 h-3 rounded-full ${cat.color}`} />
              <h3 className="text-sm font-semibold text-gray-900 dark:text-white">{cat.name}</h3>
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400 line-clamp-2 mb-4">{cat.description}</p>
            <div className="flex items-center justify-between pt-3 border-t border-gray-100 dark:border-slate-700">
              <span className="text-xs text-gray-400 dark:text-slate-500">
                {cat.questionCount}{t('instructor.questionsUnit')}
              </span>
              <button className="text-xs text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300">
                {t('common.detail')}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
