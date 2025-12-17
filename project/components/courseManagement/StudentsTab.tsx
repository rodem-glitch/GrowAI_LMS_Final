import React, { useEffect, useMemo, useState } from 'react';
import { Download, Plus, Search, Trash2 } from 'lucide-react';
import { tutorLmsApi, TutorCourseStudentRow } from '../../api/tutorLmsApi';
import { downloadCsv } from '../../utils/csv';

function parseUserIds(raw: string) {
  return raw
    .split(',')
    .map((v) => v.trim())
    .filter((v) => /^\d+$/.test(v))
    .map((v) => Number(v))
    .filter((v) => v > 0);
}

export function StudentsTab({ courseId }: { courseId: number }) {
  if (!courseId || Number.isNaN(courseId)) {
    return <div className="text-sm text-red-600">과목 ID가 올바르지 않습니다.</div>;
  }

  const [rows, setRows] = useState<TutorCourseStudentRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [keyword, setKeyword] = useState('');

  const refresh = async (nextKeyword?: string) => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getCourseStudents({ courseId, keyword: nextKeyword ?? keyword });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setRows(res.rst_data ?? []);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '수강생을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let cancelled = false;

    // 왜: 새로고침해도 동일한 DB 결과가 보여야 하므로, 탭 진입 시 서버에서 다시 가져옵니다.
    const run = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getCourseStudents({ courseId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        if (!cancelled) setRows(res.rst_data ?? []);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '수강생을 불러오는 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    run();
    return () => {
      cancelled = true;
    };
  }, [courseId]);

  const totalCount = rows.length;

  const handleAddStudents = async () => {
    // 왜: 백엔드(course_students_add.jsp)는 user_id 숫자 목록을 받습니다.
    const raw = window.prompt('추가할 수강생 user_id를 콤마(,)로 구분해 입력해주세요.\n예) 12,34,56');
    if (raw === null) return;
    const userIds = parseUserIds(raw);
    if (userIds.length === 0) {
      alert('입력값에서 user_id(숫자)를 찾지 못했습니다.');
      return;
    }

    try {
      const res = await tutorLmsApi.addCourseStudents({ courseId, userIds });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const inserted = Number(res.rst_data ?? 0);
      const skipped = Number(res.rst_skipped ?? 0);
      alert(`추가 완료: ${inserted}명${skipped > 0 ? ` (중복 ${skipped}명 제외)` : ''}`);

      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : '수강생 추가 중 오류가 발생했습니다.');
    }
  };

  const handleRemoveStudent = async (userId: number, name?: string) => {
    const ok = window.confirm(`${name || '해당 수강생'}을(를) 과목에서 제외하시겠습니까?`);
    if (!ok) return;

    try {
      const res = await tutorLmsApi.removeCourseStudent({ courseId, userId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : '수강생 제외 중 오류가 발생했습니다.');
    }
  };

  const sortedRows = useMemo(() => {
    // 왜: 서버에서는 id DESC로 내려오지만, 화면에서는 이름 기준이 더 읽기 쉽습니다.
    return [...rows].sort((a, b) => String(a.name || '').localeCompare(String(b.name || '')));
  }, [rows]);

  const handleDownloadCsv = () => {
    // 왜: 운영자가 바로 확인할 수 있도록, 화면에 표시 중인 목록을 그대로 CSV로 내려받습니다.
    const ymd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const filename = `course_${courseId}_students_${ymd}.csv`;

    const headers = ['No', 'course_user_id', 'user_id', '학번', '이름', '이메일', '진도율(%)'];
    const body = sortedRows.map((student, index) => {
      const progress = Number(student.progress ?? student.progress_ratio ?? 0);
      return [
        index + 1,
        student.course_user_id,
        student.user_id,
        student.student_id ?? '',
        student.name ?? '',
        student.email ?? '',
        Math.round(progress),
      ];
    });

    downloadCsv(filename, headers, body);
  };

  return (
    <div>
      <div className="mb-4 flex items-center justify-between gap-3">
        <div className="text-sm text-gray-600">총 {totalCount}명</div>

        <div className="flex items-center gap-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              placeholder="이름/아이디/이메일 검색"
              className="pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            onClick={() => refresh(keyword)}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50 transition-colors"
          >
            검색
          </button>

          <button
            onClick={handleAddStudents}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>수강생 추가</span>
          </button>

          <button
            onClick={handleDownloadCsv}
            className="flex items-center gap-2 px-4 py-2 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <Download className="w-4 h-4" />
            <span>엑셀 다운로드(CSV)</span>
          </button>
        </div>
      </div>

      {loading && <div className="text-sm text-gray-600">불러오는 중...</div>}
      {errorMessage && <div className="text-sm text-red-600">{errorMessage}</div>}

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이메일</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">관리</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {sortedRows.map((student, index) => {
              const progress = Number(student.progress ?? student.progress_ratio ?? 0);

              return (
                <tr key={student.course_user_id || `${student.user_id}-${index}`} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.student_id || '-'}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.name || '-'}</td>
                  <td className="px-4 py-4 text-sm text-gray-600">{student.email || '-'}</td>
                  <td className="px-4 py-4">
                    <div className="flex items-center justify-center gap-2">
                      <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-blue-600 rounded-full"
                          style={{ width: `${Math.max(0, Math.min(100, progress))}%` }}
                        />
                      </div>
                      <span className="text-sm text-gray-900">{Math.round(progress)}%</span>
                    </div>
                  </td>
                  <td className="px-4 py-4 text-center">
                    <button
                      onClick={() => handleRemoveStudent(Number(student.user_id), student.name)}
                      className="inline-flex items-center gap-1 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                      제외
                    </button>
                  </td>
                </tr>
              );
            })}
            {!loading && !errorMessage && sortedRows.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-10 text-center text-sm text-gray-500">
                  수강생이 없습니다.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
