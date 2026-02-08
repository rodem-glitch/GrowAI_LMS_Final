// pages/student/board/BoardDetailPage.tsx — 게시글 상세
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Eye, Clock, User, MessageSquare } from 'lucide-react';

export default function BoardDetailPage() {
  const { id } = useParams();

  return (
    <div className="page-container space-y-6 max-w-3xl">
      {/* Back */}
      <Link to="/board" className="inline-flex items-center gap-1 text-sm text-content-muted hover:text-primary transition-colors">
        <ArrowLeft className="w-4 h-4" /> 목록으로
      </Link>

      {/* Post */}
      <article className="card">
        <div className="mb-4">
          <span className="badge-micro badge-danger mb-2 inline-block">공지사항</span>
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">2026학년도 1학기 수강신청 안내</h1>
          <div className="flex items-center gap-4 mt-2 text-xs text-content-muted">
            <span className="flex items-center gap-1"><User className="w-3 h-3" /> 관리자</span>
            <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> 2026-02-07</span>
            <span className="flex items-center gap-1"><Eye className="w-3 h-3" /> 1,243</span>
          </div>
        </div>

        <div className="section-divider !mt-0" />

        <div className="prose prose-sm text-content-secondary leading-relaxed space-y-3">
          <p>안녕하세요, 한국폴리텍대학 학습관리시스템 관리자입니다.</p>
          <p>2026학년도 1학기 수강신청 일정을 다음과 같이 안내드립니다.</p>
          <h3 className="text-sm font-semibold text-gray-800 dark:text-white">수강신청 일정</h3>
          <ul className="list-disc list-inside space-y-1">
            <li>1차 수강신청: 2026.02.20 ~ 2026.02.22</li>
            <li>2차 수강신청(변경): 2026.02.25 ~ 2026.02.26</li>
            <li>수강확정: 2026.03.02</li>
          </ul>
          <h3 className="text-sm font-semibold text-gray-800 dark:text-white">유의사항</h3>
          <ul className="list-disc list-inside space-y-1">
            <li>수강신청 전 강좌 계획서를 반드시 확인해주세요.</li>
            <li>선착순 마감 과목이 있으니 일정에 유의해주세요.</li>
            <li>문의사항은 학사지원팀(031-000-0000)으로 연락바랍니다.</li>
          </ul>
        </div>
      </article>

      {/* Comments */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
          <MessageSquare className="w-4 h-4" /> 댓글 5
        </h2>

        <div className="space-y-3">
          {[
            { author: '홍길동', text: '수강신청 시간이 정해져 있나요?', time: '2시간 전' },
            { author: '관리자', text: '09:00부터 신청 가능합니다.', time: '1시간 전' },
          ].map((c, i) => (
            <div key={i} className="flex items-start gap-3 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
              <div className="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center text-xs font-bold text-primary-700 shrink-0">
                {c.author[0]}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-medium text-gray-800 dark:text-white">{c.author}</span>
                  <span className="text-[10px] text-gray-400">{c.time}</span>
                </div>
                <p className="text-xs text-gray-600 dark:text-slate-300 mt-1">{c.text}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="flex gap-2">
          <input type="text" placeholder="댓글을 입력하세요..." className="input" />
          <button className="btn-primary shrink-0">등록</button>
        </div>
      </section>
    </div>
  );
}
