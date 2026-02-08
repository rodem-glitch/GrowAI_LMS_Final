// demo.tsx - 중간점검 랜딩페이지 (Mid-Check Home)
// 한국폴리텍대학 LMS 고도화 프로젝트 중간점검 현황
// 레퍼런스: Dashboard.tsx, AttendanceTab.tsx 패턴 적용

import React, { useMemo, useState } from 'react';
import {
  Calendar,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Clock,
  AlertCircle,
  FileText,
  Users,
  Database,
  Shield,
  GraduationCap,
  ClipboardCheck,
  MessageSquare,
  BarChart3,
  Loader2,
  Search,
  Filter,
  Target,
  TrendingUp,
  Lock,
  RefreshCw,
  BookOpen,
} from 'lucide-react';

/**
 * 중간점검 항목 데이터 타입
 */
interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

interface CheckItem {
  id: number;
  category: string;
  categoryIcon: React.ElementType;
  title: string;
  description: string;
  status: 'completed' | 'in-progress' | 'pending' | 'blocked';
  priority: 'high' | 'medium' | 'low';
  progress: number;
  notes: string;
  assignee: string;
  dueDate: string;
  subTasks?: SubTask[];
  relatedApis?: string[];
  relatedFiles?: string[];
}

/**
 * 8개 중간점검 항목 데이터
 */
