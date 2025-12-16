import React, { useEffect, useState } from 'react';
import {
  Info,
  List,
  Users,
  ClipboardCheck,
  FileText,
  Briefcase,
  FolderOpen,
  MessageSquare,
  Award,
  CheckCircle,
  ArrowLeft,
  Download,
  Upload,
  Edit,
  Trash2,
  ChevronDown,
  ChevronRight,
  Play,
  Clock,
  Plus,
} from 'lucide-react';
import { SessionEditModal } from './SessionEditModal';
import { CourseInfoTab } from './CourseInfoTabs';
import { ExamCreateModal } from './ExamCreateModal';
import { AssignmentCreateModal } from './AssignmentCreateModal';

interface CourseManagementProps {
  course: {
    id: string;
    courseId: string;
    courseType: string;
    subjectName: string;
    programId: number;
    programName: string;
    period: string;
    students: number;
    status: string;
  };
  onBack: () => void;
}

type TabType =
  | 'info'
  | 'curriculum'
  | 'students'
  | 'attendance'
  | 'exam'
  | 'assignment'
  | 'assignment-management'
  | 'assignment-feedback'
  | 'materials'
  | 'qna'
  | 'grades'
  | 'completion';

export function CourseManagement({ course: initialCourse, onBack }: CourseManagementProps) {
  const [course, setCourse] = useState(initialCourse);
  const [activeTab, setActiveTab] = useState<TabType>('info');
  const [isAssignmentExpanded, setIsAssignmentExpanded] = useState(false);

  useEffect(() => {
    setCourse(initialCourse);
  }, [initialCourse]);

  const tabs = [
    { id: 'info' as TabType, label: '과목정보', icon: Info, isSubTab: false },
    { id: 'curriculum' as TabType, label: '강의목차', icon: List, isSubTab: false },
    { id: 'students' as TabType, label: '수강생', icon: Users, isSubTab: false },
    { id: 'attendance' as TabType, label: '진도/출석', icon: ClipboardCheck, isSubTab: false },
    { id: 'exam' as TabType, label: '시험', icon: FileText, isSubTab: false },
    { id: 'assignment' as TabType, label: '과제', icon: Briefcase, isSubTab: false, hasSubTabs: true },
    { id: 'materials' as TabType, label: '자료', icon: FolderOpen, isSubTab: false },
    { id: 'qna' as TabType, label: 'Q&A', icon: MessageSquare, isSubTab: false },
    { id: 'grades' as TabType, label: '성적관리', icon: Award, isSubTab: false },
    { id: 'completion' as TabType, label: '수료관리', icon: CheckCircle, isSubTab: false },
  ];

  const assignmentSubTabs = [
    { id: 'assignment-management' as TabType, label: '과제 관리', icon: Briefcase },
    { id: 'assignment-feedback' as TabType, label: '피드백 관리', icon: MessageSquare },
  ];

  const handleTabClick = (tabId: TabType) => {
    if (tabId === 'assignment') {
      setIsAssignmentExpanded(!isAssignmentExpanded);
      if (!isAssignmentExpanded) {
        // 펼칠 때는 첫 번째 하위 탭으로 이동
        setActiveTab('assignment-management');
      }
    } else {
      setActiveTab(tabId);
      // 다른 탭을 클릭하면 과제 탭 축소
      if (tabId !== 'assignment-management' && tabId !== 'assignment-feedback') {
        setIsAssignmentExpanded(false);
      }
    }
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'info':
        return <CourseInfoTab course={course} onCourseUpdated={setCourse} />;
      case 'curriculum':
        return <CurriculumTab />;
      case 'students':
        return <StudentsTab />;
      case 'attendance':
        return <AttendanceTab />;
      case 'exam':
        return <ExamTab />;
      case 'assignment':
        return <AssignmentTab />;
      case 'assignment-management':
        return <AssignmentManagementTab />;
      case 'assignment-feedback':
        return <AssignmentFeedbackTab />;
      case 'materials':
        return <MaterialsTab />;
      case 'qna':
        return <QnaTab />;
      case 'grades':
        return <GradesTab />;
      case 'completion':
        return <CompletionTab />;
      default:
        return null;
    }
  };

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          <span>목록으로 돌아가기</span>
        </button>
        <h2 className="text-gray-900 mb-2">{course.subjectName}</h2>
        <div className="flex items-center gap-4 text-sm text-gray-600">
          <span>과정ID: {course.courseId}</span>
          <span>•</span>
          <span>{course.courseType}</span>
          <span>•</span>
          <span>{course.period}</span>
          <span>•</span>
          <span>수강생: {course.students}명</span>
        </div>
      </div>

      {/* Vertical Tabs Layout */}
      <div className="flex gap-6">
        {/* Left Sidebar - Vertical Tabs */}
        <div className="w-64 flex-shrink-0">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden sticky top-6">
            <nav className="flex flex-col">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                const isAssignmentTab = tab.id === 'assignment';
                const isActive = activeTab === tab.id || 
                  (isAssignmentTab && (activeTab === 'assignment-management' || activeTab === 'assignment-feedback'));
                
                return (
                  <React.Fragment key={tab.id}>
                    <button
                      onClick={() => handleTabClick(tab.id)}
                      className={`flex items-center justify-between px-4 py-3 border-l-4 transition-colors text-left ${
                        isActive
                          ? 'border-blue-600 bg-blue-50 text-blue-700'
                          : 'border-transparent text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Icon className="w-5 h-5" />
                        <span>{tab.label}</span>
                      </div>
                      {isAssignmentTab && (
                        isAssignmentExpanded ? (
                          <ChevronDown className="w-4 h-4" />
                        ) : (
                          <ChevronRight className="w-4 h-4" />
                        )
                      )}
                    </button>
                    
                    {/* 과제 하위 탭 */}
                    {isAssignmentTab && isAssignmentExpanded && (
                      <div className="bg-gray-50">
                        {assignmentSubTabs.map((subTab) => {
                          const SubIcon = subTab.icon;
                          return (
                            <button
                              key={subTab.id}
                              onClick={() => {
                                setActiveTab(subTab.id);
                              }}
                              className={`w-full flex items-center gap-3 pl-12 pr-4 py-2.5 border-l-4 transition-colors text-left text-sm ${
                                activeTab === subTab.id
                                  ? 'border-blue-600 bg-blue-100 text-blue-700'
                                  : 'border-transparent text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                              }`}
                            >
                              <SubIcon className="w-4 h-4" />
                              <span>{subTab.label}</span>
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </React.Fragment>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Right Content Area */}
        <div className="flex-1 min-w-0">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            {renderTabContent()}
          </div>
        </div>
      </div>
    </div>
  );
}

// 과목정보 탭 (이제 CourseInfoTabs.tsx에서 import됨)

