// pages/admin/management/LearningManagePage.tsx — 학습 관리
import { useState } from 'react';
import { Search, Download, Filter, BarChart3, Users } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const learningData = [
  { course: 'Python 프로그래밍', code: 'CS101', enrolled: 45, avgProgress: 72, completionRate: 35, activeRate: 89 },
  { course: '데이터베이스 설계', code: 'CS201', enrolled: 38, avgProgress: 58, completionRate: 22, activeRate: 82 },
  { course: 'AI 머신러닝 입문', code: 'AI301', enrolled: 52, avgProgress: 41, completionRate: 12, activeRate: 91 },
  { course: '웹 프론트엔드', code: 'WEB101', enrolled: 41, avgProgress: 93, completionRate: 78, activeRate: 95 },
  { course: '컴퓨터 네트워크', code: 'NET101', enrolled: 35, avgProgress: 65, completionRate: 40, activeRate: 85 },
];

export default function LearningManagePage() {
  const [search, setSearch] = useState('');
  const filtered = learningData.filter((d) => d.course.includes(search) || d.code.includes(search));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">학습 관리</h1>
          <p className="text-sm text-content-secondary mt-1">수강 현황 및 진도 관리</p>
        </div>
        <button className="btn-secondary"><Download className="w-4 h-4" /> 리포트 다운로드</button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-4">
        <div className="stat-card text-center">
          <div className="stat-value">211</div>
          <div className="stat-label">전체 수강생</div>
        </div>
        <div className="stat-card text-center">
          <div className="stat-value">65.8%</div>
          <div className="stat-label">평균 진도율</div>
        </div>
        <div className="stat-card text-center">
          <div className="stat-value">37.4%</div>
          <div className="stat-label">평균 수료율</div>
        </div>
        <div className="stat-card text-center">
          <div className="stat-value">88.4%</div>
          <div className="stat-label">평균 활동률</div>
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder="강좌 검색..." value={search} onChange={(e) => setSearch(e.target.value)} className="input-with-icon" />
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">강좌</th>
              <th className="table-th-center">수강생</th>
              <th className="table-th-center">평균 진도율</th>
              <th className="table-th-center">수료율</th>
              <th className="table-th-center">활동률</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((d) => (
              <tr key={d.code} className="table-row">
                <td className="table-td">
                  <div className="font-medium">{d.course}</div>
                  <div className="text-[10px] text-gray-400">{d.code}</div>
                </td>
                <td className="table-td-center">{d.enrolled}</td>
                <td className="table-td-center">
                  <div className="w-24 mx-auto"><ProgressBar value={d.avgProgress} size="sm" /></div>
                </td>
                <td className="table-td-center">
                  <span className={d.completionRate >= 50 ? 'text-success-600 font-medium' : 'text-gray-600'}>{d.completionRate}%</span>
                </td>
                <td className="table-td-center">
                  <span className={d.activeRate >= 90 ? 'text-success-600 font-medium' : 'text-gray-600'}>{d.activeRate}%</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
