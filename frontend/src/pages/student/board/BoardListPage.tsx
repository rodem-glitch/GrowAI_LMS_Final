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
  { id: 17, type: '공지', title: '2026학년도 성적우수 장학금 신청 안내', author: '관리자', date: '2026-01-29', views: 387, comments: 12, pinned: true },
  { id: 18, type: 'Q&A', title: 'Java Stream API groupingBy 사용법 질문', author: '노학생', date: '2026-01-29', views: 58, comments: 4 },
  { id: 19, type: '자유', title: '네이버 부스트캠프 합격 후기', author: '문학생', date: '2026-01-29', views: 278, comments: 31 },
  { id: 20, type: 'Q&A', title: 'React Router v6 중첩 라우팅 구현 방법', author: '배학생', date: '2026-01-28', views: 73, comments: 6 },
  { id: 21, type: '자유', title: 'SQLD 자격증 2주 합격 공부법', author: '안학생', date: '2026-01-28', views: 195, comments: 18 },
  { id: 22, type: 'Q&A', title: 'Python 리스트 컴프리헨션 vs map 성능 차이', author: '유학생', date: '2026-01-28', views: 42, comments: 3 },
  { id: 23, type: '공지', title: '2026학년도 학사일정 변경 안내', author: '관리자', date: '2026-01-27', views: 298, comments: 7, pinned: true },
  { id: 24, type: '자유', title: '삼성 SW 역량테스트 A형 준비 스터디 모집', author: '장학생', date: '2026-01-27', views: 167, comments: 22 },
  { id: 25, type: 'Q&A', title: 'Spring Security JWT 토큰 갱신 로직 질문', author: '진학생', date: '2026-01-27', views: 89, comments: 8 },
  { id: 26, type: 'Q&A', title: 'AWS EC2 배포 시 502 Bad Gateway 에러', author: '하학생', date: '2026-01-26', views: 64, comments: 5 },
  { id: 27, type: '자유', title: '2025 DEVIEW 컨퍼런스 참가 후기', author: '황학생', date: '2026-01-26', views: 203, comments: 14 },
  { id: 28, type: 'Q&A', title: 'Docker Compose 멀티 컨테이너 환경 설정', author: '강학생', date: '2026-01-26', views: 51, comments: 4 },
  { id: 29, type: '자유', title: '카카오 인턴십 면접 후기 공유합니다', author: '노학생', date: '2026-01-25', views: 356, comments: 35 },
  { id: 30, type: 'Q&A', title: 'Git rebase vs merge 어떤 걸 써야 하나요?', author: '문학생', date: '2026-01-25', views: 76, comments: 7 },
  { id: 31, type: '공지', title: '캠퍼스 취업박람회 참가 신청 안내', author: '관리자', date: '2026-01-25', views: 245, comments: 4 },
  { id: 32, type: '자유', title: '백준 골드 달성 후기 및 공부법', author: '배학생', date: '2026-01-24', views: 184, comments: 16 },
  { id: 33, type: 'Q&A', title: 'TypeScript 제네릭 타입 추론 이해가 안 됩니다', author: '안학생', date: '2026-01-24', views: 63, comments: 5 },
  { id: 34, type: 'Q&A', title: 'SQL 서브쿼리 vs JOIN 성능 비교 질문', author: '유학생', date: '2026-01-24', views: 47, comments: 3 },
  { id: 35, type: '자유', title: '해커톤 팀원 구합니다 (프론트 2명 필요)', author: '장학생', date: '2026-01-23', views: 112, comments: 9 },
  { id: 36, type: 'Q&A', title: 'React 상태관리 Zustand vs Redux 비교', author: '진학생', date: '2026-01-23', views: 95, comments: 11 },
  { id: 37, type: '자유', title: '라인 개발자 채용 면접 팁 정리', author: '하학생', date: '2026-01-22', views: 267, comments: 24 },
  { id: 38, type: 'Q&A', title: 'Spring Boot 3.x 마이그레이션 에러 해결', author: '황학생', date: '2026-01-22', views: 82, comments: 6 },
  { id: 39, type: '자유', title: 'Junction Asia 2026 해커톤 정보 공유', author: '강학생', date: '2026-01-21', views: 134, comments: 10 },
  { id: 40, type: 'Q&A', title: '이진 탐색 트리 삭제 연산 구현 질문', author: '노학생', date: '2026-01-21', views: 35, comments: 2 },
  { id: 41, type: '공지', title: '교내 프로그래밍 경진대회 개최 안내', author: '관리자', date: '2026-01-20', views: 312, comments: 15 },
  { id: 42, type: 'Q&A', title: 'Java 멀티스레드 동기화 synchronized vs Lock', author: '문학생', date: '2026-01-20', views: 68, comments: 5 },
  { id: 43, type: '자유', title: '토스 서버 개발자 인턴 후기', author: '배학생', date: '2026-01-19', views: 289, comments: 27 },
  { id: 44, type: 'Q&A', title: 'REST API 설계 시 URL 네이밍 컨벤션', author: '안학생', date: '2026-01-18', views: 56, comments: 4 },
  { id: 45, type: '자유', title: 'GDG DevFest 2026 참관 후기', author: '유학생', date: '2026-01-17', views: 178, comments: 13 },
  { id: 46, type: 'Q&A', title: 'Python 데코레이터 활용 방법 질문', author: '장학생', date: '2026-01-17', views: 41, comments: 0 },
  { id: 47, type: '공지', title: 'LMS 시스템 정기 업데이트 완료 안내', author: '관리자', date: '2026-01-16', views: 189, comments: 3 },
  { id: 48, type: '자유', title: '쿠버네티스 입문 스터디 그룹 모집 (주 1회)', author: '진학생', date: '2026-01-15', views: 97, comments: 7 },
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
