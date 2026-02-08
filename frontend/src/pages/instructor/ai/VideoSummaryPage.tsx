// src/pages/instructor/ai/VideoSummaryPage.tsx
// PRF-A03: 영상 요약 및 검증 - AI 기반 영상 요약, 키워드 추출, 품질 검증

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  FileText,
  Sparkles,
  Loader2,
  Play,
  Tag,
  BarChart3,
  ChevronDown,
  ChevronUp,
  Link2,
  CheckCircle,
  AlertTriangle,
  Volume2,
  Clock,
  Star,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

interface VideoOption {
  id: number;
  title: string;
  duration: string;
}

interface SummaryResult {
  threeLine: string[];
  keywords: string[];
  qualityScore: number;
  sttText: string;
  totalDuration: string;
  language: string;
  sttAccuracy: number;
}

// -- Mock 데이터 -------------------------------------------------------

const videoOptions: VideoOption[] = [
  { id: 1, title: '파이썬 첫걸음 - 설치부터 Hello World까지', duration: '25:30' },
  { id: 2, title: 'if문 마스터하기 - 조건문 완벽 정리', duration: '28:15' },
  { id: 3, title: 'for문과 while문 - 반복문의 모든 것', duration: '35:40' },
  { id: 4, title: '함수와 모듈 - 코드 재사용의 핵심', duration: '32:10' },
  { id: 5, title: '리스트 컴프리헨션과 고급 자료구조', duration: '40:20' },
];

const mockSummary: SummaryResult = {
  threeLine: [
    '파이썬 3.12 설치 방법과 VS Code 개발환경 구축 과정을 단계별로 안내하며, Anaconda 배포판과의 차이점을 설명합니다.',
    'print() 함수를 활용한 첫 번째 프로그램 작성과 변수 선언, 기본 자료형(int, float, str, bool)의 특징을 학습합니다.',
    'REPL(대화형 인터프리터)과 스크립트 모드의 차이를 이해하고, 간단한 입출력 프로그램을 작성하여 실행 결과를 확인합니다.',
  ],
  keywords: [
    '파이썬 설치',
    'VS Code',
    'Anaconda',
    'print()',
    '변수',
    '자료형',
    'REPL',
    '인터프리터',
    'Hello World',
    'pip',
    '가상환경',
    'IDE',
  ],
  qualityScore: 87,
  totalDuration: '25:30',
  language: '한국어',
  sttAccuracy: 94.2,
  sttText: `안녕하세요. 오늘은 파이썬 프로그래밍의 첫 번째 시간입니다. 이번 강의에서는 파이썬을 설치하고, 개발환경을 구축하고, 우리의 첫 번째 프로그램인 Hello World를 작성해 보겠습니다.

먼저 파이썬이 무엇인지 간단히 알아보겠습니다. 파이썬은 1991년 귀도 반 로섬이 만든 프로그래밍 언어로, 현재 가장 인기 있는 프로그래밍 언어 중 하나입니다. 문법이 간결하고 읽기 쉬워서 프로그래밍 입문자에게 특히 좋습니다.

파이썬을 설치하는 방법은 크게 두 가지가 있습니다. 첫째, python.org에서 공식 배포판을 다운로드하는 방법, 둘째, Anaconda 배포판을 사용하는 방법입니다. 공식 배포판은 가볍고 빠르게 설치할 수 있으며, Anaconda는 데이터 과학에 필요한 라이브러리들이 미리 포함되어 있어 편리합니다.

이번 강의에서는 공식 배포판을 사용하겠습니다. python.org에 접속하여 Downloads 메뉴를 클릭하면 운영체제에 맞는 최신 버전을 다운로드할 수 있습니다. 설치 시 반드시 "Add Python to PATH" 옵션을 체크해 주세요. 이 옵션을 체크하지 않으면 명령 프롬프트에서 파이썬을 실행할 수 없습니다.

설치가 완료되면 명령 프롬프트를 열고 python --version 명령어를 입력하여 설치가 정상적으로 되었는지 확인합니다.

다음으로 VS Code를 설치하겠습니다. VS Code는 마이크로소프트에서 만든 무료 코드 편집기로, 파이썬 개발에 가장 많이 사용됩니다. VS Code를 설치한 후, Python 확장 프로그램을 추가로 설치하면 코드 자동완성, 디버깅 등의 기능을 사용할 수 있습니다.

이제 우리의 첫 번째 프로그램을 작성해 보겠습니다. VS Code에서 새 파일을 만들고 hello.py라고 저장합니다. 그리고 다음과 같이 입력합니다. print("Hello, World!") 그리고 실행 버튼을 누르면 터미널에 Hello, World!가 출력되는 것을 확인할 수 있습니다.

변수에 대해서도 간단히 알아보겠습니다. 변수는 데이터를 저장하는 공간입니다. 파이썬에서는 별도의 자료형 선언 없이 값을 할당하면 자동으로 자료형이 결정됩니다. 예를 들어, name = "홍길동"이라고 입력하면 name은 문자열 변수가 됩니다.

파이썬의 기본 자료형에는 정수(int), 실수(float), 문자열(str), 불리언(bool)이 있습니다. type() 함수를 사용하면 변수의 자료형을 확인할 수 있습니다.

다음 시간에는 연산자와 조건문에 대해 배우겠습니다. 오늘 배운 내용을 복습하고, 다양한 print() 문을 작성해 보시기 바랍니다. 감사합니다.`,
};

