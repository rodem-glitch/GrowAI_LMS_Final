// pages/student/mypage/MyCourseListPage.tsx — 수강 이력 (수강중/수료/미수료)
import { useState, useMemo } from 'react';
import { BookOpen, ChevronLeft, ChevronRight, GraduationCap, XCircle, Clock } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';
import { useTranslation } from '@/i18n';

const tabs = ['수강중', '수료', '미수료'];

interface CourseItem {
  id: number; title: string; status: string; progress: number; instructor: string;
  category: string; startDate: string; endDate: string; grade?: string;
}

const courses: CourseItem[] = [
  // 수강중 5개
  { id: 1, title: 'Python 프로그래밍 기초', status: '수강중', progress: 65, instructor: '김교수', category: '프로그래밍', startDate: '2026-01-06', endDate: '2026-03-28' },
  { id: 2, title: '데이터베이스 설계', status: '수강중', progress: 30, instructor: '김교수', category: '데이터베이스', startDate: '2026-01-06', endDate: '2026-03-28' },
  { id: 3, title: '머신러닝 입문', status: '수강중', progress: 80, instructor: '이교수', category: 'AI/ML', startDate: '2026-01-06', endDate: '2026-03-28' },
  { id: 4, title: '클라우드 컴퓨팅', status: '수강중', progress: 45, instructor: '박교수', category: '클라우드', startDate: '2026-01-06', endDate: '2026-03-28' },
  { id: 5, title: 'React 웹 개발', status: '수강중', progress: 55, instructor: '최교수', category: '프론트엔드', startDate: '2026-01-06', endDate: '2026-03-28' },
  // 수료 20개
  { id: 10, title: '자바 프로그래밍', status: '수료', progress: 100, instructor: '박교수', category: '프로그래밍', startDate: '2025-09-01', endDate: '2025-12-20', grade: 'A' },
  { id: 11, title: 'C언어 기초', status: '수료', progress: 100, instructor: '최교수', category: '프로그래밍', startDate: '2025-03-02', endDate: '2025-06-15', grade: 'B+' },
  { id: 12, title: '웹 개발 실무', status: '수료', progress: 100, instructor: '김교수', category: '웹개발', startDate: '2025-09-01', endDate: '2025-12-18', grade: 'A+' },
  { id: 13, title: 'Spring Boot 실습', status: '수료', progress: 100, instructor: '이교수', category: '프레임워크', startDate: '2025-09-01', endDate: '2025-12-15', grade: 'A' },
  { id: 14, title: 'SQL 활용', status: '수료', progress: 100, instructor: '박교수', category: '데이터베이스', startDate: '2025-03-02', endDate: '2025-06-20', grade: 'A' },
  { id: 15, title: '알고리즘과 자료구조', status: '수료', progress: 100, instructor: '최교수', category: '기초CS', startDate: '2025-03-02', endDate: '2025-06-18', grade: 'B+' },
  { id: 16, title: '운영체제 기초', status: '수료', progress: 100, instructor: '김교수', category: '기초CS', startDate: '2025-03-02', endDate: '2025-06-22', grade: 'B' },
  { id: 17, title: '컴퓨터 네트워크', status: '수료', progress: 100, instructor: '이교수', category: '네트워크', startDate: '2024-09-01', endDate: '2024-12-20', grade: 'A' },
  { id: 18, title: 'Linux 시스템 관리', status: '수료', progress: 100, instructor: '박교수', category: '인프라', startDate: '2024-09-01', endDate: '2024-12-18', grade: 'A+' },
  { id: 19, title: 'Git & GitHub 실습', status: '수료', progress: 100, instructor: '최교수', category: '개발도구', startDate: '2024-09-01', endDate: '2024-12-15', grade: 'A+' },
  { id: 20, title: '정보처리기사 대비반', status: '수료', progress: 100, instructor: '김교수', category: '자격증', startDate: '2025-03-02', endDate: '2025-06-10', grade: 'A' },
  { id: 21, title: '소프트웨어 공학', status: '수료', progress: 100, instructor: '이교수', category: '기초CS', startDate: '2024-03-04', endDate: '2024-06-21', grade: 'B+' },
  { id: 22, title: 'Docker & Kubernetes 입문', status: '수료', progress: 100, instructor: '박교수', category: 'DevOps', startDate: '2025-09-01', endDate: '2025-12-19', grade: 'A' },
  { id: 23, title: 'REST API 설계', status: '수료', progress: 100, instructor: '최교수', category: '웹개발', startDate: '2025-09-01', endDate: '2025-12-16', grade: 'A+' },
  { id: 24, title: '빅데이터 분석 기초', status: '수료', progress: 100, instructor: '김교수', category: '데이터', startDate: '2024-09-01', endDate: '2024-12-17', grade: 'B+' },
  { id: 25, title: 'UI/UX 디자인 기초', status: '수료', progress: 100, instructor: '이교수', category: '디자인', startDate: '2024-03-04', endDate: '2024-06-18', grade: 'A' },
  { id: 26, title: '프로젝트 관리(PMP)', status: '수료', progress: 100, instructor: '박교수', category: '관리', startDate: '2024-03-04', endDate: '2024-06-20', grade: 'B' },
  { id: 27, title: '정보보안 개론', status: '수료', progress: 100, instructor: '최교수', category: '보안', startDate: '2024-09-01', endDate: '2024-12-22', grade: 'A' },
  { id: 28, title: 'TypeScript 실전', status: '수료', progress: 100, instructor: '김교수', category: '프로그래밍', startDate: '2025-09-01', endDate: '2025-12-20', grade: 'A+' },
  { id: 29, title: 'AWS 클라우드 입문', status: '수료', progress: 100, instructor: '이교수', category: '클라우드', startDate: '2025-09-01', endDate: '2025-12-14', grade: 'A' },
  // 미수료 20개
  { id: 40, title: '딥러닝 실전', status: '미수료', progress: 45, instructor: '김교수', category: 'AI/ML', startDate: '2025-09-01', endDate: '2025-12-20' },
  { id: 41, title: 'Node.js 백엔드', status: '미수료', progress: 30, instructor: '이교수', category: '웹개발', startDate: '2025-09-01', endDate: '2025-12-18' },
  { id: 42, title: 'Kotlin 프로그래밍', status: '미수료', progress: 55, instructor: '박교수', category: '프로그래밍', startDate: '2025-03-02', endDate: '2025-06-15' },
  { id: 43, title: 'GraphQL API 개발', status: '미수료', progress: 20, instructor: '최교수', category: '웹개발', startDate: '2025-09-01', endDate: '2025-12-16' },
  { id: 44, title: 'Flutter 앱 개발', status: '미수료', progress: 35, instructor: '김교수', category: '모바일', startDate: '2025-09-01', endDate: '2025-12-19' },
  { id: 45, title: 'CI/CD 파이프라인', status: '미수료', progress: 40, instructor: '이교수', category: 'DevOps', startDate: '2025-03-02', endDate: '2025-06-20' },
  { id: 46, title: '블록체인 기초', status: '미수료', progress: 15, instructor: '박교수', category: '블록체인', startDate: '2024-09-01', endDate: '2024-12-20' },
  { id: 47, title: 'Redis & 캐싱 전략', status: '미수료', progress: 50, instructor: '최교수', category: '데이터베이스', startDate: '2025-09-01', endDate: '2025-12-17' },
  { id: 48, title: '마이크로서비스 아키텍처', status: '미수료', progress: 25, instructor: '김교수', category: '아키텍처', startDate: '2025-09-01', endDate: '2025-12-22' },
  { id: 49, title: 'Elasticsearch 검색엔진', status: '미수료', progress: 10, instructor: '이교수', category: '검색', startDate: '2025-03-02', endDate: '2025-06-18' },
  { id: 50, title: 'RabbitMQ 메시징', status: '미수료', progress: 60, instructor: '박교수', category: '인프라', startDate: '2025-09-01', endDate: '2025-12-15' },
  { id: 51, title: 'MongoDB NoSQL', status: '미수료', progress: 35, instructor: '최교수', category: '데이터베이스', startDate: '2024-09-01', endDate: '2024-12-19' },
  { id: 52, title: 'Vue.js 프론트엔드', status: '미수료', progress: 42, instructor: '김교수', category: '프론트엔드', startDate: '2024-09-01', endDate: '2024-12-18' },
  { id: 53, title: 'JPA & Hibernate 심화', status: '미수료', progress: 55, instructor: '이교수', category: '프레임워크', startDate: '2025-03-02', endDate: '2025-06-22' },
  { id: 54, title: 'Apache Kafka', status: '미수료', progress: 18, instructor: '박교수', category: '인프라', startDate: '2025-09-01', endDate: '2025-12-21' },
  { id: 55, title: 'GCP 클라우드 심화', status: '미수료', progress: 28, instructor: '최교수', category: '클라우드', startDate: '2025-09-01', endDate: '2025-12-20' },
  { id: 56, title: '자연어 처리(NLP)', status: '미수료', progress: 32, instructor: '김교수', category: 'AI/ML', startDate: '2025-03-02', endDate: '2025-06-16' },
  { id: 57, title: '테스트 자동화(Jest)', status: '미수료', progress: 48, instructor: '이교수', category: '테스트', startDate: '2025-09-01', endDate: '2025-12-14' },
  { id: 58, title: 'DevSecOps 입문', status: '미수료', progress: 22, instructor: '박교수', category: '보안', startDate: '2024-09-01', endDate: '2024-12-17' },
  { id: 59, title: '데이터 시각화(D3.js)', status: '미수료', progress: 38, instructor: '최교수', category: '데이터', startDate: '2024-03-04', endDate: '2024-06-21' },
];

