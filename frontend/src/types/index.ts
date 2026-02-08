// types/index.ts — 공통 타입 정의
export interface User {
  id: number;
  userId: string;
  name: string;
  email?: string;
  phone?: string;
  userType: 'STUDENT' | 'INSTRUCTOR' | 'ADMIN' | 'TUTOR';
  department?: string;
  campus?: string;
  campusCode?: string;
  studentNo?: string;
  groupCode?: string;
  status: string;
  lastLoginAt?: string;
}

export interface Course {
  id: number;
  courseCode: string;
  title: string;
  description?: string;
  category?: string;
  campus?: string;
  department?: string;
  instructorId?: number;
  instructorName?: string;
  credit?: number;
  totalWeeks?: number;
  startDate?: string;
  endDate?: string;
  openYear?: string;
  openTerm?: string;
  curriculumCode?: string;
  groupCode?: string;
  typeSyllabus?: string;
  isSyllabus?: string;
  thumbnailUrl?: string;
  status: string;
  maxStudents?: number;
  enrolledCount?: number;
  gradeLocked?: boolean;
}

export interface Enrollment {
  id: number;
  userId: number;
  courseId: number;
  bunbanCode?: string;
  status: string;
  progressPercent: number;
  completedAt?: string;
  enrolledAt: string;
}

export interface Lesson {
  id: number;
  courseId: number;
  weekNo: number;
  orderNo: number;
  title: string;
  contentType: string;
  contentUrl?: string;
  durationMinutes?: number;
  description?: string;
  isRequired: boolean;
  validFrom?: string;
  validTo?: string;
}

export interface Attendance {
  id: number;
  userId: number;
  lessonId: number;
  courseId: number;
  status: string;
  watchedSeconds: number;
  totalSeconds: number;
  progressPercent: number;
  completed: boolean;
}

export interface Grade {
  id: number;
  userId: number;
  courseId: number;
  attendanceScore: number;
  assignmentScore: number;
  examScore: number;
  totalScore: number;
  letterGrade?: string;
  passed: boolean;
  feedback?: string;
}

export interface GradeCriteria {
  id: number;
  courseId: number;
  attendanceRatio: number;
  assignmentRatio: number;
  midtermRatio: number;
  finalRatio: number;
  passScore: number;
  source: string;
  locked: boolean;
}

export interface Post {
  id: number;
  boardType: string;
  courseId?: number;
  title: string;
  content: string;
  authorId: number;
  authorName: string;
  viewCount: number;
  isPinned: boolean;
  createdAt: string;
}

export interface Comment {
  id: number;
  postId: number;
  authorId: number;
  authorName: string;
  content: string;
  createdAt: string;
}

export interface FraudLog {
  id: number;
  userId: number;
  fraudType: string;
  severity: string;
  ipAddress: string;
  detail?: string;
  campusCode?: string;
  resolved: boolean;
  createdAt: string;
}

export interface SyncLog {
  id: number;
  syncType: string;
  status: string;
  totalCount: number;
  successCount: number;
  failCount: number;
  errorMessage?: string;
  startedAt: string;
  completedAt?: string;
  triggeredBy: string;
}

export interface AiChatMessage {
  role: 'USER' | 'ASSISTANT';
  content: string;
  createdAt: string;
}

export interface AiRecommendation {
  id: number;
  userId: number;
  courseId: number;
  recommendType: string;
  score: number;
  reason: string;
  clicked: boolean;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  errorCode?: string;
  count?: number;
  timestamp: string;
}

// ── RFP 28건 기능정의서 타입 ──

// COM-003: GNB 메뉴
export interface MenuItem {
  id: number;
  parentId?: number;
  menuCode: string;
  menuName: string;
  menuPath?: string;
  icon?: string;
  sortOrder: number;
  roles: string[];
  isActive: boolean;
  children?: MenuItem[];
}

// COM-004: 통합 알림
export interface Notification {
  id: number;
  userId: number;
  type: 'JOB_DEADLINE' | 'APPROVAL' | 'ASSIGNMENT' | 'EXAM' | 'SYSTEM' | 'GRADE' | 'QNA';
  title: string;
  message: string;
  link?: string;
  isRead: boolean;
  readAt?: string;
  createdAt: string;
}

