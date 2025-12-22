import React, { useState } from 'react';
import { Search, BookOpen } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Content {
  id: string;
  mediaKey: string;
  title: string;
  description: string;
  category: string;
  thumbnail: string;
  duration?: string;
}

interface ContentLibraryPageProps {
  activeTab: 'all' | 'favorites';
}

export function ContentLibraryPage({ activeTab }: ContentLibraryPageProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');

  const [contents, setContents] = useState<Content[]>([]);
  const [categories, setCategories] = useState<{ key: string; name: string }[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const limit = 30;

  // 검색/필터 변경 시 초기화
  React.useEffect(() => {
    setPage(1);
    setContents([]);
    setTotalCount(0);
  }, [searchTerm, categoryFilter, activeTab]);

  // 콘텐츠 목록 불러오기(콜러스)
  React.useEffect(() => {
    let cancelled = false;
    const timer = setTimeout(() => {
      const fetchKollusList = async () => {
        const isFirstPage = page === 1;
        setLoading(isFirstPage);
        setLoadingMore(!isFirstPage);
        setErrorMessage(null);
        try {
          const res = await tutorLmsApi.getKollusList({
            keyword: searchTerm,
            categoryKey: categoryFilter || undefined,
            page,
            limit,
          });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);

          const rows = res.rst_data ?? [];
          const mapped: Content[] = rows.map((row) => ({
            id: String(row.id || row.media_content_key),
            mediaKey: row.media_content_key,
            title: row.title,
            description: row.original_file_name ? `원본파일이름: ${row.original_file_name}` : '',
            category: row.category_nm || '카테고리 없음',
            thumbnail: row.thumbnail || row.snapshot_url || '',
            duration: row.duration || '-',
          }));

          const nextCategories = Array.isArray(res.rst_categories)
            ? (res.rst_categories as { key: string; name: string }[])
            : [];

          if (!cancelled) {
            setContents((prev) => (isFirstPage ? mapped : [...prev, ...mapped]));
            setTotalCount(Number(res.rst_total ?? mapped.length));
            if (nextCategories.length > 0) setCategories(nextCategories);
          }
        } catch (e) {
          if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
        } finally {
          if (!cancelled) {
            setLoading(false);
            setLoadingMore(false);
          }
        }
      };

      fetchKollusList();
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [activeTab, searchTerm, categoryFilter, page]);

  const categoryOptions = categories;

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
            <option value="">전체</option>
            {categoryOptions.map((c) => (
              <option key={c.key} value={c.key}>
                {c.name}
              </option>
            ))}
          </select>
          <div className="text-sm text-gray-600">
            총 <span className="text-blue-600">{totalCount}</span>개의 콘텐츠
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
          {contents.map((content) => (
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
              </div>
            </div>
          ))}
        </div>
      )}

      {!loading && !errorMessage && contents.length === 0 && (
        <div className="bg-white rounded-lg border-2 border-dashed border-gray-300 p-16 text-center">
          <div className="text-gray-400">
            <BookOpen className="w-16 h-16 mx-auto mb-4 opacity-50" />
            <p className="text-lg">검색 결과가 없습니다</p>
            <p className="text-sm mt-2">다른 검색어나 필터를 시도해보세요</p>
          </div>
        </div>
      )}

      {!loading && contents.length < totalCount && (
        <div className="flex justify-center mt-8">
          <button
            type="button"
            onClick={() => setPage((prev) => prev + 1)}
            disabled={loadingMore}
            className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            {loadingMore ? '불러오는 중...' : '더보기'}
          </button>
        </div>
      )}
    </div>
  );
}
