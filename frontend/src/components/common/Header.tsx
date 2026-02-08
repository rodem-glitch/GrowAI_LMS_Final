// components/common/Header.tsx — 헤더 (다국어 지원)
import { useState } from 'react';
import { Search, Moon, Sun, Menu, User, LogOut, Bot, Home } from 'lucide-react';
import { useAuthStore } from '@/stores/useAuthStore';
import { useThemeStore } from '@/stores/useThemeStore';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from '@/i18n';
import LanguageSelector from './LanguageSelector';
import NotificationPanel from './NotificationPanel';
import BrandBanner from './BrandBanner';

interface HeaderProps {
  variant?: 'student' | 'instructor' | 'admin' | 'haksa';
  onToggleSidebar?: () => void;
}

export default function Header({ variant = 'student', onToggleSidebar }: HeaderProps) {
  const { user, logout } = useAuthStore();
  const { isDark, toggle } = useThemeStore();
  const navigate = useNavigate();
  const [showMenu, setShowMenu] = useState(false);
  const [showBrand, setShowBrand] = useState(false);
  const { t } = useTranslation();

  const homeLinks: Record<string, string> = {
    student: '/student',
    instructor: '/instructor',
    admin: '/admin',
    haksa: '/haksa',
  };

  return (
    <header className="sticky top-0 z-50 bg-white/80 dark:bg-surface-dark/80 backdrop-blur-md border-b border-gray-100 dark:border-slate-800">
      <div className="flex items-center justify-between h-14 px-4 lg:px-6">
        <div className="flex items-center gap-3">
          {onToggleSidebar && (
            <button onClick={onToggleSidebar} className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 lg:hidden">
              <Menu className="w-5 h-5" />
            </button>
          )}
          <div className="relative">
            <button
              onClick={() => setShowBrand(!showBrand)}
              className="flex items-center gap-2 hover:opacity-80 transition-opacity"
            >
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center">
                <Bot className="w-5 h-5 text-white" />
              </div>
              <span className="font-bold text-gray-900 dark:text-white text-base hidden sm:block">{t('common.appName')}</span>
            </button>
            <BrandBanner isOpen={showBrand} onClose={() => setShowBrand(false)} />
          </div>
        </div>

        <div className="hidden md:flex items-center flex-1 max-w-md mx-8">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input type="text" placeholder={t('common.searchPlaceholder')} className="input-with-icon" />
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Link to="/" className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800" title={t('common.goToMain')}>
            <Home className="w-4 h-4 text-gray-500" />
          </Link>
          {variant === 'student' && (
            <Link to="/student/ai-chat" className="btn-ghost btn-sm">
              <Bot className="w-4 h-4 text-primary-500" /> {t('common.aiHelper')}
            </Link>
          )}
          <LanguageSelector compact />
          <button onClick={toggle} className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800">
            {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <NotificationPanel />

          <div className="relative">
            <button onClick={() => setShowMenu(!showMenu)} className="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800">
              <div className="w-7 h-7 rounded-full bg-primary-100 dark:bg-primary-900 flex items-center justify-center">
                <User className="w-4 h-4 text-primary-600" />
              </div>
              <span className="text-sm font-medium hidden sm:block">{user?.name || t('common.user')}</span>
            </button>
            {showMenu && (
              <div className="absolute right-0 mt-1 w-48 bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-gray-100 dark:border-slate-700 py-1 z-50">
                <div className="px-3 py-2 border-b border-gray-100 dark:border-slate-700">
                  <div className="text-sm font-medium">{user?.name}</div>
                  <div className="text-[10px] text-gray-400">{user?.campus} · {user?.department}</div>
                </div>
                <Link to="/" onClick={() => setShowMenu(false)}
                  className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-slate-300 dark:hover:bg-slate-700">
                  <Home className="w-4 h-4" /> {t('common.goToMain')}
                </Link>
                <button onClick={() => { logout(); navigate('/login'); setShowMenu(false); }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-sm text-danger-600 hover:bg-gray-50 dark:hover:bg-slate-700">
                  <LogOut className="w-4 h-4" /> {t('common.logout')}
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
