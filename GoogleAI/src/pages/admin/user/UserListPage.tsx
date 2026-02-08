// pages/admin/user/UserListPage.tsx — 회원 목록
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, Plus, Download, Users, Eye, Edit3, Trash2, RefreshCw } from 'lucide-react';

const users = [
  { key: 'MK001', name: '홍길동', userId: 'hong', type: '학생', dept: '컴퓨터공학과', campus: '서울강서', status: 'active', lastLogin: '2026-02-08 09:30' },
  { key: 'MK002', name: '김철수', userId: 'kim_cs', type: '학생', dept: '전자공학과', campus: '서울강서', status: 'active', lastLogin: '2026-02-07 14:22' },
  { key: 'MK003', name: '이영희', userId: 'lee_yh', type: '학생', dept: '컴퓨터공학과', campus: '인천', status: 'active', lastLogin: '2026-02-08 10:15' },
  { key: 'MK100', name: '김지도', userId: 'prof_kim', type: '교수', dept: '컴퓨터공학과', campus: '서울강서', status: 'active', lastLogin: '2026-02-08 08:00' },
  { key: 'MK101', name: '이교수', userId: 'prof_lee', type: '교수', dept: '데이터과학과', campus: '서울강서', status: 'active', lastLogin: '2026-02-07 16:30' },
  { key: 'MK900', name: '관리자', userId: 'admin', type: '관리자', dept: '학사지원팀', campus: '본부', status: 'active', lastLogin: '2026-02-08 07:00' },
  { key: 'MK004', name: '박지민', userId: 'park_jm', type: '학생', dept: '기계공학과', campus: '대전', status: 'inactive', lastLogin: '2026-01-15 11:00' },
];

export default function UserListPage() {
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('전체');
  const types = ['전체', '학생', '교수', '관리자'];

  const filtered = users.filter((u) => {
    const matchSearch = u.name.includes(search) || u.userId.includes(search);
    const matchType = typeFilter === '전체' || u.type === typeFilter;
    return matchSearch && matchType;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">회원 관리</h1>
          <p className="text-sm text-content-secondary mt-1">전체 {users.length}명</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn btn-sm bg-blue-50 text-blue-700 hover:bg-blue-100"><RefreshCw className="w-3 h-3" /> 동기화</button>
          <button className="btn-secondary"><Download className="w-4 h-4" /> 엑셀</button>
          <button className="btn-primary"><Plus className="w-4 h-4" /> 회원 등록</button>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder="이름, 아이디 검색..." value={search} onChange={(e) => setSearch(e.target.value)} className="input-with-icon" />
        </div>
        <div className="filter-bar">
          {types.map((t) => (
            <button key={t} onClick={() => setTypeFilter(t)} className={`filter-chip ${typeFilter === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{t}</button>
          ))}
        </div>
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">회원키</th>
              <th className="table-th">이름</th>
              <th className="table-th">아이디</th>
              <th className="table-th-center">유형</th>
              <th className="table-th">소속</th>
              <th className="table-th-center">캠퍼스</th>
              <th className="table-th-center">상태</th>
              <th className="table-th-center">최근 로그인</th>
              <th className="table-th-center">관리</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u) => (
              <tr key={u.key} className="table-row">
                <td className="table-td text-primary font-medium">{u.key}</td>
                <td className="table-td font-medium">{u.name}</td>
                <td className="table-td">{u.userId}</td>
                <td className="table-td-center">
                  <span className={`badge-micro ${u.type === '관리자' ? 'badge-danger' : u.type === '교수' ? 'badge-purple' : 'badge-info'}`}>{u.type}</span>
                </td>
                <td className="table-td">{u.dept}</td>
                <td className="table-td-center">{u.campus}</td>
                <td className="table-td-center">
                  {u.status === 'active' ? <span className="badge-sm badge-success">정상</span> : <span className="badge-sm badge-gray">비활성</span>}
                </td>
                <td className="table-td-center text-[10px]">{u.lastLogin}</td>
                <td className="table-td-center">
                  <div className="flex items-center justify-center gap-1">
                    <Link to={`/admin/users/${u.key}`} className="p-1 text-gray-400 hover:text-primary" title="상세"><Eye className="w-3.5 h-3.5" /></Link>
                    <button className="p-1 text-gray-400 hover:text-primary" title="수정"><Edit3 className="w-3.5 h-3.5" /></button>
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
