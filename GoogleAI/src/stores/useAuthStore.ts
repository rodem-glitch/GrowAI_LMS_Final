// stores/useAuthStore.ts — 인증 상태 관리

import { create } from 'zustand';
import type { User, UserRole } from '@/types';

interface AuthState {
  user: User | null;
  role: UserRole;
  isAuthenticated: boolean;
  setUser: (user: User) => void;
  setRole: (role: UserRole) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  role: 'student',
  isAuthenticated: false,

  setUser: (user) => {
    const role: UserRole =
      user.userType === '90' ? 'admin' :
      user.userType === '30' ? 'instructor' : 'student';
    set({ user, role, isAuthenticated: true });
  },

  setRole: (role) => set({ role }),

  logout: () => {
    localStorage.removeItem('accessToken');
    set({ user: null, role: 'student', isAuthenticated: false });
  },
}));
