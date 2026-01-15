import React, { useState, useRef, useCallback } from 'react';
import { X, Upload, Film, AlertCircle, CheckCircle, Loader2 } from 'lucide-react';
import { tutorLmsApi } from '../api/tutorLmsApi';

// 왜 필요한가:
// - 교수자가 콘텐츠 라이브러리에서 직접 Kollus에 동영상을 업로드할 수 있게 합니다.
// - 기존에는 Kollus 관리자 사이트에 접속해야 했지만, LMS 내에서 바로 업로드 가능해집니다.

interface KollusUploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  onUploadComplete?: () => void;
  categories?: { key: string; name: string }[];
}

type UploadStatus = 'idle' | 'getting-url' | 'uploading' | 'success' | 'error';

export function KollusUploadModal({
  isOpen,
  onClose,
  onUploadComplete,
  categories = [],
}: KollusUploadModalProps) {
  const [title, setTitle] = useState('');
  const [categoryKey, setCategoryKey] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = useState<UploadStatus>('idle');
  const [progress, setProgress] = useState(0);
  const [errorMessage, setErrorMessage] = useState('');
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const xhrRef = useRef<XMLHttpRequest | null>(null);

  // 파일 선택 핸들러
  const handleFileSelect = useCallback((selectedFile: File | undefined) => {
    if (!selectedFile) return;
    
    // 왜: 동영상 파일만 허용합니다.
    const allowedTypes = ['video/mp4', 'video/webm', 'video/avi', 'video/mov', 'video/quicktime', 'video/x-msvideo'];
    if (!allowedTypes.includes(selectedFile.type) && !selectedFile.name.match(/\.(mp4|webm|avi|mov|mkv|wmv)$/i)) {
      setErrorMessage('동영상 파일만 업로드할 수 있습니다. (mp4, webm, avi, mov 등)');
      return;
    }

    setFile(selectedFile);
    setErrorMessage('');
    // 왜: 파일명에서 확장자를 제거하고 기본 제목으로 설정합니다.
    if (!title) {
      const baseName = selectedFile.name.replace(/\.[^.]+$/, '');
      setTitle(baseName);
    }
  }, [title]);

  // 드래그 앤 드롭 핸들러
  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const droppedFile = e.dataTransfer.files[0];
    handleFileSelect(droppedFile);
  }, [handleFileSelect]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  // 업로드 실행
  const handleUpload = async () => {
    if (!file) {
      setErrorMessage('파일을 선택해 주세요.');
      return;
    }
    if (!title.trim()) {
      setErrorMessage('제목을 입력해 주세요.');
      return;
    }

    setUploadStatus('getting-url');
    setProgress(0);
    setErrorMessage('');

    try {
      // 1. 서버에서 Kollus 업로드 URL 획득
      const urlRes = await tutorLmsApi.getKollusUploadUrl({
        title: title.trim(),
        categoryKey: categoryKey || undefined,
        expireTime: 3600, // 1시간
      });

      // 왜: JSP에서 DataSet을 반환하므로 rst_data가 배열 형태로 옵니다.
      // 첫 번째 요소에서 upload_url을 추출합니다.
      const rstData = urlRes.rst_data;
      let uploadUrl = '';
      
      if (Array.isArray(rstData) && rstData.length > 0) {
        // DataSet이 배열로 직렬화된 경우
        uploadUrl = rstData[0]?.upload_url || '';
      } else if (rstData && typeof rstData === 'object') {
        // 객체로 온 경우 (단일 객체)
        uploadUrl = (rstData as { upload_url?: string }).upload_url || '';
      }

      if (urlRes.rst_code !== '0000' || !uploadUrl) {
        throw new Error(urlRes.rst_message || '업로드 URL 생성 실패');
      }

      // 2. Kollus 업로드 URL로 파일 직접 업로드
      setUploadStatus('uploading');

      await new Promise<void>((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhrRef.current = xhr;

        xhr.upload.addEventListener('progress', (e) => {
          if (e.lengthComputable) {
            const pct = Math.round((e.loaded / e.total) * 100);
            setProgress(pct);
          }
        });

        xhr.addEventListener('load', () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve();
          } else {
            reject(new Error(`업로드 실패 (${xhr.status})`));
          }
        });

        xhr.addEventListener('error', () => {
          reject(new Error('네트워크 오류가 발생했습니다.'));
        });

        xhr.addEventListener('abort', () => {
          reject(new Error('업로드가 취소되었습니다.'));
        });

        // 왜: Kollus 업로드 API는 multipart/form-data 형식으로 파일을 받습니다.
        const formData = new FormData();
        formData.append('upload-file', file);

        xhr.open('POST', uploadUrl, true);
        xhr.send(formData);
      });

      // 업로드 성공
      setUploadStatus('success');
      setProgress(100);

      // 3초 후 모달 닫기 및 콜백 호출
      setTimeout(() => {
        handleClose();
        onUploadComplete?.();
      }, 2000);

    } catch (err) {
      setUploadStatus('error');
      setErrorMessage(err instanceof Error ? err.message : '업로드 중 오류가 발생했습니다.');
    }
  };

  // 업로드 취소
  const handleCancel = () => {
    if (xhrRef.current) {
      xhrRef.current.abort();
      xhrRef.current = null;
    }
    setUploadStatus('idle');
    setProgress(0);
  };

  // 모달 닫기
  const handleClose = () => {
    if (uploadStatus === 'uploading') {
      if (!window.confirm('업로드 중입니다. 정말 취소하시겠습니까?')) {
        return;
      }
      handleCancel();
    }
    // 상태 초기화
    setTitle('');
    setCategoryKey('');
    setFile(null);
    setUploadStatus('idle');
    setProgress(0);
    setErrorMessage('');
    onClose();
  };

  // 파일 크기 포맷팅
  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
  };

  if (!isOpen) return null;

  const isUploading = uploadStatus === 'getting-url' || uploadStatus === 'uploading';

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4">
        {/* 헤더 */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <Film className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-900">동영상 업로드</h2>
              <p className="text-sm text-gray-500">Kollus VOD에 동영상을 업로드합니다</p>
            </div>
          </div>
          <button
            onClick={handleClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* 본문 */}
        <div className="p-6 space-y-5">
          {/* 제목 입력 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              영상 제목 <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="영상 제목을 입력하세요"
              disabled={isUploading}
              className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
            />
          </div>

          {/* 카테고리 선택 */}
          {categories.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                카테고리 (선택)
              </label>
              <select
                value={categoryKey}
                onChange={(e) => setCategoryKey(e.target.value)}
                disabled={isUploading}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              >
                <option value="">선택 안함</option>
                {categories.map((cat) => (
                  <option key={cat.key} value={cat.key}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* 파일 업로드 영역 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              동영상 파일 <span className="text-red-500">*</span>
            </label>
            
            {!file ? (
              <div
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                onClick={() => fileInputRef.current?.click()}
                className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center cursor-pointer hover:border-blue-400 hover:bg-blue-50 transition-colors"
              >
                <Upload className="w-10 h-10 text-gray-400 mx-auto mb-3" />
                <p className="text-gray-600 mb-1">파일을 드래그하거나 클릭하여 선택</p>
                <p className="text-sm text-gray-400">MP4, WebM, AVI, MOV 등 지원</p>
              </div>
            ) : (
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 flex items-center gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Film className="w-6 h-6 text-blue-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">{file.name}</p>
                  <p className="text-sm text-gray-500">{formatFileSize(file.size)}</p>
                </div>
                {!isUploading && (
                  <button
                    onClick={() => setFile(null)}
                    className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>
            )}
            
            <input
              ref={fileInputRef}
              type="file"
              accept="video/*"
              onChange={(e) => handleFileSelect(e.target.files?.[0])}
              className="hidden"
            />
          </div>

          {/* 업로드 진행 상태 */}
          {isUploading && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-center gap-3 mb-3">
                <Loader2 className="w-5 h-5 text-blue-600 animate-spin" />
                <span className="text-sm font-medium text-blue-800">
                  {uploadStatus === 'getting-url' ? '업로드 준비 중...' : `업로드 중... ${progress}%`}
                </span>
              </div>
              <div className="w-full bg-blue-200 rounded-full h-2">
                <div
                  className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${uploadStatus === 'getting-url' ? 5 : progress}%` }}
                />
              </div>
            </div>
          )}

          {/* 성공 메시지 */}
          {uploadStatus === 'success' && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-3">
              <CheckCircle className="w-5 h-5 text-green-600" />
              <span className="text-sm font-medium text-green-800">
                업로드가 완료되었습니다! 잠시 후 목록이 새로고침됩니다.
              </span>
            </div>
          )}

          {/* 에러 메시지 */}
          {errorMessage && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
              <span className="text-sm text-red-800">{errorMessage}</span>
            </div>
          )}
        </div>

        {/* 푸터 */}
        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50 rounded-b-xl">
          {isUploading ? (
            <button
              onClick={handleCancel}
              className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              취소
            </button>
          ) : uploadStatus === 'success' ? (
            <button
              onClick={handleClose}
              className="px-4 py-2 text-white bg-green-600 rounded-lg hover:bg-green-700 transition-colors"
            >
              닫기
            </button>
          ) : (
            <>
              <button
                onClick={handleClose}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleUpload}
                disabled={!file || !title.trim()}
                className="px-6 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
              >
                <Upload className="w-4 h-4" />
                업로드
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
