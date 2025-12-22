import React, { useEffect, useMemo, useState } from 'react';
import { Search, Users, Settings } from 'lucide-react';
import { CourseManagement } from './CourseManagement';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Course {
  id: string;
  courseId: string;
  courseType: string;
  subjectName: string;
  programId: number;
  programName: string;
  period: string;
  students: number;
  status: '대기' | '신청기간' | '학습기간' | '종료';
  source?: 'prism' | 'haksa'; // 데이터 소스 추적용
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
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

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
    const matchesSearch =
      searchTerm === '' ||
      course.subjectName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.programName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.courseId.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesCourseType && matchesStatus && matchesSearch;
  }), [courses, courseType, status, searchTerm]);

  useEffect(() => {
    let cancelled = false;

    const fetchCourses = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        // activeTab에 따라 getMyCoursesCombined 호출
        const res = await tutorLmsApi.getMyCoursesCombined({ 
          tab: activeTab, 
          year: year === '전체' ? undefined : year 
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const mapped: Course[] = rows.map((row) => {
          const statusLabel = (row.status_label as Course['status']) ?? '대기';
          const typeParts = [
            (row.course_type_conv || '').trim(),
            (row.onoff_type_conv || '').trim(),
          ].filter(Boolean);

          return {
            id: String(row.id),
            courseId: row.course_id_conv || row.course_cd || String(row.id),
            courseType: typeParts.length > 0 ? typeParts.join(' / ') : '미지정',
            subjectName: row.course_nm_conv || row.subject_nm_conv || row.course_nm || '-',
            programId: Number(row.program_id ?? 0),
            programName: row.program_nm_conv || '-',
            period: row.period_conv || '-',
            students: Number(row.student_cnt ?? 0),
            status: statusLabel,
            source: activeTab, // 데이터 소스 추적
          };
        });

        if (!cancelled) setCourses(mapped);
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
  }, [year, activeTab]); // activeTab 의존성 추가

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
                  <td colSpan={9} className="px-4 py-12 text-center text-gray-500">
                    <p>{errorMessage}</p>
                  </td>
                </tr>
              ) : loading ? (
                <tr>
                  <td colSpan={9} className="px-4 py-12 text-center text-gray-500">
                    <p>불러오는 중...</p>
                  </td>
                </tr>
              ) : filteredCourses.length > 0 ? (
                filteredCourses.map((course, index) => (
                  <tr key={course.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.courseId}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">{course.courseType}</td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.subjectName}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">{course.programName}</td>
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
                  <td colSpan={9} className="px-4 py-12 text-center text-gray-500">
                    <p>검색 결과가 없습니다.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 총 과목 수 */}
      <div className="mt-4 text-sm text-gray-600">
        총 <span className="text-blue-600">{filteredCourses.length}</span>개의 과목
      </div>
    </div>
  );
}
