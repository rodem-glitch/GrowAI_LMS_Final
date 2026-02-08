// pages/student/board/BoardListPage.tsx — 게시판 (CSS 적용)
import { useState, useMemo } from 'react';
import { Search, Bell, MessageSquare, Eye, ChevronLeft, ChevronRight, PenSquare, Pin } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

const types = ['전체', '공지', 'Q&A', '자유'];

interface Post {
  id: number; type: string; title: string; author: string; date: string; views: number; comments: number; pinned?: boolean;
}

const posts: Post[] = [
  { id: 1, type: '공지', title: '2026학년도 1학기 수강신청 안내', author: '관리자', date: '2026-02-08', views: 342, comments: 5, pinned: true },
  { id: 2, type: '공지', title: 'GrowAI LMS 점검 안내', author: '관리자', date: '2026-02-07', views: 156, comments: 2, pinned: true },
  { id: 3, type: '공지', title: 'AI 도우미 서비스 업데이트 안내', author: '관리자', date: '2026-02-05', views: 234, comments: 8, pinned: true },
  { id: 4, type: 'Q&A', title: 'Python for문 질문', author: '박학생', date: '2026-02-06', views: 45, comments: 3 },
  { id: 5, type: '자유', title: '스터디 모집합니다', author: '최학생', date: '2026-02-05', views: 78, comments: 12 },
  { id: 6, type: 'Q&A', title: 'Spring Boot 의존성 주입 관련 질문', author: '이학생', date: '2026-02-04', views: 67, comments: 5 },
  { id: 7, type: '자유', title: '정보처리기사 실기 후기', author: '김학생', date: '2026-02-04', views: 189, comments: 15 },
  { id: 8, type: 'Q&A', title: 'React useEffect 무한루프 해결법', author: '정학생', date: '2026-02-03', views: 92, comments: 7 },
  { id: 9, type: '자유', title: '카카오 코딩테스트 준비 팁 공유', author: '한학생', date: '2026-02-03', views: 256, comments: 23 },
  { id: 10, type: 'Q&A', title: 'SQL JOIN 성능 최적화 방법', author: '송학생', date: '2026-02-02', views: 54, comments: 4 },
  { id: 11, type: '자유', title: 'AWS 자격증 합격 수기', author: '윤학생', date: '2026-02-02', views: 145, comments: 11 },
  { id: 12, type: 'Q&A', title: 'Docker 컨테이너 네트워크 설정 질문', author: '조학생', date: '2026-02-01', views: 38, comments: 2 },
  { id: 13, type: '자유', title: '졸업 프로젝트 팀원 모집 (3명)', author: '강학생', date: '2026-02-01', views: 98, comments: 8 },
  { id: 14, type: 'Q&A', title: 'Git merge conflict 해결 방법', author: '임학생', date: '2026-01-31', views: 71, comments: 6 },
  { id: 15, type: '자유', title: '개발자 취업 면접 준비 공유', author: '오학생', date: '2026-01-30', views: 312, comments: 28 },
  { id: 16, type: 'Q&A', title: 'JPA N+1 문제 해결법', author: '서학생', date: '2026-01-30', views: 83, comments: 9 },
];

const ITEMS_PER_PAGE = 10;

function getTypeBadge(type: string) {
  switch (type) {
    case '공지': return 'bg-danger-50 text-danger-600 dark:bg-danger-900/20 dark:text-danger-400 border-danger-200 dark:border-danger-800';
    case 'Q&A': return 'bg-primary-50 text-primary-600 dark:bg-primary-900/20 dark:text-primary-400 border-primary-200 dark:border-primary-800';
    case '자유': return 'bg-success-50 text-success-600 dark:bg-success-900/20 dark:text-success-400 border-success-200 dark:border-success-800';
    default: return 'bg-gray-50 text-gray-600 dark:bg-gray-900/20';
  }
}

