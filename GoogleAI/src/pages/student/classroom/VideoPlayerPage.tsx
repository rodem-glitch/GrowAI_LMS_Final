// pages/student/classroom/VideoPlayerPage.tsx — 동영상 학습 플레이어
import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  Play, Pause, Volume2, VolumeX, Maximize2,
  RotateCcw, ChevronLeft, ChevronRight, Clock,
  BookOpen, CheckCircle2, Gauge,
} from 'lucide-react';

export default function VideoPlayerPage() {
  const { courseCode, week } = useParams();
  const [isPlaying, setIsPlaying] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [progress, setProgress] = useState(35);

  return (
    <div className="page-container space-y-6">
      {/* Breadcrumb */}
      <nav className="text-xs text-content-muted flex items-center gap-1">
        <Link to={`/classroom/${courseCode}`} className="hover:text-primary">학습실</Link>
        <span>/</span>
        <span className="text-content-default font-medium">{week}주차 학습</span>
      </nav>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Player (3/4) */}
        <div className="lg:col-span-3 space-y-4">
          {/* Video Player Shell */}
          <div className="player-shell">
            {/* Toolbar */}
            <div className="player-toolbar">
              <div className="flex items-center gap-2">
                <div className="player-traffic-dot bg-red-500" />
                <div className="player-traffic-dot bg-yellow-500" />
                <div className="player-traffic-dot bg-green-500" />
                <span className="text-xs text-slate-400 ml-2">GrowAI Player</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="player-badge">HD 1080p</span>
                <span className="text-xs text-slate-500">x1.0</span>
              </div>
            </div>

            {/* Video Area */}
            <div className="relative bg-gradient-to-br from-slate-800 to-slate-900" style={{ minHeight: '380px' }}>
              <div className="absolute inset-0 flex items-center justify-center">
                {!isPlaying ? (
                  <button
                    onClick={() => setIsPlaying(true)}
                    className="btn-play w-16 h-16 rounded-full"
                  >
                    <Play className="w-6 h-6" />
                  </button>
                ) : (
                  <div className="text-slate-500 text-sm">강의 영상 재생중...</div>
                )}
              </div>
            </div>

            {/* Controls */}
            <div className="player-controls">
              {/* Progress */}
              <div className="player-progress-track mb-3">
                <div className="player-progress-fill" style={{ width: `${progress}%` }} />
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <button onClick={() => setIsPlaying(!isPlaying)} className="btn-icon-sm bg-slate-700 text-white hover:bg-slate-600">
                    {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                  </button>
                  <button className="btn-icon-sm bg-slate-700 text-slate-300 hover:bg-slate-600">
                    <RotateCcw className="w-4 h-4" />
                  </button>
                  <button onClick={() => setIsMuted(!isMuted)} className="btn-icon-sm bg-slate-700 text-slate-300 hover:bg-slate-600">
                    {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                  </button>
                  <span className="text-xs text-slate-400">12:15 / 35:00</span>
                </div>

                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1 text-xs text-slate-400">
                    <Gauge className="w-3 h-3" />
                    <select className="bg-transparent text-slate-300 text-xs outline-none">
                      <option value="1">1.0x</option>
                      <option value="1.25">1.25x</option>
                      <option value="1.5">1.5x</option>
                      <option value="2">2.0x</option>
                    </select>
                  </div>
                  <button className="btn-icon-sm bg-slate-700 text-slate-300 hover:bg-slate-600">
                    <Maximize2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Lesson Info */}
          <div className="card">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
              {week}주차: 조건문과 반복문
            </h2>
            <p className="text-sm text-content-secondary leading-relaxed">
              이번 차시에서는 Python의 if-elif-else 조건문과 for, while 반복문의 사용법을 학습합니다.
              다양한 예제를 통해 제어 구문의 활용법을 익혀봅시다.
            </p>
          </div>
        </div>

        {/* Sidebar (1/4) */}
        <aside className="space-y-4">
          <div className="card space-y-3">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">학습 정보</h3>
            <div className="space-y-2 text-xs text-gray-600 dark:text-slate-400">
              <div className="flex justify-between"><span>진도 인정 시간</span><span className="font-medium">25분 이상</span></div>
              <div className="flex justify-between"><span>현재 학습시간</span><span className="font-medium text-primary">12분 15초</span></div>
              <div className="flex justify-between"><span>유효기간</span><span className="font-medium">~02/28</span></div>
            </div>
          </div>

          <div className="card space-y-2">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">목차</h3>
            {['if-elif-else 구문', 'for 반복문', 'while 반복문'].map((item, i) => (
              <button key={i} className={`w-full text-left flex items-center gap-2 p-2 rounded-lg text-xs transition-colors ${
                i === 0 ? 'bg-primary-50 text-primary-700' : 'text-gray-600 hover:bg-gray-50 dark:text-slate-400 dark:hover:bg-slate-800'
              }`}>
                <Play className="w-3 h-3 shrink-0" />
                <span className="flex-1">{item}</span>
                {i === 0 && <CheckCircle2 className="w-3 h-3 text-success shrink-0" />}
              </button>
            ))}
          </div>

          {/* Navigation */}
          <div className="flex gap-2">
            <Link to={`/classroom/${courseCode}/player/${Number(week) - 1}`} className="btn-secondary flex-1 text-xs justify-center">
              <ChevronLeft className="w-3 h-3" /> 이전
            </Link>
            <Link to={`/classroom/${courseCode}/player/${Number(week) + 1}`} className="btn-primary flex-1 text-xs justify-center">
              다음 <ChevronRight className="w-3 h-3" />
            </Link>
          </div>
        </aside>
      </div>
    </div>
  );
}
