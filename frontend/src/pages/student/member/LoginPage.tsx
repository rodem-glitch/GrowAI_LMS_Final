import { useState } from 'react';
import { Bot, LogIn, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';
import { authApi } from '@/services/api';
import { extractErrorMessage } from '@/utils/errorHandler';
import { useTranslation } from '@/i18n';
import LanguageSelector from '@/components/common/LanguageSelector';

export default function LoginPage() {
  const [userId, setUserId] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const { setUser } = useAuthStore();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const doLogin = async (id: string, pw: string) => {
    setLoading(true);
    setError('');
    try {
      const res = await authApi.login(id, pw);
      const d = res.data?.data;
      if (d) {
        setUser(
          { userId: d.userId, name: d.name, userType: d.userType, campus: d.campus, department: d.department },
          d.accessToken
        );
        navigate('/');
      }
    } catch (err: any) {
      setError(extractErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!userId || !password) return;
    doLogin(userId, password);
  };

  // 데모 계정 — API 우회, 즉시 로그인
  const demoProfiles: Record<string, { userId: string; name: string; userType: string; campus: string; department: string }> = {
    student:    { userId: 'student01',    name: '김학생', userType: 'STUDENT',    campus: '서울강서', department: '컴퓨터공학과' },
    instructor: { userId: 'instructor01', name: '박교수', userType: 'INSTRUCTOR', campus: '서울강서', department: '컴퓨터공학과' },
    admin:      { userId: 'admin',        name: '관리자', userType: 'ADMIN',      campus: '본부',     department: '교육혁신원' },
  };

  const demoLogin = (type: string) => {
    const profile = demoProfiles[type];
    setUserId(profile.userId);
    setPassword('••••••••');
    setUser(profile, 'demo-token-' + type);
    navigate('/');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-600 via-primary-500 to-secondary-500 p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center mx-auto mb-4">
            <Bot className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">{t('common.appName')}</h1>
          <p className="text-primary-100 text-sm mt-1">{t('login.subtitle')}</p>
        </div>

        <div className="card p-6 space-y-4">
          {/* 언어 선택 */}
          <div className="flex justify-end">
            <LanguageSelector />
          </div>

          <form onSubmit={handleLogin} className="space-y-3">
            <input type="text" value={userId} onChange={e => setUserId(e.target.value)} placeholder={t('login.userId')} className="input" disabled={loading} />
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder={t('login.password')} className="input" disabled={loading} />
            {error && <p className="text-xs text-red-500">{error}</p>}
            <button type="submit" className="btn-primary w-full justify-center" disabled={loading}>
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <LogIn className="w-4 h-4" />}
              {loading ? t('login.loggingIn') : t('login.loginBtn')}
            </button>
          </form>

          <div className="relative"><div className="absolute inset-0 flex items-center"><div className="w-full border-t border-gray-200 dark:border-slate-700" /></div><div className="relative flex justify-center"><span className="px-2 text-[10px] text-gray-400 bg-white dark:bg-surface-dark-card">{t('login.demoLogin')}</span></div></div>

          <div className="grid grid-cols-3 gap-2">
            <button onClick={() => demoLogin('student')} className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-lg bg-blue-50 text-blue-700 font-medium text-sm border border-blue-200 hover:bg-blue-100 hover:border-blue-300 transition-all duration-200 disabled:opacity-50" disabled={loading}>{t('login.student')}</button>
            <button onClick={() => demoLogin('instructor')} className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-lg bg-emerald-50 text-emerald-700 font-medium text-sm border border-emerald-200 hover:bg-emerald-100 hover:border-emerald-300 transition-all duration-200 disabled:opacity-50" disabled={loading}>{t('login.instructor')}</button>
            <button onClick={() => demoLogin('admin')} className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-lg bg-violet-50 text-violet-700 font-medium text-sm border border-violet-200 hover:bg-violet-100 hover:border-violet-300 transition-all duration-200 disabled:opacity-50" disabled={loading}>{t('login.admin')}</button>
          </div>

          <button onClick={() => navigate('/simulation')} className="flex items-center justify-center gap-1.5 w-full px-4 py-2.5 rounded-lg bg-amber-50 text-amber-700 font-medium text-sm border border-amber-200 hover:bg-amber-100 hover:border-amber-300 transition-all duration-200 disabled:opacity-50 mt-2" disabled={loading}>
            {t('login.simulation')}
          </button>
        </div>
      </div>
    </div>
  );
}