// COM-005: 통합 검색
export interface SearchResult {
  entityType: 'COURSE' | 'CONTENT' | 'JOB' | 'BOARD' | 'FAQ' | 'MENU';
  entityId: number;
  title: string;
  snippet?: string;
  campusCode?: string;
}

// STD-001: 학적 정보
export interface StudentProfile {
  id: number;
  userId: number;
  studentNo: string;
  department: string;
  gradeYear: number;
  gpa: number;
  totalCredits: number;
  campusCode: string;
  lastSyncAt?: string;
  syncSource: 'KPOLY_API' | 'MANUAL';
}

// STD-002: 역량 태그
export interface CompetencyTag {
  id: number;
  tagName: string;
  tagCategory: 'SKILL' | 'CERT' | 'NCS' | 'LANGUAGE' | 'TOOL';
  ncsCode?: string;
  ncsDescription?: string;
  color: string;
}

export interface UserCompetency {
  id: number;
  userId: number;
  tagId: number;
  tagName: string;
  tagCategory: string;
  source: 'COURSE' | 'CERT' | 'MANUAL' | 'AI_ANALYSIS';
  proficiency: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED' | 'EXPERT';
  acquiredAt?: string;
}

// STD-A01: AI 진로 상담
export interface CareerChatSession {
  id: number;
  userId: number;
  sessionId: string;
  title: string;
  messageCount: number;
  lastMessageAt?: string;
  createdAt: string;
}

export interface CareerChatMessage {
  id: number;
  sessionId: number;
  role: 'USER' | 'ASSISTANT' | 'SYSTEM';
  content: string;
  metadata?: Record<string, any>;
  createdAt: string;
}

// STD-A02: AI 자소서
export interface CoverLetter {
  id: number;
  userId: number;
  targetCompany: string;
  targetPosition: string;
  generatedContent: string;
  editedContent?: string;
  status: 'DRAFT' | 'EDITED' | 'FINAL';
  version: number;
  createdAt: string;
}

// STD-C01: 맞춤 공고 추천
export interface JobPosting {
  id: number;
  source: 'WORK24' | 'JOBKOREA' | 'SARAMIN' | 'MANUAL';
  companyName: string;
  positionTitle: string;
  location?: string;
  salaryInfo?: string;
  companySize?: string;
  description?: string;
  requirements?: string;
  keywords?: string[];
  deadline?: string;
  externalUrl?: string;
}

export interface JobRecommendation {
  id: number;
  userId: number;
  jobPostingId: number;
  jobPosting?: JobPosting;
  matchScore: number;
  matchedTags?: string[];
  reason?: string;
}

// STD-C02: 공고 스크랩
export interface JobScrap {
  id: number;
  userId: number;
  jobPostingId: number;
  jobPosting?: JobPosting;
  memo?: string;
  alertBeforeDays: number;
  createdAt: string;
}

// STD-L01: 역량 Gap 분석
export interface GapAnalysis {
  id: number;
  userId: number;
  targetJobCode: string;
  targetJobName: string;
  requiredTags: string[];
  ownedTags: string[];
  gapTags: string[];
  gapScore: number;
  radarData: { label: string; required: number; owned: number }[];
  analyzedAt: string;
}

// STD-L02: 콘텐츠 추천
export interface ContentRecommendation {
  id: number;
  userId: number;
  contentType: 'COURSE' | 'ELEARNING' | 'VIDEO' | 'DOCUMENT';
  contentId: number;
  contentTitle: string;
  contentThumbnail?: string;
  relevanceScore: number;
  reason: string;
  gapTagName?: string;
}

// PRF-001: 과거 강의
export interface LectureHistory {
  id: number;
  instructorId: number;
  courseCode: string;
  courseName: string;
  semester: string;
  year: number;
  description?: string;
  objectives?: string;
  syllabusData?: Record<string, any>;
}

// PRF-A01: AI 실라버스
export interface AiSyllabus {
  id: number;
  instructorId: number;
  subjectName: string;
  targetGrade: number;
  totalWeeks: number;
  generatedContent: { weekNo: number; topic: string; objective: string; method: string; note: string }[];
  ncsCodes?: string[];
  status: 'GENERATED' | 'EDITING' | 'SUBMITTED';
  version: number;
  createdAt: string;
}

