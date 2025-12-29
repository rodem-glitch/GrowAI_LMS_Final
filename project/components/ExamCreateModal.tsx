import { useState } from 'react';
import { X } from 'lucide-react';

interface ExamCreateModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (examData: any) => void;
}

export function ExamCreateModal({ isOpen, onClose, onSave }: ExamCreateModalProps) {
  const [examData, setExamData] = useState({
    title: '',
    description: '',
    examDate: '',
    examTime: '',
    examEndDate: '',
    examEndTime: '',
    duration: '',
    totalScore: 100,
    passingScore: 60,
    questionCount: 0,
    allowRetake: false,
    showResults: true,
  });

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(examData);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h3 className="text-gray-900">시험 등록</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* 시험 제목 */}
          <div>
            <label className="block text-sm text-gray-700 mb-2">
              시험 제목 <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={examData.title}
              onChange={(e) => setExamData({ ...examData, title: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="예: 중간고사"
              required
            />
          </div>

          {/* 시험 설명 */}
          <div>
            <label className="block text-sm text-gray-700 mb-2">시험 설명</label>
            <textarea
              value={examData.description}
              onChange={(e) => setExamData({ ...examData, description: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              rows={3}
              placeholder="시험에 대한 설명을 입력하세요"
            />
          </div>

          {/* 시험 일시 */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-700 mb-2">
                시험 날짜 <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                value={examData.examDate}
                onChange={(e) => setExamData({ ...examData, examDate: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">
                시작 시간 <span className="text-red-500">*</span>
              </label>
              <input
                type="time"
                value={examData.examTime}
                onChange={(e) => setExamData({ ...examData, examTime: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
          </div>

          {/* 시험 마감 일시 */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-700 mb-2">
                마감 날짜 <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                value={examData.examEndDate}
                onChange={(e) => setExamData({ ...examData, examEndDate: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">
                마감 시간 <span className="text-red-500">*</span>
              </label>
              <input
                type="time"
                value={examData.examEndTime}
                onChange={(e) => setExamData({ ...examData, examEndTime: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
          </div>

          {/* 시험 시간 */}
          <div>
            <label className="block text-sm text-gray-700 mb-2">
              시험 시간 (분) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              value={examData.duration}
              onChange={(e) => setExamData({ ...examData, duration: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="예: 90"
              required
            />
          </div>

          {/* 문제 수 */}
          <div>
            <label className="block text-sm text-gray-700 mb-2">
              문제 수 <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              value={examData.questionCount}
              onChange={(e) => setExamData({ ...examData, questionCount: parseInt(e.target.value) || 0 })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="예: 20"
              required
            />
          </div>

          {/* 배점 설정 */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-700 mb-2">총점</label>
              <input
                type="number"
                value={examData.totalScore}
                onChange={(e) => setExamData({ ...examData, totalScore: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">합격 점수</label>
              <input
                type="number"
                value={examData.passingScore}
                onChange={(e) => setExamData({ ...examData, passingScore: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* 추가 옵션 */}
          <div className="space-y-3">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={examData.allowRetake}
                onChange={(e) => setExamData({ ...examData, allowRetake: e.target.checked })}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <span className="text-sm text-gray-700">재시험 허용</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={examData.showResults}
                onChange={(e) => setExamData({ ...examData, showResults: e.target.checked })}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <span className="text-sm text-gray-700">시험 종료 후 결과 공개</span>
            </label>
          </div>

          {/* 버튼 */}
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              취소
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              등록
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
