// stores/useAuthStore.ts — 인증 상태 관리
import { create } from 'zustand';

interface AuthState {
  user: { userId: string; name: string; userType: string; campus?: string; department?: string } | null;
  isAuthenticated: boolean;
  role: 'student' | 'instructor' | 'admin';
  setUser: (user: AuthState['user'], accessToken: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  role: 'student',
  setUser: (user, accessToken) => {
    localStorage.setItem('accessToken', accessToken);
    const role = user?.userType === 'ADMIN' ? 'admin'
      : user?.userType === 'INSTRUCTOR' || user?.userType === 'TUTOR' ? 'instructor'
      : 'student';
    set({ user, isAuthenticated: true, role });
  },
  logout: () => {
    localStorage.removeItem('accessToken');
    set({ user: null, isAuthenticated: false, role: 'student' });
  }
}));
