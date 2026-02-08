// pages/student/classroom/ExamPage.tsx — 시험 응시 페이지
import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { Clock, AlertTriangle, CheckCircle2, ChevronLeft, ChevronRight } from 'lucide-react';

const questions = [
  { id: 1, text: 'Python에서 리스트(List)의 특성으로 올바른 것은?', options: ['순서가 없다', '중복을 허용하지 않는다', '변경 가능(mutable)하다', '고정 크기이다'], answer: 2 },
  { id: 2, text: 'for i in range(5)의 출력 결과에 포함되지 않는 값은?', options: ['0', '3', '5', '4'], answer: 2 },
  { id: 3, text: 'Python에서 함수를 정의할 때 사용하는 키워드는?', options: ['function', 'def', 'func', 'define'], answer: 1 },
  { id: 4, text: '딕셔너리에서 키(key)의 특성으로 올바른 것은?', options: ['변경 가능해야 한다', '중복될 수 있다', '고유(unique)해야 한다', '정수만 가능하다'], answer: 2 },
  { id: 5, text: 'while True: 구문에서 루프를 종료하기 위한 키워드는?', options: ['stop', 'exit', 'break', 'end'], answer: 2 },
];

export default function ExamPage() {
  const { courseCode, week } = useParams();
  const [currentQ, setCurrentQ] = useState(0);
  const [answers, setAnswers] = useState<Record<number, number>>({});

  const q = questions[currentQ];
  const answeredCount = Object.keys(answers).length;

  return (
    <div className="page-container space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <nav className="text-xs text-content-muted flex items-center gap-1 mb-1">
            <Link to={`/classroom/${courseCode}`} className="hover:text-primary">학습실</Link>
            <span>/</span>
            <span className="text-content-default font-medium">중간고사</span>
          </nav>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{week}주차 중간고사</h1>
        </div>
        <div className="alert alert-warning py-2">
          <Clock className="w-4 h-4" />
          <span className="text-sm font-medium">남은 시간: 45:30</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Question Area */}
        <div className="lg:col-span-3">
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <span className="badge badge-info">문제 {currentQ + 1} / {questions.length}</span>
              <span className="text-xs text-gray-500">배점: 20점</span>
            </div>

            <h2 className="text-base font-semibold text-gray-900 dark:text-white mb-6">{q.text}</h2>

            <div className="space-y-3">
              {q.options.map((opt, i) => (
                <button
                  key={i}
                  onClick={() => setAnswers({ ...answers, [q.id]: i })}
                  className={`w-full text-left flex items-center gap-3 p-4 rounded-lg border transition-all ${
                    answers[q.id] === i
                      ? 'border-primary bg-primary-50 dark:bg-primary-900/20'
                      : 'border-gray-200 dark:border-slate-700 hover:border-primary-200 hover:bg-gray-50 dark:hover:bg-slate-800'
                  }`}
                >
                  <span className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium shrink-0 ${
                    answers[q.id] === i ? 'bg-primary text-white' : 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-400'
                  }`}>
                    {String.fromCharCode(65 + i)}
                  </span>
                  <span className="text-sm text-gray-700 dark:text-slate-300">{opt}</span>
                </button>
              ))}
            </div>

            {/* Navigation */}
            <div className="flex items-center justify-between mt-8">
              <button
                onClick={() => setCurrentQ(Math.max(0, currentQ - 1))}
                disabled={currentQ === 0}
                className="btn-secondary disabled:opacity-50"
              >
                <ChevronLeft className="w-4 h-4" /> 이전 문제
              </button>

              {currentQ < questions.length - 1 ? (
                <button onClick={() => setCurrentQ(currentQ + 1)} className="btn-primary">
                  다음 문제 <ChevronRight className="w-4 h-4" />
                </button>
              ) : (
                <button className="btn btn-md bg-success text-white hover:bg-success-600" disabled={answeredCount < questions.length}>
                  <CheckCircle2 className="w-4 h-4" /> 제출하기
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <aside className="space-y-4">
          <div className="card">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300 mb-3">문제 목록</h3>
            <div className="grid grid-cols-5 gap-2">
              {questions.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setCurrentQ(i)}
                  className={`w-full aspect-square rounded-lg flex items-center justify-center text-xs font-medium transition-colors ${
                    i === currentQ
                      ? 'bg-primary text-white'
                      : answers[questions[i].id] !== undefined
                        ? 'bg-success-50 text-success-700 border border-success-200'
                        : 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-400'
                  }`}
                >
                  {i + 1}
                </button>
              ))}
            </div>
            <p className="text-[10px] text-gray-400 mt-3 text-center">
              {answeredCount}/{questions.length} 답변 완료
            </p>
          </div>

          <div className="alert alert-danger">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            <div className="text-xs">
              <p className="font-medium">주의사항</p>
              <p className="mt-0.5">시험 중 탭 전환 시 부정행위로 감지될 수 있습니다.</p>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
