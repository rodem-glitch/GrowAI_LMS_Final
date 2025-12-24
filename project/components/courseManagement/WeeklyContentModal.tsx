import React, { useState } from 'react';
import { X, Video, FileText, ClipboardList, BookOpen } from 'lucide-react';

export type ContentType = 'video' | 'exam' | 'assignment' | 'document';

export interface WeekContentItem {
  id: string;
  weekNumber: number;
  type: ContentType;
  title: string;
  description?: string;
  duration?: string;
  createdAt: string;
}

interface WeeklyContentModalProps {
  isOpen: boolean;
  onClose: () => void;
  weekNumber: number;
  onAdd: (content: Omit<WeekContentItem, 'id' | 'createdAt'>) => void;
}

export function WeeklyContentModal({ isOpen, onClose, weekNumber, onAdd }: WeeklyContentModalProps) {
  const [selectedType, setSelectedType] = useState<ContentType | null>(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [duration, setDuration] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedType || !title.trim()) return;

    onAdd({
      weekNumber,
      type: selectedType,
      title: title.trim(),
      description: description.trim() || undefined,
      duration: selectedType === 'video' ? duration.trim() || undefined : undefined,
    });

    // 폼 초기화
    setSelectedType(null);
    setTitle('');
    setDescription('');
    setDuration('');
    onClose();
  };

  const contentTypes = [
    { type: 'video' as ContentType, icon: Video, label: '동영상', color: 'blue', desc: '강의 동영상을 추가합니다' },
    { type: 'exam' as ContentType, icon: ClipboardList, label: '시험', color: 'red', desc: '해당 주차에 시험을 등록합니다' },
    { type: 'assignment' as ContentType, icon: BookOpen, label: '과제', color: 'purple', desc: '해당 주차에 과제를 등록합니다' },
    { type: 'document' as ContentType, icon: FileText, label: '학습자료', color: 'green', desc: 'PDF, 문서 등 학습자료를 추가합니다' },
  ];

  const getColorClasses = (color: string, isSelected: boolean) => {
    if (isSelected) {
      switch (color) {
        case 'blue': return 'border-blue-500 bg-blue-50 text-blue-700';
        case 'red': return 'border-red-500 bg-red-50 text-red-700';
        case 'purple': return 'border-purple-500 bg-purple-50 text-purple-700';
        case 'green': return 'border-green-500 bg-green-50 text-green-700';
        default: return 'border-gray-500 bg-gray-50 text-gray-700';
      }
    }
    return 'border-gray-200 hover:border-gray-300 hover:bg-gray-50';
  };

  const getIconColorClass = (color: string) => {
    switch (color) {
      case 'blue': return 'text-blue-600';
      case 'red': return 'text-red-600';
      case 'purple': return 'text-purple-600';
      case 'green': return 'text-green-600';
      default: return 'text-gray-600';
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />

      {/* Modal */}
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">{weekNumber}주차 콘텐츠 추가</h2>
            <p className="text-sm text-gray-500 mt-0.5">추가할 콘텐츠 유형을 선택해 주세요</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Step 1: 콘텐츠 유형 선택 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">콘텐츠 유형</label>
            <div className="grid grid-cols-2 gap-3">
              {contentTypes.map(({ type, icon: Icon, label, color, desc }) => (
                <button
                  key={type}
                  type="button"
                  onClick={() => setSelectedType(type)}
                  className={`flex flex-col items-start p-4 border-2 rounded-lg transition-all ${getColorClasses(color, selectedType === type)}`}
                >
                  <Icon className={`w-6 h-6 mb-2 ${selectedType === type ? '' : getIconColorClass(color)}`} />
                  <span className="font-medium">{label}</span>
                  <span className={`text-xs mt-1 ${selectedType === type ? 'opacity-80' : 'text-gray-500'}`}>
                    {desc}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Step 2: 상세 정보 입력 (유형 선택 후) */}
          {selectedType && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {selectedType === 'video' ? '동영상 제목' :
                   selectedType === 'exam' ? '시험 제목' :
                   selectedType === 'assignment' ? '과제 제목' : '자료 제목'}
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder={`${weekNumber}주차 ${selectedType === 'video' ? '강의' : selectedType === 'exam' ? '시험' : selectedType === 'assignment' ? '과제' : '자료'} 제목을 입력하세요`}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                />
              </div>

              {selectedType === 'video' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">재생 시간</label>
                  <input
                    type="text"
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    placeholder="예: 25:30"
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">설명 (선택)</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="콘텐츠에 대한 간단한 설명을 입력하세요"
                  rows={3}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                />
              </div>
            </>
          )}

          {/* Footer */}
          <div className="flex justify-end gap-3 pt-4 border-t border-gray-100">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
            >
              취소
            </button>
            <button
              type="submit"
              disabled={!selectedType || !title.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              추가하기
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
