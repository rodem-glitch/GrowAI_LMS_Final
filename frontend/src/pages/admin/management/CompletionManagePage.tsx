import { Award, Download } from 'lucide-react';
import { useTranslation } from '@/i18n';

const completions = [
  { name: '박학생', studentNo: '2024001', course: 'Python 프로그래밍 기초', grade: 'A', score: 92, date: '2026-01-20' },
  { name: '최학생', studentNo: '2024002', course: '데이터베이스 설계', grade: 'B+', score: 85, date: '2026-01-18' },
  { name: '정학생', studentNo: '2024003', course: '웹 개발 실무', grade: 'A', score: 95, date: '2026-01-15' },
];

export default function CompletionManagePage() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.completionManageTitle')}</h1>
        <button className="btn-secondary"><Download className="w-4 h-4" /> 엑셀 다운로드</button>
      </div>
      <div className="grid grid-cols-3 gap-4">
        <div className="stat-card"><div className="stat-value">156</div><div className="stat-label">총 수료자</div></div>
        <div className="stat-card"><div className="stat-value">87%</div><div className="stat-label">평균 수료율</div></div>
        <div className="stat-card"><div className="stat-value">B+</div><div className="stat-label">평균 성적</div></div>
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">{t('common.name')}</th><th className="table-th-center">학번</th><th className="table-th">강좌</th><th className="table-th-center">성적</th><th className="table-th-center">점수</th><th className="table-th-center">{t('common.date')}</th></tr></thead>
          <tbody>
            {completions.map((c, i) => (
              <tr key={i} className="table-row">
                <td className="table-td font-medium">{c.name}</td>
                <td className="table-td-center text-xs">{c.studentNo}</td>
                <td className="table-td">{c.course}</td>
                <td className="table-td-center font-medium text-primary-600">{c.grade}</td>
                <td className="table-td-center">{c.score}</td>
                <td className="table-td-center text-xs">{c.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
