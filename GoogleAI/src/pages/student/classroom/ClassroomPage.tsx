// pages/student/classroom/ClassroomPage.tsx — 학습실 메인 (강좌 목차)
import { useParams, Link } from 'react-router-dom';
import {
  Play, FileText, ClipboardCheck, MessageSquare,
  HelpCircle, BookOpen, CheckCircle2, Lock, Clock,
  ChevronRight,
} from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const sections = [
  {
    week: 1, title: '오리엔테이션', completed: true,
    items: [
      { type: 'video', title: '강좌 소개 영상', duration: '15:30', completed: true },
      { type: 'video', title: '개발환경 설치 가이드', duration: '25:00', completed: true },
      { type: 'assignment', title: '환경설정 확인 과제', completed: true },
    ],
  },
  {
    week: 2, title: '변수와 자료형', completed: true,
    items: [
      { type: 'video', title: '변수 선언과 사용', duration: '20:00', completed: true },
      { type: 'video', title: '기본 자료형', duration: '25:00', completed: true },
      { type: 'video', title: '형변환과 연산자', duration: '15:00', completed: true },
      { type: 'assignment', title: '자료형 실습 과제', completed: true },
    ],
  },
  {
    week: 3, title: '조건문과 반복문', completed: false,
    items: [
      { type: 'video', title: 'if-elif-else 구문', duration: '20:00', completed: true },
      { type: 'video', title: 'for 반복문', duration: '18:00', completed: false },
      { type: 'video', title: 'while 반복문', duration: '15:00', completed: false },
      { type: 'quiz', title: '조건문/반복문 퀴즈', completed: false },
    ],
  },
  {
    week: 4, title: '함수와 모듈', completed: false, locked: true,
    items: [
      { type: 'video', title: '함수 정의와 호출', duration: '22:00', completed: false },
      { type: 'video', title: '매개변수와 반환값', duration: '18:00', completed: false },
      { type: 'assignment', title: '함수 작성 과제', completed: false },
    ],
  },
];

const typeIcon = {
  video: Play,
  assignment: FileText,
  quiz: ClipboardCheck,
  discussion: MessageSquare,
};

export default function ClassroomPage() {
  const { courseCode } = useParams();

  return (
    <div className="page-container space-y-6">
      {/* Breadcrumb */}
      <nav className="text-xs text-content-muted flex items-center gap-1">
        <Link to="/courses" className="hover:text-primary">강좌목록</Link>
        <span>/</span>
        <Link to={`/courses/${courseCode}`} className="hover:text-primary">{courseCode}</Link>
        <span>/</span>
        <span className="text-content-default font-medium">학습실</span>
      </nav>

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">Python 프로그래밍 기초</h1>
          <p className="text-sm text-content-secondary mt-1">학습실 — 전체 15주차</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="text-right">
            <div className="text-sm font-bold text-gray-900 dark:text-white">37%</div>
            <div className="text-[10px] text-gray-500">진도율</div>
          </div>
          <div className="w-20">
            <ProgressBar value={37} showPercent={false} size="sm" />
          </div>
        </div>
      </div>

      {/* Quick Nav */}
      <div className="grid grid-cols-4 gap-3">
        {[
          { icon: MessageSquare, label: '토론방', path: '#' },
          { icon: HelpCircle, label: 'Q&A', path: '#' },
          { icon: BookOpen, label: '학습자료', path: '#' },
          { icon: ClipboardCheck, label: '시험', path: '#' },
        ].map((nav) => (
          <Link key={nav.label} to={nav.path} className="card-compact text-center group">
            <nav.icon className="w-5 h-5 mx-auto mb-1 text-gray-400 group-hover:text-primary transition-colors" />
            <span className="text-xs text-gray-600 dark:text-slate-400">{nav.label}</span>
          </Link>
        ))}
      </div>

      {/* Week Sections */}
      <div className="space-y-4">
        {sections.map((s) => (
          <div key={s.week} className={`card ${s.locked ? 'opacity-60' : ''}`}>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold ${
                  s.completed ? 'bg-success-50 text-success-600' : s.locked ? 'bg-gray-100 text-gray-400' : 'bg-primary-50 text-primary-600'
                }`}>
                  {s.completed ? <CheckCircle2 className="w-4 h-4" /> : s.locked ? <Lock className="w-4 h-4" /> : s.week}
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-800 dark:text-white">{s.week}주차: {s.title}</h3>
                  <p className="text-[10px] text-gray-400">{s.items.length}개 항목</p>
                </div>
              </div>
              {s.completed && <span className="badge-sm badge-success">완료</span>}
            </div>

            <div className="space-y-1.5">
              {s.items.map((item, i) => {
                const Icon = typeIcon[item.type as keyof typeof typeIcon] || FileText;
                return (
                  <Link
                    key={i}
                    to={s.locked ? '#' : item.type === 'video' ? `/classroom/${courseCode}/player/${s.week}` : `/classroom/${courseCode}/homework/${s.week}`}
                    className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors group"
                  >
                    <Icon className={`w-4 h-4 shrink-0 ${item.completed ? 'text-success-500' : 'text-gray-400'}`} />
                    <span className="flex-1 text-xs text-gray-700 dark:text-slate-300 group-hover:text-primary transition-colors">
                      {item.title}
                    </span>
                    {'duration' in item && (
                      <span className="text-[10px] text-gray-400 flex items-center gap-1"><Clock className="w-3 h-3" /> {item.duration}</span>
                    )}
                    {item.completed && <CheckCircle2 className="w-3.5 h-3.5 text-success-500 shrink-0" />}
                    <ChevronRight className="w-3 h-3 text-gray-300 shrink-0" />
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
