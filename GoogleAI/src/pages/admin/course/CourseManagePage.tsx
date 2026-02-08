// pages/admin/course/CourseManagePage.tsx — 관리자 과정 관리
import { useState } from 'react';
import { Search, Plus, Edit3, Trash2, Eye, Filter, Download } from 'lucide-react';

const courses = [
  { code: 'CS101', name: 'Python 프로그래밍 기초', category: '프로그래밍', professor: '김교수', students: 45, semester: '2026-1', status: 'active' },
  { code: 'CS201', name: '데이터베이스 설계', category: '데이터베이스', professor: '이교수', students: 38, semester: '2026-1', status: 'active' },
  { code: 'AI301', name: 'AI 머신러닝 입문', category: 'AI/ML', professor: '박교수', students: 52, semester: '2026-1', status: 'active' },
  { code: 'WEB101', name: '웹 프론트엔드 개발', category: '웹개발', professor: '최교수', students: 41, semester: '2026-1', status: 'active' },
  { code: 'SEC201', name: '정보보안 개론', category: '보안', professor: '정교수', students: 0, semester: '2026-1', status: 'upcoming' },
  { code: 'NET101', name: '컴퓨터 네트워크', category: '네트워크', professor: '한교수', students: 35, semester: '2026-1', status: 'active' },
];

export default function CourseManagePage() {
  const [search, setSearch] = useState('');
  const filtered = courses.filter((c) => c.name.includes(search) || c.code.includes(search));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">과정 관리</h1>
          <p className="text-sm text-content-secondary mt-1">전체 {courses.length}개 과정</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-secondary"><Download className="w-4 h-4" /> 엑셀</button>
          <button className="btn-primary"><Plus className="w-4 h-4" /> 과정 등록</button>
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder="과정명, 코드 검색..." value={search} onChange={(e) => setSearch(e.target.value)} className="input-with-icon" />
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">코드</th>
              <th className="table-th">과정명</th>
              <th className="table-th-center">분류</th>
              <th className="table-th-center">담당교수</th>
              <th className="table-th-center">수강생</th>
              <th className="table-th-center">학기</th>
              <th className="table-th-center">상태</th>
              <th className="table-th-center">관리</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((c) => (
              <tr key={c.code} className="table-row">
                <td className="table-td font-medium text-primary">{c.code}</td>
                <td className="table-td font-medium">{c.name}</td>
                <td className="table-td-center"><span className="badge-micro badge-info">{c.category}</span></td>
                <td className="table-td-center">{c.professor}</td>
                <td className="table-td-center">{c.students}</td>
                <td className="table-td-center">{c.semester}</td>
                <td className="table-td-center">
                  {c.status === 'active' ? <span className="badge-sm badge-success">운영중</span> : <span className="badge-sm badge-warning">예정</span>}
                </td>
                <td className="table-td-center">
                  <div className="flex items-center justify-center gap-1">
                    <button className="p-1 text-gray-400 hover:text-primary transition-colors" title="보기"><Eye className="w-3.5 h-3.5" /></button>
                    <button className="p-1 text-gray-400 hover:text-primary transition-colors" title="수정"><Edit3 className="w-3.5 h-3.5" /></button>
                    <button className="p-1 text-gray-400 hover:text-danger transition-colors" title="삭제"><Trash2 className="w-3.5 h-3.5" /></button>
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
