import { useParams, Link } from 'react-router-dom';
import { BookOpen, Users, Calendar, Clock, Award, ChevronRight } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';
import { useTranslation } from '@/i18n';

const weekPlan = [
  { week: 1, title: 'Python 개발환경 설치 및 소개', lessons: 3, completed: 3 },
  { week: 2, title: '변수, 자료형, 연산자', lessons: 3, completed: 3 },
  { week: 3, title: '조건문과 반복문', lessons: 4, completed: 2 },
  { week: 4, title: '함수와 모듈', lessons: 3, completed: 0 },
];

export default function CourseDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  return (
    <div className="space-y-6">
      <div className="card bg-gradient-to-r from-primary-600 to-secondary-500 text-white p-6">
        <div className="badge-sm bg-white/20 text-white mb-2">프로그래밍</div>
        <h1 className="text-xl font-bold">{t('student.courseDetailTitle')}</h1>
        <p className="text-primary-100 text-sm mt-1">Python 언어의 기본 문법과 프로그래밍 개념을 학습합니다.</p>
        <div className="flex gap-4 mt-4 text-xs text-primary-100">
          <span className="flex items-center gap-1"><Users className="w-3 h-3" />35명 수강중</span>
          <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />2026.03.02 ~ 06.20</span>
          <span className="flex items-center gap-1"><Clock className="w-3 h-3" />3학점 · 16주</span>
        </div>
        <Link to={`/classroom/${id}`} className="btn bg-white text-primary-700 hover:bg-primary-50 mt-4 text-sm">
          학습실 입장 <ChevronRight className="w-4 h-4" />
        </Link>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">주차별 학습 계획</h2>
          {weekPlan.map(w => (
            <div key={w.week} className="card p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="w-7 h-7 rounded-lg bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center text-xs font-bold text-primary-600">{w.week}</span>
                  <span className="text-sm font-medium">{w.title}</span>
                </div>
                <span className="text-[10px] text-gray-400">{w.completed}/{w.lessons} 완료</span>
              </div>
              <ProgressBar value={Math.round(w.completed / w.lessons * 100)} size="sm" />
            </div>
          ))}
        </div>

        <div className="space-y-4">
          <div className="card p-4">
            <h3 className="text-sm font-semibold mb-3">내 학습 현황</h3>
            <ProgressBar value={65} label="전체 진도율" />
            <div className="grid grid-cols-2 gap-3 mt-4">
              <div className="text-center"><div className="text-lg font-bold text-primary-600">8/13</div><div className="text-[10px] text-gray-400">완료 차시</div></div>
              <div className="text-center"><div className="text-lg font-bold text-success-600">92%</div><div className="text-[10px] text-gray-400">출석률</div></div>
            </div>
          </div>
          <div className="card p-4">
            <h3 className="text-sm font-semibold mb-2">강좌 정보</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between"><span className="text-gray-400">교수자</span><span>김교수</span></div>
              <div className="flex justify-between"><span className="text-gray-400">캠퍼스</span><span>서울강서</span></div>
              <div className="flex justify-between"><span className="text-gray-400">학과</span><span>컴퓨터공학과</span></div>
              <div className="flex justify-between"><span className="text-gray-400">학점</span><span>3학점</span></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
