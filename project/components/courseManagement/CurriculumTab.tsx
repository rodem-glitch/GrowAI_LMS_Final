import React from 'react';
import { CurriculumEditor } from '../CurriculumEditor';

export function CurriculumTab({ courseId }: { courseId: number }) {
  if (!courseId || Number.isNaN(courseId)) {
    return <div className="text-sm text-red-600">과목 ID가 올바르지 않습니다.</div>;
  }

  return (
    <CurriculumEditor
      courseId={courseId}
      embedded={true}
    />
  );
}
