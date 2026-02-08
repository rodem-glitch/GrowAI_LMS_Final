// MidCheck.tsx - 중간점검 랜딩페이지 (Mid-Check Home)
// 한국폴리텍대학 LMS 고도화 프로젝트 중간점검 현황
// 실제 프로젝트 UI 기반 초현실적 시뮬레이션

import React, { useMemo, useState, useCallback, useRef, useEffect } from 'react';
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
  Lock,
  RefreshCw,
  Play,
  Zap,
  Bot,
  Sparkles,
  Activity,
  Terminal,
  CheckCheck,
  XCircle,
  Cpu,
  Cloud,
  Eye,
  RotateCcw,
  Gauge,
  Pause,
  Volume2,
  VolumeX,
  Maximize2,
  MonitorPlay,
  Video,
  BookOpen,
  User,
  ChevronLeft,
  Edit3,
  Save,
  X,
  Check,
  AlertTriangle,
  Download,
  Printer,
  Table,
  FileSpreadsheet,
  HelpCircle,
} from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

interface SimulationResult {
  success: boolean;
  message: string;
  data?: Record<string, unknown>;
  duration: number;
  timestamp: string;
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
  mockEndpoint?: string;
  aiFeatures?: string[];
  demoVideo?: string;
}

// ============================================================================
// Mock Data
// ============================================================================

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
    notes: '차시별 시작일/종료일 설정, 유효기간 초과 시 출석 불인정 처리.',
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
    mockEndpoint: '/mock/attendance/validity',
    aiFeatures: ['출석 패턴 분석', '이상 탐지 AI'],
    demoVideo: 'attendance',
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
    notes: '학사포털 API 연동 필요, 강좌 계획서 스키마 확인 필요.',
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
    mockEndpoint: '/mock/haksa/syllabus',
    aiFeatures: ['Gemini 요약 생성', '학습목표 추출'],
    demoVideo: 'syllabus',
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
    notes: '현재 부분 연동 중, 실시간 동기화 구현 필요.',
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
    mockEndpoint: '/mock/haksa/courses',
    aiFeatures: ['데이터 정합성 검증', 'Vertex AI 매핑'],
    demoVideo: 'course-sync',
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
    notes: '얼굴 인식, IP 기반 검증, 기기 바인딩, 세션 동시 접속 제한 등 복합 적용.',
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
    mockEndpoint: '/mock/security/verify',
    aiFeatures: ['Vision AI 얼굴인식', 'ML 이상탐지', 'Cloud Identity'],
    demoVideo: 'security',
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
    notes: '과제, 시험, 출석, 참여도 등 항목별 점수 집계 뷰.',
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
    mockEndpoint: '/mock/grades/summary',
    aiFeatures: ['BigQuery 분석', '성적 예측 AI'],
    demoVideo: 'grades',
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
    notes: '교수자용 일괄 출력 기능, PDF/Excel 내보내기 지원.',
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
    mockEndpoint: '/mock/feedback/export',
    aiFeatures: ['Gemini 피드백 요약', 'Document AI'],
    demoVideo: 'feedback',
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
    notes: '종합정보시스템에서 정의된 성적 기준만 사용, LMS에서는 읽기 전용으로 처리.',
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
    mockEndpoint: '/mock/grades/criteria',
    aiFeatures: ['Cloud Logging', '감사 추적'],
    demoVideo: 'grade-lock',
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
    notes: '반영 완료 - 통합 스키마 적용, 마이그레이션 완료.',
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
    mockEndpoint: '/mock/courses/consistency',
    aiFeatures: ['Cloud SQL', 'Dataflow 검증'],
    demoVideo: 'db-consistency',
  },
];

// ============================================================================
// Mock Data Generators
// ============================================================================

const generateMockAttendance = () => ({
  sessionId: 'SES-' + Math.random().toString(36).substr(2, 9).toUpperCase(),
  courseCode: 'CS101',
  validFrom: '2026-02-01T09:00:00',
  validTo: '2026-02-15T23:59:59',
  students: Array.from({ length: 5 }, (_, i) => ({
    studentId: `STU-${1001 + i}`,
    name: ['김민수', '이영희', '박지훈', '최수연', '정태영'][i],
    attendanceStatus: ['출석', '출석', '지각', '출석', '결석'][i],
    checkInTime: `09:${String(Math.floor(Math.random() * 30)).padStart(2, '0')}:00`,
  })),
});

const generateMockSyllabus = () => ({
  courseCode: 'CS101',
  courseName: '프로그래밍 기초',
  professor: '홍길동',
  credits: 3,
  weeks: Array.from({ length: 15 }, (_, i) => ({
    week: i + 1,
    topic: `Week ${i + 1}: ${['오리엔테이션', '변수와 자료형', '조건문', '반복문', '함수', '배열', '객체', '클래스', '상속', '예외처리', '파일입출력', '네트워크', '데이터베이스', '프로젝트', '기말평가'][i]}`,
    assignment: i % 3 === 0 ? `과제 ${Math.ceil((i + 1) / 3)}` : null,
  })),
  aiSummary: 'Gemini AI 분석: 본 과정은 프로그래밍 기초 개념을 다루며, 실습 중심의 학습을 제공합니다.',
});

const generateMockCourseInfo = () => ({
  courses: Array.from({ length: 3 }, (_, i) => ({
    courseId: `CRS-${2024001 + i}`,
    courseCode: ['CS101', 'CS201', 'CS301'][i],
    courseName: ['프로그래밍 기초', '자료구조', '알고리즘'][i],
    professor: ['홍길동', '김철수', '이영희'][i],
    division: ['A', 'B', 'A'][i],
    students: 30 + i * 5,
    syncStatus: 'synced',
    lastSync: new Date().toISOString(),
  })),
});

const generateMockSecurityCheck = () => ({
  sessionId: 'SEC-' + Math.random().toString(36).substr(2, 9).toUpperCase(),
  userId: 'user@kopo.ac.kr',
  checks: [
    { type: 'session', status: 'pass', message: '단일 세션 확인됨' },
    { type: 'ip', status: 'pass', message: 'IP 192.168.1.xxx 허용 범위' },
    { type: 'device', status: 'pass', message: '등록된 기기 확인' },
    { type: 'face', status: 'pending', message: 'Vision AI 대기 중' },
  ],
  riskScore: 0.12,
  aiAnalysis: 'ML 이상탐지: 정상 패턴 (신뢰도 88%)',
});

const generateMockGradeSummary = () => ({
  courseId: 'CS101',
  students: Array.from({ length: 5 }, (_, i) => ({
    studentId: `STU-${1001 + i}`,
    name: ['김민수', '이영희', '박지훈', '최수연', '정태영'][i],
    attendance: 95 - i * 3,
    assignment: 88 + i * 2,
    midterm: 85 - i * 5,
    final: 90 + i,
    total: 89 - i * 2,
    grade: ['A+', 'A0', 'B+', 'B0', 'B+'][i],
  })),
  analytics: {
    average: 85.4,
    median: 87,
    stdDev: 5.2,
    aiPrediction: '성적 분포 정상 (BigQuery 분석)',
  },
});

