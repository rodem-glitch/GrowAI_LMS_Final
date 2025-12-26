import React, { useState, useEffect } from 'react';
import { CurriculumEditor } from '../CurriculumEditor';
import { Info, ChevronDown, ChevronRight, Plus, Video, FileText, BookOpen, ClipboardList, Trash2, Edit } from 'lucide-react';
import { WeeklyContentModal, type WeekContentItem, type ContentType } from './WeeklyContentModal';

interface CourseProps {
  id: string;
  sourceType?: 'haksa' | 'prism';
  courseId: string;
  subjectName: string;
  haksaWeek?: string;
  haksaCourseName?: string;
  [key: string]: unknown;
}

interface CurriculumTabProps {
  courseId: number;
  course?: CourseProps;
}

interface WeekData {
  weekNumber: number;
  title: string;
  isExpanded: boolean;
}

// 로컬스토리지 키 생성
const getStorageKey = (courseId: string) => `haksa_curriculum_${courseId}`;

export function CurriculumTab({ courseId, course }: CurriculumTabProps) {
  // 왜: 학사 과목은 courseId가 NaN 또는 0이므로, 빈 상태로 시작하여 교수자가 직접 추가할 수 있도록 합니다.
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0 || course?.sourceType === 'haksa';
  
  // 주차 수 결정: 기본정보의 주차 정보 사용, 없으면 15주차 기본값
  const weekCount = (() => {
    if (course?.haksaWeek) {
      const parsed = parseInt(course.haksaWeek, 10);
      if (!isNaN(parsed) && parsed > 0) return parsed;
    }
    return 15; // 기본값
  })();

  // 콘텐츠 목록 상태 (로컬스토리지에서 불러오기)
  const [contents, setContents] = useState<WeekContentItem[]>(() => {
    if (!course?.id) return [];
    try {
      const saved = localStorage.getItem(getStorageKey(course.id));
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  // 콘텐츠 변경시 로컬스토리지에 저장
  useEffect(() => {
    if (course?.id) {
      localStorage.setItem(getStorageKey(course.id), JSON.stringify(contents));
    }
  }, [contents, course?.id]);

  // 주차별 데이터 초기화
  const [weeks, setWeeks] = useState<WeekData[]>(() =>
    Array.from({ length: weekCount }, (_, i) => ({
      weekNumber: i + 1,
      title: `${i + 1}주차`,
      isExpanded: i === 0, // 첫 주차만 펼침
    }))
  );

  // 모달 상태
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedWeek, setSelectedWeek] = useState(1);

  const toggleWeek = (weekNumber: number) => {
    setWeeks((prev) =>
      prev.map((w) =>
        w.weekNumber === weekNumber ? { ...w, isExpanded: !w.isExpanded } : w
      )
    );
  };

  const openAddModal = (weekNumber: number) => {
    setSelectedWeek(weekNumber);
    setModalOpen(true);
  };

  const handleAddContent = (content: Omit<WeekContentItem, 'id' | 'createdAt'>) => {
    const newContent: WeekContentItem = {
      ...content,
      id: `content_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date().toISOString(),
    };
    setContents((prev) => [...prev, newContent]);
  };

  const handleDeleteContent = (contentId: string) => {
    if (confirm('이 콘텐츠를 삭제하시겠습니까?')) {
      setContents((prev) => prev.filter((c) => c.id !== contentId));
    }
  };

  const getWeekContents = (weekNumber: number) => {
    return contents.filter((c) => c.weekNumber === weekNumber);
  };

  const getContentIcon = (type: ContentType) => {
    switch (type) {
      case 'video':
        return <Video className="w-4 h-4 text-blue-600" />;
      case 'exam':
        return <ClipboardList className="w-4 h-4 text-red-600" />;
      case 'assignment':
        return <BookOpen className="w-4 h-4 text-purple-600" />;
      case 'document':
        return <FileText className="w-4 h-4 text-green-600" />;
    }
  };

  const getContentTypeBadge = (type: ContentType) => {
    switch (type) {
      case 'video':
        return <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">동영상</span>;
      case 'exam':
        return <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs rounded">시험</span>;
      case 'assignment':
        return <span className="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs rounded">과제</span>;
      case 'document':
        return <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded">자료</span>;
    }
  };

  // 통계 계산
  const stats = {
    total: contents.length,
    videos: contents.filter((c) => c.type === 'video').length,
    exams: contents.filter((c) => c.type === 'exam').length,
    assignments: contents.filter((c) => c.type === 'assignment').length,
    documents: contents.filter((c) => c.type === 'document').length,
  };

  if (isHaksaCourse) {
    return (
      <div className="space-y-4">
        {/* 주차 정보 헤더 */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-medium text-gray-900">주차별 강의목차</h3>
            <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs font-medium rounded">
              총 {weekCount}주차
            </span>
          </div>
          <div className="text-sm text-gray-500">
            {course?.haksaCourseName || course?.subjectName || '강좌명 없음'}
          </div>
        </div>

        {/* 콘텐츠 통계 */}
        {stats.total > 0 && (
          <div className="grid grid-cols-5 gap-3">
            <div className="px-4 py-3 bg-gray-50 rounded-lg text-center">
              <div className="text-2xl font-semibold text-gray-900">{stats.total}</div>
              <div className="text-xs text-gray-500">전체</div>
            </div>
            <div className="px-4 py-3 bg-blue-50 rounded-lg text-center">
              <div className="text-2xl font-semibold text-blue-600">{stats.videos}</div>
              <div className="text-xs text-blue-600">동영상</div>
            </div>
            <div className="px-4 py-3 bg-red-50 rounded-lg text-center">
              <div className="text-2xl font-semibold text-red-600">{stats.exams}</div>
              <div className="text-xs text-red-600">시험</div>
            </div>
            <div className="px-4 py-3 bg-purple-50 rounded-lg text-center">
              <div className="text-2xl font-semibold text-purple-600">{stats.assignments}</div>
              <div className="text-xs text-purple-600">과제</div>
            </div>
            <div className="px-4 py-3 bg-green-50 rounded-lg text-center">
              <div className="text-2xl font-semibold text-green-600">{stats.documents}</div>
              <div className="text-xs text-green-600">자료</div>
            </div>
          </div>
        )}

        {/* 주차별 아코디언 */}
        <div className="space-y-2">
          {weeks.map((week) => {
            const weekContents = getWeekContents(week.weekNumber);
            return (
              <div
                key={week.weekNumber}
                className="border border-gray-200 rounded-lg overflow-hidden"
              >
                {/* 주차 헤더 */}
                <div
                  className="flex items-center justify-between px-4 py-3 bg-gray-50 cursor-pointer hover:bg-gray-100 transition-colors"
                  onClick={() => toggleWeek(week.weekNumber)}
                >
                  <div className="flex items-center gap-3">
                    {week.isExpanded ? (
                      <ChevronDown className="w-5 h-5 text-gray-500" />
                    ) : (
                      <ChevronRight className="w-5 h-5 text-gray-500" />
                    )}
                    <span className="font-medium text-gray-900">{week.title}</span>
                    {weekContents.length > 0 && (
                      <span className="px-2 py-0.5 bg-gray-200 text-gray-600 text-xs rounded">
                        {weekContents.length}개 콘텐츠
                      </span>
                    )}
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      openAddModal(week.weekNumber);
                    }}
                    className="flex items-center gap-1 px-3 py-1.5 text-sm text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    <span>추가</span>
                  </button>
                </div>

                {/* 주차 콘텐츠 */}
                {week.isExpanded && (
                  <div className="px-4 py-3 border-t border-gray-200 bg-white">
                    {weekContents.length > 0 ? (
                      <div className="space-y-2">
                        {weekContents.map((content) => (
                          <div
                            key={content.id}
                            className="flex items-center gap-3 px-4 py-3 bg-gray-50 rounded-lg group hover:bg-gray-100 transition-colors"
                          >
                            {getContentIcon(content.type)}
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2">
                                <span className="font-medium text-gray-800 truncate">
                                  {content.title}
                                </span>
                                {getContentTypeBadge(content.type)}
                              </div>
                              {content.description && (
                                <p className="text-sm text-gray-500 truncate mt-0.5">
                                  {content.description}
                                </p>
                              )}
                            </div>
                            {content.duration && (
                              <span className="text-sm text-gray-500 flex-shrink-0">
                                {content.duration}
                              </span>
                            )}
                            <button
                              onClick={() => handleDeleteContent(content.id)}
                              className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded opacity-0 group-hover:opacity-100 transition-all"
                              title="삭제"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-8 text-gray-400">
                        <p className="mb-3">등록된 콘텐츠가 없습니다.</p>
                        <button
                          className="inline-flex items-center gap-2 px-4 py-2 text-sm text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                          onClick={() => openAddModal(week.weekNumber)}
                        >
                          <Plus className="w-4 h-4" />
                          <span>콘텐츠 추가</span>
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* 콘텐츠 추가 모달 */}
        <WeeklyContentModal
          isOpen={modalOpen}
          onClose={() => setModalOpen(false)}
          weekNumber={selectedWeek}
          onAdd={handleAddContent}
        />
      </div>
    );
  }

  return (
    <CurriculumEditor
      courseId={courseId}
      embedded={true}
    />
  );
}

// 다른 탭에서 사용할 수 있도록 콘텐츠 조회 함수 export
export function getHaksaCurriculumContents(courseId: string): WeekContentItem[] {
  try {
    const saved = localStorage.getItem(getStorageKey(courseId));
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
}

export function getHaksaExams(courseId: string): WeekContentItem[] {
  return getHaksaCurriculumContents(courseId).filter((c) => c.type === 'exam');
}

export function getHaksaAssignments(courseId: string): WeekContentItem[] {
  return getHaksaCurriculumContents(courseId).filter((c) => c.type === 'assignment');
}
