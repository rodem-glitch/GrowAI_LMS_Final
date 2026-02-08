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
  { id: 10, title: 'Spring Boot REST API 구현', description: 'Spring Boot로 CRUD REST API를 처음부터 끝까지 구현하는 실전 강의입니다.', type: 'video', thumbnail: '🍃', tags: ['Spring', 'Java', 'REST'], duration: '120분', views: 487, likes: 95, isFavorite: true, createdAt: '2025-09-10' },
  { id: 11, title: 'React Hooks 완전정복', description: 'useState, useEffect, useContext, useReducer 등 모든 Hook을 마스터합니다.', type: 'video', thumbnail: '⚛️', tags: ['React', 'Frontend', 'Hook'], duration: '90분', views: 412, likes: 78, isFavorite: false, createdAt: '2025-09-25' },
  { id: 12, title: 'Docker 컨테이너 실습', description: 'Docker 이미지 빌드, 컨테이너 관리, 네트워크 설정을 실습합니다.', type: 'video', thumbnail: '🐳', tags: ['Docker', 'DevOps', '컨테이너'], duration: '75분', views: 298, likes: 52, isFavorite: false, createdAt: '2025-10-05' },
  { id: 13, title: 'Python 데이터 분석', description: 'Pandas, NumPy를 활용한 데이터 전처리 및 시각화 강의입니다.', type: 'video', thumbnail: '📊', tags: ['Python', '데이터분석', 'Pandas'], duration: '105분', views: 356, likes: 63, isFavorite: true, createdAt: '2025-10-18' },
  { id: 14, title: 'SQL 성능 최적화', description: '인덱스 설계, 쿼리 튜닝, 실행계획 분석을 통한 SQL 성능 최적화 기법입니다.', type: 'video', thumbnail: '🗄️', tags: ['SQL', 'DB', '성능최적화'], duration: '80분', views: 265, likes: 47, isFavorite: false, createdAt: '2025-11-02' },
  { id: 15, title: 'AWS EC2 배포 가이드', description: 'EC2 인스턴스 생성부터 보안그룹 설정, 배포 자동화까지 다룹니다.', type: 'video', thumbnail: '☁️', tags: ['AWS', 'EC2', '배포'], duration: '65분', views: 189, likes: 34, isFavorite: false, createdAt: '2025-11-15' },
  { id: 16, title: 'Git 브랜치 전략', description: 'Git Flow, GitHub Flow 등 팀 협업을 위한 브랜치 전략을 설명합니다.', type: 'video', thumbnail: '🌿', tags: ['Git', '협업', '버전관리'], duration: '45분', views: 321, likes: 58, isFavorite: true, createdAt: '2025-11-28' },
  { id: 17, title: 'Linux 명령어 마스터', description: '리눅스 파일 시스템, 프로세스 관리, 셸 스크립트 핵심 명령어를 학습합니다.', type: 'video', thumbnail: '🐧', tags: ['Linux', '서버', '명령어'], duration: '55분', views: 234, likes: 41, isFavorite: false, createdAt: '2025-12-10' },
  { id: 18, title: '알고리즘 문제풀이', description: '그래프 탐색, 최단경로, 그리디 알고리즘 실전 문제풀이 영상입니다.', type: 'video', thumbnail: '🧩', tags: ['Algorithm', '코딩테스트', 'PS'], duration: '110분', views: 445, likes: 82, isFavorite: false, createdAt: '2025-12-22' },
  { id: 19, title: 'Java 디자인 패턴 정리', description: 'Singleton, Factory, Observer 등 핵심 디자인 패턴을 코드 예제와 함께 정리했습니다.', type: 'document', thumbnail: '📘', tags: ['Java', 'Spring', '디자인패턴'], duration: '읽기 30분', views: 378, likes: 66, isFavorite: true, createdAt: '2025-09-18' },
  { id: 20, title: '네트워크 프로토콜 가이드', description: 'TCP/IP, HTTP, DNS 등 핵심 네트워크 프로토콜 개념을 정리한 문서입니다.', type: 'document', thumbnail: '🌐', tags: ['Network', 'TCP/IP', 'HTTP'], duration: '읽기 25분', views: 256, likes: 38, isFavorite: false, createdAt: '2025-10-12' },
  { id: 21, title: 'DB 정규화 이론', description: '1NF부터 BCNF까지 정규화 단계별 이론과 실습 예제를 정리한 문서입니다.', type: 'document', thumbnail: '📑', tags: ['DB', 'SQL', '정규화'], duration: '읽기 20분', views: 198, likes: 29, isFavorite: false, createdAt: '2025-11-08' },
  { id: 22, title: '소프트웨어 테스팅 방법론', description: '단위 테스트, 통합 테스트, E2E 테스트 전략과 JUnit/Jest 활용법입니다.', type: 'document', thumbnail: '🧪', tags: ['Testing', 'Java', 'React'], duration: '읽기 35분', views: 167, likes: 24, isFavorite: true, createdAt: '2025-12-05' },
  { id: 23, title: '클라우드 아키텍처 설계', description: 'AWS 기반 3-Tier 아키텍처, 마이크로서비스 설계 패턴을 정리한 문서입니다.', type: 'document', thumbnail: '☁️', tags: ['AWS', 'Architecture', 'MSA'], duration: '읽기 40분', views: 143, likes: 21, isFavorite: false, createdAt: '2026-01-08' },
  { id: 24, title: '중간고사 대비 퀴즈', description: '자바 기초, 객체지향, 자료구조 범위의 중간고사 대비 모의 퀴즈입니다.', type: 'quiz', thumbnail: '📝', tags: ['Java', 'Algorithm', '시험대비'], duration: '40분', views: 467, likes: 73, isFavorite: true, createdAt: '2025-10-25' },
  { id: 25, title: 'SQL 실력 점검', description: 'SELECT, JOIN, 서브쿼리, 윈도우 함수까지 SQL 실력을 점검하는 퀴즈입니다.', type: 'quiz', thumbnail: '🗃️', tags: ['SQL', 'DB', '실력점검'], duration: '25분', views: 312, likes: 45, isFavorite: false, createdAt: '2025-11-20' },
  { id: 26, title: '보안 취약점 퀴즈', description: 'CSRF, SSRF, 파일 업로드 취약점 등 웹 보안 취약점 점검 퀴즈입니다.', type: 'quiz', thumbnail: '🛡️', tags: ['Security', 'OWASP', '웹보안'], duration: '20분', views: 205, likes: 31, isFavorite: false, createdAt: '2026-01-12' },
  { id: 27, title: 'OOP 개념 확인', description: '캡슐화, 상속, 다형성, 추상화 등 객체지향 핵심 개념을 확인하는 퀴즈입니다.', type: 'quiz', thumbnail: '🎯', tags: ['Java', 'OOP', '객체지향'], duration: '15분', views: 389, likes: 56, isFavorite: true, createdAt: '2026-02-02' },
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
