// src/pages/instructor/syllabus/SyllabusSubmitPage.tsx
// PRF-002: 강의계획서 제출 - 실라버스 + 커리큘럼 완성 확인 및 제출

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  Send,
  CheckCircle,
  Circle,
  FileText,
  Calendar,
  BookOpen,
  Users,
  ClipboardCheck,
  LayoutGrid,
  BarChart3,
  ArrowRight,
  RefreshCw,
  AlertCircle,
  Clock,
  Eye,
  Download,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

type SubmitStatus = '작성중' | '제출' | '승인대기' | '승인완료';

interface ChecklistItem {
  id: string;
  label: string;
  description: string;
  completed: boolean;
  icon: React.ElementType;
}

interface SyllabusSummary {
  courseName: string;
  semester: string;
  instructor: string;
  department: string;
  credit: number;
  targetGrade: string;
  totalWeeks: number;
  totalContents: number;
  totalDuration: string;
  evaluationMethod: { name: string; weight: number }[];
}

interface WeekPreview {
  week: number;
  topic: string;
  contents: number;
  duration: string;
}

// -- Mock 데이터 -------------------------------------------------------

const syllabusSummary: SyllabusSummary = {
  courseName: '파이썬 프로그래밍',
  semester: '2026-1학기',
  instructor: '김교수',
  department: '컴퓨터공학과',
  credit: 3,
  targetGrade: '2학년',
  totalWeeks: 15,
  totalContents: 42,
  totalDuration: '18시간 30분',
  evaluationMethod: [
    { name: '중간고사', weight: 30 },
    { name: '기말고사', weight: 30 },
    { name: '과제', weight: 20 },
    { name: '출석', weight: 10 },
    { name: '퀴즈', weight: 10 },
  ],
};

const weekPreviews: WeekPreview[] = [
  { week: 1, topic: '파이썬 소개 및 개발환경 구축', contents: 3, duration: '50분' },
  { week: 2, topic: '변수, 자료형, 입출력', contents: 3, duration: '50분' },
  { week: 3, topic: '조건문과 반복문', contents: 4, duration: '78분' },
  { week: 4, topic: '함수와 모듈', contents: 3, duration: '52분' },
  { week: 5, topic: '리스트와 딕셔너리', contents: 3, duration: '55분' },
  { week: 6, topic: '파일 입출력', contents: 3, duration: '45분' },
  { week: 7, topic: '객체지향 프로그래밍', contents: 4, duration: '65분' },
  { week: 8, topic: '중간고사', contents: 1, duration: '60분' },
  { week: 9, topic: '예외처리와 디버깅', contents: 3, duration: '48분' },
  { week: 10, topic: '정규표현식', contents: 3, duration: '50분' },
  { week: 11, topic: '웹 크롤링 기초', contents: 3, duration: '55분' },
  { week: 12, topic: '데이터 시각화', contents: 3, duration: '52분' },
  { week: 13, topic: 'API 활용', contents: 3, duration: '50분' },
  { week: 14, topic: '미니 프로젝트', contents: 2, duration: '90분' },
  { week: 15, topic: '기말고사 및 프로젝트 발표', contents: 2, duration: '90분' },
];

const initialChecklist: ChecklistItem[] = [
  {
    id: 'basic',
    label: '기본정보',
    description: '과목명, 학기, 학점, 담당교수 등 기본 정보 입력 완료',
    completed: true,
    icon: FileText,
  },
  {
    id: 'weekly',
    label: '주차별계획',
    description: '15주차 학습주제, 학습목표, 교수방법 작성 완료',
    completed: true,
    icon: Calendar,
  },
  {
    id: 'content',
    label: '콘텐츠배치',
    description: '주차별 영상, 문서, 퀴즈 콘텐츠 배치 완료',
    completed: true,
    icon: LayoutGrid,
  },
  {
    id: 'evaluation',
    label: '평가기준',
    description: '중간고사, 기말고사, 과제, 출석 등 평가 비율 설정 완료',
    completed: true,
    icon: BarChart3,
  },
];

// -- 상태 트래커 스텝 ---------------------------------------------------

const statusSteps: { key: SubmitStatus; label: string }[] = [
  { key: '작성중', label: '작성중' },
  { key: '제출', label: '제출' },
  { key: '승인대기', label: '승인대기' },
  { key: '승인완료', label: '승인완료' },
];

