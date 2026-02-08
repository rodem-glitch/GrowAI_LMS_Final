// stores/useLanguageStore.ts — 다국어 상태 관리
import { create } from 'zustand';

export type Language = 'ko' | 'en' | 'zh' | 'ja';

interface LanguageState {
  language: Language;
  setLanguage: (lang: Language) => void;
}

export const useLanguageStore = create<LanguageState>((set) => ({
  language: (localStorage.getItem('language') as Language) || 'ko',
  setLanguage: (lang) => {
    localStorage.setItem('language', lang);
    set({ language: lang });
  },
}));
