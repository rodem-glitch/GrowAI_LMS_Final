// pages/haksa/GradeManagePage.tsx -- 성적 관리
import { useState, useMemo } from 'react';
import { FileText, Calculator, CheckCircle, ChevronLeft, ChevronRight, X, User, BookOpen } from 'lucide-react';
import { useTranslation } from '@/i18n';

interface GradeRecord {
  id: number;
  studentId: string;
  name: string;
  subject: string;
  credit: number;
  grade: string;
  gradePoint: number;
  classification: string;
  department: string;
  year: string;
  semester: string;
  registeredAt: string;
}

const allGrades: GradeRecord[] = [
  // 2026 1학기 - 컴퓨터공학과
  { id: 1, studentId: '20210001', name: '김민수', subject: '데이터베이스', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 2, studentId: '20210045', name: '이서연', subject: '운영체제', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 3, studentId: '20200112', name: '박지훈', subject: '알고리즘', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 4, studentId: '20220078', name: '최예은', subject: '선형대수학', credit: 3, grade: 'C+', gradePoint: 2.5, classification: '교양필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 5, studentId: '20190034', name: '정우진', subject: '소프트웨어공학', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 6, studentId: '20210001', name: '김민수', subject: '컴퓨터네트워크', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 7, studentId: '20210045', name: '이서연', subject: '인공지능', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 8, studentId: '20200112', name: '박지훈', subject: '웹프로그래밍', credit: 3, grade: 'B0', gradePoint: 3.0, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 9, studentId: '20220078', name: '최예은', subject: '데이터베이스', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 10, studentId: '20190034', name: '정우진', subject: '컴퓨터구조', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  // 2026 1학기 - 전자공학과
  { id: 11, studentId: '20210102', name: '한소희', subject: '회로이론', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공필수', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 12, studentId: '20210156', name: '윤성호', subject: '신호및시스템', credit: 3, grade: 'B0', gradePoint: 3.0, classification: '전공필수', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 13, studentId: '20200089', name: '강민지', subject: '전자회로', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공선택', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 14, studentId: '20220134', name: '조현우', subject: '디지털논리', credit: 3, grade: 'C+', gradePoint: 2.5, classification: '전공필수', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 15, studentId: '20210102', name: '한소희', subject: '마이크로프로세서', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공선택', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 16, studentId: '20210156', name: '윤성호', subject: '통신이론', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공선택', department: '전자공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  // 2026 1학기 - 기계공학과
  { id: 17, studentId: '20210201', name: '서지원', subject: '열역학', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '기계공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 18, studentId: '20210245', name: '문재현', subject: '재료역학', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공필수', department: '기계공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 19, studentId: '20200178', name: '임수빈', subject: '유체역학', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공선택', department: '기계공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  { id: 20, studentId: '20220190', name: '배성민', subject: '기계설계', credit: 3, grade: 'B0', gradePoint: 3.0, classification: '전공필수', department: '기계공학과', year: '2026', semester: '1학기', registeredAt: '2026-01-15' },
  // 2026 2학기 - 컴퓨터공학과
  { id: 21, studentId: '20210001', name: '김민수', subject: '캡스톤디자인', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '2학기', registeredAt: '2026-07-15' },
  { id: 22, studentId: '20210045', name: '이서연', subject: '빅데이터분석', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '2학기', registeredAt: '2026-07-15' },
  { id: 23, studentId: '20200112', name: '박지훈', subject: '클라우드컴퓨팅', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '2학기', registeredAt: '2026-07-15' },
  { id: 24, studentId: '20220078', name: '최예은', subject: '정보보안', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공선택', department: '컴퓨터공학과', year: '2026', semester: '2학기', registeredAt: '2026-07-15' },
  { id: 25, studentId: '20190034', name: '정우진', subject: '임베디드시스템', credit: 3, grade: 'B0', gradePoint: 3.0, classification: '전공필수', department: '컴퓨터공학과', year: '2026', semester: '2학기', registeredAt: '2026-07-15' },
  // 2025 1학기
  { id: 26, studentId: '20210001', name: '김민수', subject: 'C프로그래밍', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공필수', department: '컴퓨터공학과', year: '2025', semester: '1학기', registeredAt: '2025-01-15' },
  { id: 27, studentId: '20210045', name: '이서연', subject: '자료구조', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '컴퓨터공학과', year: '2025', semester: '1학기', registeredAt: '2025-01-15' },
  { id: 28, studentId: '20200112', name: '박지훈', subject: '이산수학', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공선택', department: '컴퓨터공학과', year: '2025', semester: '1학기', registeredAt: '2025-01-15' },
  { id: 29, studentId: '20210102', name: '한소희', subject: '기초전자공학', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '전자공학과', year: '2025', semester: '1학기', registeredAt: '2025-01-15' },
  { id: 30, studentId: '20210201', name: '서지원', subject: '공학수학', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공필수', department: '기계공학과', year: '2025', semester: '1학기', registeredAt: '2025-01-15' },
  // 2025 2학기
  { id: 31, studentId: '20210001', name: '김민수', subject: 'Java프로그래밍', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '컴퓨터공학과', year: '2025', semester: '2학기', registeredAt: '2025-07-15' },
  { id: 32, studentId: '20210045', name: '이서연', subject: '컴퓨터구조', credit: 3, grade: 'B+', gradePoint: 3.5, classification: '전공필수', department: '컴퓨터공학과', year: '2025', semester: '2학기', registeredAt: '2025-07-15' },
  { id: 33, studentId: '20210102', name: '한소희', subject: '전자기학', credit: 3, grade: 'A+', gradePoint: 4.5, classification: '전공필수', department: '전자공학과', year: '2025', semester: '2학기', registeredAt: '2025-07-15' },
  { id: 34, studentId: '20210201', name: '서지원', subject: '동역학', credit: 3, grade: 'A0', gradePoint: 4.0, classification: '전공필수', department: '기계공학과', year: '2025', semester: '2학기', registeredAt: '2025-07-15' },
  { id: 35, studentId: '20220078', name: '최예은', subject: '미분적분학', credit: 3, grade: 'B0', gradePoint: 3.0, classification: '교양필수', department: '컴퓨터공학과', year: '2025', semester: '2학기', registeredAt: '2025-07-15' },
];

const gradeBadge = (grade: string) => {
  if (grade.startsWith('A')) return 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
  if (grade.startsWith('B')) return 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400';
  if (grade.startsWith('C')) return 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
  return 'bg-gray-50 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400';
};

const ITEMS_PER_PAGE = 10;

export default function GradeManagePage() {
  const { t } = useTranslation();
  const [year, setYear] = useState('2026');
  const [semester, setSemester] = useState('1학기');
  const [department, setDepartment] = useState('전체');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedGrade, setSelectedGrade] = useState<GradeRecord | null>(null);

  // 필터링
  const filtered = useMemo(() => {
    return allGrades.filter((g) => {
      const matchYear = g.year === year;
      const matchSemester = g.semester === semester;
      const matchDept = department === '전체' || g.department === department;
      return matchYear && matchSemester && matchDept;
    });
  }, [year, semester, department]);

  // 요약 통계 계산
  const stats = useMemo(() => {
    const total = filtered.length;
    if (total === 0) return { total: 0, avgGpa: '0.00', completionRate: '0.0' };
    const totalGpa = filtered.reduce((sum, g) => sum + g.gradePoint, 0);
    const avgGpa = (totalGpa / total).toFixed(2);
    const passed = filtered.filter((g) => g.gradePoint >= 2.0).length;
    const completionRate = ((passed / total) * 100).toFixed(1);
    return { total, avgGpa, completionRate };
  }, [filtered]);

  // 페이지네이션
  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginatedData = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filtered.slice(start, start + ITEMS_PER_PAGE);
  }, [filtered, currentPage]);

  const handleSearch = () => {
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) setCurrentPage(page);
  };

  // 페이지 번호 생성 (ellipsis 포함)
  const getPageNumbers = (): (number | string)[] => {
    const pages: (number | string)[] = [];
    if (totalPages <= 5) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (currentPage > 3) pages.push('...');
      const start = Math.max(2, currentPage - 1);
      const end = Math.min(totalPages - 1, currentPage + 1);
      for (let i = start; i <= end; i++) pages.push(i);
      if (currentPage < totalPages - 2) pages.push('...');
      pages.push(totalPages);
    }
    return pages;
  };

  // 필터 변경 시 페이지 초기화
  const handleFilterChange = (setter: (v: string) => void, value: string) => {
    setter(value);
    setCurrentPage(1);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.gradeManageTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.gradeManageDesc')}</p>
      </div>

      {/* 필터 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <select
            value={year}
            onChange={(e) => handleFilterChange(setYear, e.target.value)}
            className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="2026">2026년</option>
            <option value="2025">2025년</option>
            <option value="2024">2024년</option>
          </select>
          <select
            value={semester}
            onChange={(e) => handleFilterChange(setSemester, e.target.value)}
            className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="1학기">1학기</option>
            <option value="2학기">2학기</option>
          </select>
          <select
            value={department}
            onChange={(e) => handleFilterChange(setDepartment, e.target.value)}
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

      {/* 요약 카드 */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/30">
              <FileText className="w-4 h-4 text-blue-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">{stats.total.toLocaleString()}건</div>
              <div className="text-[10px] text-gray-500">총 성적 건수</div>
            </div>
          </div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-50 dark:bg-green-900/30">
              <Calculator className="w-4 h-4 text-green-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">{stats.avgGpa}</div>
              <div className="text-[10px] text-gray-500">평균 학점</div>
            </div>
          </div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-amber-50 dark:bg-amber-900/30">
              <CheckCircle className="w-4 h-4 text-amber-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">{stats.completionRate}%</div>
              <div className="text-[10px] text-gray-500">이수 완료율</div>
            </div>
          </div>
        </div>
      </div>

      {/* 성적 테이블 */}
      <section className="card space-y-4">
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">No</th>
                <th className="table-th">학번</th>
                <th className="table-th">이름</th>
                <th className="table-th">과목명</th>
                <th className="table-th-center">학점</th>
                <th className="table-th-center">성적</th>
                <th className="table-th-center">이수구분</th>
                <th className="table-th-center">등록일</th>
              </tr>
            </thead>
            <tbody>
              {paginatedData.length > 0 ? (
                paginatedData.map((g, idx) => (
                  <tr
                    key={g.id}
                    className="table-row cursor-pointer hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                    onClick={() => setSelectedGrade(g)}
                  >
                    <td className="table-td-center">{(currentPage - 1) * ITEMS_PER_PAGE + idx + 1}</td>
                    <td className="table-td font-medium text-primary-600 dark:text-primary-400">{g.studentId}</td>
                    <td className="table-td font-medium">{g.name}</td>
                    <td className="table-td">{g.subject}</td>
                    <td className="table-td-center">{g.credit}</td>
                    <td className="table-td-center">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-bold ${gradeBadge(g.grade)}`}>
                        {g.grade}
                      </span>
                    </td>
                    <td className="table-td-center">
                      <span className="text-xs text-gray-600 dark:text-slate-400">{g.classification}</span>
                    </td>
                    <td className="table-td-center text-[10px]">{g.registeredAt}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="px-4 py-16 text-center">
                    <div className="flex flex-col items-center gap-2 text-gray-400 dark:text-gray-500">
                      <FileText className="w-10 h-10" />
                      <p className="text-sm">해당 조건에 맞는 성적이 없습니다.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* 페이지네이션 - 우측 하단 */}
        {filtered.length > 0 && (
          <div className="flex items-center justify-between px-5 pb-4">
            <span className="text-xs text-gray-500 dark:text-gray-400">
              총 {filtered.length}건 중 {(currentPage - 1) * ITEMS_PER_PAGE + 1}-{Math.min(currentPage * ITEMS_PER_PAGE, filtered.length)} 표시
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 1}
                className="flex items-center gap-1 rounded-md px-2 py-1.5 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              {getPageNumbers().map((page, idx) =>
                typeof page === 'string' ? (
                  <span key={`ellipsis-${idx}`} className="px-2 text-xs text-gray-400">
                    {page}
                  </span>
                ) : (
                  <button
                    key={page}
                    onClick={() => handlePageChange(page)}
                    className={`min-w-[28px] rounded-md px-2 py-1.5 text-xs font-medium transition-colors ${
                      currentPage === page
                        ? 'bg-primary-600 text-white'
                        : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                    }`}
                  >
                    {page}
                  </button>
                )
              )}
              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage === totalPages}
                className="flex items-center gap-1 rounded-md px-2 py-1.5 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}
      </section>

      {/* 성적 상세 모달 */}
      {selectedGrade && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setSelectedGrade(null)}
        >
          <div
            className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* 모달 헤더 */}
            <div className="px-6 py-4 bg-primary-50 dark:bg-primary-900/20 border-b border-primary-100 dark:border-primary-800">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-primary-600 dark:text-primary-400">성적 상세</span>
                <button
                  onClick={() => setSelectedGrade(null)}
                  className="p-1 rounded-lg hover:bg-primary-100 dark:hover:bg-primary-800/40 transition-colors"
                >
                  <X className="w-4 h-4 text-primary-600 dark:text-primary-400" />
                </button>
              </div>
              <h2 className="text-lg font-bold text-gray-900 dark:text-white mt-1">{selectedGrade.subject}</h2>
            </div>

            {/* 모달 본문 */}
            <div className="px-6 py-5 space-y-4">
              {/* 학생 정보 */}
              <div className="flex items-center gap-3">
                <User className="w-4 h-4 text-gray-400" />
                <div>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">{selectedGrade.name}</span>
                  <span className="ml-2 text-xs text-gray-500">({selectedGrade.studentId})</span>
                </div>
              </div>

              {/* 학과 */}
              <div className="flex items-center gap-3">
                <BookOpen className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-700 dark:text-gray-300">{selectedGrade.department}</span>
              </div>

              {/* 성적 정보 그리드 */}
              <div className="grid grid-cols-2 gap-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 text-center">
                  <div className="text-[10px] text-gray-500 mb-1">성적</div>
                  <div className={`text-lg font-bold ${
                    selectedGrade.grade.startsWith('A') ? 'text-blue-600' :
                    selectedGrade.grade.startsWith('B') ? 'text-green-600' :
                    'text-yellow-600'
                  }`}>
                    {selectedGrade.grade}
                  </div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 text-center">
                  <div className="text-[10px] text-gray-500 mb-1">평점</div>
                  <div className="text-lg font-bold text-gray-900 dark:text-white">{selectedGrade.gradePoint.toFixed(1)}</div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 text-center">
                  <div className="text-[10px] text-gray-500 mb-1">학점</div>
                  <div className="text-lg font-bold text-gray-900 dark:text-white">{selectedGrade.credit}</div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 text-center">
                  <div className="text-[10px] text-gray-500 mb-1">이수구분</div>
                  <div className="text-sm font-bold text-gray-900 dark:text-white">{selectedGrade.classification}</div>
                </div>
              </div>

              {/* 부가 정보 */}
              <div className="text-xs text-gray-400 dark:text-gray-500 pt-2 border-t border-gray-100 dark:border-gray-700">
                {selectedGrade.year}년 {selectedGrade.semester} | 등록일: {selectedGrade.registeredAt}
              </div>
            </div>

            {/* 모달 하단 */}
            <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-700 flex justify-end">
              <button
                onClick={() => setSelectedGrade(null)}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
              >
                닫기
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
