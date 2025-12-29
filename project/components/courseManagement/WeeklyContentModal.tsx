import React, { useState, useEffect } from 'react';
import { X, Video, FileText, ClipboardList, BookOpen, FolderOpen, Clock, RotateCcw, Eye } from 'lucide-react';
import { ContentLibraryModal } from '../ContentLibraryModal';
import { Exam, getExamList } from '../ExamManagementPage';

export type ContentType = 'video' | 'exam' | 'assignment' | 'document';

export interface WeekContentItem {
  id: string;
  weekNumber: number;
  type: ContentType;
  title: string;
  description?: string;
  duration?: string;
  createdAt: string;
  // 콘텐츠 라이브러리에서 선택한 영상 정보
  mediaKey?: string;
  lessonId?: number;
  originalVideoTitle?: string;
  // 시험 관련 정보
  examId?: string;
  examSettings?: {
    testPeriod: number; // 강의 이후 N일
    points: number;
    allowRetake: boolean;
    retakeScore: number; // 재응시 기준 점수
    retakeCount: number; // 재응시 가능 횟수
    showResults: boolean;
  };
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
  
  // 콘텐츠 라이브러리 모달 상태
  const [showLibrary, setShowLibrary] = useState(false);
  const [selectedVideo, setSelectedVideo] = useState<{
    mediaKey: string;
    lessonId?: number;
    title: string;
    duration?: string;
  } | null>(null);

  // 시험 선택 상태
  const [examList, setExamList] = useState<Exam[]>([]);
  const [selectedExamId, setSelectedExamId] = useState<string>('');
  const [examSettings, setExamSettings] = useState({
    testPeriod: 1,
    points: 0,
    allowRetake: false,
    retakeScore: 0,
    retakeCount: 0,
    showResults: true,
  });

  // 시험 목록 로드
  useEffect(() => {
    if (!isOpen || selectedType !== 'exam') return;
    let cancelled = false;

    const loadExams = async () => {
      try {
        const exams = await getExamList();
        if (!cancelled) setExamList(exams);
      } catch {
        if (!cancelled) setExamList([]);
      }
    };

    void loadExams();
    return () => {
      cancelled = true;
    };
  }, [isOpen, selectedType]);

  // 선택한 시험 정보
  const selectedExam = examList.find(e => e.id === selectedExamId);

