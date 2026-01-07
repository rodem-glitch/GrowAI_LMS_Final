import React, { useState } from 'react';
import { X, Search, Check } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Content {
  id: string;
  mediaKey: string;
  title: string;
  description: string;
  category: string;
  thumbnail: string;
  duration?: string;
  totalTime?: number;
  contentWidth?: number;
  contentHeight?: number;
  lessonId?: number;
  originalFileName?: string;
  score?: number;
}

interface ContentLibraryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (content: Content) => void;
  multiSelect?: boolean;
  onMultiSelect?: (contents: Content[]) => void;
  recommendContext?: {
    courseName?: string;
    courseIntro?: string;
    courseDetail?: string;
    lessonTitle?: string;
    lessonDescription?: string;
  };
  excludeLessonIds?: Array<number | string>;
}

export function ContentLibraryModal({
  isOpen,
  onClose,
  onSelect,
  multiSelect = true,
  onMultiSelect,
  recommendContext,
  excludeLessonIds,
}: ContentLibraryModalProps) {
  // 왜: 추천 탭은 현재 임시로 숨겨야 해서, UI/로직 모두 전체 탭만 사용하도록 고정합니다.
  const hideRecommendTab = true;
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [activeTab, setActiveTab] = useState<'recommend' | 'all'>('all');

  const [contents, setContents] = useState<Content[]>([]);
  const [categories, setCategories] = useState<{ key: string; name: string }[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [selecting, setSelecting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [recommendationsRaw, setRecommendationsRaw] = useState<Content[]>([]);
  const [recommendations, setRecommendations] = useState<Content[]>([]);
  const [recommendLoading, setRecommendLoading] = useState(false);
  const [recommendCacheKey, setRecommendCacheKey] = useState<string>('');

  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const limit = 20;

  React.useEffect(() => {
    if (!isOpen) return;

    // 왜: 모달을 다시 열 때는 이전 검색/선택이 남아 있으면 혼란스러워서 기본 상태로 초기화합니다.
    setSearchTerm('');
    setCategoryFilter('');
    setActiveTab('all');
    setPage(1);
    setContents([]);
    setTotalCount(0);
    setRecommendations([]);
    setRecommendationsRaw([]);
    setRecommendCacheKey('');
    setSelectedIds(new Set());
  }, [isOpen]);

  React.useEffect(() => {
    if (!isOpen) return;

    // 왜: 탭을 바꾸면 조회 대상이 완전히 달라지므로, 선택/페이지/에러를 같이 초기화합니다.
    setPage(1);
    setContents([]);
    setTotalCount(0);
    setSelectedIds(new Set());
    setErrorMessage(null);
  }, [isOpen, activeTab]);

  React.useEffect(() => {
    if (!isOpen) return;

    // 왜: 검색/필터 변경 시 1페이지부터 다시 조회해야 정확한 목록이 됩니다.
    if (activeTab !== 'all') return;
    setPage(1);
    setContents([]);
    setTotalCount(0);
    setSelectedIds(new Set());
  }, [isOpen, activeTab, searchTerm, categoryFilter]);

  React.useEffect(() => {
    if (!isOpen) {
      setSelectedIds(new Set());
    }
  }, [isOpen]);

  React.useEffect(() => {
    if (!isOpen) return;
    if (activeTab !== 'all') return;

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
            totalTime: Number(row.total_time ?? 0),
            contentWidth: Number(row.content_width ?? 0),
            contentHeight: Number(row.content_height ?? 0),
            originalFileName: row.original_file_name || '',
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
  }, [isOpen, activeTab, searchTerm, categoryFilter, page]);

  React.useEffect(() => {
    if (!isOpen) return;
    if (activeTab !== 'recommend') return;

    let cancelled = false;
    const timer = setTimeout(() => {
      const fetchRecommendations = async () => {
        const nextCacheKey = JSON.stringify({
          courseName: recommendContext?.courseName ?? '',
          courseIntro: recommendContext?.courseIntro ?? '',
          courseDetail: recommendContext?.courseDetail ?? '',
          lessonTitle: recommendContext?.lessonTitle ?? '',
          lessonDescription: recommendContext?.lessonDescription ?? '',
          keywords: searchTerm ?? '',
          // 왜: 제외(이미 추가된 레슨) 후에도 50개가 남도록, 더 넉넉히 받아옵니다.
          topK: 120,
          similarityThreshold: 0.2,
        });

        // 왜: 모달이 열려있는 동안 탭을 왔다갔다 해도, 같은 요청이면 네트워크를 다시 타지 않게 캐시를 사용합니다.
        if (recommendationsRaw.length > 0 && recommendCacheKey === nextCacheKey) return;

        setRecommendLoading(true);
        setErrorMessage(null);
        try {
          const res = await tutorLmsApi.getContentRecommendations({
            courseName: recommendContext?.courseName,
            courseIntro: recommendContext?.courseIntro,
            courseDetail: recommendContext?.courseDetail,
            lessonTitle: recommendContext?.lessonTitle,
            lessonDescription: recommendContext?.lessonDescription,
            // 왜: 추천 탭에서도 사용자가 제목 검색을 하면, 검색어를 "추가 키워드"로 함께 보내서 추천 품질을 올립니다.
            keywords: searchTerm,
            topK: 120,
            similarityThreshold: 0.2,
          });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);

          const rows = res.rst_data ?? [];
          const mapped: Content[] = rows.map((row) => ({
            id: String(row.lesson_id ?? row.id ?? row.media_content_key),
            mediaKey: row.media_content_key,
            title: row.title,
            description: '',
            category: (row.category_nm as string) || '카테고리 없음',
            thumbnail: (row.thumbnail as string) || (row.snapshot_url as string) || '',
            duration: (row.duration as string) || '-',
            totalTime: Number((row.total_time as number) ?? 0),
            contentWidth: Number((row.content_width as number) ?? 0),
            contentHeight: Number((row.content_height as number) ?? 0),
            lessonId: row.lesson_id ? Number(row.lesson_id) : undefined,
            originalFileName: (row.original_file_name as string) || '',
            score: row.score ? Number(row.score) : undefined,
          }));

          if (!cancelled) {
            setRecommendationsRaw(mapped);
            setRecommendCacheKey(nextCacheKey);
          }
        } catch (e) {
          if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
        } finally {
          if (!cancelled) setRecommendLoading(false);
        }
      };

      fetchRecommendations();
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [
    isOpen,
    activeTab,
    searchTerm,
    recommendationsRaw.length,
    recommendCacheKey,
    recommendContext?.courseName,
    recommendContext?.courseIntro,
    recommendContext?.courseDetail,
    recommendContext?.lessonTitle,
    recommendContext?.lessonDescription,
  ]);

  React.useEffect(() => {
    if (!isOpen) return;
    if (activeTab !== 'recommend') return;

    // 왜: 과목 전체 차시에 이미 추가된 레슨은 추천에서 제외해야 하며, 제외 후에도 50개를 유지하는 게 UX가 좋습니다.
    const excludeSet = new Set<number>();
    (excludeLessonIds ?? []).forEach((v) => {
      const n = typeof v === 'number' ? v : Number(String(v).replace(/[^0-9]/g, ''));
      if (Number.isFinite(n) && n > 0) excludeSet.add(n);
    });

    const dedupe = new Set<number>();
    const filtered = recommendationsRaw
      .filter((c) => {
        if (!c.lessonId) return false;
        if (excludeSet.has(c.lessonId)) return false;
        if (dedupe.has(c.lessonId)) return false;
        dedupe.add(c.lessonId);
        return true;
      })
      .slice(0, 50);

    setRecommendations(filtered);
  }, [isOpen, activeTab, excludeLessonIds, recommendationsRaw]);

  const displayedContents = activeTab === 'recommend' ? recommendations : contents;
  const displayedTotal = activeTab === 'recommend' ? recommendations.length : totalCount;

  const handleSelect = (content: Content) => {
    if (multiSelect) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        if (next.has(content.id)) next.delete(content.id);
        else next.add(content.id);
        return next;
      });
      return;
    }

    handleSingleSelect(content);
  };

  const handleSingleSelect = async (content: Content) => {
    try {
      setSelecting(true);
      if (content.lessonId && content.lessonId > 0) {
        // 왜: 추천 탭은 이미 레슨으로 연결된 콘텐츠가 오므로, 레슨 생성(upsert) 없이 바로 사용합니다.
        const next = { ...content, id: String(content.lessonId) };
        onSelect(next);
        onClose();
        return;
      }
      const res = await tutorLmsApi.upsertKollusLesson({
        mediaContentKey: content.mediaKey,
        title: content.title,
        totalTime: content.totalTime,
        contentWidth: content.contentWidth,
        contentHeight: content.contentHeight,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const lessonId = Number(res.rst_data ?? 0);
      const next = { ...content, lessonId, id: String(lessonId) };
      onSelect(next);
      onClose();
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : '레슨 등록 중 오류가 발생했습니다.');
    } finally {
      setSelecting(false);
    }
  };

  const handleAddSelected = async () => {
    const selected = displayedContents.filter((c) => selectedIds.has(c.id));
    if (selected.length === 0) return;

    try {
      setSelecting(true);
      const mapped = await Promise.all(
        selected.map(async (content) => {
          if (content.lessonId && content.lessonId > 0) {
            // 왜: 추천 탭은 이미 레슨ID가 있으므로, 레슨 생성(upsert)을 건너뛰어 속도를 올립니다.
            return { ...content, id: String(content.lessonId) };
          }
          const res = await tutorLmsApi.upsertKollusLesson({
            mediaContentKey: content.mediaKey,
            title: content.title,
            totalTime: content.totalTime,
            contentWidth: content.contentWidth,
            contentHeight: content.contentHeight,
          });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);
          const lessonId = Number(res.rst_data ?? 0);
          return { ...content, lessonId, id: String(lessonId) };
        })
      );

      if (onMultiSelect) onMultiSelect(mapped);
      else mapped.forEach((c) => onSelect(c));

      onClose();
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : '레슨 등록 중 오류가 발생했습니다.');
    } finally {
      setSelecting(false);
    }
  };

  const handleSelectAll = () => {
    const ids = displayedContents.map((c) => c.id);
    const allSelected = ids.length > 0 && ids.every((id) => selectedIds.has(id));

    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (allSelected) {
        ids.forEach((id) => next.delete(id));
      } else {
        ids.forEach((id) => next.add(id));
      }
      return next;
    });
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-6xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-gray-900">콘텐츠 라이브러리</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 transition-colors">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              {!hideRecommendTab && (
                <button
                  type="button"
                  onClick={() => setActiveTab('recommend')}
                  className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                    activeTab === 'recommend'
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  추천
                </button>
              )}
              <button
                type="button"
                onClick={() => setActiveTab('all')}
                className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                  activeTab === 'all' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                전체
              </button>
            </div>

            <div className="text-sm text-gray-600">총: {displayedTotal}건</div>
          </div>

          <div className="flex items-center gap-3 mb-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder={activeTab === 'recommend' ? '추천 키워드 추가...' : '제목으로 검색...'}
                className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            {activeTab === 'all' && (
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">전체</option>
                {categories.map((c) => (
                  <option key={c.key} value={c.key}>
                    {c.name}
                  </option>
                ))}
              </select>
            )}
          </div>

          <div className="flex items-center justify-between mb-3">
            <div className="text-sm text-gray-600">
              총: <span className="text-blue-600 font-medium">{totalCount}</span>건
            </div>
            {multiSelect && (
              <button
                onClick={handleAddSelected}
                disabled={selectedIds.size === 0 || selecting}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                  selectedIds.size > 0 && !selecting
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

          {(loading || recommendLoading) && (
            <div className="py-12 text-center text-gray-500">
              <p>불러오는 중...</p>
            </div>
          )}

          {!loading && !recommendLoading && (
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    {multiSelect && (
                      <th className="px-3 py-2 w-10">
                        <input
                          type="checkbox"
                          checked={
                            displayedContents.length > 0 &&
                            displayedContents.every((c) => selectedIds.has(c.id))
                          }
                          onChange={handleSelectAll}
                          className="w-4 h-4 text-blue-600 rounded"
                        />
                      </th>
                    )}
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">No</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">카테고리</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">강의명</th>
                    <th className="px-3 py-2 text-center text-xs font-medium text-gray-600">시간</th>
                    <th className="px-3 py-2 text-left text-xs font-medium text-gray-600">원본파일</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {displayedContents.map((content, index) => (
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
                      <td className="px-3 py-2 text-sm text-gray-900 max-w-xs truncate">
                        {content.title}
                      </td>
                      <td className="px-3 py-2 text-center text-sm text-gray-600">
                        {content.totalTime ? `${content.totalTime}분` : content.duration}
                      </td>
                      <td className="px-3 py-2 text-sm text-gray-500 max-w-xs truncate">
                        {content.originalFileName || '-'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {displayedContents.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  <p>{activeTab === 'recommend' ? '추천 결과가 없습니다.' : '검색 결과가 없습니다.'}</p>
                </div>
              )}
            </div>
          )}

          {!loading && !recommendLoading && activeTab === 'all' && contents.length < totalCount && (
            <div className="flex justify-center mt-6">
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
      </div>
    </div>
  );
}
