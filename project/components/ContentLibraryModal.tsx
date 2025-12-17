import React, { useState } from 'react';
import { X, Search, Heart } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Content {
  id: string;
  title: string;
  description: string;
  category: string;
  tags: string[];
  views: number;
  thumbnail: string;
  isFavorite: boolean;
  duration?: string;
}

interface ContentLibraryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (content: Content) => void;
}

export function ContentLibraryModal({ isOpen, onClose, onSelect }: ContentLibraryModalProps) {
  const [activeTab, setActiveTab] = useState<'all' | 'favorites'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('전체');
  const [levelFilter, setLevelFilter] = useState('전체 유형');
  const [onlyFree, setOnlyFree] = useState(false);

  const [contents, setContents] = useState<Content[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 왜: 샘플 데이터가 아니라, 실제 레슨(LM_LESSON) 목록을 API로 가져와 보여줘야 합니다.
  // - 찜 탭은 서버에서 favorite_yn=Y로 필터링해서 내려주므로, 화면은 그대로 보여주기만 하면 됩니다.
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
          });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);

          const rows = res.rst_data ?? [];
          const mapped: Content[] = rows.map((row) => ({
            id: String(row.id),
            title: row.title,
            description: row.description || '',
            category: row.lesson_type_conv || row.lesson_type || '레슨',
            tags: [],
            views: Number(row.views ?? 0),
            thumbnail: row.thumbnail || '',
            isFavorite: Boolean(row.is_favorite),
            duration: row.duration || '-',
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
  }, [isOpen, activeTab, searchTerm]);

  const filteredContents = contents.filter((content) => {
    const matchesTab = activeTab === 'all' || (activeTab === 'favorites' && content.isFavorite);
    const matchesSearch =
      content.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      content.description.toLowerCase().includes(searchTerm.toLowerCase());

    // 왜: 레슨(LM_LESSON)은 lesson_type(유형)만 있으므로, "카테고리" 필터는 유형 기준으로 동작시킵니다.
    const matchesCategory = categoryFilter === '전체' || content.category === categoryFilter;

    // 왜: level(난이도)/무료여부는 레슨 테이블에 필드가 없어, UI는 비활성으로 처리합니다.
    return matchesTab && matchesSearch && matchesCategory;
  });

  const categoryOptions = React.useMemo(() => {
    const uniq = Array.from(new Set(contents.map((c) => c.category).filter(Boolean))).sort((a, b) =>
      a.localeCompare(b)
    );
    return ['전체', ...uniq];
  }, [contents]);

  React.useEffect(() => {
    // 왜: 검색/탭 변경으로 옵션 목록이 바뀌면, 더 이상 존재하지 않는 필터 값은 "전체"로 되돌려야 화면이 비지 않습니다.
    if (categoryFilter === '전체') return;
    if (!categoryOptions.includes(categoryFilter)) setCategoryFilter('전체');
  }, [categoryOptions, categoryFilter]);

  const handleSelect = (content: Content) => {
    onSelect(content);
    onClose();
  };

  const handleToggleFavorite = async (e: React.MouseEvent, content: Content) => {
    // 왜: 카드 전체 클릭은 "선택"이고, 하트 버튼은 "찜"이라서 이벤트를 분리해야 합니다.
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

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-5xl w-full max-h-[90vh] overflow-hidden flex flex-col">
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
          {/* Subtitle */}
          <div className="mb-6">
            <h3 className="text-gray-900 mb-2">올리팩 콘텐츠 라이브러리</h3>
            <p className="text-sm text-gray-600">
              플러에서 보유한 다양한 교육 콘텐츠를 검색하고 과정에 활용하세요.
            </p>
          </div>

          {/* Tabs */}
          <div className="flex gap-6 mb-6 border-b border-gray-200">
            <button
              onClick={() => setActiveTab('all')}
              className={`pb-3 border-b-2 transition-colors ${
                activeTab === 'all'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900'
              }`}
            >
              전체 콘텐츠
            </button>
            <button
              onClick={() => setActiveTab('favorites')}
              className={`pb-3 border-b-2 transition-colors ${
                activeTab === 'favorites'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900'
              }`}
            >
              찜한 콘텐츠 ({contents.filter(c => c.isFavorite).length})
            </button>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-4 mb-6">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="콘텐츠 제목이나 태그로 검색..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {categoryOptions.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
            <select
              value={levelFilter}
              onChange={(e) => setLevelFilter(e.target.value)}
              disabled
              title="현재 레슨 데이터에는 난이도 정보가 없어 필터를 지원하지 않습니다."
              className="px-4 py-2 border border-gray-200 rounded-lg bg-gray-50 text-gray-400 cursor-not-allowed"
            >
              <option>전체 유형</option>
              <option>기초</option>
              <option>중급</option>
              <option>고급</option>
            </select>
            <label className="flex items-center gap-2 text-sm text-gray-400 cursor-not-allowed">
              <input
                type="checkbox"
                checked={onlyFree}
                onChange={(e) => setOnlyFree(e.target.checked)}
                disabled
                title="현재 레슨 데이터에는 무료/유료 정보가 없어 필터를 지원하지 않습니다."
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 cursor-not-allowed"
              />
              무료
            </label>
            <div className="text-sm text-gray-600">
              총 {filteredContents.length}개의 콘텐츠
            </div>
          </div>

          {errorMessage && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
              {errorMessage}
            </div>
          )}

          {loading && (
            <div className="py-12 text-center text-gray-500">
              <p>불러오는 중...</p>
            </div>
          )}

          {/* Content Grid */}
          <div className="grid grid-cols-3 gap-6">
            {filteredContents.map((content) => (
              <div
                key={content.id}
                className="group cursor-pointer border border-gray-200 rounded-lg overflow-hidden hover:shadow-lg transition-shadow"
                onClick={() => handleSelect(content)}
              >
                {/* Thumbnail */}
                <div className="relative h-48 bg-gray-100">
                  {content.thumbnail ? (
                    <img
                      src={content.thumbnail}
                      alt={content.title}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-xs text-gray-400">
                      NO IMAGE
                    </div>
                  )}
                  <div className="absolute top-2 left-2 bg-white px-2 py-1 rounded text-xs">
                    {content.isFavorite ? '찜함' : '레슨'}
                  </div>
                  <button
                    type="button"
                    onClick={(e) => handleToggleFavorite(e, content)}
                    className="absolute top-2 right-2 w-8 h-8 bg-white rounded-full flex items-center justify-center hover:bg-gray-50 transition-colors"
                    title={content.isFavorite ? '찜 해제' : '찜하기'}
                  >
                    <Heart
                      className={`w-4 h-4 ${
                        content.isFavorite ? 'fill-red-500 text-red-500' : 'text-gray-400'
                      }`}
                    />
                  </button>
                  {content.duration && (
                    <div className="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white px-2 py-1 rounded text-xs">
                      {content.duration}
                    </div>
                  )}
                </div>

                {/* Content Info */}
                <div className="p-4">
                  <div className="text-xs text-blue-600 mb-1">{content.category}</div>
                  <h4 className="text-gray-900 mb-2 line-clamp-1">{content.title}</h4>
                  <p className="text-sm text-gray-600 mb-3 line-clamp-2">{content.description}</p>
                  
                  {/* Tags */}
                  <div className="flex flex-wrap gap-1 mb-3">
                    {content.tags.map((tag) => (
                      <span
                        key={tag}
                        className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>

                  {/* Stats */}
                  <div className="flex items-center justify-between text-xs text-gray-500">
                    <div className="flex items-center gap-1">
                      <span>조회 {content.views.toLocaleString()}</span>
                    </div>
                    <button className="text-blue-600 hover:underline">
                      과정에 추가
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {!loading && !errorMessage && filteredContents.length === 0 && (
            <div className="text-center py-16 text-gray-500">
              <p className="mb-2">검색 결과가 없습니다.</p>
              <p className="text-sm">다른 검색어나 필터를 시도해보세요.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
