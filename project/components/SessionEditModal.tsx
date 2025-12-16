import React, { useState } from 'react';
import { X, Plus } from 'lucide-react';
import { ContentLibraryModal } from './ContentLibraryModal';

interface Video {
  id: string;
  title: string;
  url: string;
}

interface Session {
  id: number;
  title: string;
  description: string;
  videos: Video[];
}

interface SessionEditModalProps {
  isOpen: boolean;
  onClose: () => void;
  session: Session;
  onSave: (updatedSession: Session) => void;
}

export function SessionEditModal({
  isOpen,
  onClose,
  session,
  onSave,
}: SessionEditModalProps) {
  const [editedSession, setEditedSession] = useState<Session>(session);
  const [isContentModalOpen, setIsContentModalOpen] = useState(false);

  if (!isOpen) return null;

  const updateSessionField = (field: 'title' | 'description', value: string) => {
    setEditedSession((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const addVideo = () => {
    const newVideo: Video = {
      id: `video-${Date.now()}-${Math.random()}`,
      title: '',
      url: '',
    };
    setEditedSession((prev) => ({
      ...prev,
      videos: [...prev.videos, newVideo],
    }));
  };

  const updateVideo = (videoId: string, field: 'title' | 'url', value: string) => {
    setEditedSession((prev) => ({
      ...prev,
      videos: prev.videos.map((video) =>
        video.id === videoId ? { ...video, [field]: value } : video
      ),
    }));
  };

  const removeVideo = (videoId: string) => {
    setEditedSession((prev) => ({
      ...prev,
      videos: prev.videos.filter((video) => video.id !== videoId),
    }));
  };

  const handleContentSelect = (content: any) => {
    const newVideo: Video = {
      id: `video-${Date.now()}-${Math.random()}`,
      title: content.title,
      url: content.url || content.id,
    };
    setEditedSession((prev) => ({
      ...prev,
      videos: [...prev.videos, newVideo],
    }));
    setIsContentModalOpen(false);
  };

  const handleSave = () => {
    onSave(editedSession);
    onClose();
  };

  return (
    <>
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto m-4">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-gray-200 sticky top-0 bg-white z-10">
            <h3 className="text-gray-900">차시별 구성</h3>
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Content */}
          <div className="p-6 space-y-6">
            {/* 차시 번호 */}
            <div className="flex items-center gap-2 pb-4 border-b border-gray-200">
              <span className="text-blue-700">{editedSession.id}차시</span>
            </div>

            {/* 차시 제목 */}
            <div>
              <label className="block text-sm text-gray-700 mb-2">차시 제목</label>
              <input
                type="text"
                value={editedSession.title}
                onChange={(e) => updateSessionField('title', e.target.value)}
                placeholder="예: Python 기초 문법"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 차시 설명 */}
            <div>
              <label className="block text-sm text-gray-700 mb-2">차시 설명</label>
              <textarea
                value={editedSession.description}
                onChange={(e) => updateSessionField('description', e.target.value)}
                placeholder="이 차시에서 학습할 내용을 설명하세요"
                rows={4}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 강의 영상 */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <label className="block text-sm text-gray-700">
                  강의 영상 ({editedSession.videos.length})
                </label>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setIsContentModalOpen(true)}
                    className="px-3 py-1.5 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                  >
                    콘텐츠 검색
                  </button>
                  <button
                    type="button"
                    onClick={addVideo}
                    className="flex items-center gap-1 px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    영상 추가
                  </button>
                </div>
              </div>

              {/* 영상 목록 */}
              {editedSession.videos.length > 0 ? (
                <div className="space-y-3">
                  {editedSession.videos.map((video, index) => (
                    <div
                      key={video.id}
                      className="bg-gray-50 border border-gray-200 rounded-lg p-4"
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-700 rounded-lg text-sm shrink-0">
                          {index + 1}
                        </div>
                        <div className="flex-1 space-y-3">
                          <div>
                            <label className="block text-xs text-gray-600 mb-1">
                              영상 제목
                            </label>
                            <input
                              type="text"
                              value={video.title}
                              onChange={(e) =>
                                updateVideo(video.id, 'title', e.target.value)
                              }
                              placeholder="영상 제목을 입력하세요"
                              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                          </div>
                          <div>
                            <label className="block text-xs text-gray-600 mb-1">
                              키 또는 URL
                            </label>
                            <input
                              type="text"
                              value={video.url}
                              onChange={(e) =>
                                updateVideo(video.id, 'url', e.target.value)
                              }
                              placeholder="youtube.com 또는 키 입력"
                              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => removeVideo(video.id)}
                          className="p-2 text-gray-400 hover:text-red-600 transition-colors shrink-0"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
                  <p className="text-sm text-gray-500">영상을 추가해주세요</p>
                </div>
              )}
            </div>
          </div>

          {/* Footer */}
          <div className="flex justify-end gap-3 p-6 border-t border-gray-200 bg-gray-50 sticky bottom-0">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
            >
              취소
            </button>
            <button
              onClick={handleSave}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              저장
            </button>
          </div>
        </div>
      </div>

      {/* Content Library Modal */}
      <ContentLibraryModal
        isOpen={isContentModalOpen}
        onClose={() => setIsContentModalOpen(false)}
        onSelect={handleContentSelect}
      />
    </>
  );
}
