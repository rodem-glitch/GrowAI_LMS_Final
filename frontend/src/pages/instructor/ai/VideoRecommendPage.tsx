// src/pages/instructor/ai/VideoRecommendPage.tsx
// PRF-A02: 문맥 기반 영상 추천 - 주차별 학습 주제에 맞는 영상 콘텐츠 추천

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Video,
  Play,
  Star,
  Clock,
  ExternalLink,
  X,
  BookOpen,
  ChevronRight,
  Search,
  Sparkles,
  ThumbsUp,
  Eye,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

interface WeekTopic {
  week: number;
  topic: string;
  keywords: string[];
}

interface VideoItem {
  id: number;
  title: string;
  source: '교내' | '유튜브' | 'KOCW';
  duration: string;
  relevanceScore: number;
  thumbnail: string;
  views: string;
  summary: string;
  instructor: string;
}

// -- Mock 데이터 -------------------------------------------------------

const subjects = ['파이썬 프로그래밍', '데이터베이스 설계', '웹 프로그래밍 실무'];

const weekTopics: WeekTopic[] = [
  { week: 1, topic: '파이썬 소개 및 개발환경 구축', keywords: ['파이썬', '설치', 'IDE'] },
  { week: 2, topic: '변수, 자료형, 입출력', keywords: ['변수', 'int', 'str', 'print'] },
  { week: 3, topic: '조건문과 반복문', keywords: ['if', 'for', 'while'] },
  { week: 4, topic: '함수와 모듈', keywords: ['def', 'import', 'return'] },
  { week: 5, topic: '리스트와 딕셔너리', keywords: ['list', 'dict', '자료구조'] },
  { week: 6, topic: '파일 입출력', keywords: ['open', 'read', 'write', 'csv'] },
  { week: 7, topic: '객체지향 프로그래밍', keywords: ['class', '상속', '캡슐화'] },
  { week: 8, topic: '중간고사', keywords: ['평가', '복습'] },
  { week: 9, topic: '예외처리와 디버깅', keywords: ['try', 'except', 'debug'] },
  { week: 10, topic: '정규표현식', keywords: ['regex', 're모듈', '패턴매칭'] },
  { week: 11, topic: '웹 크롤링 기초', keywords: ['requests', 'BeautifulSoup', 'crawling'] },
  { week: 12, topic: '데이터 시각화', keywords: ['matplotlib', 'pandas', 'chart'] },
  { week: 13, topic: 'API 활용', keywords: ['REST', 'JSON', 'requests'] },
  { week: 14, topic: '미니 프로젝트', keywords: ['프로젝트', '종합', '실전'] },
  { week: 15, topic: '기말고사', keywords: ['평가', '종합정리'] },
];

