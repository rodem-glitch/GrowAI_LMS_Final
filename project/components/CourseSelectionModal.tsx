import React, { useEffect, useMemo, useState } from 'react';
import { X, Search, CheckCircle } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

type LabelValue = { value?: string; label?: string };
type ProgramPlanV1 = {
  version?: number;
  basic?: {
    classification?: LabelValue;
    courseName?: string;
    department?: string;
    major?: string;
    departmentName?: string;
  };
};

function safeParsePlanJson(raw: string | null | undefined): ProgramPlanV1 | null {
  // 왜: plan_json은 문자열(JSON)이라서, 빈 값/깨진 값이 있어도 화면이 죽지 않도록 안전 파싱이 필요합니다.
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed as ProgramPlanV1;
  } catch {
    return null;
  }
}

interface Course {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
}

interface CourseSelectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (course: Course | null) => void;
  selectedCourse: Course | null;
}

export function CourseSelectionModal({
  isOpen,
  onClose,
  onSelect,
  selectedCourse,
}: CourseSelectionModalProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [classificationFilter, setClassificationFilter] = useState('전체');
  const [tempSelected, setTempSelected] = useState<Course | null>(selectedCourse);

  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 왜: 모달을 열 때마다 DB 기준 "내 과정"을 최신으로 가져옵니다.
  useEffect(() => {
    if (!isOpen) return;

    let cancelled = false;
    setTempSelected(selectedCourse);
    setSearchTerm('');
    setClassificationFilter('전체');

    const fetchPrograms = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getPrograms();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const mapped: Course[] = rows.map((row) => {
          const plan = safeParsePlanJson(row.plan_json);

          return {
            id: String(row.id),
            classification: plan?.basic?.classification?.label || plan?.basic?.classification?.value || '미분류',
            name: row.course_nm || plan?.basic?.courseName || `과정 ${row.id}`,
            department: plan?.basic?.department || '',
            major: plan?.basic?.major || '',
            departmentName: plan?.basic?.departmentName || '',
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
  }, [isOpen, selectedCourse]);

  const filteredCourses = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();

    return courses.filter((course) => {
      const haystacks = [course.name, course.department, course.major, course.departmentName]
        .map((v) => String(v || '').toLowerCase())
        .filter(Boolean);

      const matchesSearch = term === '' || haystacks.some((x) => x.includes(term));
      const matchesClassification = classificationFilter === '전체' || course.classification === classificationFilter;
      return matchesSearch && matchesClassification;
    });
  }, [courses, searchTerm, classificationFilter]);

  const handleConfirm = () => {
    onSelect(tempSelected);
    onClose();
  };

  const handleCancel = () => {
    setTempSelected(selectedCourse);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div>
            <h3 className="text-gray-900">소속 과정 선택</h3>
            <p className="text-sm text-gray-600 mt-1">개설된 과정 중 하나를 선택하거나 미선택으로 둘 수 있습니다.</p>
          </div>
          <button
            onClick={handleCancel}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Filters */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="과정명, 전공, 학과명으로 검색..."
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
          </div>
        </div>

        {/* Course List */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          <div className="space-y-2">
            {/* 미선택 옵션 */}
            <div
              onClick={() => setTempSelected(null)}
              className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                tempSelected === null
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-3">
                    <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs">
                      미선택
                    </span>
                    <p className="text-gray-700">소속 과정 없음</p>
                  </div>
                  <p className="text-sm text-gray-500 mt-2">
                    특정 과정에 소속되지 않은 독립 과목으로 개설됩니다.
                  </p>
                </div>
                {tempSelected === null && (
                  <CheckCircle className="w-6 h-6 text-blue-600" />
                )}
              </div>
            </div>

            {/* 과정 목록 */}
            {errorMessage ? (
              <div className="py-16 text-center text-gray-500">
                <p>{errorMessage}</p>
              </div>
            ) : loading ? (
              <div className="py-16 text-center text-gray-500">
                <p>불러오는 중...</p>
              </div>
            ) : filteredCourses.length === 0 ? (
              <div className="py-16 text-center text-gray-500">
                <p>검색 결과가 없습니다</p>
                <p className="text-sm mt-2">다른 검색어나 필터를 시도해보세요</p>
              </div>
            ) : (
              filteredCourses.map((course) => (
                <div
                  key={course.id}
                  onClick={() => setTempSelected(course)}
                  className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                    tempSelected?.id === course.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-xs">
                          {course.classification}
                        </span>
                        <span className="text-sm text-gray-500">{course.id}</span>
                      </div>
                      <h4 className="text-gray-900 mb-1">{course.name}</h4>
                      <div className="flex items-center gap-4 text-sm text-gray-600">
                        <span>{[course.department, course.major].filter(Boolean).join(' · ') || '-'}</span>
                        <span className="text-gray-300">·</span>
                        <span>{course.departmentName || '-'}</span>
                      </div>
                    </div>
                    {tempSelected?.id === course.id && (
                      <CheckCircle className="w-6 h-6 text-blue-600 ml-4" />
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
          <div className="text-sm text-gray-600">
            {tempSelected === null ? (
              <span>미선택 상태입니다</span>
            ) : (
              <span>
                선택된 과정: <span className="text-blue-600">{tempSelected.name}</span>
              </span>
            )}
          </div>
          <div className="flex gap-3">
            <button
              onClick={handleCancel}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
            >
              취소
            </button>
            <button
              onClick={handleConfirm}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              선택 완료
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
