import React from 'react';
import { CurriculumEditor } from '../CurriculumEditor';
import { Info } from 'lucide-react';

export function CurriculumTab({ courseId }: { courseId: number }) {
  // 왜: 학사 과목은 courseId가 NaN 또는 0이므로, 빈 상태로 시작하여 교수자가 직접 추가할 수 있도록 합니다.
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0;

  if (isHaksaCourse) {
    return (
      <div className="space-y-4">
        <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm flex items-start gap-2">
          <Info className="w-5 h-5 flex-shrink-0 mt-0.5" />
          <div>
            <strong>학사 연동 과목</strong>: 이 과목은 학사 시스템(e-poly)에서 연동되었습니다. 
            강의목차(차시)를 직접 등록하여 사용할 수 있습니다.
          </div>
        </div>
        <div className="text-center text-gray-500 py-12 border border-dashed border-gray-300 rounded-lg">
          <p className="mb-2">등록된 강의목차가 없습니다.</p>
          <p className="text-sm text-gray-400">학사 연동 과목의 강의목차 직접 등록 기능은 추후 지원 예정입니다.</p>
        </div>
      </div>
    );
  }

  return (
    <CurriculumEditor
      courseId={courseId}
      embedded={true}
    />
  );
}
