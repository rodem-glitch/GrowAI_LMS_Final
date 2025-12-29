import type { HaksaCourseKey } from '../api/tutorLmsApi';

type HaksaCourseLike = {
  haksaCourseCode?: string;
  haksaOpenYear?: string;
  haksaOpenTerm?: string;
  haksaBunbanCode?: string;
  haksaGroupCode?: string;
};

export function buildHaksaCourseKey(course?: HaksaCourseLike): HaksaCourseKey | null {
  if (!course) return null;
  const courseCode = (course.haksaCourseCode || '').trim();
  const openYear = (course.haksaOpenYear || '').trim();
  const openTerm = (course.haksaOpenTerm || '').trim();
  const bunbanCode = (course.haksaBunbanCode || '').trim();
  const groupCode = (course.haksaGroupCode || '').trim();

  if (!courseCode || !openYear || !openTerm || !bunbanCode || !groupCode) return null;
  return { courseCode, openYear, openTerm, bunbanCode, groupCode };
}
