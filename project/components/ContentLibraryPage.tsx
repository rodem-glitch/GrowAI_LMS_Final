import React, { useState } from 'react';
import { Search, Heart, BookOpen } from 'lucide-react';
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

interface ContentLibraryPageProps {
  activeTab: 'all' | 'favorites';
}

export function ContentLibraryPage({ activeTab }: ContentLibraryPageProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('전체');

  const [contents, setContents] = useState<Content[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 콘텐츠 목록 불러오기
  React.useEffect(() => {
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
  }, [activeTab, searchTerm]);

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

  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header */}
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">
          {activeTab === 'all' ? '전체 콘텐츠' : '찜한 콘텐츠'}
        </h2>
        <p className="text-gray-600">
          {activeTab === 'all' 
            ? '모든 교육 콘텐츠를 검색하고 과정에 활용하세요.'
            : '즐겨찾기한 콘텐츠만 모아서 확인하세요.'}
        </p>
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
          <div className="text-sm text-gray-600">
            총 <span className="text-blue-600">{filteredContents.length}</span>개의 콘텐츠
          </div>
        </div>
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
          {errorMessage}
        </div>
      )}

      {loading && (
        <div className="bg-white rounded-lg border border-gray-200 p-16 text-center text-gray-500">
          <p>불러오는 중...</p>
        </div>
      )}

      {/* Content Grid */}
      {!loading && (
        <div className="grid grid-cols-3 gap-6">
          {filteredContents.map((content) => (
            <div
              key={content.id}
              className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow"
            >
              {/* Thumbnail */}
              <div className="relative h-40 bg-gray-100">
                {content.thumbnail ? (
                  <img
                    src={content.thumbnail}
                    alt={content.title}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <BookOpen className="w-12 h-12 text-gray-300" />
                  </div>
                )}
                <div className="absolute top-2 left-2 bg-white px-2 py-1 rounded text-xs">
                  {content.category}
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
                {content.duration && content.duration !== '-' && (
                  <div className="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white px-2 py-1 rounded text-xs">
                    {content.duration}
                  </div>
                )}
              </div>

              {/* Content Info */}
              <div className="p-4">
                <h4 className="text-gray-900 mb-2 line-clamp-1">{content.title}</h4>
                <p className="text-sm text-gray-600 mb-3 line-clamp-2">{content.description}</p>
                
                {/* Stats */}
                <div className="flex items-center justify-between text-xs text-gray-500">
                  <span>조회 {content.views.toLocaleString()}</span>
                  {content.isFavorite && (
                    <span className="text-red-500 flex items-center gap-1">
                      <Heart className="w-3 h-3 fill-current" /> 찜함
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {!loading && !errorMessage && filteredContents.length === 0 && (
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
