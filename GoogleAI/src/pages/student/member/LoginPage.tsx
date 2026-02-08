// pages/student/member/LoginPage.tsx — 로그인 페이지
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Lock, User, Eye, EyeOff, Sparkles } from 'lucide-react';
import { useAuthStore } from '@/stores/useAuthStore';

export default function LoginPage() {
  const [userId, setUserId] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const setUser = useAuthStore((s) => s.setUser);
  const navigate = useNavigate();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    // 데모용 즉시 로그인
    setUser({
      memberKey: 'MK001',
      userId: userId || 'demo',
      korName: '홍길동',
      email: 'demo@kopo.ac.kr',
      userType: '10',
      deptName: '컴퓨터공학과',
      campusName: '서울강서캠퍼스',
      studentNo: '2024001',
    });
    navigate('/');
  };

  // 단위테스트용 데모 계정 정보 — 버튼 클릭 시 input에 자동 입력
  const demoAccounts = {
    '10': { id: 'student001', pw: 'admin1234' },
    '30': { id: 'prof001',    pw: 'admin1234' },
    '90': { id: 'admin',      pw: 'admin1234' },
  };

  const handleDemoLogin = (type: '10' | '30' | '90') => {
    setUserId(demoAccounts[type].id);
    setPassword(demoAccounts[type].pw);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-page-gradient dark:bg-slate-950 px-4">
      <div className="w-full max-w-md space-y-6">
        {/* Logo */}
        <div className="text-center">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white text-2xl font-bold mx-auto mb-4 shadow-primary">
            G
          </div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">GrowAI LMS</h1>
          <p className="text-sm text-content-secondary mt-1">한국폴리텍대학 학습관리시스템</p>
        </div>

        {/* Login Form */}
        <form onSubmit={handleLogin} className="card space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">아이디</label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={userId}
                onChange={(e) => setUserId(e.target.value)}
                placeholder="아이디를 입력하세요"
                className="input-with-icon"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">비밀번호</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type={showPw ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="비밀번호를 입력하세요"
                className="input-with-icon pr-10"
              />
              <button type="button" onClick={() => setShowPw(!showPw)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button type="submit" className="btn-primary w-full justify-center">로그인</button>

          <div className="flex items-center justify-between text-xs text-content-muted">
            <label className="flex items-center gap-1.5 cursor-pointer">
              <input type="checkbox" className="w-3.5 h-3.5 rounded border-gray-300" />
              아이디 저장
            </label>
            <a href="#" className="hover:text-primary">비밀번호 찾기</a>
          </div>
        </form>

        {/* Demo Login */}
        <div className="card space-y-3">
          <div className="flex items-center gap-2 text-xs text-content-muted">
            <Sparkles className="w-3 h-3 text-secondary" />
            <span>데모 로그인</span>
          </div>
          <div className="grid grid-cols-3 gap-2">
            <button onClick={() => handleDemoLogin('10')} className="btn btn-sm bg-blue-50 text-blue-700 hover:bg-blue-100 justify-center">학생</button>
            <button onClick={() => handleDemoLogin('30')} className="btn btn-sm bg-purple-50 text-purple-700 hover:bg-purple-100 justify-center">교수자</button>
            <button onClick={() => handleDemoLogin('90')} className="btn btn-sm bg-emerald-50 text-emerald-700 hover:bg-emerald-100 justify-center">관리자</button>
          </div>
        </div>

        <p className="text-center text-[10px] text-content-muted">
          &copy; 2026 한국폴리텍대학. SSO 통합인증 연동 환경.
        </p>
      </div>
    </div>
  );
}
