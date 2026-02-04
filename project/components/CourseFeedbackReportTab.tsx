import React, { useMemo, useState } from 'react';
import { FileText, MessageSquare, Printer } from 'lucide-react';
import { tutorLmsApi, type TutorCourseRow, type TutorHomeworkReportRow, type TutorQnaReportRow } from '../api/tutorLmsApi';
import { sanitizeHtml } from '../lib/security';

type CourseInfo = TutorCourseRow & {
  sourceType?: 'haksa' | 'prism';
  mappedCourseId?: number;
  courseId?: string;
  subjectName?: string;
  programName?: string;
  period?: string;
  haksaCourseCode?: string;
  haksaOpenYear?: string;
  haksaOpenTerm?: string;
  haksaBunbanCode?: string;
  haksaGroupCode?: string;
};

export function CourseFeedbackReportTab({ course }: { course: CourseInfo }) {
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [loadingReport, setLoadingReport] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [homeworkRows, setHomeworkRows] = useState<TutorHomeworkReportRow[]>([]);
  const [qnaRows, setQnaRows] = useState<TutorQnaReportRow[]>([]);

  const courseIdLabel = useMemo(() => {
    return course.courseId || course.course_id_conv || course.course_cd || String(course.id);
  }, [course.courseId, course.course_id_conv, course.course_cd, course.id]);

  const courseTitle = useMemo(() => {
    return course.subjectName || course.course_nm || course.course_nm_conv || '-';
  }, [course.subjectName, course.course_nm, course.course_nm_conv]);

  const coursePeriod = useMemo(() => {
    return course.period || course.period_conv || '-';
  }, [course.period, course.period_conv]);

  const courseProgramName = useMemo(() => {
    return course.programName || course.program_nm_conv || '-';
  }, [course.programName, course.program_nm_conv]);

  const parsePeriodDates = (raw?: string) => {
    if (!raw) return { start: '', end: '' };
    const matches = raw.match(/(\d{4})[.\/-](\d{2})[.\/-](\d{2})/g);
    if (!matches || matches.length < 2) return { start: '', end: '' };
    const normalize = (value: string) => {
      const parts = value.replace(/[.]/g, '-').split('-');
      if (parts.length < 3) return '';
      const [y, m, d] = parts;
      return `${y}-${m}-${d}`;
    };
    return { start: normalize(matches[0]), end: normalize(matches[1]) };
  };

  const resolveReportCourseId = async () => {
    // 왜: 학사 과목은 출력 API가 LMS course_id를 요구하므로 먼저 매핑이 필요합니다.
    const mappedId = Number(course.mappedCourseId ?? course.mapped_course_id ?? 0);
    if (mappedId > 0) return mappedId;

    if (course.sourceType !== 'haksa') {
      const parsed = Number(course.id);
      return Number.isFinite(parsed) ? parsed : 0;
    }

    const haksaCourseCode = course.haksaCourseCode ?? course.haksa_course_code;
    const haksaOpenYear = course.haksaOpenYear ?? course.haksa_open_year;
    const haksaOpenTerm = course.haksaOpenTerm ?? course.haksa_open_term;
    const haksaBunbanCode = course.haksaBunbanCode ?? course.haksa_bunban_code;
    const haksaGroupCode = course.haksaGroupCode ?? course.haksa_group_code;

    if (!haksaCourseCode || !haksaOpenYear || !haksaOpenTerm || !haksaBunbanCode || !haksaGroupCode) {
      return 0;
    }

    const res = await tutorLmsApi.resolveHaksaCourse({
      courseCode: haksaCourseCode,
      openYear: haksaOpenYear,
      openTerm: haksaOpenTerm,
      bunbanCode: haksaBunbanCode,
      groupCode: haksaGroupCode,
    });
    if (res.rst_code !== '0000') throw new Error(res.rst_message);
    const resolved = Number(res.rst_data?.mapped_course_id ?? 0);
    return Number.isFinite(resolved) ? resolved : 0;
  };

  const fetchReport = async (range?: { start?: string; end?: string }) => {
    setLoadingReport(true);
    setErrorMessage(null);
    try {
      const reportCourseId = await resolveReportCourseId();
      if (!reportCourseId) throw new Error('학사 과목이 LMS에 매핑되지 않아 출력할 수 없습니다.');

      const res = await tutorLmsApi.getCourseFeedbackReport({
        courseId: reportCourseId,
        startDate: range?.start || startDate || undefined,
        endDate: range?.end || endDate || undefined,
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

  const handleSearchReport = async () => {
    await fetchReport();
  };

  const handlePrint = () => {
    // 왜: 화면을 그대로 print 하면 브라우저별로 표/스크롤 레이아웃이 쉽게 깨집니다.
    //     대학 교수님들이 실제로 쓰는 출력물은 “안정적으로 인쇄되는 포맷”이 더 중요하므로,
    //     인쇄 전용 새 창(템플릿)으로 출력합니다.
    if (homeworkRows.length === 0 && qnaRows.length === 0) {
      alert('출력할 데이터가 없습니다.');
      return;
    }

    const escapeHtml = (value: string) =>
      value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');

    const nl2br = (value: string) => escapeHtml(value).replace(/\n/g, '<br />');

    const formatBadge = (text: string, tone: 'green' | 'orange' | 'blue' | 'gray') => {
      const color =
        tone === 'green' ? 'badge green' :
        tone === 'orange' ? 'badge orange' :
        tone === 'blue' ? 'badge blue' :
        'badge gray';
      return `<span class="${color}">${escapeHtml(text)}</span>`;
    };

    const printTitle = `과목 통합 출력`;
    const courseName = courseTitle;
    const courseIdText = courseIdLabel;
    const periodText = coursePeriod;
    const programText = courseProgramName;
    const rangeText = `${startDate || '-'} ~ ${endDate || '-'}`;

    // 과제는 과제명(과제ID) 기준으로 묶어 “과제별 + 학생 목록” 형태로 출력합니다.
    const homeworkGroupMap = new Map<number, { homeworkName: string; rows: TutorHomeworkReportRow[] }>();
    homeworkRows.forEach((row) => {
      const hid = Number(row.homework_id ?? 0);
      if (!homeworkGroupMap.has(hid)) {
        homeworkGroupMap.set(hid, { homeworkName: row.homework_nm || `과제 ${hid}`, rows: [] });
      }
      homeworkGroupMap.get(hid)!.rows.push(row);
    });
    const homeworkGroups = Array.from(homeworkGroupMap.entries())
      .sort((a, b) => a[0] - b[0])
      .map(([homeworkId, group]) => ({
        homeworkId,
        homeworkName: group.homeworkName,
        rows: group.rows,
      }));

    const homeworkHtml = homeworkGroups.length === 0
      ? `<div class="empty">과제 제출 내역이 없습니다.</div>`
      : homeworkGroups.map((g) => {
        const items = g.rows.map((row) => {
          const submitted = row.submitted || row.submit_yn === 'Y';
          const confirmed = row.confirmed || row.confirm_yn === 'Y';
          const studentName = row.user_nm || row.login_id || '-';
          const studentId = row.student_id || row.login_id || '-';
          const submittedAt = row.submitted_at || '-';
          const score = row.score_conv || (row.score !== undefined ? String(row.score) : '-');
          const taskCount = Number(row.task_cnt ?? 0);
          const lastTaskDate = row.last_task_date_conv || '-';
          const feedback = row.feedback ? nl2br(row.feedback) : '-';

          return `
            <div class="item">
              <div class="item-head">
                <div class="who">
                  <div class="name">${escapeHtml(studentName)}</div>
                  <div class="meta">학번: ${escapeHtml(studentId)}</div>
                </div>
                <div class="status">
                  ${submitted ? formatBadge('제출', 'blue') : formatBadge('미제출', 'gray')}
                  ${confirmed ? formatBadge('확인완료', 'green') : formatBadge('미확인', 'orange')}
                </div>
              </div>
              <div class="grid">
                <div class="kv"><div class="k">제출일</div><div class="v">${escapeHtml(submittedAt)}</div></div>
                <div class="kv"><div class="k">점수</div><div class="v">${escapeHtml(score)}</div></div>
                <div class="kv"><div class="k">재제출(추가과제)</div><div class="v">${taskCount}건</div></div>
                <div class="kv"><div class="k">재제출 최근일</div><div class="v">${escapeHtml(lastTaskDate)}</div></div>
              </div>
              <div class="feedback">
                <div class="k">피드백</div>
                <div class="v">${feedback}</div>
              </div>
            </div>
          `;
        }).join('');

        return `
          <section class="section">
            <div class="section-title">과제: ${escapeHtml(g.homeworkName)} <span class="muted">(ID:${g.homeworkId}, ${g.rows.length}명)</span></div>
            <div class="items">
              ${items}
            </div>
          </section>
        `;
      }).join('');

    const qnaHtml = qnaRows.length === 0
      ? `<div class="empty">Q&A 내역이 없습니다.</div>`
      : qnaRows.map((row) => {
        const who = row.question_user_nm || row.question_login_id || '-';
        const when = row.question_reg_date_conv || '-';
        const answered = row.answered ? formatBadge('답변완료', 'green') : formatBadge('대기', 'orange');

        // 왜: Q&A 내용은 원래 화면에서도 HTML로 표시되므로, 인쇄에서도 동일하게 출력합니다.
        const questionHtml = row.question_content || '';
        const answerHtml = row.answer_content || '<em>답변이 없습니다.</em>';
        const answerWhen = row.answer_reg_date_conv || '-';

        return `
          <section class="section">
            <div class="section-title">
              Q&A: ${escapeHtml(row.subject || '-')}
              <span class="muted">(${escapeHtml(who)} · ${escapeHtml(when)} · ${answered})</span>
            </div>
            <div class="qna">
              <div class="q-block">
                <div class="k">질문</div>
                <div class="v prose">${questionHtml}</div>
              </div>
              <div class="q-block">
                <div class="k">답변 <span class="muted">(최근: ${escapeHtml(answerWhen)})</span></div>
                <div class="v prose">${answerHtml}</div>
              </div>
            </div>
          </section>
        `;
      }).join('');

    const html = `
      <!doctype html>
      <html lang="ko">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>${escapeHtml(printTitle)}</title>
          <style>
            @page { size: A4 landscape; margin: 10mm; }
            * { box-sizing: border-box; }
            html, body { height: 100%; }
            body {
              margin: 0;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans KR", "Apple SD Gothic Neo", Arial, sans-serif;
              color: #111827;
              background: #ffffff;
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            .container { padding: 10mm; }
            .title { font-size: 18px; font-weight: 700; margin: 0 0 8px; }
            .sub { font-size: 12px; color: #4b5563; margin: 0 0 14px; }
            .meta {
              display: grid;
              grid-template-columns: 1fr 1fr;
              gap: 6px 16px;
              font-size: 12px;
              color: #374151;
              padding: 10px 12px;
              border: 1px solid #e5e7eb;
              border-radius: 10px;
              margin-bottom: 16px;
            }
            .meta .k { color: #6b7280; }
            .section { margin-bottom: 18px; }
            .section-title {
              display: flex;
              align-items: baseline;
              gap: 8px;
              font-weight: 700;
              font-size: 14px;
              margin: 0 0 10px;
            }
            .muted { color: #6b7280; font-weight: 500; font-size: 12px; }
            .empty {
              border: 1px dashed #e5e7eb;
              border-radius: 10px;
              padding: 12px;
              color: #6b7280;
              font-size: 12px;
            }
            .items { display: flex; flex-direction: column; gap: 10px; }
            .item {
              border: 1px solid #e5e7eb;
              border-radius: 12px;
              padding: 10px 12px;
              page-break-inside: avoid;
            }
            .item-head {
              display: flex;
              align-items: flex-start;
              justify-content: space-between;
              gap: 12px;
              margin-bottom: 8px;
            }
            .who .name { font-weight: 700; font-size: 13px; }
            .who .meta { font-size: 11px; color: #6b7280; padding: 0; border: 0; border-radius: 0; margin: 2px 0 0; display: block; }
            .status { display: flex; gap: 6px; flex-wrap: wrap; justify-content: flex-end; }
            .badge {
              display: inline-flex;
              align-items: center;
              padding: 2px 8px;
              border-radius: 999px;
              font-size: 11px;
              font-weight: 700;
              border: 1px solid transparent;
              white-space: nowrap;
            }
            .badge.green { background: #dcfce7; color: #166534; }
            .badge.orange { background: #ffedd5; color: #9a3412; }
            .badge.blue { background: #dbeafe; color: #1d4ed8; }
            .badge.gray { background: #f3f4f6; color: #4b5563; }
            .grid {
              display: grid;
              grid-template-columns: 1fr 1fr 1fr 1fr;
              gap: 6px 12px;
              font-size: 12px;
              color: #374151;
              margin-bottom: 8px;
            }
            .kv { display: flex; gap: 6px; }
            .kv .k { color: #6b7280; min-width: 86px; }
            .kv .v { color: #111827; }
            .feedback .k { color: #6b7280; font-size: 12px; margin-bottom: 4px; }
            .feedback .v { font-size: 12px; color: #111827; line-height: 1.5; }
            .qna {
              border: 1px solid #e5e7eb;
              border-radius: 12px;
              padding: 10px 12px;
              page-break-inside: avoid;
            }
            .q-block + .q-block { margin-top: 10px; padding-top: 10px; border-top: 1px solid #f3f4f6; }
            .q-block .k { font-weight: 700; font-size: 12px; margin-bottom: 4px; }
            .prose { font-size: 12px; line-height: 1.55; color: #111827; }
            .prose p { margin: 0 0 6px; }
            .prose img { max-width: 100%; height: auto; }
            @media print {
              .container { padding: 0; }
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1 class="title">${escapeHtml(printTitle)}</h1>
            <p class="sub">대학교 교수자용 통합 출력(과목 전체 기간 기준)</p>

            <div class="meta">
              <div><span class="k">과목명</span>: ${escapeHtml(courseName)}</div>
              <div><span class="k">과목코드</span>: ${escapeHtml(courseIdText)}</div>
              <div><span class="k">과정명</span>: ${escapeHtml(programText)}</div>
              <div><span class="k">과목기간</span>: ${escapeHtml(periodText)}</div>
              <div><span class="k">조회기간</span>: ${escapeHtml(rangeText)}</div>
              <div><span class="k">출력일시</span>: ${escapeHtml(new Date().toLocaleString('ko-KR'))}</div>
            </div>

            <section class="section">
              <div class="section-title">과제 제출/피드백 <span class="muted">(${homeworkRows.length}건)</span></div>
              ${homeworkHtml}
            </section>

            <section class="section">
              <div class="section-title">Q&A 질문/답변 <span class="muted">(${qnaRows.length}건)</span></div>
              ${qnaHtml}
            </section>
          </div>

          <script>
            // 왜: 새 창에서 렌더링이 끝난 뒤 인쇄를 호출해야 빈 페이지가 나오는 문제를 줄일 수 있습니다.
            window.addEventListener('load', () => {
              setTimeout(() => {
                window.print();
              }, 150);
            });
          </script>
        </body>
      </html>
    `;

    // 왜: 일부 브라우저/보안 설정에서는 `noopener,noreferrer` 또는 document.write가 막혀
    //     about:blank만 뜨는 문제가 생길 수 있습니다. (팝업은 열리지만 내용 주입이 실패)
    //     그래서 1) document.write 방식 먼저 시도하고, 실패하면 2) Blob URL 방식으로 우회합니다.
    const openAndWrite = () => {
      const w = window.open('about:blank', '_blank');
      if (!w) return false;
      try {
        // 왜: 보안상 opener 연결은 끊되, 문서 주입은 가능해야 합니다.
        //     window.open의 feature에 noopener를 넣으면 일부 환경에서 document 접근이 막힐 수 있어 수동으로 처리합니다.
        try {
          // @ts-expect-error - 일부 브라우저는 readonly처럼 보이지만 런타임에서는 동작합니다.
          w.opener = null;
        } catch {}

        w.document.open();
        w.document.write(html);
        w.document.close();
        return true;
      } catch {
        try { w.close(); } catch {}
        return false;
      }
    };

    const openWithBlobUrl = () => {
      const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const w = window.open(url, '_blank');
      if (!w) {
        URL.revokeObjectURL(url);
        return false;
      }
      // 왜: 메모리 누수 방지 (문서 로드 후 URL 해제)
      w.addEventListener('load', () => {
        setTimeout(() => URL.revokeObjectURL(url), 500);
      });
      return true;
    };

    const ok = openAndWrite() || openWithBlobUrl();
    if (!ok) {
      alert('팝업이 차단되어 출력 창을 열 수 없습니다. 브라우저에서 팝업 허용 후 다시 시도해 주세요.');
    }
  };

  React.useEffect(() => {
    let cancelled = false;
    const init = async () => {
      const parsed = parsePeriodDates(course.period || course.period_conv || '');
      if (!cancelled) {
        setStartDate(parsed.start);
        setEndDate(parsed.end);
      }
      try {
        await fetchReport({ start: parsed.start, end: parsed.end });
      } catch (e) {
        if (!cancelled) {
          setErrorMessage(e instanceof Error ? e.message : '통합 출력 데이터를 불러오는 중 오류가 발생했습니다.');
        }
      }
    };
    void init();
    return () => {
      cancelled = true;
    };
  }, [
    course.id,
    course.mappedCourseId,
    course.sourceType,
    course.period,
    course.period_conv,
    course.haksaCourseCode,
    course.haksaOpenYear,
    course.haksaOpenTerm,
    course.haksaBunbanCode,
    course.haksaGroupCode,
    course.haksa_course_code,
    course.haksa_open_year,
    course.haksa_open_term,
    course.haksa_bunban_code,
    course.haksa_group_code,
  ]);

  return (
    <div className="space-y-6">
      <style>
        {`
          @media print {
            @page { size: A4 landscape; margin: 10mm; }
            header, aside { display: none !important; }
            main { padding: 0 !important; }
            .print-hidden { display: none !important; }
            .print-card { border: none !important; box-shadow: none !important; }
            body { background: white !important; }
            .print-wide { width: 100% !important; max-width: 100% !important; }
            .print-table-wrap { overflow: visible !important; }
            .print-table { width: 100% !important; min-width: 0 !important; table-layout: auto !important; }
            .print-table th, .print-table td {
              word-break: break-word !important;
              white-space: normal !important;
              padding: 6px 8px !important;
              font-size: 11px !important;
            }
          }
        `}
      </style>

      <div className="print-hidden">
        <h3 className="text-gray-900 mb-1">과목별 과제/Q&A 통합 출력</h3>
        <p className="text-sm text-gray-600">현재 과목 기준으로 제출/피드백과 Q&A를 출력합니다.</p>
      </div>

      <div className="bg-white border border-gray-200 rounded-lg p-4 space-y-4 print-hidden">
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
              onClick={handlePrint}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              disabled={loadingReport || (homeworkRows.length === 0 && qnaRows.length === 0)}
            >
              <Printer className="w-4 h-4 inline-block mr-2" />
              출력
            </button>
            <span className="text-xs text-gray-500">
              출력은 새 창으로 열립니다(팝업 허용 필요)
            </span>
          </div>
        </div>
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg print-hidden">
          {errorMessage}
        </div>
      )}

      <div className="bg-white border border-gray-200 rounded-lg p-6 print-card print-wide">
        <div className="mb-6">
          <h4 className="text-gray-900 mb-2">과목 정보</h4>
          <div className="text-sm text-gray-600 space-y-1">
            <div>과목명: {courseTitle}</div>
            <div>과목코드: {courseIdLabel || '-'}</div>
            <div>기간: {coursePeriod}</div>
            <div>과정명: {courseProgramName}</div>
          </div>
        </div>

        <div className="space-y-8">
          <section>
            <div className="flex items-center gap-2 mb-3">
              <FileText className="w-5 h-5 text-orange-600" />
              <h4 className="text-gray-900">과제 제출/피드백</h4>
              <span className="text-sm text-gray-500">({homeworkRows.length}건)</span>
            </div>

            {loadingReport ? (
              <div className="p-6 text-center text-gray-500">불러오는 중...</div>
            ) : homeworkRows.length === 0 ? (
              <div className="p-6 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
                과제 제출 내역이 없습니다.
              </div>
            ) : (
              <div className="overflow-x-auto border border-gray-200 rounded-lg print-wide print-table-wrap">
                <table className="w-full text-sm min-w-[1200px] print-table">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-gray-700 w-48">과제명</th>
                      <th className="px-4 py-3 text-left text-gray-700 w-36">제출자</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-32">학번</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-24">제출여부</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-36">제출일</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-24">점수</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-24">확인여부</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-28">재제출 건수</th>
                      <th className="px-4 py-3 text-center text-gray-700 w-36">재제출 최근일</th>
                      <th className="px-4 py-3 text-left text-gray-700 min-w-[240px]">피드백</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {homeworkRows.map((row, idx) => {
                      const score = row.score_conv || (row.score !== undefined ? String(row.score) : '-');
                      const confirmed = row.confirmed || row.confirm_yn === 'Y';
                      const submitted = row.submitted || row.submit_yn === 'Y';
                      const studentId = row.student_id || row.login_id || '-';
                      const taskCount = Number(row.task_cnt ?? 0);
                      const lastTaskDate = row.last_task_date_conv || '-';
                      return (
                        <tr key={`${row.homework_id}-${row.course_user_id}-${idx}`}>
                          <td className="px-4 py-3 text-gray-900 whitespace-nowrap">{row.homework_nm || '-'}</td>
                          <td className="px-4 py-3 text-gray-700 whitespace-nowrap">{row.user_nm || row.login_id || '-'}</td>
                          <td className="px-4 py-3 text-center text-gray-600 whitespace-nowrap">{studentId}</td>
                          <td className="px-4 py-3 text-center">
                            <span
                              className={`px-2 py-1 text-xs rounded-full ${
                                submitted ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'
                              }`}
                            >
                              {submitted ? '제출' : '미제출'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-center text-gray-600 whitespace-nowrap">{row.submitted_at || '-'}</td>
                          <td className="px-4 py-3 text-center text-gray-600 whitespace-nowrap">{score}</td>
                          <td className="px-4 py-3 text-center">
                            <span
                              className={`px-2 py-1 text-xs rounded-full ${
                                confirmed ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
                              }`}
                            >
                              {confirmed ? '확인완료' : '미확인'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-center text-gray-700 whitespace-nowrap">{taskCount}</td>
                          <td className="px-4 py-3 text-center text-gray-600 whitespace-nowrap">{lastTaskDate}</td>
                          <td className="px-4 py-3 text-gray-700 whitespace-pre-wrap break-words">{row.feedback || '-'}</td>
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
              <h4 className="text-gray-900">Q&A 질문/답변</h4>
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
