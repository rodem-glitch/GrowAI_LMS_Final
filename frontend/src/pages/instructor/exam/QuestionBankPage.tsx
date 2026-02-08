// src/pages/instructor/exam/QuestionBankPage.tsx
// 문제은행 관리 페이지 - 시험에 사용할 문제를 관리 (Mock 데이터)

import { useState, useMemo } from 'react';
import { useTranslation } from '@/i18n';
import { Plus, HelpCircle, Search } from 'lucide-react';

interface Question {
  id: number;
  title: string;
  category: string;
  type: string;
  difficulty: string;
  createdAt: string;
}

const mockQuestions: Question[] = [
  { id: 1, title: 'Python 리스트 컴프리헨션의 올바른 사용법은?', category: 'Python', type: '객관식', difficulty: '중', createdAt: '2026-01-15' },
  { id: 2, title: 'SQL JOIN 유형별 차이를 서술하시오.', category: 'DB', type: '서술형', difficulty: '상', createdAt: '2026-01-18' },
  { id: 3, title: 'React useState Hook의 반환값은?', category: 'Frontend', type: '객관식', difficulty: '하', createdAt: '2026-01-20' },
  { id: 4, title: 'TCP 3-Way Handshake 과정을 설명하시오.', category: '네트워크', type: '서술형', difficulty: '중', createdAt: '2026-01-22' },
  { id: 5, title: 'XSS 공격의 유형 3가지는?', category: '보안', type: '객관식', difficulty: '중', createdAt: '2026-01-25' },
  { id: 6, title: 'Java에서 interface와 abstract class의 차이점은?', category: 'Java', type: '서술형', difficulty: '상', createdAt: '2026-01-28' },
  { id: 7, title: 'Docker 컨테이너와 VM의 차이점은?', category: 'DevOps', type: '객관식', difficulty: '중', createdAt: '2026-02-01' },
  { id: 8, title: 'REST API에서 PUT과 PATCH의 차이를 설명하시오.', category: 'API', type: '서술형', difficulty: '중', createdAt: '2026-02-03' },
  { id: 9, title: '정규화 제1~3 정규형을 각각 설명하시오.', category: 'DB', type: '서술형', difficulty: '상', createdAt: '2026-02-05' },
  { id: 10, title: 'Git merge와 rebase의 차이점은?', category: 'DevOps', type: '객관식', difficulty: '하', createdAt: '2026-02-07' },
];

const difficultyStyle: Record<string, string> = {
  '상': 'badge-sm badge-danger',
  '중': 'badge-sm badge-warning',
  '하': 'badge-sm badge-success',
};

export default function QuestionBankPage() {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [category, setCategory] = useState('all');
  const [type, setType] = useState('all');

  const categories = useMemo(() => [...new Set(mockQuestions.map(q => q.category))], []);

  const filtered = useMemo(() => {
    return mockQuestions.filter(q => {
      const matchSearch = searchTerm === '' || q.title.includes(searchTerm) || q.category.includes(searchTerm);
      const matchCategory = category === 'all' || q.category === category;
      const matchType = type === 'all' || q.type === type;
      return matchSearch && matchCategory && matchType;
    });
  }, [searchTerm, category, type]);

  return (
    <div className="space-y-6">
      {/* 헤더 영역 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.questionBankTitle')}</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t('instructor.questionBankDesc')}
          </p>
        </div>
        <button className="btn-primary">
          <Plus className="w-4 h-4" />
          {t('instructor.addQuestion')}
        </button>
      </div>

      {/* 필터 바 */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={t('ui.searchQuestion')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input-with-icon"
          />
        </div>
        <select value={category} onChange={(e) => setCategory(e.target.value)} className="input w-auto">
          <option value="all">{t('instructor.allCategories')}</option>
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <select value={type} onChange={(e) => setType(e.target.value)} className="input w-auto">
          <option value="all">{t('instructor.allTypes')}</option>
          <option value="객관식">{t('instructor.multipleChoice')}</option>
          <option value="서술형">{t('instructor.essay')}</option>
        </select>
        <span className="text-sm text-gray-500 dark:text-gray-400 ml-auto">
          {t('common.total')} {filtered.length}{t('common.items')}
        </span>
      </div>

      {/* 문제 목록 */}
      <div className="card">
        <div className="flex items-center gap-2 border-b border-gray-200 dark:border-slate-700 px-5 py-4">
          <HelpCircle className="w-5 h-5 text-purple-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('instructor.questionList')}</h2>
        </div>

        {filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <HelpCircle className="w-10 h-10 text-gray-300 dark:text-gray-600 mb-2" />
            <p className="text-sm text-gray-400 dark:text-gray-500">{t('common.noData')}</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100 dark:divide-slate-700">
            {filtered.map((q, i) => (
              <div key={q.id} className="flex items-center justify-between px-5 py-4 hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors cursor-pointer">
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-gray-400 w-6">{i + 1}</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-white truncate">{q.title}</span>
                  </div>
                  <div className="flex items-center gap-3 mt-1 ml-8 text-[11px] text-gray-400 dark:text-slate-500">
                    <span className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-slate-700">{q.category}</span>
                    <span>{q.type}</span>
                    <span>{q.createdAt}</span>
                  </div>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <span className={difficultyStyle[q.difficulty]}>{q.difficulty}</span>
                  <button className="text-xs text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300">
                    {t('common.detail')}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
