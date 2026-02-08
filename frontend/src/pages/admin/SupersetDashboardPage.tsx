// pages/admin/SupersetDashboardPage.tsx — 기본 통계 및 현황 분석 (Apache Superset 연동)
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from '@/i18n';
import {
  BarChart3,
  Users,
  CheckCircle2,
  Clock,
  TrendingUp,
  ExternalLink,
  Loader2,
  AlertTriangle,
  Trophy,
  GraduationCap,
  Building2,
  CalendarDays,
  LinkIcon,
  LayoutDashboard,
  FileDown,
  Search,
  MousePointerClick,
} from 'lucide-react';
import api from '../../services/api';

/* ───────────────────── 타입 정의 ───────────────────── */

interface EnrollmentStats {
  totalEnrollments: number;
  activeEnrollments: number;
  completedEnrollments: number;
  withdrawnEnrollments: number;
  enrollmentRate: number;
  completionRate: number;
}

interface AttendanceStats {
  totalRecords: number;
  presentCount: number;
  lateCount: number;
  absentCount: number;
  attendanceRate: number;
  avgAttendanceRate: number;
}

interface CompletionStats {
  totalCourses: number;
  completedCourses: number;
  inProgressCourses: number;
  notStartedCourses: number;
  avgProgressPercent: number;
  avgCompletionDays: number;
}

interface CourseRanking {
  courseId: number;
  courseTitle: string;
  enrolledCount: number;
  completedCount: number;
  completionRate: number;
  avgScore: number;
}

interface MonthlyTrend {
  month: string;
  enrollmentCount: number;
  completionCount: number;
  newUserCount: number;
}

interface DepartmentStat {
  department: string;
  studentCount: number;
  courseCount: number;
  enrollmentCount: number;
  completionRate: number;
}

interface DashboardSummary {
  enrollmentStats: EnrollmentStats;
  attendanceStats: AttendanceStats;
  completionStats: CompletionStats;
  courseRankings: CourseRanking[];
  monthlyTrends: MonthlyTrend[];
  departmentStats: DepartmentStat[];
  supersetDashboardUrl: string;
}

/* ───────────────────── 유틸 함수 ───────────────────── */

/** 숫자 포맷 (1,234) */
function fmt(n: number): string {
  return n.toLocaleString('ko-KR');
}

/** 퍼센트 포맷 */
function pct(n: number): string {
  return `${n.toFixed(1)}%`;
}

/* ───────────────────── 서브 컴포넌트 ───────────────────── */

/** KPI 요약 카드 */
function KpiCard({
  label,
  value,
  suffix,
  icon: Icon,
  color,
}: {
  label: string;
  value: string;
  suffix?: string;
  icon: React.ElementType;
  color: 'blue' | 'green' | 'purple' | 'orange';
}) {
  const colorMap = {
    blue: {
      bg: 'bg-blue-500/10',
      border: 'border-blue-500/30',
      icon: 'text-blue-400',
      value: 'text-blue-400',
    },
    green: {
      bg: 'bg-emerald-500/10',
      border: 'border-emerald-500/30',
      icon: 'text-emerald-400',
      value: 'text-emerald-400',
    },
    purple: {
      bg: 'bg-purple-500/10',
      border: 'border-purple-500/30',
      icon: 'text-purple-400',
      value: 'text-purple-400',
    },
    orange: {
      bg: 'bg-orange-500/10',
      border: 'border-orange-500/30',
      icon: 'text-orange-400',
      value: 'text-orange-400',
    },
  };
  const c = colorMap[color];

  return (
    <div
      className={`${c.bg} border ${c.border} rounded-xl p-5 transition-all duration-300 hover:scale-[1.02] hover:shadow-lg`}
    >
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-medium text-gray-400">{label}</span>
        <Icon className={`w-5 h-5 ${c.icon}`} />
      </div>
      <div className="flex items-end gap-1">
        <span className={`text-2xl font-bold ${c.value}`}>{value}</span>
        {suffix && <span className="text-sm text-gray-500 mb-0.5">{suffix}</span>}
      </div>
    </div>
  );
}