// 강의목차 탭
function CurriculumTab() {
  const [expandedSession, setExpandedSession] = useState<number | null>(null);
  const [editingSession, setEditingSession] = useState<any | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  const [sessions, setSessions] = useState([
    {
      id: 1,
      title: 'HTML 기초와 웹 표준',
      description: 'HTML 태그의 기본 구조와 웹 표준에 대해 학습합니다',
      duration: '3시간',
      status: '완료',
      videos: [
        { id: 1, title: 'HTML 소개와 기본 구조', duration: '45분', url: 'video1.mp4' },
        { id: 2, title: '주요 HTML 태그 활용', duration: '60분', url: 'video2.mp4' },
        { id: 3, title: '시맨틱 태그와 웹 접근성', duration: '55분', url: 'video3.mp4' },
      ],
    },
    {
      id: 2,
      title: 'CSS 스타일링과 레이아웃',
      description: 'CSS를 활용한 웹 페이지 디자인 기법을 배웁니다',
      duration: '3시간',
      status: '완료',
      videos: [
        { id: 1, title: 'CSS 선택자와 속성', duration: '50분', url: 'video4.mp4' },
        { id: 2, title: 'Flexbox 레이아웃', duration: '70분', url: 'video5.mp4' },
      ],
    },
    {
      id: 3,
      title: 'JavaScript 기본 문법',
      description: 'JavaScript의 기본 문법과 변수, 함수 등을 학습합니다',
      duration: '3시간',
      status: '진행중',
      videos: [
        { id: 1, title: 'JavaScript 소개', duration: '40min', url: 'video6.mp4' },
        { id: 2, title: '변수와 데이터 타입', duration: '55min', url: 'video7.mp4' },
        { id: 3, title: '함수와 스코프', duration: '65min', url: 'video8.mp4' },
      ],
    },
    {
      id: 4,
      title: 'DOM 조작과 이벤트 처리',
      description: 'DOM API를 사용하여 동적인 웹 페이지를 만드는 방법을 학습합니다',
      duration: '3시간',
      status: '예정',
      videos: [
        { id: 1, title: 'DOM 이해하기', duration: '45min', url: 'video9.mp4' },
        { id: 2, title: '이벤트 핸들링', duration: '60min', url: 'video10.mp4' },
      ],
    },
    {
      id: 5,
      title: '반응형 웹 디자인',
      description: '다양한 디바이스에 대응하는 반응형 웹 디자인을 구현합니다',
      duration: '3시간',
      status: '예정',
      videos: [
        { id: 1, title: '미디어 쿼리 기초', duration: '50min', url: 'video11.mp4' },
        { id: 2, title: '모바일 퍼스트 접근법', duration: '70min', url: 'video12.mp4' },
      ],
    },
    {
      id: 6,
      title: '웹 프로젝트 실습',
      description: '지금까지 배운 내용을 활용하여 완성도 있는 웹 페이지를 제작합니다',
      duration: '3시간',
      status: '예정',
      videos: [
        { id: 1, title: '프로젝트 기획 및 설계', duration: '60min', url: 'video13.mp4' },
        { id: 2, title: '프로젝트 개발 실습', duration: '90min', url: 'video14.mp4' },
        { id: 3, title: '코드 리뷰 및 개선', duration: '30min', url: 'video15.mp4' },
      ],
    },
  ]);

  const toggleSession = (sessionId: number) => {
    setExpandedSession(expandedSession === sessionId ? null : sessionId);
  };

  const handleEditSession = (session: any) => {
    setEditingSession(session);
    setIsEditModalOpen(true);
  };

  const handleSaveSession = (updatedSession: any) => {
    setSessions((prevSessions) =>
      prevSessions.map((session) =>
        session.id === updatedSession.id ? updatedSession : session
      )
    );
    setIsEditModalOpen(false);
    setEditingSession(null);
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center mb-4">
        <div className="text-sm text-gray-600">총 {sessions.length}개 차시</div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Plus className="w-4 h-4" />
          <span>차시 추가</span>
        </button>
      </div>

      {sessions.map((session) => {
        const isExpanded = expandedSession === session.id;

        return (
          <div key={session.id} className="border border-gray-200 rounded-lg overflow-hidden">
            {/* 차시 헤더 */}
            <button
              onClick={() => toggleSession(session.id)}
              className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="flex items-center justify-center w-12 h-12 bg-blue-100 text-blue-700 rounded-lg shrink-0">
                  {session.id}차시
                </div>
                <div className="text-left">
                  <div className="text-gray-900 mb-1">{session.title}</div>
                  <div className="text-sm text-gray-600 flex items-center gap-3">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {session.duration}
                    </span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Play className="w-3 h-3" />
                      {session.videos.length}개 영상
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <span
                  className={`px-3 py-1 text-xs rounded-full ${
                    session.status === '완료'
                      ? 'bg-green-100 text-green-700'
                      : session.status === '진행중'
                      ? 'bg-blue-100 text-blue-700'
                      : 'bg-gray-100 text-gray-700'
                  }`}
                >
                  {session.status}
                </span>
                {isExpanded ? (
                  <ChevronDown className="w-5 h-5 text-gray-400" />
                ) : (
                  <ChevronRight className="w-5 h-5 text-gray-400" />
                )}
              </div>
            </button>

            {/* 확장된 영상 목록 */}
            {isExpanded && (
              <div className="border-t border-gray-200 bg-gray-50 p-4">
                {/* 차시 설명 */}
                <div className="mb-4 px-4 py-3 bg-blue-50 border border-blue-200 rounded-lg">
                  <p className="text-sm text-blue-900">{session.description}</p>
                </div>

                {/* 영상 목록 */}
                <div className="space-y-2">
                  <div className="text-sm text-gray-700 mb-2 px-1">강의 영상</div>
                  {session.videos.map((video, index) => (
                    <div
                      key={video.id}
                      className="flex items-center justify-between p-3 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-700 rounded-lg text-sm shrink-0">
                          {index + 1}
                        </div>
                        <div>
                          <div className="text-sm text-gray-900">{video.title}</div>
                          <div className="text-xs text-gray-600 flex items-center gap-1 mt-0.5">
                            <Clock className="w-3 h-3" />
                            {video.duration}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => alert(`${video.title} 재생`)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        >
                          <Play className="w-4 h-4" />
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            alert(`${video.title} 수정`);
                          }}
                          className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                {/* 액션 버튼 */}
                <div className="mt-4 pt-4 border-t border-gray-200 flex justify-end gap-2">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      alert(`${session.title} 영상 추가`);
                    }}
                    className="px-3 py-1.5 text-sm text-blue-600 border border-blue-300 rounded-lg hover:bg-blue-50 transition-colors"
                  >
                    영상 추가
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleEditSession(session);
                    }}
                    className="px-3 py-1.5 text-sm text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    차시 수정
                  </button>
                </div>
              </div>
            )}
          </div>
        );
      })}

      {/* 차시 수정 모달 */}
      {editingSession && (
        <SessionEditModal
          isOpen={isEditModalOpen}
          onClose={() => {
            setIsEditModalOpen(false);
            setEditingSession(null);
          }}
          session={editingSession}
          onSave={handleSaveSession}
        />
      )}
    </div>
  );
}

