// types/index.ts — GrowAI LMS 공통 타입 정의

export type UserRole = 'student' | 'instructor' | 'admin';

export interface User {
  memberKey: string;
  userId: string;
  korName: string;
  engName?: string;
  email: string;
  mobile?: string;
  userType: '10' | '30' | '90'; // 10:학생, 30:교수, 90:관리자
  deptCode?: string;
  deptName?: string;
  campusCode?: string;
  campusName?: string;
  grade?: string;
  studentNo?: string;
}

export interface Course {
  courseCode: string;
  courseName: string;
  category: string;
  professorName: string;
  semester: string;
  credit: number;
  status: 'active' | 'closed' | 'upcoming';
  thumbnail?: string;
  description?: string;
  studentCount?: number;
  progress?: number;
}

export interface LectPlan {
  week: number;
  title: string;
  description: string;
  type: 'video' | 'assignment' | 'exam' | 'discussion';
  duration?: number;
  completed?: boolean;
}

export interface Attendance {
  courseCode: string;
  memberKey: string;
  week: number;
  status: 'present' | 'absent' | 'late' | 'excused';
  checkedAt?: string;
}

export interface Grade {
  courseCode: string;
  memberKey: string;
  midterm?: number;
  final?: number;
  assignment?: number;
  attendance?: number;
  total?: number;
  grade?: string;
}

export interface BoardPost {
  id: number;
  boardType: 'notice' | 'faq' | 'qna' | 'forum';
  title: string;
  content: string;
  author: string;
  createdAt: string;
  viewCount: number;
  commentCount?: number;
}

export type StatusType = 'completed' | 'in-progress' | 'pending' | 'blocked';
export type PriorityType = 'high' | 'medium' | 'low';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  count?: number;
}

export interface SyncStatus {
  enabled: boolean;
  lastSyncStatus: string;
  lastSyncTime?: string;
  successCount?: number;
  errorCount?: number;
}

export interface DashboardStats {
  totalCourses: number;
  totalStudents: number;
  completionRate: number;
  activeUsers: number;
}