function getStepStatus(currentStatus: SubmitStatus, stepKey: SubmitStatus) {
  const order: SubmitStatus[] = ['작성중', '제출', '승인대기', '승인완료'];
  const currentIdx = order.indexOf(currentStatus);
  const stepIdx = order.indexOf(stepKey);
  if (stepIdx < currentIdx) return 'completed';
  if (stepIdx === currentIdx) return 'current';
  return 'pending';
}

// -- 메인 컴포넌트 -------------------------------------------------------

export default function SyllabusSubmitPage() {
  const { t } = useTranslation();
  const [status, setStatus] = useState<SubmitStatus>('승인대기');
  const [checklist] = useState(initialChecklist);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [syncStatus, setSyncStatus] = useState<'synced' | 'syncing' | 'pending'>('synced');

  const allChecked = checklist.every((c) => c.completed);
  const totalWeight = syllabusSummary.evaluationMethod.reduce((s, e) => s + e.weight, 0);

  const handleSubmit = () => {
    setShowConfirmModal(true);
  };

  const handleConfirmSubmit = () => {
    setStatus('승인대기');
    setShowConfirmModal(false);
  };

  const handleSync = () => {
    setSyncStatus('syncing');
    setTimeout(() => setSyncStatus('synced'), 2000);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center">
            <Send className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.syllabusSubmitTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.syllabusSubmitDesc')}
            </p>
          </div>
        </div>
        {/* 학사시스템 동기화 상태 */}
        <div className="flex items-center gap-2">
          <div className={`flex items-center gap-2 px-4 py-2 rounded-lg border text-sm ${
            syncStatus === 'synced'
              ? 'border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400'
              : syncStatus === 'syncing'
              ? 'border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400'
              : 'border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400'
          }`}>
            {syncStatus === 'synced' && <CheckCircle className="w-4 h-4" />}
            {syncStatus === 'syncing' && <RefreshCw className="w-4 h-4 animate-spin" />}
            {syncStatus === 'pending' && <AlertCircle className="w-4 h-4" />}
            <span className="font-medium">
              {syncStatus === 'synced' && '학사시스템 동기화 완료'}
              {syncStatus === 'syncing' && '동기화 중...'}
              {syncStatus === 'pending' && '동기화 대기'}
            </span>
          </div>
          <button
            onClick={handleSync}
            disabled={syncStatus === 'syncing'}
            className="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50 transition-colors"
            title="동기화 새로고침"
          >
            <RefreshCw className={`w-4 h-4 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* 상태 트래커 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
        <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-5">제출 진행 상태</h3>
        <div className="flex items-center justify-between">
          {statusSteps.map((step, idx) => {
            const stepStatus = getStepStatus(status, step.key);
            return (
              <div key={step.key} className="flex items-center flex-1">
                <div className="flex flex-col items-center">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center ${
                      stepStatus === 'completed'
                        ? 'bg-emerald-500 text-white'
                        : stepStatus === 'current'
                        ? 'bg-blue-500 text-white ring-4 ring-blue-100 dark:ring-blue-900/50'
                        : 'bg-gray-200 dark:bg-gray-700 text-gray-400 dark:text-gray-500'
                    }`}
                  >
                    {stepStatus === 'completed' ? (
                      <CheckCircle className="w-5 h-5" />
                    ) : stepStatus === 'current' ? (
                      <Clock className="w-5 h-5" />
                    ) : (
                      <Circle className="w-5 h-5" />
                    )}
                  </div>
                  <span
                    className={`mt-2 text-xs font-medium ${
                      stepStatus === 'completed'
                        ? 'text-emerald-600 dark:text-emerald-400'
                        : stepStatus === 'current'
                        ? 'text-blue-600 dark:text-blue-400'
                        : 'text-gray-400 dark:text-gray-500'
                    }`}
                  >
                    {step.label}
                  </span>
                </div>
                {idx < statusSteps.length - 1 && (
                  <div
                    className={`flex-1 h-0.5 mx-3 mt-[-1.25rem] ${
                      getStepStatus(status, statusSteps[idx + 1].key) !== 'pending'
                        ? 'bg-emerald-400'
                        : 'bg-gray-200 dark:bg-gray-700'
                    }`}
                  />
                )}
              </div>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 왼쪽: 체크리스트 + 기본 정보 */}
        <div className="lg:col-span-1 space-y-6">
          {/* 체크리스트 */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-4">제출 체크리스트</h3>
            <div className="space-y-3">
              {checklist.map((item) => {
                const Icon = item.icon;
                return (
                  <div
                    key={item.id}
                    className={`flex items-start gap-3 p-3 rounded-lg border transition-all ${
                      item.completed
                        ? 'border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20'
                        : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800'
                    }`}
                  >
                    {item.completed ? (
                      <CheckCircle className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                    ) : (
                      <Circle className="w-5 h-5 text-gray-300 dark:text-gray-600 shrink-0 mt-0.5" />
                    )}
                    <div>
                      <div className="flex items-center gap-2">
                        <Icon className="w-3.5 h-3.5 text-gray-400" />
                        <p className="text-sm font-medium text-gray-700 dark:text-gray-300">{item.label}</p>
                      </div>
                      <p className="text-xs text-gray-400 mt-0.5">{item.description}</p>
                    </div>
                  </div>
                );
              })}
            </div>
            {allChecked && (
              <div className="mt-4 p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg text-center">
                <p className="text-sm font-medium text-emerald-600 dark:text-emerald-400">
                  모든 항목이 완료되었습니다
                </p>
              </div>
            )}
          </div>

          {/* 기본 정보 요약 */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-4">기본 정보</h3>
            <div className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">과목명</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.courseName}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">학기</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.semester}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">담당교수</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.instructor}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">학과</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.department}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">학점</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.credit}학점</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">대상학년</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.targetGrade}</span>
              </div>
              <div className="h-px bg-gray-100 dark:bg-gray-700" />
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">총 콘텐츠</span>
                <span className="font-bold text-blue-600 dark:text-blue-400">{syllabusSummary.totalContents}개</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">총 학습시간</span>
                <span className="font-bold text-green-600 dark:text-green-400">{syllabusSummary.totalDuration}</span>
              </div>
            </div>
          </div>

          {/* 평가 기준 */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-4">평가 기준</h3>
            <div className="space-y-2">
              {syllabusSummary.evaluationMethod.map((e) => (
                <div key={e.name} className="flex items-center gap-3">
                  <div className="flex-1">
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-gray-600 dark:text-gray-400">{e.name}</span>
                      <span className="font-medium text-gray-700 dark:text-gray-300">{e.weight}%</span>
                    </div>
                    <div className="w-full h-2 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-500 rounded-full transition-all"
                        style={{ width: `${e.weight}%` }}
                      />
                    </div>
                  </div>
                </div>
              ))}
              <div className="flex justify-between text-sm pt-2 border-t border-gray-100 dark:border-gray-700">
                <span className="text-gray-400">합계</span>
                <span className={`font-bold ${totalWeight === 100 ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600'}`}>
                  {totalWeight}%
                  {totalWeight === 100 && <CheckCircle className="w-3.5 h-3.5 inline ml-1" />}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* 오른쪽: 미리보기 패널 */}
        <div className="lg:col-span-2">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-700/50">
              <h3 className="text-base font-semibold text-gray-900 dark:text-white">
                강의계획서 미리보기
              </h3>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowPreview(!showPreview)}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-600 dark:text-gray-400 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  <Eye className="w-3.5 h-3.5" />
                  {showPreview ? '테이블 보기' : '문서 미리보기'}
                </button>
                <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-600 dark:text-gray-400 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                  <Download className="w-3.5 h-3.5" />
                  PDF 다운로드
                </button>
              </div>
            </div>

            {showPreview ? (
              /* 문서 미리보기 */
              <div className="p-8 max-h-[700px] overflow-y-auto">
                <div className="max-w-2xl mx-auto space-y-6">
                  <div className="text-center pb-6 border-b border-gray-200 dark:border-gray-700">
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-1">
                      {syllabusSummary.semester} 강의계획서
                    </h2>
                    <p className="text-lg font-semibold text-blue-600 dark:text-blue-400">
                      {syllabusSummary.courseName}
                    </p>
                    <p className="text-sm text-gray-500 mt-2">
                      {syllabusSummary.department} | {syllabusSummary.instructor} 교수 | {syllabusSummary.credit}학점
                    </p>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-gray-700 dark:text-gray-300 mb-3">주차별 강의 계획</h4>
                    {weekPreviews.map((w) => (
                      <div key={w.week} className="flex items-start gap-4 py-2 border-b border-gray-100 dark:border-gray-700/50 last:border-0">
                        <span className="text-xs font-bold text-gray-400 w-12 pt-0.5">{w.week}주차</span>
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-700 dark:text-gray-300">{w.topic}</p>
                          <p className="text-xs text-gray-400 mt-0.5">{w.contents}개 콘텐츠 | {w.duration}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              /* 테이블 보기 */
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-gray-50 dark:bg-gray-700/30">
                      <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 w-16">주차</th>
                      <th className="text-left py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400">학습주제</th>
                      <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 w-24">콘텐츠</th>
                      <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 w-24">시간</th>
                      <th className="text-center py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 w-20">상태</th>
                    </tr>
                  </thead>
                  <tbody>
                    {weekPreviews.map((w) => (
                      <tr key={w.week} className="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors">
                        <td className="py-3 px-4 text-center">
                          <span className="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-xs font-bold">
                            {w.week}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-gray-700 dark:text-gray-300 font-medium">{w.topic}</td>
                        <td className="py-3 px-4 text-center text-gray-500 dark:text-gray-400">{w.contents}개</td>
                        <td className="py-3 px-4 text-center text-gray-500 dark:text-gray-400">{w.duration}</td>
                        <td className="py-3 px-4 text-center">
                          <CheckCircle className="w-4 h-4 text-emerald-500 mx-auto" />
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* 제출 버튼 영역 */}
          <div className="mt-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
            {status === '작성중' && (
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  모든 항목을 확인한 후 제출 버튼을 클릭하세요.
                </p>
                <button
                  onClick={handleSubmit}
                  disabled={!allChecked}
                  className="inline-flex items-center gap-2 px-6 py-3 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-colors shadow-sm"
                >
                  <Send className="w-4 h-4" />
                  강의계획서 제출
                </button>
              </div>
            )}
            {status === '제출' && (
              <div className="flex items-center gap-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <CheckCircle className="w-5 h-5 text-blue-500" />
                <div>
                  <p className="text-sm font-medium text-blue-700 dark:text-blue-400">
                    강의계획서가 제출되었습니다
                  </p>
                  <p className="text-xs text-blue-600 dark:text-blue-400 mt-0.5">
                    학과장 승인을 대기 중입니다.
                  </p>
                </div>
              </div>
            )}
            {status === '승인대기' && (
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                    <Clock className="w-5 h-5 text-amber-500" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900 dark:text-white">승인 대기 중</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      2026-02-08 14:30 제출 | 학과장 승인 대기
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="px-3 py-1.5 text-xs font-medium rounded-full bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
                    승인대기
                  </span>
                </div>
              </div>
            )}
            {status === '승인완료' && (
              <div className="flex items-center gap-3 p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
                <CheckCircle className="w-5 h-5 text-emerald-500" />
                <div>
                  <p className="text-sm font-medium text-emerald-700 dark:text-emerald-400">
                    강의계획서가 승인되었습니다
                  </p>
                  <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-0.5">
                    학사시스템에 동기화가 완료되었습니다.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* 제출 확인 모달 */}
      {showConfirmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowConfirmModal(false)} />
          <div className="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-md w-full p-6 space-y-5">
            <div className="text-center">
              <div className="w-14 h-14 mx-auto mb-4 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <Send className="w-7 h-7 text-blue-600 dark:text-blue-400" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                강의계획서를 제출하시겠습니까?
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
                제출 후에는 학과장의 승인이 필요하며, 승인 전까지 수정이 가능합니다.
              </p>
            </div>

            <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">과목명</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.courseName}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">학기</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.semester}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">총 콘텐츠</span>
                <span className="font-medium text-gray-700 dark:text-gray-300">{syllabusSummary.totalContents}개</span>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setShowConfirmModal(false)}
                className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              >
                {t('common.cancel')}
              </button>
              <button
                onClick={handleConfirmSubmit}
                className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors"
              >
                <Send className="w-4 h-4" />
                {t('common.submit')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
