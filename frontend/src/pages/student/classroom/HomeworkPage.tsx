import { useState } from 'react';
import { Upload, FileText, Calendar } from 'lucide-react';
import { useTranslation } from '@/i18n';

export default function HomeworkPage() {
  const { t } = useTranslation();
  const [content, setContent] = useState('');
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <h1 className="text-xl font-bold">{t('student.homeworkTitle')}</h1>
      <div className="card p-5">
        <h2 className="text-sm font-semibold mb-2">과제 설명</h2>
        <p className="text-sm text-gray-600 dark:text-slate-400">Python의 for 반복문을 활용하여 2~9단 구구단을 출력하는 프로그램을 작성하세요.</p>
        <div className="flex items-center gap-4 mt-3 text-[10px] text-gray-400">
          <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />마감: 2026-03-15</span>
          <span className="flex items-center gap-1"><FileText className="w-3 h-3" />배점: 100점</span>
        </div>
      </div>
      <div className="card p-5 space-y-4">
        <h2 className="text-sm font-semibold">답안 작성</h2>
        <textarea value={content} onChange={e => setContent(e.target.value)} rows={8} placeholder="답안을 작성하세요..." className="input font-mono text-sm" />
        <div className="border-2 border-dashed border-gray-200 dark:border-slate-700 rounded-lg p-6 text-center">
          <Upload className="w-6 h-6 text-gray-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">파일을 드래그하거나 클릭하여 첨부</p>
        </div>
        <button className="btn-primary w-full justify-center">과제 제출</button>
      </div>
    </div>
  );
}
