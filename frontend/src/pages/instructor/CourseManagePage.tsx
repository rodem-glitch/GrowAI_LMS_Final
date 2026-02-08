import { useTranslation } from '@/i18n';
import { BookOpen, Users, BarChart3, Settings } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const courses = [
  { id: 1, title: 'Python 프로그래밍 기초', code: 'CS101', students: 35, avgProgress: 65, completion: 12, pending: 5 },
  { id: 2, title: '데이터베이스 설계', code: 'CS201', students: 28, avgProgress: 45, completion: 5, pending: 3 },
  { id: 3, title: '웹 개발 실무', code: 'WEB101', students: 38, avgProgress: 55, completion: 8, pending: 8 },
  { id: 4, title: 'Java 프로그래밍 심화', code: 'CS401', students: 42, avgProgress: 72, completion: 18, pending: 3 },
  { id: 5, title: '네트워크 보안', code: 'CS402', students: 31, avgProgress: 38, completion: 4, pending: 7 },
  { id: 6, title: '모바일 앱 개발', code: 'CS403', students: 45, avgProgress: 60, completion: 15, pending: 6 },
  { id: 7, title: '클라우드 컴퓨팅', code: 'CS404', students: 27, avgProgress: 85, completion: 22, pending: 1 },
  { id: 8, title: '소프트웨어 공학', code: 'CS405', students: 33, avgProgress: 50, completion: 8, pending: 5 },
  { id: 9, title: '임베디드 시스템', code: 'CS406', students: 25, avgProgress: 30, completion: 0, pending: 2 },
];

export default function CourseManagePage() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.myCoursesTitle')}</h1>
      <div className="space-y-4">
        {courses.map(c => (
          <div key={c.id} className="card p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="text-sm font-semibold">{c.title}</div>
                <div className="text-[10px] text-gray-400">{c.code}</div>
              </div>
              <button className="btn-ghost btn-sm"><Settings className="w-3 h-3" /> {t('common.manage')}</button>
            </div>
            <div className="grid grid-cols-4 gap-4 mb-3">
              <div className="text-center"><div className="text-lg font-bold text-primary-600">{c.students}</div><div className="text-[10px] text-gray-400">수강생</div></div>
              <div className="text-center"><div className="text-lg font-bold text-success-600">{c.completion}</div><div className="text-[10px] text-gray-400">수료</div></div>
              <div className="text-center"><div className="text-lg font-bold text-warning-600">{c.pending}</div><div className="text-[10px] text-gray-400">미채점</div></div>
              <div className="text-center"><div className="text-lg font-bold">{c.avgProgress}%</div><div className="text-[10px] text-gray-400">평균진도</div></div>
            </div>
            <ProgressBar value={c.avgProgress} size="sm" label="전체 진도율" />
          </div>
        ))}
      </div>
    </div>
  );
}
