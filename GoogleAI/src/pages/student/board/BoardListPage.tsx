// pages/student/board/BoardListPage.tsx — 게시판 목록
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, MessageSquare, Eye, Clock } from 'lucide-react';

const boardTypes = ['전체', '공지사항', 'FAQ', 'Q&A'];

const posts = [
  { id: 1, type: '공지사항', title: '2026학년도 1학기 수강신청 안내', author: '관리자', date: '2026-02-07', views: 1243, comments: 5, pinned: true },
  { id: 2, type: '공지사항', title: '시스템 점검 안내 (2/15 새벽)', author: '관리자', date: '2026-02-06', views: 856, comments: 2, pinned: true },
  { id: 3, type: '공지사항', title: 'AI 학습 도우미 서비스 오픈', author: '관리자', date: '2026-02-05', views: 672, comments: 12, pinned: false },
  { id: 4, type: 'FAQ', title: '수강신청 변경은 어떻게 하나요?', author: '관리자', date: '2026-02-04', views: 421, comments: 1, pinned: false },
  { id: 5, type: 'Q&A', title: 'Python 과제 제출 관련 문의', author: '홍길동', date: '2026-02-03', views: 45, comments: 3, pinned: false },
  { id: 6, type: 'FAQ', title: '수료증 발급 방법을 알려주세요', author: '관리자', date: '2026-02-02', views: 389, comments: 0, pinned: false },
  { id: 7, type: 'Q&A', title: 'DB 과제 기한 연장 가능한가요?', author: '김학생', date: '2026-02-01', views: 32, comments: 1, pinned: false },
  { id: 8, type: '공지사항', title: '동계 특강 수료증 발급 안내', author: '관리자', date: '2026-01-28', views: 534, comments: 3, pinned: false },
];

export default function BoardListPage() {
  const [activeType, setActiveType] = useState('전체');
  const [search, setSearch] = useState('');

  const filtered = posts.filter((p) => {
    const matchType = activeType === '전체' || p.type === activeType;
    const matchSearch = p.title.includes(search);
    return matchType && matchSearch;
  });

  return (
    <div className="page-container space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">게시판</h1>
        <p className="text-sm text-content-secondary mt-1">공지사항, FAQ, Q&A</p>
      </div>

      {/* Filter + Search */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="filter-bar">
          {boardTypes.map((t) => (
            <button
              key={t}
              onClick={() => setActiveType(t)}
              className={`filter-chip ${activeType === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}
            >
              {t}
            </button>
          ))}
        </div>
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="검색..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-with-icon"
          />
        </div>
      </div>

      {/* Posts Table */}
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th w-20">분류</th>
              <th className="table-th">제목</th>
              <th className="table-th-center w-20">작성자</th>
              <th className="table-th-center w-24">날짜</th>
              <th className="table-th-center w-16">조회</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => (
              <tr key={p.id} className={`table-row ${p.pinned ? 'bg-primary-50/50 dark:bg-primary-900/10' : ''}`}>
                <td className="table-td">
                  <span className={`badge-micro ${
                    p.type === '공지사항' ? 'badge-danger' : p.type === 'FAQ' ? 'badge-info' : 'badge-gray'
                  }`}>{p.type}</span>
                </td>
                <td className="table-td">
                  <Link to={`/board/${p.id}`} className="text-gray-800 dark:text-slate-200 hover:text-primary transition-colors">
                    {p.pinned && <span className="text-danger font-bold mr-1">[필독]</span>}
                    {p.title}
                    {p.comments > 0 && (
                      <span className="text-primary ml-1 text-[10px]">[{p.comments}]</span>
                    )}
                  </Link>
                </td>
                <td className="table-td-center text-[10px]">{p.author}</td>
                <td className="table-td-center text-[10px]">{p.date}</td>
                <td className="table-td-center text-[10px]">{p.views}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
