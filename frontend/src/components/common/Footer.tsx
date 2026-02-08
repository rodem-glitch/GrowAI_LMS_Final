// components/common/Footer.tsx — 푸터 (다국어 지원)
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

export default function Footer() {
  const { t } = useTranslation();

  return (
    <footer className="border-t border-gray-100 dark:border-slate-800 py-6 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-2">
        <p className="text-xs text-gray-400">{t('common.footerCopyright')}</p>
        <div className="flex items-center gap-4 text-xs text-gray-400">
          <Link to="/terms" className="hover:text-gray-600 dark:hover:text-slate-300">{t('common.terms')}</Link>
          <Link to="/privacy" className="hover:text-gray-600 dark:hover:text-slate-300 font-semibold">{t('common.privacy')}</Link>
          <Link to="/support" className="hover:text-gray-600 dark:hover:text-slate-300">{t('common.support')}</Link>
        </div>
      </div>
    </footer>
  );
}
