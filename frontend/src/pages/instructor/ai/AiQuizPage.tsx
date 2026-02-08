// src/pages/instructor/ai/AiQuizPage.tsx
// PRF-E02: AI 퀴즈 생성 - 텍스트 기반 객관식 문제 자동 생성 및 편집

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Brain,
  Sparkles,
  Loader2,
  CheckCircle,
  Edit3,
  Save,
  HelpCircle,
  FileText,
  Type,
  AlertCircle,
  Trash2,
  Plus,
  BookOpen,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

type Difficulty = '쉬움' | '보통' | '어려움';
type SourceType = 'stt' | 'manual';

interface QuizChoice {
  label: string;
  text: string;
}

interface QuizQuestion {
  id: number;
  question: string;
  choices: QuizChoice[];
  answer: string;
  explanation: string;
  difficulty: Difficulty;
}

// -- Mock 데이터: 생성된 퀴즈 -------------------------------------------

const generatedQuiz: QuizQuestion[] = [
  {
    id: 1,
    question: '파이썬에서 변수에 값을 할당할 때 사용하는 연산자는?',
    choices: [
      { label: 'A', text: '== (등호 두 개)' },
      { label: 'B', text: '= (등호 한 개)' },
      { label: 'C', text: ':= (콜론 등호)' },
      { label: 'D', text: '<- (화살표)' },
    ],
    answer: 'B',
    explanation:
      '파이썬에서 변수에 값을 할당할 때는 = (등호 한 개)를 사용합니다. ==는 비교 연산자이며, :=는 바다코끼리 연산자(walrus operator)로 Python 3.8부터 도입된 할당 표현식입니다. <-는 R 언어에서 사용되는 할당 연산자입니다.',
    difficulty: '쉬움',
  },
  {
    id: 2,
    question: '다음 파이썬 코드의 실행 결과로 올바른 것은?\n\nfor i in range(1, 6):\n    if i % 2 == 0:\n        print(i, end=" ")',
    choices: [
      { label: 'A', text: '1 2 3 4 5' },
      { label: 'B', text: '2 4' },
      { label: 'C', text: '2 4 6' },
      { label: 'D', text: '1 3 5' },
    ],
    answer: 'B',
    explanation:
      'range(1, 6)은 1부터 5까지의 정수를 생성합니다. i % 2 == 0 조건은 짝수인 경우에만 참이 되므로, i가 2와 4일 때만 print가 실행됩니다. 따라서 출력 결과는 "2 4"입니다.',
    difficulty: '보통',
  },
  {
    id: 3,
    question: '파이썬의 리스트(list)에 대한 설명으로 옳지 않은 것은?',
    choices: [
      { label: 'A', text: '리스트는 대괄호 []를 사용하여 생성한다' },
      { label: 'B', text: '리스트의 요소는 서로 다른 자료형을 가질 수 있다' },
      { label: 'C', text: '리스트는 생성 후 요소를 변경할 수 없다 (불변)' },
      { label: 'D', text: 'append() 메서드로 요소를 추가할 수 있다' },
    ],
    answer: 'C',
    explanation:
      '파이썬의 리스트는 가변(mutable) 자료형입니다. 생성 후에도 요소를 추가, 삭제, 변경할 수 있습니다. 불변(immutable) 자료형은 튜플(tuple)입니다. 따라서 C번이 옳지 않은 설명입니다.',
    difficulty: '어려움',
  },
];

const sampleSttText = `파이썬에서 변수는 데이터를 저장하는 공간입니다. 등호 기호를 사용하여 값을 할당하며, 별도의 자료형 선언이 필요 없습니다. 기본 자료형으로는 정수, 실수, 문자열, 불리언이 있습니다. for문은 range 함수와 함께 사용하여 반복 처리를 수행합니다. 조건문은 if, elif, else 키워드를 사용합니다. 리스트는 대괄호로 생성하며 가변 자료형으로 요소의 추가, 삭제, 변경이 가능합니다.`;

// -- 난이도 배지 색상 ---------------------------------------------------

function difficultyBadge(d: Difficulty): string {
  switch (d) {
    case '쉬움':
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    case '보통':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
    case '어려움':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
  }
}

// -- 메인 컴포넌트 -------------------------------------------------------

