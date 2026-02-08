import { useState } from 'react';
import { Search, Bell, MessageSquare } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

const types = ['전체', '공지', 'Q&A', '자유'];
const posts = [
  { id: 1, type: '공지', title: '2026학년도 1학기 수강신청 안내', author: '관리자', date: '2026-02-08', views: 342, comments: 5, pinned: true },
  { id: 2, type: '공지', title: 'GrowAI LMS 점검 안내', author: '관리자', date: '2026-02-07', views: 156, comments: 2, pinned: true },
  { id: 3, type: 'Q&A', title: 'Python for문 질문', author: '박학생', date: '2026-02-06', views: 45, comments: 3 },
  { id: 4, type: '자유', title: '스터디 모집합니다', author: '최학생', date: '2026-02-05', views: 78, comments: 12 },
];

export default function BoardListPage() {
  const { t } = useTranslation();
  const [type, setType] = useState('전체');
  const [search, setSearch] = useState('');
  const filtered = posts.filter(p => (type === '전체' || p.type === type) && p.title.includes(search));
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold">{t('student.boardTitle')}</h1>
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder="검색..." value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
        </div>
        <div className="filter-bar">
          {types.map(t => <button key={t} onClick={() => setType(t)} className={`filter-chip ${type === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{t}</button>)}
        </div>
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">제목</th><th className="table-th-center">작성자</th><th className="table-th-center">날짜</th><th className="table-th-center">조회</th></tr></thead>
          <tbody>
            {filtered.map(p => (
              <tr key={p.id} className="table-row">
                <td className="table-td">
                  <div className="flex items-center gap-2">
                    {p.pinned && <Bell className="w-3 h-3 text-danger-500 shrink-0" />}
                    <Link to={`/board/${p.id}`} className="hover:text-primary-600 font-medium">{p.title}</Link>
                    {p.comments > 0 && <span className="text-[10px] text-primary-500 flex items-center gap-0.5"><MessageSquare className="w-3 h-3" />{p.comments}</span>}
                  </div>
                </td>
                <td className="table-td-center text-xs">{p.author}</td>
                <td className="table-td-center text-xs">{p.date}</td>
                <td className="table-td-center text-xs">{p.views}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
