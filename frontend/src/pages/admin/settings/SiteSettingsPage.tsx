import { useState } from 'react';
import { Save, Globe, Palette, Bell, Database, RefreshCw } from 'lucide-react';
import { useTranslation } from '@/i18n';

export default function SiteSettingsPage() {
  const { t } = useTranslation();
  const [siteName, setSiteName] = useState('GrowAI LMS');
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.siteSettingsTitle')}</h1>
        <button className="btn-primary"><Save className="w-4 h-4" /> {t('common.save')}</button>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card space-y-4">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300"><Globe className="w-4 h-4 text-primary-500" /> 기본 정보</div>
          <div><label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">사이트명</label><input type="text" value={siteName} onChange={e => setSiteName(e.target.value)} className="input" /></div>
          <div><label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">사이트 URL</label><input type="text" defaultValue="https://lms.kopo.ac.kr" className="input" /></div>
          <div><label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">관리자 이메일</label><input type="email" defaultValue="admin@kopo.ac.kr" className="input" /></div>
        </div>
        <div className="card space-y-4">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300"><Database className="w-4 h-4 text-info-500" /> 학사 연동 설정</div>
          <div><label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">연동 엔드포인트</label><input type="text" defaultValue="https://e-poly.kopo.ac.kr/api" className="input" /></div>
          <div><label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">동기화 주기</label>
            <select className="input"><option>매일 새벽 2시</option><option>매 6시간</option><option>매 12시간</option><option>수동</option></select>
          </div>
          <div className="flex items-center gap-2">
            <button className="btn btn-sm bg-info-500/10 text-info-600 hover:bg-info-500/20"><RefreshCw className="w-3 h-3" /> 즉시 동기화</button>
            <span className="text-[10px] text-gray-400">마지막: 2026-02-08 02:00</span>
          </div>
        </div>
      </div>
    </div>
  );
}
