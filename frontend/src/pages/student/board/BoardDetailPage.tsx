import { useParams } from 'react-router-dom';
import { useState } from 'react';
import { useTranslation } from '@/i18n';

export default function BoardDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  const [comment, setComment] = useState('');
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="card p-6">
        <div className="badge-sm badge-info mb-2">공지</div>
        <h1 className="text-lg font-bold mb-2">{t('student.boardDetailTitle')}</h1>
        <div className="text-[10px] text-gray-400 mb-4">관리자 · 2026-02-08 · 조회 342</div>
        <div className="prose prose-sm dark:prose-invert max-w-none text-sm text-gray-700 dark:text-slate-300">
          <p>2026학년도 1학기 수강신청이 아래와 같이 진행됩니다.</p>
          <ul><li>신청 기간: 2026.02.15 ~ 02.28</li><li>수강 확인: 2026.03.01</li><li>개강일: 2026.03.02</li></ul>
        </div>
      </div>
      <div className="card p-5 space-y-4">
        <h2 className="text-sm font-semibold">댓글 (5)</h2>
        <div className="space-y-3">
          {['감사합니다!', '수강신청 방법이 궁금합니다.'].map((c, i) => (
            <div key={i} className="flex gap-3 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
              <div className="w-7 h-7 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center text-xs font-bold text-primary-600 shrink-0">{i === 0 ? '박' : '최'}</div>
              <div><div className="text-xs font-medium">{i === 0 ? '박학생' : '최학생'} <span className="text-gray-400 font-normal">· 2026-02-0{8 - i}</span></div><div className="text-sm mt-1">{c}</div></div>
            </div>
          ))}
        </div>
        <div className="flex gap-2">
          <input type="text" value={comment} onChange={e => setComment(e.target.value)} placeholder="댓글 입력..." className="input flex-1" />
          <button className="btn-primary btn-sm">등록</button>
        </div>
      </div>
    </div>
  );
}
