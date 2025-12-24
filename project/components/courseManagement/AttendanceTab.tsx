import React, { useEffect, useMemo, useState } from 'react';
import { ChevronRight, Info, Loader2, Search } from 'lucide-react';
import { tutorLmsApi, TutorProgressDetailRow, TutorProgressStudentRow, TutorProgressSummaryRow } from '../../api/tutorLmsApi';

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

export function AttendanceTab({ courseId }: { courseId: number }) {
  // 왜: 학사 과목은 courseId가 NaN 또는 0이므로, 빈 상태로 시작하여 교수자가 직접 추가할 수 있도록 합니다.
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0;

  const [summaryRows, setSummaryRows] = useState<TutorProgressSummaryRow[]>([]);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryError, setSummaryError] = useState<string | null>(null);

  const [selectedLessonId, setSelectedLessonId] = useState<number | null>(null);

  const [studentRows, setStudentRows] = useState<TutorProgressStudentRow[]>([]);
  const [studentLoading, setStudentLoading] = useState(false);
  const [studentError, setStudentError] = useState<string | null>(null);

  const [studentKeyword, setStudentKeyword] = useState('');

  const [detailOpen, setDetailOpen] = useState(false);
  const [detail, setDetail] = useState<TutorProgressDetailRow | null>(null);

  useEffect(() => {
    // 왜: 다른 과목으로 이동했을 때 이전 선택(lesson_id)이 남아있으면 잘못된 조회가 발생할 수 있습니다.
    setSelectedLessonId(null);
    setStudentRows([]);
    setStudentKeyword('');
  }, [courseId]);

  useEffect(() => {
    // 왜: 학사 과목은 courseId가 유효하지 않아 API 호출이 불가능하므로, 빈 상태로 시작합니다.
    if (isHaksaCourse) return;

    let cancelled = false;

    // 왜: 진도 화면은 "요약(차시 목록)"이 먼저 있어야, 사용자가 차시를 선택할 수 있습니다.
    const run = async () => {
      setSummaryLoading(true);
      setSummaryError(null);
      try {
        const res = await tutorLmsApi.getProgressSummary({ courseId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        const rows = res.rst_data ?? [];
        if (cancelled) return;
        setSummaryRows(rows);
        if (!selectedLessonId && rows.length > 0) setSelectedLessonId(Number(rows[0].lesson_id));
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
  }, [courseId, isHaksaCourse]);

  const selectedSummary = useMemo(
    () => summaryRows.find((r) => Number(r.lesson_id) === Number(selectedLessonId)),
    [summaryRows, selectedLessonId]
  );

  const fetchStudents = async (lessonId: number) => {
    setStudentLoading(true);
    setStudentError(null);
    try {
      const res = await tutorLmsApi.getProgressStudents({ courseId, lessonId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setStudentRows(res.rst_data ?? []);
    } catch (e) {
      setStudentError(e instanceof Error ? e.message : '진도 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setStudentLoading(false);
    }
  };

  useEffect(() => {
    if (!selectedLessonId) return;
    fetchStudents(selectedLessonId);
  }, [selectedLessonId]);

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
    if (!selectedLessonId) return;

    // 왜: 상세는 클릭한 순간에만 불러오면 서버/DB 부담이 줄고 화면도 빨라집니다.
    setDetailOpen(true);
    setDetail(null);
    try {
      const res = await tutorLmsApi.getProgressDetail({
        courseId,
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

  // 왜: 학사 과목인 경우 빈 상태로 시작하여 교수자가 직접 진도 정보를 관리할 수 있도록 합니다.
  if (isHaksaCourse) {
    return (
      <div className="space-y-4">
        <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm flex items-start gap-2">
          <Info className="w-5 h-5 flex-shrink-0 mt-0.5" />
          <div>
            <strong>학사 연동 과목</strong>: 이 과목은 학사 시스템(e-poly)에서 연동되었습니다. 
            강의목차 등록 후 진도/출석 현황을 확인할 수 있습니다.
          </div>
        </div>
        <div className="text-center text-gray-500 py-12 border border-dashed border-gray-300 rounded-lg">
          <p className="mb-2">진도/출석 데이터가 없습니다.</p>
          <p className="text-sm text-gray-400">먼저 강의목차를 등록해주세요.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-12 gap-4">
        {/* 차시 목록 */}
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

        {/* 학생 진도 */}
        <div className="col-span-8 border border-gray-200 rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 flex items-center justify-between gap-3">
            <div className="text-sm text-gray-700">
              {selectedSummary ? (
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
                  <th className="px-4 py-3 text-left text-sm text-gray-700">학습시간</th>
                  <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
                  <th className="px-4 py-3 text-left text-sm text-gray-700">마지막 학습</th>
                  <th className="px-4 py-3 text-center text-sm text-gray-700">상세</th>
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
                              className={`h-full rounded-full ${complete ? 'bg-green-600' : 'bg-blue-600'}`}
                              style={{ width: `${ratio}%` }}
                            />
                          </div>
                          <span className="text-sm text-gray-900">{Math.round(ratio)}%</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-700">{row.last_date_conv || '-'}</td>
                      <td className="px-4 py-3 text-center">
                        <button
                          onClick={() => openDetail(row)}
                          className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
                        >
                          보기
                        </button>
                      </td>
                    </tr>
                  );
                })}

                {!studentLoading && !studentError && filteredStudents.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-4 py-10 text-center text-sm text-gray-500">
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