const generateMockFeedback = () => ({
  courseId: 'CS101',
  exportFormat: 'PDF',
  feedbacks: Array.from({ length: 3 }, (_, i) => ({
    studentId: `STU-${1001 + i}`,
    studentName: ['김민수', '이영희', '박지훈'][i],
    assignments: [
      { title: '과제 1', score: 90 + i, feedback: '잘 작성됨' },
      { title: '과제 2', score: 85 - i, feedback: '개선 필요' },
    ],
    qna: [
      { question: '질문 예시', answer: 'AI 자동 응답', aiGenerated: true },
    ],
  })),
  geminiSummary: '전체 학생 피드백 요약: 대부분 양호한 진행 상황을 보이고 있습니다.',
});

const generateMockGradeCriteria = () => ({
  courseId: 'CS101',
  criteria: {
    attendance: { weight: 10, locked: true },
    assignment: { weight: 20, locked: true },
    midterm: { weight: 30, locked: true },
    final: { weight: 40, locked: true },
  },
  source: '종합정보시스템',
  lastUpdated: '2026-01-15T10:00:00',
  auditLog: [
    { action: 'READ', user: 'admin', timestamp: new Date().toISOString() },
  ],
});

const generateMockConsistency = () => ({
  degreePrograms: 45,
  nonDegreePrograms: 23,
  totalCourses: 128,
  consistencyChecks: [
    { table: 'LM_COURSE', status: 'consistent', records: 128 },
    { table: 'LM_USER', status: 'consistent', records: 3420 },
    { table: 'LM_ENROLLMENT', status: 'consistent', records: 8540 },
  ],
  dataflowResult: 'Dataflow 검증 완료: 모든 레코드 일관성 확인',
});

const mockGenerators: Record<number, () => Record<string, unknown>> = {
  1: generateMockAttendance,
  2: generateMockSyllabus,
  3: generateMockCourseInfo,
  4: generateMockSecurityCheck,
  5: generateMockGradeSummary,
  6: generateMockFeedback,
  7: generateMockGradeCriteria,
  8: generateMockConsistency,
};

// ============================================================================
// Config
// ============================================================================