const videoRecommendations: Record<number, VideoItem[]> = {
  1: [
    { id: 101, title: '파이썬 첫걸음 - 설치부터 Hello World까지', source: '교내', duration: '25:30', relevanceScore: 98, thumbnail: '', views: '1,240', summary: '파이썬 3.x 설치 과정과 VS Code 개발환경 구축, 첫 번째 프로그램 작성까지의 과정을 단계별로 안내합니다. Anaconda 환경도 함께 소개합니다.', instructor: '김교수' },
    { id: 102, title: '왜 파이썬인가? - 프로그래밍 언어 비교와 전망', source: '유튜브', duration: '18:45', relevanceScore: 92, thumbnail: '', views: '45,200', summary: '파이썬의 특징과 장점을 다른 프로그래밍 언어와 비교하여 설명합니다. 취업 시장에서의 파이썬 수요와 활용 분야를 분석합니다.', instructor: '코딩마스터' },
    { id: 103, title: 'Python IDE 완벽 비교 (VS Code vs PyCharm)', source: '유튜브', duration: '22:10', relevanceScore: 88, thumbnail: '', views: '32,100', summary: '파이썬 개발에 많이 사용되는 IDE들의 장단점을 비교합니다. 학생들에게 적합한 개발환경 설정 방법을 소개합니다.', instructor: '개발자김' },
    { id: 104, title: '파이썬 기초 - 대학 강의 시리즈 (1강)', source: 'KOCW', duration: '50:00', relevanceScore: 85, thumbnail: '', views: '8,900', summary: 'KOCW 공개강의로, 대학 수준의 파이썬 프로그래밍 입문 강의입니다. 컴퓨터 과학의 기초 개념부터 시작합니다.', instructor: '이정화 교수' },
    { id: 105, title: 'Jupyter Notebook 활용법', source: '교내', duration: '15:20', relevanceScore: 82, thumbnail: '', views: '890', summary: 'Jupyter Notebook의 설치와 기본 사용법을 안내합니다. 마크다운 셀과 코드 셀 활용, 단축키 등 실용적인 팁을 다룹니다.', instructor: '박교수' },
    { id: 106, title: '파이썬으로 할 수 있는 것들 - 실무 활용 사례', source: '유튜브', duration: '20:30', relevanceScore: 78, thumbnail: '', views: '67,500', summary: '데이터 분석, 웹 개발, AI, 자동화 등 파이썬의 다양한 활용 사례를 실제 코드와 함께 소개합니다.', instructor: '테크톡' },
  ],
  3: [
    { id: 301, title: 'if문 마스터하기 - 조건문 완벽 정리', source: '교내', duration: '28:15', relevanceScore: 97, thumbnail: '', views: '2,100', summary: 'if, elif, else 구문의 문법과 활용법을 다양한 예제로 설명합니다. 중첩 조건문과 조건 표현식도 다룹니다.', instructor: '김교수' },
    { id: 302, title: 'for문과 while문 - 반복문의 모든 것', source: '교내', duration: '35:40', relevanceScore: 95, thumbnail: '', views: '1,890', summary: 'for문과 while문의 차이점, range() 함수 활용, break/continue/else 절의 사용법을 실습 코드와 함께 학습합니다.', instructor: '김교수' },
    { id: 303, title: '파이썬 조건문 실전 문제 풀이', source: '유튜브', duration: '42:20', relevanceScore: 91, thumbnail: '', views: '28,400', summary: '코딩테스트 기출 문제를 활용하여 조건문 활용 역량을 키웁니다. 단계별 문제 풀이 전략을 소개합니다.', instructor: '알고리즘왕' },
    { id: 304, title: '리스트 컴프리헨션과 조건 표현식', source: '유튜브', duration: '19:50', relevanceScore: 86, thumbnail: '', views: '15,600', summary: '파이썬만의 강력한 문법인 리스트 컴프리헨션과 삼항 연산자를 활용한 간결한 코드 작성법을 배웁니다.', instructor: '파이써니스타' },
    { id: 305, title: '반복문 활용 패턴 10가지', source: 'KOCW', duration: '45:00', relevanceScore: 83, thumbnail: '', views: '5,200', summary: '실무에서 자주 사용되는 반복문 패턴 10가지를 예제 코드와 함께 정리합니다. enumerate, zip 등 내장함수 활용법도 포함합니다.', instructor: '서울대 박교수' },
    { id: 306, title: '중첩 반복문으로 별 찍기 프로그램 만들기', source: '교내', duration: '20:00', relevanceScore: 79, thumbnail: '', views: '1,450', summary: '이중 for문을 활용한 별 찍기 프로그램을 단계별로 구현합니다. 중첩 루프의 동작 원리를 시각적으로 이해합니다.', instructor: '박교수' },
    { id: 307, title: '파이썬 제어문 종합 실습', source: '유튜브', duration: '55:10', relevanceScore: 75, thumbnail: '', views: '12,300', summary: '조건문과 반복문을 종합적으로 활용하는 실습 프로젝트입니다. 가위바위보 게임, 숫자 맞추기 게임 등을 구현합니다.', instructor: '코딩클럽' },
  ],
};

