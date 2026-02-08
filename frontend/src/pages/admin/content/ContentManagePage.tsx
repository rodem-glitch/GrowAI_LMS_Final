import { useState } from 'react';
import { Search, Upload, Video, FileText, Eye, Edit3, Trash2 } from 'lucide-react';
import { useTranslation } from '@/i18n';

const contents = [
  { id: 1, title: 'Python 개발환경 설치 가이드', type: '동영상', course: 'CS101', size: '245MB', uploaded: '2026-01-15', status: 'active' },
  { id: 2, title: '변수와 자료형 강의', type: '동영상', course: 'CS101', size: '380MB', uploaded: '2026-01-20', status: 'active' },
  { id: 3, title: 'DB 설계 교안', type: '문서', course: 'CS201', size: '12MB', uploaded: '2026-01-18', status: 'active' },
];

export default function ContentManagePage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.contentManageTitle')}</h1>
        <button className="btn-primary"><Upload className="w-4 h-4" /> 업로드</button>
      </div>
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder={t('common.searchPlaceholder')} value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">{t('common.name')}</th><th className="table-th-center">{t('common.type')}</th><th className="table-th-center">강좌</th><th className="table-th-center">용량</th><th className="table-th-center">{t('common.date')}</th><th className="table-th-center">{t('common.action')}</th></tr></thead>
          <tbody>
            {contents.filter(c => c.title.includes(search)).map(c => (
              <tr key={c.id} className="table-row">
                <td className="table-td"><div className="flex items-center gap-2">{c.type === '동영상' ? <Video className="w-4 h-4 text-gray-400" /> : <FileText className="w-4 h-4 text-gray-400" />}<span className="font-medium">{c.title}</span></div></td>
                <td className="table-td-center"><span className="badge-sm badge-gray">{c.type}</span></td>
                <td className="table-td-center">{c.course}</td>
                <td className="table-td-center">{c.size}</td>
                <td className="table-td-center text-xs">{c.uploaded}</td>
                <td className="table-td-center">
                  <div className="flex items-center justify-center gap-1">
                    <button className="p-1 text-gray-400 hover:text-primary-600"><Eye className="w-3.5 h-3.5" /></button>
                    <button className="p-1 text-gray-400 hover:text-primary-600"><Edit3 className="w-3.5 h-3.5" /></button>
                    <button className="p-1 text-gray-400 hover:text-danger-600"><Trash2 className="w-3.5 h-3.5" /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
