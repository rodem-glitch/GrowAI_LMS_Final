import { useState } from 'react';
import { FileText, ChevronRight } from 'lucide-react';
import { ExamCreateModal } from './ExamCreateModal';

interface ExamTabWrapperProps {
  exams: any[];
  examScores: any;
  onSelectExam: (id: number) => void;
  ExamDetailView: any;
}

export function ExamTabWrapper({ exams, examScores, onSelectExam, ExamDetailView }: ExamTabWrapperProps) {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedExam, setSelectedExam] = useState<number | null>(null);

  const handleCreateExam = (examData: any) => {
    console.log('새 시험 등록:', examData);
    // 실제로는 여기서 시험 데이터를 저장하는 로직이 들어갑니다
    alert('시험이 등록되었습니다.');
  };

  if (selectedExam !== null) {
    const exam = exams.find((e) => e.id === selectedExam);
    const scores = examScores[selectedExam];
    
    return <ExamDetailView exam={exam} scores={scores} onBack={() => setSelectedExam(null)} />;
  }

  return (
    <>
      <div className="space-y-4">
        <div className="flex justify-end">
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <FileText className="w-4 h-4" />
            <span>시험 등록</span>
          </button>
        </div>
        {exams.map((exam) => (
          <button
            key={exam.id}
            onClick={() => setSelectedExam(exam.id)}
            className="w-full p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="text-gray-900 mb-1">{exam.title}</div>
                <div className="text-sm text-gray-600">
                  시험일: {exam.date} • 시험시간: {exam.duration}
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <div className="text-sm text-gray-600">제출 현황</div>
                  <div className="text-gray-900">
                    {exam.submitted} / {exam.total}명
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </div>
            </div>
          </button>
        ))}
      </div>

      <ExamCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={handleCreateExam}
      />
    </>
  );
}