// 기본적으로 1주차 데이터를 보여주고, 3주차만 다른 데이터 있음. 나머지는 1주차 기반으로 표시
const getVideosForWeek = (week: number): VideoItem[] => {
  return videoRecommendations[week] || videoRecommendations[1] || [];
};

// -- 배지 스타일 헬퍼 ---------------------------------------------------

function sourceBadge(source: string): string {
  switch (source) {
    case '교내':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
    case '유튜브':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
    case 'KOCW':
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

function relevanceColor(score: number): string {
  if (score >= 90) return 'text-emerald-600 dark:text-emerald-400';
  if (score >= 80) return 'text-blue-600 dark:text-blue-400';
  if (score >= 70) return 'text-amber-600 dark:text-amber-400';
  return 'text-gray-500';
}

// -- 메인 컴포넌트 -------------------------------------------------------

export default function VideoRecommendPage() {
  const { t } = useTranslation();
  const [selectedSubject, setSelectedSubject] = useState(subjects[0]);
  const [selectedWeek, setSelectedWeek] = useState(1);
  const [previewVideo, setPreviewVideo] = useState<VideoItem | null>(null);

  const videos = getVideosForWeek(selectedWeek);
  const currentTopic = weekTopics.find((t) => t.week === selectedWeek);

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <div className="flex items-center gap-3 mb-1">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
            <Video className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.videoRecommendTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.videoRecommendDesc')}
            </p>
          </div>
        </div>
      </div>

      {/* 과목 + 주차 선택 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3">
          <div className="flex items-center gap-2">
            <BookOpen className="w-4 h-4 text-gray-500" />
            <select
              value={selectedSubject}
              onChange={(e) => setSelectedSubject(e.target.value)}
              className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            >
              {subjects.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
          <ChevronRight className="w-4 h-4 text-gray-300 hidden sm:block" />
          <div className="flex items-center gap-2">
            <Search className="w-4 h-4 text-gray-500" />
            <select
              value={selectedWeek}
              onChange={(e) => setSelectedWeek(Number(e.target.value))}
              className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            >
              {weekTopics.map((wt) => (
                <option key={wt.week} value={wt.week}>
                  {wt.week}주차 - {wt.topic}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* 분할 패널: 왼쪽 주차별 주제 / 오른쪽 추천 영상 */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* 왼쪽: 주차별 주제 목록 */}
        <div className="lg:col-span-1 space-y-1">
          <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3 px-1">
            주차별 학습주제
          </h3>
          <div className="space-y-1 max-h-[600px] overflow-y-auto">
            {weekTopics.map((wt) => (
              <button
                key={wt.week}
                onClick={() => setSelectedWeek(wt.week)}
                className={`w-full text-left px-3 py-2.5 rounded-lg text-sm transition-all ${
                  selectedWeek === wt.week
                    ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 font-medium border border-blue-200 dark:border-blue-800'
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                }`}
              >
                <span className="text-xs text-gray-400 dark:text-gray-500">{wt.week}주차</span>
                <p className="mt-0.5 text-xs leading-snug">{wt.topic}</p>
              </button>
            ))}
          </div>
        </div>

        {/* 오른쪽: 추천 영상 목록 */}
        <div className="lg:col-span-3">
          {/* 현재 주제 정보 */}
          {currentTopic && (
            <div className="flex items-center gap-3 mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
              <Sparkles className="w-5 h-5 text-blue-500 shrink-0" />
              <div>
                <p className="text-sm font-medium text-blue-700 dark:text-blue-300">
                  {currentTopic.week}주차: {currentTopic.topic}
                </p>
                <div className="flex flex-wrap gap-1.5 mt-1">
                  {currentTopic.keywords.map((kw) => (
                    <span
                      key={kw}
                      className="px-2 py-0.5 text-xs bg-blue-100 dark:bg-blue-800 text-blue-600 dark:text-blue-300 rounded"
                    >
                      {kw}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* 영상 카드 그리드 */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {videos.map((video) => (
              <div
                key={video.id}
                onClick={() => setPreviewVideo(video)}
                className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden cursor-pointer hover:shadow-md transition-all group"
              >
                {/* 썸네일 영역 */}
                <div className="relative h-36 bg-gradient-to-br from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 flex items-center justify-center">
                  <div className="w-14 h-14 rounded-full bg-black/40 flex items-center justify-center group-hover:bg-black/60 transition-colors">
                    <Play className="w-7 h-7 text-white ml-1" />
                  </div>
                  <span className="absolute bottom-2 right-2 px-2 py-0.5 text-xs font-medium bg-black/70 text-white rounded">
                    {video.duration}
                  </span>
                  <span
                    className={`absolute top-2 left-2 px-2 py-0.5 text-xs font-medium rounded ${sourceBadge(video.source)}`}
                  >
                    {video.source}
                  </span>
                </div>
                {/* 정보 영역 */}
                <div className="p-4">
                  <h4 className="text-sm font-semibold text-gray-900 dark:text-white line-clamp-2 mb-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                    {video.title}
                  </h4>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">{video.instructor}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 text-xs text-gray-400">
                      <span className="flex items-center gap-1">
                        <Eye className="w-3 h-3" />
                        {video.views}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {video.duration}
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Star className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
                      <span className={`text-sm font-bold ${relevanceColor(video.relevanceScore)}`}>
                        {video.relevanceScore}%
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <p className="text-xs text-gray-400 dark:text-gray-500 mt-4 text-center">
            총 {videos.length}개 영상이 추천되었습니다. 영상을 클릭하면 요약을 확인할 수 있습니다.
          </p>
        </div>
      </div>

      {/* 영상 미리보기 모달 */}
      {previewVideo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/50"
            onClick={() => setPreviewVideo(null)}
          />
          <div className="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            {/* 모달 헤더 */}
            <div className="flex items-center justify-between p-5 border-b border-gray-100 dark:border-gray-700">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white pr-4">
                {previewVideo.title}
              </h3>
              <button
                onClick={() => setPreviewVideo(null)}
                className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors shrink-0"
              >
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>

            {/* 비디오 플레이어 자리 */}
            <div className="relative h-64 bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-3 rounded-full bg-white/20 flex items-center justify-center">
                  <Play className="w-8 h-8 text-white ml-1" />
                </div>
                <p className="text-sm text-gray-400">영상 미리보기 영역</p>
              </div>
              <span className="absolute bottom-3 right-3 px-2 py-0.5 text-xs font-medium bg-black/60 text-white rounded">
                {previewVideo.duration}
              </span>
            </div>

            {/* 영상 상세 정보 */}
            <div className="p-5 space-y-4">
              <div className="flex items-center gap-3 flex-wrap">
                <span
                  className={`px-2.5 py-1 text-xs font-medium rounded-full ${sourceBadge(previewVideo.source)}`}
                >
                  {previewVideo.source}
                </span>
                <span className="flex items-center gap-1 text-xs text-gray-500">
                  <Clock className="w-3.5 h-3.5" />
                  {previewVideo.duration}
                </span>
                <span className="flex items-center gap-1 text-xs text-gray-500">
                  <Eye className="w-3.5 h-3.5" />
                  조회 {previewVideo.views}회
                </span>
                <span className="flex items-center gap-1 text-xs text-gray-500">
                  <ThumbsUp className="w-3.5 h-3.5" />
                  {previewVideo.instructor}
                </span>
              </div>

              <div>
                <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">영상 요약</h4>
                <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                  {previewVideo.summary}
                </p>
              </div>

              <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <div className="flex items-center gap-2">
                  <Star className="w-5 h-5 text-amber-400 fill-amber-400" />
                  <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    학습 관련도
                  </span>
                </div>
                <span className={`text-lg font-bold ${relevanceColor(previewVideo.relevanceScore)}`}>
                  {previewVideo.relevanceScore}%
                </span>
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => setPreviewVideo(null)}
                  className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
                >
                  {t('common.close')}
                </button>
                <button className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors">
                  <ExternalLink className="w-4 h-4" />
                  커리큘럼에 추가
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