const checkItems: CheckItem[] = [
  {
    id: 1,
    category: '출결관리',
    categoryIcon: ClipboardCheck,
    title: '차시마다 유효기간 설정 (출결)',
    description: '각 강의 차시별로 출결 인정 유효기간을 설정하여 학습 기간 내에만 출석이 인정되도록 구현',
    status: 'in-progress',
    priority: 'high',
    progress: 65,
    notes: '차시별 시작일/종료일 설정, 유효기간 초과 시 출석 불인정 처리. 학사 과목은 주차/차시 기준으로 출석 판정.',
    assignee: 'Backend Team',
    dueDate: '2026-02-15',
    subTasks: [
      { id: '1-1', title: '차시별 유효기간 DB 스키마 설계', completed: true },
      { id: '1-2', title: '차시 유효기간 설정 API 개발', completed: true },
      { id: '1-3', title: '출결 판정 로직 수정', completed: true },
      { id: '1-4', title: '관리자 UI 개발', completed: false },
      { id: '1-5', title: '학습자 출결 현황 표시', completed: false },
    ],
    relatedApis: ['/api/v1/attendance/sessions/{sessionId}/validity', '/api/v1/attendance/check'],
    relatedFiles: ['AttendanceTab.tsx', 'HaksaAttendanceService.java'],
  },
  {
    id: 2,
    category: '학사연동',
    categoryIcon: GraduationCap,
    title: '학사포털 강좌 계획서 연동',
    description: '학사포털 시스템에서 강좌 계획서(Syllabus) 데이터를 자동으로 불러오는 기능 구현',
    status: 'pending',
    priority: 'high',
    progress: 20,
    notes: '학사포털 API 연동 필요, 강좌 계획서 스키마 확인 필요. 주차별 학습 내용, 평가방법, 참고자료 포함.',
    assignee: 'Integration Team',
    dueDate: '2026-02-20',
    subTasks: [
      { id: '2-1', title: '학사포털 API 스펙 확인', completed: true },
      { id: '2-2', title: '강좌 계획서 데이터 매핑', completed: false },
      { id: '2-3', title: 'API 연동 개발', completed: false },
      { id: '2-4', title: '동기화 스케줄러 구현', completed: false },
    ],
    relatedApis: ['/api/v1/haksa/syllabus/{courseCode}', '/api/v1/courses/{id}/syllabus'],
    relatedFiles: ['HaksaSyllabusService.java', 'CourseInfoTabs.tsx'],
  },
  {
    id: 3,
    category: '학사연동',
    categoryIcon: RefreshCw,
    title: '학사포털 개설정보 연동',
    description: '학사포털에서 과목 개설정보(교과목, 담당교수, 분반 등)를 실시간으로 가져오는 기능 확인',
    status: 'in-progress',
    priority: 'high',
    progress: 75,
    notes: '현재 부분 연동 중, 실시간 동기화 구현 필요. 분반코드, 그룹코드 매핑 완료.',
    assignee: 'Integration Team',
    dueDate: '2026-02-18',
    subTasks: [
      { id: '3-1', title: '개설정보 API 연동', completed: true },
      { id: '3-2', title: '과목-분반 매핑 로직', completed: true },
      { id: '3-3', title: '담당교수 정보 동기화', completed: true },
      { id: '3-4', title: '실시간 동기화 구현', completed: false },
    ],
    relatedApis: ['/api/v1/haksa/courses', '/api/v1/haksa/resolve'],
    relatedFiles: ['tutorLmsApi.ts', 'HaksaCourseService.java'],
  },
  {
    id: 4,
    category: '보안',
    categoryIcon: Shield,
    title: '대리출석 방지 방안',
    description: '본인 인증 및 부정행위 방지를 위한 다중 인증 방안 구현',
    status: 'in-progress',
    priority: 'high',
    progress: 55,
    notes: '얼굴 인식, IP 기반 검증, 기기 바인딩, 세션 동시 접속 제한 등 복합 적용. Google Identity Platform 연동.',
    assignee: 'Security Team',
    dueDate: '2026-02-25',
    subTasks: [
      { id: '4-1', title: '세션 동시 접속 제한', completed: true },
      { id: '4-2', title: 'IP 기반 접속 검증', completed: true },
      { id: '4-3', title: '기기 바인딩 구현', completed: false },
      { id: '4-4', title: '얼굴 인식 연동', completed: false },
      { id: '4-5', title: '부정행위 탐지 로직', completed: false },
    ],
    relatedApis: ['/api/v1/auth/session', '/api/v1/security/device-binding'],
    relatedFiles: ['SessionManagementService.java', 'SecurityAgent.java'],
  },
  {
    id: 5,
    category: '성적관리',
    categoryIcon: BarChart3,
    title: '성적 등록 뷰테이블 생성',
    description: '성적 조회 및 등록을 위한 최적화된 뷰테이블 설계 및 생성',
    status: 'pending',
    priority: 'medium',
    progress: 10,
    notes: '과제, 시험, 출석, 참여도 등 항목별 점수 집계 뷰. 실시간 성적 현황 조회 최적화.',
    assignee: 'Database Team',
    dueDate: '2026-02-22',
    subTasks: [
      { id: '5-1', title: '성적 집계 쿼리 설계', completed: true },
      { id: '5-2', title: '뷰테이블 생성', completed: false },
      { id: '5-3', title: '인덱스 최적화', completed: false },
      { id: '5-4', title: '조회 API 개발', completed: false },
    ],
    relatedApis: ['/api/v1/grades/summary', '/api/v1/grades/register'],
    relatedFiles: ['GradeService.java', 'V_GRADE_SUMMARY.sql'],
  },
  {
    id: 6,
    category: '학습관리',
    categoryIcon: MessageSquare,
    title: '과제 및 Q&A 피드백 일괄 출력',
    description: '학생별 과제 제출 현황 및 Q&A 질의응답 피드백을 한번에 출력하는 기능',
    status: 'pending',
    priority: 'medium',
    progress: 5,
    notes: '교수자용 일괄 출력 기능, PDF/Excel 내보내기 지원. 학생별, 과목별 피드백 통합 조회.',
    assignee: 'Frontend Team',
    dueDate: '2026-02-28',
    subTasks: [
      { id: '6-1', title: '피드백 데이터 통합 API', completed: false },
      { id: '6-2', title: 'PDF 출력 템플릿 설계', completed: false },
      { id: '6-3', title: 'Excel 내보내기 구현', completed: false },
      { id: '6-4', title: '일괄 출력 UI 개발', completed: false },
    ],
    relatedApis: ['/api/v1/feedback/export', '/api/v1/feedback/summary'],
    relatedFiles: ['CourseFeedbackReportPage.tsx', 'FeedbackExportService.java'],
  },
  {
    id: 7,
    category: '성적관리',
    categoryIcon: Lock,
    title: '성적 기준 수정 제한',
    description: '종합정보시스템의 성적 기준에 맞춰 LMS 내 성적 기준 수정을 불가능하게 설정',
    status: 'completed',
    priority: 'high',
    progress: 100,
    notes: '종합정보시스템에서 정의된 성적 기준만 사용, LMS에서는 읽기 전용으로 처리. 관리자 권한으로도 수정 불가.',
    assignee: 'Backend Team',
    dueDate: '2026-02-10',
    subTasks: [
      { id: '7-1', title: '성적 기준 읽기 전용 설정', completed: true },
      { id: '7-2', title: '수정 API 비활성화', completed: true },
      { id: '7-3', title: 'UI 수정 버튼 제거', completed: true },
      { id: '7-4', title: '감사 로그 추가', completed: true },
    ],
    relatedApis: ['/api/v1/grades/criteria'],
    relatedFiles: ['GradeCriteriaService.java'],
  },
  {
    id: 8,
    category: '데이터베이스',
    categoryIcon: Database,
    title: '학위/비학위 DB 일관성 유지',
    description: '학위과정과 비학위과정의 데이터베이스 스키마 및 데이터 일관성 확보',
    status: 'completed',
    priority: 'high',
    progress: 100,
    notes: '반영 완료 - 통합 스키마 적용, 마이그레이션 완료. 학위/비학위 구분 필드 추가.',
    assignee: 'Database Team',
    dueDate: '2026-02-08',
    subTasks: [
      { id: '8-1', title: '통합 스키마 설계', completed: true },
      { id: '8-2', title: '데이터 마이그레이션', completed: true },
      { id: '8-3', title: '일관성 검증 쿼리 작성', completed: true },
      { id: '8-4', title: '문서화', completed: true },
    ],
    relatedApis: ['/api/v1/courses?type=degree', '/api/v1/courses?type=non-degree'],
    relatedFiles: ['CourseService.java', 'V001_unified_schema.sql'],
  },
];

