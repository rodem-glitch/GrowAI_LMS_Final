// App.tsx — 라우팅 (메인 포탈 + 학생/교수자/관리자/학사정보 연동 + RFP 28건 전수)
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';
import { lazy, Suspense } from 'react';

// Layouts
import StudentLayout from '@/layouts/StudentLayout';
import InstructorLayout from '@/layouts/InstructorLayout';
import AdminLayout from '@/layouts/AdminLayout';
import HaksaLayout from '@/layouts/HaksaLayout';

// Main Portal
import MainPortalPage from '@/pages/MainPortalPage';
import LoginPage from '@/pages/student/member/LoginPage';

// Student Pages (기존)
import MainPage from '@/pages/student/MainPage';
import CourseListPage from '@/pages/student/course/CourseListPage';
import CourseDetailPage from '@/pages/student/course/CourseDetailPage';
import ClassroomPage from '@/pages/student/classroom/ClassroomPage';
import VideoPlayerPage from '@/pages/student/classroom/VideoPlayerPage';
import ExamPage from '@/pages/student/classroom/ExamPage';
import HomeworkPage from '@/pages/student/classroom/HomeworkPage';
import DashboardPage from '@/pages/student/mypage/DashboardPage';
import MyCourseListPage from '@/pages/student/mypage/MyCourseListPage';
import CertificatePage from '@/pages/student/mypage/CertificatePage';
import BoardListPage from '@/pages/student/board/BoardListPage';
import BoardDetailPage from '@/pages/student/board/BoardDetailPage';
import AiChatPage from '@/pages/student/ai/AiChatPage';

// Student Pages (RFP 신규: STD-001~L02)
import StudentProfilePage from '@/pages/student/profile/StudentProfilePage';
import CompetencyTagPage from '@/pages/student/competency/CompetencyTagPage';
import CareerChatPage from '@/pages/student/ai/CareerChatPage';
import CoverLetterPage from '@/pages/student/ai/CoverLetterPage';
import JobRecommendPage from '@/pages/student/career/JobRecommendPage';
import JobDetailPage from '@/pages/student/career/JobDetailPage';
import GapAnalysisPage from '@/pages/student/learning/GapAnalysisPage';
import ContentRecommendPage from '@/pages/student/learning/ContentRecommendPage';

// Instructor Pages (기존)
import InstructorDashboard from '@/pages/instructor/DashboardPage';
import CourseSearchPage from '@/pages/instructor/CourseSearchPage';
import InstructorMyCourseListPage from '@/pages/instructor/MyCourseListPage';
import AssignmentManagePage from '@/pages/instructor/AssignmentManagePage';
import QnaManagePage from '@/pages/instructor/QnaManagePage';
import CourseCreatePage from '@/pages/instructor/CourseCreatePage';
import ContentAllPage from '@/pages/instructor/content/ContentAllPage';
import ContentFavoritePage from '@/pages/instructor/content/ContentFavoritePage';
import ExamCategoryPage from '@/pages/instructor/exam/ExamCategoryPage';
import QuestionBankPage from '@/pages/instructor/exam/QuestionBankPage';
import ExamManagePage from '@/pages/instructor/exam/ExamManagePage';
import SubjectCreatePage from '@/pages/instructor/SubjectCreatePage';
import InstructorStatisticsPage from '@/pages/instructor/StatisticsPage';

// Instructor Pages (RFP 신규: PRF-001~002)
import PastLecturePage from '@/pages/instructor/lecture/PastLecturePage';
import AiSyllabusPage from '@/pages/instructor/ai/AiSyllabusPage';
import VideoRecommendPage from '@/pages/instructor/ai/VideoRecommendPage';
import VideoSummaryPage from '@/pages/instructor/ai/VideoSummaryPage';
import CurriculumBuilderPage from '@/pages/instructor/builder/CurriculumBuilderPage';
import AiQuizPage from '@/pages/instructor/ai/AiQuizPage';
import SyllabusSubmitPage from '@/pages/instructor/syllabus/SyllabusSubmitPage';
import LiveLecturePage from '@/pages/instructor/conference/LiveLecturePage';

