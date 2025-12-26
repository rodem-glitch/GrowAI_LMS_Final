import React, { useEffect, useMemo, useState } from 'react';
import { Search, Users, Settings } from 'lucide-react';
import { CourseManagement } from './CourseManagement';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Course {
  id: string;
  // 왜: 학사/프리즘 탭에 따라 화면 동작(배지, 관리 버튼)을 바꾸기 위해 소스 타입을 들고 있습니다.
  sourceType: 'haksa' | 'prism';
  courseId: string;
  courseType: string;
  subjectName: string;
  programId: number;
  programName: string;
  period: string;
  students: number;
  status: '대기' | '신청기간' | '학습기간' | '종료' | '-';
  // ===== 학사 View 25개 필드 =====
  haksaCategory?: string;        // 강좌형태
  haksaDeptName?: string;        // 학과/전공 이름
  haksaWeek?: string;            // 주차
  haksaOpenTerm?: string;        // 학기
  haksaCourseCode?: string;      // 강좌코드
  haksaVisible?: string;         // 강좌 폐강 여부 (Y=정상, N=폐강)
  haksaStartdate?: string;       // 강좌시작일
  haksaBunbanCode?: string;      // 분반코드
  haksaGrade?: string;           // 학년
  haksaGradName?: string;        // 단과대학 이름
  haksaDayCd?: string;           // 강의 요일
  haksaClassroom?: string;       // 강의실 정보
  haksaCurriculumCode?: string;  // 과목구분 코드
  haksaCourseEname?: string;     // 강좌명(영문)
  haksaTypeSyllabus?: string;    // 강의계획서 구분
  haksaOpenYear?: string;        // 연도
  haksaDeptCode?: string;        // 학과/전공 코드
  haksaCourseName?: string;      // 강좌명(한글)
  haksaGroupCode?: string;       // 학부/대학원 구분
  haksaEnddate?: string;         // 강좌종료일
  haksaEnglish?: string;         // 영문 강좌 여부
  haksaHour1?: string;           // 강의 시간
  haksaCurriculumName?: string;  // 과목구분 이름
  haksaGradCode?: string;        // 단과대학 코드
  haksaIsSyllabus?: string;      // 강의계획서 존재여부
}


type TabType = 'haksa' | 'prism';