/** 출결 현황 도넛 링 */
function AttendanceRing({ rate }: { rate: number }) {
  const radius = 54;
  const circumference = 2 * Math.PI * radius;
  const filled = (rate / 100) * circumference;

  return (
    <svg width="140" height="140" viewBox="0 0 140 140">
      {/* 배경 링 */}
      <circle
        cx="70"
        cy="70"
        r={radius}
        fill="none"
        stroke="#374151"
        strokeWidth="12"
      />
      {/* 값 링 */}
      <circle
        cx="70"
        cy="70"
        r={radius}
        fill="none"
        stroke="#a78bfa"
        strokeWidth="12"
        strokeLinecap="round"
        strokeDasharray={`${filled} ${circumference}`}
        strokeDashoffset={circumference * 0.25}
        className="transition-all duration-1000 ease-out"
      />
      {/* 중앙 텍스트 */}
      <text
        x="70"
        y="65"
        textAnchor="middle"
        className="fill-white font-bold"
        fontSize="22"
      >
        {rate.toFixed(1)}%
      </text>
      <text
        x="70"
        y="85"
        textAnchor="middle"
        className="fill-gray-400"
        fontSize="11"
      >
        출석률
      </text>
    </svg>
  );
}

/** 섹션 헤더 */
function SectionHeader({
  icon: Icon,
  title,
  color,
}: {
  icon: React.ElementType;
  title: string;
  color: string;
}) {
  return (
    <div className={`flex items-center gap-2 border-l-4 ${color} pl-3 mb-5`}>
      <Icon className="w-5 h-5 text-gray-300" />
      <h2 className="text-base font-semibold text-white">{title}</h2>
    </div>
  );
}

/** 순위 메달 */
function RankBadge({ rank }: { rank: number }) {
  if (rank === 1) return <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-yellow-500/20 text-yellow-400 font-bold text-xs">1</span>;
  if (rank === 2) return <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-gray-400/20 text-gray-300 font-bold text-xs">2</span>;
  if (rank === 3) return <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-amber-700/20 text-amber-600 font-bold text-xs">3</span>;
  return <span className="inline-flex items-center justify-center w-7 h-7 text-gray-500 font-medium text-xs">{rank}</span>;
}

/* ───────────────────── 메인 컴포넌트 ───────────────────── */

