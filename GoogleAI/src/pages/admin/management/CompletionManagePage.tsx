// pages/admin/management/CompletionManagePage.tsx — 수료 관리
import { useState } from 'react';
import { Search, Download, Award, CheckCircle2, XCircle, Clock } from 'lucide-react';

const completionData = [
  { name: '홍길동', studentNo: '2024001', course: 'CS101', progress: 100, attendance: 95, midterm: 88, final: 92, total: 91, status: 'completed', grade: 'A' },
  { name: '김철수', studentNo: '2024002', course: 'CS101', progress: 100, attendance: 90, midterm: 75, final: 80, total: 82, status: 'completed', grade: 'B+' },
  { name: '이영희', studentNo: '2024003', course: 'CS101', progress: 95, attendance: 100, midterm: 95, final: 98, total: 97, status: 'completed', grade: 'A+' },
  { name: '박지민', studentNo: '2024004', course: 'CS101', progress: 70, attendance: 65, midterm: 55, final: 60, total: 60, status: 'incomplete', grade: 'D' },
  { name: '최수진', studentNo: '2024005', course: 'CS101', progress: 45, attendance: 50, midterm: null, final: null, total: null, status: 'in-progress', grade: '-' },
];

export default function CompletionManagePage() {
  const [search, setSearch] = useState('');
  const filtered = completionData.filter((d) => d.name.includes(search) || d.studentNo.includes(search));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">수료 관리</h1>
          <p className="text-sm text-content-secondary mt-1">수료 현황 및 발급 관리</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-secondary"><Download className="w-4 h-4" /> 수료자 목록</button>
          <button className="btn-primary"><Award className="w-4 h-4" /> 일괄 수료처리</button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="stat-card text-center"><div className="stat-value text-success">3</div><div className="stat-label">수료</div></div>
        <div className="stat-card text-center"><div className="stat-value text-danger">1</div><div className="stat-label">미수료</div></div>
        <div className="stat-card text-center"><div className="stat-value text-amber-500">1</div><div className="stat-label">진행중</div></div>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder="이름, 학번 검색..." value={search} onChange={(e) => setSearch(e.target.value)} className="input-with-icon" />
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">학번</th>
              <th className="table-th">이름</th>
              <th className="table-th-center">진도</th>
              <th className="table-th-center">출석</th>
              <th className="table-th-center">중간</th>
              <th className="table-th-center">기말</th>
              <th className="table-th-center">총점</th>
              <th className="table-th-center">등급</th>
              <th className="table-th-center">상태</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((d) => (
              <tr key={d.studentNo} className="table-row">
                <td className="table-td font-medium">{d.studentNo}</td>
                <td className="table-td">{d.name}</td>
                <td className="table-td-center">{d.progress}%</td>
                <td className="table-td-center">{d.attendance}%</td>
                <td className="table-td-center">{d.midterm ?? '-'}</td>
                <td className="table-td-center">{d.final ?? '-'}</td>
                <td className="table-td-center font-medium">{d.total ?? '-'}</td>
                <td className="table-td-center font-bold">{d.grade}</td>
                <td className="table-td-center">
                  {d.status === 'completed' ? <span className="badge-sm badge-success"><CheckCircle2 className="w-3 h-3" /> 수료</span> :
                   d.status === 'incomplete' ? <span className="badge-sm badge-danger"><XCircle className="w-3 h-3" /> 미수료</span> :
                   <span className="badge-sm badge-warning"><Clock className="w-3 h-3" /> 진행중</span>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
