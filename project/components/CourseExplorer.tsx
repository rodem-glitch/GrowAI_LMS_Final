import React, { useState } from 'react';
import { Search, Filter, Calendar, Users, BookOpen } from 'lucide-react';
import { OperationalPlan } from './OperationalPlan';

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

  // 샘플 과정 데이터
  const courses: Course[] = [
    {
      id: 'C001',
      classification: '학위전공',
      name: '데이터베이스 학위과정',
      department: '정보통신계열',
      major: '컴퓨터공학',
      departmentName: '컴퓨터공학과',
      trainingPeriod: '2024.03.01 - 2024.12.31',
      trainingLevel: '중급',
      trainingTarget: '컴퓨터공학 전공자',
      trainingGoal: '데이터베이스 설계 및 관리 능력을 배양하고, SQL을 활용한 데이터 처리 능력을 향상시킵니다.',
      instructor: '김교수',
      year: '2024',
      students: 28,
      subjects: 12,
      thumbnail: 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?w=400&h=300&fit=crop',
    },
    {
      id: 'C002',
      classification: '전문기술',
      name: 'AI 머신러닝 전문과정',
      department: '정보통신계열',
      major: '인공지능',
      departmentName: '인공지능학과',
      trainingPeriod: '2024.03.01 - 2024.08.31',
      trainingLevel: '고급',
      trainingTarget: '인공지능 전공자 및 관련 분야 실무자',
      trainingGoal: '머신러닝 알고리즘의 이해와 실무 적용 능력을 배양하고, 딥러닝 모델 구축 능력을 향상시킵니다.',
      instructor: '이교수',
      year: '2024',
      students: 25,
      subjects: 10,
      thumbnail: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&h=300&fit=crop',
    },
    {
      id: 'C003',
      classification: '학위전공심화',
      name: '웹 프론트엔드 개발 과정',
      department: '정보통신계열',
      major: '소프트웨어공학',
      departmentName: '소프트웨어공학과',
      trainingPeriod: '2024.09.01 - 2025.02.28',
      trainingLevel: '중급',
      trainingTarget: '웹 개발에 관심있는 학생',
      trainingGoal: '모던 웹 프론트엔드 기술을 습득하고, React 기반의 웹 애플리케이션 개발 능력을 배양합니다.',
      instructor: '박교수',
      year: '2024',
      students: 30,
      subjects: 8,
      thumbnail: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400&h=300&fit=crop',
    },
    {
      id: 'C004',
      classification: '하이테크',
      name: '사물인터넷 하이테크 과정',
      department: '전자계열',
      major: '전자공학',
      departmentName: '전자공학과',
      trainingPeriod: '2023.09.01 - 2024.02.29',
      trainingLevel: '고급',
      trainingTarget: '전자공학 전공자 및 IoT 관심자',
      trainingGoal: 'IoT 시스템 설계 및 구현 능력을 배양하고, 센서 네트워크와 임베디드 시스템 개발 능력을 향상시킵니다.',
      instructor: '최교수',
      year: '2023',
      students: 20,
      subjects: 15,
      thumbnail: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&h=300&fit=crop',
    },
    {
      id: 'C005',
      classification: '기능장',
      name: '기계설계 기능장 과정',
      department: '기계계열',
      major: '기계공학',
      departmentName: '기계공학과',
      trainingPeriod: '2024.03.01 - 2024.12.31',
      trainingLevel: '고급',
      trainingTarget: '기계설계 경력자 및 기능장 자격 취득 희망자',
      trainingGoal: '고급 기계설계 능력을 배양하고, 기능장 자격 취득을 위한 전문 지식과 실무 능력을 향상시킵니다.',
      instructor: '정교수',
      year: '2024',
      students: 18,
      subjects: 20,
      thumbnail: 'https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=400&h=300&fit=crop',
    },
    {
      id: 'C006',
      classification: '신중년',
      name: '신중년 디지털 전환 과정',
      department: '특별과정',
      major: '디지털리터러시',
      departmentName: '평생교육원',
      trainingPeriod: '2024.04.01 - 2024.06.30',
      trainingLevel: '초급',
      trainingTarget: '50세 이상 신중년층',
      trainingGoal: '디지털 기술에 대한 이해를 높이고, 일상생활과 업무에서 디지털 도구를 활용하는 능력을 배양합니다.',
      instructor: '강교수',
      year: '2024',
      students: 22,
      subjects: 6,
      thumbnail: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=300&fit=crop',
    },
  ];

  const filteredCourses = courses.filter((course) => {
    const matchesSearch =
      course.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.major.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.instructor.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.departmentName.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesClassification =
      classificationFilter === '전체' || course.classification === classificationFilter;
    const matchesYear = yearFilter === '전체' || course.year === yearFilter;

    return matchesSearch && matchesClassification && matchesYear;
  });

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
    </div>
  );
}