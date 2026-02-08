import { useParams, Link } from 'react-router-dom';
import { Video, FileText, ClipboardList, Lock, CheckCircle, Play } from 'lucide-react';
import { useTranslation } from '@/i18n';

const weeks = [
  { week: 1, title: '개발환경과 기초', items: [
    { id: 1, title: 'Python 소개', type: 'VIDEO', duration: '25:30', completed: true },
    { id: 2, title: '개발환경 설치', type: 'VIDEO', duration: '20:00', completed: true },
    { id: 3, title: '실습: Hello World', type: 'ASSIGNMENT', completed: true },
  ]},
  { week: 2, title: '변수와 자료형', items: [
    { id: 4, title: '변수의 개념', type: 'VIDEO', duration: '30:00', completed: true },
    { id: 5, title: '자료형 이해', type: 'VIDEO', duration: '35:00', completed: true },
    { id: 6, title: '연산자', type: 'VIDEO', duration: '25:00', completed: true },
  ]},
  { week: 3, title: '조건문과 반복문', items: [
    { id: 7, title: 'if-else 조건문', type: 'VIDEO', duration: '30:00', completed: true },
    { id: 8, title: 'for/while 반복문', type: 'VIDEO', duration: '35:00', completed: true },
    { id: 9, title: '실습: 구구단 만들기', type: 'ASSIGNMENT', completed: false },
    { id: 10, title: '1~3주차 퀴즈', type: 'QUIZ', completed: false },
  ]},
  { week: 4, title: '함수와 모듈', items: [
    { id: 11, title: '함수 정의', type: 'VIDEO', duration: '30:00', locked: true },
    { id: 12, title: '모듈 활용', type: 'VIDEO', duration: '25:00', locked: true },
    { id: 13, title: '과제: 계산기 프로그램', type: 'ASSIGNMENT', locked: true },
  ]},
];

const typeIcons: Record<string, typeof Video> = { VIDEO: Video, ASSIGNMENT: ClipboardList, QUIZ: FileText, DOCUMENT: FileText };

export default function ClassroomPage() {
  const { t } = useTranslation();
  const { courseId } = useParams();
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.classroomTitle')}</h1>
        <p className="text-sm text-gray-500 mt-1">8/13 차시 완료 · 진도율 65%</p>
      </div>
      <div className="space-y-4">
        {weeks.map(w => (
          <div key={w.week} className="card p-0 overflow-hidden">
            <div className="flex items-center gap-3 px-4 py-3 bg-surface-muted dark:bg-slate-800 border-b border-gray-100 dark:border-slate-700">
              <span className="w-6 h-6 rounded-full bg-primary-100 dark:bg-primary-900/30 text-primary-600 flex items-center justify-center text-xs font-bold">{w.week}</span>
              <span className="text-sm font-medium">{w.title}</span>
            </div>
            <div className="divide-y divide-gray-50 dark:divide-slate-800">
              {w.items.map(item => {
                const Icon = typeIcons[item.type] || FileText;
                const locked = 'locked' in item && item.locked;
                return (
                  <div key={item.id} className={`flex items-center gap-3 px-4 py-3 ${locked ? 'opacity-50' : 'hover:bg-gray-50 dark:hover:bg-slate-800'} transition-colors`}>
                    {'completed' in item && item.completed ? <CheckCircle className="w-4 h-4 text-success-500 shrink-0" /> : locked ? <Lock className="w-4 h-4 text-gray-300 shrink-0" /> : <Play className="w-4 h-4 text-primary-500 shrink-0" />}
                    <Icon className="w-4 h-4 text-gray-400 shrink-0" />
                    <div className="flex-1">
                      {locked ? (
                        <span className="text-sm text-gray-400">{item.title}</span>
                      ) : item.type === 'VIDEO' ? (
                        <Link to={`/classroom/${courseId}/video/${item.id}`} className="text-sm hover:text-primary-600">{item.title}</Link>
                      ) : item.type === 'QUIZ' ? (
                        <Link to={`/classroom/${courseId}/exam/${item.id}`} className="text-sm hover:text-primary-600">{item.title}</Link>
                      ) : (
                        <Link to={`/classroom/${courseId}/homework/${item.id}`} className="text-sm hover:text-primary-600">{item.title}</Link>
                      )}
                    </div>
                    {'duration' in item && item.duration && <span className="text-[10px] text-gray-400">{item.duration}</span>}
                    <span className="badge-sm badge-gray">{item.type === 'VIDEO' ? '동영상' : item.type === 'QUIZ' ? '퀴즈' : '과제'}</span>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
