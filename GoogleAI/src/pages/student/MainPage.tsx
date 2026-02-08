// pages/student/MainPage.tsx — 메인 페이지 (학생 홈)
import { Link } from 'react-router-dom';
import {
  BookOpen, GraduationCap, Users, BarChart3,
  Sparkles, ArrowRight, Play, Clock, CheckCircle2,
  TrendingUp, Award, Bot,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';

// Mock 데이터
const stats = [
  { icon: BookOpen, label: '수강중 강좌', value: 5, change: '+2', trend: 'up' as const },
  { icon: GraduationCap, label: '수료 완료', value: 12, change: '+1', trend: 'up' as const },
  { icon: Clock, label: '이번주 학습', value: '14h', trend: 'neutral' as const },
  { icon: TrendingUp, label: '평균 진도율', value: '78%', change: '+5%', trend: 'up' as const },
];

const myCourses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', professor: '김교수', progress: 85, thumbnail: '🐍' },
  { code: 'CS201', name: '데이터베이스 설계', professor: '이교수', progress: 62, thumbnail: '🗄️' },
  { code: 'AI301', name: 'AI 머신러닝 입문', professor: '박교수', progress: 45, thumbnail: '🤖' },
  { code: 'WEB101', name: '웹 프론트엔드 개발', professor: '최교수', progress: 93, thumbnail: '🌐' },
];

const notices = [
  { id: 1, title: '2026학년도 1학기 수강신청 안내', date: '2026-02-07', isNew: true },
  { id: 2, title: '시스템 점검 안내 (2/15 새벽)', date: '2026-02-06', isNew: true },
  { id: 3, title: 'AI 학습 도우미 서비스 오픈', date: '2026-02-05', isNew: false },
  { id: 4, title: '동계 특강 수료증 발급 안내', date: '2026-02-03', isNew: false },
];

export default function MainPage() {
  return (
    <div className="page-container space-y-8">
      {/* Hero Banner */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 p-8 text-white">
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-2">
            <Sparkles className="w-5 h-5 text-yellow-300" />
            <span className="badge-sm bg-white/20 text-white">AI 기반 학습 추천</span>
          </div>
          <h1 className="text-2xl font-bold mb-2">안녕하세요, 학습자님!</h1>
          <p className="text-blue-100 text-sm max-w-lg">
            오늘도 한 걸음 더 성장하세요. AI가 분석한 맞춤형 학습 경로가 준비되어 있습니다.
          </p>
          <div className="flex items-center gap-3 mt-5">
            <Link to="/courses" className="btn btn-md bg-white text-indigo-700 hover:bg-blue-50 font-semibold">
              <BookOpen className="w-4 h-4" /> 강좌 탐색
            </Link>
            <Link to="/mypage" className="btn btn-md bg-white/15 text-white hover:bg-white/25">
              내 학습 현황 <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
        <div className="absolute -right-8 -bottom-8 opacity-10">
          <Bot className="w-48 h-48" />
        </div>
      </section>

      {/* Stats Grid */}
      <section>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <StatCard key={s.label} {...s} />
          ))}
        </div>
      </section>

      {/* Main Content: My Courses + Notices */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* My Courses (2/3) */}
        <section className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">수강중인 강좌</h2>
            <Link to="/mypage/courses" className="text-sm text-primary hover:underline flex items-center gap-1">
              전체보기 <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {myCourses.map((c) => (
              <Link key={c.code} to={`/classroom/${c.code}`} className="card-hover group">
                <div className="flex items-start gap-3 mb-3">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-50 to-secondary-50 flex items-center justify-center text-2xl">
                    {c.thumbnail}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-sm font-semibold text-gray-800 dark:text-white truncate group-hover:text-primary transition-colors">
                      {c.name}
                    </h3>
                    <p className="text-[10px] text-gray-500">{c.professor}</p>
                  </div>
                </div>
                <ProgressBar value={c.progress} size="sm" />
              </Link>
            ))}
          </div>
        </section>

        {/* Notices (1/3) */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">공지사항</h2>
            <Link to="/board" className="text-sm text-primary hover:underline flex items-center gap-1">
              전체보기 <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="card space-y-3">
            {notices.map((n) => (
              <Link key={n.id} to={`/board/${n.id}`} className="flex items-start gap-2 group">
                {n.isNew && <span className="w-1.5 h-1.5 rounded-full bg-danger mt-1.5 shrink-0" />}
                {!n.isNew && <span className="w-1.5 h-1.5 rounded-full bg-transparent mt-1.5 shrink-0" />}
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-700 dark:text-slate-300 truncate group-hover:text-primary transition-colors">
                    {n.title}
                  </p>
                  <p className="text-[10px] text-gray-400 mt-0.5">{n.date}</p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </div>

      {/* AI Recommendation Banner */}
      <section className="surface-tint-purple p-5">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center text-white">
            <Sparkles className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <h3 className="text-sm font-semibold text-purple-800">AI 추천: 다음 학습 단계</h3>
            <p className="text-xs text-purple-600 mt-0.5">
              Python 프로그래밍 기초 85% 완료 — "데이터 분석 with Python" 과정을 추천합니다.
            </p>
          </div>
          <Link to="/courses" className="btn btn-sm bg-purple-600 text-white hover:bg-purple-700">
            확인하기
          </Link>
        </div>
      </section>
    </div>
  );
}
