// src/pages/instructor/ai/AiSyllabusPage.tsx
// PRF-A01: AI 실라버스 생성 - AI 기반 자동 실라버스 초안 생성 및 편집

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Brain,
  Sparkles,
  Save,
  Edit3,
  Loader2,
  BookOpen,
  GraduationCap,
  Calendar,
  CheckCircle,
  Info,
  RefreshCw,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

interface SyllabusRow {
  week: number;
  topic: string;
  objective: string;
  method: string;
  note: string;
}

// -- Mock 데이터: 생성된 15주차 실라버스 ----------------------------------

const generatedSyllabus: SyllabusRow[] = [
  { week: 1, topic: '파이썬 소개 및 개발환경 구축', objective: '파이썬의 특징을 이해하고 개발환경을 설정할 수 있다', method: '이론+실습', note: '' },
  { week: 2, topic: '변수, 자료형, 입출력', objective: '기본 자료형과 입출력 함수를 활용할 수 있다', method: '이론+실습', note: 'NCS 참조' },
  { week: 3, topic: '연산자와 조건문 (if/elif/else)', objective: '조건문을 활용한 분기 처리를 구현할 수 있다', method: '이론+실습', note: '' },
  { week: 4, topic: '반복문 (for/while)과 제어문', objective: '반복문과 break/continue를 활용할 수 있다', method: '실습 중심', note: 'NCS 참조' },
  { week: 5, topic: '함수 정의와 매개변수', objective: '사용자 정의 함수를 작성하고 활용할 수 있다', method: '이론+실습', note: '' },
  { week: 6, topic: '모듈과 패키지', objective: '표준 라이브러리와 외부 패키지를 활용할 수 있다', method: '이론+실습', note: '' },
  { week: 7, topic: '리스트와 튜플', objective: '시퀀스 자료형을 이해하고 활용할 수 있다', method: '실습 중심', note: 'NCS 참조' },
  { week: 8, topic: '중간고사', objective: '1~7주차 학습내용 평가', method: '시험', note: '중간평가' },
  { week: 9, topic: '딕셔너리와 집합', objective: '매핑/집합 자료형을 활용한 데이터 처리가 가능하다', method: '이론+실습', note: '' },
  { week: 10, topic: '문자열 처리와 정규표현식', objective: '문자열 메서드와 정규식을 활용할 수 있다', method: '실습 중심', note: 'NCS 참조' },
  { week: 11, topic: '파일 입출력과 예외처리', objective: '파일 I/O와 try-except 구문을 구현할 수 있다', method: '이론+실습', note: '' },
  { week: 12, topic: '객체지향 프로그래밍 (클래스)', objective: '클래스와 객체의 개념을 이해하고 구현할 수 있다', method: '이론+실습', note: '' },
  { week: 13, topic: '상속과 다형성', objective: '상속을 활용한 코드 재사용을 수행할 수 있다', method: '이론+실습', note: 'NCS 참조' },
  { week: 14, topic: '미니 프로젝트 (데이터 분석)', objective: 'pandas를 활용한 간단한 데이터 분석 프로젝트를 완성할 수 있다', method: '프로젝트', note: '팀 프로젝트' },
  { week: 15, topic: '기말고사 및 프로젝트 발표', objective: '9~14주차 학습내용 평가 및 프로젝트 성과 발표', method: '시험+발표', note: '기말평가' },
];

// -- 메인 컴포넌트 -------------------------------------------------------

