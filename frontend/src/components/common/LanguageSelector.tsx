// components/common/LanguageSelector.tsx — 다국어 선택 드롭다운
import { useState, useRef, useEffect } from 'react';
import { Globe } from 'lucide-react';
import { useLanguageStore, type Language } from '@/stores/useLanguageStore';

const languages: { code: Language; label: string; short: string }[] = [
  { code: 'ko', label: '한국어', short: 'KO' },
  { code: 'en', label: 'English', short: 'EN' },
  { code: 'zh', label: '中文', short: 'ZH' },
  { code: 'ja', label: '日本語', short: 'JA' },
];

export default function LanguageSelector({ compact }: { compact?: boolean }) {
  const { language, setLanguage } = useLanguageStore();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const current = languages.find(l => l.code === language)!;

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(!open)}
        className={compact
          ? 'p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 flex items-center gap-1'
          : 'flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 dark:border-slate-600 hover:bg-gray-50 dark:hover:bg-slate-800 text-sm transition-colors'
        }
        title={current.label}
      >
        <Globe className="w-4 h-4 text-gray-500" />
        <span className="text-xs font-medium text-gray-700 dark:text-slate-300">{current.short}</span>
      </button>
      {open && (
        <div className="absolute right-0 mt-1 w-36 bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-gray-100 dark:border-slate-700 py-1 z-50">
          {languages.map(lang => (
            <button
              key={lang.code}
              onClick={() => { setLanguage(lang.code); setOpen(false); }}
              className={`w-full text-left px-3 py-2 text-sm hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors flex items-center justify-between ${
                language === lang.code
                  ? 'text-primary-600 font-medium bg-primary-50 dark:bg-primary-900/20'
                  : 'text-gray-700 dark:text-slate-300'
              }`}
            >
              <span>{lang.label}</span>
              <span className="text-[10px] text-gray-400 font-mono">{lang.short}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
