import React, { useEffect, useMemo, useState } from 'react';
import { Search, Filter, Calendar, Users, BookOpen } from 'lucide-react';
import { OperationalPlan } from './OperationalPlan';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Course {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
  trainingPeriod: string;
  trainingLevel: string;
  trainingTarget: string;
  trainingGoal: string;
  instructor: string;
  year: string;
  students: number;
  subjects: number;
  thumbnail?: string;
}

export function CourseExplorer() {
  const [searchTerm, setSearchTerm] = useState('');
  const [classificationFilter, setClassificationFilter] = useState('전체');
  const [yearFilter, setYearFilter] = useState('전체');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 왜: "과정 탐색" 화면은 DB에 실제로 존재하는 내 과정(프로그램) 목록을 보여줘야 합니다.
  useEffect(() => {
    let cancelled = false;

    const fetchPrograms = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getPrograms();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const mapped: Course[] = rows.map((row) => {
          const trainingPeriod = row.training_period || '-';
          const year = row.start_date
            ? String(row.start_date).substring(0, 4)
            : (trainingPeriod && trainingPeriod.length >= 4 ? trainingPeriod.substring(0, 4) : '-');

          return {
            id: String(row.id),
            classification: '과정',
            name: row.course_nm,
            department: '-',
            major: '-',
            departmentName: '-',
            trainingPeriod,
            trainingLevel: '-',
            trainingTarget: '-',
            trainingGoal: '-',
            instructor: '-',
            year,
            students: 0,
            subjects: Number(row.course_cnt ?? 0),
          };
        });

        if (!cancelled) setCourses(mapped);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchPrograms();
    return () => {
      cancelled = true;
    };
  }, []);

  const filteredCourses = useMemo(() => courses.filter((course) => {
    const matchesSearch =
      searchTerm === '' ||
      course.name.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesYear = yearFilter === '전체' || course.year === yearFilter;

    // 왜: DB에 "분류" 컬럼이 없어서, UI는 유지하되 현재는 검색/년도만 적용합니다.
    const matchesClassification = true;
    return matchesSearch && matchesYear && matchesClassification;
  }), [courses, searchTerm, yearFilter, classificationFilter]);

  // 선택된 과정이 있으면 운영계획서 표시
  if (selectedCourse) {
    return (
      <OperationalPlan
        course={selectedCourse}
        onBack={() => setSelectedCourse(null)}
      />
    );
  }

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">과정 탐색</h2>
        <p className="text-gray-600">개설된 모든 교육 과정을 확인하고 관리할 수 있습니다.</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="과정명, 전공, 학과명, 교수명으로 검색..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={classificationFilter}
            onChange={(e) => setClassificationFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option>전체</option>
            <option>학위전공</option>
            <option>학위전공심화</option>
            <option>전문기술</option>
            <option>하이테크</option>
            <option>기능장</option>
            <option>고교위탁</option>
            <option>신중년</option>
          </select>
          <select
            value={yearFilter}
            onChange={(e) => setYearFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option>전체</option>
            <option>2024</option>
            <option>2023</option>
            <option>2022</option>
          </select>
          <div className="flex gap-2">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'grid'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              <Filter className="w-5 h-5" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'list'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              <BookOpen className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Results Count */}
      <div className="mb-4">
        <p className="text-sm text-gray-600">
          총 <span className="text-blue-600">{filteredCourses.length}</span>개의 과정
        </p>
      </div>

      {/* Course Grid/List */}
      {errorMessage ? (
        <div className="bg-white rounded-lg border border-gray-200 p-16 text-center text-gray-500">
          <p>{errorMessage}</p>
        </div>
      ) : loading ? (
        <div className="bg-white rounded-lg border border-gray-200 p-16 text-center text-gray-500">
          <p>불러오는 중...</p>
        </div>
      ) : (
        <>
          {viewMode === 'grid' ? (
            <div className="grid grid-cols-3 gap-6">
              {filteredCourses.map((course) => (
                <div
                  key={course.id}
                  onClick={() => setSelectedCourse(course)}
                  className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
                >
                  {/* Thumbnail */}
                  <div className="relative h-40 bg-gray-100">
                    {course.thumbnail ? (
                      <img
                        src={course.thumbnail}
                        alt={course.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <BookOpen className="w-12 h-12 text-gray-300" />
                      </div>
                    )}
                    <div className="absolute top-3 left-3">
                      <span className="px-3 py-1 bg-white bg-opacity-90 rounded-full text-xs text-gray-900">
                        {course.classification}
                      </span>
                    </div>
                  </div>

                  {/* Content */}
                  <div className="p-4">
                    <div className="mb-3">
                      <h4 className="text-gray-900 mb-1 line-clamp-1">{course.name}</h4>
                      <p className="text-sm text-gray-600">
                        {course.department} • {course.major}
                      </p>
                      <p className="text-xs text-gray-500 mt-1">{course.departmentName}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-6 py-3 text-left text-sm text-gray-700">과정ID</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-700">분류</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-700">과정명</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-700">계열/전공</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-700">학과명</th>
                    <th className="px-6 py-3 text-center text-sm text-gray-700">관리</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {filteredCourses.map((course) => (
                    <tr key={course.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 text-sm text-gray-900">{course.id}</td>
                      <td className="px-6 py-4">
                        <span className="px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs">
                          {course.classification}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900">{course.name}</div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {course.department}<br />
                        {course.major}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{course.departmentName}</td>
                      <td className="px-6 py-4 text-center">
                        <button
                          onClick={() => setSelectedCourse(course)}
                          className="px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded transition-colors"
                        >
                          상세
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {filteredCourses.length === 0 && (
            <div className="bg-white rounded-lg border-2 border-dashed border-gray-300 p-16 text-center">
              <div className="text-gray-400">
                <BookOpen className="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p className="text-lg">검색 결과가 없습니다</p>
                <p className="text-sm mt-2">다른 검색어나 필터를 시도해보세요</p>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
