import React, { useEffect, useMemo, useState } from 'react';
import { ChevronRight, Info, Loader2, Search } from 'lucide-react';
import {
  tutorLmsApi,
  TutorProgressDetailRow,
  TutorProgressStudentRow,
  TutorProgressSummaryRow,
} from '../../api/tutorLmsApi';
import { buildHaksaCourseKey } from '../../utils/haksa';

type AttendanceCourse = {
  sourceType?: 'haksa' | 'prism';
  mappedCourseId?: number;
  haksaCourseCode?: string;
  haksaOpenYear?: string;
  haksaOpenTerm?: string;
  haksaBunbanCode?: string;
  haksaGroupCode?: string;
};

type HaksaCurriculumContent = {
  type?: string;
  title?: string;
  lessonId?: number;
  originalVideoTitle?: string;
};

type HaksaCurriculumSession = {
  sessionId?: string;
  sessionName?: string;
  contents?: HaksaCurriculumContent[];
};

type HaksaCurriculumWeek = {
  weekNumber?: number;
  title?: string;
  sessions?: HaksaCurriculumSession[];
};

type HaksaSessionItem = {
  sessionId: string;
  sessionName: string;
  weekNumber: number;
  weekTitle: string;
  videoLessons: { lessonId: number; title: string }[];
  videoCount: number;
};

function ProgressDetailModal({
  isOpen,
  onClose,
  detail,
}: {
  isOpen: boolean;
  onClose: () => void;
  detail: TutorProgressDetailRow | null;
}) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-xl overflow-hidden">
        <div className="flex items-center justify-between p-5 border-b border-gray-200">
          <h3 className="text-gray-900">진도 상세</h3>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700 transition-colors">
            닫기
          </button>
        </div>
        <div className="p-5 space-y-3">
          {!detail ? (
            <div className="text-sm text-gray-600">불러오는 중...</div>
          ) : (
            <>
              <div className="text-sm text-gray-700">
                <span className="text-gray-900">{detail.name || '-'}</span> ({detail.student_id || '-'})
              </div>
              <div className="text-sm text-gray-700">
                차시: {detail.chapter ? `${detail.chapter}차시` : '-'} · {detail.lesson_nm || '-'}
              </div>
              <div className="text-sm text-gray-700">진도율: {Math.round(Number(detail.ratio ?? 0))}%</div>
              <div className="text-sm text-gray-700">학습시간: {detail.study_time_conv || '-'}</div>
              <div className="text-sm text-gray-700">마지막 학습: {detail.last_date_conv || '-'}</div>
              <div className="text-sm text-gray-700">완료여부: {detail.complete_yn === 'Y' ? '완료' : '미완료'}</div>
              <div className="text-sm text-gray-700">완료일시: {detail.complete_date_conv || '-'}</div>
              <div className="text-sm text-gray-700">
                보기횟수: {Number(detail.view_cnt ?? 0)}회
              </div>
            </>
          )}
        </div>
        <div className="flex justify-end p-5 border-t border-gray-200 bg-gray-50">
          <button
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
          >
            확인
          </button>
        </div>
      </div>
    </div>
  );
}

