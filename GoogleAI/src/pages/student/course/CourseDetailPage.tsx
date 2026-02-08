// pages/student/course/CourseDetailPage.tsx — 강좌 상세 페이지
import { useParams, Link } from 'react-router-dom';
import {
  BookOpen, Clock, Users, Star, Calendar, Play,
  FileText, ClipboardCheck, ArrowRight, CheckCircle2,
} from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const weekPlan = [
  { week: 1, title: '오리엔테이션 및 개발환경 설정', type: 'video', duration: 50, completed: true },
  { week: 2, title: '변수와 자료형', type: 'video', duration: 60, completed: true },
  { week: 3, title: '조건문과 반복문', type: 'video', duration: 55, completed: true },
  { week: 4, title: '함수와 모듈', type: 'video', duration: 65, completed: false },
  { week: 5, title: '리스트와 딕셔너리', type: 'video', duration: 60, completed: false },
  { week: 6, title: '파일 입출력', type: 'video', duration: 50, completed: false },
  { week: 7, title: '중간고사', type: 'exam', duration: 90, completed: false },
  { week: 8, title: '객체지향 프로그래밍 기초', type: 'video', duration: 70, completed: false },
];

export default function CourseDetailPage() {
  const { courseCode } = useParams();

  return (
    <div className="page-container space-y-6">
      {/* Breadcrumb */}
      <nav className="text-xs text-content-muted flex items-center gap-1">
        <Link to="/courses" className="hover:text-primary">강좌목록</Link>
        <span>/</span>
        <span className="text-content-default font-medium">{courseCode}</span>
      </nav>

      {/* Hero */}
      <div className="card p-0 overflow-hidden">
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-white">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <span className="badge-sm bg-white/20 text-white">프로그래밍</span>
                <span className="badge-sm bg-white/20 text-white">3학점</span>
              </div>
              <h1 className="text-xl font-bold mb-1">Python 프로그래밍 기초</h1>
              <p className="text-sm text-blue-100">김교수 | 2026-1학기 | 수 13:00~15:00</p>
            </div>
            <Link to={`/classroom/${courseCode}`} className="btn btn-md bg-white text-indigo-700 hover:bg-blue-50 font-semibold">
              <Play className="w-4 h-4" /> 학습실 입장
            </Link>
          </div>
        </div>

        <div className="p-6 grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="text-center">
            <Users className="w-5 h-5 text-primary mx-auto mb-1" />
            <div className="text-lg font-bold text-gray-900 dark:text-white">45</div>
            <div className="text-[10px] text-gray-500">수강생</div>
          </div>
          <div className="text-center">
            <Clock className="w-5 h-5 text-secondary mx-auto mb-1" />
            <div className="text-lg font-bold text-gray-900 dark:text-white">15주</div>
            <div className="text-[10px] text-gray-500">총 차시</div>
          </div>
          <div className="text-center">
            <Star className="w-5 h-5 text-amber-400 mx-auto mb-1" />
            <div className="text-lg font-bold text-gray-900 dark:text-white">4.8</div>
            <div className="text-[10px] text-gray-500">평점</div>
          </div>
          <div className="text-center">
            <CheckCircle2 className="w-5 h-5 text-success mx-auto mb-1" />
            <div className="text-lg font-bold text-gray-900 dark:text-white">37%</div>
            <div className="text-[10px] text-gray-500">진도율</div>
          </div>
        </div>
      </div>

      {/* Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Week Plan (2/3) */}
        <section className="lg:col-span-2 space-y-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">차시 계획</h2>
          <div className="space-y-2">
            {weekPlan.map((w) => (
              <Link
                key={w.week}
                to={w.type === 'exam' ? `/classroom/${courseCode}/exam/${w.week}` : `/classroom/${courseCode}/player/${w.week}`}
                className="card-compact flex items-center gap-4 group"
              >
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${
                  w.completed ? 'bg-success-50 text-success-600' : 'bg-gray-100 dark:bg-slate-700 text-gray-400'
                }`}>
                  {w.completed ? <CheckCircle2 className="w-5 h-5" /> : <span className="text-sm font-bold">{w.week}</span>}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-medium text-gray-800 dark:text-white group-hover:text-primary transition-colors">{w.title}</h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="badge-micro badge-gray">{w.type === 'exam' ? '시험' : '동영상'}</span>
                    <span className="text-[10px] text-gray-400">{w.duration}분</span>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-gray-300 group-hover:text-primary transition-colors shrink-0" />
              </Link>
            ))}
          </div>
        </section>

        {/* Sidebar Info (1/3) */}
        <aside className="space-y-4">
          <div className="card space-y-4">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">내 학습 현황</h3>
            <ProgressBar value={37} label="진도율" />
            <ProgressBar value={80} label="출석률" variant="success" />
            <div className="section-divider !mt-4 !pt-4">
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-500">중간고사</span>
                <span className="font-medium text-gray-700 dark:text-slate-300">미응시</span>
              </div>
              <div className="flex items-center justify-between text-xs mt-2">
                <span className="text-gray-500">과제</span>
                <span className="font-medium text-gray-700 dark:text-slate-300">1/3 제출</span>
              </div>
            </div>
          </div>

          <div className="card space-y-3">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">강좌 정보</h3>
            <div className="text-xs text-gray-600 dark:text-slate-400 space-y-2">
              <div className="flex justify-between"><span>강좌코드</span><span className="font-medium">{courseCode}</span></div>
              <div className="flex justify-between"><span>학기</span><span className="font-medium">2026-1학기</span></div>
              <div className="flex justify-between"><span>강의시간</span><span className="font-medium">수 13:00~15:00</span></div>
              <div className="flex justify-between"><span>강의실</span><span className="font-medium">공학관 301호</span></div>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
