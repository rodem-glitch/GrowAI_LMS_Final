// components/common/Footer.tsx — 공통 푸터

export default function Footer() {
  return (
    <footer className="border-t border-surface-border bg-surface-muted dark:bg-slate-900">
      <div className="page-container py-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white text-[10px] font-bold">G</div>
            <span className="text-sm font-semibold text-gray-700 dark:text-slate-300">GrowAI LMS</span>
          </div>
          <p className="text-xs text-content-muted text-center">
            &copy; 2026 한국폴리텍대학 학습관리시스템. All rights reserved.
          </p>
          <div className="flex items-center gap-4 text-xs text-content-muted">
            <a href="#" className="hover:text-primary transition-colors">이용약관</a>
            <a href="#" className="hover:text-primary transition-colors">개인정보처리방침</a>
            <a href="#" className="hover:text-primary transition-colors">고객센터</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
