import { useState } from 'react';
import { Clock, AlertTriangle } from 'lucide-react';
import { useTranslation } from '@/i18n';

const questions = [
  { id: 1, text: 'Python에서 변수를 선언할 때 사용하는 키워드는?', options: ['var','let','없음 (바로 할당)','const'], answer: 2 },
  { id: 2, text: 'print("Hello") 실행 결과는?', options: ['Hello','print("Hello")','Error','None'], answer: 0 },
  { id: 3, text: 'for i in range(3)의 i 값은?', options: ['1,2,3','0,1,2','0,1,2,3','1,2'], answer: 1 },
];

export default function ExamPage() {
  const { t } = useTranslation();
  const [answers, setAnswers] = useState<Record<number, number>>({});
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">{t('student.examTitle')}</h1>
        <div className="flex items-center gap-2 text-sm text-danger-600 font-medium"><Clock className="w-4 h-4" />남은 시간: 28:30</div>
      </div>
      <div className="alert alert-warning"><AlertTriangle className="w-4 h-4 shrink-0" />시험 중 다른 탭으로 전환 시 부정행위로 기록될 수 있습니다.</div>
      <div className="space-y-6">
        {questions.map((q, idx) => (
          <div key={q.id} className="card p-5">
            <div className="text-sm font-medium mb-4"><span className="text-primary-600 mr-2">Q{idx + 1}.</span>{q.text}</div>
            <div className="space-y-2">
              {q.options.map((opt, oi) => (
                <button key={oi} onClick={() => setAnswers({ ...answers, [q.id]: oi })}
                  className={`w-full text-left p-3 rounded-lg border text-sm transition-colors ${answers[q.id] === oi ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20' : 'border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-800'}`}>
                  <span className="font-medium mr-2">{String.fromCharCode(65 + oi)}.</span>{opt}
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>
      <button className="btn-primary w-full justify-center">답안 제출</button>
    </div>
  );
}
