import React, { useState } from 'react';
import { X, CheckCircle, MessageSquare, Clock, User } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface HomeworkTaskDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  courseId: number;
  task: any;
  onRefresh: () => void;
}

export function HomeworkTaskDetailModal({
  isOpen,
  onClose,
  courseId,
  task,
  onRefresh,
}: HomeworkTaskDetailModalProps) {
  const [feedback, setFeedback] = useState(task?.feedback || '');
  const [loading, setLoading] = useState(false);

  if (!isOpen || !task) return null;

  const handleConfirm = async () => {
    setLoading(true);
    try {
      const res = await tutorLmsApi.confirmHomeworkTask({
        courseId,
        taskId: task.id,
        feedback,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      
      alert('평가완료 처리되었습니다.');
      onRefresh();
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : '처리 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-white">
          <div className="flex items-center gap-2">
            <CheckCircle className="w-5 h-5 text-blue-600" />
            <h3 className="text-lg font-semibold text-gray-900">추가 과제 상세 확인</h3>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* 과제 지시 내용 */}
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <MessageSquare className="w-4 h-4" />
              <span>과제 지시 내용</span>
            </div>
            <div className="bg-blue-50 border border-blue-100 rounded-lg p-4 text-gray-800 text-sm whitespace-pre-wrap">
              {task.task}
            </div>
            <div className="flex items-center gap-4 text-xs text-gray-500 mt-1">
              <span className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                부여: {task.reg_date_conv}
              </span>
            </div>
          </div>

          <hr className="border-gray-100" />

          {/* 학생 제출 내용 */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                <User className="w-4 h-4" />
                <span>학생 제출 내용</span>
              </div>
              <span className={`px-2 py-1 text-xs rounded font-medium ${
                task.submit_yn === 'Y' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
              }`}>
                {task.submit_yn_label}
              </span>
            </div>

            {task.submit_yn === 'Y' ? (
              <div className="space-y-4">
                <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                  {task.subject && (
                    <div className="font-semibold text-gray-900 mb-2 border-b border-gray-200 pb-2">
                      {task.subject}
                    </div>
                  )}
                  <div className="text-gray-800 text-sm whitespace-pre-wrap min-h-[100px]">
                    {task.content || '내용 없음'}
                  </div>
                </div>
                <div className="text-xs text-gray-500">
                  제출: {task.submit_date_conv}
                </div>
              </div>
            ) : (
              <div className="py-10 text-center text-gray-400 border border-dashed border-gray-200 rounded-lg">
                아직 제출된 내용이 없습니다.
              </div>
            )}
          </div>

          <hr className="border-gray-100" />

          {/* 피드백 입력 및 상태 변경 */}
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <CheckCircle className="w-4 h-4" />
              <span>교수자 피드백 및 평가</span>
            </div>
            <textarea
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="추가 과제에 대한 피드백을 입력하세요..."
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm resize-none min-h-[120px]"
            />
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end gap-3 font-semibold">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
          >
            닫기
          </button>
          {task.submit_yn === 'Y' && (
            <button
              onClick={handleConfirm}
              disabled={loading}
              className="px-6 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400 flex items-center gap-2"
            >
              {loading ? (
                <span>처리 중...</span>
              ) : (
                <>
                  <CheckCircle className="w-4 h-4" />
                  <span>평가완료(확인)</span>
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