// 수강생 탭
function StudentsTab() {
  const students = [
    { id: 1, name: '김민수', studentId: '2024001', email: 'minsu@example.com', progress: 85 },
    { id: 2, name: '이지현', studentId: '2024002', email: 'jihyun@example.com', progress: 92 },
    { id: 3, name: '박준호', studentId: '2024003', email: 'junho@example.com', progress: 78 },
    { id: 4, name: '최서연', studentId: '2024004', email: 'seoyeon@example.com', progress: 95 },
    { id: 5, name: '정우진', studentId: '2024005', email: 'woojin@example.com', progress: 88 },
  ];

  return (
    <div>
      <div className="mb-4 flex justify-between items-center">
        <div className="text-sm text-gray-600">총 {students.length}명</div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Download className="w-4 h-4" />
          <span>엑셀 다운로드</span>
        </button>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이메일</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {students.map((student, index) => (
              <tr key={student.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                <td className="px-4 py-4 text-sm text-gray-900">{student.studentId}</td>
                <td className="px-4 py-4 text-sm text-gray-900">{student.name}</td>
                <td className="px-4 py-4 text-sm text-gray-600">{student.email}</td>
                <td className="px-4 py-4">
                  <div className="flex items-center justify-center gap-2">
                    <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-600 rounded-full"
                        style={{ width: `${student.progress}%` }}
                      />
                    </div>
                    <span className="text-sm text-gray-900">{student.progress}%</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// 진도/출석 탭
function AttendanceTab() {
  const [selectedSession, setSelectedSession] = useState<number>(1);

  // 차시 목록
  const sessions = [
    { id: 1, title: 'HTML 기초와 웹 표준', totalVideos: 3 },
    { id: 2, title: 'CSS 스타일링과 레이아웃', totalVideos: 2 },
    { id: 3, title: 'JavaScript 기본 문법', totalVideos: 3 },
    { id: 4, title: 'DOM 조작과 이벤트 처리', totalVideos: 2 },
    { id: 5, title: '반응형 웹 디자인', totalVideos: 2 },
    { id: 6, title: '웹 프로젝트 실습', totalVideos: 3 },
  ];

  // 학생 목록
  const students = [
    { id: 1, name: '김민수', studentId: '2024001' },
    { id: 2, name: '이지현', studentId: '2024002' },
    { id: 3, name: '박준호', studentId: '2024003' },
    { id: 4, name: '최서연', studentId: '2024004' },
    { id: 5, name: '정우진', studentId: '2024005' },
  ];

  // 차시별 학생 진도 데이터
  const sessionProgress = {
    1: [
      { studentId: 1, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.15' },
      { studentId: 2, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.14' },
      { studentId: 3, watchedVideos: 2, totalVideos: 3, completionRate: 67, lastWatched: '2024.03.16' },
      { studentId: 4, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.13' },
      { studentId: 5, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.15' },
    ],
    2: [
      { studentId: 1, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.03.22' },
      { studentId: 2, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.03.21' },
      { studentId: 3, watchedVideos: 1, totalVideos: 2, completionRate: 50, lastWatched: '2024.03.23' },
      { studentId: 4, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.03.20' },
      { studentId: 5, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.03.22' },
    ],
    3: [
      { studentId: 1, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.29' },
      { studentId: 2, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.28' },
      { studentId: 3, watchedVideos: 2, totalVideos: 3, completionRate: 67, lastWatched: '2024.03.30' },
      { studentId: 4, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.27' },
      { studentId: 5, watchedVideos: 3, totalVideos: 3, completionRate: 100, lastWatched: '2024.03.29' },
    ],
    4: [
      { studentId: 1, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.05' },
      { studentId: 2, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.04' },
      { studentId: 3, watchedVideos: 1, totalVideos: 2, completionRate: 50, lastWatched: '2024.04.06' },
      { studentId: 4, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.03' },
      { studentId: 5, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.05' },
    ],
    5: [
      { studentId: 1, watchedVideos: 1, totalVideos: 2, completionRate: 50, lastWatched: '2024.04.12' },
      { studentId: 2, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.11' },
      { studentId: 3, watchedVideos: 0, totalVideos: 2, completionRate: 0, lastWatched: '-' },
      { studentId: 4, watchedVideos: 2, totalVideos: 2, completionRate: 100, lastWatched: '2024.04.10' },
      { studentId: 5, watchedVideos: 1, totalVideos: 2, completionRate: 50, lastWatched: '2024.04.12' },
    ],
    6: [
      { studentId: 1, watchedVideos: 0, totalVideos: 3, completionRate: 0, lastWatched: '-' },
      { studentId: 2, watchedVideos: 1, totalVideos: 3, completionRate: 33, lastWatched: '2024.04.15' },
      { studentId: 3, watchedVideos: 0, totalVideos: 3, completionRate: 0, lastWatched: '-' },
      { studentId: 4, watchedVideos: 2, totalVideos: 3, completionRate: 67, lastWatched: '2024.04.14' },
      { studentId: 5, watchedVideos: 0, totalVideos: 3, completionRate: 0, lastWatched: '-' },
    ],
  };

  // 차시별 출석률 계산
  const getSessionAttendance = (sessionId: number) => {
    const progress = sessionProgress[sessionId];
    const completed = progress.filter((p) => p.completionRate === 100).length;
    return Math.round((completed / progress.length) * 100);
  };

  // 선택된 차시의 진도 데이터
  const currentSessionProgress = sessionProgress[selectedSession];

  return (
    <div className="space-y-4">
      <div className="mb-4 flex justify-between items-center">
        <div className="text-sm text-gray-600">총 {students.length}명 • {sessions.length}개 차시</div>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Download className="w-4 h-4" />
          <span>엑셀 다운로드</span>
        </button>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* 왼쪽: 차시 목록 */}
        <div className="col-span-1">
          <div className="bg-gray-50 px-4 py-3 rounded-t-lg border border-b-0 border-gray-200">
            <h4 className="text-gray-900">차시 목록</h4>
          </div>
          <div className="border border-gray-200 rounded-b-lg divide-y divide-gray-200">
            {sessions.map((session) => {
              const attendance = getSessionAttendance(session.id);
              const isSelected = selectedSession === session.id;

              return (
                <button
                  key={session.id}
                  onClick={() => setSelectedSession(session.id)}
                  className={`w-full p-4 text-left transition-colors ${
                    isSelected
                      ? 'bg-blue-50 border-l-4 border-blue-600'
                      : 'hover:bg-gray-50 border-l-4 border-transparent'
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-700 rounded-lg text-sm shrink-0">
                        {session.id}
                      </div>
                      <div className="text-sm text-gray-900">{session.title}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 mt-2 pl-10">
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs text-gray-600">출석률</span>
                        <span className="text-xs text-gray-900">{attendance}%</span>
                      </div>
                      <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${
                            attendance >= 80
                              ? 'bg-green-600'
                              : attendance >= 60
                              ? 'bg-yellow-600'
                              : 'bg-red-600'
                          }`}
                          style={{ width: `${attendance}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* 오른쪽: 학생별 진도율 */}
        <div className="col-span-2">
          <div className="bg-gray-50 px-4 py-3 rounded-t-lg border border-b-0 border-gray-200">
            <h4 className="text-gray-900">
              {sessions.find((s) => s.id === selectedSession)?.title} - 학생별 진도
            </h4>
          </div>
          <div className="border border-gray-200 rounded-b-lg">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
                    <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
                    <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                    <th className="px-4 py-3 text-center text-sm text-gray-700">시청 영상</th>
                    <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
                    <th className="px-4 py-3 text-center text-sm text-gray-700">최근 시청일</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {students.map((student, index) => {
                    const progress = currentSessionProgress.find((p) => p.studentId === student.id);
                    if (!progress) return null;

                    return (
                      <tr key={student.id} className="hover:bg-gray-50 transition-colors">
                        <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                        <td className="px-4 py-4 text-sm text-gray-900">{student.studentId}</td>
                        <td className="px-4 py-4 text-sm text-gray-900">{student.name}</td>
                        <td className="px-4 py-4 text-center">
                          <span className="text-sm text-gray-900">
                            {progress.watchedVideos} / {progress.totalVideos}
                          </span>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center justify-center gap-2">
                            <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                              <div
                                className={`h-full rounded-full ${
                                  progress.completionRate === 100
                                    ? 'bg-green-600'
                                    : progress.completionRate >= 50
                                    ? 'bg-yellow-600'
                                    : 'bg-red-600'
                                }`}
                                style={{ width: `${progress.completionRate}%` }}
                              />
                            </div>
                            <span className="text-sm text-gray-900 w-12 text-right">
                              {progress.completionRate}%
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-center text-sm text-gray-600">
                          {progress.lastWatched}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* 통계 요약 */}
            <div className="border-t border-gray-200 p-4 bg-gray-50">
              <div className="grid grid-cols-4 gap-4">
                <div className="text-center">
                  <div className="text-sm text-gray-600 mb-1">완료</div>
                  <div className="text-xl text-green-700">
                    {currentSessionProgress.filter((p) => p.completionRate === 100).length}명
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-600 mb-1">진행중</div>
                  <div className="text-xl text-yellow-700">
                    {
                      currentSessionProgress.filter(
                        (p) => p.completionRate > 0 && p.completionRate < 100
                      ).length
                    }
                    명
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-600 mb-1">미시청</div>
                  <div className="text-xl text-red-700">
                    {currentSessionProgress.filter((p) => p.completionRate === 0).length}명
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-600 mb-1">평균 진도율</div>
                  <div className="text-xl text-blue-700">
                    {Math.round(
                      currentSessionProgress.reduce((sum, p) => sum + p.completionRate, 0) /
                        currentSessionProgress.length
                    )}
                    %
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// 시험 탭
function ExamTab() {
  const [selectedExam, setSelectedExam] = useState<number | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const exams = [
    { id: 1, title: '중간고사', date: '2024.04.15', duration: '90분', submitted: 25, total: 28 },
    { id: 2, title: '기말고사', date: '2024.06.20', duration: '90분', submitted: 0, total: 28 },
  ];

  // 학생별 시험 점수 데이터
  const examScores = {
    1: [
      { studentId: '2024001', name: '김민수', score: 85, submitted: true, submittedAt: '2024.04.15 14:30' },
      { studentId: '2024002', name: '이지현', score: 92, submitted: true, submittedAt: '2024.04.15 14:25' },
      { studentId: '2024003', name: '박준호', score: 78, submitted: true, submittedAt: '2024.04.15 14:45' },
      { studentId: '2024004', name: '최서연', score: 95, submitted: true, submittedAt: '2024.04.15 14:20' },
      { studentId: '2024005', name: '정우진', score: 88, submitted: true, submittedAt: '2024.04.15 14:35' },
      { studentId: '2024006', name: '강민지', score: 82, submitted: true, submittedAt: '2024.04.15 14:40' },
      { studentId: '2024007', name: '윤서준', score: 90, submitted: true, submittedAt: '2024.04.15 14:28' },
      { studentId: '2024008', name: '장예은', score: 76, submitted: true, submittedAt: '2024.04.15 14:50' },
      { studentId: '2024009', name: '조현우', score: 88, submitted: true, submittedAt: '2024.04.15 14:32' },
      { studentId: '2024010', name: '한지우', score: 94, submitted: true, submittedAt: '2024.04.15 14:22' },
      { studentId: '2024011', name: '송민호', score: 80, submitted: true, submittedAt: '2024.04.15 14:38' },
      { studentId: '2024012', name: '임수빈', score: 86, submitted: true, submittedAt: '2024.04.15 14:33' },
      { studentId: '2024013', name: '오지훈', score: 72, submitted: true, submittedAt: '2024.04.15 14:55' },
      { studentId: '2024014', name: '백서현', score: 91, submitted: true, submittedAt: '2024.04.15 14:26' },
      { studentId: '2024015', name: '신동욱', score: 84, submitted: true, submittedAt: '2024.04.15 14:36' },
      { studentId: '2024016', name: '홍유진', score: 89, submitted: true, submittedAt: '2024.04.15 14:31' },
      { studentId: '2024017', name: '권태양', score: 77, submitted: true, submittedAt: '2024.04.15 14:48' },
      { studentId: '2024018', name: '노은별', score: 93, submitted: true, submittedAt: '2024.04.15 14:24' },
      { studentId: '2024019', name: '남궁민', score: 81, submitted: true, submittedAt: '2024.04.15 14:39' },
      { studentId: '2024020', name: '서하윤', score: 87, submitted: true, submittedAt: '2024.04.15 14:34' },
      { studentId: '2024021', name: '양준석', score: 79, submitted: true, submittedAt: '2024.04.15 14:46' },
      { studentId: '2024022', name: '유채원', score: 85, submitted: true, submittedAt: '2024.04.15 14:37' },
      { studentId: '2024023', name: '이다은', score: 90, submitted: true, submittedAt: '2024.04.15 14:29' },
      { studentId: '2024024', name: '전시우', score: 83, submitted: true, submittedAt: '2024.04.15 14:41' },
      { studentId: '2024025', name: '최지호', score: 88, submitted: true, submittedAt: '2024.04.15 14:35' },
      { studentId: '2024026', name: '표재민', score: 0, submitted: false, submittedAt: '-' },
      { studentId: '2024027', name: '하윤아', score: 0, submitted: false, submittedAt: '-' },
      { studentId: '2024028', name: '황수아', score: 0, submitted: false, submittedAt: '-' },
    ],
    2: [],
  };

  if (selectedExam !== null) {
    const exam = exams.find((e) => e.id === selectedExam);
    const scores = examScores[selectedExam];
    
    return <ExamDetailView exam={exam} scores={scores} onBack={() => setSelectedExam(null)} />;
  }

  return (
    <>
      <div className="space-y-4">
        <div className="flex justify-end">
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <FileText className="w-4 h-4" />
            <span>시험 등록</span>
          </button>
        </div>
        {exams.map((exam) => (
          <button
            key={exam.id}
            onClick={() => setSelectedExam(exam.id)}
            className="w-full p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="text-gray-900 mb-1">{exam.title}</div>
                <div className="text-sm text-gray-600">
                  시험일: {exam.date} • 시험시간: {exam.duration}
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <div className="text-sm text-gray-600">제출 현황</div>
                  <div className="text-gray-900">
                    {exam.submitted} / {exam.total}명
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </div>
            </div>
          </button>
        ))}
      </div>
      
      <ExamCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={(examData) => {
          console.log('새 시험 등록:', examData);
          alert('시험이 등록되었습니다.');
        }}
      />
    </>
  );
}

// 시험 상세 화면
function ExamDetailView({ exam, scores, onBack }: { exam: any; scores: any[]; onBack: () => void }) {
  const [editingScore, setEditingScore] = useState<string | null>(null);
  const [tempScore, setTempScore] = useState<string>('');
  const [studentScores, setStudentScores] = useState(scores);

  const submittedScores = studentScores.filter((s) => s.submitted);
  
  // 통계 계산
  const stats = {
    average: submittedScores.length > 0 
      ? Math.round(submittedScores.reduce((sum, s) => sum + s.score, 0) / submittedScores.length * 10) / 10
      : 0,
    highest: submittedScores.length > 0 ? Math.max(...submittedScores.map((s) => s.score)) : 0,
    lowest: submittedScores.length > 0 ? Math.min(...submittedScores.map((s) => s.score)) : 0,
    submitted: submittedScores.length,
    total: studentScores.length,
  };

  // 점수 구간별 분포 계산
  const getScoreDistribution = () => {
    const ranges = [
      { range: '90-100', min: 90, max: 100, count: 0 },
      { range: '80-89', min: 80, max: 89, count: 0 },
      { range: '70-79', min: 70, max: 79, count: 0 },
      { range: '60-69', min: 60, max: 69, count: 0 },
      { range: '0-59', min: 0, max: 59, count: 0 },
    ];

    submittedScores.forEach((student) => {
      const range = ranges.find((r) => student.score >= r.min && student.score <= r.max);
      if (range) range.count++;
    });

    return ranges;
  };

  const distribution = getScoreDistribution();

  // 엑셀 다운로드 함수
  const handleDownloadExcel = () => {
    alert('엑셀 다운로드 기능 (실제로는 CSV/XLSX 생성)');
  };

  // 점수 수정 시작
  const handleStartEdit = (studentId: string, currentScore: number) => {
    setEditingScore(studentId);
    setTempScore(currentScore.toString());
  };

  // 점수 수정 저장
  const handleSaveScore = (studentId: string) => {
    const newScore = parseInt(tempScore);
    if (isNaN(newScore) || newScore < 0 || newScore > 100) {
      alert('점수는 0~100 사이의 숫자여야 합니다.');
      return;
    }

    setStudentScores((prev) =>
      prev.map((student) =>
        student.studentId === studentId ? { ...student, score: newScore } : student
      )
    );
    setEditingScore(null);
    setTempScore('');
  };

  // 점수 수정 취소
  const handleCancelEdit = () => {
    setEditingScore(null);
    setTempScore('');
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h3 className="text-xl text-gray-900">{exam.title}</h3>
            <p className="text-sm text-gray-600">
              시험일: {exam.date} • 시험시간: {exam.duration}
            </p>
          </div>
        </div>
        <button
          onClick={handleDownloadExcel}
          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
        >
          <Download className="w-4 h-4" />
          <span>엑셀 다운로드</span>
        </button>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-5 gap-4">
        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <div className="text-sm text-blue-700 mb-1">평균 점수</div>
          <div className="text-2xl text-blue-900">{stats.average}점</div>
        </div>
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
          <div className="text-sm text-green-700 mb-1">최고 점수</div>
          <div className="text-2xl text-green-900">{stats.highest}점</div>
        </div>
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <div className="text-sm text-red-700 mb-1">최저 점수</div>
          <div className="text-2xl text-red-900">{stats.lowest}점</div>
        </div>
        <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
          <div className="text-sm text-purple-700 mb-1">제출 인원</div>
          <div className="text-2xl text-purple-900">{stats.submitted}명</div>
        </div>
        <div className="p-4 bg-gray-50 border border-gray-200 rounded-lg">
          <div className="text-sm text-gray-700 mb-1">미제출 인원</div>
          <div className="text-2xl text-gray-900">{stats.total - stats.submitted}명</div>
        </div>
      </div>

      {/* 점수 분포 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">점수 분포</h4>
        <div className="space-y-3">
          {distribution.map((item) => (
            <div key={item.range}>
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm text-gray-700">{item.range}점</span>
                <span className="text-sm text-gray-900">{item.count}명</span>
              </div>
              <div className="w-full h-8 bg-gray-200 rounded-lg overflow-hidden">
                <div
                  className="h-full bg-blue-600 flex items-center justify-end px-2"
                  style={{
                    width: stats.submitted > 0 ? `${(item.count / stats.submitted) * 100}%` : '0%',
                  }}
                >
                  {item.count > 0 && (
                    <span className="text-xs text-white">
                      {Math.round((item.count / stats.submitted) * 100)}%
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 학생별 점수 테이블 */}
      <div className="border border-gray-200 rounded-lg">
        <div className="bg-gray-50 px-4 py-3 border-b border-gray-200 flex items-center justify-between">
          <h4 className="text-gray-900">학생별 점수</h4>
          <p className="text-sm text-gray-600">점수를 클릭하여 수정할 수 있습니다</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">학번</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">점수</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">제출 상태</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">제출 시간</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">채점</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {studentScores.map((student, index) => (
                <tr key={student.studentId} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.studentId}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.name}</td>
                  <td className="px-4 py-4 text-center">
                    {student.submitted ? (
                      editingScore === student.studentId ? (
                        <div className="flex items-center justify-center gap-2">
                          <input
                            type="number"
                            min="0"
                            max="100"
                            value={tempScore}
                            onChange={(e) => setTempScore(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                handleSaveScore(student.studentId);
                              } else if (e.key === 'Escape') {
                                handleCancelEdit();
                              }
                            }}
                            className="w-16 px-2 py-1 border border-blue-500 rounded text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                            autoFocus
                          />
                          <button
                            onClick={() => handleSaveScore(student.studentId)}
                            className="p-1 text-green-600 hover:bg-green-100 rounded transition-colors"
                            title="저장"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button
                            onClick={handleCancelEdit}
                            className="p-1 text-red-600 hover:bg-red-100 rounded transition-colors"
                            title="취소"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => handleStartEdit(student.studentId, student.score)}
                          className={`inline-flex items-center justify-center px-3 py-1 rounded-lg hover:opacity-80 transition-opacity ${
                            student.score >= 90
                              ? 'bg-green-100 text-green-700'
                              : student.score >= 80
                              ? 'bg-blue-100 text-blue-700'
                              : student.score >= 70
                              ? 'bg-yellow-100 text-yellow-700'
                              : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {student.score}점
                        </button>
                      )
                    ) : (
                      <span className="text-sm text-gray-400">-</span>
                    )}
                  </td>
                  <td className="px-4 py-4 text-center">
                    {student.submitted ? (
                      <span className="inline-flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 rounded text-xs">
                        <CheckCircle className="w-3 h-3" />
                        제출 완료
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2 py-1 bg-red-100 text-red-700 rounded text-xs">
                        미제출
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4 text-center text-sm text-gray-600">
                    {student.submittedAt}
                  </td>
                  <td className="px-4 py-4 text-center">
                    {student.submitted && editingScore !== student.studentId && (
                      <button
                        onClick={() => handleStartEdit(student.studentId, student.score)}
                        className="p-1 text-blue-600 hover:bg-blue-100 rounded transition-colors"
                        title="점수 수정"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                    )}
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

// 과제 탭
function AssignmentTab() {
  const [subTab, setSubTab] = useState<'management' | 'feedback'>('management');

  return (
    <div className="space-y-4">
      {/* 하위 탭 네비게이션 */}
      <div className="flex gap-2 border-b border-gray-200">
        <button
          onClick={() => setSubTab('management')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'management'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          과제 관리
        </button>
        <button
          onClick={() => setSubTab('feedback')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'feedback'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          피드백 관리
        </button>
      </div>

      {/* 하위 탭 콘텐츠 */}
      {subTab === 'management' && <AssignmentManagementTab />}
      {subTab === 'feedback' && <AssignmentFeedbackTab />}
    </div>
  );
}

// 과제 관리 하위 탭
function AssignmentManagementTab() {
  const [showCreateModal, setShowCreateModal] = useState(false);
  
  const assignments = [
    {
      id: 1,
      title: 'HTML 포트폴리오 페이지 제작',
      dueDate: '2024.03.25',
      submitted: 22,
      total: 28,
    },
    { id: 2, title: 'CSS 레이아웃 실습', dueDate: '2024.04.10', submitted: 20, total: 28 },
    {
      id: 3,
      title: 'JavaScript 계산기 만들기',
      dueDate: '2024.05.05',
      submitted: 15,
      total: 28,
    },
  ];

  return (
    <>
      <div className="space-y-4">
        <div className="flex justify-end">
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Briefcase className="w-4 h-4" />
            <span>과제 등록</span>
          </button>
        </div>
      {assignments.map((assignment) => (
        <div
          key={assignment.id}
          className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <div className="text-gray-900 mb-1">{assignment.title}</div>
              <div className="text-sm text-gray-600">마감일: {assignment.dueDate}</div>
            </div>
            <div className="flex items-center gap-4">
              <div className="text-right">
                <div className="text-sm text-gray-600">제출 현황</div>
                <div className="text-gray-900">
                  {assignment.submitted} / {assignment.total}명
                </div>
              </div>
              <button
                onClick={() => alert(`${assignment.title} 수정 기능`)}
                className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <Edit className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      ))}
      </div>
      
      <AssignmentCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={(assignmentData) => {
          console.log('새 과제 등록:', assignmentData);
          alert('과제가 등록되었습니다.');
        }}
      />
    </>
  );
}

// 피드백 관리 하위 탭
function AssignmentFeedbackTab() {
  const [selectedAssignment, setSelectedAssignment] = useState('1');
  const [selectedStudent, setSelectedStudent] = useState<string | null>(null);
  const [feedbackText, setFeedbackText] = useState('');

  // 과제 목록
  const assignments = [
    { id: '1', title: 'HTML 포트폴리오 페이지 제작' },
    { id: '2', title: 'CSS 레이아웃 실습' },
    { id: '3', title: 'JavaScript 계산기 만들기' },
  ];

  // 학생 제출 현황 (과제별)
  const submissions = [
    {
      studentId: '1',
      studentName: '김민수',
      studentNumber: '2024001',
      assignmentId: '1',
      submissions: [
        {
          version: 1,
          submitDate: '2024.03.20 14:30',
          status: 'feedback',
          fileUrl: 'portfolio_v1.zip',
          feedback: {
            author: '김교수',
            date: '2024.03.21 10:00',
            content: '전체적인 구조는 좋습니다. 다만 다음 사항을 개선해주세요:\n1. header 태그의 시맨틱 구조 개선 필요\n2. 반응형 디자인 적용\n3. 이미지 최적화 필요',
          },
        },
        {
          version: 2,
          submitDate: '2024.03.23 16:20',
          status: 'submitted',
          fileUrl: 'portfolio_v2.zip',
          feedback: null,
        },
      ],
    },
    {
      studentId: '2',
      studentName: '이지현',
      studentNumber: '2024002',
      assignmentId: '1',
      submissions: [
        {
          version: 1,
          submitDate: '2024.03.19 11:20',
          status: 'feedback',
          fileUrl: 'portfolio_v1.zip',
          feedback: {
            author: '김교수',
            date: '2024.03.20 09:30',
            content: '매우 잘 작성하셨습니다! CSS 애니메이션 활용이 인상적입니다.\n소스코드 주석을 추가하면 더욱 좋을 것 같습니다.',
          },
        },
        {
          version: 2,
          submitDate: '2024.03.22 14:10',
          status: 'feedback',
          fileUrl: 'portfolio_v2.zip',
          feedback: {
            author: '김교수',
            date: '2024.03.23 10:15',
            content: '주석 추가 완료 확인했습니다. 완성도가 높습니다. 수고하셨습니다!',
          },
        },
      ],
    },
    {
      studentId: '3',
      studentName: '박준호',
      studentNumber: '2024003',
      assignmentId: '1',
      submissions: [
        {
          version: 1,
          submitDate: '2024.03.24 23:50',
          status: 'submitted',
          fileUrl: 'portfolio_v1.zip',
          feedback: null,
        },
      ],
    },
    {
      studentId: '4',
      studentName: '최서연',
      studentNumber: '2024004',
      assignmentId: '1',
      submissions: [
        {
          version: 1,
          submitDate: '2024.03.18 09:15',
          status: 'feedback',
          fileUrl: 'portfolio_v1.zip',
          feedback: {
            author: '김교수',
            date: '2024.03.19 14:20',
            content: '디자인 감각이 뛰어납니다. 다만 다음을 보완해주세요:\n1. 모바일 환경에서 메뉴 버튼 동작 확인\n2. 접근성(alt 태그) 추가',
          },
        },
        {
          version: 2,
          submitDate: '2024.03.21 10:30',
          status: 'feedback',
          fileUrl: 'portfolio_v2.zip',
          feedback: {
            author: '김교수',
            date: '2024.03.22 11:00',
            content: '모바일 메뉴 동작 확인했습니다. 접근성도 잘 적용되었네요.\nfooter 영역의 정렬만 조정하면 완벽할 것 같습니다.',
          },
        },
        {
          version: 3,
          submitDate: '2024.03.23 15:40',
          status: 'submitted',
          fileUrl: 'portfolio_v3.zip',
          feedback: null,
        },
      ],
    },
  ];

  // 선택된 과제에 해당하는 제출물 필터링
  const filteredSubmissions = submissions.filter(
    (s) => s.assignmentId === selectedAssignment
  );

  // 선택된 학생의 상세 정보
  const selectedStudentData = filteredSubmissions.find(
    (s) => s.studentId === selectedStudent
  );

  const handleSubmitFeedback = () => {
    if (!feedbackText.trim()) {
      alert('피드백 내용을 입력해주세요.');
      return;
    }
    // 실제로는 여기서 API 호출하여 피드백 저장
    alert('피드백이 저장되었습니다.');
    setFeedbackText('');
    setSelectedStudent(null);
  };

  return (
    <div className="space-y-4">
      {/* 과제 선택 */}
      <div className="flex items-center gap-4">
        <label className="text-sm text-gray-700">과제 선택:</label>
        <select
          value={selectedAssignment}
          onChange={(e) => {
            setSelectedAssignment(e.target.value);
            setSelectedStudent(null);
          }}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {assignments.map((assignment) => (
            <option key={assignment.id} value={assignment.id}>
              {assignment.title}
            </option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* 왼쪽: 학생 목록 */}
        <div>
          <div className="bg-gray-50 px-4 py-3 rounded-t-lg border border-b-0 border-gray-200">
            <h4 className="text-gray-900">제출 학생 목록 ({filteredSubmissions.length}명)</h4>
          </div>
          <div className="border border-gray-200 rounded-b-lg divide-y divide-gray-200 max-h-[600px] overflow-y-auto">
            {filteredSubmissions.map((submission) => {
              const latestSubmission = submission.submissions[submission.submissions.length - 1];
              const needsFeedback = latestSubmission.status === 'submitted';
              const submissionCount = submission.submissions.length;

              return (
                <button
                  key={submission.studentId}
                  onClick={() => setSelectedStudent(submission.studentId)}
                  className={`w-full p-4 text-left transition-colors ${
                    selectedStudent === submission.studentId
                      ? 'bg-blue-50 border-l-4 border-blue-600'
                      : 'hover:bg-gray-50 border-l-4 border-transparent'
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <div className="text-gray-900 mb-1">{submission.studentName}</div>
                      <div className="text-sm text-gray-600">{submission.studentNumber}</div>
                    </div>
                    {needsFeedback && (
                      <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">
                        피드백 필요
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <span>제출 {submissionCount}회</span>
                    <span>•</span>
                    <span>{latestSubmission.submitDate}</span>
                  </div>
                </button>
              );
            })}

            {filteredSubmissions.length === 0 && (
              <div className="p-8 text-center text-gray-500">
                <p>제출한 학생이 없습니다</p>
              </div>
            )}
          </div>
        </div>

        {/* 오른쪽: 선택된 학생의 제출 이력 및 피드백 */}
        <div>
          {selectedStudentData ? (
            <div>
              <div className="bg-gray-50 px-4 py-3 rounded-t-lg border border-b-0 border-gray-200">
                <h4 className="text-gray-900">
                  {selectedStudentData.studentName}의 제출 이력
                </h4>
              </div>
              <div className="border border-gray-200 rounded-b-lg max-h-[600px] overflow-y-auto">
                <div className="p-4 space-y-6">
                  {/* 제출 이력 (최신순) */}
                  {[...selectedStudentData.submissions].reverse().map((sub, index) => {
                    const versionNumber = selectedStudentData.submissions.length - index;
                    const isLatest = index === 0;

                    return (
                      <div
                        key={index}
                        className={`p-4 rounded-lg border-2 ${
                          isLatest ? 'border-blue-300 bg-blue-50' : 'border-gray-200 bg-white'
                        }`}
                      >
                        {/* 제출 헤더 */}
                        <div className="flex items-center justify-between mb-3">
                          <div className="flex items-center gap-2">
                            <span className="px-3 py-1 bg-blue-600 text-white rounded-full text-xs">
                              {versionNumber}차 제출
                            </span>
                            {isLatest && (
                              <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded-full">
                                최신
                              </span>
                            )}
                          </div>
                          <span className="text-sm text-gray-600">{sub.submitDate}</span>
                        </div>

                        {/* 제출 파일 */}
                        <div className="mb-3 p-3 bg-white border border-gray-200 rounded-lg">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <Upload className="w-4 h-4 text-gray-500" />
                              <span className="text-sm text-gray-900">{sub.fileUrl}</span>
                            </div>
                            <button className="px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded transition-colors">
                              다운로드
                            </button>
                          </div>
                        </div>

                        {/* 기존 피드백 표시 */}
                        {sub.feedback ? (
                          <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                            <div className="flex items-center gap-2 mb-2">
                              <CheckCircle className="w-4 h-4 text-green-600" />
                              <span className="text-sm text-green-900">피드백 완료</span>
                              <span className="text-xs text-green-700 ml-auto">
                                {sub.feedback.author} • {sub.feedback.date}
                              </span>
                            </div>
                            <div className="text-sm text-gray-900 whitespace-pre-line">
                              {sub.feedback.content}
                            </div>
                          </div>
                        ) : (
                          <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                            <div className="flex items-center gap-2 mb-2">
                              <MessageSquare className="w-4 h-4 text-yellow-600" />
                              <span className="text-sm text-yellow-900">피드백 대기 중</span>
                            </div>
                            {isLatest && (
                              <div className="mt-3 space-y-2">
                                <textarea
                                  value={feedbackText}
                                  onChange={(e) => setFeedbackText(e.target.value)}
                                  placeholder="학생에게 전달할 피드백을 입력하세요..."
                                  rows={4}
                                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                                />
                                <div className="flex justify-end gap-2">
                                  <button
                                    onClick={() => {
                                      setFeedbackText('');
                                    }}
                                    className="px-4 py-2 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                                  >
                                    취소
                                  </button>
                                  <button
                                    onClick={handleSubmitFeedback}
                                    className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                                  >
                                    피드백 전송
                                  </button>
                                </div>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}

                  {/* 피드백 사이클 안내 */}
                  <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <div className="text-sm text-blue-900 mb-2">💡 피드백 프로세스</div>
                    <div className="text-sm text-blue-700">
                      1. 학생이 과제를 제출합니다
                      <br />
                      2. 교수자가 피드백을 작성하여 전송합니다
                      <br />
                      3. 학생이 피드백을 확인하고 개선하여 재제출합니다
                      <br />
                      4. 교수자가 재제출된 과제를 확인하고 다시 피드백합니다
                      <br />• 이 과정은 과제가 완료될 때까지 반복됩니다
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="border border-gray-200 rounded-lg">
              <div className="p-12 text-center text-gray-500">
                <MessageSquare className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                <p>학생을 선택하여</p>
                <p>제출 이력과 피드백을 확인하세요</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* 통계 요약 */}
      <div className="grid grid-cols-3 gap-4 pt-4 border-t border-gray-200">
        <div className="p-4 bg-gray-50 rounded-lg">
          <div className="text-sm text-gray-600 mb-1">총 제출</div>
          <div className="text-2xl text-gray-900">{filteredSubmissions.length}명</div>
        </div>
        <div className="p-4 bg-orange-50 rounded-lg">
          <div className="text-sm text-orange-600 mb-1">피드백 필요</div>
          <div className="text-2xl text-orange-900">
            {
              filteredSubmissions.filter(
                (s) => s.submissions[s.submissions.length - 1].status === 'submitted'
              ).length
            }
            명
          </div>
        </div>
        <div className="p-4 bg-green-50 rounded-lg">
          <div className="text-sm text-green-600 mb-1">피드백 완료</div>
          <div className="text-2xl text-green-900">
            {
              filteredSubmissions.filter(
                (s) => s.submissions[s.submissions.length - 1].status === 'feedback'
              ).length
            }
            명
          </div>
        </div>
      </div>
    </div>
  );
}

// 자료 탭
function MaterialsTab() {
  const materials = [
    { id: 1, title: 'HTML 기초 강의자료.pdf', uploadDate: '2024.03.01', size: '2.5MB' },
    { id: 2, title: 'CSS 스타일링 예제.zip', uploadDate: '2024.03.08', size: '5.2MB' },
    { id: 3, title: 'JavaScript 실습 코드.zip', uploadDate: '2024.03.15', size: '3.8MB' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Upload className="w-4 h-4" />
          <span>자료 업로드</span>
        </button>
      </div>
      <div className="space-y-2">
        {materials.map((material) => (
          <div
            key={material.id}
            className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <FolderOpen className="w-5 h-5 text-blue-600" />
              <div>
                <div className="text-gray-900">{material.title}</div>
                <div className="text-sm text-gray-600">
                  {material.uploadDate} • {material.size}
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button className="px-3 py-1.5 text-sm text-blue-700 hover:bg-blue-50 rounded transition-colors">
                다운로드
              </button>
              <button
                onClick={() => alert(`${material.title} 수정 기능`)}
                className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <Edit className="w-4 h-4" />
              </button>
              <button
                onClick={() => alert(`${material.title} 삭제 기능`)}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Q&A 탭
function QnaTab() {
  const qnas = [
    {
      id: 1,
      question: 'CSS flexbox와 grid의 차이점이 무엇인가요?',
      student: '김민수',
      date: '2024.03.20',
      answered: true,
    },
    {
      id: 2,
      question: 'JavaScript 이벤트 버블링에 대해 설명해주세요.',
      student: '이지현',
      date: '2024.03.22',
      answered: true,
    },
    {
      id: 3,
      question: '과제 제출 기한 연장이 가능한가요?',
      student: '박준호',
      date: '2024.03.23',
      answered: false,
    },
  ];

  return (
    <div className="space-y-4">
      {qnas.map((qna) => (
        <div
          key={qna.id}
          className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-start justify-between mb-2">
            <div className="flex-1">
              <div className="text-gray-900 mb-1">{qna.question}</div>
              <div className="text-sm text-gray-600">
                {qna.student} • {qna.date}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span
                className={`px-3 py-1 text-xs rounded-full ${
                  qna.answered
                    ? 'bg-green-100 text-green-700'
                    : 'bg-yellow-100 text-yellow-700'
                }`}
              >
                {qna.answered ? '답변완료' : '대기중'}
              </span>
              <button
                onClick={() => alert(`${qna.question} 답변 ${qna.answered ? '수정' : '작성'} 기능`)}
                className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              >
                <Edit className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

// 성적관리 탭
function GradesTab() {
  const grades = [
    { name: '김민수', studentId: '2020001', midterm: 85, final: 90, assignment: 88, attendance: 95, progressRate: 100, total: 89 },
    { name: '이지현', studentId: '2020002', midterm: 92, final: 95, assignment: 90, attendance: 100, progressRate: 100, total: 94 },
    { name: '박준호', studentId: '2020003', midterm: 78, final: 82, assignment: 75, attendance: 90, progressRate: 85, total: 81 },
    { name: '최서연', studentId: '2020004', midterm: 95, final: 98, assignment: 95, attendance: 100, progressRate: 100, total: 97 },
    { name: '정우진', studentId: '2020005', midterm: 88, final: 85, assignment: 90, attendance: 95, progressRate: 95, total: 89 },
    { name: '강민지', studentId: '2020006', midterm: 65, final: 70, assignment: 68, attendance: 75, progressRate: 80, total: 69 },
    { name: '윤서준', studentId: '2020007', midterm: 45, final: 50, assignment: 52, attendance: 60, progressRate: 55, total: 52 },
  ];

  // 수료기준: 총점 60점 이상, 진도율 60% 이상
  const completionCriteria = { totalScore: 60, progressRate: 60 };
  // 합격기준: 총점 80점 이상, 진도율 80% 이상
  const passCriteria = { totalScore: 80, progressRate: 80 };

  const getStatus = (student: any) => {
    const meetsCompletion = student.total >= completionCriteria.totalScore && student.progressRate >= completionCriteria.progressRate;
    const meetsPass = student.total >= passCriteria.totalScore && student.progressRate >= passCriteria.progressRate;

    if (meetsPass) {
      return { label: '합격', color: 'bg-green-100 text-green-700' };
    } else if (meetsCompletion) {
      return { label: '수료', color: 'bg-blue-100 text-blue-700' };
    } else {
      return { label: '미달', color: 'bg-red-100 text-red-700' };
    }
  };

  return (
    <div>
      <div className="mb-4 flex justify-between items-center">
        <div className="text-sm text-gray-600">성적 입력 및 관리</div>
        <button className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
          <Download className="w-4 h-4" />
          <span>성적표 다운로드</span>
        </button>
      </div>

      {/* 기준 안내 */}
      <div className="mb-4 p-4 bg-gray-50 border border-gray-200 rounded-lg">
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-700 mb-1">수료 기준</div>
            <div className="text-gray-600">
              총점 {completionCriteria.totalScore}점 이상, 진도율 {completionCriteria.progressRate}% 이상
            </div>
          </div>
          <div>
            <div className="text-gray-700 mb-1">합격 기준</div>
            <div className="text-gray-600">
              총점 {passCriteria.totalScore}점 이상, 진도율 {passCriteria.progressRate}% 이상
            </div>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">학번</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">중간고사</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">기말고사</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">과제</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">출석</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">총점</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">결과</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {grades.map((grade, index) => {
              const status = getStatus(grade);
              return (
                <tr key={index} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-sm text-gray-900">{grade.name}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-600">{grade.studentId}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">{grade.midterm}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">{grade.final}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {grade.assignment}
                  </td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {grade.attendance}
                  </td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {grade.progressRate}%
                  </td>
                  <td className="px-4 py-4 text-center">
                    <span className="inline-flex px-3 py-1 bg-blue-100 text-blue-700 rounded-full">
                      {grade.total}
                    </span>
                  </td>
                  <td className="px-4 py-4 text-center">
                    <span className={`inline-flex px-3 py-1 rounded-full ${status.color}`}>
                      {status.label}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// 수료관리 탭
function CompletionTab() {
  const [selectedStudents, setSelectedStudents] = useState<number[]>([]);

  const completionData = [
    { id: 1, name: '김민수', studentId: '2020001', progress: 100, attendance: 95, grade: 89, status: '합격' },
    { id: 2, name: '이지현', studentId: '2020002', progress: 100, attendance: 100, grade: 94, status: '합격' },
    { id: 3, name: '박준호', studentId: '2020003', progress: 85, attendance: 90, grade: 81, status: '수료' },
    { id: 4, name: '최서연', studentId: '2020004', progress: 100, attendance: 100, grade: 97, status: '합격' },
    { id: 5, name: '정우진', studentId: '2020005', progress: 95, attendance: 95, grade: 89, status: '합격' },
    { id: 6, name: '강민지', studentId: '2020006', progress: 80, attendance: 75, grade: 69, status: '수료' },
    { id: 7, name: '윤서준', studentId: '2020007', progress: 55, attendance: 60, grade: 52, status: '미달' },
  ];

  const completionCriteria = { totalScore: 60, progressRate: 60 };
  const passCriteria = { totalScore: 80, progressRate: 80 };

  const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.checked) {
      const eligibleIds = completionData
        .filter(d => d.status === '수료' || d.status === '합격')
        .map(d => d.id);
      setSelectedStudents(eligibleIds);
    } else {
      setSelectedStudents([]);
    }
  };

  const handleSelectStudent = (id: number) => {
    setSelectedStudents(prev =>
      prev.includes(id) ? prev.filter(sid => sid !== id) : [...prev, id]
    );
  };

  const handlePrintCompletion = () => {
    const selectedData = completionData.filter(d => selectedStudents.includes(d.id));
    if (selectedData.length === 0) {
      alert('출력할 학생을 선택해주세요.');
      return;
    }
    alert(`수료증 ${selectedData.length}건을 출력합니다.\n\n${selectedData.map(d => d.name).join(', ')}`);
  };

  const handlePrintPass = () => {
    const selectedData = completionData.filter(d => selectedStudents.includes(d.id) && d.status === '합격');
    if (selectedData.length === 0) {
      alert('출력할 합격자를 선택해주세요.');
      return;
    }
    alert(`합격증 ${selectedData.length}건을 출력합니다.\n\n${selectedData.map(d => d.name).join(', ')}`);
  };

  const handlePrintIndividual = (student: any, type: 'completion' | 'pass') => {
    if (type === 'pass' && student.status !== '합격') {
      alert('합격 기준을 충족하지 않은 학생입니다.');
      return;
    }
    if (type === 'completion' && student.status === '미달') {
      alert('수료 기준을 충족하지 않은 학생입니다.');
      return;
    }
    alert(`${student.name} 학생의 ${type === 'completion' ? '수료증' : '합격증'}을 출력합니다.`);
  };

  const getStatusBadge = (status: string) => {
    if (status === '합격') {
      return 'bg-green-100 text-green-700';
    } else if (status === '수료') {
      return 'bg-blue-100 text-blue-700';
    } else {
      return 'bg-red-100 text-red-700';
    }
  };

  return (
    <div>
      <div className="mb-4 p-4 bg-gray-50 border border-gray-200 rounded-lg">
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-700 mb-1">수료 기준</div>
            <div className="text-gray-600">
              총점 {completionCriteria.totalScore}점 이상, 진도율 {completionCriteria.progressRate}% 이상
            </div>
          </div>
          <div>
            <div className="text-gray-700 mb-1">합격 기준</div>
            <div className="text-gray-600">
              총점 {passCriteria.totalScore}점 이상, 진도율 {passCriteria.progressRate}% 이상
            </div>
          </div>
        </div>
      </div>

      <div className="mb-4 flex gap-2 justify-end">
        <button
          onClick={handlePrintCompletion}
          disabled={selectedStudents.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          <Download className="w-4 h-4" />
          <span>수료증 일괄출력 ({selectedStudents.length})</span>
        </button>
        <button
          onClick={handlePrintPass}
          disabled={selectedStudents.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          <Download className="w-4 h-4" />
          <span>합격증 일괄출력 ({completionData.filter(d => selectedStudents.includes(d.id) && d.status === '합격').length})</span>
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 text-center">
                <input
                  type="checkbox"
                  onChange={handleSelectAll}
                  checked={selectedStudents.length > 0 && selectedStudents.length === completionData.filter(d => d.status !== '미달').length}
                  className="w-4 h-4 text-blue-600 rounded"
                />
              </th>
              <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">학번</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">출석률</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">총점</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">결과</th>
              <th className="px-4 py-3 text-center text-sm text-gray-700">증명서 출력</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {completionData.map((data, index) => (
              <tr key={index} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-4 text-center">
                  <input
                    type="checkbox"
                    checked={selectedStudents.includes(data.id)}
                    onChange={() => handleSelectStudent(data.id)}
                    disabled={data.status === '미달'}
                    className="w-4 h-4 text-blue-600 rounded disabled:opacity-50"
                  />
                </td>
                <td className="px-4 py-4 text-sm text-gray-900">{data.name}</td>
                <td className="px-4 py-4 text-center text-sm text-gray-600">{data.studentId}</td>
                <td className="px-4 py-4 text-center text-sm text-gray-900">{data.progress}%</td>
                <td className="px-4 py-4 text-center text-sm text-gray-900">
                  {data.attendance}%
                </td>
                <td className="px-4 py-4 text-center text-sm text-gray-900">{data.grade}점</td>
                <td className="px-4 py-4 text-center">
                  <span className={`inline-flex px-3 py-1 rounded-full text-xs ${getStatusBadge(data.status)}`}>
                    {data.status}
                  </span>
                </td>
                <td className="px-4 py-4 text-center">
                  <div className="flex gap-2 justify-center">
                    <button
                      onClick={() => handlePrintIndividual(data, 'completion')}
                      disabled={data.status === '미달'}
                      className="px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                      수료증
                    </button>
                    <button
                      onClick={() => handlePrintIndividual(data, 'pass')}
                      disabled={data.status !== '합격'}
                      className="px-3 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                    >
                      합격증
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