/**
 * 상태별 설정
 */
const statusConfig = {
  completed: {
    label: '완료',
    color: 'bg-green-500',
    textColor: 'text-green-700',
    bgLight: 'bg-green-50',
    borderColor: 'border-green-200',
    icon: CheckCircle2,
  },
  'in-progress': {
    label: '진행중',
    color: 'bg-blue-500',
    textColor: 'text-blue-700',
    bgLight: 'bg-blue-50',
    borderColor: 'border-blue-200',
    icon: Loader2,
  },
  pending: {
    label: '대기',
    color: 'bg-amber-500',
    textColor: 'text-amber-700',
    bgLight: 'bg-amber-50',
    borderColor: 'border-amber-200',
    icon: Clock,
  },
  blocked: {
    label: '차단',
    color: 'bg-red-500',
    textColor: 'text-red-700',
    bgLight: 'bg-red-50',
    borderColor: 'border-red-200',
    icon: AlertCircle,
  },
};

const priorityConfig = {
  high: { label: '높음', color: 'text-red-600', bgColor: 'bg-red-100' },
  medium: { label: '보통', color: 'text-amber-600', bgColor: 'bg-amber-100' },
  low: { label: '낮음', color: 'text-green-600', bgColor: 'bg-green-100' },
};

/**
 * 중간점검 랜딩페이지 메인 컴포넌트
 */
