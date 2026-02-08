// pages/haksa/StudentRecordsPage.tsx -- 학적 관리
import { useState } from 'react';
import { Search, ChevronLeft, ChevronRight, Eye, Edit, X } from 'lucide-react';
import { useTranslation } from '@/i18n';

const allStudents = [
  { no: 1, studentId: '20210001', name: '김민수', department: '컴퓨터공학과', year: 3, status: '재학', admissionDate: '2021-03-02' },
  { no: 2, studentId: '20210045', name: '이서연', department: '전자공학과', year: 3, status: '재학', admissionDate: '2021-03-02' },
  { no: 3, studentId: '20200112', name: '박지훈', department: '기계공학과', year: 4, status: '휴학', admissionDate: '2020-03-02' },
  { no: 4, studentId: '20220078', name: '최예은', department: '컴퓨터공학과', year: 2, status: '재학', admissionDate: '2022-03-02' },
  { no: 5, studentId: '20190034', name: '정우진', department: '전자공학과', year: 4, status: '졸업', admissionDate: '2019-03-04' },
];

const statusBadge = (status: string) => {
  const styles: Record<string, string> = {
    '재학': 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    '휴학': 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
    '졸업': 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  };
  return styles[status] || 'bg-gray-50 text-gray-700';
};

export default function StudentRecordsPage() {
  const { t } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [department, setDepartment] = useState('전체');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedStudent, setSelectedStudent] = useState<typeof allStudents[0] | null>(null);

  // 검색 및 필터 적용
  const filtered = allStudents.filter(s => {
    const matchSearch = searchQuery === '' || s.name.includes(searchQuery) || s.studentId.includes(searchQuery);
    const matchDept = department === '전체' || s.department === department;
    return matchSearch && matchDept;
  });

  const handleSearch = () => {
    setCurrentPage(1);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.studentRecordsTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.studentRecordsDesc')}</p>
      </div>

      {/* 검색 바 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="학번 또는 이름 검색..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
            />
          </div>
          <select
            value={department}
            onChange={(e) => setDepartment(e.target.value)}
            className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="전체">{t('common.all')}</option>
            <option value="컴퓨터공학과">컴퓨터공학과</option>
            <option value="전자공학과">전자공학과</option>
            <option value="기계공학과">기계공학과</option>
          </select>
          <button
            onClick={handleSearch}
            className="px-4 py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors"
          >
            {t('common.search')}
          </button>
        </div>
      </div>

      {/* 학적 테이블 */}
      <section className="card space-y-4">
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">No</th>
                <th className="table-th">학번</th>
                <th className="table-th">이름</th>
                <th className="table-th">학과</th>
                <th className="table-th-center">학년</th>
                <th className="table-th-center">재학상태</th>
                <th className="table-th-center">입학일</th>
                <th className="table-th-center">관리</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.studentId} className="table-row">
                  <td className="table-td-center">{s.no}</td>
                  <td className="table-td font-medium text-primary-600 dark:text-primary-400">{s.studentId}</td>
                  <td className="table-td font-medium">{s.name}</td>
                  <td className="table-td">{s.department}</td>
                  <td className="table-td-center">{s.year}학년</td>
                  <td className="table-td-center">
                    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${statusBadge(s.status)}`}>
                      {s.status}
                    </span>
                  </td>
                  <td className="table-td-center text-[10px]">{s.admissionDate}</td>
                  <td className="table-td-center">
                    <div className="flex items-center justify-center gap-1">
                      <button
                        onClick={() => setSelectedStudent(s)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500 dark:text-slate-400" title={t('common.detail')}
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setSelectedStudent(s)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500 dark:text-slate-400" title={t('common.edit')}
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* 페이지네이션 */}
        <div className="flex items-center justify-between pt-2">
          <span className="text-xs text-gray-500 dark:text-slate-400">총 {filtered.length}건 중 1-{filtered.length} 표시</span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-400 disabled:opacity-40"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            {[1, 2, 3].map(p => (
              <button
                key={p}
                onClick={() => setCurrentPage(p)}
                className={`w-8 h-8 rounded-lg text-sm font-medium ${currentPage === p ? 'bg-primary-600 text-white' : 'hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400'}`}
              >
                {p}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage(p => Math.min(3, p + 1))}
              disabled={currentPage === 3}
              className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400 disabled:opacity-40"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </section>

      {/* 학생 상세 모달 */}
      {selectedStudent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedStudent(null)}>
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
          <div className="relative bg-white dark:bg-slate-800 rounded-2xl shadow-2xl w-full max-w-md p-6" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">학생 상세 정보</h3>
              <button onClick={() => setSelectedStudent(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between"><span className="text-gray-500">학번</span><span className="font-medium">{selectedStudent.studentId}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">이름</span><span className="font-medium">{selectedStudent.name}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">학과</span><span className="font-medium">{selectedStudent.department}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">학년</span><span className="font-medium">{selectedStudent.year}학년</span></div>
              <div className="flex justify-between"><span className="text-gray-500">재학상태</span><span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${statusBadge(selectedStudent.status)}`}>{selectedStudent.status}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">입학일</span><span className="font-medium">{selectedStudent.admissionDate}</span></div>
            </div>
            <button
              onClick={() => setSelectedStudent(null)}
              className="mt-6 w-full py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors"
            >
              {t('common.close')}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
