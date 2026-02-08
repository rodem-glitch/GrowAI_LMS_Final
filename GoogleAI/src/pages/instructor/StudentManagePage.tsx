// pages/instructor/StudentManagePage.tsx — 수강생 관리
import { useState } from 'react';
import { Search, Download, Users, CheckCircle2, XCircle, Clock } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const students = [
  { key: 'MK001', name: '홍길동', studentNo: '2024001', progress: 85, attendance: 95, midterm: 88, assignment: 90, status: 'active' },
  { key: 'MK002', name: '김철수', studentNo: '2024002', progress: 72, attendance: 90, midterm: 75, assignment: 85, status: 'active' },
  { key: 'MK003', name: '이영희', studentNo: '2024003', progress: 93, attendance: 100, midterm: 95, assignment: 92, status: 'active' },
  { key: 'MK004', name: '박지민', studentNo: '2024004', progress: 45, attendance: 70, midterm: 60, assignment: 55, status: 'warning' },
  { key: 'MK005', name: '최수진', studentNo: '2024005', progress: 30, attendance: 55, midterm: null, assignment: 40, status: 'danger' },
  { key: 'MK006', name: '정민호', studentNo: '2024006', progress: 68, attendance: 85, midterm: 72, assignment: 78, status: 'active' },
  { key: 'MK007', name: '강예린', studentNo: '2024007', progress: 88, attendance: 95, midterm: 90, assignment: 88, status: 'active' },
  { key: 'MK008', name: '윤서준', studentNo: '2024008', progress: 55, attendance: 80, midterm: 65, assignment: 70, status: 'active' },
];

export default function StudentManagePage() {
  const [search, setSearch] = useState('');
  const filtered = students.filter((s) => s.name.includes(search) || s.studentNo.includes(search));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">수강생 관리</h1>
          <p className="text-sm text-content-secondary mt-1">Python 프로그래밍 기초 (CS101) — 수강생 {students.length}명</p>
        </div>
        <button className="btn-secondary">
          <Download className="w-4 h-4" /> 엑셀 다운로드
        </button>
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder="이름, 학번 검색..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input-with-icon"
        />
      </div>

      {/* Table */}
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">학번</th>
              <th className="table-th">이름</th>
              <th className="table-th-center">진도율</th>
              <th className="table-th-center">출석률</th>
              <th className="table-th-center">중간고사</th>
              <th className="table-th-center">과제</th>
              <th className="table-th-center">상태</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((s) => (
              <tr key={s.key} className="table-row">
                <td className="table-td font-medium">{s.studentNo}</td>
                <td className="table-td">{s.name}</td>
                <td className="table-td-center">
                  <div className="w-20 mx-auto">
                    <ProgressBar value={s.progress} showPercent={true} size="sm" />
                  </div>
                </td>
                <td className="table-td-center">
                  <span className={s.attendance >= 80 ? 'text-success-600' : 'text-danger-600'}>{s.attendance}%</span>
                </td>
                <td className="table-td-center">{s.midterm ?? '-'}</td>
                <td className="table-td-center">{s.assignment}</td>
                <td className="table-td-center">
                  {s.status === 'danger' ? (
                    <span className="badge-sm badge-danger">위험</span>
                  ) : s.status === 'warning' ? (
                    <span className="badge-sm badge-warning">주의</span>
                  ) : (
                    <span className="badge-sm badge-success">정상</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
