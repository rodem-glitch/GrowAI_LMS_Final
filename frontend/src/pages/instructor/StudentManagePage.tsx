import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Search } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const students = [
  { id: 1, name: '박학생', studentNo: '2024001', progress: 85, attendance: 95, grade: 'A', status: '정상' },
  { id: 2, name: '최학생', studentNo: '2024002', progress: 72, attendance: 88, grade: 'B+', status: '정상' },
  { id: 3, name: '정학생', studentNo: '2024003', progress: 45, attendance: 70, grade: 'C', status: '주의' },
  { id: 4, name: '이학생', studentNo: '2024004', progress: 30, attendance: 55, grade: 'D', status: '위험' },
  { id: 5, name: '강민수', studentNo: '2023005', progress: 92, attendance: 98, grade: 'A+', status: '우수' },
  { id: 6, name: '노준혁', studentNo: '2023006', progress: 67, attendance: 82, grade: 'B+', status: '수강중' },
  { id: 7, name: '문서연', studentNo: '2023007', progress: 100, attendance: 100, grade: 'A+', status: '우수' },
  { id: 8, name: '배지훈', studentNo: '2023008', progress: 55, attendance: 75, grade: 'B', status: '수강중' },
  { id: 9, name: '안소희', studentNo: '2023009', progress: 78, attendance: 60, grade: 'B+', status: '지각경고' },
  { id: 10, name: '유태영', studentNo: '2023010', progress: 88, attendance: 93, grade: 'A', status: '수강중' },
  { id: 11, name: '장하늘', studentNo: '2023011', progress: 40, attendance: 65, grade: 'C+', status: '지각경고' },
  { id: 12, name: '진수민', studentNo: '2023012', progress: 20, attendance: 72, grade: 'B', status: '수강중' },
];

export default function StudentManagePage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const filtered = students.filter(s => s.name.includes(search) || s.studentNo.includes(search));
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.myCoursesDesc')}</h1>
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder={t('common.searchPlaceholder')} value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head">
            <tr><th className="table-th">{t('common.name')}</th><th className="table-th-center">{t('common.no')}</th><th className="table-th-center">{t('common.inProgress')}</th><th className="table-th-center">출석률</th><th className="table-th-center">성적</th><th className="table-th-center">{t('common.status')}</th></tr>
          </thead>
          <tbody>
            {filtered.map(s => (
              <tr key={s.id} className="table-row">
                <td className="table-td font-medium">{s.name}</td>
                <td className="table-td-center text-xs">{s.studentNo}</td>
                <td className="table-td-center w-32"><ProgressBar value={s.progress} size="sm" showPercent={true} /></td>
                <td className="table-td-center">{s.attendance}%</td>
                <td className="table-td-center font-medium">{s.grade}</td>
                <td className="table-td-center">
                  <span className={`badge-sm ${s.status === '정상' ? 'badge-success' : s.status === '주의' ? 'badge-warning' : 'badge-danger'}`}>{s.status}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