const statusConfig = {
  completed: {
    label: '완료',
    color: 'bg-emerald-500',
    textColor: 'text-emerald-700',
    bgLight: 'bg-emerald-50',
    borderColor: 'border-emerald-200',
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
  low: { label: '낮음', color: 'text-emerald-600', bgColor: 'bg-emerald-100' },
};

// ============================================================================
// Realistic UI Video Player Component
// ============================================================================

function RealisticVideoPlayer({ demoType, itemId }: { demoType: string; itemId: number }) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [progress, setProgress] = useState(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const totalDuration = 10000;
  const totalSteps = 8;

  useEffect(() => {
    if (isPlaying) {
      intervalRef.current = setInterval(() => {
        setProgress(prev => {
          const next = prev + (100 / (totalDuration / 100));
          if (next >= 100) {
            setIsPlaying(false);
            setCurrentStep(totalSteps - 1);
            return 100;
          }
          setCurrentStep(Math.min(Math.floor((next / 100) * totalSteps), totalSteps - 1));
          return next;
        });
      }, 100);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [isPlaying]);

  const handlePlayPause = () => {
    if (progress >= 100) {
      setProgress(0);
      setCurrentStep(0);
    }
    setIsPlaying(!isPlaying);
  };

  const handleReset = () => {
    setIsPlaying(false);
    setProgress(0);
    setCurrentStep(0);
  };

  // Render different UI based on demo type
  const renderDemoContent = () => {
    switch (demoType) {
      case 'attendance':
        return <AttendanceDemo step={currentStep} />;
      case 'syllabus':
        return <SyllabusDemo step={currentStep} />;
      case 'course-sync':
        return <CourseSyncDemo step={currentStep} />;
      case 'security':
        return <SecurityDemo step={currentStep} />;
      case 'grades':
        return <GradesDemo step={currentStep} />;
      case 'feedback':
        return <FeedbackDemo step={currentStep} />;
      case 'grade-lock':
        return <GradeLockDemo step={currentStep} />;
      case 'db-consistency':
        return <DbConsistencyDemo step={currentStep} />;
      default:
        return <div className="text-white">Demo not available</div>;
    }
  };

  return (
    <div className="bg-slate-900 rounded-2xl overflow-hidden shadow-2xl border border-slate-700">
      {/* Video Header */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-800 border-b border-slate-700">
        <div className="flex items-center gap-2">
          <div className="flex gap-1.5">
            <div className="w-3 h-3 rounded-full bg-red-500" />
            <div className="w-3 h-3 rounded-full bg-yellow-500" />
            <div className="w-3 h-3 rounded-full bg-green-500" />
          </div>
          <span className="text-xs text-slate-400 ml-2">GrowAI LMS - 실시간 오퍼레이션</span>
        </div>
        <div className="flex items-center gap-2 text-xs text-slate-500">
          <span className="px-2 py-0.5 bg-purple-500/20 text-purple-300 rounded">LIVE</span>
          Step {currentStep + 1}/8
        </div>
      </div>

      {/* Main Display Area */}
      <div className="relative bg-gradient-to-br from-slate-100 to-slate-200" style={{ minHeight: '380px' }}>
        {!isPlaying && progress === 0 ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-900/90 backdrop-blur-sm">
            <div
              className="w-20 h-20 rounded-full bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shadow-xl shadow-purple-500/30 cursor-pointer hover:scale-105 transition-transform mb-4"
              onClick={handlePlayPause}
            >
              <Play className="w-10 h-10 text-white ml-1" />
            </div>
            <h3 className="text-lg font-bold text-white mb-1">실제 화면 시뮬레이션</h3>
            <p className="text-slate-400 text-sm">플레이 버튼을 눌러 시작</p>
          </div>
        ) : (
          <div className="w-full h-full">
            {renderDemoContent()}
          </div>
        )}

        {/* Completion Overlay */}
        {progress >= 100 && (
          <div className="absolute inset-0 bg-emerald-500/20 flex items-center justify-center backdrop-blur-sm">
            <div className="text-center">
              <CheckCircle2 className="w-16 h-16 text-emerald-500 mx-auto mb-3" />
              <h3 className="text-xl font-bold text-slate-800 mb-2">시뮬레이션 완료</h3>
              <button
                onClick={handleReset}
                className="mt-2 px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700 transition-colors flex items-center gap-2 mx-auto"
              >
                <RotateCcw className="w-4 h-4" />
                다시 보기
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Video Controls */}
      <div className="px-4 py-3 bg-slate-800 border-t border-slate-700">
        <div className="relative h-1.5 bg-slate-700 rounded-full mb-3">
          <div
            className="absolute h-full bg-gradient-to-r from-purple-500 to-indigo-500 rounded-full transition-all"
            style={{ width: `${progress}%` }}
          />
        </div>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <button
              onClick={handlePlayPause}
              className="w-9 h-9 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 text-white flex items-center justify-center hover:from-purple-600 hover:to-indigo-700 transition-all"
            >
              {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
            </button>
            <button onClick={handleReset} className="w-8 h-8 rounded-full bg-slate-700 text-slate-300 flex items-center justify-center hover:bg-slate-600">
              <RotateCcw className="w-4 h-4" />
            </button>
          </div>
          <span className="text-xs text-slate-400 font-mono">{Math.floor((progress / 100) * 10)}s / 10s</span>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// Demo Components - Realistic UI Simulations
// ============================================================================

// 1. Attendance Demo - Based on AttendanceTab.tsx
function AttendanceDemo({ step }: { step: number }) {
  const students = [
    { id: '2024001', name: '김민수', status: '출석', video: 3, exam: 1, hw: 2, progress: 85 },
    { id: '2024002', name: '이영희', status: '출석', video: 3, exam: 1, hw: 1, progress: 72 },
    { id: '2024003', name: '박지훈', status: '지각', video: 2, exam: 1, hw: 2, progress: 68 },
    { id: '2024004', name: '최수연', status: '출석', video: 3, exam: 1, hw: 2, progress: 91 },
    { id: '2024005', name: '정태영', status: '결석', video: 1, exam: 0, hw: 1, progress: 45 },
  ];

  return (
    <div className="h-full flex text-sm" style={{ minHeight: '380px' }}>
      {/* Left Sidebar */}
      <div className="w-56 bg-white border-r border-gray-200 p-3">
        <div className="text-xs font-semibold text-gray-500 mb-2">차시 목록</div>
        {[1, 2, 3].map(week => (
          <div key={week} className={`mb-2 ${step >= week ? 'opacity-100' : 'opacity-40'}`}>
            <div className="flex items-center gap-2 px-2 py-1.5 bg-gray-50 rounded text-xs font-medium text-gray-700">
              <ChevronDown className="w-3 h-3" />
              {week}주차
            </div>
            {[1, 2].map(session => (
              <div
                key={session}
                className={`ml-4 px-2 py-1 text-xs cursor-pointer rounded mt-1 ${
                  week === 1 && session === 1 && step >= 2 ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-50'
                }`}
              >
                {session}차시 {step >= 3 && week === 1 && session === 1 && (
                  <span className="ml-1 text-[10px] text-green-600">●</span>
                )}
              </div>
            ))}
          </div>
        ))}
        {step >= 4 && (
          <div className="mt-3 p-2 bg-blue-50 rounded border border-blue-100">
            <div className="text-[10px] text-blue-600 font-medium">유효기간 설정</div>
            <div className="text-[10px] text-gray-600 mt-1">2026-02-01 ~ 02-15</div>
          </div>
        )}
      </div>

      {/* Main Content */}
      <div className="flex-1 p-4 bg-gray-50">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold text-gray-800">1주차 1차시 - 수강생 진도</span>
            {step >= 5 && <span className="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] rounded-full">유효기간 내</span>}
          </div>
          <div className="flex gap-1">
            <button className={`px-2 py-1 text-xs rounded ${step >= 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'}`}>출석 보기</button>
            <button className="px-2 py-1 text-xs rounded bg-gray-200 text-gray-600">진도 보기</button>
          </div>
        </div>

        {/* Search */}
        {step >= 3 && (
          <div className="relative mb-3">
            <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-gray-400" />
            <input className="w-48 pl-7 pr-3 py-1.5 text-xs border border-gray-200 rounded-lg bg-white" placeholder="학생 검색..." />
          </div>
        )}

        {/* Table */}
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr className="text-[11px] text-gray-600">
                <th className="px-3 py-2 text-left font-medium">학번</th>
                <th className="px-3 py-2 text-left font-medium">이름</th>
                <th className="px-3 py-2 text-center font-medium">출석</th>
                <th className="px-3 py-2 text-center font-medium">동영상</th>
                <th className="px-3 py-2 text-center font-medium">시험</th>
                <th className="px-3 py-2 text-center font-medium">과제</th>
                <th className="px-3 py-2 text-center font-medium">진도율</th>
              </tr>
            </thead>
            <tbody>
              {students.slice(0, step >= 6 ? 5 : step >= 4 ? 3 : 2).map((s, i) => (
                <tr key={s.id} className={`border-t border-gray-100 ${step >= 7 && i === 4 ? 'bg-red-50' : ''}`}>
                  <td className="px-3 py-2 text-[11px] text-gray-600">{s.id}</td>
                  <td className="px-3 py-2 text-[11px] text-gray-800 font-medium">{s.name}</td>
                  <td className="px-3 py-2 text-center">
                    <span className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${
                      s.status === '출석' ? 'bg-green-100 text-green-700' :
                      s.status === '지각' ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                    }`}>{s.status}</span>
                  </td>
                  <td className="px-3 py-2 text-[11px] text-gray-600 text-center">{s.video}/3</td>
                  <td className="px-3 py-2 text-[11px] text-gray-600 text-center">{s.exam}/1</td>
                  <td className="px-3 py-2 text-[11px] text-gray-600 text-center">{s.hw}/2</td>
                  <td className="px-3 py-2">
                    <div className="flex items-center gap-1">
                      <div className="w-16 h-1.5 bg-gray-200 rounded-full overflow-hidden">
                        <div className={`h-full rounded-full ${s.progress >= 80 ? 'bg-green-500' : s.progress >= 60 ? 'bg-blue-500' : 'bg-red-500'}`} style={{ width: `${s.progress}%` }} />
                      </div>
                      <span className="text-[10px] text-gray-500">{s.progress}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {step >= 7 && (
          <div className="mt-3 p-2 bg-amber-50 border border-amber-200 rounded-lg flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-amber-500" />
            <span className="text-[11px] text-amber-700">정태영: 유효기간 초과로 출석 불인정 처리됨</span>
          </div>
        )}
      </div>
    </div>
  );
}

// 2. Syllabus Demo - Based on CourseInfoTabs.tsx
function SyllabusDemo({ step }: { step: number }) {
  const fields = [
    { label: '과목명', value: '프로그래밍 기초' },
    { label: '과목코드', value: 'CS101' },
    { label: '분반코드', value: 'A' },
    { label: '담당교수', value: '홍길동' },
    { label: '학점', value: '3학점' },
    { label: '개설년도/학기', value: '2026/1학기' },
  ];

  const weeks = [
    { week: 1, topic: '오리엔테이션 및 개발환경 설정', assignment: null },
    { week: 2, topic: '변수와 자료형', assignment: '과제 1' },
    { week: 3, topic: '조건문 (if, switch)', assignment: null },
    { week: 4, topic: '반복문 (for, while)', assignment: '과제 2' },
  ];

  return (
    <div className="h-full bg-white p-4 text-sm" style={{ minHeight: '380px' }}>
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <GraduationCap className="w-5 h-5 text-purple-600" />
          <h2 className="font-semibold text-gray-800">강좌 계획서</h2>
          {step >= 2 && <span className="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] rounded-full">학사포털 연동</span>}
        </div>
        {step >= 7 && (
          <button className="flex items-center gap-1 px-3 py-1.5 bg-purple-600 text-white text-xs rounded-lg">
            <RefreshCw className="w-3 h-3" />
            동기화
          </button>
        )}
      </div>

      {/* Basic Info Grid */}
      <div className="mb-4">
        <h3 className="text-xs font-semibold text-gray-500 mb-2">기본 정보</h3>
        <div className="grid grid-cols-3 gap-2">
          {fields.slice(0, step >= 3 ? 6 : step >= 2 ? 3 : 0).map((f, i) => (
            <div key={i} className="bg-gray-50 rounded-lg p-2">
              <div className="text-[10px] text-gray-500 mb-0.5">{f.label}</div>
              <div className="text-xs text-gray-800 font-medium">{f.value}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Weeks Table */}
      {step >= 4 && (
        <div className="mb-4">
          <h3 className="text-xs font-semibold text-gray-500 mb-2">주차별 학습 내용</h3>
          <div className="border border-gray-200 rounded-lg overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr className="text-[10px] text-gray-600">
                  <th className="px-3 py-1.5 text-left font-medium w-16">주차</th>
                  <th className="px-3 py-1.5 text-left font-medium">학습 내용</th>
                  <th className="px-3 py-1.5 text-center font-medium w-20">과제</th>
                </tr>
              </thead>
              <tbody>
                {weeks.slice(0, step >= 5 ? 4 : 2).map(w => (
                  <tr key={w.week} className="border-t border-gray-100">
                    <td className="px-3 py-1.5 text-[11px] text-gray-600">{w.week}주차</td>
                    <td className="px-3 py-1.5 text-[11px] text-gray-800">{w.topic}</td>
                    <td className="px-3 py-1.5 text-center">
                      {w.assignment && <span className="px-1.5 py-0.5 bg-blue-100 text-blue-700 text-[10px] rounded">{w.assignment}</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* AI Summary */}
      {step >= 6 && (
        <div className="p-3 bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-100 rounded-lg">
          <div className="flex items-center gap-2 mb-1">
            <Sparkles className="w-4 h-4 text-purple-500" />
            <span className="text-xs font-semibold text-purple-700">Gemini AI 요약</span>
          </div>
          <p className="text-[11px] text-gray-600 leading-relaxed">
            본 과정은 프로그래밍 기초 개념을 다루며, 변수, 조건문, 반복문 등 핵심 문법을 학습합니다.
            총 15주 과정으로 실습 중심의 학습을 제공하며, 5개의 과제와 2회의 시험이 포함됩니다.
          </p>
        </div>
      )}
    </div>
  );
}

// 3. Course Sync Demo
function CourseSyncDemo({ step }: { step: number }) {
  const courses = [
    { code: 'CS101', name: '프로그래밍 기초', prof: '홍길동', div: 'A', students: 35, status: 'synced' },
    { code: 'CS201', name: '자료구조', prof: '김철수', div: 'B', students: 30, status: 'syncing' },
    { code: 'CS301', name: '알고리즘', prof: '이영희', div: 'A', students: 28, status: 'pending' },
  ];

  return (
    <div className="h-full bg-white p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <RefreshCw className={`w-5 h-5 text-blue-600 ${step >= 2 && step < 6 ? 'animate-spin' : ''}`} />
          <h2 className="font-semibold text-gray-800">학사포털 개설정보 연동</h2>
        </div>
        <div className="flex items-center gap-2">
          {step >= 1 && <span className="text-[10px] text-gray-500">마지막 동기화: {new Date().toLocaleTimeString('ko-KR')}</span>}
          {step >= 7 && <span className="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] rounded-full">연동 완료</span>}
        </div>
      </div>

      {/* Sync Progress */}
      {step >= 2 && step < 7 && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-100 rounded-lg">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-blue-700 font-medium">동기화 진행중...</span>
            <span className="text-xs text-blue-600">{Math.min((step - 1) * 20, 100)}%</span>
          </div>
          <div className="w-full h-2 bg-blue-200 rounded-full overflow-hidden">
            <div className="h-full bg-blue-500 rounded-full transition-all" style={{ width: `${Math.min((step - 1) * 20, 100)}%` }} />
          </div>
        </div>
      )}

      {/* Course List */}
      <div className="space-y-2">
        {courses.slice(0, step >= 5 ? 3 : step >= 3 ? 2 : 1).map((c, i) => (
          <div key={c.code} className={`p-3 border rounded-lg transition-all ${
            step >= 6 + i ? 'border-green-200 bg-green-50' : 'border-gray-200 bg-white'
          }`}>
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-gray-800">{c.name}</span>
                  <span className="px-1.5 py-0.5 bg-gray-100 text-gray-600 text-[10px] rounded">{c.code}</span>
                </div>
                <div className="text-[10px] text-gray-500 mt-0.5">{c.prof} | 분반 {c.div} | 수강생 {c.students}명</div>
              </div>
              <div className="flex items-center gap-2">
                {step >= 6 + i ? (
                  <span className="flex items-center gap-1 px-2 py-0.5 bg-green-100 text-green-700 text-[10px] rounded-full">
                    <Check className="w-3 h-3" /> 동기화 완료
                  </span>
                ) : step >= 3 + i ? (
                  <span className="flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 text-[10px] rounded-full">
                    <Loader2 className="w-3 h-3 animate-spin" /> 동기화 중
                  </span>
                ) : (
                  <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-[10px] rounded-full">대기</span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {step >= 7 && (
        <div className="mt-4 p-3 bg-emerald-50 border border-emerald-200 rounded-lg">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
            <span className="text-xs text-emerald-700 font-medium">3개 과목 동기화 완료 - 스케줄러 등록됨 (매일 06:00)</span>
          </div>
        </div>
      )}
    </div>
  );
}

// 4. Security Demo
function SecurityDemo({ step }: { step: number }) {
  const checks = [
    { icon: Users, label: '세션 동시 접속', status: step >= 2 ? 'pass' : 'checking' },
    { icon: Target, label: 'IP 주소 검증', status: step >= 3 ? 'pass' : step >= 2 ? 'checking' : 'waiting' },
    { icon: Cpu, label: '기기 바인딩', status: step >= 4 ? 'pass' : step >= 3 ? 'checking' : 'waiting' },
    { icon: Eye, label: '얼굴 인식 (Vision AI)', status: step >= 5 ? 'pass' : step >= 4 ? 'checking' : 'waiting' },
    { icon: Bot, label: 'ML 이상탐지', status: step >= 6 ? 'pass' : step >= 5 ? 'checking' : 'waiting' },
  ];

  return (
    <div className="h-full bg-slate-900 p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Shield className="w-5 h-5 text-emerald-400" />
          <h2 className="font-semibold text-white">본인 인증 보안 검증</h2>
        </div>
        {step >= 7 && (
          <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded-full flex items-center gap-1">
            <Check className="w-3 h-3" /> 인증 완료
          </span>
        )}
      </div>

      {/* User Info */}
      <div className="p-3 bg-slate-800 rounded-lg mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-full flex items-center justify-center">
            <User className="w-5 h-5 text-white" />
          </div>
          <div>
            <div className="text-white text-xs font-medium">user@kopo.ac.kr</div>
            <div className="text-slate-400 text-[10px]">IP: 192.168.1.xxx | Device: Chrome/Windows</div>
          </div>
        </div>
      </div>

      {/* Security Checks */}
      <div className="space-y-2">
        {checks.map((c, i) => (
          <div key={i} className={`p-3 rounded-lg border transition-all ${
            c.status === 'pass' ? 'bg-emerald-500/10 border-emerald-500/30' :
            c.status === 'checking' ? 'bg-blue-500/10 border-blue-500/30' :
            'bg-slate-800 border-slate-700'
          }`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <c.icon className={`w-4 h-4 ${
                  c.status === 'pass' ? 'text-emerald-400' :
                  c.status === 'checking' ? 'text-blue-400' :
                  'text-slate-500'
                }`} />
                <span className="text-xs text-slate-300">{c.label}</span>
              </div>
              {c.status === 'pass' && (
                <span className="flex items-center gap-1 text-[10px] text-emerald-400">
                  <Check className="w-3 h-3" /> PASS
                </span>
              )}
              {c.status === 'checking' && (
                <Loader2 className="w-4 h-4 text-blue-400 animate-spin" />
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Risk Score */}
      {step >= 6 && (
        <div className="mt-4 p-3 bg-slate-800 rounded-lg">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[10px] text-slate-400">위험도 점수</span>
            <span className="text-xs text-emerald-400 font-mono">0.12 (낮음)</span>
          </div>
          <div className="w-full h-2 bg-slate-700 rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full" style={{ width: '12%' }} />
          </div>
        </div>
      )}
    </div>
  );
}

// 5. Grades Demo
function GradesDemo({ step }: { step: number }) {
  const gradeItems = [
    { label: '출석(진도)', value: 10, color: 'blue' },
    { label: '시험', value: 30, color: 'purple' },
    { label: '과제', value: 20, color: 'green' },
    { label: '토론', value: 20, color: 'orange' },
    { label: '기타', value: 20, color: 'gray' },
  ];

  const students = [
    { name: '김민수', att: 95, exam: 88, hw: 92, disc: 85, total: 89, grade: 'A+' },
    { name: '이영희', att: 90, exam: 82, hw: 88, disc: 90, total: 86, grade: 'A0' },
    { name: '박지훈', att: 85, exam: 78, hw: 85, disc: 80, total: 81, grade: 'B+' },
  ];

  return (
    <div className="h-full bg-white p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <BarChart3 className="w-5 h-5 text-indigo-600" />
          <h2 className="font-semibold text-gray-800">성적 뷰테이블</h2>
        </div>
        {step >= 7 && (
          <span className="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] rounded-full">뷰 생성 완료</span>
        )}
      </div>

      {/* Grade Ratio */}
      <div className="mb-4">
        <h3 className="text-xs font-semibold text-gray-500 mb-2">배점 비율</h3>
        <div className="grid grid-cols-5 gap-2">
          {gradeItems.slice(0, step >= 3 ? 5 : step >= 2 ? 3 : 0).map((g, i) => (
            <div key={i} className="text-center p-2 bg-gray-50 rounded-lg border border-gray-200">
              <div className="text-[10px] text-gray-500 mb-1">{g.label}</div>
              <div className="text-sm font-bold text-gray-800">{g.value}%</div>
            </div>
          ))}
        </div>
        {step >= 4 && (
          <div className="mt-2 text-right">
            <span className={`text-[10px] px-2 py-0.5 rounded ${gradeItems.reduce((a, b) => a + b.value, 0) === 100 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
              합계: {gradeItems.reduce((a, b) => a + b.value, 0)}%
            </span>
          </div>
        )}
      </div>

      {/* Students Table */}
      {step >= 5 && (
        <div className="border border-gray-200 rounded-lg overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr className="text-[10px] text-gray-600">
                <th className="px-2 py-1.5 text-left font-medium">이름</th>
                <th className="px-2 py-1.5 text-center font-medium">출석</th>
                <th className="px-2 py-1.5 text-center font-medium">시험</th>
                <th className="px-2 py-1.5 text-center font-medium">과제</th>
                <th className="px-2 py-1.5 text-center font-medium">토론</th>
                <th className="px-2 py-1.5 text-center font-medium">총점</th>
                <th className="px-2 py-1.5 text-center font-medium">등급</th>
              </tr>
            </thead>
            <tbody>
              {students.slice(0, step >= 6 ? 3 : 2).map(s => (
                <tr key={s.name} className="border-t border-gray-100">
                  <td className="px-2 py-1.5 text-[11px] text-gray-800 font-medium">{s.name}</td>
                  <td className="px-2 py-1.5 text-[11px] text-gray-600 text-center">{s.att}</td>
                  <td className="px-2 py-1.5 text-[11px] text-gray-600 text-center">{s.exam}</td>
                  <td className="px-2 py-1.5 text-[11px] text-gray-600 text-center">{s.hw}</td>
                  <td className="px-2 py-1.5 text-[11px] text-gray-600 text-center">{s.disc}</td>
                  <td className="px-2 py-1.5 text-[11px] text-gray-800 text-center font-semibold">{s.total}</td>
                  <td className="px-2 py-1.5 text-center">
                    <span className={`px-1.5 py-0.5 text-[10px] rounded font-medium ${
                      s.grade.startsWith('A') ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'
                    }`}>{s.grade}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {step >= 7 && (
        <div className="mt-3 p-2 bg-indigo-50 border border-indigo-100 rounded-lg flex items-center gap-2">
          <Cpu className="w-4 h-4 text-indigo-500" />
          <span className="text-[10px] text-indigo-700">BigQuery 분석: 성적 분포 정상 (평균 85.4, 중앙값 86)</span>
        </div>
      )}
    </div>
  );
}

// 6. Feedback Demo
function FeedbackDemo({ step }: { step: number }) {
  const feedbacks = [
    { student: '김민수', hw: '과제 1', score: 92, status: '확인완료', feedback: '잘 작성됨' },
    { student: '이영희', hw: '과제 1', score: 88, status: '미확인', feedback: '-' },
    { student: '박지훈', hw: '과제 2', score: 85, status: '확인완료', feedback: '개선 필요' },
  ];

  return (
    <div className="h-full bg-white p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <MessageSquare className="w-5 h-5 text-orange-600" />
          <h2 className="font-semibold text-gray-800">과제/Q&A 피드백 통합</h2>
        </div>
        <div className="flex items-center gap-2">
          {step >= 6 && (
            <>
              <button className="flex items-center gap-1 px-2 py-1 bg-red-100 text-red-700 text-[10px] rounded hover:bg-red-200">
                <FileText className="w-3 h-3" /> PDF
              </button>
              <button className="flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 text-[10px] rounded hover:bg-green-200">
                <FileSpreadsheet className="w-3 h-3" /> Excel
              </button>
            </>
          )}
        </div>
      </div>

      {/* Search Bar */}
      {step >= 2 && (
        <div className="flex items-center gap-2 mb-3">
          <div className="relative flex-1">
            <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-gray-400" />
            <input className="w-full pl-7 pr-3 py-1.5 text-xs border border-gray-200 rounded-lg" placeholder="과제명/학생명 검색..." />
          </div>
          <select className="px-2 py-1.5 text-xs border border-gray-200 rounded-lg bg-white">
            <option>전체 상태</option>
            <option>미확인</option>
            <option>확인완료</option>
          </select>
        </div>
      )}

      {/* Feedback List */}
      {step >= 3 && (
        <div className="space-y-2 mb-4">
          {feedbacks.slice(0, step >= 5 ? 3 : step >= 4 ? 2 : 1).map((f, i) => (
            <div key={i} className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                    <User className="w-4 h-4 text-gray-500" />
                  </div>
                  <div>
                    <div className="text-xs font-medium text-gray-800">{f.student} - {f.hw}</div>
                    <div className="text-[10px] text-gray-500">점수: {f.score}점 | 피드백: {f.feedback}</div>
                  </div>
                </div>
                <span className={`px-2 py-0.5 text-[10px] rounded-full ${
                  f.status === '확인완료' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
                }`}>{f.status}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* AI Summary */}
      {step >= 7 && (
        <div className="p-3 bg-gradient-to-r from-orange-50 to-amber-50 border border-orange-100 rounded-lg">
          <div className="flex items-center gap-2 mb-1">
            <Sparkles className="w-4 h-4 text-orange-500" />
            <span className="text-xs font-semibold text-orange-700">Gemini 피드백 요약</span>
          </div>
          <p className="text-[11px] text-gray-600">
            전체 3명의 학생 피드백 분석 완료. 평균 점수 88.3점, 대부분 양호한 진행 상황입니다.
            1건의 미확인 피드백이 있습니다.
          </p>
        </div>
      )}
    </div>
  );
}

// 7. Grade Lock Demo
function GradeLockDemo({ step }: { step: number }) {
  const criteria = [
    { label: '출석(진도)', value: 10 },
    { label: '시험', value: 30 },
    { label: '과제', value: 20 },
    { label: '기타', value: 40 },
  ];

  const auditLog = [
    { action: 'READ', user: 'admin', time: '2026-02-08 09:00:00' },
    { action: 'LOCK', user: 'system', time: '2026-02-01 00:00:00' },
  ];

  return (
    <div className="h-full bg-white p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Lock className="w-5 h-5 text-red-600" />
          <h2 className="font-semibold text-gray-800">성적 기준 (읽기 전용)</h2>
        </div>
        {step >= 3 && (
          <span className="px-2 py-1 bg-red-100 text-red-700 text-[10px] rounded-full flex items-center gap-1">
            <Lock className="w-3 h-3" /> 수정 불가
          </span>
        )}
      </div>

      {/* Source Info */}
      {step >= 2 && (
        <div className="p-3 bg-blue-50 border border-blue-100 rounded-lg mb-4">
          <div className="flex items-center gap-2">
            <Database className="w-4 h-4 text-blue-500" />
            <span className="text-xs text-blue-700">연동 출처: <strong>종합정보시스템</strong></span>
          </div>
          <div className="text-[10px] text-gray-500 mt-1">마지막 동기화: 2026-01-15 10:00:00</div>
        </div>
      )}

      {/* Criteria Grid */}
      {step >= 4 && (
        <div className="mb-4">
          <h3 className="text-xs font-semibold text-gray-500 mb-2">배점 기준</h3>
          <div className="grid grid-cols-4 gap-2">
            {criteria.map((c, i) => (
              <div key={i} className="text-center p-3 bg-gray-100 rounded-lg border border-gray-200 relative">
                <Lock className="absolute top-1 right-1 w-3 h-3 text-gray-400" />
                <div className="text-[10px] text-gray-500 mb-1">{c.label}</div>
                <div className="text-lg font-bold text-gray-800">{c.value}%</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Edit Button Disabled */}
      {step >= 5 && (
        <div className="mb-4">
          <button className="w-full px-4 py-2 bg-gray-200 text-gray-400 rounded-lg cursor-not-allowed flex items-center justify-center gap-2">
            <Edit3 className="w-4 h-4" />
            수정 불가 (종합정보시스템 연동)
          </button>
        </div>
      )}

      {/* Audit Log */}
      {step >= 6 && (
        <div>
          <h3 className="text-xs font-semibold text-gray-500 mb-2">감사 로그</h3>
          <div className="border border-gray-200 rounded-lg overflow-hidden">
            {auditLog.map((log, i) => (
              <div key={i} className={`flex items-center justify-between px-3 py-2 ${i > 0 ? 'border-t border-gray-100' : ''}`}>
                <div className="flex items-center gap-2">
                  <span className={`px-1.5 py-0.5 text-[10px] rounded ${
                    log.action === 'LOCK' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'
                  }`}>{log.action}</span>
                  <span className="text-[11px] text-gray-600">{log.user}</span>
                </div>
                <span className="text-[10px] text-gray-400">{log.time}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// 8. DB Consistency Demo
function DbConsistencyDemo({ step }: { step: number }) {
  const tables = [
    { name: 'LM_COURSE', records: 128, status: step >= 4 ? 'pass' : step >= 2 ? 'checking' : 'waiting' },
    { name: 'LM_USER', records: 3420, status: step >= 5 ? 'pass' : step >= 3 ? 'checking' : 'waiting' },
    { name: 'LM_ENROLLMENT', records: 8540, status: step >= 6 ? 'pass' : step >= 4 ? 'checking' : 'waiting' },
  ];

  return (
    <div className="h-full bg-slate-900 p-4 text-sm" style={{ minHeight: '380px' }}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Database className="w-5 h-5 text-cyan-400" />
          <h2 className="font-semibold text-white">DB 일관성 검증</h2>
        </div>
        {step >= 7 && (
          <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded-full">검증 완료</span>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="p-3 bg-slate-800 rounded-lg text-center">
          <div className="text-xl font-bold text-cyan-400">45</div>
          <div className="text-[10px] text-slate-400">학위과정</div>
        </div>
        <div className="p-3 bg-slate-800 rounded-lg text-center">
          <div className="text-xl font-bold text-purple-400">23</div>
          <div className="text-[10px] text-slate-400">비학위과정</div>
        </div>
        <div className="p-3 bg-slate-800 rounded-lg text-center">
          <div className="text-xl font-bold text-emerald-400">128</div>
          <div className="text-[10px] text-slate-400">전체 과목</div>
        </div>
      </div>

      {/* Table Checks */}
      <div className="space-y-2 mb-4">
        {tables.map((t, i) => (
          <div key={i} className={`p-3 rounded-lg border ${
            t.status === 'pass' ? 'bg-emerald-500/10 border-emerald-500/30' :
            t.status === 'checking' ? 'bg-cyan-500/10 border-cyan-500/30' :
            'bg-slate-800 border-slate-700'
          }`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Table className={`w-4 h-4 ${
                  t.status === 'pass' ? 'text-emerald-400' :
                  t.status === 'checking' ? 'text-cyan-400' : 'text-slate-500'
                }`} />
                <span className="text-xs text-slate-300 font-mono">{t.name}</span>
                <span className="text-[10px] text-slate-500">({t.records.toLocaleString()} records)</span>
              </div>
              {t.status === 'pass' && <span className="text-[10px] text-emerald-400 flex items-center gap-1"><Check className="w-3 h-3" /> Consistent</span>}
              {t.status === 'checking' && <Loader2 className="w-4 h-4 text-cyan-400 animate-spin" />}
            </div>
          </div>
        ))}
      </div>

      {/* Dataflow Result */}
      {step >= 7 && (
        <div className="p-3 bg-gradient-to-r from-cyan-500/10 to-purple-500/10 border border-cyan-500/30 rounded-lg">
          <div className="flex items-center gap-2 mb-1">
            <Cpu className="w-4 h-4 text-cyan-400" />
            <span className="text-xs font-semibold text-cyan-400">Dataflow 파이프라인</span>
          </div>
          <p className="text-[11px] text-slate-300">
            전체 일관성 검증 완료: 학위/비학위 통합 스키마 적용됨. 12,088개 레코드 검증 통과.
          </p>
        </div>
      )}
    </div>
  );
}

// ============================================================================
// Main Component
// ============================================================================

export default function MidCheckLandingPage() {
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [searchKeyword, setSearchKeyword] = useState('');
  const [simulations, setSimulations] = useState<Record<number, SimulationResult | null>>({});
  const [runningSimulations, setRunningSimulations] = useState<Set<number>>(new Set());

  const stats = useMemo(() => {
    const total = checkItems.length;
    const completed = checkItems.filter(item => item.status === 'completed').length;
    const inProgress = checkItems.filter(item => item.status === 'in-progress').length;
    const pending = checkItems.filter(item => item.status === 'pending').length;
    const avgProgress = Math.round(checkItems.reduce((sum, item) => sum + item.progress, 0) / total);
    const simulatedCount = Object.keys(simulations).filter(k => simulations[Number(k)]?.success).length;
    return { total, completed, inProgress, pending, avgProgress, simulatedCount };
  }, [simulations]);

  const categories = useMemo(() => [...new Set(checkItems.map(item => item.category))], []);

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

  const runSimulation = useCallback(async (itemId: number) => {
    setRunningSimulations(prev => new Set(prev).add(itemId));
    const startTime = Date.now();
    await new Promise(resolve => setTimeout(resolve, 800 + Math.random() * 1200));
    const generator = mockGenerators[itemId];
    const mockData = generator ? generator() : {};
    const result: SimulationResult = {
      success: true,
      message: `Mock 데이터 생성 완료 (${checkItems.find(i => i.id === itemId)?.mockEndpoint})`,
      data: mockData,
      duration: Date.now() - startTime,
      timestamp: new Date().toISOString(),
    };
    setSimulations(prev => ({ ...prev, [itemId]: result }));
    setRunningSimulations(prev => { const next = new Set(prev); next.delete(itemId); return next; });
  }, []);

  const runAllSimulations = useCallback(async () => {
    for (const item of checkItems) {
      if (!runningSimulations.has(item.id)) {
        runSimulation(item.id);
        await new Promise(resolve => setTimeout(resolve, 300));
      }
    }
  }, [runSimulation, runningSimulations]);

  const resetSimulations = useCallback(() => {
    setSimulations({});
    setRunningSimulations(new Set());
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-2.5 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl shadow-lg shadow-blue-500/25">
                <Target className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">중간점검 시뮬레이션</h1>
                <p className="text-sm text-gray-500">한국폴리텍대학 LMS 고도화 프로젝트</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <button onClick={runAllSimulations} disabled={runningSimulations.size > 0}
                className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-lg shadow-blue-500/25 disabled:opacity-50">
                {runningSimulations.size > 0 ? <Loader2 className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4" />}
                전체 시뮬레이션
              </button>
              <button onClick={resetSimulations} className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-all">
                <RotateCcw className="w-4 h-4" /> 초기화
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Stats */}
        <section className="mb-8">
          <div className="grid grid-cols-6 gap-4">
            <StatCard label="전체 항목" value={stats.total} icon={FileText} gradient="from-slate-500 to-slate-600" />
            <StatCard label="완료" value={stats.completed} icon={CheckCircle2} gradient="from-emerald-500 to-emerald-600" />
            <StatCard label="진행중" value={stats.inProgress} icon={Activity} gradient="from-blue-500 to-blue-600" />
            <StatCard label="대기" value={stats.pending} icon={Clock} gradient="from-amber-500 to-amber-600" />
            <StatCard label="시뮬레이션" value={stats.simulatedCount} icon={Zap} gradient="from-purple-500 to-purple-600" />
            <StatCard label="평균 진행률" value={`${stats.avgProgress}%`} icon={Gauge} gradient="from-indigo-500 to-indigo-600" />
          </div>
        </section>

        {/* AI Banner */}
        <section className="mb-8">
          <div className="bg-gradient-to-r from-violet-600 via-purple-600 to-indigo-600 rounded-2xl p-6 text-white shadow-xl">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-white/20 rounded-xl"><Sparkles className="w-8 h-8" /></div>
                <div>
                  <h2 className="text-lg font-bold">Google AI Ecosystem 통합</h2>
                  <p className="text-white/80 text-sm">Gemini, Vertex AI, Vision AI, BigQuery, Cloud Functions</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                {['Gemini Pro', 'Vertex AI', 'Vision AI', 'BigQuery'].map(ai => (
                  <span key={ai} className="flex items-center gap-2 px-3 py-1.5 bg-white/20 rounded-full text-sm">{ai}</span>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* Filters */}
        <section className="mb-6">
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <div className="flex items-center gap-3">
                <Filter className="w-5 h-5 text-gray-400" />
                <div className="flex gap-1 p-1 bg-gray-100 rounded-lg">
                  {['all', 'completed', 'in-progress', 'pending'].map(status => (
                    <button key={status} onClick={() => setStatusFilter(status)}
                      className={`px-3 py-1.5 rounded-md text-sm font-medium transition-all ${statusFilter === status ? 'bg-white shadow text-gray-900' : 'text-gray-600 hover:text-gray-900'}`}>
                      {status === 'all' ? '전체' : statusConfig[status as keyof typeof statusConfig]?.label}
                    </button>
                  ))}
                </div>
                <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)} className="px-3 py-2 bg-gray-100 border-0 rounded-lg text-sm">
                  <option value="all">전체 카테고리</option>
                  {categories.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input value={searchKeyword} onChange={(e) => setSearchKeyword(e.target.value)} placeholder="검색..." className="pl-9 pr-4 py-2 bg-gray-100 border-0 rounded-lg text-sm w-64" />
              </div>
            </div>
          </div>
        </section>

        {/* Items */}
        <section className="space-y-4">
          {filteredItems.map(item => (
            <CheckItemCard key={item.id} item={item} expanded={expandedId === item.id}
              onToggle={() => setExpandedId(expandedId === item.id ? null : item.id)}
              simulation={simulations[item.id]} isRunning={runningSimulations.has(item.id)}
              onRunSimulation={() => runSimulation(item.id)} />
          ))}
        </section>

        {/* Legend */}
        <section className="mt-10 pt-6 border-t border-gray-200">
          <div className="flex flex-wrap justify-center gap-6 text-sm text-gray-500">
            {Object.entries(statusConfig).map(([key, config]) => (
              <span key={key} className="flex items-center gap-2">
                <span className={`w-3 h-3 rounded-full ${config.color}`}></span>{config.label}
              </span>
            ))}
          </div>
        </section>
      </main>

      <footer className="mt-16 py-8 bg-white border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <p className="text-gray-600">© 2026 한국폴리텍대학 LMS 고도화 프로젝트</p>
          <p className="text-sm text-gray-400 mt-2">GrowAILMS - AI 기반 학습관리시스템</p>
        </div>
      </footer>
    </div>
  );
}

// ============================================================================
// Sub Components
// ============================================================================

function StatCard({ label, value, icon: Icon, gradient }: { label: string; value: number | string; icon: React.ElementType; gradient: string; }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm hover:shadow-md transition-shadow">
      <div className={`inline-flex p-2 rounded-lg bg-gradient-to-br ${gradient} text-white mb-3`}><Icon className="w-5 h-5" /></div>
      <div className="text-2xl font-bold text-gray-900">{value}</div>
      <div className="text-sm text-gray-500">{label}</div>
    </div>
  );
}

function CheckItemCard({ item, expanded, onToggle, simulation, isRunning, onRunSimulation }: {
  item: CheckItem; expanded: boolean; onToggle: () => void; simulation: SimulationResult | null; isRunning: boolean; onRunSimulation: () => void;
}) {
  const status = statusConfig[item.status];
  const priority = priorityConfig[item.priority];
  const StatusIcon = status.icon;
  const CategoryIcon = item.categoryIcon;
  const completedSubTasks = item.subTasks?.filter(t => t.completed).length || 0;
  const totalSubTasks = item.subTasks?.length || 0;

  return (
    <div className={`bg-white border rounded-xl overflow-hidden transition-all duration-300 shadow-sm hover:shadow-md ${expanded ? 'shadow-lg ring-2 ring-blue-500/20' : 'border-gray-200'}`}>
      <div className="p-5">
        <div className="flex items-start gap-4">
          <div className={`p-3 rounded-xl ${status.bgLight} shrink-0`}><CategoryIcon className={`w-6 h-6 ${status.textColor}`} /></div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2 flex-wrap">
              <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${status.color} text-white`}>
                <StatusIcon className={`w-3 h-3 ${item.status === 'in-progress' ? 'animate-spin' : ''}`} />{status.label}
              </span>
              <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${priority.bgColor} ${priority.color}`}>{priority.label}</span>
              <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">{item.category}</span>
              {simulation?.success && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700"><CheckCheck className="w-3 h-3" /> 시뮬레이션 완료</span>}
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-1">{item.id}. {item.title}</h3>
            <p className="text-sm text-gray-600 mb-3">{item.description}</p>
            <div className="flex items-center gap-4">
              <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                <div className={`h-full rounded-full transition-all duration-500 ${item.status === 'completed' ? 'bg-emerald-500' : item.status === 'in-progress' ? 'bg-blue-500' : 'bg-amber-500'}`} style={{ width: `${item.progress}%` }} />
              </div>
              <span className="text-sm font-semibold text-gray-700 w-12 text-right">{item.progress}%</span>
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button onClick={(e) => { e.stopPropagation(); onRunSimulation(); }} disabled={isRunning}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${simulation?.success ? 'bg-purple-100 text-purple-700 hover:bg-purple-200' : 'bg-blue-100 text-blue-700 hover:bg-blue-200'} disabled:opacity-50`}>
              {isRunning ? <Loader2 className="w-4 h-4 animate-spin" /> : simulation?.success ? <Eye className="w-4 h-4" /> : <Play className="w-4 h-4" />}
              {isRunning ? '실행중...' : simulation?.success ? '결과보기' : '테스트'}
            </button>
            <button onClick={onToggle} className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">
              {expanded ? <ChevronDown className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>

      {expanded && (
        <div className="px-5 pb-6 border-t border-gray-100">
          <div className="pt-5 grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="space-y-5">
              {item.aiFeatures && item.aiFeatures.length > 0 && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2"><Sparkles className="w-4 h-4 text-purple-500" /> AI 기능</h4>
                  <div className="flex flex-wrap gap-2">
                    {item.aiFeatures.map((f, i) => <span key={i} className="inline-flex items-center gap-1 px-3 py-1.5 bg-gradient-to-r from-purple-50 to-indigo-50 text-purple-700 rounded-lg text-sm border border-purple-100"><Bot className="w-3.5 h-3.5" />{f}</span>)}
                  </div>
                </div>
              )}
              <div>
                <h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2"><FileText className="w-4 h-4" /> 비고</h4>
                <p className="text-sm text-gray-600 bg-gray-50 rounded-lg p-3">{item.notes}</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div><h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2"><Users className="w-4 h-4" /> 담당</h4><p className="text-sm text-gray-900">{item.assignee}</p></div>
                <div><h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2"><Calendar className="w-4 h-4" /> 기한</h4><p className="text-sm text-gray-900">{item.dueDate}</p></div>
              </div>
              {item.relatedApis && item.relatedApis.length > 0 && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2"><Terminal className="w-4 h-4" /> API 엔드포인트</h4>
                  <div className="space-y-1.5">{item.relatedApis.map((api, i) => <code key={i} className="block text-xs bg-slate-800 text-emerald-400 px-3 py-2 rounded-lg font-mono">{api}</code>)}</div>
                </div>
              )}
              {item.subTasks && item.subTasks.length > 0 && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center justify-between"><span className="flex items-center gap-2"><ClipboardCheck className="w-4 h-4" /> 세부 작업</span><span className="text-xs text-gray-500 font-normal">{completedSubTasks}/{totalSubTasks} 완료</span></h4>
                  <div className="space-y-2">
                    {item.subTasks.map(task => (
                      <div key={task.id} className={`flex items-center gap-3 p-3 rounded-lg border transition-colors ${task.completed ? 'bg-emerald-50 border-emerald-200' : 'bg-gray-50 border-gray-200'}`}>
                        <div className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 ${task.completed ? 'bg-emerald-500' : 'bg-gray-300'}`}>{task.completed && <CheckCircle2 className="w-3 h-3 text-white" />}</div>
                        <span className={`text-sm ${task.completed ? 'text-emerald-700' : 'text-gray-700'}`}>{task.title}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="space-y-6">
              {simulation && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2"><Zap className="w-4 h-4 text-purple-500" /> 시뮬레이션 결과</h4>
                  <div className="bg-slate-900 rounded-xl p-4 text-sm font-mono overflow-x-auto" style={{ minHeight: '200px' }}>
                    <div className="flex items-center gap-2 mb-3">{simulation.success ? <CheckCircle2 className="w-4 h-4 text-emerald-400" /> : <XCircle className="w-4 h-4 text-red-400" />}<span className={simulation.success ? 'text-emerald-400' : 'text-red-400'}>{simulation.message}</span></div>
                    <div className="text-xs text-gray-500 mb-3">응답시간: {simulation.duration}ms | {new Date(simulation.timestamp).toLocaleTimeString('ko-KR')}</div>
                    <pre className="text-xs text-gray-300 overflow-y-auto" style={{ maxHeight: '120px' }}>{JSON.stringify(simulation.data, null, 2)}</pre>
                  </div>
                </div>
              )}
              {item.demoVideo && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2"><MonitorPlay className="w-4 h-4 text-purple-500" /> 실제 화면 시뮬레이션</h4>
                  <RealisticVideoPlayer demoType={item.demoVideo} itemId={item.id} />
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