export function MyCoursesList() {
  const currentYear = String(new Date().getFullYear());
  const [activeTab, setActiveTab] = useState<TabType>('haksa'); // 기본 탭: 학사
  const [yearOptions, setYearOptions] = useState<string[]>(['전체', currentYear]);
  const [year, setYear] = useState(currentYear);
  const [courseType, setCourseType] = useState('전체');
  const [status, setStatus] = useState('전체');
  const [searchTerm, setSearchTerm] = useState('');
  const [searchKeyword, setSearchKeyword] = useState('');
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [totalCount, setTotalCount] = useState(0);

  useEffect(() => {
    let cancelled = false;

    // 왜: 년도 필터 옵션을 하드코딩하면(2024/2023/2022), 실제 데이터와 안 맞아 "없는 년도"를 고르게 될 수 있습니다.
    const fetchYears = async () => {
      try {
        const res = await tutorLmsApi.getCourseYears();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const years = (res.rst_data ?? [])
          .map((r) => String(r.year || '').trim())
          .filter(Boolean);

        const uniq = Array.from(new Set(years)).sort((a, b) => b.localeCompare(a));
        const options = ['전체', ...uniq];

        if (cancelled) return;
        setYearOptions(options.length > 1 ? options : ['전체', currentYear]);
        setYear((prev) => {
          if (prev && options.includes(prev)) return prev;
          return uniq[0] ? uniq[0] : '전체';
        });
      } catch (e) {
        // 왜: 년도 옵션 조회 실패는 치명적이지 않으므로, 기본값(현재년도/전체)으로 폴백합니다.
        if (!cancelled) setYearOptions(['전체', currentYear]);
      }
    };

    void fetchYears();
    return () => {
      cancelled = true;
    };
  }, [currentYear]);

  // 왜: 기존 화면 필터 UI를 그대로 살리면서, 데이터만 실제 DB 결과로 바꿉니다.
  const filteredCourses = useMemo(() => courses.filter((course) => {
    const matchesCourseType = courseType === '전체' || course.courseType === courseType;
    const matchesStatus = status === '전체' || course.status === status;
    return matchesCourseType && matchesStatus;
  }), [courses, courseType, status]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchKeyword(searchTerm.trim());
    }, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    setPage(1);
  }, [activeTab, year, searchKeyword, pageSize]);

  useEffect(() => {
    let cancelled = false;

    const fetchCourses = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        // activeTab에 따라 getMyCoursesCombined 호출
        const res = await tutorLmsApi.getMyCoursesCombined({
          tab: activeTab,
          year: year === '전체' ? undefined : year,
          keyword: searchKeyword || undefined,
          page,
          pageSize,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const serverTotal = Number(res.rst_total_count ?? rows.length);
        const mapped: Course[] = rows.map((row) => {
          const statusLabel = (row.status_label as Course['status']) ?? '대기';
          const typeParts = [
            (row.course_type_conv || '').trim(),
            (row.onoff_type_conv || '').trim(),
          ].filter(Boolean);

          return {
            id: String(row.id),
            sourceType: activeTab,
            courseId: row.course_id_conv || row.course_cd || String(row.id),
            courseType: typeParts.length > 0 ? typeParts.join(' / ') : '미지정',
            subjectName: row.course_nm_conv || row.subject_nm_conv || row.course_nm || '-',
            programId: Number(row.program_id ?? 0),
            programName: row.program_nm_conv || '-',
            period: row.period_conv || '-',
            students: Number(row.student_cnt ?? 0),
            status: statusLabel,
            // ===== 학사 View 25개 필드 =====
            haksaCategory: row.haksa_category || '',
            haksaDeptName: row.haksa_dept_name || '',
            haksaWeek: row.haksa_week || '',
            haksaOpenTerm: row.haksa_open_term || '',
            haksaCourseCode: row.haksa_course_code || '',
            haksaVisible: row.haksa_visible || '',
            haksaStartdate: row.haksa_startdate || '',
            haksaBunbanCode: row.haksa_bunban_code || '',
            haksaGrade: row.haksa_grade || '',
            haksaGradName: row.haksa_grad_name || '',
            haksaDayCd: row.haksa_day_cd || '',
            haksaClassroom: row.haksa_classroom || '',
            haksaCurriculumCode: row.haksa_curriculum_code || '',
            haksaCourseEname: row.haksa_course_ename || '',
            haksaTypeSyllabus: row.haksa_type_syllabus || '',
            haksaOpenYear: row.haksa_open_year || '',
            haksaDeptCode: row.haksa_dept_code || '',
            haksaCourseName: row.haksa_course_name || '',
            haksaGroupCode: row.haksa_group_code || '',
            haksaEnddate: row.haksa_enddate || '',
            haksaEnglish: row.haksa_english || '',
            haksaHour1: row.haksa_hour1 || '',
            haksaCurriculumName: row.haksa_curriculum_name || '',
            haksaGradCode: row.haksa_grad_code || '',
            haksaIsSyllabus: row.haksa_is_syllabus || '',
          };
        });

        if (!cancelled) {
          setCourses(mapped);
          setTotalCount(Number.isNaN(serverTotal) ? rows.length : serverTotal);
        }
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchCourses();
    return () => {
      cancelled = true;
    };
  }, [year, activeTab, searchKeyword, page, pageSize]); // activeTab 의존성 추가

  useEffect(() => {
    const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
    if (page > totalPages) setPage(totalPages);
  }, [totalCount, pageSize, page]);

  const courseTypeOptions = useMemo(() => {
    const types = Array.from(new Set(courses.map((c) => c.courseType).filter((t) => t && t !== '미지정'))).sort((a, b) =>
      a.localeCompare(b)
    );
    return ['전체', ...types];
  }, [courses]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case '대기':
        return 'bg-gray-100 text-gray-700';
      case '신청기간':
        return 'bg-blue-100 text-blue-700';
      case '학습기간':
        return 'bg-green-100 text-green-700';
      case '종료':
        return 'bg-gray-200 text-gray-600';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const pageNumbers = useMemo(() => {
    const start = Math.max(1, page - 2);
    const end = Math.min(totalPages, page + 2);
    return Array.from({ length: end - start + 1 }, (_, idx) => start + idx);
  }, [page, totalPages]);

  // 선택된 과목이 있으면 관리 페이지 표시
  if (selectedCourse) {
    return (
      <CourseManagement
        course={selectedCourse}
        onBack={() => setSelectedCourse(null)}
      />
    );
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">담당 과목</h2>
        <p className="text-gray-600">담당하고 있는 과목 목록을 확인하고 관리합니다.</p>
      </div>

      {/* 탭 영역 */}
      <div className="flex gap-2 mb-4">
        <button
          onClick={() => setActiveTab('haksa')}
          className={`px-6 py-2.5 rounded-lg font-medium transition-all ${
            activeTab === 'haksa'
              ? 'bg-blue-600 text-white shadow-md'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          학사
        </button>
        <button
          onClick={() => setActiveTab('prism')}
          className={`px-6 py-2.5 rounded-lg font-medium transition-all ${
            activeTab === 'prism'
              ? 'bg-blue-600 text-white shadow-md'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          프리즘
        </button>
      </div>

      {/* 필터 영역 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="grid grid-cols-4 gap-4 mb-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">년도</label>
            <select
              value={year}
              onChange={(e) => setYear(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {yearOptions.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">유형</label>
            <select
              value={courseType}
              onChange={(e) => setCourseType(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {courseTypeOptions.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">상태</label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="전체">전체</option>
              <option value="대기">대기</option>
              <option value="신청기간">신청기간</option>
              <option value="학습기간">학습기간</option>
              <option value="종료">종료</option>
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">검색</label>
            <div className="relative">
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="과목명, 과정명, 과정ID 검색"
                className="w-full px-4 py-2 pl-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            </div>
          </div>
        </div>
      </div>

      {/* 과목 목록 테이블 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">요청</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">과정ID</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">유형</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">과목명</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">소속 과정명</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">기간</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">수강생</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">상태</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {errorMessage ? (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>{errorMessage}</p>
                  </td>
                </tr>
              ) : loading ? (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>불러오는 중...</p>
                  </td>
                </tr>
              ) : filteredCourses.length > 0 ? (
                filteredCourses.map((course, index) => (
                  <tr key={course.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4 text-sm text-gray-900">{(page - 1) * pageSize + index + 1}</td>
                    <td className="px-4 py-4 text-center">
                      <span className={`inline-flex px-2 py-0.5 text-xs rounded-full ${
                        course.sourceType === 'prism' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'
                      }`}>
                        {course.sourceType === 'prism' ? 'LMS' : '학사'}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.courseId}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">{course.courseType}</td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.subjectName}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">
                      {course.programName}
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-600">{course.period}</td>
                    <td className="px-4 py-4 text-center">
                      <div className="flex items-center justify-center gap-1 text-sm text-gray-900">
                        <Users className="w-4 h-4 text-gray-500" />
                        <span>{course.students}</span>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-center">
                      <span
                        className={`inline-flex px-3 py-1 text-xs rounded-full ${getStatusColor(
                          course.status
                        )}`}
                      >
                        {course.status}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center justify-center">
                        <button
                          className="flex items-center gap-1 px-4 py-1.5 text-xs text-blue-700 bg-blue-50 rounded hover:bg-blue-100 transition-colors"
                          title="과목 관리"
                          onClick={() => setSelectedCourse(course)}
                        >
                          <Settings className="w-4 h-4" />
                          <span>관리</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>검색 결과가 없습니다.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 페이지/카운트 */}
      <div className="mt-4 flex flex-wrap items-center justify-between gap-3 text-sm text-gray-600">
        <div className="flex items-center gap-2">
          <span>총</span>
          <span className="text-blue-600">{totalCount}</span>
          <span>개의 과목</span>
          <span className="text-gray-400">/ 현재 {filteredCourses.length}개 표시</span>
        </div>
        <div className="flex items-center gap-2">
          <label htmlFor="page-size" className="text-gray-600">페이지당</label>
          <select
            id="page-size"
            value={pageSize}
            onChange={(e) => setPageSize(Number(e.target.value))}
            className="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {[20, 50, 100].map((size) => (
              <option key={size} value={size}>{size}</option>
            ))}
          </select>
        </div>
      </div>

      {/* 페이지네이션 */}
      <div className="mt-4 flex items-center justify-center gap-2">
        <button
          type="button"
          onClick={() => setPage(1)}
          disabled={page === 1}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          처음
        </button>
        <button
          type="button"
          onClick={() => setPage((prev) => Math.max(1, prev - 1))}
          disabled={page === 1}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          이전
        </button>
        {pageNumbers.map((num) => (
          <button
            key={num}
            type="button"
            onClick={() => setPage(num)}
            className={`px-3 py-1.5 text-sm border rounded-md ${
              num === page ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300'
            }`}
          >
            {num}
          </button>
        ))}
        <button
          type="button"
          onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
          disabled={page === totalPages}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          다음
        </button>
        <button
          type="button"
          onClick={() => setPage(totalPages)}
          disabled={page === totalPages}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          끝
        </button>
      </div>
    </div>
  );
}
