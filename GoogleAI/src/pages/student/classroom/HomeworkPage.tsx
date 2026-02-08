// pages/student/classroom/HomeworkPage.tsx — 과제 제출 페이지
import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { FileText, Upload, Calendar, Clock, CheckCircle2 } from 'lucide-react';

export default function HomeworkPage() {
  const { courseCode, week } = useParams();
  const [file, setFile] = useState<File | null>(null);
  const [content, setContent] = useState('');

  return (
    <div className="page-container space-y-6">
      {/* Breadcrumb */}
      <nav className="text-xs text-content-muted flex items-center gap-1">
        <Link to={`/classroom/${courseCode}`} className="hover:text-primary">학습실</Link>
        <span>/</span>
        <span className="text-content-default font-medium">{week}주차 과제</span>
      </nav>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main */}
        <div className="lg:col-span-2 space-y-4">
          <div className="card">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-primary-50 flex items-center justify-center">
                <FileText className="w-5 h-5 text-primary" />
              </div>
              <div>
                <h1 className="text-lg font-bold text-gray-900 dark:text-white">자료형 실습 과제</h1>
                <p className="text-xs text-content-muted">제출 기한: 2026-02-28 23:59</p>
              </div>
            </div>

            <div className="bg-surface-muted dark:bg-slate-800 rounded-lg p-4 text-sm text-content-secondary leading-relaxed">
              <p className="font-medium text-gray-800 dark:text-white mb-2">과제 설명</p>
              <p>Python의 기본 자료형(int, float, str, bool, list, dict)을 활용하여 간단한 학생 관리 프로그램을 작성하세요.</p>
              <ul className="list-disc list-inside mt-2 space-y-1 text-xs">
                <li>학생 정보(이름, 학번, 성적)를 딕셔너리로 관리</li>
                <li>평균 성적 계산 함수 구현</li>
                <li>성적순 정렬 기능 구현</li>
              </ul>
            </div>
          </div>

          {/* Submission Form */}
          <div className="card space-y-4">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">과제 제출</h2>

            <div>
              <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">내용 입력</label>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="과제 내용을 입력하세요..."
                rows={6}
                className="input resize-none"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">파일 첨부</label>
              <div className="border-2 border-dashed border-gray-200 dark:border-slate-700 rounded-lg p-6 text-center">
                <Upload className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                <p className="text-xs text-gray-500">파일을 드래그하거나 클릭하여 업로드</p>
                <p className="text-[10px] text-gray-400 mt-1">최대 10MB / .py, .zip, .pdf</p>
                <input type="file" className="hidden" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
              </div>
              {file && (
                <div className="mt-2 flex items-center gap-2 text-xs text-gray-600">
                  <FileText className="w-3 h-3" />
                  <span>{file.name}</span>
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2">
              <button className="btn-secondary">임시 저장</button>
              <button className="btn-primary">
                <CheckCircle2 className="w-4 h-4" /> 제출하기
              </button>
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <aside className="space-y-4">
          <div className="card space-y-3">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300">과제 정보</h3>
            <div className="space-y-2 text-xs text-gray-600 dark:text-slate-400">
              <div className="flex items-center gap-2"><Calendar className="w-3 h-3" /> 출제일: 2026-02-07</div>
              <div className="flex items-center gap-2"><Clock className="w-3 h-3" /> 마감일: 2026-02-28</div>
              <div className="flex items-center gap-2"><FileText className="w-3 h-3" /> 배점: 10점</div>
            </div>
          </div>

          <div className="alert alert-info">
            <div className="text-xs">
              <p className="font-medium">제출 안내</p>
              <p className="mt-0.5">마감일 이후에는 제출이 불가합니다. 지각 제출 시 감점될 수 있습니다.</p>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
