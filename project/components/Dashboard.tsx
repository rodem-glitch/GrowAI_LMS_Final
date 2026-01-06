import React, { useEffect, useMemo, useState } from 'react';
import {
  Users,
  BookOpen,
  ClipboardCheck,
  MessageSquare,
  Clock,
} from 'lucide-react';
import { tutorLmsApi, type TutorDashboardCourseRow, type TutorDashboardQnaRow, type TutorDashboardStats, type TutorDashboardSubmissionRow } from '../api/tutorLmsApi';
import type { CourseManagementTabId } from './CourseManagement';

type DashboardMenuId = 'dashboard' | 'explore' | 'courses' | 'create-course' | 'subject-create';
type DashboardCourseLink = {
  courseId: number;
  courseName?: string;
  targetTab?: CourseManagementTabId;
};

export function Dashboard({
  onNavigate,
  onOpenCourse,
}: {
  onNavigate?: (menu: DashboardMenuId) => void;
  onOpenCourse?: (payload: DashboardCourseLink) => void;
} = {}) {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [stats, setStats] = useState<TutorDashboardStats | null>(null);
  const [ongoingCourses, setOngoingCourses] = useState<TutorDashboardCourseRow[]>([]);
  const [recentSubmissions, setRecentSubmissions] = useState<TutorDashboardSubmissionRow[]>([]);
  const [recentQnas, setRecentQnas] = useState<TutorDashboardQnaRow[]>([]);

  useEffect(() => {
    let cancelled = false;

    const fetchDashboard = async () => {
      // 왜: 대시보드는 “요약 + 최신” 데이터라서, 화면 진입 시 한 번만 불러오면 됩니다.
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getDashboard();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        if (cancelled) return;
        setStats(res.rst_data ?? null);
        setOngoingCourses(res.rst_courses ?? []);
        setRecentSubmissions(res.rst_submissions ?? []);
        setRecentQnas(res.rst_qna ?? []);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '대시보드를 불러오는 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void fetchDashboard();
    return () => {
      cancelled = true;
    };
  }, []);

  const statCards = useMemo(() => ([
    {
      title: '진행 중인 과목',
      value: stats?.active_course_cnt ?? 0,
      icon: BookOpen,
      color: 'bg-blue-100 text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: '미확인 과제',
      value: stats?.pending_homework_cnt ?? 0,
      icon: ClipboardCheck,
      color: 'bg-orange-100 text-orange-600',
      bgColor: 'bg-orange-50',
    },
    {
      title: '미답변 Q&A',
      value: stats?.unanswered_qna_cnt ?? 0,
      icon: MessageSquare,
      color: 'bg-purple-100 text-purple-600',
      bgColor: 'bg-purple-50',
    },
  ]), [stats?.active_course_cnt, stats?.pending_homework_cnt, stats?.unanswered_qna_cnt]);

  // 왜: 대시보드는 "요약" 화면이라서 최신 항목을 3개까지만 보여줍니다.
  const visibleOngoingCourses = useMemo(() => ongoingCourses.slice(0, 3), [ongoingCourses]);
  const visibleRecentSubmissions = useMemo(() => recentSubmissions.slice(0, 3), [recentSubmissions]);
  const visibleRecentQnas = useMemo(() => recentQnas.slice(0, 3), [recentQnas]);

  const goToMyCourses = () => {
    // 왜: 대시보드의 상세 작업(과제/질문 확인)은 결국 “담당과목”에서 진행됩니다.
    onNavigate?.('courses');
  };

  const openCourseFromDashboard = (payload: DashboardCourseLink) => {
    // 왜: 대시보드 항목을 눌렀을 때 담당과목의 해당 탭으로 바로 이동하게 합니다.
    if (onOpenCourse) {
      onOpenCourse(payload);
      return;
    }
    onNavigate?.('courses');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-gray-900 mb-1">대시보드</h1>
        <p className="text-gray-600">교수자 활동 현황을 한눈에 확인하세요</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {statCards.map((stat, index) => (
          <div
            key={index}
            className={`${stat.bgColor} border border-gray-200 rounded-lg p-6 transition-all hover:shadow-md`}
          >
            <div className="flex items-center justify-between mb-4">
              <div className={`${stat.color} p-3 rounded-lg`}>
                <stat.icon className="w-6 h-6" />
              </div>
            </div>
            <div>
              <div className="text-3xl text-gray-900 mb-1">{stat.value}</div>
              <div className="text-sm text-gray-600">{stat.title}</div>
            </div>
          </div>
        ))}
      </div>

      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {errorMessage}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 진행 중인 강좌 */}
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-blue-600" />
                <h3 className="text-gray-900">진행 중인 강좌</h3>
              </div>
              <button onClick={goToMyCourses} className="text-sm text-blue-600 hover:text-blue-700">
                전체보기
              </button>
            </div>
          </div>
          {loading ? (
            <div className="p-10 text-center text-gray-500">불러오는 중...</div>
          ) : ongoingCourses.length === 0 ? (
            <div className="p-10 text-center text-gray-500">진행 중인 과목이 없습니다.</div>
          ) : (
            <div className="divide-y divide-gray-200">
              {visibleOngoingCourses.map((course) => {
                const progress = Math.round(Number(course.avg_progress_ratio ?? 0));
                const students = Number(course.student_cnt ?? 0);
                const pendingHomework = Number(course.pending_homework_cnt ?? 0);
                const unansweredQna = Number(course.unanswered_qna_cnt ?? 0);

                return (
                  <button
                    key={course.id}
                    type="button"
                    onClick={() => openCourseFromDashboard({ courseId: course.id, courseName: course.course_nm, targetTab: 'attendance' })}
                    className="w-full text-left p-6 hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-start justify-between mb-3">
                      <div>
                        <h4 className="text-gray-900 mb-1">{course.course_nm}</h4>
                        <p className="text-sm text-gray-600">
                          {course.period_conv || '-'}
                        </p>
                      </div>
                      {(pendingHomework > 0 || unansweredQna > 0) && (
                        <div className="flex items-center gap-2">
                          {pendingHomework > 0 && (
                            <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">
                              미확인 과제 {pendingHomework}건
                            </span>
                          )}
                          {unansweredQna > 0 && (
                            <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs rounded-full">
                              미답변 Q&A {unansweredQna}건
                            </span>
                          )}
                        </div>
                      )}
                    </div>
                    <div className="flex items-center gap-4 text-sm text-gray-600 mb-3">
                      <span className="flex items-center gap-1">
                        <Users className="w-4 h-4" />
                        {students}명
                      </span>
                    </div>
                    <div className="space-y-1">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">평균 진도율</span>
                        <span className="text-gray-900">{progress}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div
                          className="bg-blue-600 h-2 rounded-full transition-all"
                          style={{ width: `${Math.min(100, Math.max(0, progress))}%` }}
                        />
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* 과제 목록 */}
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ClipboardCheck className="w-5 h-5 text-orange-600" />
                <h3 className="text-gray-900">과제 목록</h3>
              </div>
              <button onClick={goToMyCourses} className="text-sm text-blue-600 hover:text-blue-700">
                전체보기
              </button>
            </div>
          </div>
          {loading ? (
            <div className="p-10 text-center text-gray-500">불러오는 중...</div>
          ) : recentSubmissions.length === 0 ? (
            <div className="p-10 text-center text-gray-500">최근 제출된 과제가 없습니다.</div>
          ) : (
            <div className="divide-y divide-gray-200">
              {visibleRecentSubmissions.map((row) => {
                const confirmed = Boolean(row.confirmed);
                const studentLabel = `${row.user_nm || '-'} · ${row.course_nm}`;
                const submittedAt = row.submitted_at || '-';

                return (
                  <button
                    key={`${row.homework_id}-${row.course_user_id}`}
                    type="button"
                    onClick={() => openCourseFromDashboard({ courseId: row.course_id, courseName: row.course_nm, targetTab: 'assignment-feedback' })}
                    className="w-full text-left p-6 hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex-1">
                        <h4 className="text-gray-900 mb-1">{row.homework_nm}</h4>
                        <p className="text-sm text-gray-600 mb-1">{studentLabel}</p>
                      </div>
                      {!confirmed ? (
                        <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full whitespace-nowrap">
                          미확인
                        </span>
                      ) : (
                        <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded-full whitespace-nowrap">
                          확인완료
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-1 text-sm text-gray-500">
                      <Clock className="w-4 h-4" />
                      <span>{submittedAt}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* 최근 Q&A */}
      <div className="bg-white border border-gray-200 rounded-lg">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-purple-600" />
              <h3 className="text-gray-900">최근 Q&A</h3>
            </div>
            <button onClick={goToMyCourses} className="text-sm text-blue-600 hover:text-blue-700">
              전체보기
            </button>
          </div>
        </div>
        {loading ? (
          <div className="p-10 text-center text-gray-500">불러오는 중...</div>
        ) : recentQnas.length === 0 ? (
          <div className="p-10 text-center text-gray-500">최근 Q&A가 없습니다.</div>
        ) : (
          <div className="divide-y divide-gray-200">
            {visibleRecentQnas.map((qna) => (
              <button
                key={qna.post_id}
                type="button"
                onClick={() => openCourseFromDashboard({ courseId: qna.course_id, courseName: qna.course_nm, targetTab: 'qna' })}
                className="w-full text-left p-6 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <h4 className="text-gray-900 mb-1 line-clamp-1">{qna.subject}</h4>
                    <p className="text-sm text-gray-600 mb-1">
                      {qna.user_nm || '-'} · {qna.course_nm}
                    </p>
                  </div>
                  {!qna.answered ? (
                    <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs rounded-full whitespace-nowrap">
                      미답변
                    </span>
                  ) : (
                    <span className="px-2 py-1 bg-gray-100 text-gray-700 text-xs rounded-full whitespace-nowrap">
                      답변완료
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-1 text-sm text-gray-500">
                  <Clock className="w-4 h-4" />
                  <span>{qna.reg_date_conv || '-'}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
