// src/App.tsx — 루트 라우팅
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/useAuthStore';

// Layouts
import StudentLayout from '@/layouts/StudentLayout';
import AdminLayout from '@/layouts/AdminLayout';
import InstructorLayout from '@/layouts/InstructorLayout';

// Student Pages
import MainPage from '@/pages/student/MainPage';
import CourseListPage from '@/pages/student/course/CourseListPage';
import CourseDetailPage from '@/pages/student/course/CourseDetailPage';
import ClassroomPage from '@/pages/student/classroom/ClassroomPage';
import VideoPlayerPage from '@/pages/student/classroom/VideoPlayerPage';
import ExamPage from '@/pages/student/classroom/ExamPage';
import HomeworkPage from '@/pages/student/classroom/HomeworkPage';
import MyDashboardPage from '@/pages/student/mypage/DashboardPage';
import MyCourseListPage from '@/pages/student/mypage/MyCourseListPage';
import CertificatePage from '@/pages/student/mypage/CertificatePage';
import BoardListPage from '@/pages/student/board/BoardListPage';
import BoardDetailPage from '@/pages/student/board/BoardDetailPage';
import LoginPage from '@/pages/student/member/LoginPage';

// Instructor Pages
import InstructorDashboard from '@/pages/instructor/DashboardPage';
import InstructorCourseManage from '@/pages/instructor/CourseManagePage';
import InstructorStudentManage from '@/pages/instructor/StudentManagePage';

// Admin Pages
import AdminDashboard from '@/pages/admin/DashboardPage';
import AdminCourseManage from '@/pages/admin/course/CourseManagePage';
import AdminLearningManage from '@/pages/admin/management/LearningManagePage';
import AdminCompletionManage from '@/pages/admin/management/CompletionManagePage';
import AdminUserList from '@/pages/admin/user/UserListPage';
import AdminUserDetail from '@/pages/admin/user/UserDetailPage';
import AdminContentManage from '@/pages/admin/content/ContentManagePage';
import AdminStatistics from '@/pages/admin/statistics/StatisticsPage';
import AdminSiteSettings from '@/pages/admin/settings/SiteSettingsPage';

export default function App() {
  const role = useAuthStore((s) => s.role);

  return (
    <Routes>
      {/* 인증 */}
      <Route path="/login" element={<LoginPage />} />

      {/* 학생 */}
      <Route element={<StudentLayout />}>
        <Route path="/" element={<MainPage />} />
        <Route path="/courses" element={<CourseListPage />} />
        <Route path="/courses/:courseCode" element={<CourseDetailPage />} />
        <Route path="/classroom/:courseCode" element={<ClassroomPage />} />
        <Route path="/classroom/:courseCode/player/:week" element={<VideoPlayerPage />} />
        <Route path="/classroom/:courseCode/exam/:week" element={<ExamPage />} />
        <Route path="/classroom/:courseCode/homework/:week" element={<HomeworkPage />} />
        <Route path="/mypage" element={<MyDashboardPage />} />
        <Route path="/mypage/courses" element={<MyCourseListPage />} />
        <Route path="/mypage/certificates" element={<CertificatePage />} />
        <Route path="/board" element={<BoardListPage />} />
        <Route path="/board/:id" element={<BoardDetailPage />} />
      </Route>

      {/* 교수자 */}
      <Route path="/instructor" element={<InstructorLayout />}>
        <Route index element={<InstructorDashboard />} />
        <Route path="courses" element={<InstructorCourseManage />} />
        <Route path="students" element={<InstructorStudentManage />} />
      </Route>

      {/* 관리자 */}
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<AdminDashboard />} />
        <Route path="courses" element={<AdminCourseManage />} />
        <Route path="learning" element={<AdminLearningManage />} />
        <Route path="completion" element={<AdminCompletionManage />} />
        <Route path="users" element={<AdminUserList />} />
        <Route path="users/:memberKey" element={<AdminUserDetail />} />
        <Route path="content" element={<AdminContentManage />} />
        <Route path="statistics" element={<AdminStatistics />} />
        <Route path="settings" element={<AdminSiteSettings />} />
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