export function AttendanceTab({ courseId, course }: { courseId: number; course?: AttendanceCourse }) {
  // 왜: 학사/프리즘 구분은 courseId가 아니라 소스 타입으로 해야 화면/동작이 정확합니다.
  const isHaksaCourse = course?.sourceType === 'haksa';
  const baseCourseId = isHaksaCourse ? Number(course?.mappedCourseId ?? 0) : courseId;
  const [resolvedCourseId, setResolvedCourseId] = useState<number | null>(null);
  const effectiveCourseId = resolvedCourseId && resolvedCourseId > 0 ? resolvedCourseId : baseCourseId;

  const haksaKey = useMemo(
    () =>
      buildHaksaCourseKey({
        haksaCourseCode: course?.haksaCourseCode,
        haksaOpenYear: course?.haksaOpenYear,
        haksaOpenTerm: course?.haksaOpenTerm,
        haksaBunbanCode: course?.haksaBunbanCode,
        haksaGroupCode: course?.haksaGroupCode,
      }),
    [
      course?.haksaCourseCode,
      course?.haksaOpenYear,
      course?.haksaOpenTerm,
      course?.haksaBunbanCode,
      course?.haksaGroupCode,
    ]
  );

  const [haksaWeeks, setHaksaWeeks] = useState<HaksaCurriculumWeek[]>([]);
  const [haksaLoading, setHaksaLoading] = useState(false);
  const [haksaError, setHaksaError] = useState<string | null>(null);
  const [resolvingCourseId, setResolvingCourseId] = useState(false);

  const [summaryRows, setSummaryRows] = useState<TutorProgressSummaryRow[]>([]);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryError, setSummaryError] = useState<string | null>(null);

  const [selectedLessonId, setSelectedLessonId] = useState<number | null>(null);
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);

  const [studentRows, setStudentRows] = useState<TutorProgressStudentRow[]>([]);
  const [studentLoading, setStudentLoading] = useState(false);
  const [studentError, setStudentError] = useState<string | null>(null);

  const [studentKeyword, setStudentKeyword] = useState('');

  const [detailOpen, setDetailOpen] = useState(false);
  const [detail, setDetail] = useState<TutorProgressDetailRow | null>(null);

  useEffect(() => {
    // 왜: 과목이 바뀌면 이전 선택/검색 결과가 남아 잘못된 조회가 될 수 있습니다.
    setSelectedLessonId(null);
    setSelectedSessionId(null);
    setStudentRows([]);
    setStudentKeyword('');
  }, [courseId, course?.mappedCourseId, course?.sourceType]);

  useEffect(() => {
    if (!isHaksaCourse) {
      setResolvedCourseId(null);
      return;
    }

    if (baseCourseId > 0) {
      setResolvedCourseId(null);
      return;
    }

    if (!haksaKey) {
      setHaksaError('학사 과목 키가 비어 있어 과정 매핑을 진행할 수 없습니다.');
      return;
    }

    let cancelled = false;
    const resolveCourseId = async () => {
      setResolvingCourseId(true);
      setHaksaError(null);
      try {
        const res = await tutorLmsApi.resolveHaksaCourse(haksaKey);
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const payload = Array.isArray(res.rst_data) ? res.rst_data[0] : res.rst_data;
        const mapped = Number(payload?.mapped_course_id ?? 0);
        if (!mapped || Number.isNaN(mapped)) throw new Error('매핑된 과정ID를 찾지 못했습니다.');

        if (!cancelled) setResolvedCourseId(mapped);
      } catch (e) {
        if (!cancelled) {
          setResolvedCourseId(null);
          setHaksaError(e instanceof Error ? e.message : '과정 매핑 중 오류가 발생했습니다.');
        }
      } finally {
        if (!cancelled) setResolvingCourseId(false);
      }
    };

    void resolveCourseId();
    return () => {
      cancelled = true;
    };
  }, [isHaksaCourse, baseCourseId, haksaKey]);

  useEffect(() => {
    // 왜: 학사 과목은 주차/차시 구조를 읽어와야 진도 화면을 구성할 수 있습니다.
    if (!isHaksaCourse || !haksaKey) {
      setHaksaWeeks([]);
      return;
    }

    let cancelled = false;
    const run = async () => {
      setHaksaLoading(true);
      setHaksaError(null);
      try {
        const res = await tutorLmsApi.getHaksaCurriculum(haksaKey);
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        const payload = Array.isArray(res.rst_data) ? res.rst_data[0] : res.rst_data;
        const raw = payload?.curriculum_json || '';
        const parsed = raw ? JSON.parse(raw) : [];
        if (!cancelled) setHaksaWeeks(Array.isArray(parsed) ? parsed : []);
      } catch (e) {
        if (!cancelled) {
          setHaksaWeeks([]);
          setHaksaError(e instanceof Error ? e.message : '강의목차를 불러오는 중 오류가 발생했습니다.');
        }
      } finally {
        if (!cancelled) setHaksaLoading(false);
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [isHaksaCourse, haksaKey]);

  useEffect(() => {
    if (!effectiveCourseId) return;
    let cancelled = false;

    const run = async () => {
      setSummaryLoading(true);
      setSummaryError(null);
      try {
        const res = await tutorLmsApi.getProgressSummary({ courseId: effectiveCourseId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        const rows = res.rst_data ?? [];
        if (cancelled) return;
        setSummaryRows(rows);
        if (!isHaksaCourse && !selectedLessonId && rows.length > 0) {
          setSelectedLessonId(Number(rows[0].lesson_id));
        }
      } catch (e) {
        if (!cancelled) setSummaryError(e instanceof Error ? e.message : '진도 요약을 불러오는 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setSummaryLoading(false);
      }
    };

    run();
    return () => {
      cancelled = true;
    };
  }, [effectiveCourseId, isHaksaCourse]);

  const summaryMap = useMemo(() => {
    const map = new Map<number, TutorProgressSummaryRow>();
    summaryRows.forEach((row) => {
      map.set(Number(row.lesson_id), row);
    });
    return map;
  }, [summaryRows]);

  const haksaWeekGroups = useMemo(() => {
    if (!isHaksaCourse) return [] as { weekNumber: number; weekTitle: string; sessions: HaksaSessionItem[] }[];

    const sortedWeeks = [...haksaWeeks].sort((a, b) => {
      const aNo = Number(a.weekNumber ?? 0);
      const bNo = Number(b.weekNumber ?? 0);
      return aNo - bNo;
    });

    return sortedWeeks.map((week, weekIdx) => {
      const weekNumberRaw = Number(week.weekNumber ?? 0);
      const weekNumber = Number.isFinite(weekNumberRaw) && weekNumberRaw > 0 ? weekNumberRaw : weekIdx + 1;
      const weekTitle = week.title || `${weekNumber}주차`;
      const rawSessions = Array.isArray(week.sessions) ? week.sessions : [];

      const sessions = rawSessions.map((session, sessionIdx) => {
        const contents = Array.isArray(session.contents) ? session.contents : [];
        const videoContents = contents.filter((content) => String(content.type || '').toLowerCase() === 'video');
        const videoLessons = videoContents
          .map((content) => ({
            lessonId: Number(content.lessonId ?? 0),
            title: content.title || content.originalVideoTitle || '동영상',
          }))
          .filter((lesson) => lesson.lessonId > 0);

        return {
          sessionId: String(session.sessionId || `${weekNumber}-${sessionIdx + 1}`),
          sessionName: session.sessionName || `${sessionIdx + 1}차시`,
          weekNumber,
          weekTitle,
          videoLessons,
          videoCount: videoContents.length,
        } as HaksaSessionItem;
      });

      return { weekNumber, weekTitle, sessions };
    });
  }, [haksaWeeks, isHaksaCourse]);

  const haksaSessionsFlat = useMemo(
    () => haksaWeekGroups.flatMap((week) => week.sessions),
    [haksaWeekGroups]
  );

  useEffect(() => {
    // 왜: 학사 진도는 "차시 선택"이 먼저 필요하므로 기본 차시를 자동 선택합니다.
    if (!isHaksaCourse) return;

    // 왜: 사용자가 "전체 정보 보기"를 눌렀다면 자동 선택 로직이 덮어쓰지 않도록 그대로 둡니다.
    if (selectedSessionId === 'overall') return;

    if (haksaSessionsFlat.length === 0) {
      setSelectedSessionId(null);
      setSelectedLessonId(null);
      return;
    }

    const stillExists = selectedSessionId && haksaSessionsFlat.some((s) => s.sessionId === selectedSessionId);
    if (stillExists) return;

    const firstWithVideo = haksaSessionsFlat.find((s) => s.videoLessons.length > 0);
    const fallback = haksaSessionsFlat[0];
    setSelectedSessionId((firstWithVideo ?? fallback).sessionId);
  }, [isHaksaCourse, haksaSessionsFlat, selectedSessionId]);

  useEffect(() => {
    if (!isHaksaCourse) return;
    // 왜: 전체 보기 모드에서는 selectedLessonId를 -1로 유지해야 API가 전체 진도를 조회합니다.
    if (selectedSessionId === 'overall') {
      setSelectedLessonId(-1);
      return;
    }
    const session = haksaSessionsFlat.find((s) => s.sessionId === selectedSessionId);
    const nextLessonId = session?.videoLessons[0]?.lessonId ?? null;
    setSelectedLessonId(nextLessonId);
  }, [isHaksaCourse, selectedSessionId, haksaSessionsFlat]);

  const selectedSummary = useMemo(
    () => summaryRows.find((r) => Number(r.lesson_id) === Number(selectedLessonId)),
    [summaryRows, selectedLessonId]
  );

  const selectedHaksaSession = useMemo(
    () => haksaSessionsFlat.find((s) => s.sessionId === selectedSessionId) ?? null,
    [haksaSessionsFlat, selectedSessionId]
  );

  const selectedHaksaVideo = useMemo(() => {
    if (!selectedHaksaSession || !selectedLessonId) return null;
    return selectedHaksaSession.videoLessons.find((video) => video.lessonId === selectedLessonId) ?? null;
  }, [selectedHaksaSession, selectedLessonId]);

  const buildSessionSummary = (session: HaksaSessionItem) => {
    if (session.videoLessons.length === 0) return null;
    const rows = session.videoLessons
      .map((video) => summaryMap.get(video.lessonId))
      .filter((row): row is TutorProgressSummaryRow => !!row);
    if (rows.length === 0) return null;
    const completeRate = rows.reduce((sum, row) => sum + Number(row.complete_rate ?? 0), 0) / rows.length;
    const avgRatio = rows.reduce((sum, row) => sum + Number(row.avg_ratio ?? 0), 0) / rows.length;
    return { completeRate, avgRatio };
  };

  const fetchStudents = async (lessonId: number) => {
    if (!effectiveCourseId) return;
    setStudentLoading(true);
    setStudentError(null);
    try {
      const res = await tutorLmsApi.getProgressStudents({ courseId: effectiveCourseId, lessonId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setStudentRows(res.rst_data ?? []);
    } catch (e) {
      setStudentError(e instanceof Error ? e.message : '진도 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setStudentLoading(false);
    }
  };

  useEffect(() => {
    // 왜: selectedLessonId가 -1(전체 보기)일 때도 API를 호출해야 합니다.
    if (selectedLessonId === null || selectedLessonId === 0 || !effectiveCourseId) return;
    fetchStudents(selectedLessonId);
  }, [selectedLessonId, effectiveCourseId]);

  const filteredStudents = useMemo(() => {
    const kw = studentKeyword.trim().toLowerCase();
    if (!kw) return studentRows;
    return studentRows.filter((row) => {
      const name = String(row.name || '').toLowerCase();
      const studentId = String(row.student_id || '').toLowerCase();
      const email = String(row.email || '').toLowerCase();
      return name.includes(kw) || studentId.includes(kw) || email.includes(kw);
    });
  }, [studentRows, studentKeyword]);

  const openDetail = async (row: TutorProgressStudentRow) => {
    if (!selectedLessonId || !effectiveCourseId) return;

    // 왜: 상세는 클릭한 순간에만 불러오면 서버/DB 부담이 줄고 화면도 빨라집니다.
    setDetailOpen(true);
    setDetail(null);
    try {
      const res = await tutorLmsApi.getProgressDetail({
        courseId: effectiveCourseId,
        courseUserId: Number(row.course_user_id),
        lessonId: Number(selectedLessonId),
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setDetail(res.rst_data ?? null);
    } catch (e) {
      alert(e instanceof Error ? e.message : '진도 상세 조회 중 오류가 발생했습니다.');
      setDetailOpen(false);
    }
  };

  if (isHaksaCourse) {
    return (
      <div className="space-y-4">
        <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm flex items-start gap-2">
          <Info className="w-5 h-5 flex-shrink-0 mt-0.5" />
          <div>
            학사 과목은 <strong>주차/차시 기준</strong>으로 진도를 보여줍니다.
            동영상 콘텐츠가 있는 차시만 진도 데이터가 표시됩니다.
          </div>
        </div>

        {haksaError && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
            {haksaError}
          </div>
        )}
        {resolvingCourseId && (
          <div className="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-lg text-sm">
            과정 매핑 중입니다. 잠시만 기다려 주세요.
          </div>
        )}

        <div className="grid grid-cols-12 gap-4">
          <div className="col-span-4 border border-gray-200 rounded-lg overflow-hidden">
            <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 text-sm text-gray-700">
              주차별 차시 목록
            </div>

            {haksaLoading && (
              <div className="p-4 text-sm text-gray-600 flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                불러오는 중...
              </div>
            )}
            {summaryError && <div className="p-4 text-sm text-red-600">{summaryError}</div>}

            {!haksaLoading && haksaWeekGroups.length === 0 && (
              <div className="p-4 text-sm text-gray-600">등록된 차시가 없습니다.</div>
            )}

            <div className="divide-y divide-gray-200">
              {/* 전체 정보 보기 옵션 */}
              <button
                onClick={() => {
                  setSelectedSessionId('overall');
                  setSelectedLessonId(-1);
                }}
                className={`w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors ${
                  selectedSessionId === 'overall' ? 'bg-purple-50' : ''
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="min-w-0">
                    <div className="text-sm text-purple-700 font-medium">📊 전체 정보 보기</div>
                    <div className="text-xs text-gray-600">전체 진도율 확인</div>
                  </div>
                  <ChevronRight className={`w-4 h-4 ${selectedSessionId === 'overall' ? 'text-purple-600' : 'text-gray-400'}`} />
                </div>
              </button>
              {haksaWeekGroups.map((week) => (
                <div key={`week-${week.weekNumber}`}>
                  <div className="px-4 py-2 text-xs text-gray-500 bg-gray-50 border-b border-gray-200">
                    {week.weekTitle}
                    {week.sessions.length > 0 ? ` · ${week.sessions.length}개 차시` : ''}
                  </div>
                  <div className="divide-y divide-gray-200">
                    {week.sessions.map((session) => {
                      const isActive = session.sessionId === selectedSessionId;
                      const stats = buildSessionSummary(session);
                      const videoLabel = session.videoCount > 0 ? `동영상 ${session.videoCount}개` : '동영상 없음';

                      return (
                        <button
                          key={session.sessionId}
                          onClick={() => setSelectedSessionId(session.sessionId)}
                          className={`w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors ${
                            isActive ? 'bg-blue-50' : ''
                          }`}
                        >
                          <div className="flex items-center justify-between gap-2">
                            <div className="min-w-0">
                              <div className="text-sm text-gray-900 truncate">
                                {session.sessionName}
                              </div>
                              <div className="text-xs text-gray-600">
                                {videoLabel}
                                {stats
                                  ? ` · 완료 ${Math.round(stats.completeRate)}% · 평균 ${Math.round(stats.avgRatio)}%`
                                  : ''}
                              </div>
                            </div>
                            <ChevronRight className={`w-4 h-4 text-gray-400 ${isActive ? 'text-blue-600' : ''}`} />
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="col-span-8 border border-gray-200 rounded-lg overflow-hidden">
            <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 flex items-center justify-between gap-3">
              <div className="text-sm text-gray-700">
                {selectedSessionId === 'overall' ? (
                  <span className="text-purple-700 font-medium">📊 전체 정보 보기</span>
                ) : selectedHaksaSession ? (
                  <>
                    <span className="text-gray-900">
                      {selectedHaksaSession.weekTitle} · {selectedHaksaSession.sessionName}
                    </span>
                    {selectedHaksaVideo && (
                      <span className="text-gray-600"> · {selectedHaksaVideo.title}</span>
                    )}
                  </>
                ) : (
                  '차시를 선택해주세요'
                )}
              </div>

              <div className="flex items-center gap-2">
                {selectedHaksaSession && selectedHaksaSession.videoLessons.length > 1 && (
                  <select
                    value={selectedLessonId ?? ''}
                    onChange={(e) => setSelectedLessonId(Number(e.target.value))}
                    className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {selectedHaksaSession.videoLessons.map((video) => (
                      <option key={video.lessonId} value={video.lessonId}>
                        {video.title}
                      </option>
                    ))}
                  </select>
                )}
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    value={studentKeyword}
                    onChange={(e) => setStudentKeyword(e.target.value)}
                    placeholder="수강생 검색"
                    className="pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {selectedHaksaSession && selectedHaksaSession.videoLessons.length === 0 && (
              <div className="p-6 text-sm text-gray-500">
                선택한 차시에는 동영상 콘텐츠가 없습니다.
              </div>
            )}

            {studentLoading && (
              <div className="p-4 text-sm text-gray-600 flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                불러오는 중...
              </div>
            )}
            {studentError && <div className="p-4 text-sm text-red-600">{studentError}</div>}

            {(selectedLessonId === -1 || selectedLessonId) && (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-white border-b border-gray-200">
                    <tr>
                      <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
                      <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                      <th className="px-4 py-3 text-left text-sm text-gray-700">총 학습시간</th>
                      <th className="px-4 py-3 text-center text-sm text-gray-700">
                        {selectedLessonId === -1 ? '전체 진도율' : '진도율'}
                      </th>
                      <th className="px-4 py-3 text-left text-sm text-gray-700">
                        {selectedLessonId === -1 ? '수료여부' : '마지막 학습'}
                      </th>
                      {selectedLessonId !== -1 && (
                        <th className="px-4 py-3 text-center text-sm text-gray-700">상세</th>
                      )}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {filteredStudents.map((row) => {
                      const ratio = Math.max(0, Math.min(100, Number(row.ratio ?? 0)));
                      const complete = row.complete_yn === 'Y';

                      return (
                        <tr key={row.course_user_id} className="hover:bg-gray-50 transition-colors">
                          <td className="px-4 py-3 text-sm text-gray-900">{row.student_id || '-'}</td>
                          <td className="px-4 py-3 text-sm text-gray-900">{row.name || '-'}</td>
                          <td className="px-4 py-3 text-sm text-gray-700">{row.study_time_conv || '-'}</td>
                          <td className="px-4 py-3">
                            <div className="flex items-center justify-center gap-2">
                              <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                                <div
                                  className={`h-full rounded-full ${selectedLessonId === -1 ? 'bg-purple-600' : complete ? 'bg-green-600' : 'bg-blue-600'}`}
                                  style={{ width: `${ratio}%` }}
                                />
                              </div>
                              <span className="text-sm text-gray-900">{Math.round(ratio)}%</span>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-700">
                            {selectedLessonId === -1 ? (
                              <span className={`px-2 py-1 rounded text-xs ${complete ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                                {complete ? '수료' : '미수료'}
                              </span>
                            ) : (
                              row.last_date_conv || '-'
                            )}
                          </td>
                          {selectedLessonId !== -1 && (
                            <td className="px-4 py-3 text-center">
                              <button
                                onClick={() => openDetail(row)}
                                className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
                              >
                                보기
                              </button>
                            </td>
                          )}
                        </tr>
                      );
                    })}

                    {!studentLoading && !studentError && filteredStudents.length === 0 && (
                      <tr>
                        <td colSpan={selectedLessonId === -1 ? 5 : 6} className="px-4 py-10 text-center text-sm text-gray-500">
                          표시할 수강생이 없습니다.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        <ProgressDetailModal
          isOpen={detailOpen}
          onClose={() => setDetailOpen(false)}
          detail={detail}
        />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-12 gap-4">
        <div className="col-span-4 border border-gray-200 rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 text-sm text-gray-700">
            차시 목록
          </div>

          {summaryLoading && (
            <div className="p-4 text-sm text-gray-600 flex items-center gap-2">
              <Loader2 className="w-4 h-4 animate-spin" />
              불러오는 중...
            </div>
          )}
          {summaryError && <div className="p-4 text-sm text-red-600">{summaryError}</div>}

          {!summaryLoading && !summaryError && summaryRows.length === 0 && (
            <div className="p-4 text-sm text-gray-600">차시가 없습니다.</div>
          )}

          <div className="divide-y divide-gray-200">
            {/* 전체 정보 보기 옵션 */}
            <button
              onClick={() => setSelectedLessonId(-1)}
              className={`w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors ${
                selectedLessonId === -1 ? 'bg-purple-50' : ''
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <div className="min-w-0">
                  <div className="text-sm text-purple-700 font-medium">📊 전체 정보 보기</div>
                  <div className="text-xs text-gray-600">전체 진도율 확인</div>
                </div>
                <ChevronRight className={`w-4 h-4 ${selectedLessonId === -1 ? 'text-purple-600' : 'text-gray-400'}`} />
              </div>
            </button>
            {summaryRows.map((row) => {
              const isActive = Number(row.lesson_id) === Number(selectedLessonId);
              const completeRate = Number(row.complete_rate ?? 0);

              return (
                <button
                  key={`${row.lesson_id}-${row.chapter}`}
                  onClick={() => setSelectedLessonId(Number(row.lesson_id))}
                  className={`w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors ${
                    isActive ? 'bg-blue-50' : ''
                  }`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <div className="text-sm text-gray-900 truncate">
                        {row.chapter}. {row.lesson_nm || '-'}
                      </div>
                      <div className="text-xs text-gray-600">
                        완료 {Math.round(completeRate)}% · 평균 {Math.round(Number(row.avg_ratio ?? 0))}%
                      </div>
                    </div>
                    <ChevronRight className={`w-4 h-4 text-gray-400 ${isActive ? 'text-blue-600' : ''}`} />
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        <div className="col-span-8 border border-gray-200 rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 flex items-center justify-between gap-3">
            <div className="text-sm text-gray-700">
              {selectedLessonId === -1 ? (
                <span className="text-purple-700 font-medium">📊 전체 정보 보기</span>
              ) : selectedSummary ? (
                <>
                  <span className="text-gray-900">{selectedSummary.chapter}차시</span>
                  <span className="text-gray-600"> · {selectedSummary.lesson_nm}</span>
                </>
              ) : (
                '차시를 선택해주세요'
              )}
            </div>

            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                value={studentKeyword}
                onChange={(e) => setStudentKeyword(e.target.value)}
                placeholder="수강생 검색"
                className="pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {studentLoading && (
            <div className="p-4 text-sm text-gray-600 flex items-center gap-2">
              <Loader2 className="w-4 h-4 animate-spin" />
              불러오는 중...
            </div>
          )}
          {studentError && <div className="p-4 text-sm text-red-600">{studentError}</div>}

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-white border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
                  <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                  <th className="px-4 py-3 text-left text-sm text-gray-700">총 학습시간</th>
                  <th className="px-4 py-3 text-center text-sm text-gray-700">
                    {selectedLessonId === -1 ? '전체 진도율' : '진도율'}
                  </th>
                  <th className="px-4 py-3 text-left text-sm text-gray-700">
                    {selectedLessonId === -1 ? '수료여부' : '마지막 학습'}
                  </th>
                  {selectedLessonId !== -1 && (
                    <th className="px-4 py-3 text-center text-sm text-gray-700">상세</th>
                  )}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredStudents.map((row) => {
                  const ratio = Math.max(0, Math.min(100, Number(row.ratio ?? 0)));
                  const complete = row.complete_yn === 'Y';

                  return (
                    <tr key={row.course_user_id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3 text-sm text-gray-900">{row.student_id || '-'}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{row.name || '-'}</td>
                      <td className="px-4 py-3 text-sm text-gray-700">{row.study_time_conv || '-'}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-center gap-2">
                          <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                            <div
                              className={`h-full rounded-full ${selectedLessonId === -1 ? 'bg-purple-600' : complete ? 'bg-green-600' : 'bg-blue-600'}`}
                              style={{ width: `${ratio}%` }}
                            />
                          </div>
                          <span className="text-sm text-gray-900">{Math.round(ratio)}%</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-700">
                        {selectedLessonId === -1 ? (
                          <span className={`px-2 py-1 rounded text-xs ${complete ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                            {complete ? '수료' : '미수료'}
                          </span>
                        ) : (
                          row.last_date_conv || '-'
                        )}
                      </td>
                      {selectedLessonId !== -1 && (
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={() => openDetail(row)}
                            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
                          >
                            보기
                          </button>
                        </td>
                      )}
                    </tr>
                  );
                })}

                {!studentLoading && !studentError && filteredStudents.length === 0 && (
                  <tr>
                    <td colSpan={selectedLessonId === -1 ? 5 : 6} className="px-4 py-10 text-center text-sm text-gray-500">
                      표시할 수강생이 없습니다.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <ProgressDetailModal
        isOpen={detailOpen}
        onClose={() => setDetailOpen(false)}
        detail={detail}
      />
    </div>
  );
}
