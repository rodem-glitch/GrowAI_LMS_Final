// i18n/index.ts — 다국어 번역 훅
import { useLanguageStore, type Language } from '@/stores/useLanguageStore';
import ko from './locales/ko';
import en from './locales/en';
import zh from './locales/zh';
import ja from './locales/ja';

const locales: Record<Language, typeof ko> = { ko, en, zh, ja };

function getNestedValue(obj: Record<string, any>, path: string): string | undefined {
  const val = path.split('.').reduce<any>((acc, key) => acc?.[key], obj);
  return typeof val === 'string' ? val : undefined;
}

export function useTranslation() {
  const { language } = useLanguageStore();

  const t = (key: string): string => {
    return getNestedValue(locales[language], key)
      ?? getNestedValue(locales.ko, key)
      ?? key;
  };

  return { t, language };
}

export type { Language };
