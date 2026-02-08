import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Plus, Eye, Edit3, Trash2, X, CheckCircle } from 'lucide-react';
import { useTranslation } from '@/i18n';

const initialCourses = [
  { id: 1, code: 'CS101', title: 'Python 프로그래밍 기초', instructor: '김교수', campus: '서울강서', enrolled: 35, status: 'ACTIVE' },
  { id: 2, code: 'CS201', title: '데이터베이스 설계', instructor: '김교수', campus: '서울강서', enrolled: 28, status: 'ACTIVE' },
  { id: 3, code: 'AI301', title: '머신러닝 입문', instructor: '이교수', campus: '인천', enrolled: 22, status: 'ACTIVE' },
  { id: 4, code: 'WEB101', title: '웹 개발 실무', instructor: '김교수', campus: '서울강서', enrolled: 38, status: 'ACTIVE' },
];

export default function CourseManagePage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [courses, setCourses] = useState(initialCourses);
  const [selectedCourse, setSelectedCourse] = useState<typeof initialCourses[0] | null>(null);
  const [toast, setToast] = useState('');

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2000);
  };

  const handleDelete = (id: number) => {
    const course = courses.find(c => c.id === id);
    if (course && confirm(`"${course.title}" 강좌를 삭제하시겠습니까?`)) {
      setCourses(prev => prev.filter(c => c.id !== id));
      showToast('강좌가 삭제되었습니다.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.courseManageTitle')}</h1>
        <button onClick={() => navigate('/instructor/course-create')} className="btn-primary"><Plus className="w-4 h-4" /> 강좌 추가</button>
      </div>
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input type="text" placeholder={t('common.searchPlaceholder')} value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
      </div>
      <div className="table-container">
        <table className="w-full">
          <thead className="table-head"><tr><th className="table-th">강좌코드</th><th className="table-th">{t('common.name')}</th><th className="table-th-center">교수자</th><th className="table-th-center">캠퍼스</th><th className="table-th-center">수강생</th><th className="table-th-center">{t('common.status')}</th><th className="table-th-center">{t('common.action')}</th></tr></thead>
          <tbody>
            {courses.filter(c => c.title.includes(search) || c.code.includes(search)).map(c => (
              <tr key={c.id} className="table-row">
                <td className="table-td font-mono text-xs">{c.code}</td>
                <td className="table-td font-medium">{c.title}</td>
                <td className="table-td-center">{c.instructor}</td>
                <td className="table-td-center">{c.campus}</td>
                <td className="table-td-center">{c.enrolled}</td>
                <td className="table-td-center"><span className="badge-sm badge-success">활성</span></td>
                <td className="table-td-center">
                  <div className="flex items-center justify-center gap-1">
                    <button onClick={() => setSelectedCourse(c)} className="p-1 text-gray-400 hover:text-primary-600" title="상세보기"><Eye className="w-3.5 h-3.5" /></button>
                    <button onClick={() => setSelectedCourse(c)} className="p-1 text-gray-400 hover:text-primary-600" title="수정"><Edit3 className="w-3.5 h-3.5" /></button>
                    <button onClick={() => handleDelete(c.id)} className="p-1 text-gray-400 hover:text-danger-600" title="삭제"><Trash2 className="w-3.5 h-3.5" /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 강좌 상세 모달 */}
      {selectedCourse && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedCourse(null)}>
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
          <div className="relative bg-white dark:bg-slate-800 rounded-2xl shadow-2xl w-full max-w-md p-6" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">강좌 상세</h3>
              <button onClick={() => setSelectedCourse(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700"><X className="w-4 h-4 text-gray-400" /></button>
            </div>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between"><span className="text-gray-500">강좌코드</span><span className="font-mono font-medium">{selectedCourse.code}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">강좌명</span><span className="font-medium">{selectedCourse.title}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">교수자</span><span className="font-medium">{selectedCourse.instructor}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">캠퍼스</span><span className="font-medium">{selectedCourse.campus}</span></div>
              <div className="flex justify-between"><span className="text-gray-500">수강생</span><span className="font-medium">{selectedCourse.enrolled}명</span></div>
            </div>
            <button onClick={() => setSelectedCourse(null)} className="mt-6 w-full py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors">{t('common.close')}</button>
          </div>
        </div>
      )}

      {/* 토스트 */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-green-600 text-white px-5 py-3 rounded-xl shadow-lg">
          <CheckCircle className="w-5 h-5" />
          <span className="text-sm font-medium">{toast}</span>
        </div>
      )}
    </div>
  );
}
