// components/common/Header.tsx — 공통 헤더
import { Link, useNavigate } from 'react-router-dom';
import { Search, Bell, Moon, Sun, User, LogOut, Menu } from 'lucide-react';
import { useAuthStore } from '@/stores/useAuthStore';
import { useThemeStore } from '@/stores/useThemeStore';
import clsx from 'clsx';

interface HeaderProps {
  onMenuToggle?: () => void;
  variant?: 'student' | 'instructor' | 'admin';
}

export default function Header({ onMenuToggle, variant = 'student' }: HeaderProps) {
  const { user, logout } = useAuthStore();
  const { isDark, toggle } = useThemeStore();
  const navigate = useNavigate();

  const brandLabel =
    variant === 'admin' ? '관리자' :
    variant === 'instructor' ? '교수자' : '';

  return (
    <header className="sticky top-0 z-50 bg-white dark:bg-slate-900 border-b border-surface-border">
      <div className="page-header flex items-center justify-between">
        {/* Left */}
        <div className="flex items-center gap-4">
          {onMenuToggle && (
            <button onClick={onMenuToggle} className="btn-icon-sm bg-gray-100 dark:bg-slate-800 text-gray-600 dark:text-slate-300">
              <Menu className="w-5 h-5" />
            </button>
          )}
          <Link to={variant === 'admin' ? '/admin' : variant === 'instructor' ? '/instructor' : '/'} className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white font-bold text-sm">G</div>
            <span className="text-lg font-bold text-gray-900 dark:text-white">GrowAI LMS</span>
            {brandLabel && (
              <span className="badge-sm badge-purple">{brandLabel}</span>
            )}
          </Link>
        </div>

        {/* Center — Search */}
        <div className="hidden md:flex items-center flex-1 max-w-md mx-8">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="강좌, 과정 검색..."
              className="input-with-icon"
            />
          </div>
        </div>

        {/* Right */}
        <div className="flex items-center gap-2">
          <button onClick={toggle} className="btn-icon-sm bg-gray-100 dark:bg-slate-800 text-gray-600 dark:text-slate-300" title="테마 전환">
            {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <button className="btn-icon-sm bg-gray-100 dark:bg-slate-800 text-gray-600 dark:text-slate-300 relative" title="알림">
            <Bell className="w-4 h-4" />
            <span className="absolute -top-0.5 -right-0.5 w-2 h-2 bg-danger rounded-full" />
          </button>

          {user ? (
            <div className="flex items-center gap-3 ml-2">
              <div className="hidden sm:block text-right">
                <div className="text-sm font-medium text-gray-900 dark:text-white">{user.korName}</div>
                <div className="text-[10px] text-gray-500">{user.deptName}</div>
              </div>
              <button onClick={() => { logout(); navigate('/login'); }} className="btn-icon-sm bg-gray-100 dark:bg-slate-800 text-gray-500" title="로그아웃">
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <Link to="/login" className="btn btn-sm bg-primary text-white">
              <User className="w-4 h-4" /> 로그인
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