export default function MidCheckLandingPage() {
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [searchKeyword, setSearchKeyword] = useState('');

  // 통계 계산
  const stats = useMemo(() => {
    const total = checkItems.length;
    const completed = checkItems.filter(item => item.status === 'completed').length;
    const inProgress = checkItems.filter(item => item.status === 'in-progress').length;
    const pending = checkItems.filter(item => item.status === 'pending').length;
    const avgProgress = Math.round(checkItems.reduce((sum, item) => sum + item.progress, 0) / total);

    return { total, completed, inProgress, pending, avgProgress };
  }, []);

  // 카테고리 목록
  const categories = useMemo(() => {
    return [...new Set(checkItems.map(item => item.category))];
  }, []);

  // 필터링
  const filteredItems = useMemo(() => {
    return checkItems.filter(item => {
      const matchesStatus = statusFilter === 'all' || item.status === statusFilter;
      const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;
      const matchesSearch = searchKeyword === '' ||
        item.title.toLowerCase().includes(searchKeyword.toLowerCase()) ||
        item.description.toLowerCase().includes(searchKeyword.toLowerCase());

      return matchesStatus && matchesCategory && matchesSearch;
    });
  }, [statusFilter, categoryFilter, searchKeyword]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 헤더 */}
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-6 py-6">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <Target className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">중간점검 현황</h1>
                  <p className="text-sm text-gray-600 mt-1">
                    한국폴리텍대학 LMS 고도화 프로젝트
                  </p>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-500">최종 업데이트</p>
              <p className="text-base font-semibold text-gray-900">
                {new Date().toLocaleDateString('ko-KR', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* 진행률 요약 카드 */}
        <section className="mb-8">
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-semibold text-gray-900">전체 진행률</h2>
              </div>
              <span className="text-3xl font-bold text-blue-600">{stats.avgProgress}%</span>
            </div>

            {/* 프로그레스 바 */}
            <div className="h-3 bg-gray-200 rounded-full overflow-hidden mb-6">
              <div
                className="h-full bg-blue-600 rounded-full transition-all duration-500"
                style={{ width: `${stats.avgProgress}%` }}
              />
            </div>

            {/* 상태별 통계 */}
            <div className="grid grid-cols-4 gap-4">
              <StatCard
                label="전체 항목"
                value={stats.total}
                icon={FileText}
                color="bg-gray-100 text-gray-600"
              />
              <StatCard
                label="완료"
                value={stats.completed}
                icon={CheckCircle2}
                color="bg-green-100 text-green-600"
              />
              <StatCard
                label="진행중"
                value={stats.inProgress}
                icon={Loader2}
                color="bg-blue-100 text-blue-600"
              />
              <StatCard
                label="대기"
                value={stats.pending}
                icon={Clock}
                color="bg-amber-100 text-amber-600"
              />
            </div>
          </div>
        </section>

        {/* 필터 영역 */}
        <section className="mb-6">
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <div className="flex items-center gap-3">
                <Filter className="w-5 h-5 text-gray-400" />

                {/* 상태 필터 */}
                <div className="flex gap-1">
                  <FilterButton
                    active={statusFilter === 'all'}
                    onClick={() => setStatusFilter('all')}
                    label="전체"
                  />
                  <FilterButton
                    active={statusFilter === 'completed'}
                    onClick={() => setStatusFilter('completed')}
                    label="완료"
                    variant="green"
                  />
                  <FilterButton
                    active={statusFilter === 'in-progress'}
                    onClick={() => setStatusFilter('in-progress')}
                    label="진행중"
                    variant="blue"
                  />
                  <FilterButton
                    active={statusFilter === 'pending'}
                    onClick={() => setStatusFilter('pending')}
                    label="대기"
                    variant="amber"
                  />
                </div>

                {/* 카테고리 필터 */}
                <select
                  value={categoryFilter}
                  onChange={(e) => setCategoryFilter(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="all">전체 카테고리</option>
                  {categories.map(category => (
                    <option key={category} value={category}>{category}</option>
                  ))}
                </select>
              </div>

              {/* 검색 */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  value={searchKeyword}
                  onChange={(e) => setSearchKeyword(e.target.value)}
                  placeholder="항목 검색..."
                  className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-64"
                />
              </div>
            </div>
          </div>
        </section>

        {/* 점검 항목 목록 */}
        <section className="space-y-4">
          {filteredItems.length === 0 ? (
            <div className="bg-white border border-gray-200 rounded-lg p-12 text-center">
              <p className="text-gray-500">검색 결과가 없습니다.</p>
            </div>
          ) : (
            filteredItems.map(item => (
              <CheckItemCard
                key={item.id}
                item={item}
                expanded={expandedId === item.id}
                onToggle={() => setExpandedId(expandedId === item.id ? null : item.id)}
              />
            ))
          )}
        </section>

        {/* 범례 */}
        <section className="mt-10 pt-6 border-t border-gray-200">
          <div className="flex flex-wrap justify-center gap-6 text-sm text-gray-500">
            {Object.entries(statusConfig).map(([key, config]) => (
              <span key={key} className="flex items-center gap-2">
                <span className={`w-3 h-3 rounded-full ${config.color}`}></span>
                {config.label}
              </span>
            ))}
          </div>
        </section>
      </main>

      {/* 푸터 */}
      <footer className="mt-16 py-8 bg-white border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <p className="text-gray-600">
            © 2026 한국폴리텍대학 LMS 고도화 프로젝트
          </p>
          <p className="text-sm text-gray-400 mt-2">
            GrowAILMS - AI 기반 학습관리시스템
          </p>
        </div>
      </footer>
    </div>
  );
}

/**
 * 통계 카드 컴포넌트
 */
function StatCard({ label, value, icon: Icon, color }: {
  label: string;
  value: number;
  icon: React.ElementType;
  color: string;
}) {
  return (
    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-2">
        <div className={`p-2 rounded-lg ${color}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
      <div className="text-2xl font-bold text-gray-900">{value}</div>
      <div className="text-sm text-gray-600">{label}</div>
    </div>
  );
}

/**
 * 필터 버튼 컴포넌트
 */
function FilterButton({ active, onClick, label, variant = 'default' }: {
  active: boolean;
  onClick: () => void;
  label: string;
  variant?: 'default' | 'green' | 'blue' | 'amber';
}) {
  const variantStyles = {
    default: active ? 'bg-gray-900 text-white' : 'bg-white text-gray-700 border border-gray-300',
    green: active ? 'bg-green-600 text-white' : 'bg-white text-gray-700 border border-gray-300',
    blue: active ? 'bg-blue-600 text-white' : 'bg-white text-gray-700 border border-gray-300',
    amber: active ? 'bg-amber-500 text-white' : 'bg-white text-gray-700 border border-gray-300',
  };

  return (
    <button
      className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${variantStyles[variant]} hover:opacity-90`}
      onClick={onClick}
    >
      {label}
    </button>
  );
}

/**
 * 점검 항목 카드 컴포넌트
 */
function CheckItemCard({ item, expanded, onToggle }: {
  item: CheckItem;
  expanded: boolean;
  onToggle: () => void;
}) {
  const status = statusConfig[item.status];
  const priority = priorityConfig[item.priority];
  const StatusIcon = status.icon;
  const CategoryIcon = item.categoryIcon;

  const completedSubTasks = item.subTasks?.filter(t => t.completed).length || 0;
  const totalSubTasks = item.subTasks?.length || 0;

  return (
    <div className={`bg-white border rounded-lg overflow-hidden transition-all duration-300 ${
      expanded ? `shadow-lg ${status.borderColor}` : 'border-gray-200 hover:border-gray-300'
    }`}>
      {/* 헤더 */}
      <div
        className="p-5 cursor-pointer hover:bg-gray-50 transition-colors"
        onClick={onToggle}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-4 flex-1">
            {/* 카테고리 아이콘 */}
            <div className={`p-2.5 rounded-lg ${status.bgLight}`}>
              <CategoryIcon className={`w-5 h-5 ${status.textColor}`} />
            </div>

            <div className="flex-1 min-w-0">
              {/* 상단 태그들 */}
              <div className="flex items-center gap-2 mb-2 flex-wrap">
                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${status.color} text-white`}>
                  <StatusIcon className={`w-3 h-3 ${item.status === 'in-progress' ? 'animate-spin' : ''}`} />
                  {status.label}
                </span>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${priority.bgColor} ${priority.color}`}>
                  우선순위: {priority.label}
                </span>
                <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                  {item.category}
                </span>
              </div>

              {/* 제목 */}
              <h3 className="text-base font-semibold text-gray-900 mb-1">
                {item.id}. {item.title}
              </h3>

              {/* 설명 */}
              <p className="text-sm text-gray-600 line-clamp-2">
                {item.description}
              </p>

              {/* 진행률 바 */}
              <div className="mt-3 flex items-center gap-3">
                <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${
                      item.status === 'completed' ? 'bg-green-500' :
                      item.status === 'in-progress' ? 'bg-blue-500' : 'bg-amber-500'
                    }`}
                    style={{ width: `${item.progress}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-700 w-12 text-right">
                  {item.progress}%
                </span>
              </div>
            </div>
          </div>

          {/* 확장 버튼 */}
          <button className="text-gray-400 hover:text-gray-600 transition-colors p-1">
            {expanded ? (
              <ChevronDown className="w-5 h-5" />
            ) : (
              <ChevronRight className="w-5 h-5" />
            )}
          </button>
        </div>
      </div>

      {/* 상세 내용 */}
      {expanded && (
        <div className="px-5 pb-5 border-t border-gray-100">
          <div className="pt-5 grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 왼쪽: 세부 정보 */}
            <div className="space-y-4">
              {/* 비고 */}
              <div>
                <h4 className="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                  <FileText className="w-4 h-4" /> 비고
                </h4>
                <p className="text-sm text-gray-600 bg-gray-50 rounded-lg p-3">
                  {item.notes}
                </p>
              </div>

              {/* 담당/기한 */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                    <Users className="w-4 h-4" /> 담당
                  </h4>
                  <p className="text-sm text-gray-900">{item.assignee}</p>
                </div>
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
                    <Calendar className="w-4 h-4" /> 기한
                  </h4>
                  <p className="text-sm text-gray-900">{item.dueDate}</p>
                </div>
              </div>

              {/* 관련 API */}
              {item.relatedApis && item.relatedApis.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-2">관련 API</h4>
                  <div className="space-y-1">
                    {item.relatedApis.map((api, idx) => (
                      <code key={idx} className="block text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded font-mono">
                        {api}
                      </code>
                    ))}
                  </div>
                </div>
              )}

              {/* 관련 파일 */}
              {item.relatedFiles && item.relatedFiles.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-2">관련 파일</h4>
                  <div className="flex flex-wrap gap-2">
                    {item.relatedFiles.map((file, idx) => (
                      <span key={idx} className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded">
                        {file}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* 오른쪽: 세부 작업 */}
            {item.subTasks && item.subTasks.length > 0 && (
              <div>
                <h4 className="text-sm font-medium text-gray-700 mb-3 flex items-center justify-between">
                  <span className="flex items-center gap-2">
                    <ClipboardCheck className="w-4 h-4" /> 세부 작업
                  </span>
                  <span className="text-xs text-gray-500">
                    {completedSubTasks}/{totalSubTasks} 완료
                  </span>
                </h4>
                <div className="space-y-2">
                  {item.subTasks.map(task => (
                    <div
                      key={task.id}
                      className={`flex items-center gap-3 p-3 rounded-lg border ${
                        task.completed
                          ? 'bg-green-50 border-green-200'
                          : 'bg-gray-50 border-gray-200'
                      }`}
                    >
                      <div className={`w-5 h-5 rounded-full flex items-center justify-center ${
                        task.completed ? 'bg-green-500' : 'bg-gray-300'
                      }`}>
                        {task.completed && (
                          <CheckCircle2 className="w-3 h-3 text-white" />
                        )}
                      </div>
                      <span className={`text-sm ${
                        task.completed ? 'text-green-700 line-through' : 'text-gray-700'
                      }`}>
                        {task.title}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
