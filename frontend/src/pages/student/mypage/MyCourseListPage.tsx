import { useState } from 'react';
import ProgressBar from '@/components/common/ProgressBar';
import { useTranslation } from '@/i18n';

const tabs = ['수강중', '수료', '미수료'];
const courses = [
  { id: 1, title: 'Python 프로그래밍 기초', status: '수강중', progress: 65, instructor: '김교수' },
  { id: 2, title: '데이터베이스 설계', status: '수강중', progress: 30, instructor: '김교수' },
  { id: 3, title: '머신러닝 입문', status: '수강중', progress: 80, instructor: '이교수' },
  { id: 4, title: '자바 프로그래밍', status: '수료', progress: 100, instructor: '박교수' },
  { id: 5, title: 'C언어 기초', status: '수료', progress: 100, instructor: '최교수' },
];

export default function MyCourseListPage() {
  const { t } = useTranslation();
  const [tab, setTab] = useState('수강중');
  const filtered = courses.filter(c => c.status === tab);
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold">{t('student.myCourseListTitle')}</h1>
      <div className="filter-bar">
        {tabs.map(t => <button key={t} onClick={() => setTab(t)} className={`filter-chip ${tab === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{t}</button>)}
      </div>
      <div className="space-y-3">
        {filtered.map(c => (
          <div key={c.id} className="card p-4 flex items-center gap-4">
            <div className="flex-1"><div className="text-sm font-medium">{c.title}</div><div className="text-[10px] text-gray-400">{c.instructor}</div></div>
            <div className="w-32"><ProgressBar value={c.progress} size="sm" variant={c.progress === 100 ? 'success' : 'default'} /></div>
          </div>
        ))}
      </div>
    </div>
  );
}
