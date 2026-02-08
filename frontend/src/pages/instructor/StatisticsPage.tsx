// src/pages/instructor/StatisticsPage.tsx
// 교수자 통계 - 담당 과목의 학습 현황과 성과 분석 대시보드

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Users,
  CalendarCheck,
  ClipboardCheck,
  Award,
} from 'lucide-react';

// ── 타입 정의 ──────────────────────────────────────────────

interface StatCardData {
  label: string;
  value: string;
  icon: React.ElementType;
  iconBg: string;
  iconColor: string;
}

interface CourseBar {
  name: string;
  count: number;
  percent: number;
}

interface MonthlyData {
  month: string;
  count: number;
}

interface CourseSummary {
  name: string;
  students: number;
  attendance: string;
  submission: string;
  avgScore: string;
  completionRate: string;
}

// ── Mock 데이터 ────────────────────────────────────────────

const statCards: StatCardData[] = [
  {
    label: '총 수강생',
    value: '156명',
    icon: Users,
    iconBg: 'bg-blue-100 dark:bg-blue-900/30',
    iconColor: 'text-blue-600 dark:text-blue-400',
  },
  {
    label: '평균 출석률',
    value: '87.3%',
    icon: CalendarCheck,
    iconBg: 'bg-green-100 dark:bg-green-900/30',
    iconColor: 'text-green-600 dark:text-green-400',
  },
  {
    label: '과제 제출률',
    value: '72.1%',
    icon: ClipboardCheck,
    iconBg: 'bg-orange-100 dark:bg-orange-900/30',
    iconColor: 'text-orange-600 dark:text-orange-400',
  },
  {
    label: '평균 성적',
    value: '81.5점',
    icon: Award,
    iconBg: 'bg-purple-100 dark:bg-purple-900/30',
    iconColor: 'text-purple-600 dark:text-purple-400',
  },
];

const courseBars: CourseBar[] = [
  { name: 'Python 프로그래밍', count: 45, percent: 90 },
  { name: '데이터베이스 설계', count: 38, percent: 76 },
  { name: '웹 개발 실무', count: 35, percent: 70 },
  { name: 'AI 기초', count: 28, percent: 56 },
  { name: '캡스톤 디자인', count: 10, percent: 20 },
];

const monthlyData: MonthlyData[] = [
  { month: '9월', count: 120 },
  { month: '10월', count: 135 },
  { month: '11월', count: 142 },
  { month: '12월', count: 128 },
  { month: '1월', count: 148 },
  { month: '2월', count: 156 },
];

const courseSummaries: CourseSummary[] = [
  {
    name: 'Python 프로그래밍',
    students: 45,
    attendance: '91.2%',
    submission: '78.5%',
    avgScore: '84.3점',
    completionRate: '88.9%',
  },
  {
    name: '데이터베이스 설계',
    students: 38,
    attendance: '85.7%',
    submission: '69.4%',
    avgScore: '79.1점',
    completionRate: '82.3%',
  },
  {
    name: '웹 개발 실무',
    students: 35,
    attendance: '88.1%',
    submission: '74.2%',
    avgScore: '81.7점',
    completionRate: '85.7%',
  },
];

// ── 월별 최대값 계산 (차트 높이 비율용) ─────────────────────

const maxMonthly = Math.max(...monthlyData.map((d) => d.count));

// ── 메인 컴포넌트 ─────────────────────────────────────────────

export default function StatisticsPage() {
  const { t } = useTranslation();
  const [period, setPeriod] = useState('이번 학기');

  return (
    <div className="space-y-8">
      {/* 페이지 타이틀 + 기간 선택 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            {t('instructor.statisticsTitle')}
          </h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t('instructor.statisticsDesc')}
          </p>
        </div>
        <select
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
          className="w-40 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
        >
          <option>이번 학기</option>
          <option>지난 학기</option>
          <option>전체 기간</option>
        </select>
      </div>

      {/* 통계 카드 4개 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <div
              key={card.label}
              className="bg-white dark:bg-gray-800 rounded-xl p-5 flex items-center gap-4 shadow-sm"
            >
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center ${card.iconBg}`}
              >
                <Icon className={`w-6 h-6 ${card.iconColor}`} />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {card.label}
                </p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {card.value}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      {/* 차트 섹션 2열 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 좌측: 과목별 수강생 현황 (수평 바 차트) */}
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
            과목별 수강생 현황
          </h2>
          <div className="space-y-4">
            {courseBars.map((course) => (
              <div key={course.name}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    {course.name}
                  </span>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {course.count}명
                  </span>
                </div>
                <div className="w-full h-3 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-blue-500 rounded-full transition-all duration-500"
                    style={{ width: `${course.percent}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 우측: 최근 6개월 수강생 추이 (세로 바 차트) */}
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
            최근 6개월 수강생 추이
          </h2>
          <div className="flex items-end justify-between gap-3 h-48">
            {monthlyData.map((data) => {
              const heightPercent = (data.count / maxMonthly) * 100;
              return (
                <div
                  key={data.month}
                  className="flex flex-col items-center flex-1"
                >
                  {/* 수치 라벨 */}
                  <span className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                    {data.count}
                  </span>
                  {/* 세로 바 */}
                  <div className="w-full flex justify-center" style={{ height: '160px' }}>
                    <div className="relative w-full max-w-[40px] h-full flex items-end">
                      <div
                        className="w-full bg-blue-500 rounded-t-md transition-all duration-500"
                        style={{ height: `${heightPercent}%` }}
                      />
                    </div>
                  </div>
                  {/* 월 라벨 */}
                  <span className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                    {data.month}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* 하단: 과목별 성과 요약 테이블 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
          과목별 성과 요약
        </h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="text-left py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  과목명
                </th>
                <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  수강생
                </th>
                <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  출석률
                </th>
                <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  과제제출률
                </th>
                <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  평균성적
                </th>
                <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  이수율
                </th>
              </tr>
            </thead>
            <tbody>
              {courseSummaries.map((course) => (
                <tr
                  key={course.name}
                  className="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors"
                >
                  <td className="py-3 px-4 text-sm font-medium text-gray-900 dark:text-white">
                    {course.name}
                  </td>
                  <td className="py-3 px-4 text-sm text-center text-gray-700 dark:text-gray-300">
                    {course.students}명
                  </td>
                  <td className="py-3 px-4 text-sm text-center">
                    <span className="font-medium text-green-600 dark:text-green-400">
                      {course.attendance}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-sm text-center">
                    <span className="font-medium text-orange-600 dark:text-orange-400">
                      {course.submission}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-sm text-center">
                    <span className="font-medium text-blue-600 dark:text-blue-400">
                      {course.avgScore}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-sm text-center">
                    <span className="font-medium text-purple-600 dark:text-purple-400">
                      {course.completionRate}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