export default function AiSyllabusPage() {
  const { t } = useTranslation();
  const [courseName, setCourseName] = useState('파이썬 프로그래밍');
  const [targetGrade, setTargetGrade] = useState('2학년');
  const [totalWeeks, setTotalWeeks] = useState(15);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isGenerated, setIsGenerated] = useState(false);
  const [syllabus, setSyllabus] = useState<SyllabusRow[]>([]);
  const [editingCell, setEditingCell] = useState<{ week: number; field: keyof SyllabusRow } | null>(null);
  const [isSaved, setIsSaved] = useState(false);

  const handleGenerate = () => {
    setIsGenerating(true);
    setIsSaved(false);
    // AI 생성 시뮬레이션 (2초 딜레이)
    setTimeout(() => {
      setSyllabus([...generatedSyllabus]);
      setIsGenerated(true);
      setIsGenerating(false);
    }, 2000);
  };

  const handleCellEdit = (week: number, field: keyof SyllabusRow, value: string) => {
    setSyllabus((prev) =>
      prev.map((row) => (row.week === week ? { ...row, [field]: value } : row))
    );
    setIsSaved(false);
  };

  const handleSave = () => {
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 3000);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <div className="flex items-center gap-3 mb-1">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
            <Brain className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.aiSyllabusTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.aiSyllabusDesc')}
            </p>
          </div>
        </div>
      </div>

      {/* 입력 폼 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-4">기본 정보 입력</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
              <BookOpen className="w-3.5 h-3.5 inline mr-1" />
              과목명
            </label>
            <input
              type="text"
              value={courseName}
              onChange={(e) => setCourseName(e.target.value)}
              placeholder="과목명을 입력하세요"
              className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
              <GraduationCap className="w-3.5 h-3.5 inline mr-1" />
              대상학년
            </label>
            <select
              value={targetGrade}
              onChange={(e) => setTargetGrade(e.target.value)}
              className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            >
              <option>1학년</option>
              <option>2학년</option>
              <option>3학년</option>
              <option>4학년</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
              <Calendar className="w-3.5 h-3.5 inline mr-1" />
              총 주차수
            </label>
            <input
              type="number"
              value={totalWeeks}
              onChange={(e) => setTotalWeeks(Number(e.target.value))}
              min={1}
              max={20}
              className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            />
          </div>
        </div>

        <div className="mt-5 flex items-center gap-3">
          <button
            onClick={handleGenerate}
            disabled={isGenerating || !courseName.trim()}
            className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-all shadow-sm"
          >
            {isGenerating ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                AI 생성 중...
              </>
            ) : (
              <>
                <Sparkles className="w-4 h-4" />
                AI 생성
              </>
            )}
          </button>
          {isGenerated && (
            <button
              onClick={handleGenerate}
              className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              재생성
            </button>
          )}
        </div>
      </div>

      {/* 로딩 애니메이션 */}
      {isGenerating && (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-12 flex flex-col items-center justify-center">
          <div className="relative mb-4">
            <div className="w-16 h-16 rounded-full border-4 border-purple-200 dark:border-purple-800 animate-pulse" />
            <Brain className="absolute inset-0 m-auto w-8 h-8 text-purple-500 animate-bounce" />
          </div>
          <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            AI가 실라버스를 생성하고 있습니다
          </p>
          <p className="text-xs text-gray-400">
            NCS 학습모듈과 교육과정을 분석하여 최적의 주차 계획을 수립합니다...
          </p>
        </div>
      )}

      {/* 생성된 실라버스 테이블 */}
      {isGenerated && !isGenerating && (
        <>
          {/* NCS 참조 안내 */}
          <div className="flex items-start gap-3 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-200 dark:border-blue-800">
            <Info className="w-5 h-5 text-blue-500 shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-blue-700 dark:text-blue-300">
                NCS 학습모듈 참조 완료
              </p>
              <p className="text-xs text-blue-600 dark:text-blue-400 mt-0.5">
                '응용SW엔지니어링 (20010202)' NCS 능력단위를 기반으로 학습주제와 목표를 구성하였습니다.
                <span className="ml-1 px-1.5 py-0.5 bg-blue-100 dark:bg-blue-800 rounded text-blue-700 dark:text-blue-300 font-medium">
                  NCS 참조
                </span>
                표시가 된 주차는 NCS 모듈과 연계된 항목입니다.
              </p>
            </div>
          </div>

          {/* 실라버스 테이블 */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700">
              <h2 className="text-base font-semibold text-gray-900 dark:text-white">
                {courseName} - {totalWeeks}주차 실라버스
              </h2>
              <div className="flex items-center gap-2">
                {isSaved && (
                  <span className="flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                    <CheckCircle className="w-4 h-4" />
                    저장됨
                  </span>
                )}
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-gray-50 dark:bg-gray-700/50">
                    <th className="text-center py-3 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 w-16">
                      주차
                    </th>
                    <th className="text-left py-3 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 min-w-[200px]">
                      학습주제
                    </th>
                    <th className="text-left py-3 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 min-w-[250px]">
                      학습목표
                    </th>
                    <th className="text-center py-3 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 w-28">
                      교수방법
                    </th>
                    <th className="text-center py-3 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 w-24">
                      비고
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {syllabus.map((row) => (
                    <tr
                      key={row.week}
                      className="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors"
                    >
                      <td className="py-3 px-3 text-center font-medium text-gray-700 dark:text-gray-300">
                        <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-xs font-bold">
                          {row.week}
                        </span>
                      </td>
                      {/* 학습주제 - 클릭하여 편집 */}
                      <td
                        className="py-3 px-3 cursor-pointer group"
                        onClick={() => setEditingCell({ week: row.week, field: 'topic' })}
                      >
                        {editingCell?.week === row.week && editingCell?.field === 'topic' ? (
                          <input
                            type="text"
                            value={row.topic}
                            onChange={(e) => handleCellEdit(row.week, 'topic', e.target.value)}
                            onBlur={() => setEditingCell(null)}
                            onKeyDown={(e) => e.key === 'Enter' && setEditingCell(null)}
                            autoFocus
                            className="w-full px-2 py-1 text-sm border border-blue-400 rounded bg-blue-50 dark:bg-blue-900/30 dark:border-blue-600 text-gray-900 dark:text-white outline-none"
                          />
                        ) : (
                          <span className="text-gray-700 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                            {row.topic}
                            <Edit3 className="w-3 h-3 inline ml-1 opacity-0 group-hover:opacity-100 text-gray-400 transition-opacity" />
                          </span>
                        )}
                      </td>
                      {/* 학습목표 - 클릭하여 편집 */}
                      <td
                        className="py-3 px-3 cursor-pointer group"
                        onClick={() => setEditingCell({ week: row.week, field: 'objective' })}
                      >
                        {editingCell?.week === row.week && editingCell?.field === 'objective' ? (
                          <input
                            type="text"
                            value={row.objective}
                            onChange={(e) => handleCellEdit(row.week, 'objective', e.target.value)}
                            onBlur={() => setEditingCell(null)}
                            onKeyDown={(e) => e.key === 'Enter' && setEditingCell(null)}
                            autoFocus
                            className="w-full px-2 py-1 text-sm border border-blue-400 rounded bg-blue-50 dark:bg-blue-900/30 dark:border-blue-600 text-gray-900 dark:text-white outline-none"
                          />
                        ) : (
                          <span className="text-gray-600 dark:text-gray-400 text-xs group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                            {row.objective}
                            <Edit3 className="w-3 h-3 inline ml-1 opacity-0 group-hover:opacity-100 text-gray-400 transition-opacity" />
                          </span>
                        )}
                      </td>
                      {/* 교수방법 */}
                      <td className="py-3 px-3 text-center">
                        <span
                          className={`inline-block px-2.5 py-1 text-xs font-medium rounded-full ${
                            row.method === '시험' || row.method === '시험+발표'
                              ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                              : row.method === '프로젝트'
                              ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                              : row.method === '실습 중심'
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                              : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                          }`}
                        >
                          {row.method}
                        </span>
                      </td>
                      {/* 비고 */}
                      <td className="py-3 px-3 text-center">
                        {row.note === 'NCS 참조' ? (
                          <span className="inline-block px-2 py-0.5 text-xs font-medium bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 rounded">
                            NCS
                          </span>
                        ) : row.note ? (
                          <span className="text-xs text-gray-500 dark:text-gray-400">{row.note}</span>
                        ) : (
                          <span className="text-xs text-gray-300 dark:text-gray-600">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* 하단 버튼 영역 */}
          <div className="flex items-center justify-between">
            <p className="text-xs text-gray-400 dark:text-gray-500">
              각 셀을 클릭하면 직접 수정할 수 있습니다.
            </p>
            <div className="flex items-center gap-3">
              <button
                onClick={handleGenerate}
                className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              >
                <Edit3 className="w-4 h-4" />
                {t('common.edit')}
              </button>
              <button
                onClick={handleSave}
                className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-sm"
              >
                <Save className="w-4 h-4" />
                {t('common.save')}
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
