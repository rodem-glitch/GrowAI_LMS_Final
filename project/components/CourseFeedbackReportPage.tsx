import React, { useEffect, useMemo, useState } from 'react';
import { FileText, MessageSquare, Printer, RefreshCw } from 'lucide-react';
import { tutorLmsApi, type TutorCourseRow, type TutorHomeworkReportRow, type TutorQnaReportRow } from '../api/tutorLmsApi';
import { sanitizeHtml } from '../lib/security';

export function CourseFeedbackReportPage() {
  const [tab, setTab] = useState<'prism' | 'haksa'>('prism');
  const [courses, setCourses] = useState<TutorCourseRow[]>([]);
  const [courseKeyword, setCourseKeyword] = useState('');
  const [searchKeyword, setSearchKeyword] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState<string>('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [loadingCourses, setLoadingCourses] = useState(false);
  const [loadingReport, setLoadingReport] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [homeworkRows, setHomeworkRows] = useState<TutorHomeworkReportRow[]>([]);
  const [qnaRows, setQnaRows] = useState<TutorQnaReportRow[]>([]);

  useEffect(() => {
    let cancelled = false;

    const fetchCourses = async () => {
      setLoadingCourses(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getMyCoursesCombined({
          tab,
          keyword: searchKeyword || undefined,
          page: 1,
          pageSize: 200,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        if (!cancelled) setCourses(res.rst_data ?? []);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '과목 목록을 불러오는 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoadingCourses(false);
      }
    };

    void fetchCourses();
    return () => {
      cancelled = true;
    };
  }, [tab, searchKeyword]);

  useEffect(() => {
    // 왜: 탭이 바뀌면 선택 과목과 결과를 초기화해야 혼동을 막을 수 있습니다.
    setSelectedCourseId('');
    setHomeworkRows([]);
    setQnaRows([]);
  }, [tab]);

  const filteredCourses = useMemo(() => {
    const keyword = courseKeyword.trim().toLowerCase();
    if (!keyword) return courses;
    return courses.filter((course) => {
      const targets = [course.course_nm, course.program_nm_conv, course.course_id_conv]
        .map((value) => String(value || '').toLowerCase());
      return targets.some((value) => value.includes(keyword));
    });
  }, [courses, courseKeyword]);

  const selectedCourse = useMemo(() => {
    if (!selectedCourseId) return null;
    return courses.find((course) => String(course.id) === selectedCourseId) ?? null;
  }, [courses, selectedCourseId]);

  const resolveReportCourseId = async (course: TutorCourseRow) => {
    const mappedId = Number(course.mapped_course_id ?? 0);
    if (mappedId > 0) return mappedId;
    if (course.source_type !== 'haksa') {
      const parsed = Number(course.id);
      return Number.isFinite(parsed) ? parsed : 0;
    }
    if (!course.haksa_course_code || !course.haksa_open_year || !course.haksa_open_term || !course.haksa_bunban_code || !course.haksa_group_code) {
      return 0;
    }
    const res = await tutorLmsApi.resolveHaksaCourse({
      courseCode: course.haksa_course_code,
      openYear: course.haksa_open_year,
      openTerm: course.haksa_open_term,
      bunbanCode: course.haksa_bunban_code,
      groupCode: course.haksa_group_code,
    });
    if (res.rst_code !== '0000') throw new Error(res.rst_message);
    const resolved = Number(res.rst_data?.mapped_course_id ?? 0);
    return Number.isFinite(resolved) ? resolved : 0;
  };

  const handleSearchReport = async () => {
    // 왜: 과목이 선택되지 않으면 과목별 출력이 불가능하므로 먼저 확인합니다.
    if (!selectedCourseId || !selectedCourse) {
      alert('먼저 과목을 선택해 주세요.');
      return;
    }

    setLoadingReport(true);
    setErrorMessage(null);
    try {
      const courseId = await resolveReportCourseId(selectedCourse);
      if (!courseId) {
        throw new Error('학사 과목이 LMS에 매핑되어 있지 않아 출력할 수 없습니다.');
      }
      const res = await tutorLmsApi.getCourseFeedbackReport({
        courseId,
        startDate: startDate || undefined,
        endDate: endDate || undefined,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      setHomeworkRows(res.rst_homework ?? []);
      setQnaRows(res.rst_qna ?? []);
    } catch (e) {
      setHomeworkRows([]);
      setQnaRows([]);
      setErrorMessage(e instanceof Error ? e.message : '통합 출력 데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoadingReport(false);
    }
  };

  const handlePrint = () => {
    // 왜: 출력 시에는 화면 버튼/필터를 숨기고 결과만 보여줍니다.
    window.print();
  };

  const handleCourseSearch = () => {
    setSearchKeyword(courseKeyword.trim());
  };

  return (
    <div className="space-y-6">
      <style>
        {`
          @media print {
            .print-hidden { display: none !important; }
            .print-card { border: none !important; box-shadow: none !important; }
            body { background: white !important; }
          }
        `}
      </style>

      <div className="print-hidden">
        <h1 className="text-gray-900 mb-1">과목별 과제/Q&A 통합 출력</h1>
        <p className="text-gray-600">선택한 과목의 제출/피드백과 Q&A를 한 번에 확인하고 출력합니다.</p>
      </div>

      <div className="bg-white border border-gray-200 rounded-lg p-4 space-y-4 print-hidden">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setTab('haksa')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              tab === 'haksa' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            학사
          </button>
          <button
            type="button"
            onClick={() => setTab('prism')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              tab === 'prism' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            LMS
          </button>
        </div>
        <div className="flex flex-col md:flex-row gap-3 md:items-center">
          <div className="flex-1">
            <label className="block text-sm text-gray-600 mb-1">과목 검색</label>
            <input
              type="text"
              value={courseKeyword}
              onChange={(e) => setCourseKeyword(e.target.value)}
              placeholder="과목명/과정명으로 검색"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleCourseSearch();
              }}
            />
          </div>
          <div className="w-full md:w-80">
            <label className="block text-sm text-gray-600 mb-1">과목 선택</label>
            <select
              value={selectedCourseId}
              onChange={(e) => setSelectedCourseId(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg"
            >
              <option value="">과목을 선택하세요</option>
              {filteredCourses.map((course) => (
                <option key={course.id} value={course.id}>
                  {course.course_nm} ({course.course_id_conv || course.id})
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex flex-col md:flex-row gap-3 md:items-center">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">기간</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm"
            />
            <span className="text-sm text-gray-400">~</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm"
            />
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={handleSearchReport}
              className="px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
              disabled={loadingReport}
            >
              {loadingReport ? '조회 중...' : '조회'}
            </button>
            <button
              onClick={handleCourseSearch}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50 transition-colors"
            >
              과목 검색
            </button>
            <button
              onClick={handlePrint}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              disabled={loadingReport || (homeworkRows.length === 0 && qnaRows.length === 0)}
            >
              <Printer className="w-4 h-4 inline-block mr-2" />
              출력
            </button>
            <button
              onClick={() => window.location.reload()}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50 transition-colors"
              title="화면 새로고침"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {loadingCourses && <div className="text-sm text-gray-500">과목 목록을 불러오는 중...</div>}
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg print-hidden">
          {errorMessage}
        </div>
      )}

      <div className="bg-white border border-gray-200 rounded-lg p-6 print-card">
        <div className="mb-6">
          <h2 className="text-gray-900 mb-2">과목 정보</h2>
          {selectedCourse ? (
            <div className="text-sm text-gray-600 space-y-1">
              <div>과목명: {selectedCourse.course_nm}</div>
              <div>과목코드: {selectedCourse.course_id_conv || selectedCourse.id}</div>
              <div>기간: {selectedCourse.period_conv || '-'}</div>
              <div>과정명: {selectedCourse.program_nm_conv || '-'}</div>
            </div>
          ) : (
            <div className="text-sm text-gray-500">선택된 과목이 없습니다.</div>
          )}
        </div>

        <div className="space-y-8">
          <section>
            <div className="flex items-center gap-2 mb-3">
              <FileText className="w-5 h-5 text-orange-600" />
              <h3 className="text-gray-900">과제 제출/피드백</h3>
              <span className="text-sm text-gray-500">({homeworkRows.length}건)</span>
            </div>

            {loadingReport ? (
              <div className="p-6 text-center text-gray-500">불러오는 중...</div>
            ) : homeworkRows.length === 0 ? (
              <div className="p-6 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
                과제 제출 내역이 없습니다.
              </div>
            ) : (
              <div className="overflow-x-auto border border-gray-200 rounded-lg">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-gray-700">과제명</th>
                      <th className="px-4 py-3 text-left text-gray-700">제출자</th>
                      <th className="px-4 py-3 text-center text-gray-700">제출일</th>
                      <th className="px-4 py-3 text-center text-gray-700">점수</th>
                      <th className="px-4 py-3 text-center text-gray-700">확인여부</th>
                      <th className="px-4 py-3 text-left text-gray-700">피드백</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {homeworkRows.map((row, idx) => {
                      const score = row.score_conv || (row.score !== undefined ? String(row.score) : '-');
                      const confirmed = row.confirmed || row.confirm_yn === 'Y';
                      return (
                        <tr key={`${row.homework_id}-${row.course_user_id}-${idx}`}>
                          <td className="px-4 py-3 text-gray-900">{row.homework_nm || '-'}</td>
                          <td className="px-4 py-3 text-gray-700">{row.user_nm || row.login_id || '-'}</td>
                          <td className="px-4 py-3 text-center text-gray-600">{row.submitted_at || '-'}</td>
                          <td className="px-4 py-3 text-center text-gray-600">{score}</td>
                          <td className="px-4 py-3 text-center">
                            <span
                              className={`px-2 py-1 text-xs rounded-full ${
                                confirmed ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
                              }`}
                            >
                              {confirmed ? '확인완료' : '미확인'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-gray-700 whitespace-pre-wrap">{row.feedback || '-'}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </section>

          <section>
            <div className="flex items-center gap-2 mb-3">
              <MessageSquare className="w-5 h-5 text-purple-600" />
              <h3 className="text-gray-900">Q&A 질문/답변</h3>
              <span className="text-sm text-gray-500">({qnaRows.length}건)</span>
            </div>

            {loadingReport ? (
              <div className="p-6 text-center text-gray-500">불러오는 중...</div>
            ) : qnaRows.length === 0 ? (
              <div className="p-6 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
                Q&A 내역이 없습니다.
              </div>
            ) : (
              <div className="space-y-4">
                {qnaRows.map((row) => (
                  <div key={row.question_id} className="border border-gray-200 rounded-lg">
                    <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                      <div className="text-gray-900 mb-1">{row.subject || '-'}</div>
                      <div className="text-sm text-gray-600">
                        {row.question_user_nm || row.question_login_id || '-'} · {row.question_reg_date_conv || '-'}
                      </div>
                    </div>
                    <div
                      className="p-4 text-sm text-gray-800 prose max-w-none"
                      dangerouslySetInnerHTML={{ __html: sanitizeHtml(row.question_content) }}
                    />
                    <div className="bg-gray-50 px-4 py-2 border-t border-gray-200 text-sm text-gray-600">
                      답변: {row.answered ? '완료' : '대기'} · {row.answer_reg_date_conv || '-'}
                    </div>
                    <div
                      className="p-4 text-sm text-gray-800 prose max-w-none"
                      dangerouslySetInnerHTML={{ __html: sanitizeHtml(row.answer_content) || '<em>답변이 없습니다.</em>' }}
                    />
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}
