// src/pages/instructor/QnaDetailPage.tsx
// Q&A 상세 페이지 — 질문 보기 + 답변 작성/수정 기능

import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft, MessageSquare, User, Clock, BookOpen, Send, CheckCircle, Edit3,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

interface QnaDetail {
  id: number;
  courseName: string;
  title: string;
  content: string;
  author: string;
  createdAt: string;
  status: string;
  answer: string;
  answeredAt: string;
}

export default function QnaDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const mockQna: Record<string, QnaDetail> = {
    '1': {
      id: 1,
      courseName: t('mock.courses.pythonBasic'),
      title: t('mock.qna.deadlineExtension'),
      content: '교수님, 과제 제출 기한을 좀 더 연장해주실 수 있을까요? 개인적인 사정으로 현재 기한까지 완성이 어렵습니다. 감사합니다.',
      author: t('mock.students.parkName'),
      createdAt: '2026-02-05',
      status: t('mockStatus.answered'),
      answer: t('mock.qnaAnswers.deadlineAnswer'),
      answeredAt: '2026-02-05',
    },
    '2': {
      id: 2,
      courseName: t('mock.courses.dbDesign'),
      title: t('mock.qna.erdQuestion'),
      content: 'ERD 과제에서 다대다 관계를 표현할 때 중간 테이블을 꼭 만들어야 하나요? 아니면 직접 연결해도 되는지 궁금합니다.',
      author: t('mock.students.choiName'),
      createdAt: '2026-02-06',
      status: t('mockStatus.pending'),
      answer: '',
      answeredAt: '',
    },
    '3': {
      id: 3,
      courseName: t('mock.courses.webDev'),
      title: t('mock.qna.reactRouter'),
      content: 'React Router v6에서 중첩 라우트를 설정하는데 Outlet이 제대로 동작하지 않습니다. 어떻게 해결할 수 있을까요?',
      author: t('mock.students.jungName'),
      createdAt: '2026-02-07',
      status: t('mockStatus.pending'),
      answer: '',
      answeredAt: '',
    },
  };

  const detail = mockQna[id || '1'] || mockQna['1'];

  const [answerText, setAnswerText] = useState(detail.answer);
  const [isEditing, setIsEditing] = useState(!detail.answer);
  const [saved, setSaved] = useState(false);

  const isAnswered = detail.status === t('mockStatus.answered');

  const handleSubmitAnswer = () => {
    if (!answerText.trim()) return;
    setSaved(true);
    setIsEditing(false);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div className="space-y-6">
      {/* 뒤로가기 + 제목 */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate('/instructor/qna')}
          className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600 dark:text-slate-400" />
        </button>
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('ui.qnaDetail')}</h1>
          <p className="text-sm text-gray-500 dark:text-slate-400">{detail.courseName}</p>
        </div>
        <span className={`ml-auto ${isAnswered ? 'badge-sm badge-success' : 'badge-sm badge-warning'}`}>
          {detail.status}
        </span>
      </div>

      {/* 질문 카드 */}
      <div className="card">
        <div className="flex items-center gap-2 mb-4">
          <MessageSquare className="w-5 h-5 text-purple-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('ui.question')}</h2>
        </div>

        <div className="space-y-4">
          {/* 질문 메타 정보 */}
          <div className="flex flex-wrap items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-gray-400" />
              <span className="text-gray-600 dark:text-slate-400">{detail.courseName}</span>
            </div>
            <div className="flex items-center gap-2">
              <User className="w-4 h-4 text-gray-400" />
              <span className="text-gray-600 dark:text-slate-400">{detail.author}</span>
            </div>
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-400" />
              <span className="text-gray-600 dark:text-slate-400">{detail.createdAt}</span>
            </div>
          </div>

          {/* 질문 제목 */}
          <h3 className="text-base font-semibold text-gray-900 dark:text-white">{detail.title}</h3>

          {/* 질문 본문 */}
          <div className="bg-gray-50 dark:bg-slate-800 rounded-lg p-4 text-sm text-gray-700 dark:text-slate-300 leading-relaxed">
            {detail.content}
          </div>
        </div>
      </div>

      {/* 답변 카드 */}
      <div className="card">
        <div className="flex items-center gap-2 mb-4">
          <Send className="w-5 h-5 text-blue-600" />
          <h2 className="text-sm font-semibold text-gray-900 dark:text-white">
            {isAnswered && !isEditing ? t('ui.answerContent') : t('ui.writeAnswer')}
          </h2>
          {isAnswered && !isEditing && (
            <button
              onClick={() => setIsEditing(true)}
              className="ml-auto flex items-center gap-1 text-xs text-blue-600 dark:text-blue-400 hover:underline"
            >
              <Edit3 className="w-3.5 h-3.5" />
              {t('ui.editAnswer')}
            </button>
          )}
        </div>

        {/* 답변 표시 또는 편집 */}
        {isAnswered && !isEditing ? (
          <div className="space-y-3">
            <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 text-sm text-gray-700 dark:text-slate-300 leading-relaxed">
              {answerText}
            </div>
            <p className="text-xs text-gray-400 flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {detail.answeredAt}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            <textarea
              rows={6}
              value={answerText}
              onChange={(e) => setAnswerText(e.target.value)}
              placeholder={t('ui.answerPlaceholder')}
              className="input resize-none"
            />
            <div className="flex items-center gap-3">
              <button
                onClick={handleSubmitAnswer}
                disabled={!answerText.trim()}
                className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4" />
                {isAnswered ? t('ui.editAnswer') : t('ui.submitAnswer')}
              </button>
              {isAnswered && (
                <button
                  onClick={() => { setIsEditing(false); setAnswerText(detail.answer); }}
                  className="btn-secondary"
                >
                  {t('common.cancel')}
                </button>
              )}
            </div>
          </div>
        )}

        {saved && (
          <div className="flex items-center gap-2 mt-3 text-sm text-emerald-600 dark:text-emerald-400">
            <CheckCircle className="w-4 h-4" />
            {t('ui.savedSuccess')}
          </div>
        )}
      </div>
    </div>
  );
}