// -- 메인 컴포넌트 -------------------------------------------------------

export default function VideoSummaryPage() {
  const { t } = useTranslation();
  const [videoUrl, setVideoUrl] = useState('');
  const [selectedVideo, setSelectedVideo] = useState<number | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [summary, setSummary] = useState<SummaryResult | null>(null);
  const [showStt, setShowStt] = useState(false);

  const handleAnalyze = () => {
    setIsAnalyzing(true);
    setTimeout(() => {
      setSummary(mockSummary);
      setIsAnalyzing(false);
    }, 2500);
  };

  const getQualityColor = (score: number) => {
    if (score >= 85) return { bar: 'bg-emerald-500', text: 'text-emerald-600 dark:text-emerald-400', label: '우수' };
    if (score >= 70) return { bar: 'bg-blue-500', text: 'text-blue-600 dark:text-blue-400', label: '양호' };
    if (score >= 50) return { bar: 'bg-amber-500', text: 'text-amber-600 dark:text-amber-400', label: '보통' };
    return { bar: 'bg-red-500', text: 'text-red-600 dark:text-red-400', label: '개선필요' };
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <div className="flex items-center gap-3 mb-1">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
            <FileText className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.videoSummaryTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.videoSummaryDesc')}
            </p>
          </div>
        </div>
      </div>

      {/* 영상 입력 영역 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-300">영상 선택</h2>

        {/* URL 직접 입력 */}
        <div>
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
            <Link2 className="w-3.5 h-3.5 inline mr-1" />
            영상 URL 직접 입력
          </label>
          <input
            type="url"
            value={videoUrl}
            onChange={(e) => {
              setVideoUrl(e.target.value);
              setSelectedVideo(null);
            }}
            placeholder="https://www.youtube.com/watch?v=..."
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
          />
        </div>

        <div className="flex items-center gap-3">
          <div className="flex-1 h-px bg-gray-200 dark:bg-gray-700" />
          <span className="text-xs text-gray-400">또는</span>
          <div className="flex-1 h-px bg-gray-200 dark:bg-gray-700" />
        </div>

        {/* 추천 영상에서 선택 */}
        <div>
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
            추천 영상에서 선택
          </label>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
            {videoOptions.map((v) => (
              <button
                key={v.id}
                onClick={() => {
                  setSelectedVideo(v.id);
                  setVideoUrl('');
                }}
                className={`text-left p-3 rounded-lg border text-sm transition-all ${
                  selectedVideo === v.id
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/30 ring-1 ring-blue-500'
                    : 'border-gray-200 dark:border-gray-600 hover:border-gray-300 dark:hover:border-gray-500'
                }`}
              >
                <div className="flex items-start gap-2">
                  <Play className="w-4 h-4 text-gray-400 mt-0.5 shrink-0" />
                  <div>
                    <p className="text-xs font-medium text-gray-700 dark:text-gray-300 line-clamp-2">
                      {v.title}
                    </p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      <Clock className="w-3 h-3 inline mr-0.5" />
                      {v.duration}
                    </p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        <button
          onClick={handleAnalyze}
          disabled={isAnalyzing || (!videoUrl && !selectedVideo)}
          className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-all shadow-sm"
        >
          {isAnalyzing ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              요약 생성 중...
            </>
          ) : (
            <>
              <Sparkles className="w-4 h-4" />
              요약 생성
            </>
          )}
        </button>
      </div>

      {/* 로딩 상태 */}
      {isAnalyzing && (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-12 flex flex-col items-center justify-center">
          <div className="relative mb-4">
            <div className="w-16 h-16 rounded-full border-4 border-amber-200 dark:border-amber-800 animate-pulse" />
            <Volume2 className="absolute inset-0 m-auto w-8 h-8 text-amber-500 animate-bounce" />
          </div>
          <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            영상을 분석하고 있습니다
          </p>
          <p className="text-xs text-gray-400">
            STT 변환 → 텍스트 분석 → 요약 생성 → 품질 검증
          </p>
        </div>
      )}

      {/* 결과 영역 */}
      {summary && !isAnalyzing && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* 왼쪽: 영상 플레이어 (플레이스홀더) */}
          <div className="space-y-4">
            <div className="bg-gray-900 rounded-xl overflow-hidden aspect-video flex items-center justify-center relative">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-3 rounded-full bg-white/20 flex items-center justify-center">
                  <Play className="w-8 h-8 text-white ml-1" />
                </div>
                <p className="text-sm text-gray-400">영상 플레이어</p>
                <p className="text-xs text-gray-500 mt-1">
                  {videoOptions.find((v) => v.id === selectedVideo)?.title || '선택된 영상'}
                </p>
              </div>
              <span className="absolute bottom-3 right-3 px-2 py-0.5 text-xs bg-black/60 text-white rounded">
                {summary.totalDuration}
              </span>
            </div>

            {/* 영상 메타정보 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
              <div className="grid grid-cols-3 gap-4 text-center">
                <div>
                  <p className="text-xs text-gray-400 mb-1">영상 길이</p>
                  <p className="text-sm font-bold text-gray-700 dark:text-gray-300">{summary.totalDuration}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 mb-1">언어</p>
                  <p className="text-sm font-bold text-gray-700 dark:text-gray-300">{summary.language}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 mb-1">STT 정확도</p>
                  <p className="text-sm font-bold text-emerald-600 dark:text-emerald-400">{summary.sttAccuracy}%</p>
                </div>
              </div>
            </div>

            {/* STT 전문 보기 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
              <button
                onClick={() => setShowStt(!showStt)}
                className="w-full flex items-center justify-between p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Volume2 className="w-4 h-4 text-gray-500" />
                  <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                    STT 전문 보기
                  </span>
                </div>
                {showStt ? (
                  <ChevronUp className="w-4 h-4 text-gray-400" />
                ) : (
                  <ChevronDown className="w-4 h-4 text-gray-400" />
                )}
              </button>
              {showStt && (
                <div className="px-4 pb-4">
                  <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4 max-h-80 overflow-y-auto">
                    <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed whitespace-pre-wrap">
                      {summary.sttText}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* 오른쪽: 요약 결과 */}
          <div className="space-y-4">
            {/* 3줄 요약 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
              <div className="flex items-center gap-2 mb-4">
                <FileText className="w-4 h-4 text-amber-500" />
                <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">3줄 요약</h3>
              </div>
              <div className="space-y-3">
                {summary.threeLine.map((line, i) => (
                  <div key={i} className="flex gap-3">
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 text-xs font-bold shrink-0">
                      {i + 1}
                    </span>
                    <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                      {line}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            {/* 핵심 키워드 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
              <div className="flex items-center gap-2 mb-4">
                <Tag className="w-4 h-4 text-blue-500" />
                <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">핵심 키워드</h3>
              </div>
              <div className="flex flex-wrap gap-2">
                {summary.keywords.map((kw) => (
                  <span
                    key={kw}
                    className="px-3 py-1.5 text-xs font-medium bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-full border border-blue-200 dark:border-blue-800"
                  >
                    {kw}
                  </span>
                ))}
              </div>
            </div>

            {/* 품질 점수 게이지 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
              <div className="flex items-center gap-2 mb-4">
                <BarChart3 className="w-4 h-4 text-purple-500" />
                <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">교육 품질 점수</h3>
              </div>
              {(() => {
                const quality = getQualityColor(summary.qualityScore);
                return (
                  <div className="space-y-4">
                    {/* 게이지 */}
                    <div className="relative">
                      <div className="flex items-center justify-between mb-2">
                        <span className={`text-3xl font-bold ${quality.text}`}>
                          {summary.qualityScore}
                        </span>
                        <span className={`px-3 py-1 text-xs font-medium rounded-full ${
                          summary.qualityScore >= 85
                            ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
                            : summary.qualityScore >= 70
                            ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                            : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                        }`}>
                          {quality.label}
                        </span>
                      </div>
                      <div className="w-full h-4 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                        <div
                          className={`h-full ${quality.bar} rounded-full transition-all duration-1000`}
                          style={{ width: `${summary.qualityScore}%` }}
                        />
                      </div>
                    </div>
                    {/* 세부 항목 */}
                    <div className="grid grid-cols-2 gap-3">
                      <div className="flex items-center gap-2 p-2.5 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <CheckCircle className="w-4 h-4 text-emerald-500" />
                        <div>
                          <p className="text-xs text-gray-400">내용 정확도</p>
                          <p className="text-sm font-bold text-gray-700 dark:text-gray-300">92%</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 p-2.5 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
                        <div>
                          <p className="text-xs text-gray-400">학습 적합도</p>
                          <p className="text-sm font-bold text-gray-700 dark:text-gray-300">88%</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 p-2.5 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <Volume2 className="w-4 h-4 text-blue-500" />
                        <div>
                          <p className="text-xs text-gray-400">음성 품질</p>
                          <p className="text-sm font-bold text-gray-700 dark:text-gray-300">85%</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 p-2.5 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <AlertTriangle className="w-4 h-4 text-orange-500" />
                        <div>
                          <p className="text-xs text-gray-400">저작권 위험</p>
                          <p className="text-sm font-bold text-emerald-600 dark:text-emerald-400">낮음</p>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })()}
            </div>

            {/* 활용 버튼 */}
            <div className="flex gap-3">
              <button className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors">
                요약 다운로드
              </button>
              <button className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-sm">
                커리큘럼에 추가
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
