import { useState } from 'react';
import { Search, Plus, RefreshCw } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

const types = ['전체', '학생', '교수자', '관리자'];
const users = [
  { id: 1, userId: 'admin', name: '시스템관리자', type: 'ADMIN', campus: '본부', status: 'ACTIVE' },
  { id: 2, userId: 'prof001', name: '김교수', type: 'INSTRUCTOR', campus: '서울강서', status: 'ACTIVE' },
  { id: 3, userId: 'student001', name: '박학생', type: 'STUDENT', campus: '서울강서', status: 'ACTIVE' },
  { id: 4, userId: 'student002', name: '최학생', type: 'STUDENT', campus: '인천', status: 'ACTIVE' },
  { id: 5, userId: 'admin003', name: '강관리', type: 'ADMIN', campus: '본부', status: 'ACTIVE' },
  { id: 6, userId: 'prof005', name: '노교수', type: 'INSTRUCTOR', campus: '성남', status: 'ACTIVE' },
  { id: 7, userId: 'std005', name: '문학생', type: 'STUDENT', campus: '대전', status: 'INACTIVE' },
  { id: 8, userId: 'std006', name: '배학생', type: 'STUDENT', campus: '부산', status: 'ACTIVE' },
  { id: 9, userId: 'prof006', name: '안교수', type: 'INSTRUCTOR', campus: '광주', status: 'SUSPENDED' },
  { id: 10, userId: 'std007', name: '유학생', type: 'STUDENT', campus: '인천', status: 'ACTIVE' },
  { id: 11, userId: 'std008', name: '장학생', type: 'STUDENT', campus: '서울강서', status: 'INACTIVE' },
  { id: 12, userId: 'std009', name: '진학생', type: 'STUDENT', campus: '성남', status: 'ACTIVE' },
];

const typeMap: Record<string, string> = { ADMIN: '관리자', INSTRUCTOR: '교수자', STUDENT: '학생' };

export default function UserListPage() {
  const { t } = useTranslation();
  const [type, setType] = useState('전체');
  const [search, setSearch] = useState('');
  const filtered = users.filter(u => {
    const matchType = type === '전체' || typeMap[u.type] === type;
    const matchSearch = u.name.includes(search) || u.userId.includes(search);
    return matchType && matchSearch;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.userListTitle')}</h1>
        <div className="flex gap-2">
          <button className="btn-secondary"><RefreshCw className="w-4 h-4" /> 학사 동기화</button>
          <button className="btn-primary"><Plus className="w-4 h-4" /> 사용자 추가</button>
        </div>
      </div>
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder={t('common.searchPlaceholder')} value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
        </div>
        <div className="filter-bar">
          {types.map(t => <button key={t} onClick={() => setType(t)} className={`filter-chip ${type === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{t}</button>)}
        </div>
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">ID</th><th className="table-th">{t('common.name')}</th><th className="table-th-center">{t('common.type')}</th><th className="table-th-center">캠퍼스</th><th className="table-th-center">{t('common.status')}</th></tr></thead>
          <tbody>
            {filtered.map(u => (
              <tr key={u.id} className="table-row">
                <td className="table-td font-mono text-xs"><Link to={`/admin/users/${u.id}`} className="hover:text-primary-600">{u.userId}</Link></td>
                <td className="table-td font-medium">{u.name}</td>
                <td className="table-td-center"><span className={`badge-sm ${u.type === 'ADMIN' ? 'badge-danger' : u.type === 'INSTRUCTOR' ? 'badge-info' : 'badge-gray'}`}>{typeMap[u.type]}</span></td>
                <td className="table-td-center">{u.campus}</td>
                <td className="table-td-center"><span className="badge-sm badge-success">활성</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
