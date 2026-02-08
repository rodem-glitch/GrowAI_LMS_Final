import { useState } from 'react';
import { Search, BookOpen, Users, Clock } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

const categories = ['전체', '프로그래밍', '데이터베이스', 'AI/ML', '웹개발', '보안'];
const courses = [
  { id: 1, title: 'Python 프로그래밍 기초', category: '프로그래밍', instructor: '김교수', campus: '서울강서', enrolled: 35, maxStudents: 40, credit: 3 },
  { id: 2, title: '데이터베이스 설계', category: '데이터베이스', instructor: '김교수', campus: '서울강서', enrolled: 28, maxStudents: 35, credit: 3 },
  { id: 3, title: '머신러닝 입문', category: 'AI/ML', instructor: '이교수', campus: '인천', enrolled: 22, maxStudents: 30, credit: 3 },
  { id: 4, title: '웹 개발 실무', category: '웹개발', instructor: '김교수', campus: '서울강서', enrolled: 38, maxStudents: 40, credit: 3 },
  { id: 5, title: '정보보안 개론', category: '보안', instructor: '박교수', campus: '대전', enrolled: 20, maxStudents: 35, credit: 3 },
  { id: 6, title: '딥러닝 실습', category: 'AI/ML', instructor: '이교수', campus: '인천', enrolled: 18, maxStudents: 25, credit: 3 },
  { id: 7, title: 'Java 프로그래밍 심화', category: '프로그래밍', instructor: '최교수', campus: '성남', enrolled: 32, maxStudents: 40, credit: 3 },
  { id: 8, title: 'Spring Framework 실습', category: '웹개발', instructor: '최교수', campus: '성남', enrolled: 27, maxStudents: 35, credit: 3 },
  { id: 9, title: '네트워크 보안', category: '보안', instructor: '정교수', campus: '대전', enrolled: 24, maxStudents: 40, credit: 3 },
  { id: 10, title: '모바일 앱 개발(Android)', category: '프로그래밍', instructor: '강교수', campus: '부산', enrolled: 36, maxStudents: 45, credit: 3 },
  { id: 11, title: 'IoT 프로그래밍', category: '프로그래밍', instructor: '한교수', campus: '광주', enrolled: 19, maxStudents: 30, credit: 2 },
  { id: 12, title: '빅데이터 분석', category: 'AI/ML', instructor: '조교수', campus: '서울강서', enrolled: 42, maxStudents: 50, credit: 3 },
  { id: 13, title: '클라우드 컴퓨팅(AWS)', category: '웹개발', instructor: '박교수', campus: '인천', enrolled: 30, maxStudents: 40, credit: 3 },
  { id: 14, title: '소프트웨어 공학', category: '프로그래밍', instructor: '김교수', campus: '서울강서', enrolled: 45, maxStudents: 55, credit: 3 },
  { id: 15, title: '임베디드 시스템', category: '프로그래밍', instructor: '한교수', campus: '광주', enrolled: 17, maxStudents: 30, credit: 2 },
  { id: 16, title: '리눅스 시스템 관리', category: '보안', instructor: '정교수', campus: '대전', enrolled: 25, maxStudents: 35, credit: 2 },
  { id: 17, title: 'UI/UX 디자인 실습', category: '웹개발', instructor: '강교수', campus: '부산', enrolled: 33, maxStudents: 40, credit: 2 },
  { id: 18, title: '블록체인 기초', category: '보안', instructor: '조교수', campus: '성남', enrolled: 21, maxStudents: 35, credit: 2 },
];

export default function CourseListPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [cat, setCat] = useState('전체');
  const filtered = courses.filter(c => {
    const matchSearch = c.title.includes(search) || c.instructor.includes(search);
    const matchCat = cat === '전체' || c.category === cat;
    return matchSearch && matchCat;
  });

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.coursesTitle')}</h1>
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder="강좌 검색..." value={search} onChange={e => setSearch(e.target.value)} className="input-with-icon" />
        </div>
        <div className="filter-bar">
          {categories.map(c => (
            <button key={c} onClick={() => setCat(c)} className={`filter-chip ${cat === c ? 'filter-chip-active' : 'filter-chip-inactive'}`}>{c}</button>
          ))}
        </div>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(c => (
          <Link key={c.id} to={`/courses/${c.id}`} className="card p-4 hover:shadow-card-hover">
            <div className="h-32 rounded-lg bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 flex items-center justify-center mb-3">
              <BookOpen className="w-8 h-8 text-primary-400" />
            </div>
            <div className="text-sm font-medium text-gray-900 dark:text-white mb-1">{c.title}</div>
            <div className="text-[10px] text-gray-400 mb-2">{c.instructor} · {c.campus}</div>
            <div className="flex items-center gap-3 text-[10px] text-gray-500">
              <span className="flex items-center gap-1"><Users className="w-3 h-3" />{c.enrolled}/{c.maxStudents}</span>
              <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{c.credit}학점</span>
              <span className="badge-sm badge-info">{c.category}</span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
