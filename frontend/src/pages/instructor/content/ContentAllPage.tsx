// src/pages/instructor/content/ContentAllPage.tsx
// 교수자 > 전체 콘텐츠 목록 페이지 (Mock 데이터 + 카드 그리드)
import { useState, useMemo } from 'react';
import { useTranslation } from '@/i18n';
import { Search, Upload, Heart, Play, FileText, HelpCircle, ClipboardList, Eye, ThumbsUp, Clock } from 'lucide-react';

interface Content {
  id: number;
  title: string;
  description: string;
  type: 'video' | 'document' | 'quiz' | 'assignment';
  thumbnail: string;
  tags: string[];
  duration: string;
  views: number;
  likes: number;
  isFavorite: boolean;
  createdAt: string;
}

const mockContents: Content[] = [
  { id: 1, title: 'Python 기초 문법 강의', description: '변수, 자료형, 조건문, 반복문 등 Python 핵심 문법을 학습합니다.', type: 'video', thumbnail: '🐍', tags: ['Python', '프로그래밍', '입문'], duration: '45분', views: 1250, likes: 89, isFavorite: true, createdAt: '2026-01-15' },
  { id: 2, title: '데이터베이스 설계 가이드', description: 'ERD 작성법과 정규화 이론을 문서로 정리한 학습자료입니다.', type: 'document', thumbnail: '📄', tags: ['DB', 'ERD', '설계'], duration: '읽기 20분', views: 820, likes: 45, isFavorite: false, createdAt: '2026-01-20' },
  { id: 3, title: 'React 컴포넌트 실습', description: 'useState, useEffect 등 React Hook을 활용한 컴포넌트 개발 실습입니다.', type: 'video', thumbnail: '⚛️', tags: ['React', 'Frontend', 'Hook'], duration: '60분', views: 2100, likes: 156, isFavorite: true, createdAt: '2026-01-22' },
  { id: 4, title: '보안 개념 퀴즈', description: 'SQL Injection, XSS 등 보안 취약점 관련 퀴즈입니다.', type: 'quiz', thumbnail: '🔒', tags: ['보안', 'OWASP', '퀴즈'], duration: '15분', views: 650, likes: 32, isFavorite: false, createdAt: '2026-01-25' },
  { id: 5, title: 'REST API 설계 실습', description: 'RESTful API 설계 원칙과 Spring Boot 구현 과제입니다.', type: 'assignment', thumbnail: '🌐', tags: ['API', 'Spring Boot', 'REST'], duration: '과제 2시간', views: 430, likes: 28, isFavorite: true, createdAt: '2026-01-28' },
  { id: 6, title: 'Spring Boot 핵심 강의', description: 'DI, AOP, JPA 등 Spring Boot 핵심 개념 강의입니다.', type: 'video', thumbnail: '🍃', tags: ['Spring', 'Java', 'Backend'], duration: '90분', views: 1800, likes: 120, isFavorite: false, createdAt: '2026-02-01' },
  { id: 7, title: '알고리즘 문제풀이', description: '정렬, 탐색, DP 등 핵심 알고리즘 문제풀이 퀴즈입니다.', type: 'quiz', thumbnail: '🧮', tags: ['알고리즘', 'PS', '코딩테스트'], duration: '30분', views: 980, likes: 67, isFavorite: false, createdAt: '2026-02-03' },
  { id: 8, title: 'UX/UI 디자인 원칙', description: '사용자 경험 중심의 UI 설계 원칙을 정리한 문서입니다.', type: 'document', thumbnail: '🎨', tags: ['UX', 'UI', '디자인'], duration: '읽기 15분', views: 560, likes: 41, isFavorite: true, createdAt: '2026-02-05' },
  { id: 9, title: 'Docker 컨테이너 실습', description: 'Dockerfile 작성부터 Docker Compose까지 실습합니다.', type: 'assignment', thumbnail: '🐳', tags: ['Docker', 'DevOps', '컨테이너'], duration: '과제 3시간', views: 720, likes: 55, isFavorite: false, createdAt: '2026-02-07' },
];

