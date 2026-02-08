// src/pages/instructor/DashboardPage.tsx
// 교수자 대시보드 - 담당 과목, 과제, Q&A 현황 종합 페이지

import { Link } from 'react-router-dom';
import {
  BookOpen,
  ClipboardCheck,
  MessageSquare,
  ChevronRight,
  Users,
  Clock,
  Star,
} from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { dataApi } from '@/services/api';
import { useTranslation } from '@/i18n';

// ── 타입 정의 ──────────────────────────────────────────────

interface StatCard {
  label: string;
  value: number;
  icon: React.ElementType;
  iconBg: string;
  iconColor: string;
}

interface Course {
  id: number;
  title: string;
  badge: '정규' | '비정규';
  studentCount: number;
  progress: number;
}

interface Assignment {
  id: number;
  title: string;
  courseName: string;
  dueDate: string;
  status: '제출완료' | '미제출';
}

interface QAItem {
  id: number;
  title: string;
  author: string;
  date: string;
  status: '답변완료' | '대기중';
}

// ── Mock 데이터 ────────────────────────────────────────────

const courses: Course[] = [
  {
    id: 1,
    title: 'Python 프로그래밍 기초',
    badge: '정규',
    studentCount: 35,
    progress: 65,
  },
  {
    id: 2,
    title: '데이터베이스 설계 및 실습',
    badge: '비정규',
    studentCount: 28,
    progress: 45,
  },
];

const assignments: Assignment[] = [
  {
    id: 1,
    title: '제3장 함수와 모듈 실습 과제',
    courseName: 'Python 프로그래밍 기초',
    dueDate: '2026-02-15',
    status: '제출완료',
  },
  {
    id: 2,
    title: 'ER 다이어그램 설계 과제',
    courseName: '데이터베이스 설계 및 실습',
    dueDate: '2026-02-20',
    status: '미제출',
  },
];

const qaItems: QAItem[] = [
  {
    id: 1,
    title: '리스트 컴프리헨션 관련 질문입니다',
    author: '박학생',
    date: '2026-02-07',
    status: '답변완료',
  },
  {
    id: 2,
    title: '정규화 3NF 판별 기준이 궁금합니다',
    author: '최학생',
    date: '2026-02-08',
    status: '대기중',
  },
];

// ── 배지 스타일 헬퍼 ──────────────────────────────────────

function badgeClass(type: string): string {
  switch (type) {
    case '정규':
      return 'bg-blue-100 text-blue-700';
    case '비정규':
      return 'bg-green-100 text-green-700';
    case '제출완료':
      return 'bg-emerald-100 text-emerald-700';
    case '미제출':
      return 'bg-red-100 text-red-700';
    case '답변완료':
      return 'bg-emerald-100 text-emerald-700';
    case '대기중':
      return 'bg-amber-100 text-amber-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

// ── 섹션 헤더 컴포넌트 ────────────────────────────────────

function SectionHeader({ title, linkTo }: { title: string; linkTo: string }) {
  const { t } = useTranslation();
  return (
    <div className="flex items-center justify-between mb-4">
      <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
        {title}
      </h2>
      <Link
        to={linkTo}
        className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 transition-colors"
      >
        {t('common.viewAll')}
        <ChevronRight className="w-4 h-4" />
      </Link>
    </div>
  );
}

// ── 메인 컴포넌트 ─────────────────────────────────────────

export default function DashboardPage() {
  const { data: examData } = useQuery({
    queryKey: ['instructor-exams'],
    queryFn: () => dataApi.getExamManagement().catch(() => null),
    staleTime: 60000,
    retry: false,
  });

  const { t } = useTranslation();

  const stats: StatCard[] = [
    {
      label: t('instructor.activeCourses'),
      value: 3,
      icon: BookOpen,
      iconBg: 'bg-blue-100',
      iconColor: 'text-blue-600',
    },
    {
      label: t('instructor.pendingAssignments'),
      value: 12,
      icon: ClipboardCheck,
      iconBg: 'bg-orange-100',
      iconColor: 'text-orange-600',
    },
    {
      label: t('instructor.unansweredQA'),
      value: 5,
      icon: MessageSquare,
      iconBg: 'bg-purple-100',
      iconColor: 'text-purple-600',
    },
  ];

  return (
    <div className="space-y-8">
      {/* 페이지 타이틀 */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {t('instructor.dashboardTitle')}
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {t('instructor.dashboardDesc')}
        </p>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.label}
              className="bg-white dark:bg-gray-800 rounded-xl p-5 flex items-center gap-4 shadow-sm"
            >
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center ${stat.iconBg}`}
              >
                <Icon className={`w-6 h-6 ${stat.iconColor}`} />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {stat.label}
                </p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stat.value}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      {/* 진행 중인 강좌 */}
      <section>
        <SectionHeader title={t('instructor.ongoingCourses')} linkTo="/instructor/my-courses" />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {courses.map((course) => (
            <div
              key={course.id}
              className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm space-y-4"
            >
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                    {course.title}
                  </h3>
                  <span
                    className={`mt-1 inline-block px-2 py-0.5 text-xs font-medium rounded-full ${badgeClass(course.badge)}`}
                  >
                    {course.badge}
                  </span>
                </div>
                <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400">
                  <Users className="w-3.5 h-3.5" />
                  <span>{course.studentCount}명</span>
                </div>
              </div>
              {/* 진도율 바 */}
              <div>
                <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
                  <span>{t('instructor.overallProgress')}</span>
                  <span className="font-medium">{course.progress}%</span>
                </div>
                <div className="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-blue-500 rounded-full transition-all"
                    style={{ width: `${course.progress}%` }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 과제 목록 */}
      <section>
        <SectionHeader title={t('instructor.assignmentList')} linkTo="/instructor/assignments" />
        <div className="space-y-3">
          {assignments.map((a) => (
            <div
              key={a.id}
              className="bg-white dark:bg-gray-800 rounded-xl p-4 flex items-center justify-between shadow-sm"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-orange-50 dark:bg-orange-900/20 flex items-center justify-center">
                  <ClipboardCheck className="w-5 h-5 text-orange-500" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {a.title}
                  </p>
                  <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                    <span>{a.courseName}</span>
                    <span className="inline-block w-1 h-1 rounded-full bg-gray-300" />
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {a.dueDate}
                    </span>
                  </div>
                </div>
              </div>
              <span
                className={`px-2.5 py-1 text-xs font-medium rounded-full ${badgeClass(a.status)}`}
              >
                {a.status}
              </span>
            </div>
          ))}
        </div>
      </section>

      {/* 최근 Q&A */}
      <section>
        <SectionHeader title={t('instructor.recentQA')} linkTo="/instructor/qna" />
        <div className="space-y-3">
          {qaItems.map((q) => (
            <div
              key={q.id}
              className="bg-white dark:bg-gray-800 rounded-xl p-4 flex items-center justify-between shadow-sm"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center">
                  <MessageSquare className="w-5 h-5 text-purple-500" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {q.title}
                  </p>
                  <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                    <span>{q.author}</span>
                    <span className="inline-block w-1 h-1 rounded-full bg-gray-300" />
                    <span>{q.date}</span>
                  </div>
                </div>
              </div>
              <span
                className={`px-2.5 py-1 text-xs font-medium rounded-full ${badgeClass(q.status)}`}
              >
                {q.status}
              </span>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