// Admin Pages (기존)
import AdminDashboard from '@/pages/admin/DashboardPage';
import AdminCourseManage from '@/pages/admin/course/CourseManagePage';
import LearningManagePage from '@/pages/admin/management/LearningManagePage';
import CompletionManagePage from '@/pages/admin/management/CompletionManagePage';
import UserListPage from '@/pages/admin/user/UserListPage';
import UserDetailPage from '@/pages/admin/user/UserDetailPage';
import ContentManagePage from '@/pages/admin/content/ContentManagePage';
import StatisticsPage from '@/pages/admin/statistics/StatisticsPage';
import SiteSettingsPage from '@/pages/admin/settings/SiteSettingsPage';
import SyncDashboardPage from '@/pages/admin/sync/SyncDashboardPage';
import AntiFraudPage from '@/pages/admin/antifraud/AntiFraudPage';

// Admin Pages (RFP 신규: ADM-001~Y02)
import OperationsMonitorPage from '@/pages/admin/monitoring/OperationsMonitorPage';
import FunnelAnalysisPage from '@/pages/admin/statistics/FunnelAnalysisPage';
import CompetencyAchievementPage from '@/pages/admin/statistics/CompetencyAchievementPage';
import EmploymentMatchPage from '@/pages/admin/statistics/EmploymentMatchPage';
import UserControlPage from '@/pages/admin/user/UserControlPage';
import BannerManagePage from '@/pages/admin/cms/BannerManagePage';
import AccessLogPage from '@/pages/admin/log/AccessLogPage';
import PrivacyAccessLogPage from '@/pages/admin/log/PrivacyAccessLogPage';

// Admin Pages (LMS 플랫폼 + Apache Superset 통계)
import LmsPlatformPage from '@/pages/admin/LmsPlatformPage';
import SupersetDashboardPage from '@/pages/admin/SupersetDashboardPage';

// Common Pages (RFP 신규: COM-001~005)
import SearchPage from '@/pages/common/SearchPage';
import SSOCallbackPage from '@/pages/common/SSOCallbackPage';

// 시뮬레이션 (중간점검)
import MidCheckLandingPage from '@/pages/MidCheck';

// Haksa (학사정보 연동) Pages
import HaksaDashboard from '@/pages/haksa/DashboardPage';
import StudentRecordsPage from '@/pages/haksa/StudentRecordsPage';
import GradeManagePage from '@/pages/haksa/GradeManagePage';
import EnrollmentPage from '@/pages/haksa/EnrollmentPage';
import CalendarPage from '@/pages/haksa/CalendarPage';
import HaksaSyncPage from '@/pages/haksa/SyncPage';
import LogsPage from '@/pages/haksa/LogsPage';