  // 시험 선택 시 배점 자동 설정
  useEffect(() => {
    if (selectedExam) {
      setExamSettings(prev => ({
        ...prev,
        points: selectedExam.totalPoints,
      }));
    }
  }, [selectedExam]);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedType) return;
    
    // 동영상
    if (selectedType === 'video') {
      if (!selectedVideo) return;
      onAdd({
        weekNumber,
        type: selectedType,
        title: title.trim() || selectedVideo.title,
        description: description.trim() || undefined,
        duration: selectedVideo.duration,
        mediaKey: selectedVideo.mediaKey,
        lessonId: selectedVideo.lessonId,
        originalVideoTitle: selectedVideo.title,
      });
    }
    // 시험
    else if (selectedType === 'exam') {
      if (!selectedExamId) return;
      onAdd({
        weekNumber,
        type: selectedType,
        title: selectedExam?.title || '시험',
        description: description.trim() || undefined,
        examId: selectedExamId,
        examSettings: {
          testPeriod: examSettings.testPeriod,
          points: examSettings.points,
          allowRetake: examSettings.allowRetake,
          retakeScore: examSettings.retakeScore,
          retakeCount: examSettings.retakeCount,
          showResults: examSettings.showResults,
        },
      });
    }
    // 과제/자료
    else {
      if (!title.trim()) return;
      onAdd({
        weekNumber,
        type: selectedType,
        title: title.trim(),
        description: description.trim() || undefined,
      });
    }

    // 폼 초기화
    resetForm();
    onClose();
  };

  const resetForm = () => {
    setSelectedType(null);
    setTitle('');
    setDescription('');
    setSelectedVideo(null);
    setSelectedExamId('');
    setExamSettings({
      testPeriod: 1,
      points: 0,
      allowRetake: false,
      retakeScore: 0,
      retakeCount: 0,
      showResults: true,
    });
  };

  const handleVideoSelect = (content: any) => {
    setSelectedVideo({
      mediaKey: content.mediaKey,
      lessonId: content.lessonId,
      title: content.title,
      duration: content.duration || (content.totalTime ? `${content.totalTime}분` : undefined),
    });
    setShowLibrary(false);
  };

  const contentTypes = [
    { type: 'video' as ContentType, icon: Video, label: '동영상', color: 'blue', desc: '콘텐츠 라이브러리에서 선택' },
    { type: 'exam' as ContentType, icon: ClipboardList, label: '시험', color: 'red', desc: '시험관리에서 시험을 선택합니다' },
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
    <>
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
                    onClick={() => {
                      setSelectedType(type);
                      setSelectedVideo(null);
                      setSelectedExamId('');
                    }}
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

            {/* Step 2: 상세 정보 입력 */}
            {selectedType && (
              <>
                {/* 동영상 선택 */}
                {selectedType === 'video' && (
                  <>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        선택한 동영상 <span className="text-red-500 ml-1">*</span>
                      </label>
                      {selectedVideo ? (
                        <div className="flex items-center justify-between p-4 bg-blue-50 border border-blue-200 rounded-lg">
                          <div className="flex items-center gap-3">
                            <Video className="w-5 h-5 text-blue-600" />
                            <div>
                              <p className="font-medium text-blue-900">{selectedVideo.title}</p>
                              {selectedVideo.duration && (
                                <p className="text-sm text-blue-600">재생시간: {selectedVideo.duration}</p>
                              )}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => setShowLibrary(true)}
                            className="px-3 py-1.5 text-sm text-blue-600 bg-white border border-blue-300 rounded-lg hover:bg-blue-50 transition-colors"
                          >
                            변경
                          </button>
                        </div>
                      ) : (
                        <button
                          type="button"
                          onClick={() => setShowLibrary(true)}
                          className="w-full flex items-center justify-center gap-2 p-4 border-2 border-dashed border-gray-300 rounded-lg text-gray-500 hover:border-blue-400 hover:text-blue-600 transition-colors"
                        >
                          <FolderOpen className="w-5 h-5" />
                          <span>콘텐츠 라이브러리에서 영상 선택</span>
                        </button>
                      )}
                    </div>
                    
                    {selectedVideo && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          콘텐츠 제목 (선택)
                        </label>
                        <input
                          type="text"
                          value={title}
                          onChange={(e) => setTitle(e.target.value)}
                          placeholder={selectedVideo.title}
                          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                        <p className="text-xs text-gray-400 mt-1">
                          비워두면 동영상 제목이 사용됩니다.
                        </p>
                      </div>
                    )}
                  </>
                )}

                {/* 시험 선택 및 상세 설정 */}
                {selectedType === 'exam' && (
                  <>
                    {/* 시험 선택 */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        시험 선택 <span className="text-red-500 ml-1">*</span>
                      </label>
                      {examList.length > 0 ? (
                        <select
                          value={selectedExamId}
                          onChange={(e) => setSelectedExamId(e.target.value)}
                          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                        >
                          <option value="">시험을 선택하세요</option>
                          {examList.map(exam => (
                            <option key={exam.id} value={exam.id}>
                              {exam.title} ({exam.questionIds.length}문제, {exam.totalPoints}점)
                            </option>
                          ))}
                        </select>
                      ) : (
                        <div className="p-4 bg-gray-50 rounded-lg text-center text-gray-500">
                          <ClipboardList className="w-8 h-8 mx-auto mb-2 opacity-50" />
                          <p className="text-sm">등록된 시험이 없습니다.</p>
                          <p className="text-xs mt-1">시험관리 메뉴에서 먼저 시험을 생성해주세요.</p>
                        </div>
                      )}
                    </div>

                    {/* 시험 상세 설정 (시험 선택 후) */}
                    {selectedExamId && (
                      <div className="space-y-4 pt-4 border-t border-gray-100">
                        {/* 응시기간 */}
                        <div className="flex items-center gap-3">
                          <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">응시기간</label>
                          <div className="flex items-center gap-2">
                            <input
                              type="number"
                              value={examSettings.testPeriod}
                              onChange={(e) => setExamSettings(prev => ({ ...prev, testPeriod: parseInt(e.target.value) || 0 }))}
                              min={0}
                              className="w-16 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-red-500"
                            />
                            <span className="text-sm text-gray-600">강의 이후</span>
                            <span className="text-xs text-gray-400">▶ 강의 전은 0 입력</span>
                          </div>
                        </div>

                        {/* 배점 */}
                        <div className="flex items-center gap-3">
                          <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">배점</label>
                          <div className="flex items-center gap-2">
                            <input
                              type="number"
                              value={examSettings.points}
                              onChange={(e) => setExamSettings(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                              min={0}
                              className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-red-500"
                            />
                            <span className="text-sm text-gray-600">점</span>
                          </div>
                        </div>

                        {/* 재응시 가능여부 */}
                        <div className="flex items-center gap-3">
                          <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능여부</label>
                          <label className="flex items-center gap-2 cursor-pointer">
                            <input
                              type="checkbox"
                              checked={examSettings.allowRetake}
                              onChange={(e) => setExamSettings(prev => ({ ...prev, allowRetake: e.target.checked }))}
                              className="w-4 h-4 text-red-600 border-gray-300 rounded focus:ring-red-500"
                            />
                            <span className="text-sm text-gray-600">재응시 가능</span>
                          </label>
                          <span className="text-xs text-gray-400 flex-1">▶ 재응시를 지정하면 기준점수 미만일 경우 횟수제한 범위안에서 재응시할 수 있습니다.</span>
                        </div>

                        {/* 재응시 기준 점수 */}
                        {examSettings.allowRetake && (
                          <>
                            <div className="flex items-center gap-3">
                              <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">재응시 기준 점수</label>
                              <div className="flex items-center gap-2">
                                <input
                                  type="number"
                                  value={examSettings.retakeScore}
                                  onChange={(e) => setExamSettings(prev => ({ ...prev, retakeScore: parseInt(e.target.value) || 0 }))}
                                  min={0}
                                  max={100}
                                  className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-red-500"
                                />
                                <span className="text-sm text-gray-600">점 미만일때 재응시가 가능합니다.</span>
                                <span className="text-xs text-gray-400">▶ 100점 만점 기준입니다.</span>
                              </div>
                            </div>

                            {/* 재응시 가능 횟수 */}
                            <div className="flex items-center gap-3">
                              <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능 횟수</label>
                              <div className="flex items-center gap-2">
                                <input
                                  type="number"
                                  value={examSettings.retakeCount}
                                  onChange={(e) => setExamSettings(prev => ({ ...prev, retakeCount: parseInt(e.target.value) || 0 }))}
                                  min={0}
                                  className="w-16 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-red-500"
                                />
                                <span className="text-sm text-gray-600">회까지 재응시가 가능합니다.</span>
                              </div>
                            </div>
                          </>
                        )}

                        {/* 시험결과노출 */}
                        <div className="flex items-center gap-3">
                          <label className="w-24 text-sm font-medium text-gray-700 flex-shrink-0">시험결과노출</label>
                          <label className="flex items-center gap-2 cursor-pointer">
                            <input
                              type="checkbox"
                              checked={examSettings.showResults}
                              onChange={(e) => setExamSettings(prev => ({ ...prev, showResults: e.target.checked }))}
                              className="w-4 h-4 text-red-600 border-gray-300 rounded focus:ring-red-500"
                            />
                            <span className="text-sm text-gray-600">노출</span>
                          </label>
                          <span className="text-xs text-gray-400">▶ 응시 후 수강생이 정답을 확인할 수 있습니다.</span>
                        </div>
                      </div>
                    )}
                  </>
                )}

                {/* 과제/학습자료: 제목 입력 */}
                {(selectedType === 'assignment' || selectedType === 'document') && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {selectedType === 'assignment' ? '과제 제목' : '자료 제목'}
                      <span className="text-red-500 ml-1">*</span>
                    </label>
                    <input
                      type="text"
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      placeholder={`${weekNumber}주차 ${selectedType === 'assignment' ? '과제' : '자료'} 제목을 입력하세요`}
                      className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      required
                    />
                  </div>
                )}

                {/* 설명 (공통) */}
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
                disabled={
                  !selectedType || 
                  (selectedType === 'video' && !selectedVideo) ||
                  (selectedType === 'exam' && !selectedExamId) ||
                  ((selectedType === 'assignment' || selectedType === 'document') && !title.trim())
                }
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                추가하기
              </button>
            </div>
          </form>
        </div>
      </div>

      {/* 콘텐츠 라이브러리 모달 */}
      <ContentLibraryModal
        isOpen={showLibrary}
        onClose={() => setShowLibrary(false)}
        onSelect={handleVideoSelect}
        multiSelect={false}
      />
    </>
  );
}
