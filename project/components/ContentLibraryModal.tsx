import React, { useState } from 'react';
import { X, Search, Heart, Check } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Content {
  id: string;
  title: string;
  description: string;
  category: string;
  lessonType: string;
  tags: string[];
  views: number;
  thumbnail: string;
  isFavorite: boolean;
  duration?: string;
  totalTime?: number;
  contentName?: string;
}

interface ContentLibraryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (content: Content) => void;
  multiSelect?: boolean; // 다중 선택 모드
  onMultiSelect?: (contents: Content[]) => void; // 다중 선택 콜백
}

// 콘텐츠타입 옵션 (기존 관리자 lesson_video.jsp 기준)
const LESSON_TYPES = [
  { value: '', label: '전체' },
  { value: '01', label: '동영상(위캔디오)' },
  { value: '03', label: '동영상(콜러스)' },
  { value: '04', label: '라이브(콜러스)' },
  { value: '05', label: '웹콘텐츠(WBT)' },
  { value: '07', label: 'MP4' },
  { value: '08', label: '외부링크' },
  { value: '09', label: '문서(닥줌)' },
];

export function ContentLibraryModal({ 
  isOpen, 
  onClose, 
  onSelect,
  multiSelect = true,
  onMultiSelect 
}: ContentLibraryModalProps) {
  const [activeTab, setActiveTab] = useState<'all' | 'favorites'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('전체');
  const [lessonTypeFilter, setLessonTypeFilter] = useState('');
  const [searchField, setSearchField] = useState('');

  const [contents, setContents] = useState<Content[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 다중 선택 state
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  // 왜: 샘플 데이터가 아니라, 실제 레슨(LM_LESSON) 목록을 API로 가져와 보여줘야 합니다.
  React.useEffect(() => {
    if (!isOpen) return;

    let cancelled = false;
    const timer = setTimeout(() => {
      const fetchLessons = async () => {
        setLoading(true);
        setErrorMessage(null);
        setContents([]);
        try {
          const res = await tutorLmsApi.getLessons({
            keyword: searchTerm,
            favoriteOnly: activeTab === 'favorites',
            lessonType: lessonTypeFilter || undefined,
          });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);

          const rows = res.rst_data ?? [];
          const mapped: Content[] = rows.map((row) => ({
            id: String(row.id),
            title: row.title,
            description: row.description || '',
            category: row.lesson_type_conv || row.lesson_type || '레슨',
            lessonType: row.lesson_type || '',
            tags: [],
            views: Number(row.views ?? 0),
            thumbnail: row.thumbnail || '',
            isFavorite: Boolean(row.is_favorite),
            duration: row.duration || '-',
            totalTime: Number(row.total_time ?? 0),
            completeTime: Number(row.complete_time ?? row.total_time ?? 0), // 인정시간 (DB에서 가져옴)
            contentName: row.content_nm || '',
          }));

          if (!cancelled) setContents(mapped);
        } catch (e) {
          if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
        } finally {
          if (!cancelled) setLoading(false);
        }
      };

      fetchLessons();
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [isOpen, activeTab, searchTerm, lessonTypeFilter]);

  // 모달 닫힐 때 선택 초기화
  React.useEffect(() => {
    if (!isOpen) {
      setSelectedIds(new Set());
    }
  }, [isOpen]);

  const filteredContents = contents.filter((content) => {
    const matchesTab = activeTab === 'all' || (activeTab === 'favorites' && content.isFavorite);
    const matchesSearch =
      content.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      content.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === '전체' || content.category === categoryFilter;

    return matchesTab && matchesSearch && matchesCategory;
  });

  const categoryOptions = React.useMemo(() => {
    const uniq = Array.from(new Set(contents.map((c) => c.category).filter(Boolean))).sort((a, b) =>
      a.localeCompare(b)
    );
    return ['전체', ...uniq];
  }, [contents]);

  React.useEffect(() => {
    if (categoryFilter === '전체') return;
    if (!categoryOptions.includes(categoryFilter)) setCategoryFilter('전체');
  }, [categoryOptions, categoryFilter]);

  const handleSelect = (content: Content) => {
    if (multiSelect) {
      // 다중 선택 모드: 체크박스 토글
      setSelectedIds(prev => {
        const next = new Set(prev);
        if (next.has(content.id)) {
          next.delete(content.id);
        } else {
          next.add(content.id);
        }
        return next;
      });
    } else {
      // 단일 선택 모드
      onSelect(content);
      onClose();
    }
  };

  const handleAddSelected = () => {
    const selected = contents.filter(c => selectedIds.has(c.id));
    if (onMultiSelect) {
      onMultiSelect(selected);
    } else {
      // 단일 콜백만 있으면 각각 호출
      selected.forEach(c => onSelect(c));
    }
    onClose();
  };

  const handleToggleFavorite = async (e: React.MouseEvent, content: Content) => {
    e.preventDefault();
    e.stopPropagation();

    try {
      const res = await tutorLmsApi.toggleWishlist({ module: 'lesson', moduleId: Number(content.id) });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const next = Number(res.rst_data ?? 0) === 1;
      setContents((prev) => {
        if (activeTab === 'favorites' && !next) return prev.filter((c) => c.id !== content.id);
        return prev.map((c) => (c.id === content.id ? { ...c, isFavorite: next } : c));
      });
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : '찜 처리 중 오류가 발생했습니다.');
    }
  };

  const handleSelectAll = () => {
    if (selectedIds.size === filteredContents.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(filteredContents.map(c => c.id)));
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-6xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-gray-900">콘텐츠 라이브러리</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* 콘텐츠타입 필터 (라디오 버튼) */}
          <div className="mb-4 p-4 bg-gray-50 rounded-lg">
            <div className="text-sm font-medium text-gray-700 mb-2">콘텐츠타입</div>
            <div className="flex flex-wrap gap-3">
              {LESSON_TYPES.map((type) => (
                <label key={type.value} className="flex items-center gap-1.5 cursor-pointer">
                  <input
                    type="radio"
                    name="lessonType"
                    value={type.value}
                    checked={lessonTypeFilter === type.value}
                    onChange={(e) => setLessonTypeFilter(e.target.value)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <span className="text-sm text-gray-700">{type.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* 검색 영역 */}
          <div className="flex items-center gap-3 mb-4">
            <span className="text-sm text-gray-600">검색</span>
            <select
              value={searchField}
              onChange={(e) => setSearchField(e.target.value)}
              className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">전체</option>
              <option value="title">강의명</option>
              <option value="author">제작자</option>
            </select>
            <div className="flex-1 relative">
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="검색어 입력..."
                className="w-full pl-4 pr-10 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 bg-gray-100 text-gray-600 text-xs rounded hover:bg-gray-200">
                검색
              </button>
            </div>
          </div>

          {/* 결과 헤더 */}
          <div className="flex items-center justify-between mb-3">
            <div className="text-sm text-gray-600">
              총: <span className="text-blue-600 font-medium">{filteredContents.length}</span>건
            </div>
            {multiSelect && (
              <button
                onClick={handleAddSelected}
                disabled={selectedIds.size === 0}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                  selectedIds.size > 0
                    ? 'bg-blue-600 text-white hover:bg-blue-700'
                    : 'bg-gray-200 text-gray-400 cursor-not-allowed'
                }`}
              >
                <Check className="w-4 h-4" />
                <span>선택추가 ({selectedIds.size}건)</span>
              </button>
            )}
          </div>

          {errorMessage && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
              {errorMessage}
            </div>
          )}

          {loading && (
            <div className="py-12 text-center text-gray-500">
              <p>불러오는 중...</p>
            </div>
          )}

          {/* 테이블 형태 목록 */}
          {!loading && (
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    {multiSelect && (
                      <th className="px-3 py-2 w-10">
                        <input
                          type="checkbox"
                          checked={selectedIds.size === filteredContents.length && filteredContents.length > 0}
                          onChange={handleSelectAll}
                          className="w-4 h-4 text-blue-600 rounded"
                        />
                      </th>
                    )}
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">No</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">콘텐츠타입</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">콘텐츠목록</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">강의명</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-600">시간</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-600">등록일</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-600">찜</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {filteredContents.map((content, index) => (
                    <tr
                      key={content.id}
                      className={`hover:bg-blue-50 cursor-pointer transition-colors ${
                        selectedIds.has(content.id) ? 'bg-blue-50' : ''
                      }`}
                      onClick={() => handleSelect(content)}
                    >
                      {multiSelect && (
                        <td className="px-3 py-2 text-center">
                          <input
                            type="checkbox"
                            checked={selectedIds.has(content.id)}
                            onChange={() => {}}
                            className="w-4 h-4 text-blue-600 rounded"
                          />
                        </td>
                      )}
                      <td className="px-3 py-2 text-sm text-gray-600">{index + 1}</td>
                      <td className="px-3 py-2">
                        <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                          {content.category}
                        </span>
                      </td>
                      <td className="px-3 py-2 text-sm text-gray-600">
                        {content.contentName || '-'}
                      </td>
                      <td className="px-3 py-2 text-sm text-gray-900 max-w-xs truncate">
                        {content.title}
                      </td>
                      <td className="px-3 py-2 text-center text-sm text-gray-600">
                        {content.totalTime ? `${content.totalTime}분` : content.duration}
                      </td>
                      <td className="px-3 py-2 text-center text-sm text-gray-500">
                        -
                      </td>
                      <td className="px-3 py-2 text-center">
                        <button
                          type="button"
                          onClick={(e) => handleToggleFavorite(e, content)}
                          className="p-1 hover:bg-gray-100 rounded transition-colors"
                          title={content.isFavorite ? '찜 해제' : '찜하기'}
                        >
                          <Heart
                            className={`w-4 h-4 ${
                              content.isFavorite ? 'fill-red-500 text-red-500' : 'text-gray-400'
                            }`}
                          />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {filteredContents.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  <p>검색 결과가 없습니다.</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

