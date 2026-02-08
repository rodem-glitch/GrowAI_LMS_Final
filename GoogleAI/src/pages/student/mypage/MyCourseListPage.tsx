// pages/student/mypage/MyCourseListPage.tsx — 수강중인 강좌 목록
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { BookOpen, Clock, CheckCircle2 } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const tabs = ['수강중', '수료', '미수료'];

const courses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', professor: '김교수', progress: 85, status: '수강중', semester: '2026-1' },
  { code: 'CS201', name: '데이터베이스 설계', professor: '이교수', progress: 62, status: '수강중', semester: '2026-1' },
  { code: 'AI301', name: 'AI 머신러닝 입문', professor: '박교수', progress: 45, status: '수강중', semester: '2026-1' },
  { code: 'WEB101', name: '웹 프론트엔드 개발', professor: '최교수', progress: 93, status: '수강중', semester: '2026-1' },
  { code: 'CS100', name: '컴퓨터개론', professor: '정교수', progress: 100, status: '수료', semester: '2025-2' },
  { code: 'WEB100', name: 'HTML/CSS 기초', professor: '최교수', progress: 100, status: '수료', semester: '2025-2' },
];

export default function MyCourseListPage() {
  const [activeTab, setActiveTab] = useState('수강중');
  const filtered = courses.filter((c) => c.status === activeTab);

  return (
    <div className="page-container space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">내 강좌</h1>
        <p className="text-sm text-content-secondary mt-1">수강 현황 및 학습 이력</p>
      </div>

      {/* Tabs */}
      <div className="filter-bar">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`filter-chip ${activeTab === tab ? 'filter-chip-active' : 'filter-chip-inactive'}`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Course List */}
      <div className="space-y-3">
        {filtered.map((c) => (
          <Link key={c.code} to={`/classroom/${c.code}`} className="card-hover flex items-center gap-4 group">
            <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-primary-50 to-secondary-50 flex items-center justify-center shrink-0">
              <BookOpen className="w-6 h-6 text-primary-400" />
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="text-sm font-semibold text-gray-800 dark:text-white group-hover:text-primary transition-colors truncate">{c.name}</h3>
              <p className="text-xs text-content-muted mt-0.5">{c.professor} | {c.semester}</p>
            </div>
            <div className="w-32 shrink-0">
              <ProgressBar value={c.progress} variant={c.progress === 100 ? 'success' : 'default'} size="sm" />
            </div>
            {c.progress === 100 && (
              <span className="badge-sm badge-success"><CheckCircle2 className="w-3 h-3" /> 수료</span>
            )}
          </Link>
        ))}
        {filtered.length === 0 && (
          <div className="card text-center py-12 text-content-muted text-sm">
            해당 상태의 강좌가 없습니다.
          </div>
        )}
      </div>
    </div>
  );
}