export default function AiQuizPage() {
  const { t } = useTranslation();
  const [sourceType, setSourceType] = useState<SourceType>('stt');
  const [sourceText, setSourceText] = useState(sampleSttText);
  const [difficulty, setDifficulty] = useState<Difficulty>('보통');
  const [isGenerating, setIsGenerating] = useState(false);
  const [quiz, setQuiz] = useState<QuizQuestion[]>([]);
  const [editingField, setEditingField] = useState<{
    qId: number;
    field: string;
    choiceLabel?: string;
  } | null>(null);
  const [isSaved, setIsSaved] = useState(false);

  const handleGenerate = () => {
    setIsGenerating(true);
    setIsSaved(false);
    setTimeout(() => {
      setQuiz([...generatedQuiz]);
      setIsGenerating(false);
    }, 2000);
  };

  const handleQuizEdit = (qId: number, field: string, value: string, choiceLabel?: string) => {
    setQuiz((prev) =>
      prev.map((q) => {
        if (q.id !== qId) return q;
        if (field === 'question') return { ...q, question: value };
        if (field === 'explanation') return { ...q, explanation: value };
        if (field === 'answer') return { ...q, answer: value };
        if (field === 'choice' && choiceLabel) {
          return {
            ...q,
            choices: q.choices.map((c) =>
              c.label === choiceLabel ? { ...c, text: value } : c
            ),
          };
        }
        return q;
      })
    );
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
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center">
            <HelpCircle className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.aiQuizTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.aiQuizDesc')}
            </p>
          </div>
        </div>
      </div>

      {/* 입력 영역 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 space-y-4">
        {/* 소스 유형 선택 */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
            출제 소스 선택
          </label>
          <div className="flex gap-3">
            <button
              onClick={() => {
                setSourceType('stt');
                setSourceText(sampleSttText);
              }}
              className={`flex items-center gap-2 px-4 py-2.5 text-sm rounded-lg border transition-all ${
                sourceType === 'stt'
                  ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 ring-1 ring-purple-500'
                  : 'border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:border-gray-300'
              }`}
            >
              <FileText className="w-4 h-4" />
              영상 STT 텍스트
            </button>
            <button
              onClick={() => {
                setSourceType('manual');
                setSourceText('');
              }}
              className={`flex items-center gap-2 px-4 py-2.5 text-sm rounded-lg border transition-all ${
                sourceType === 'manual'
                  ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 ring-1 ring-purple-500'
                  : 'border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:border-gray-300'
              }`}
            >
              <Type className="w-4 h-4" />
              직접 입력
            </button>
          </div>
        </div>

        {/* 텍스트 입력 영역 */}
        <div>
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
            {sourceType === 'stt' ? '영상 STT 변환 텍스트' : '출제 소스 텍스트를 입력하세요'}
          </label>
          <textarea
            value={sourceText}
            onChange={(e) => setSourceText(e.target.value)}
            rows={6}
            placeholder="퀴즈 생성의 기반이 될 학습 내용을 입력하세요..."
            className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-3 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors resize-none"
          />
          <p className="text-xs text-gray-400 mt-1">{sourceText.length}자</p>
        </div>

        {/* 난이도 선택 */}
        <div>
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
            난이도 선택
          </label>
          <div className="flex gap-2">
            {(['쉬움', '보통', '어려움'] as Difficulty[]).map((d) => (
              <button
                key={d}
                onClick={() => setDifficulty(d)}
                className={`px-4 py-2 text-sm rounded-lg border transition-all ${
                  difficulty === d
                    ? `${difficultyBadge(d)} border-transparent font-medium`
                    : 'border-gray-200 dark:border-gray-600 text-gray-500 dark:text-gray-400 hover:border-gray-300'
                }`}
              >
                {d}
              </button>
            ))}
          </div>
        </div>

        {/* 생성 버튼 */}
        <button
          onClick={handleGenerate}
          disabled={isGenerating || !sourceText.trim()}
          className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-all shadow-sm"
        >
          {isGenerating ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              퀴즈 생성 중...
            </>
          ) : (
            <>
              <Sparkles className="w-4 h-4" />
              퀴즈 생성
            </>
          )}
        </button>
      </div>

      {/* 로딩 상태 */}
      {isGenerating && (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-12 flex flex-col items-center justify-center">
          <div className="relative mb-4">
            <div className="w-16 h-16 rounded-full border-4 border-purple-200 dark:border-purple-800 animate-pulse" />
            <Brain className="absolute inset-0 m-auto w-8 h-8 text-purple-500 animate-bounce" />
          </div>
          <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            AI가 퀴즈를 생성하고 있습니다
          </p>
          <p className="text-xs text-gray-400">
            텍스트를 분석하여 핵심 개념 기반의 객관식 문제를 만들고 있습니다...
          </p>
        </div>
      )}

      {/* 생성된 퀴즈 목록 */}
      {quiz.length > 0 && !isGenerating && (
        <>
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              생성된 퀴즈 ({quiz.length}문제)
            </h2>
            {isSaved && (
              <span className="flex items-center gap-1 text-sm text-emerald-600 dark:text-emerald-400 font-medium">
                <CheckCircle className="w-4 h-4" />
                문제은행에 등록되었습니다
              </span>
            )}
          </div>

          <div className="space-y-6">
            {quiz.map((q, qIdx) => (
              <div
                key={q.id}
                className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden"
              >
                {/* 문제 헤더 */}
                <div className="flex items-center justify-between px-6 py-4 bg-gray-50 dark:bg-gray-700/50 border-b border-gray-100 dark:border-gray-700">
                  <div className="flex items-center gap-3">
                    <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 text-sm font-bold">
                      {qIdx + 1}
                    </span>
                    <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${difficultyBadge(q.difficulty)}`}>
                      {q.difficulty}
                    </span>
                  </div>
                  <button
                    onClick={() => setQuiz((prev) => prev.filter((item) => item.id !== q.id))}
                    className="p-1.5 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30 text-gray-400 hover:text-red-500 transition-colors"
                    title="문제 삭제"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>

                <div className="p-6 space-y-5">
                  {/* 문제 */}
                  <div>
                    <label className="text-xs font-medium text-gray-400 mb-1 block">문제</label>
                    {editingField?.qId === q.id && editingField?.field === 'question' ? (
                      <textarea
                        value={q.question}
                        onChange={(e) => handleQuizEdit(q.id, 'question', e.target.value)}
                        onBlur={() => setEditingField(null)}
                        autoFocus
                        rows={3}
                        className="w-full px-3 py-2 text-sm border border-blue-400 rounded-lg bg-blue-50 dark:bg-blue-900/30 dark:border-blue-600 text-gray-900 dark:text-white outline-none resize-none"
                      />
                    ) : (
                      <div
                        onClick={() => setEditingField({ qId: q.id, field: 'question' })}
                        className="text-sm font-medium text-gray-900 dark:text-white whitespace-pre-wrap cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/50 p-2 rounded-lg transition-colors group"
                      >
                        {q.question}
                        <Edit3 className="w-3 h-3 inline ml-2 text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity" />
                      </div>
                    )}
                  </div>

                  {/* 보기 A~D */}
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-gray-400 block">보기</label>
                    {q.choices.map((choice) => (
                      <div
                        key={choice.label}
                        className={`flex items-start gap-3 p-3 rounded-lg border transition-all ${
                          q.answer === choice.label
                            ? 'border-emerald-300 dark:border-emerald-700 bg-emerald-50 dark:bg-emerald-900/20'
                            : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800'
                        }`}
                      >
                        <button
                          onClick={() => handleQuizEdit(q.id, 'answer', choice.label)}
                          className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold shrink-0 transition-colors ${
                            q.answer === choice.label
                              ? 'bg-emerald-500 text-white'
                              : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:bg-blue-100 dark:hover:bg-blue-900/30 hover:text-blue-600'
                          }`}
                          title="정답으로 설정"
                        >
                          {choice.label}
                        </button>
                        {editingField?.qId === q.id &&
                        editingField?.field === 'choice' &&
                        editingField?.choiceLabel === choice.label ? (
                          <input
                            type="text"
                            value={choice.text}
                            onChange={(e) =>
                              handleQuizEdit(q.id, 'choice', e.target.value, choice.label)
                            }
                            onBlur={() => setEditingField(null)}
                            onKeyDown={(e) => e.key === 'Enter' && setEditingField(null)}
                            autoFocus
                            className="flex-1 px-2 py-1 text-sm border border-blue-400 rounded bg-blue-50 dark:bg-blue-900/30 dark:border-blue-600 text-gray-900 dark:text-white outline-none"
                          />
                        ) : (
                          <span
                            onClick={() =>
                              setEditingField({ qId: q.id, field: 'choice', choiceLabel: choice.label })
                            }
                            className="flex-1 text-sm text-gray-700 dark:text-gray-300 cursor-pointer hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                          >
                            {choice.text}
                            {q.answer === choice.label && (
                              <CheckCircle className="w-4 h-4 inline ml-2 text-emerald-500" />
                            )}
                          </span>
                        )}
                      </div>
                    ))}
                  </div>

                  {/* 정답 표시 */}
                  <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg border border-emerald-200 dark:border-emerald-800">
                    <CheckCircle className="w-4 h-4 text-emerald-500 shrink-0" />
                    <span className="text-sm font-medium text-emerald-700 dark:text-emerald-400">
                      정답: {q.answer}
                    </span>
                  </div>

                  {/* 해설 */}
                  <div>
                    <label className="text-xs font-medium text-gray-400 mb-1 block">해설</label>
                    {editingField?.qId === q.id && editingField?.field === 'explanation' ? (
                      <textarea
                        value={q.explanation}
                        onChange={(e) => handleQuizEdit(q.id, 'explanation', e.target.value)}
                        onBlur={() => setEditingField(null)}
                        autoFocus
                        rows={3}
                        className="w-full px-3 py-2 text-sm border border-blue-400 rounded-lg bg-blue-50 dark:bg-blue-900/30 dark:border-blue-600 text-gray-900 dark:text-white outline-none resize-none"
                      />
                    ) : (
                      <div
                        onClick={() => setEditingField({ qId: q.id, field: 'explanation' })}
                        className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/50 p-2 rounded-lg transition-colors group"
                      >
                        <AlertCircle className="w-4 h-4 inline mr-1 text-amber-500" />
                        {q.explanation}
                        <Edit3 className="w-3 h-3 inline ml-2 text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity" />
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* 하단 버튼 */}
          <div className="flex items-center justify-between">
            <button
              onClick={handleGenerate}
              className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              <Plus className="w-4 h-4" />
              추가 문제 생성
            </button>
            <div className="flex items-center gap-3">
              <span className="text-sm text-gray-400">총 {quiz.length}문제</span>
              <button
                onClick={handleSave}
                className="inline-flex items-center gap-2 px-6 py-2.5 text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 rounded-lg transition-colors shadow-sm"
              >
                <BookOpen className="w-4 h-4" />
                문제은행에 등록
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