export default function BoardListPage() {
  const { t } = useTranslation();
  const [type, setType] = useState('전체');
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  const filtered = useMemo(() =>
    posts.filter(p => (type === '전체' || p.type === type) && p.title.toLowerCase().includes(search.toLowerCase())),
    [type, search]
  );

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginated = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filtered.slice(start, start + ITEMS_PER_PAGE);
  }, [filtered, currentPage]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <PenSquare className="w-6 h-6 text-primary-500" />
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.boardTitle')}</h1>
        </div>
        <span className="badge-sm badge-info">{filtered.length}개 게시글</span>
      </div>

      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input type="text" placeholder="검색..." value={search}
              onChange={e => { setSearch(e.target.value); setCurrentPage(1); }}
              className="input-with-icon w-full" />
          </div>
          <div className="filter-bar">
            {types.map(tp => (
              <button key={tp} onClick={() => { setType(tp); setCurrentPage(1); }}
                className={`filter-chip ${type === tp ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{tp}</button>
            ))}
          </div>
        </div>
      </div>

      <div className="card overflow-hidden">
        {/* 테이블 헤더 */}
        <div className="grid grid-cols-12 gap-2 px-5 py-3 bg-gray-50 dark:bg-slate-800/50 border-b border-gray-100 dark:border-slate-700 text-[11px] font-semibold text-gray-500 dark:text-slate-400 uppercase tracking-wider">
          <div className="col-span-1 text-center">분류</div>
          <div className="col-span-7">제목</div>
          <div className="col-span-1 text-center">작성자</div>
          <div className="col-span-2 text-center">날짜</div>
          <div className="col-span-1 text-center">조회</div>
        </div>

        {/* 게시글 목록 */}
        {paginated.map((p, idx) => (
          <div key={p.id} className={`grid grid-cols-12 gap-2 px-5 py-3.5 items-center border-b border-gray-50 dark:border-slate-800 hover:bg-primary-50/30 dark:hover:bg-primary-900/10 transition-colors ${
            p.pinned ? 'bg-warning-50/30 dark:bg-warning-900/10' : idx % 2 === 0 ? '' : 'bg-gray-50/50 dark:bg-slate-800/20'
          }`}>
            <div className="col-span-1 text-center">
              <span className={`text-[10px] px-2 py-0.5 rounded-full border font-medium ${getTypeBadge(p.type)}`}>
                {p.type}
              </span>
            </div>
            <div className="col-span-7">
              <div className="flex items-center gap-2">
                {p.pinned && <Pin className="w-3 h-3 text-warning-500 shrink-0 rotate-45" />}
                <Link to={`/board/${p.id}`}
                  className="text-sm font-medium text-gray-800 dark:text-slate-200 hover:text-primary-600 dark:hover:text-primary-400 transition-colors truncate">
                  {p.title}
                </Link>
                {p.comments > 0 && (
                  <span className="text-[10px] text-primary-500 flex items-center gap-0.5 shrink-0 font-medium">
                    <MessageSquare className="w-3 h-3" />{p.comments}
                  </span>
                )}
              </div>
            </div>
            <div className="col-span-1 text-center text-xs text-gray-500 dark:text-slate-400">{p.author}</div>
            <div className="col-span-2 text-center text-xs text-gray-400 dark:text-slate-500">{p.date}</div>
            <div className="col-span-1 text-center text-xs text-gray-400 dark:text-slate-500 flex items-center justify-center gap-0.5">
              <Eye className="w-3 h-3" />{p.views}
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="p-8 text-center text-sm text-gray-400">검색 결과가 없습니다.</div>
        )}
      </div>

      {/* 페이지네이션 */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-1 pt-2">
          <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
            className="rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 dark:text-gray-400 dark:hover:bg-gray-700">
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
            <button key={p} onClick={() => setCurrentPage(p)}
              className={`min-w-[32px] rounded-md px-3 py-2 text-xs font-medium transition-colors ${
                currentPage === p ? 'bg-primary-600 text-white' : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
              }`}>{p}</button>
          ))}
          <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
            className="rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 dark:text-gray-400 dark:hover:bg-gray-700">
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      )}
    </div>
  );
}
