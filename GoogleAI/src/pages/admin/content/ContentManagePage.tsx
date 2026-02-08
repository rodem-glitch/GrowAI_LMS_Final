// pages/admin/content/ContentManagePage.tsx — 콘텐츠 관리
import { useState } from 'react';
import { Search, Plus, Video, FileText, BookOpen, Upload, Eye, Edit3, Trash2, Filter } from 'lucide-react';

const contentTypes = ['전체', '동영상', '문서', 'SCORM', '링크'];

const contents = [
  { id: 1, title: 'Python 개발환경 설치 가이드', type: '동영상', course: 'CS101', size: '245MB', duration: '25:30', uploaded: '2026-01-15', status: 'active' },
  { id: 2, title: '변수와 자료형 강의', type: '동영상', course: 'CS101', size: '380MB', duration: '35:00', uploaded: '2026-01-20', status: 'active' },
  { id: 3, title: 'DB 설계 교안', type: '문서', course: 'CS201', size: '12MB', duration: '-', uploaded: '2026-01-18', status: 'active' },
  { id: 4, title: 'ML 실습 노트북', type: 'SCORM', course: 'AI301', size: '56MB', duration: '-', uploaded: '2026-01-22', status: 'active' },
  { id: 5, title: 'React 공식 문서', type: '링크', course: 'WEB101', size: '-', duration: '-', uploaded: '2026-01-25', status: 'active' },
  { id: 6, title: '조건문 반복문 강의', type: '동영상', course: 'CS101', size: '310MB', duration: '30:00', uploaded: '2026-02-01', status: 'encoding' },
];

const typeIcon: Record<string, typeof Video> = { '동영상': Video, '문서': FileText, 'SCORM': BookOpen, '링크': BookOpen };

export default function ContentManagePage() {
  const [search, setSearch] = useState('');
  const [activeType, setActiveType] = useState('전체');

  const filtered = contents.filter((c) => {
    const matchSearch = c.title.includes(search);
    const matchType = activeType === '전체' || c.type === activeType;
    return matchSearch && matchType;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">콘텐츠 관리</h1>
          <p className="text-sm text-content-secondary mt-1">학습 콘텐츠 업로드 및 관리</p>
        </div>
        <button className="btn-primary"><Upload className="w-4 h-4" /> 콘텐츠 업로드</button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-4 gap-4">
        <div className="stat-card text-center"><div className="stat-value">24</div><div className="stat-label">동영상</div></div>
        <div className="stat-card text-center"><div className="stat-value">15</div><div className="stat-label">문서</div></div>
        <div className="stat-card text-center"><div className="stat-value">8</div><div className="stat-label">SCORM</div></div>
        <div className="stat-card text-center"><div className="stat-value">5.2GB</div><div className="stat-label">총 용량</div></div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder="콘텐츠 검색..." value={search} onChange={(e) => setSearch(e.target.value)} className="input-with-icon" />
        </div>
        <div className="filter-bar">
          {contentTypes.map((t) => (
            <button key={t} onClick={() => setActiveType(t)} className={`filter-chip ${activeType === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{t}</button>
          ))}
        </div>
      </div>

      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr>
              <th className="table-th">콘텐츠명</th>
              <th className="table-th-center">유형</th>
              <th className="table-th-center">강좌</th>
              <th className="table-th-center">용량</th>
              <th className="table-th-center">시간</th>
              <th className="table-th-center">업로드일</th>
              <th className="table-th-center">상태</th>
              <th className="table-th-center">관리</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((c) => {
              const Icon = typeIcon[c.type] || FileText;
              return (
                <tr key={c.id} className="table-row">
                  <td className="table-td">
                    <div className="flex items-center gap-2">
                      <Icon className="w-4 h-4 text-gray-400 shrink-0" />
                      <span className="font-medium">{c.title}</span>
                    </div>
                  </td>
                  <td className="table-td-center"><span className="badge-micro badge-gray">{c.type}</span></td>
                  <td className="table-td-center">{c.course}</td>
                  <td className="table-td-center">{c.size}</td>
                  <td className="table-td-center">{c.duration}</td>
                  <td className="table-td-center text-[10px]">{c.uploaded}</td>
                  <td className="table-td-center">
                    {c.status === 'active' ? <span className="badge-sm badge-success">활성</span> : <span className="badge-sm badge-warning">인코딩중</span>}
                  </td>
                  <td className="table-td-center">
                    <div className="flex items-center justify-center gap-1">
                      <button className="p-1 text-gray-400 hover:text-primary"><Eye className="w-3.5 h-3.5" /></button>
                      <button className="p-1 text-gray-400 hover:text-primary"><Edit3 className="w-3.5 h-3.5" /></button>
                      <button className="p-1 text-gray-400 hover:text-danger"><Trash2 className="w-3.5 h-3.5" /></button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