const typeConfig: Record<Content['type'], { icon: typeof Play; label: string; color: string }> = {
  video: { icon: Play, label: '동영상', color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400' },
  document: { icon: FileText, label: '문서', color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' },
  quiz: { icon: HelpCircle, label: '퀴즈', color: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400' },
  assignment: { icon: ClipboardList, label: '과제', color: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400' },
};

const CATEGORY_OPTIONS = [
  { value: '', label: '전체' },
  { value: 'video', label: '동영상' },
  { value: 'document', label: '문서' },
  { value: 'quiz', label: '퀴즈' },
  { value: 'assignment', label: '과제' },
];

export default function ContentAllPage() {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [category, setCategory] = useState('');
  const [favorites, setFavorites] = useState<Set<number>>(() => new Set(mockContents.filter(c => c.isFavorite).map(c => c.id)));
  const [showFavOnly, setShowFavOnly] = useState(false);

  const filtered = useMemo(() => {
    return mockContents.filter((c) => {
      const matchSearch = searchTerm === '' || c.title.includes(searchTerm) || c.tags.some(tag => tag.includes(searchTerm));
      const matchCategory = category === '' || c.type === category;
      const matchFav = !showFavOnly || favorites.has(c.id);
      return matchSearch && matchCategory && matchFav;
    });
  }, [searchTerm, category, showFavOnly, favorites]);

  const toggleFavorite = (id: number) => {
    setFavorites(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">
          {t('instructor.contentAllTitle')}
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {t('instructor.contentAllDesc')}
        </p>
      </div>

      {/* 필터 바 */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-4">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3">
          <div className="relative flex-1 w-full sm:max-w-sm">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder={t('ui.searchContent')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-with-icon"
            />
          </div>

          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="input w-auto"
          >
            {CATEGORY_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>

          <button
            onClick={() => setShowFavOnly(!showFavOnly)}
            className={`inline-flex items-center gap-1.5 px-3 py-2 text-sm rounded-lg border transition-colors ${showFavOnly ? 'bg-red-50 border-red-200 text-red-600 dark:bg-red-900/20 dark:border-red-800 dark:text-red-400' : 'border-gray-300 text-gray-600 hover:bg-gray-50 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700'}`}
          >
            <Heart className={`w-4 h-4 ${showFavOnly ? 'fill-current' : ''}`} />
            {t('instructor.contentFavTitle')}
          </button>

          <span className="text-sm text-gray-500 dark:text-gray-400 whitespace-nowrap ml-auto">
            {t('common.total')} {filtered.length}{t('common.items')}
          </span>

          <button
            type="button"
            className="btn-primary"
          >
            <Upload className="w-4 h-4" />
            {t('instructor.uploadContent')}
          </button>
        </div>
      </div>

      {/* 콘텐츠 그리드 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.length === 0 ? (
          <div className="col-span-full py-20 text-center">
            <FileText className="w-10 h-10 text-gray-300 dark:text-slate-600 mx-auto mb-2" />
            <p className="text-sm text-gray-400 dark:text-gray-500">{t('common.noData')}</p>
          </div>
        ) : (
          filtered.map((item) => {
            const tc = typeConfig[item.type];
            const TypeIcon = tc.icon;
            const isFav = favorites.has(item.id);
            return (
              <div key={item.id} className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden hover:shadow-md transition-shadow">
                {/* 썸네일 */}
                <div className="relative h-36 bg-gradient-to-br from-gray-100 to-gray-200 dark:from-slate-700 dark:to-slate-800 flex items-center justify-center">
                  <span className="text-5xl">{item.thumbnail}</span>
                  <button
                    onClick={() => toggleFavorite(item.id)}
                    className="absolute top-2 right-2 p-1.5 rounded-full bg-white/80 dark:bg-slate-900/60 hover:bg-white dark:hover:bg-slate-900 transition-colors"
                  >
                    <Heart className={`w-4 h-4 ${isFav ? 'fill-red-500 text-red-500' : 'text-gray-400'}`} />
                  </button>
                  <span className={`absolute bottom-2 left-2 inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium ${tc.color}`}>
                    <TypeIcon className="w-3 h-3" /> {tc.label}
                  </span>
                </div>

                {/* 콘텐츠 정보 */}
                <div className="p-4">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white truncate">{item.title}</h3>
                  <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 line-clamp-2">{item.description}</p>
                  <div className="flex flex-wrap gap-1 mt-2">
                    {item.tags.map(tag => (
                      <span key={tag} className="px-1.5 py-0.5 text-[10px] rounded bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-400">
                        {tag}
                      </span>
                    ))}
                  </div>
                  <div className="flex items-center gap-3 mt-3 pt-3 border-t border-gray-100 dark:border-slate-700 text-[11px] text-gray-400 dark:text-slate-500">
                    <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{item.duration}</span>
                    <span className="flex items-center gap-1"><Eye className="w-3 h-3" />{item.views.toLocaleString()}</span>
                    <span className="flex items-center gap-1"><ThumbsUp className="w-3 h-3" />{item.likes}</span>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
