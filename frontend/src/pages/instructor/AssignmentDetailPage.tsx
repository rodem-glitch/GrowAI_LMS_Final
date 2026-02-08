// src/pages/instructor/AssignmentDetailPage.tsx
// 과제 상세 페이지 — 채점, 피드백, 파일 다운로드 기능

import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft, FileText, Download, CheckCircle, AlertCircle, Clock, User, BookOpen, Save,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

interface AssignmentDetail {
  id: number;
  courseName: string;
  assignmentName: string;
  description: string;
  submitter: string;
  submittedDate: string;
  status: string;
  score: string;
  fileName: string;
  feedback: string;
  dueDate: string;
}

export default function AssignmentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useTranslation();

  // Mock 상세 데이터 (i18n)
  const mockDetails: Record<string, AssignmentDetail> = {
    '1': {
      id: 1,
      courseName: t('mock.courses.pythonBasic'),
      assignmentName: t('mock.assignments.listDict'),
      description: t('mock.assignmentContents.listDictDesc'),
      submitter: t('mock.students.park'),
      submittedDate: '2026-02-05',
      status: t('mockStatus.submitted'),
      score: '-',
      fileName: 'chapter3_lab.zip',
      feedback: '',
      dueDate: '2026-02-15',
    },
    '2': {
      id: 2,
      courseName: t('mock.courses.dbDesign'),
      assignmentName: t('mock.assignments.erdProject'),
      description: t('mock.assignmentContents.erdProjectDesc'),
      submitter: t('mock.students.choi'),
      submittedDate: '-',
      status: t('mockStatus.notSubmitted'),
      score: '-',
      fileName: '',
      feedback: '',
      dueDate: '2026-02-20',
    },
    '3': {
      id: 3,
      courseName: t('mock.courses.webDev'),
      assignmentName: t('mock.assignments.reactComponent'),
      description: t('mock.assignmentContents.reactComponentDesc'),
      submitter: t('mock.students.jung'),
      submittedDate: '2026-02-03',
      status: t('mockStatus.graded'),
      score: '92',
      fileName: 'react_todo_app.zip',
      feedback: '',
      dueDate: '2026-02-10',
    },
  };

  const detail = mockDetails[id || '1'] || mockDetails['1'];

  const [score, setScore] = useState(detail.score === '-' ? '' : detail.score);
  const [feedback, setFeedback] = useState(detail.feedback);
  const [saved, setSaved] = useState(false);

  const isSubmitted = detail.status !== t('mockStatus.notSubmitted');

  const handleSaveGrade = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const statusBadge = (status: string) => {
    if (status === t('mockStatus.submitted')) return 'badge-sm badge-info';
    if (status === t('mockStatus.notSubmitted')) return 'badge-sm badge-danger';
    if (status === t('mockStatus.graded')) return 'badge-sm badge-success';
    return 'badge-sm badge-gray';
  };

  return (
    <div className="space-y-6">
      {/* 뒤로가기 + 제목 */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate('/instructor/assignments')}
          className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600 dark:text-slate-400" />
        </button>
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('ui.assignmentDetail')}</h1>
          <p className="text-sm text-gray-500 dark:text-slate-400">{detail.assignmentName}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 왼쪽: 과제 정보 + 제출 정보 */}
        <div className="lg:col-span-2 space-y-6">
          {/* 과제 정보 카드 */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <BookOpen className="w-5 h-5 text-blue-600" />
              <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('ui.assignmentInfo')}</h2>
            </div>
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-sm">
                <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('ui.courseName')}</span>
                <span className="text-gray-900 dark:text-white font-medium">{detail.courseName}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('ui.assignmentName')}</span>
                <span className="text-gray-900 dark:text-white font-medium">{detail.assignmentName}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('ui.dueDate')}</span>
                <span className="flex items-center gap-1 text-gray-900 dark:text-white">
                  <Clock className="w-3.5 h-3.5 text-gray-400" /> {detail.dueDate}
                </span>
              </div>
              <div className="text-sm">
                <span className="text-gray-500 dark:text-slate-400 block mb-1">{t('ui.content')}</span>
                <p className="text-gray-700 dark:text-slate-300 bg-gray-50 dark:bg-slate-800 rounded-lg p-3">
                  {detail.description}
                </p>
              </div>
            </div>
          </div>

          {/* 제출 정보 카드 */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <User className="w-5 h-5 text-emerald-600" />
              <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{t('ui.submissionInfo')}</h2>
              <span className={`ml-auto ${statusBadge(detail.status)}`}>{detail.status}</span>
            </div>
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-sm">
                <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('ui.submitter')}</span>
                <span className="text-gray-900 dark:text-white font-medium">{detail.submitter}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('common.date')}</span>
                <span className="text-gray-900 dark:text-white">
                  {detail.submittedDate === '-' ? '-' : detail.submittedDate}
                </span>
              </div>

              {isSubmitted && detail.fileName ? (
                <div className="flex items-center gap-3 text-sm">
                  <span className="text-gray-500 dark:text-slate-400 w-20 shrink-0">{t('ui.submittedFile')}</span>
                  <button className="flex items-center gap-2 text-blue-600 dark:text-blue-400 hover:underline">
                    <FileText className="w-4 h-4" />
                    {detail.fileName}
                    <Download className="w-3.5 h-3.5" />
                  </button>
                </div>
              ) : !isSubmitted ? (
                <div className="flex items-center gap-2 text-sm text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 rounded-lg p-3">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  {t('ui.noSubmission')}
                </div>
              ) : null}
            </div>
          </div>
        </div>

        {/* 오른쪽: 채점 + 피드백 */}
        <div className="space-y-6">
          {/* 점수 입력 */}
          <div className="card">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">{t('ui.gradeInput')}</h3>
            <input
              type="number"
              min="0"
              max="100"
              value={score}
              onChange={(e) => setScore(e.target.value)}
              disabled={!isSubmitted}
              placeholder={t('ui.gradePlaceholder')}
              className="input mb-3"
            />
            <button
              onClick={handleSaveGrade}
              disabled={!isSubmitted || !score}
              className="btn-primary w-full justify-center disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Save className="w-4 h-4" />
              {t('ui.saveGrade')}
            </button>
            {saved && (
              <div className="flex items-center gap-2 mt-3 text-sm text-emerald-600 dark:text-emerald-400">
                <CheckCircle className="w-4 h-4" />
                {t('ui.savedSuccess')}
              </div>
            )}
          </div>

          {/* 피드백 */}
          <div className="card">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">{t('ui.feedback')}</h3>
            <textarea
              rows={6}
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              disabled={!isSubmitted}
              placeholder={t('ui.feedbackPlaceholder')}
              className="input resize-none"
            />
            <button
              onClick={handleSaveGrade}
              disabled={!isSubmitted}
              className="btn-secondary w-full justify-center mt-3 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {t('ui.saveFeedback')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