// PRF-A02: 영상 추천
export interface VideoRecommendation {
  id: number;
  source: 'INTERNAL' | 'YOUTUBE' | 'KOLLUS';
  videoTitle: string;
  videoUrl: string;
  thumbnailUrl?: string;
  durationSeconds: number;
  relevanceScore: number;
}

// PRF-A03: 영상 요약
export interface VideoSummary {
  id: number;
  videoUrl: string;
  sttText?: string;
  summaryText: string;
  keywords: string[];
  qualityScore: number;
}

// PRF-E01: 커리큘럼 빌더
export interface CurriculumBuilder {
  id: number;
  instructorId: number;
  subjectId?: number;
  title: string;
  totalDurationMinutes: number;
  accreditedMinutes: number;
  status: 'DRAFT' | 'COMPLETE' | 'SUBMITTED';
  items: CurriculumItem[];
}

export interface CurriculumItem {
  id: number;
  builderId: number;
  weekNo: number;
  sortOrder: number;
  itemType: 'VIDEO' | 'DOCUMENT' | 'QUIZ' | 'ASSIGNMENT' | 'LINK';
  title: string;
  durationMinutes: number;
  fileUrl?: string;
}

// PRF-E02: AI 퀴즈
export interface AiGeneratedQuiz {
  id: number;
  sourceType: 'VIDEO_STT' | 'DOCUMENT' | 'MANUAL_TEXT';
  questions: { question: string; options: string[]; answer: string; explanation: string }[];
  questionCount: number;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  status: 'GENERATED' | 'REVIEWED' | 'REGISTERED';
}

// PRF-002: 강의계획서 제출
export interface SyllabusSubmission {
  id: number;
  instructorId: number;
  subjectId?: number;
  submissionStatus: 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED';
  submittedAt?: string;
  approvedAt?: string;
  rejectionReason?: string;
  kpolySyncStatus: 'PENDING' | 'SYNCED' | 'FAILED';
}

// ADM-001: 운영 모니터링
export interface SystemMetric {
  metricType: string;
  metricValue: number;
  metricUnit?: string;
  recordedAt: string;
}

// ADM-S01: 퍼널 분석
export interface TalentFunnel {
  stage: 'ADMISSION' | 'EDUCATION' | 'COMPLETION' | 'EMPLOYMENT';
  count: number;
  conversionRate: number;
  dropoutRate: number;
}

// ADM-S02: 역량 성취도
export interface CompetencyAchievement {
  userId: number;
  assessmentType: 'ENTRY' | 'EXIT' | 'PERIODIC';
  competencyScores: Record<string, number>;
  overallScore: number;
  aiUsageHours: number;
  employmentResult?: string;
}

// ADM-S03: 전공 일치 취업률
export interface EmploymentRecord {
  id: number;
  userId: number;
  companyName: string;
  companyIndustry: string;
  positionTitle: string;
  majorMatchScore: number;
  matchedSkills?: string[];
  hasInsurance: boolean;
}

// ADM-O01: 배너/팝업
export interface Banner {
  id: number;
  bannerType: 'MAIN_SLIDE' | 'SUB_BANNER' | 'EVENT';
  title: string;
  imageUrl: string;
  linkUrl?: string;
  sortOrder: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
}

export interface Popup {
  id: number;
  title: string;
  content?: string;
  imageUrl?: string;
  linkUrl?: string;
  width: number;
  height: number;
  posX: number;
  posY: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
}

// ADM-Y01: 접속 로그
export interface AccessLog {
  id: number;
  userId?: number;
  ipAddress: string;
  browser: string;
  os?: string;
  requestUrl: string;
  responseStatus: number;
  responseTimeMs: number;
  createdAt: string;
}

// ADM-Y02: 개인정보 열람 로그
export interface PrivacyAccessLog {
  id: number;
  accessorId: number;
  accessorName?: string;
  targetUserId: number;
  targetUserName?: string;
  accessReason: string;
  accessedFields: string[];
  ipAddress: string;
  isBulkAccess: boolean;
  alertSent: boolean;
  createdAt: string;
}