const ITEMS_PER_PAGE = 8;

export default function MyCourseListPage() {
  const { t } = useTranslation();
  const [tab, setTab] = useState('수강중');
  const [currentPage, setCurrentPage] = useState(1);

  const filtered = useMemo(() => courses.filter(c => c.status === tab), [tab]);
  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginated = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filtered.slice(start, start + ITEMS_PER_PAGE);
  }, [filtered, currentPage]);

  const handleTabChange = (t: string) => { setTab(t); setCurrentPage(1); };

  const tabIcon = (t: string) => {
    if (t === '수강중') return <Clock className="w-3.5 h-3.5" />;
    if (t === '수료') return <GraduationCap className="w-3.5 h-3.5" />;
    return <XCircle className="w-3.5 h-3.5" />;
  };

  const tabCount = (t: string) => courses.filter(c => c.status === t).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <BookOpen className="w-6 h-6 text-primary-500" />
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.myCourseListTitle')}</h1>
        </div>
        <span className="text-xs text-gray-400">총 {courses.length}개 강좌</span>
      </div>

      <div className="filter-bar">
        {tabs.map(t => (
          <button key={t} onClick={() => handleTabChange(t)}
            className={`filter-chip flex items-center gap-1.5 ${tab === t ? 'filter-chip-active' : 'filter-chip-inactive'}`}>
            {tabIcon(t)} {t}
            <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${tab === t ? 'bg-white/20' : 'bg-gray-100 dark:bg-slate-700'}`}>
              {tabCount(t)}
            </span>
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {paginated.map(c => (
          <div key={c.id} className="card p-4 hover:shadow-card-hover transition-all">
            <div className="flex items-center gap-4">
              <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${
                c.status === '수료' ? 'bg-success-50 dark:bg-success-900/20' :
                c.status === '미수료' ? 'bg-danger-50 dark:bg-danger-900/20' :
                'bg-primary-50 dark:bg-primary-900/20'
              }`}>
                {c.status === '수료' ? <GraduationCap className="w-5 h-5 text-success-500" /> :
                 c.status === '미수료' ? <XCircle className="w-5 h-5 text-danger-500" /> :
                 <BookOpen className="w-5 h-5 text-primary-500" />}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-gray-900 dark:text-white truncate">{c.title}</span>
                  <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-gray-100 dark:bg-slate-700 text-gray-500 dark:text-slate-400 shrink-0">{c.category}</span>
                </div>
                <div className="text-[10px] text-gray-400 mt-0.5">{c.instructor} · {c.startDate} ~ {c.endDate}</div>
              </div>
              {c.grade && (
                <div className="text-center shrink-0">
                  <div className="text-lg font-bold text-primary-600 dark:text-primary-400">{c.grade}</div>
                  <div className="text-[9px] text-gray-400">성적</div>
                </div>
              )}
              <div className="w-28 shrink-0">
                <ProgressBar value={c.progress} size="sm" variant={c.progress === 100 ? 'success' : c.status === '미수료' ? 'danger' : 'default'} />
                <div className="text-[10px] text-gray-400 text-right mt-0.5">{c.progress}%</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="card p-8 text-center">
          <BookOpen className="w-8 h-8 text-gray-300 mx-auto mb-2" />
          <p className="text-sm text-gray-500">해당 상태의 강좌가 없습니다.</p>
        </div>
      )}

      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-1 pt-2">
          <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
            className="rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 dark:text-gray-400 dark:hover:bg-gray-700">
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
            <button key={p} onClick={() => setCurrentPage(p)}
              className={`min-w-[32px] rounded-md px-3 py-2 text-xs font-medium transition-colors ${
                currentPage === p ? 'bg-primary-600 text-white' : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
              }`}>{p}</button>
          ))}
          <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
            className="rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 dark:text-gray-400 dark:hover:bg-gray-700">
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      <div className="text-center text-[10px] text-gray-400">
        {filtered.length}건 중 {Math.min((currentPage - 1) * ITEMS_PER_PAGE + 1, filtered.length)}-{Math.min(currentPage * ITEMS_PER_PAGE, filtered.length)} 표시
      </div>
    </div>
  );
}