export default function SupersetDashboardPage() {
  const { t } = useTranslation();
  const {
    data: dashboard,
    isLoading,
    isError,
    error,
  } = useQuery<DashboardSummary>({
    queryKey: ['statistics-dashboard'],
    queryFn: async () => {
      const res = await api.get('/statistics/dashboard');
      return res.data.data ?? res.data;
    },
    staleTime: 60_000,
    retry: 2,
  });

  /* ── 로딩 상태 ── */
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-10 h-10 text-blue-400 animate-spin" />
          <p className="text-gray-400 text-sm">{t('common.loading')}</p>
        </div>
      </div>
    );
  }

  /* ── 에러 상태 ── */
  if (isError || !dashboard) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="bg-gray-800 rounded-xl p-8 max-w-md text-center space-y-4">
          <AlertTriangle className="w-12 h-12 text-red-400 mx-auto" />
          <h2 className="text-lg font-bold text-white">데이터 로드 실패</h2>
          <p className="text-sm text-gray-400">
            통계 대시보드 데이터를 불러오는 데 실패했습니다.
            <br />
            {(error as Error)?.message ?? '잠시 후 다시 시도해 주세요.'}
          </p>
          <button
            onClick={() => window.location.reload()}
            className="px-5 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium transition-colors"
          >
            새로고침
          </button>
        </div>
      </div>
    );
  }

  const {
    enrollmentStats,
    attendanceStats,
    completionStats,
    courseRankings,
    monthlyTrends,
    departmentStats,
    supersetDashboardUrl,
  } = dashboard;

  /* ── 수강 현황 바 데이터 ── */
  const notStarted =
    enrollmentStats.totalEnrollments -
    enrollmentStats.activeEnrollments -
    enrollmentStats.completedEnrollments -
    enrollmentStats.withdrawnEnrollments;
  const enrollmentBars = [
    { label: '수강중', count: enrollmentStats.activeEnrollments, color: 'bg-blue-500' },
    { label: '이수완료', count: enrollmentStats.completedEnrollments, color: 'bg-emerald-500' },
    { label: '미시작', count: Math.max(notStarted, 0), color: 'bg-gray-500' },
    { label: '수강철회', count: enrollmentStats.withdrawnEnrollments, color: 'bg-red-500' },
  ];
  const maxEnrollmentBar = Math.max(...enrollmentBars.map((b) => b.count), 1);

  /* ── 월별 추이 바 차트 최대값 ── */
  const maxMonthlyValue = Math.max(
    ...monthlyTrends.flatMap((m) => [m.enrollmentCount, m.completionCount, m.newUserCount]),
    1,
  );

  /* ── 과정 순위 Top 10 ── */
  const topCourses = [...courseRankings]
    .sort((a, b) => b.enrolledCount - a.enrolledCount)
    .slice(0, 10);

  /* ── 학과별 통계 정렬 ── */
  const sortedDepartments = [...departmentStats].sort(
    (a, b) => b.studentCount - a.studentCount,
  );

  return (
    <div className="min-h-screen bg-gray-900 text-white p-6 space-y-8">
      {/* ═══════════════ 1. 헤더 ═══════════════ */}
      <header className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            {t('admin.supersetTitle')}
          </h1>
          <p className="text-sm text-gray-400 mt-1">
            Apache Superset 연동 데이터 시각화 대시보드
          </p>
        </div>
        <a
          href={supersetDashboardUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium transition-colors whitespace-nowrap"
        >
          <ExternalLink className="w-4 h-4" />
          Superset 대시보드 열기
        </a>
      </header>

      {/* ═══════════════ 2. KPI 요약 카드 ═══════════════ */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard
          label="총 수강 건수"
          value={fmt(enrollmentStats.totalEnrollments)}
          icon={Users}
          color="blue"
        />
        <KpiCard
          label="이수 완료율"
          value={pct(enrollmentStats.completionRate)}
          icon={CheckCircle2}
          color="green"
        />
        <KpiCard
          label="출석률"
          value={pct(attendanceStats.attendanceRate)}
          icon={Clock}
          color="purple"
        />
        <KpiCard
          label="평균 진도율"
          value={pct(completionStats.avgProgressPercent)}
          icon={TrendingUp}
          color="orange"
        />
      </section>

      {/* ═══════════════ 3. 수강 현황 분석 ═══════════════ */}
      <section className="bg-gray-800 rounded-xl p-6">
        <SectionHeader icon={BarChart3} title="수강 현황 분석" color="border-blue-500" />
        <div className="space-y-4">
          {enrollmentBars.map((bar) => {
            const widthPct = (bar.count / maxEnrollmentBar) * 100;
            return (
              <div key={bar.label} className="space-y-1.5">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-300">{bar.label}</span>
                  <span className="text-gray-400 font-medium">{fmt(bar.count)}명</span>
                </div>
                <div className="w-full h-6 bg-gray-700 rounded-full overflow-hidden">
                  <div
                    className={`h-full ${bar.color} rounded-full transition-all duration-700 ease-out flex items-center justify-end pr-2`}
                    style={{ width: `${Math.max(widthPct, 2)}%` }}
                  >
                    {widthPct > 10 && (
                      <span className="text-[10px] text-white font-medium">
                        {((bar.count / Math.max(enrollmentStats.totalEnrollments, 1)) * 100).toFixed(1)}%
                      </span>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ═══════════════ 4 & 5. 출결 현황 + 이수 현황 ═══════════════ */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ── 4. 출결 현황 ── */}
        <section className="bg-gray-800 rounded-xl p-6">
          <SectionHeader icon={Clock} title="출결 현황" color="border-purple-500" />
          <div className="flex flex-col items-center gap-6">
            <AttendanceRing rate={attendanceStats.attendanceRate} />
            <div className="grid grid-cols-3 gap-6 w-full max-w-xs text-center">
              {[
                { label: '출석', count: attendanceStats.presentCount, dot: 'bg-emerald-400' },
                { label: '지각', count: attendanceStats.lateCount, dot: 'bg-yellow-400' },
                { label: '결석', count: attendanceStats.absentCount, dot: 'bg-red-400' },
              ].map((item) => (
                <div key={item.label} className="flex flex-col items-center gap-1">
                  <span className={`w-3 h-3 rounded-full ${item.dot}`} />
                  <span className="text-xs text-gray-400">{item.label}</span>
                  <span className="text-sm font-bold text-white">{fmt(item.count)}</span>
                </div>
              ))}
            </div>
            <p className="text-xs text-gray-500">
              총 출결 기록: {fmt(attendanceStats.totalRecords)}건 | 평균 출석률: {pct(attendanceStats.avgAttendanceRate)}
            </p>
          </div>
        </section>

        {/* ── 5. 이수 현황 ── */}
        <section className="bg-gray-800 rounded-xl p-6">
          <SectionHeader icon={GraduationCap} title="이수 현황" color="border-emerald-500" />
          <div className="space-y-5">
            {[
              {
                label: '이수 완료 과정',
                value: completionStats.completedCourses,
                total: completionStats.totalCourses,
                color: 'bg-emerald-500',
              },
              {
                label: '수강 중 과정',
                value: completionStats.inProgressCourses,
                total: completionStats.totalCourses,
                color: 'bg-blue-500',
              },
              {
                label: '미시작 과정',
                value: completionStats.notStartedCourses,
                total: completionStats.totalCourses,
                color: 'bg-gray-500',
              },
            ].map((item) => {
              const ratio = completionStats.totalCourses > 0
                ? (item.value / completionStats.totalCourses) * 100
                : 0;
              return (
                <div key={item.label} className="space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-300">{item.label}</span>
                    <span className="text-gray-400">
                      {fmt(item.value)} / {fmt(item.total)}
                    </span>
                  </div>
                  <div className="w-full h-3 bg-gray-700 rounded-full overflow-hidden">
                    <div
                      className={`h-full ${item.color} rounded-full transition-all duration-700 ease-out`}
                      style={{ width: `${Math.max(ratio, 1)}%` }}
                    />
                  </div>
                </div>
              );
            })}
            {/* 평균 이수 소요일 */}
            <div className="mt-4 p-4 bg-gray-700/50 rounded-lg flex items-center justify-between">
              <span className="text-sm text-gray-300">평균 이수 소요일</span>
              <div className="flex items-end gap-1">
                <span className="text-2xl font-bold text-emerald-400">
                  {completionStats.avgCompletionDays}
                </span>
                <span className="text-sm text-gray-500 mb-0.5">일</span>
              </div>
            </div>
          </div>
        </section>
      </div>

      {/* ═══════════════ 6. 과정별 순위 (Top 10) ═══════════════ */}
      <section className="bg-gray-800 rounded-xl p-6">
        <SectionHeader icon={Trophy} title="과정별 순위 (Top 10)" color="border-yellow-500" />
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-700">
                <th className="text-left py-3 px-3 text-gray-400 font-medium w-16">순위</th>
                <th className="text-left py-3 px-3 text-gray-400 font-medium">과정명</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">수강인원</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">이수인원</th>
                <th className="text-left py-3 px-3 text-gray-400 font-medium w-44">이수율</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">평균점수</th>
              </tr>
            </thead>
            <tbody>
              {topCourses.map((course, idx) => {
                const rank = idx + 1;
                const rowBg =
                  rank === 1
                    ? 'bg-yellow-500/5'
                    : rank === 2
                      ? 'bg-gray-400/5'
                      : rank === 3
                        ? 'bg-amber-700/5'
                        : '';
                return (
                  <tr
                    key={course.courseId}
                    className={`border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors ${rowBg}`}
                  >
                    <td className="py-3 px-3">
                      <RankBadge rank={rank} />
                    </td>
                    <td className="py-3 px-3 text-gray-200 font-medium">
                      {course.courseTitle}
                    </td>
                    <td className="py-3 px-3 text-center text-gray-300">
                      {fmt(course.enrolledCount)}
                    </td>
                    <td className="py-3 px-3 text-center text-gray-300">
                      {fmt(course.completedCount)}
                    </td>
                    <td className="py-3 px-3">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2 bg-gray-700 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                            style={{ width: `${Math.min(course.completionRate, 100)}%` }}
                          />
                        </div>
                        <span className="text-xs text-emerald-400 font-medium w-12 text-right">
                          {pct(course.completionRate)}
                        </span>
                      </div>
                    </td>
                    <td className="py-3 px-3 text-center font-medium text-gray-200">
                      {course.avgScore.toFixed(1)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      {/* ═══════════════ 7. 월별 추이 ═══════════════ */}
      <section className="bg-gray-800 rounded-xl p-6">
        <SectionHeader icon={CalendarDays} title="월별 추이" color="border-indigo-500" />
        {/* 범례 */}
        <div className="flex items-center gap-5 mb-5 text-xs">
          {[
            { label: '수강신청', color: 'bg-blue-500' },
            { label: '이수완료', color: 'bg-emerald-500' },
            { label: '신규사용자', color: 'bg-purple-500' },
          ].map((leg) => (
            <div key={leg.label} className="flex items-center gap-1.5">
              <span className={`w-3 h-3 rounded-sm ${leg.color}`} />
              <span className="text-gray-400">{leg.label}</span>
            </div>
          ))}
        </div>
        {/* 바 차트 */}
        <div className="overflow-x-auto">
          <div className="flex items-end gap-3 min-w-[600px] h-56 pb-8 relative">
            {/* Y축 가이드 */}
            {[0, 0.25, 0.5, 0.75, 1].map((ratio) => (
              <div
                key={ratio}
                className="absolute left-0 right-0 border-t border-gray-700/50"
                style={{ bottom: `${ratio * 100 * 0.78 + 14}%` }}
              >
                <span className="absolute -left-1 -top-2.5 text-[10px] text-gray-600">
                  {Math.round(maxMonthlyValue * ratio)}
                </span>
              </div>
            ))}
            {monthlyTrends.map((m) => {
              const h1 = (m.enrollmentCount / maxMonthlyValue) * 180;
              const h2 = (m.completionCount / maxMonthlyValue) * 180;
              const h3 = (m.newUserCount / maxMonthlyValue) * 180;
              return (
                <div key={m.month} className="flex-1 flex flex-col items-center gap-1">
                  <div className="flex items-end gap-1 h-[180px]">
                    <div
                      className="w-5 bg-blue-500 rounded-t transition-all duration-500 hover:bg-blue-400"
                      style={{ height: `${Math.max(h1, 2)}px` }}
                      title={`수강신청: ${fmt(m.enrollmentCount)}`}
                    />
                    <div
                      className="w-5 bg-emerald-500 rounded-t transition-all duration-500 hover:bg-emerald-400"
                      style={{ height: `${Math.max(h2, 2)}px` }}
                      title={`이수완료: ${fmt(m.completionCount)}`}
                    />
                    <div
                      className="w-5 bg-purple-500 rounded-t transition-all duration-500 hover:bg-purple-400"
                      style={{ height: `${Math.max(h3, 2)}px` }}
                      title={`신규사용자: ${fmt(m.newUserCount)}`}
                    />
                  </div>
                  <span className="text-[10px] text-gray-500 mt-1">{m.month}</span>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ═══════════════ 8. 학과별 통계 ═══════════════ */}
      <section className="bg-gray-800 rounded-xl p-6">
        <SectionHeader icon={Building2} title="학과별 통계" color="border-cyan-500" />
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-700">
                <th className="text-left py-3 px-3 text-gray-400 font-medium">학과</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">학생 수</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">과정 수</th>
                <th className="text-center py-3 px-3 text-gray-400 font-medium">수강 건수</th>
                <th className="text-left py-3 px-3 text-gray-400 font-medium w-52">이수율</th>
              </tr>
            </thead>
            <tbody>
              {sortedDepartments.map((dept) => (
                <tr
                  key={dept.department}
                  className="border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors"
                >
                  <td className="py-3 px-3 text-gray-200 font-medium">{dept.department}</td>
                  <td className="py-3 px-3 text-center text-gray-300">{fmt(dept.studentCount)}</td>
                  <td className="py-3 px-3 text-center text-gray-300">{fmt(dept.courseCount)}</td>
                  <td className="py-3 px-3 text-center text-gray-300">{fmt(dept.enrollmentCount)}</td>
                  <td className="py-3 px-3">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-2 bg-gray-700 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-cyan-500 rounded-full transition-all duration-500"
                          style={{ width: `${Math.min(dept.completionRate, 100)}%` }}
                        />
                      </div>
                      <span className="text-xs text-cyan-400 font-medium w-12 text-right">
                        {pct(dept.completionRate)}
                      </span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* ═══════════════ 9. Apache Superset 연동 ═══════════════ */}
      <section className="bg-gray-800 rounded-xl p-6">
        <SectionHeader icon={LayoutDashboard} title="Apache Superset 연동" color="border-rose-500" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* 왼쪽: 설명 및 기능 */}
          <div className="space-y-5">
            <p className="text-sm text-gray-300 leading-relaxed">
              Apache Superset를 통한 고급 분석 및 시각화를 제공합니다.
              실시간으로 연동된 LMS 데이터를 기반으로 다양한 커스텀 차트와
              대시보드를 생성하고 분석할 수 있습니다.
            </p>
            <div className="flex items-center gap-2 text-xs bg-gray-700/50 rounded-lg p-3">
              <LinkIcon className="w-4 h-4 text-gray-400 flex-shrink-0" />
              <span className="text-gray-400 truncate">{supersetDashboardUrl}</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                { icon: TrendingUp, label: '실시간 데이터 연동', desc: 'LMS 데이터 실시간 반영' },
                { icon: LayoutDashboard, label: '커스텀 대시보드', desc: '맞춤형 시각화 생성' },
                { icon: Search, label: '드릴다운 분석', desc: '세부 데이터 탐색 가능' },
                { icon: FileDown, label: 'PDF/Excel 내보내기', desc: '보고서 자동 생성' },
              ].map((feat) => (
                <div
                  key={feat.label}
                  className="flex items-start gap-3 p-3 bg-gray-700/30 rounded-lg hover:bg-gray-700/50 transition-colors"
                >
                  <feat.icon className="w-5 h-5 text-rose-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-gray-200">{feat.label}</p>
                    <p className="text-[11px] text-gray-500">{feat.desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <a
              href={supersetDashboardUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-sm font-medium transition-colors"
            >
              <MousePointerClick className="w-4 h-4" />
              Superset 대시보드 열기
            </a>
          </div>

          {/* 오른쪽: iframe 미리보기 */}
          <div className="relative rounded-lg overflow-hidden border border-gray-700 bg-gray-900 min-h-[320px]">
            <iframe
              src={supersetDashboardUrl}
              title="Apache Superset Dashboard"
              className="w-full h-full min-h-[320px] border-0"
              sandbox="allow-scripts allow-same-origin allow-popups"
              loading="lazy"
            />
            {/* iframe 로드 실패 시 대체 오버레이 */}
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-900/80 opacity-0 hover:opacity-100 transition-opacity duration-300">
              <LayoutDashboard className="w-10 h-10 text-gray-500 mb-3" />
              <p className="text-sm text-gray-400">
                대시보드가 표시되지 않으면
              </p>
              <a
                href={supersetDashboardUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-rose-400 hover:text-rose-300 underline mt-1"
              >
                새 탭에서 열기
              </a>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