export default function App() {
  const { isAuthenticated } = useAuthStore();

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/sso/callback" element={<SSOCallbackPage />} />
      <Route path="/simulation" element={<MidCheckLandingPage />} />

      {/* 메인 포탈 — 로그인 후 진입점 */}
      <Route path="/" element={isAuthenticated ? <MainPortalPage /> : <Navigate to="/login" />} />

      {/* 통합 검색 (COM-005) */}
      <Route path="/search" element={isAuthenticated ? <SearchPage /> : <Navigate to="/login" />} />

      {/* 학생 Routes */}
      <Route path="/student" element={isAuthenticated ? <StudentLayout /> : <Navigate to="/login" />}>
        <Route index element={<MainPage />} />
        <Route path="courses" element={<CourseListPage />} />
        <Route path="courses/:id" element={<CourseDetailPage />} />
        <Route path="classroom/:courseId" element={<ClassroomPage />} />
        <Route path="classroom/:courseId/video/:lessonId" element={<VideoPlayerPage />} />
        <Route path="classroom/:courseId/exam/:examId" element={<ExamPage />} />
        <Route path="classroom/:courseId/homework/:assignmentId" element={<HomeworkPage />} />
        <Route path="mypage" element={<DashboardPage />} />
        <Route path="mypage/courses" element={<MyCourseListPage />} />
        <Route path="mypage/certificates" element={<CertificatePage />} />
        <Route path="board" element={<BoardListPage />} />
        <Route path="board/:id" element={<BoardDetailPage />} />
        <Route path="ai-chat" element={<AiChatPage />} />
        {/* RFP 신규 학생 기능 */}
        <Route path="profile" element={<StudentProfilePage />} />
        <Route path="competency" element={<CompetencyTagPage />} />
        <Route path="career-chat" element={<CareerChatPage />} />
        <Route path="cover-letter" element={<CoverLetterPage />} />
        <Route path="jobs" element={<JobRecommendPage />} />
        <Route path="jobs/:id" element={<JobDetailPage />} />
        <Route path="gap-analysis" element={<GapAnalysisPage />} />
        <Route path="content-recommend" element={<ContentRecommendPage />} />
      </Route>

      {/* 교수자 Routes */}
      <Route path="/instructor" element={isAuthenticated ? <InstructorLayout /> : <Navigate to="/login" />}>
        <Route index element={<InstructorDashboard />} />
        <Route path="course-search" element={<CourseSearchPage />} />
        <Route path="my-courses" element={<InstructorMyCourseListPage />} />
        <Route path="assignments" element={<AssignmentManagePage />} />
        <Route path="qna" element={<QnaManagePage />} />
        <Route path="course-create" element={<CourseCreatePage />} />
        <Route path="content/all" element={<ContentAllPage />} />
        <Route path="content/favorites" element={<ContentFavoritePage />} />
        <Route path="exam/categories" element={<ExamCategoryPage />} />
        <Route path="exam/questions" element={<QuestionBankPage />} />
        <Route path="exam/manage" element={<ExamManagePage />} />
        <Route path="subject-create" element={<SubjectCreatePage />} />
        <Route path="statistics" element={<InstructorStatisticsPage />} />
        {/* RFP 신규 교수자 기능 */}
        <Route path="past-lectures" element={<PastLecturePage />} />
        <Route path="ai-syllabus" element={<AiSyllabusPage />} />
        <Route path="video-recommend" element={<VideoRecommendPage />} />
        <Route path="video-summary" element={<VideoSummaryPage />} />
        <Route path="curriculum-builder" element={<CurriculumBuilderPage />} />
        <Route path="ai-quiz" element={<AiQuizPage />} />
        <Route path="syllabus-submit" element={<SyllabusSubmitPage />} />
        <Route path="live-lecture" element={<LiveLecturePage />} />
      </Route>

      {/* 관리자 Routes */}
      <Route path="/admin" element={isAuthenticated ? <AdminLayout /> : <Navigate to="/login" />}>
        <Route index element={<AdminDashboard />} />
        <Route path="courses" element={<AdminCourseManage />} />
        <Route path="learning" element={<LearningManagePage />} />
        <Route path="completion" element={<CompletionManagePage />} />
        <Route path="users" element={<UserListPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="content" element={<ContentManagePage />} />
        <Route path="statistics" element={<StatisticsPage />} />
        <Route path="settings" element={<SiteSettingsPage />} />
        <Route path="sync" element={<SyncDashboardPage />} />
        <Route path="antifraud" element={<AntiFraudPage />} />
        {/* RFP 신규 관리자 기능 */}
        <Route path="monitoring" element={<OperationsMonitorPage />} />
        <Route path="funnel" element={<FunnelAnalysisPage />} />
        <Route path="competency-achievement" element={<CompetencyAchievementPage />} />
        <Route path="employment-match" element={<EmploymentMatchPage />} />
        <Route path="user-control" element={<UserControlPage />} />
        <Route path="banners" element={<BannerManagePage />} />
        <Route path="access-logs" element={<AccessLogPage />} />
        <Route path="privacy-logs" element={<PrivacyAccessLogPage />} />
        {/* LMS 플랫폼 + Apache Superset 통계 */}
        <Route path="lms-platform" element={<LmsPlatformPage />} />
        <Route path="superset-dashboard" element={<SupersetDashboardPage />} />
      </Route>

      {/* 학사정보 연동 Routes */}
      <Route path="/haksa" element={isAuthenticated ? <HaksaLayout /> : <Navigate to="/login" />}>
        <Route index element={<HaksaDashboard />} />
        <Route path="student-records" element={<StudentRecordsPage />} />
        <Route path="grades" element={<GradeManagePage />} />
        <Route path="enrollment" element={<EnrollmentPage />} />
        <Route path="calendar" element={<CalendarPage />} />
        <Route path="sync" element={<HaksaSyncPage />} />
        <Route path="logs" element={<LogsPage />} />
      </Route>
    </Routes>
  );
}
