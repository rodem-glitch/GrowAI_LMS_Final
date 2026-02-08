// pages/student/course/CourseListPage.tsx — 강좌 목록 페이지
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, Filter, BookOpen, Users, Clock, Star } from 'lucide-react';

const categories = ['전체', '프로그래밍', '데이터베이스', 'AI/ML', '웹개발', '보안', '네트워크'];

const courses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', category: '프로그래밍', professor: '김교수', students: 45, credit: 3, status: 'active' as const, rating: 4.8 },
  { code: 'CS201', name: '데이터베이스 설계', category: '데이터베이스', professor: '이교수', students: 38, credit: 3, status: 'active' as const, rating: 4.5 },
  { code: 'AI301', name: 'AI 머신러닝 입문', category: 'AI/ML', professor: '박교수', students: 52, credit: 3, status: 'active' as const, rating: 4.9 },
  { code: 'WEB101', name: '웹 프론트엔드 개발', category: '웹개발', professor: '최교수', students: 41, credit: 3, status: 'active' as const, rating: 4.6 },
  { code: 'SEC201', name: '정보보안 개론', category: '보안', professor: '정교수', students: 30, credit: 3, status: 'upcoming' as const, rating: 4.3 },
  { code: 'NET101', name: '컴퓨터 네트워크', category: '네트워크', professor: '한교수', students: 35, credit: 3, status: 'active' as const, rating: 4.4 },
  { code: 'AI401', name: '딥러닝 응용', category: 'AI/ML', professor: '박교수', students: 28, credit: 3, status: 'upcoming' as const, rating: 4.7 },
  { code: 'WEB201', name: 'React 실전 프로젝트', category: '웹개발', professor: '최교수', students: 33, credit: 3, status: 'active' as const, rating: 4.8 },
];

export default function CourseListPage() {
  const [search, setSearch] = useState('');
  const [activeCategory, setActiveCategory] = useState('전체');

  const filtered = courses.filter((c) => {
    const matchSearch = c.name.includes(search) || c.professor.includes(search);
    const matchCat = activeCategory === '전체' || c.category === activeCategory;
    return matchSearch && matchCat;
  });

  return (
    <div className="page-container space-y-6">
      {/* Page Title */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">강좌 목록</h1>
        <p className="text-sm text-content-secondary mt-1">2026학년도 1학기 개설 강좌</p>
      </div>

      {/* Search + Filter */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="강좌명, 교수명 검색..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-with-icon"
          />
        </div>
        <div className="filter-bar">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`filter-chip ${activeCategory === cat ? 'filter-chip-active' : 'filter-chip-inactive'}`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Results Count */}
      <p className="text-sm text-content-muted">{filtered.length}개 강좌</p>

      {/* Course Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filtered.map((c) => (
          <Link key={c.code} to={`/courses/${c.code}`} className="card-hover group flex flex-col">
            {/* Thumbnail placeholder */}
            <div className="h-32 rounded-lg bg-gradient-to-br from-primary-50 to-secondary-50 mb-4 flex items-center justify-center">
              <BookOpen className="w-10 h-10 text-primary-300" />
            </div>

            {/* Info */}
            <div className="flex items-center gap-2 mb-2">
              <span className="badge-micro badge-info">{c.category}</span>
              {c.status === 'upcoming' && <span className="badge-micro badge-warning">예정</span>}
            </div>
            <h3 className="text-sm font-semibold text-gray-800 dark:text-white group-hover:text-primary transition-colors mb-1">
              {c.name}
            </h3>
            <p className="text-xs text-content-muted mb-3">{c.professor} | {c.credit}학점</p>

            {/* Bottom */}
            <div className="mt-auto flex items-center justify-between text-[10px] text-gray-500">
              <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {c.students}명</span>
              <span className="flex items-center gap-1"><Star className="w-3 h-3 text-amber-400" /> {c.rating}</span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
