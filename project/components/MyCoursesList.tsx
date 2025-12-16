import React, { useState } from 'react';
import { Search, Users, Settings } from 'lucide-react';
import { CourseManagement } from './CourseManagement';

interface Course {
  id: string;
  courseId: string;
  courseType: string;
  subjectName: string;
  programName: string;
  period: string;
  students: number;
  status: '대기' | '신청기간' | '학습기간' | '종료';
}

const mockCourses: Course[] = [
  {
    id: '1',
    courseId: 'CS2024001',
    courseType: '학위전공',
    subjectName: '웹 프로그래밍 기초',
    programName: '-',
    period: '2024.03.01 - 2024.06.30',
    students: 28,
    status: '학습기간',
  },
  {
    id: '2',
    courseId: 'CS2024002',
    courseType: '학위전공심화',
    subjectName: '데이터베이스 설계',
    programName: '여름방학 단기과정',
    period: '2024.03.01 - 2024.06.30',
    students: 24,
    status: '학습기간',
  },
  {
    id: '3',
    courseId: 'HT2024001',
    courseType: '하이테크',
    subjectName: 'AI 머신러닝 실습',
    programName: '-',
    period: '2024.09.01 - 2024.12.31',
    students: 30,
    status: '신청기간',
  },
  {
    id: '4',
    courseId: 'PT2024001',
    courseType: '전문기술',
    subjectName: '네트워크 보안',
    programName: '여름방학 단기과정',
    period: '2024.01.01 - 2024.02.28',
    students: 22,
    status: '종료',
  },
  {
    id: '5',
    courseId: 'MC2024001',
    courseType: '기능장',
    subjectName: '산업용 로봇 제어',
    programName: '-',
    period: '2024.06.01 - 2024.08.31',
    students: 18,
    status: '대기',
  },
  {
    id: '6',
    courseId: 'HS2024001',
    courseType: '고교위탁',
    subjectName: '프로그래밍 입문',
    programName: '여름방학 단기과정',
    period: '2024.03.01 - 2024.12.31',
    students: 35,
    status: '학습기간',
  },
];

export function MyCoursesList() {
  const [year, setYear] = useState('2024');
  const [courseType, setCourseType] = useState('전체');
  const [status, setStatus] = useState('전체');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);

  const filteredCourses = mockCourses.filter((course) => {
    const matchesCourseType = courseType === '전체' || course.courseType === courseType;
    const matchesStatus = status === '전체' || course.status === status;
    const matchesSearch =
      searchTerm === '' ||
      course.subjectName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.programName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.courseId.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesCourseType && matchesStatus && matchesSearch;
  });

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

      {/* 필터 영역 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="grid grid-cols-3 gap-4 mb-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">년도</label>
            <select
              value={year}
              onChange={(e) => setYear(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="2024">2024</option>
              <option value="2023">2023</option>
              <option value="2022">2022</option>
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
                <th className="px-4 py-3 text-left text-sm text-gray-700">과목명</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">소속 과정명</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">기간</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">수강생</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">상태</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredCourses.length > 0 ? (
                filteredCourses.map((course, index) => (
                  <tr key={course.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.courseId}</td>
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
                  <td colSpan={8} className="px-4 py-12 text-center text-gray-500">
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