// stores/useThemeStore.ts — 테마 관리
import { create } from 'zustand';

interface ThemeState {
  isDark: boolean;
  toggle: () => void;
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  isDark: localStorage.getItem('theme') === 'dark',
  toggle: () => {
    const next = !get().isDark;
    document.documentElement.classList.toggle('dark', next);
    localStorage.setItem('theme', next ? 'dark' : 'light');
    set({ isDark: next });
  }
}));
