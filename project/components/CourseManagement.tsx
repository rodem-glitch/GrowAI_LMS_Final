import React, { useEffect, useRef, useState } from 'react';
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
  BookOpen,
} from 'lucide-react';
import { SessionEditModal } from './SessionEditModal';
import { CourseInfoTab } from './CourseInfoTabs';
import { ExamCreateModal } from './ExamCreateModal';
import { AssignmentCreateModal } from './AssignmentCreateModal';
import { tutorLmsApi } from '../api/tutorLmsApi';
import { CurriculumTab } from './courseManagement/CurriculumTab';
import { StudentsTab } from './courseManagement/StudentsTab';
import { AttendanceTab } from './courseManagement/AttendanceTab';
import { downloadCsv } from '../utils/csv';

interface CourseManagementProps {
  course: {
    id: string;
    // 왜: 학사/프리즘 탭에 따라 API 호출 및 편집 가능 여부를 결정합니다.
    sourceType?: 'haksa' | 'prism';
    courseId: string;
    courseType: string;
    subjectName: string;
    programId: number;
    programName: string;
    period: string;
    students: number;
    status: string;
    // ===== 학사 View 25개 필드 =====
    haksaCategory?: string;
    haksaDeptName?: string;
    haksaWeek?: string;
    haksaOpenTerm?: string;
    haksaCourseCode?: string;
    haksaVisible?: string;
    haksaStartdate?: string;
    haksaBunbanCode?: string;
    haksaGrade?: string;
    haksaGradName?: string;
    haksaDayCd?: string;
    haksaClassroom?: string;
    haksaCurriculumCode?: string;
    haksaCourseEname?: string;
    haksaTypeSyllabus?: string;
    haksaOpenYear?: string;
    haksaDeptCode?: string;
    haksaCourseName?: string;
    haksaGroupCode?: string;
    haksaEnddate?: string;
    haksaEnglish?: string;
    haksaHour1?: string;
    haksaCurriculumName?: string;
    haksaGradCode?: string;
    haksaIsSyllabus?: string;
  };
  onBack: () => void;
}


type TabType =
  | 'info'
  | 'info-basic'
  | 'info-evaluation'
  | 'info-completion'
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
  const [activeTab, setActiveTab] = useState<TabType>('info-basic');
  const [isInfoExpanded, setIsInfoExpanded] = useState(true);
  const [isAssignmentExpanded, setIsAssignmentExpanded] = useState(false);

  // 페이지 진입 시 스크롤을 맨 위로 이동
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  useEffect(() => {
    setCourse(initialCourse);
  }, [initialCourse]);

  const tabs = [
    { id: 'info' as TabType, label: '과목정보', icon: Info, isSubTab: false, hasSubTabs: true },
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

  // 왜: 과목정보 하위 탭 (info 탭 케럟 변경)
  const infoSubTabs = [
    { id: 'info-basic' as TabType, label: '기본 정보', icon: Info },
    { id: 'info-evaluation' as TabType, label: '평가/수료 기준', icon: ClipboardCheck },
    { id: 'info-completion' as TabType, label: '수료증', icon: Award },
  ];

  const assignmentSubTabs = [
    { id: 'assignment-management' as TabType, label: '과제 관리', icon: Briefcase },
    { id: 'assignment-feedback' as TabType, label: '피드백 관리', icon: MessageSquare },
  ];

  const handleTabClick = (tabId: TabType) => {
    if (tabId === 'info') {
      setIsInfoExpanded(!isInfoExpanded);
      if (!isInfoExpanded) {
        setActiveTab('info-basic');
      }
    } else if (tabId === 'assignment') {
      setIsAssignmentExpanded(!isAssignmentExpanded);
      if (!isAssignmentExpanded) {
        setActiveTab('assignment-management');
      }
    } else {
      setActiveTab(tabId);
      // 다른 탭을 클릭하면 해당 탭의 하위 탭만 유지
      if (!['info-basic', 'info-evaluation', 'info-completion'].includes(tabId)) {
        setIsInfoExpanded(false);
      }
      if (!['assignment-management', 'assignment-feedback'].includes(tabId)) {
        setIsAssignmentExpanded(false);
      }
    }
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'info':
      case 'info-basic':
        return <CourseInfoTab course={course} onCourseUpdated={setCourse} initialSubTab="basic" />;
      case 'info-evaluation':
        return <CourseInfoTab course={course} onCourseUpdated={setCourse} initialSubTab="evaluation" />;
      case 'info-completion':
        return <CourseInfoTab course={course} onCourseUpdated={setCourse} initialSubTab="completion" />;
      case 'curriculum':
        return <CurriculumTab courseId={Number(course.id)} course={course} />;
      case 'students':
        return <StudentsTab courseId={Number(course.id)} />;
      case 'attendance':
        return <AttendanceTab courseId={Number(course.id)} />;
      case 'exam':
        return <ExamTab courseId={Number(course.id)} course={course} />;
      case 'assignment':
        return <AssignmentTab courseId={Number(course.id)} />;
      case 'assignment-management':
        return <AssignmentManagementTab courseId={Number(course.id)} course={course} />;
      case 'assignment-feedback':
        return <AssignmentFeedbackTab courseId={Number(course.id)} />;
      case 'materials':
        return <MaterialsTab courseId={Number(course.id)} />;
      case 'qna':
        return <QnaTab courseId={Number(course.id)} />;
      case 'grades':
        return <GradesTab courseId={Number(course.id)} />;
      case 'completion':
        return <CompletionTab courseId={Number(course.id)} course={course} />;
      default:
        return null;
    }
  };

  return (
    <div className="max-w-7xl mx-auto">
      {/* Vertical Tabs Layout */}
      <div className="flex gap-6">
        {/* Left Sidebar - Vertical Tabs (Fixed Position) */}
        <div className="w-64 flex-shrink-0">
          <div className="fixed w-64" style={{ maxHeight: 'calc(100vh - 40px)', overflowY: 'auto' }}>
            {/* 목록으로 돌아가기 버튼 */}
            <button
              onClick={onBack}
              className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
              <span>목록으로 돌아가기</span>
            </button>
            
            {/* 메뉴 네비게이션 */}
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
              <nav className="flex flex-col">
                {tabs.map((tab) => {
                  const Icon = tab.icon;
                  const isInfoTab = tab.id === 'info';
                  const isAssignmentTab = tab.id === 'assignment';
                  const isActive = activeTab === tab.id || 
                    (isInfoTab && ['info-basic', 'info-evaluation', 'info-completion'].includes(activeTab)) ||
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
                        {(isInfoTab || isAssignmentTab) && (
                          (isInfoTab ? isInfoExpanded : isAssignmentExpanded) ? (
                            <ChevronDown className="w-4 h-4" />
                          ) : (
                            <ChevronRight className="w-4 h-4" />
                          )
                        )}
                      </button>
                      
                      {/* 과목정보 하위 탭 */}
                      {isInfoTab && isInfoExpanded && (
                        <div className="bg-gray-50">
                          {infoSubTabs.map((subTab) => {
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
        </div>

        {/* Right Content Area */}
        <div className="flex-1 min-w-0">
          {/* 강좌 정보 헤더 (스크롤과 함께 이동) */}
          <div className="mb-6">
            <h2 className="text-gray-900 mb-2">{course.subjectName}</h2>
            <div className="flex items-center gap-4 text-sm text-gray-600">
              <span>과정ID: {course.courseId}</span>
              <span className="text-gray-300">·</span>
              <span>{course.courseType}</span>
              <span className="text-gray-300">·</span>
              <span>{course.period}</span>
              <span className="text-gray-300">·</span>
              <span>수강생: {course.students}명</span>
            </div>
          </div>
          
          {/* 탭 콘텐츠 */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            {renderTabContent()}
          </div>
        </div>
      </div>
    </div>
  );
}

// 과목정보 탭 (이제 CourseInfoTabs.tsx에서 import됨)

function ExamTab({ courseId, course }: { courseId: number; course?: any }) {
  // 왜: 학사 과목은 courseId가 NaN 또는 0이므로, 빈 상태로 시작하여 교수자가 직접 추가할 수 있도록 합니다.
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0 || course?.sourceType === 'haksa';

  const [selectedExam, setSelectedExam] = useState<number | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const [exams, setExams] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 학사 과목의 경우 로컬스토리지에서 시험 목록 불러오기
  const [haksaExams, setHaksaExams] = useState<any[]>([]);

  useEffect(() => {
    if (isHaksaCourse && course?.id) {
      try {
        const saved = localStorage.getItem(`haksa_curriculum_${course.id}`);
        if (saved) {
          const contents = JSON.parse(saved);
          const examContents = contents.filter((c: any) => c.type === 'exam');
          setHaksaExams(examContents);
        }
      } catch {
        setHaksaExams([]);
      }
    }
  }, [isHaksaCourse, course?.id]);

  const fetchExams = async () => {
    if (!courseId || isHaksaCourse) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getExams({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row) => ({
        id: Number(row.exam_id),
        title: row.exam_nm,
        date: row.start_date_conv || row.start_date || '-',
        duration: row.exam_time ? `${row.exam_time}분` : '-',
        submitted: Number(row.submitted_cnt ?? 0),
        total: Number(row.total_cnt ?? 0),
      }));
      setExams(mapped);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '시험 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!isHaksaCourse) void fetchExams();
  }, [courseId, isHaksaCourse]);

  // 왜: 학사 과목인 경우 시험관리에서 등록한 시험을 표시하고 추가할 수 있습니다.
  if (isHaksaCourse) {
    return (
      <HaksaExamContent
        courseId={course?.id}
        haksaExams={haksaExams}
        setHaksaExams={setHaksaExams}
      />
    );
  }



  if (selectedExam !== null) {
    const exam = exams.find((e) => e.id === selectedExam);

    return (
      <ExamDetailView
        courseId={courseId}
        examId={selectedExam}
        exam={exam}
        onBack={() => setSelectedExam(null)}
        onRefresh={() => void fetchExams()}
      />
    );
  }

  // 프리즘 과목: 시험관리 목록에서 선택하는 모달 표시
  return (
    <>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">등록된 시험</h3>
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>시험 추가</span>
          </button>
        </div>
        {errorMessage && (
          <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
            {errorMessage}
          </div>
        )}

        {loading && (
          <div className="p-6 text-center text-gray-500">시험 목록을 불러오는 중...</div>
        )}

        {!loading && exams.length > 0 && exams.map((exam) => (
          <button
            key={exam.id}
            onClick={() => setSelectedExam(exam.id)}
            className="w-full p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="text-gray-900 mb-1">{exam.title}</div>
                <div className="text-sm text-gray-600">
                  시험일: {exam.date} · 시험시간: {exam.duration}
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

        {!loading && exams.length === 0 && (
          <div className="text-center text-gray-500 py-12 border border-dashed border-gray-300 rounded-lg">
            <ClipboardCheck className="w-12 h-12 mx-auto text-gray-300 mb-3" />
            <p className="mb-2">등록된 시험이 없습니다.</p>
            <p className="text-sm text-gray-400">시험 추가 버튼을 눌러 시험관리에서 만든 시험을 등록하세요.</p>
          </div>
        )}
      </div>
      
      <ExamSelectModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={async (examData) => {
          try {
            const res = await tutorLmsApi.createExam({
              courseId,
              title: examData.title,
              description: examData.description || '',
              examDate: new Date().toISOString().split('T')[0],
              examTime: '09:00',
              duration: examData.duration || 60,
              questionCount: examData.questionCount || 0,
              totalScore: examData.points || 100,
              allowRetake: examData.allowRetake || false,
              showResults: examData.showResults || true,
              onoffType: 'F',
            });
            if (res.rst_code !== '0000') throw new Error(res.rst_message);
            await fetchExams();
            alert('시험이 등록되었습니다.');
          } catch (e) {
            alert(e instanceof Error ? e.message : '시험 등록 중 오류가 발생했습니다.');
          }
        }}
      />
    </>
  );
}

// 시험 상세 화면
function ExamDetailView({
  courseId,
  examId,
  exam,
  onBack,
  onRefresh,
}: {
  courseId: number;
  examId: number;
  exam: any;
  onBack: () => void;
  onRefresh: () => void;
}) {
  const [editingScore, setEditingScore] = useState<number | null>(null);
  const [tempScore, setTempScore] = useState<string>('');
  const [studentScores, setStudentScores] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const examTitle = exam?.title ?? '시험';
  const examDate = exam?.date ?? '-';
  const examDuration = exam?.duration ?? '-';

  const fetchExamUsers = async () => {
    if (!courseId || !examId) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getExamUsers({ courseId, examId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        courseUserId: Number(row.course_user_id),
        studentId: row.login_id,
        name: row.user_nm,
        score: Number(row.marking_score ?? 0),
        submitted: Boolean(row.submitted),
        submittedAt: row.submitted_at ?? '-',
      }));
      setStudentScores(mapped);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '제출 현황을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchExamUsers();
  }, [courseId, examId]);

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
    // 왜: 서버에 별도 파일 생성 기능이 없어도, 화면에 있는 데이터를 CSV로 내려받을 수 있습니다.
    const ymd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const filename = `course_${courseId}_exam_${examId}_${ymd}.csv`;

    const headers = ['No', '학번', '이름', '제출여부', '제출시간', '점수'];
    const rows = studentScores.map((student, index) => ([
      index + 1,
      student.studentId ?? '',
      student.name ?? '',
      student.submitted ? 'Y' : 'N',
      student.submittedAt ?? '',
      student.submitted ? Number(student.score ?? 0) : '',
    ]));

    downloadCsv(filename, headers, rows);
  };

  // 점수 수정 시작
  const handleStartEdit = (courseUserId: number, currentScore: number) => {
    setEditingScore(courseUserId);
    setTempScore(currentScore.toString());
  };

  // 점수 수정 저장
  const handleSaveScore = async (courseUserId: number) => {
    const newScore = parseInt(tempScore, 10);
    if (isNaN(newScore) || newScore < 0 || newScore > 100) {
      alert('점수는 0~100 사이의 숫자여야 합니다.');
      return;
    }

    try {
      const res = await tutorLmsApi.updateExamScore({
        courseId,
        examId,
        courseUserId,
        markingScore: newScore,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      await fetchExamUsers();
      onRefresh();
      setEditingScore(null);
      setTempScore('');
    } catch (e) {
      alert(e instanceof Error ? e.message : '점수 저장 중 오류가 발생했습니다.');
    }
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
            <h3 className="text-xl text-gray-900">{examTitle}</h3>
            <p className="text-sm text-gray-600">
              시험일: {examDate} · 시험시간: {examDuration}
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

      {errorMessage && (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
          {errorMessage}
        </div>
      )}

      {loading && (
        <div className="p-6 text-center text-gray-500">제출 현황을 불러오는 중...</div>
      )}

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
                <tr key={student.courseUserId} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-sm text-gray-900">{index + 1}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.studentId}</td>
                  <td className="px-4 py-4 text-sm text-gray-900">{student.name}</td>
                  <td className="px-4 py-4 text-center">
                    {student.submitted ? (
                      editingScore === student.courseUserId ? (
                        <div className="flex items-center justify-center gap-2">
                          <input
                            type="number"
                            min="0"
                            max="100"
                            value={tempScore}
                            onChange={(e) => setTempScore(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                handleSaveScore(student.courseUserId);
                              } else if (e.key === 'Escape') {
                                handleCancelEdit();
                              }
                            }}
                            className="w-16 px-2 py-1 border border-blue-500 rounded text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                            autoFocus
                          />
                          <button
                            onClick={() => handleSaveScore(student.courseUserId)}
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
                          onClick={() => handleStartEdit(student.courseUserId, student.score)}
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
                    {student.submitted && editingScore !== student.courseUserId && (
                      <button
                        onClick={() => handleStartEdit(student.courseUserId, student.score)}
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
function AssignmentTab({ courseId }: { courseId: number }) {
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
      {subTab === 'management' && <AssignmentManagementTab courseId={courseId} />}
      {subTab === 'feedback' && <AssignmentFeedbackTab courseId={courseId} />}
    </div>
  );
}

// 과제 관리 하위 탭
function AssignmentManagementTab({ courseId, course }: { courseId: number; course?: any }) {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0 || course?.sourceType === 'haksa';

  const [homeworks, setHomeworks] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // 학사 과목의 경우 로컬스토리지에서 과제 목록 불러오기
  const [haksaAssignments, setHaksaAssignments] = useState<any[]>([]);

  useEffect(() => {
    if (isHaksaCourse && course?.id) {
      try {
        const saved = localStorage.getItem(`haksa_curriculum_${course.id}`);
        if (saved) {
          const contents = JSON.parse(saved);
          const assignmentContents = contents.filter((c: any) => c.type === 'assignment');
          setHaksaAssignments(assignmentContents);
        }
      } catch {
        setHaksaAssignments([]);
      }
    }
  }, [isHaksaCourse, course?.id]);

  // 왜: 과제 탭은 "새로고침해도 유지되는 실데이터"가 핵심이라서, 화면이 뜰 때마다 DB(서버)에서 다시 읽어옵니다.
  const fetchHomeworks = async () => {
    if (!courseId || isHaksaCourse) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getHomeworks({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        id: Number(row.homework_id),
        title: row.homework_nm || row.module_nm || '과제',
        dueDate: row.end_date_conv || row.end_date || '-',
        submitted: Number(row.submitted_cnt ?? 0),
        total: Number(row.total_cnt ?? 0),
      }));
      setHomeworks(mapped);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '과제 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!isHaksaCourse) void fetchHomeworks();
  }, [courseId, isHaksaCourse]);

  // 학사 과목인 경우 강의목차에서 등록한 과제 표시
  if (isHaksaCourse) {
    return (
      <div className="space-y-4">
        {haksaAssignments.length > 0 ? (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">등록된 과제</h3>
              <span className="px-3 py-1 bg-purple-100 text-purple-700 text-sm rounded-full">
                총 {haksaAssignments.length}개
              </span>
            </div>
            {haksaAssignments.map((assignment: any) => (
              <div
                key={assignment.id}
                className="p-4 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <BookOpen className="w-5 h-5 text-purple-600" />
                      <span className="font-medium text-gray-900">{assignment.title}</span>
                      <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                        {assignment.weekNumber}주차
                      </span>
                    </div>
                    {assignment.description && (
                      <p className="text-sm text-gray-500 mt-1 ml-7">{assignment.description}</p>
                    )}
                  </div>
                  <div className="text-sm text-gray-400">
                    {new Date(assignment.createdAt).toLocaleDateString('ko-KR')}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center text-gray-500 py-12 border border-dashed border-gray-300 rounded-lg">
            <BookOpen className="w-12 h-12 mx-auto text-gray-300 mb-3" />
            <p className="mb-2">등록된 과제가 없습니다.</p>
            <p className="text-sm text-gray-400">강의목차에서 주차별로 과제를 추가할 수 있습니다.</p>
          </div>
        )}
      </div>
    );
  }

  const handleDeleteHomework = (homeworkId: number, title: string) => {
    void (async () => {
      // 왜: 제출/채점 데이터가 이미 쌓인 과제를 지우면 운영 데이터가 깨질 수 있어서, 사용자에게 한 번 더 확인받습니다.
      const ok = confirm(
        `과제 "${title}"을(를) 삭제하시겠습니까?\n\n이미 제출 내역이 있는 경우, 서버에서 삭제가 차단될 수 있습니다.`
      );
      if (!ok) return;

      try {
        const res = await tutorLmsApi.deleteHomework({ courseId, homeworkId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchHomeworks();
        alert('삭제되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '삭제 중 오류가 발생했습니다.');
      }
    })();
  };

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

        {errorMessage && (
          <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
            {errorMessage}
          </div>
        )}

        {loading && (
          <div className="p-6 text-center text-gray-500">과제 목록을 불러오는 중...</div>
        )}

        {!loading && homeworks.length === 0 && (
          <div className="p-10 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
            등록된 과제가 없습니다. 우측 상단에서 과제를 등록해 주세요.
          </div>
        )}

        {!loading &&
          homeworks.map((assignment) => (
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
                    onClick={() => handleDeleteHomework(assignment.id, assignment.title)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="삭제"
                  >
                    <Trash2 className="w-4 h-4" />
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
          void (async () => {
            try {
              const res = await tutorLmsApi.createHomework({
                courseId,
                title: assignmentData.title,
                description: assignmentData.description,
                dueDate: assignmentData.dueDate,
                dueTime: assignmentData.dueTime,
                totalScore: Number(assignmentData.totalScore || 0),
                onoffType: 'N',
              });
              if (res.rst_code !== '0000') throw new Error(res.rst_message);

              await fetchHomeworks();
              alert('과제가 등록되었습니다.');
            } catch (e) {
              alert(e instanceof Error ? e.message : '과제 등록 중 오류가 발생했습니다.');
            }
          })();
        }}
      />
    </>
  );
}

// 피드백 관리 하위 탭
function AssignmentFeedbackTab({ courseId }: { courseId: number }) {
  const [homeworks, setHomeworks] = useState<any[]>([]);
  const [selectedHomeworkId, setSelectedHomeworkId] = useState<number | null>(null);

  const [students, setStudents] = useState<any[]>([]);
  const [selectedCourseUserId, setSelectedCourseUserId] = useState<number | null>(null);

  const [tempScore, setTempScore] = useState<string>('0');
  const [feedbackText, setFeedbackText] = useState<string>('');

  const [loadingHomeworks, setLoadingHomeworks] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const toBool = (value: any) =>
    value === true || value === 1 || value === '1' || value === 'Y' || value === 'true';

  // 왜: 피드백 화면은 "현재 과제 목록"이 먼저 필요하므로, 진입 시 과제 목록을 먼저 불러옵니다.
  const fetchHomeworks = async () => {
    if (!courseId) return;
    setLoadingHomeworks(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getHomeworks({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        id: Number(row.homework_id),
        title: row.homework_nm || row.module_nm || '과제',
      }));
      setHomeworks(mapped);

      const firstId = mapped[0]?.id ?? null;
      setSelectedHomeworkId((prev) => {
        if (prev && mapped.some((h: any) => h.id === prev)) return prev;
        return firstId;
      });

      if (!firstId) {
        setStudents([]);
        setSelectedCourseUserId(null);
        setTempScore('0');
        setFeedbackText('');
      }
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '과제 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoadingHomeworks(false);
    }
  };

  const fetchHomeworkUsers = async (homeworkId: number) => {
    if (!courseId || !homeworkId) return;
    setLoadingUsers(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getHomeworkUsers({ courseId, homeworkId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        courseUserId: Number(row.course_user_id),
        studentId: row.login_id,
        name: row.user_nm,
        submitted: toBool(row.submitted),
        submittedAt: row.submitted_at ?? '-',
        confirm: toBool(row.confirm),
        markingScore: Number(row.marking_score ?? 0),
        scoreConv: row.score_conv ?? '',
        feedback: row.feedback ?? '',
        taskCnt: Number(row.task_cnt ?? 0),
      }));
      setStudents(mapped);

      // 왜: 재조회 후 선택된 학생이 목록에서 사라지면(권한/상태 변화 등) 선택을 해제해야 화면이 깨지지 않습니다.
      setSelectedCourseUserId((prev) => {
        if (prev && mapped.some((s: any) => s.courseUserId === prev)) return prev;
        return null;
      });
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '제출 현황을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoadingUsers(false);
    }
  };

  useEffect(() => {
    void fetchHomeworks();
  }, [courseId]);

  useEffect(() => {
    if (!selectedHomeworkId) return;
    void fetchHomeworkUsers(selectedHomeworkId);
  }, [courseId, selectedHomeworkId]);

  const selectedStudent = students.find((s: any) => s.courseUserId === selectedCourseUserId) ?? null;

  const handleSelectStudent = (courseUserId: number) => {
    setSelectedCourseUserId(courseUserId);
    const student = students.find((s: any) => s.courseUserId === courseUserId);
    setTempScore(String(student?.markingScore ?? 0));
    setFeedbackText(String(student?.feedback ?? ''));
  };

  const handleSubmitFeedback = () => {
    if (!selectedHomeworkId || !selectedCourseUserId) return;

    const score = parseInt(tempScore, 10);
    if (isNaN(score) || score < 0 || score > 100) {
      alert('점수는 0~100 사이의 숫자여야 합니다.');
      return;
    }

    void (async () => {
      try {
        // 왜: 저장 즉시 성적(homework_score/total_score)에 반영되어야 "실사용" 흐름이 끊기지 않습니다.
        const res = await tutorLmsApi.updateHomeworkFeedback({
          courseId,
          homeworkId: selectedHomeworkId,
          courseUserId: selectedCourseUserId,
          markingScore: score,
          feedback: feedbackText,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchHomeworkUsers(selectedHomeworkId);
        alert('저장되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
      }
    })();
  };

  const handleAppendTask = () => {
    if (!selectedHomeworkId || !selectedCourseUserId) return;

    const task = prompt('추가과제 내용을 입력해 주세요.');
    if (!task || !task.trim()) return;

    void (async () => {
      try {
        const res = await tutorLmsApi.appendHomeworkTask({
          courseId,
          homeworkId: selectedHomeworkId,
          courseUserId: selectedCourseUserId,
          task: task.trim(),
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchHomeworkUsers(selectedHomeworkId);
        alert('추가과제가 부여되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '추가과제 부여 중 오류가 발생했습니다.');
      }
    })();
  };

  const summary = {
    total: students.length,
    needFeedback: students.filter((s: any) => s.submitted && !s.confirm).length,
    doneFeedback: students.filter((s: any) => s.confirm).length,
  };

  return (
    <div className="space-y-4">
      {/* 과제 선택 */}
      <div className="flex items-center gap-4">
        <label className="text-sm text-gray-700">과제 선택:</label>
        <select
          value={selectedHomeworkId ?? ''}
          onChange={(e) => {
            const nextId = e.target.value ? Number(e.target.value) : null;
            setSelectedHomeworkId(nextId);
            setSelectedCourseUserId(null);
            setTempScore('0');
            setFeedbackText('');
          }}
          disabled={loadingHomeworks || homeworks.length === 0}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
        >
          {homeworks.length === 0 && <option value="">과제가 없습니다</option>}
          {homeworks.map((hw: any) => (
            <option key={hw.id} value={hw.id}>
              {hw.title}
            </option>
          ))}
        </select>
      </div>

      {errorMessage && (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
          {errorMessage}
        </div>
      )}

      {loadingUsers && (
        <div className="p-6 text-center text-gray-500">제출 현황을 불러오는 중...</div>
      )}

      {homeworks.length === 0 && !loadingHomeworks ? (
        <div className="p-10 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
          먼저 과제를 등록해 주세요. (과제 관리 탭에서 등록할 수 있습니다.)
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-6">
            {/* 왼쪽: 수강생 목록 */}
            <div>
              <div className="bg-gray-50 px-4 py-3 rounded-t-lg border border-b-0 border-gray-200">
                <h4 className="text-gray-900">수강생 목록 ({students.length}명)</h4>
              </div>
              <div className="border border-gray-200 rounded-b-lg divide-y divide-gray-200 max-h-[600px] overflow-y-auto">
                {students.map((student: any) => {
                  const isSelected = selectedCourseUserId === student.courseUserId;
                  const badge = !student.submitted
                    ? { label: '미제출', className: 'bg-red-100 text-red-700' }
                    : student.confirm
                    ? { label: '피드백 완료', className: 'bg-green-100 text-green-700' }
                    : { label: '피드백 필요', className: 'bg-orange-100 text-orange-700' };

                  return (
                    <button
                      key={student.courseUserId}
                      onClick={() => handleSelectStudent(student.courseUserId)}
                      className={`w-full p-4 text-left transition-colors ${
                        isSelected
                          ? 'bg-blue-50 border-l-4 border-blue-600'
                          : 'hover:bg-gray-50 border-l-4 border-transparent'
                      }`}
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <div className="text-gray-900 mb-1">{student.name}</div>
                          <div className="text-sm text-gray-600">{student.studentId}</div>
                        </div>
                        <span className={`px-2 py-1 rounded text-xs ${badge.className}`}>
                          {badge.label}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-xs text-gray-500">
                        <span>제출: {student.submittedAt}</span>
                        <span>
                          점수: {student.markingScore}점{student.scoreConv ? ` (${student.scoreConv})` : ''}
                        </span>
                      </div>
                      {0 < student.taskCnt && (
                        <div className="mt-2 text-xs text-blue-700">추가과제 {student.taskCnt}건</div>
                      )}
                    </button>
                  );
                })}

                {students.length === 0 && (
                  <div className="p-8 text-center text-gray-500">수강생이 없습니다.</div>
                )}
              </div>
            </div>

            {/* 오른쪽: 피드백/채점 */}
            <div>
              {selectedStudent ? (
                <div className="border border-gray-200 rounded-lg">
                  <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                    <h4 className="text-gray-900">
                      {selectedStudent.name} ({selectedStudent.studentId})
                    </h4>
                    <p className="text-xs text-gray-500 mt-1">제출시간: {selectedStudent.submittedAt}</p>
                  </div>
                  <div className="p-4 space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm text-gray-700 mb-2">점수(0~100)</label>
                        <input
                          type="number"
                          min="0"
                          max="100"
                          value={tempScore}
                          onChange={(e) => setTempScore(e.target.value)}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <div className="flex items-end justify-end">
                        <button
                          onClick={handleAppendTask}
                          className="flex items-center gap-2 px-4 py-2 border border-blue-200 text-blue-700 rounded-lg hover:bg-blue-50 transition-colors"
                        >
                          <Plus className="w-4 h-4" />
                          <span>추가과제 부여</span>
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm text-gray-700 mb-2">피드백</label>
                      <textarea
                        value={feedbackText}
                        onChange={(e) => setFeedbackText(e.target.value)}
                        placeholder="학생에게 전달할 피드백을 입력하세요..."
                        rows={6}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                      />
                    </div>

                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => {
                          setTempScore(String(selectedStudent.markingScore ?? 0));
                          setFeedbackText(String(selectedStudent.feedback ?? ''));
                        }}
                        className="px-4 py-2 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                      >
                        취소
                      </button>
                      <button
                        onClick={handleSubmitFeedback}
                        className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        저장
                      </button>
                    </div>

                    <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                      <div className="text-sm text-blue-900 mb-2">피드백 안내</div>
                      <div className="text-sm text-blue-700">
                        - 저장을 누르면 점수/피드백이 DB에 저장되고, 성적(과제 점수)에 즉시 반영됩니다.
                        <br />- 오프라인 과제처럼 제출 기록이 없어도, 필요하면 점수 입력이 가능합니다.
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="border border-gray-200 rounded-lg">
                  <div className="p-12 text-center text-gray-500">
                    <MessageSquare className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                    <p>학생을 선택하여</p>
                    <p>점수와 피드백을 저장하세요</p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* 통계 요약 */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-gray-200">
            <div className="p-4 bg-gray-50 rounded-lg">
              <div className="text-sm text-gray-600 mb-1">총 인원</div>
              <div className="text-2xl text-gray-900">{summary.total}명</div>
            </div>
            <div className="p-4 bg-orange-50 rounded-lg">
              <div className="text-sm text-orange-600 mb-1">피드백 필요</div>
              <div className="text-2xl text-orange-900">{summary.needFeedback}명</div>
            </div>
            <div className="p-4 bg-green-50 rounded-lg">
              <div className="text-sm text-green-600 mb-1">피드백 완료</div>
              <div className="text-2xl text-green-900">{summary.doneFeedback}명</div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

// 자료 탭
function MaterialsTab({ courseId }: { courseId: number }) {
  const [showUploadModal, setShowUploadModal] = useState(false);

  const [materials, setMaterials] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [uploadForm, setUploadForm] = useState<{
    title: string;
    content: string;
    link: string;
    file: File | null;
  }>({
    title: '',
    content: '',
    link: '',
    file: null,
  });

  const resetUploadForm = () => {
    setUploadForm({ title: '', content: '', link: '', file: null });
  };

  // 왜: 자료 목록은 DB가 기준이므로, 탭 진입/업로드/삭제 후에는 서버에서 다시 읽어와야 합니다.
  const fetchMaterials = async () => {
    if (!courseId) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getMaterials({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        id: Number(row.library_id),
        title: row.library_nm,
        uploadDate: row.upload_date_conv || '-',
        size: row.file_size_conv || '-',
        downloadUrl: row.file_url || row.library_link || '',
        hasFile: !!row.file_url,
        hasLink: !!row.library_link,
      }));
      setMaterials(mapped);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '자료 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchMaterials();
  }, [courseId]);

  const handleDownload = (material: any) => {
    const url = material.downloadUrl;
    if (!url) {
      alert('다운로드할 파일/링크가 없습니다.');
      return;
    }
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const handleDelete = (libraryId: number, title: string) => {
    void (async () => {
      // 왜: 삭제는 되돌리기 어렵기 때문에, 운영 환경에서는 반드시 확인을 한 번 더 받습니다.
      const ok = confirm(`자료 "${title}"을(를) 삭제하시겠습니까?`);
      if (!ok) return;

      try {
        const res = await tutorLmsApi.deleteMaterial({ courseId, libraryId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchMaterials();
        alert('삭제되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '삭제 중 오류가 발생했습니다.');
      }
    })();
  };

  const handleUpload = () => {
    void (async () => {
      const title = uploadForm.title.trim();
      const hasFile = !!uploadForm.file;
      const hasLink = !!uploadForm.link.trim();

      if (!title) {
        alert('자료명을 입력해 주세요.');
        return;
      }
      if (!hasFile && !hasLink) {
        alert('자료 파일 또는 링크 중 하나는 필요합니다.');
        return;
      }

      setUploading(true);
      try {
        const res = await tutorLmsApi.uploadMaterial({
          courseId,
          title,
          content: uploadForm.content,
          link: uploadForm.link,
          file: uploadForm.file,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchMaterials();
        setShowUploadModal(false);
        resetUploadForm();
        alert('업로드되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '업로드 중 오류가 발생했습니다.');
      } finally {
        setUploading(false);
      }
    })();
  };

  return (
    <>
      <div className="space-y-4">
        <div className="flex justify-end">
          <button
            onClick={() => setShowUploadModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Upload className="w-4 h-4" />
            <span>자료 업로드</span>
          </button>
        </div>

        {errorMessage && (
          <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
            {errorMessage}
          </div>
        )}

        {loading && (
          <div className="p-6 text-center text-gray-500">자료 목록을 불러오는 중...</div>
        )}

        {!loading && materials.length === 0 && (
          <div className="p-10 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
            등록된 자료가 없습니다. 우측 상단에서 자료를 업로드해 주세요.
          </div>
        )}

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
                    {material.uploadDate} · {material.size}
                    {material.hasLink && !material.hasFile && <span className="ml-2">(링크)</span>}
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleDownload(material)}
                  className="px-3 py-1.5 text-sm text-blue-700 hover:bg-blue-50 rounded transition-colors"
                >
                  다운로드
                </button>
                <button
                  onClick={() => handleDelete(material.id, material.title)}
                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="삭제"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {showUploadModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-gray-900">자료 업로드</h3>
              <button
                onClick={() => {
                  setShowUploadModal(false);
                  resetUploadForm();
                }}
                className="text-gray-500 hover:text-gray-700 transition-colors"
              >
                닫기
              </button>
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleUpload();
              }}
              className="p-6 space-y-6"
            >
              <div>
                <label className="block text-sm text-gray-700 mb-2">
                  자료명 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={uploadForm.title}
                  onChange={(e) => setUploadForm({ ...uploadForm, title: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="예: 강의자료.pdf"
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">설명</label>
                <textarea
                  value={uploadForm.content}
                  onChange={(e) => setUploadForm({ ...uploadForm, content: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  rows={3}
                  placeholder="자료에 대한 간단한 설명을 입력하세요"
                />
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">링크(선택)</label>
                <input
                  type="url"
                  value={uploadForm.link}
                  onChange={(e) => setUploadForm({ ...uploadForm, link: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="https://..."
                />
                <p className="text-sm text-gray-500 mt-1">파일 업로드 대신 링크만 등록할 수도 있습니다.</p>
              </div>

              <div>
                <label className="block text-sm text-gray-700 mb-2">파일(선택)</label>
                <input
                  type="file"
                  onChange={(e) =>
                    setUploadForm({ ...uploadForm, file: e.target.files?.[0] ?? null })
                  }
                  className="w-full"
                />
                <p className="text-sm text-gray-500 mt-1">파일 또는 링크 중 하나는 필수입니다.</p>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => {
                    setShowUploadModal(false);
                    resetUploadForm();
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  disabled={uploading}
                >
                  취소
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300"
                  disabled={uploading}
                >
                  {uploading ? '업로드 중...' : '업로드'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

// Q&A 탭
function QnaTab({ courseId }: { courseId: number }) {
  const [keyword, setKeyword] = useState('');
  const [qnas, setQnas] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [selectedPostId, setSelectedPostId] = useState<number | null>(null);
  const [detail, setDetail] = useState<any | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [answerText, setAnswerText] = useState('');

  const toBool = (value: any) =>
    value === true || value === 1 || value === '1' || value === 'Y' || value === 'true';

  // 왜: Q&A는 새 글/답변이 수시로 생기므로, 목록은 항상 서버(DB)에서 다시 읽는 방식이 안전합니다.
  const fetchQnas = async (params?: { keyword?: string }) => {
    if (!courseId) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getQnas({ courseId, keyword: params?.keyword });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        id: Number(row.id),
        subject: row.subject,
        student: row.user_nm || row.login_id || '-',
        date: row.reg_date_conv || '-',
        answered: toBool(row.answered) || Number(row.proc_status ?? 0) === 1,
      }));
      setQnas(mapped);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : 'Q&A 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const fetchDetail = async (postId: number) => {
    if (!courseId || !postId) return;
    setDetailLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getQnaDetail({ courseId, postId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      setDetail(res.rst_data ?? null);
      setAnswerText(String(res.rst_data?.answer_content ?? ''));
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : 'Q&A 상세를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setDetailLoading(false);
    }
  };

  useEffect(() => {
    void fetchQnas({ keyword: keyword.trim() ? keyword.trim() : undefined });
  }, [courseId]);

  useEffect(() => {
    if (!selectedPostId) return;
    void fetchDetail(selectedPostId);
  }, [courseId, selectedPostId]);

  const handleSaveAnswer = () => {
    if (!selectedPostId) return;
    const content = answerText.trim();
    if (!content) {
      alert('답변 내용을 입력해 주세요.');
      return;
    }

    void (async () => {
      try {
        const res = await tutorLmsApi.answerQna({ courseId, postId: selectedPostId, content });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchDetail(selectedPostId);
        await fetchQnas({ keyword: keyword.trim() ? keyword.trim() : undefined });
        alert('저장되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.');
      }
    })();
  };

  if (selectedPostId) {
    const answered = detail ? toBool(detail.answered) : false;

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                setSelectedPostId(null);
                setDetail(null);
                setAnswerText('');
              }}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <div>
              <h3 className="text-xl text-gray-900">Q&A</h3>
              <p className="text-sm text-gray-600">질문 상세 및 답변</p>
            </div>
          </div>
          <span
            className={`px-3 py-1 text-xs rounded-full ${
              answered ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
            }`}
          >
            {answered ? '답변완료' : '대기중'}
          </span>
        </div>

        {errorMessage && (
          <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
            {errorMessage}
          </div>
        )}

        {detailLoading && (
          <div className="p-6 text-center text-gray-500">상세를 불러오는 중...</div>
        )}

        {detail && (
          <div className="space-y-4">
            <div className="border border-gray-200 rounded-lg">
              <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                <div className="text-gray-900 mb-1">{detail.subject}</div>
                <div className="text-sm text-gray-600">
                  {detail.question_user_nm} · {detail.question_reg_date_conv || '-'}
                </div>
              </div>
              <div
                className="p-4 text-sm text-gray-800 prose max-w-none"
                dangerouslySetInnerHTML={{ __html: detail.question_content || '' }}
              />
            </div>

            <div className="border border-gray-200 rounded-lg">
              <div className="bg-gray-50 px-4 py-3 border-b border-gray-200 flex items-center justify-between">
                <div className="text-gray-900">답변</div>
                <div className="text-xs text-gray-500">
                  {detail.answer_reg_date_conv ? `최근 저장: ${detail.answer_reg_date_conv}` : ''}
                </div>
              </div>
              <div className="p-4 space-y-3">
                <textarea
                  value={answerText}
                  onChange={(e) => setAnswerText(e.target.value)}
                  rows={6}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  placeholder="답변 내용을 입력하세요..."
                />
                <div className="flex justify-end">
                  <button
                    onClick={handleSaveAnswer}
                    className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    {answered ? '답변 수정' : '답변 등록'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <input
          type="text"
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
          placeholder="검색어(제목)"
          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          onKeyDown={(e) => {
            if (e.key === 'Enter') void fetchQnas({ keyword: keyword.trim() ? keyword.trim() : undefined });
          }}
        />
        <button
          onClick={() => void fetchQnas({ keyword: keyword.trim() ? keyword.trim() : undefined })}
          className="px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
        >
          검색
        </button>
      </div>

      {errorMessage && (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
          {errorMessage}
        </div>
      )}

      {loading && <div className="p-6 text-center text-gray-500">Q&A 목록을 불러오는 중...</div>}

      {!loading && qnas.length === 0 && (
        <div className="p-10 text-center text-gray-500 border border-dashed border-gray-200 rounded-lg">
          Q&A 글이 없습니다.
        </div>
      )}

      <div className="space-y-4">
        {qnas.map((qna) => (
          <button
            key={qna.id}
            onClick={() => setSelectedPostId(qna.id)}
            className="w-full text-left p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-start justify-between mb-2">
              <div className="flex-1">
                <div className="text-gray-900 mb-1">{qna.subject}</div>
                <div className="text-sm text-gray-600">
                  {qna.student} · {qna.date}
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span
                  className={`px-3 py-1 text-xs rounded-full ${
                    qna.answered ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                  }`}
                >
                  {qna.answered ? '답변완료' : '대기중'}
                </span>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// 성적관리 탭
function GradesTab({ courseId }: { courseId: number }) {
  const [grades, setGrades] = useState<any[]>([]);
  const [courseInfo, setCourseInfo] = useState<any | null>(null);

  const [loading, setLoading] = useState(false);
  const [recalcLoading, setRecalcLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const toNum = (value: any, fallback = 0) => {
    const n = Number(value);
    return Number.isFinite(n) ? n : fallback;
  };

  // 왜: 성적 화면은 "현재 DB 점수"가 기준이므로, 탭 진입/재계산 후에는 서버에서 다시 불러옵니다.
  const fetchGrades = async () => {
    if (!courseId) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getGrades({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const rows = res.rst_data ?? [];
      const mapped = rows.map((row: any) => ({
        courseUserId: Number(row.course_user_id),
        studentId: row.login_id,
        name: row.user_nm,
        progressRatio: toNum(row.progress_ratio, 0),
        examScore: toNum(row.exam_score, 0),
        homeworkScore: toNum(row.homework_score, 0),
        etcScore: toNum(row.etc_score, 0),
        totalScore: toNum(row.total_score, 0),
        statusLabel: row.status_label || '',
      }));
      setGrades(mapped);
      setCourseInfo(res.rst_course ?? null);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '성적을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchGrades();
  }, [courseId]);

  const getStatusBadge = (label: string) => {
    if (label === '합격') return 'bg-green-100 text-green-700';
    if (label === '수료') return 'bg-blue-100 text-blue-700';
    return 'bg-red-100 text-red-700';
  };

  const completionCriteria = {
    progressRate: toNum(courseInfo?.complete_limit_progress, 0),
    totalScore: toNum(courseInfo?.complete_limit_total_score, 0),
  };
  const passEnabled = String(courseInfo?.pass_yn || '') === 'Y';
  const passCriteria = {
    progressRate: toNum(courseInfo?.limit_progress, 0),
    totalScore: toNum(courseInfo?.limit_total_score, 0),
  };

  const handleRecalc = () => {
    void (async () => {
      // 왜: 재계산은 전체 수강생 점수/총점을 다시 계산하므로 시간이 걸릴 수 있어, 명시적으로 눌렀을 때만 실행합니다.
      const ok = confirm('성적을 재계산하시겠습니까?\n\n(시험/과제 점수, 진도율 등을 기준으로 총점이 다시 계산됩니다.)');
      if (!ok) return;

      setRecalcLoading(true);
      try {
        const res = await tutorLmsApi.recalcGrades({ courseId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchGrades();
        alert('재계산이 완료되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '재계산 중 오류가 발생했습니다.');
      } finally {
        setRecalcLoading(false);
      }
    })();
  };

  const handleDownloadGrades = () => {
    // 왜: 성적표는 “현재 화면에 보이는 결과”가 중요하므로, 화면 상태(grades)를 그대로 CSV로 내려받습니다.
    const ymd = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const filename = `course_${courseId}_grades_${ymd}.csv`;

    const headers = ['No', 'course_user_id', '학번', '이름', '진도율(%)', '시험', '과제', '기타', '총점', '상태'];
    const rows = grades.map((g, index) => ([
      index + 1,
      g.courseUserId ?? '',
      g.studentId ?? '',
      g.name ?? '',
      Math.round(toNum(g.progressRatio, 0)),
      toNum(g.examScore, 0),
      toNum(g.homeworkScore, 0),
      toNum(g.etcScore, 0),
      toNum(g.totalScore, 0),
      g.statusLabel ?? '',
    ]));

    downloadCsv(filename, headers, rows);
  };

  return (
    <div>
      <div className="mb-4 flex justify-between items-center">
        <div className="text-sm text-gray-600">성적 조회 및 관리</div>
        <div className="flex gap-2">
          <button
            onClick={handleRecalc}
            disabled={recalcLoading}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300"
          >
            <Play className="w-4 h-4" />
            <span>{recalcLoading ? '재계산 중...' : '성적 재계산'}</span>
          </button>
          <button
            onClick={handleDownloadGrades}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
          >
            <Download className="w-4 h-4" />
            <span>성적표 다운로드(CSV)</span>
          </button>
        </div>
      </div>

      {/* 기준 안내 */}
      <div className="mb-4 p-4 bg-gray-50 border border-gray-200 rounded-lg">
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-700 mb-1">수료 기준</div>
            <div className="text-gray-600">
              진도율 {completionCriteria.progressRate}% 이상
              {completionCriteria.totalScore > 0 ? `, 총점 ${completionCriteria.totalScore}점 이상` : ''}
            </div>
          </div>
          <div>
            <div className="text-gray-700 mb-1">합격 기준</div>
            <div className="text-gray-600">
              {passEnabled
                ? `진도율 ${passCriteria.progressRate}% 이상${passCriteria.totalScore > 0 ? `, 총점 ${passCriteria.totalScore}점 이상` : ''}`
                : '미사용(과목 설정에서 pass_yn=Y일 때 적용)'}
            </div>
          </div>
        </div>
      </div>

      {errorMessage && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
          {errorMessage}
        </div>
      )}

      {loading && <div className="p-6 text-center text-gray-500">성적을 불러오는 중...</div>}

      {!loading && (
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">학번</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">시험</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">과제</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">기타</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">총점</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">결과</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {grades.map((grade) => (
                <tr key={grade.courseUserId} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-sm text-gray-900">{grade.name}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-600">{grade.studentId}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {Math.round(grade.progressRatio * 10) / 10}%
                  </td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">{grade.examScore}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">{grade.homeworkScore}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">{grade.etcScore}</td>
                  <td className="px-4 py-4 text-center">
                    <span className="inline-flex px-3 py-1 bg-blue-100 text-blue-700 rounded-full">
                      {Math.round(grade.totalScore * 100) / 100}
                    </span>
                  </td>
                  <td className="px-4 py-4 text-center">
                    <span className={`inline-flex px-3 py-1 rounded-full ${getStatusBadge(grade.statusLabel)}`}>
                      {grade.statusLabel || '미달'}
                    </span>
                  </td>
                </tr>
              ))}

              {grades.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-4 py-10 text-center text-gray-500">
                    성적 데이터가 없습니다.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

// 수료관리 탭(API 연동)
function CompletionTab({ courseId, course }: { courseId: number; course?: any }) {
  // 학사 과목 여부 체크
  const isHaksaCourse = !courseId || Number.isNaN(courseId) || courseId <= 0 || course?.sourceType === 'haksa';
  const [selectedCourseUserIds, setSelectedCourseUserIds] = useState<number[]>([]);

  const [rows, setRows] = useState<any[]>([]);
  const [courseInfo, setCourseInfo] = useState<any | null>(null);

  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const toNum = (value: any, fallback = 0) => {
    const n = Number(value);
    return Number.isFinite(n) ? n : fallback;
  };

  // 왜: 수료/종료/증명서 출력은 "운영 DB 상태"가 기준이므로, 화면 진입/처리 후에는 반드시 다시 조회합니다.
  const fetchCompletions = async () => {
    if (!courseId) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getCompletions({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const list = res.rst_data ?? [];
      const mapped = list.map((row: any) => ({
        courseUserId: Number(row.course_user_id),
        studentId: row.login_id,
        name: row.user_nm,
        progressRatio: toNum(row.progress_ratio, 0),
        totalScore: toNum(row.total_score, 0),
        completeStatus: String(row.complete_status || ''), //P/C/F/''
        completeYn: String(row.complete_yn || ''),
        completeDate: row.complete_date_conv || '-',
        closeYn: String(row.close_yn || ''),
        closeDate: row.close_date_conv || '-',
        statusLabel: row.status_label || '',
      }));
      setRows(mapped);
      setCourseInfo(res.rst_course ?? null);

      // 선택된 항목이 목록에서 사라진 경우(상태 변화 등) 선택을 정리합니다.
      setSelectedCourseUserIds((prev) =>
        prev.filter((id) => mapped.some((r: any) => r.courseUserId === id))
      );
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '수료 정보를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchCompletions();
  }, [courseId]);

  const completionCriteria = {
    progressRate: toNum(courseInfo?.complete_limit_progress, 0),
    totalScore: toNum(courseInfo?.complete_limit_total_score, 0),
  };
  const passEnabled = String(courseInfo?.pass_yn || '') === 'Y';
  const passCriteria = {
    progressRate: toNum(courseInfo?.limit_progress, 0),
    totalScore: toNum(courseInfo?.limit_total_score, 0),
  };

  const canPrintCompletion = (row: any) => row.completeStatus === 'C' || row.completeStatus === 'P';
  const canPrintPass = (row: any) => row.completeStatus === 'P';

  const getStatusBadge = (label: string) => {
    if (label === '합격') return 'bg-green-100 text-green-700';
    if (label === '수료') return 'bg-blue-100 text-blue-700';
    if (label === '종료') return 'bg-gray-100 text-gray-700';
    if (label === '미수료') return 'bg-red-100 text-red-700';
    return 'bg-yellow-100 text-yellow-800';
  };

  const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.checked) {
      setSelectedCourseUserIds(rows.map((r) => r.courseUserId));
    } else {
      setSelectedCourseUserIds([]);
    }
  };

  const handleSelectStudent = (courseUserId: number) => {
    setSelectedCourseUserIds((prev) =>
      prev.includes(courseUserId) ? prev.filter((id) => id !== courseUserId) : [...prev, courseUserId]
    );
  };

  const handleAction = (action: 'complete_y' | 'complete_n' | 'close_y' | 'close_n', label: string) => {
    if (selectedCourseUserIds.length === 0) {
      alert('처리할 학생을 선택해 주세요.');
      return;
    }

    void (async () => {
      const ok = confirm(`${label}을(를) 실행하시겠습니까?\n\n선택 인원: ${selectedCourseUserIds.length}명`);
      if (!ok) return;

      setActionLoading(true);
      try {
        const res = await tutorLmsApi.updateCompletion({ courseId, action, courseUserIds: selectedCourseUserIds });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        await fetchCompletions();
        alert('처리가 완료되었습니다.');
      } catch (e) {
        alert(e instanceof Error ? e.message : '처리 중 오류가 발생했습니다.');
      } finally {
        setActionLoading(false);
      }
    })();
  };

  const openCertificate = (courseUserId: number, type: 'C' | 'P') => {
    // 왜: 팝업 차단을 피하려면(브라우저 정책), 클릭 직후에 창을 먼저 열어 둔 뒤 URL을 채워야 합니다.
    const win = window.open('', '_blank');
    if (!win) {
      alert('팝업이 차단되었습니다. 브라우저에서 팝업 허용 후 다시 시도해 주세요.');
      return;
    }

    void (async () => {
      try {
        const res = await tutorLmsApi.issueCertificate({ courseUserId, type });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        const url = res.rst_data;
        if (!url) throw new Error('인쇄 URL을 받지 못했습니다.');
        win.location.href = url;
      } catch (e) {
        try { win.close(); } catch (ignore) {}
        alert(e instanceof Error ? e.message : '증명서 출력 중 오류가 발생했습니다.');
      }
    })();
  };

  const handlePrintBulk = (type: 'C' | 'P') => {
    if (selectedCourseUserIds.length === 0) {
      alert('출력할 학생을 선택해 주세요.');
      return;
    }

    const selectedRows = rows.filter((r) => selectedCourseUserIds.includes(r.courseUserId));
    const eligible = selectedRows.filter((r) => (type === 'P' ? canPrintPass(r) : canPrintCompletion(r)));

    if (eligible.length === 0) {
      alert(type === 'P' ? '합격증을 출력할 대상이 없습니다.' : '수료증을 출력할 대상이 없습니다.');
      return;
    }

    if (eligible.length > 20) {
      alert('한 번에 너무 많이 출력하면 팝업 차단이 될 수 있습니다. 20명 이하로 나눠서 출력해 주세요.');
      return;
    }

    // 팝업은 동기적으로 먼저 열어 둡니다.
    const opened = eligible.map((r) => ({
      row: r,
      win: window.open('', '_blank'),
    }));

    if (opened.some((x) => !x.win)) {
      opened.forEach((x) => {
        try { x.win?.close(); } catch (ignore) {}
      });
      alert('팝업이 차단되었습니다. 브라우저에서 팝업 허용 후 다시 시도해 주세요.');
      return;
    }

    void (async () => {
      const errors: string[] = [];
      for (const x of opened) {
        try {
          const res = await tutorLmsApi.issueCertificate({ courseUserId: x.row.courseUserId, type });
          if (res.rst_code !== '0000') throw new Error(res.rst_message);
          const url = res.rst_data;
          if (!url) throw new Error('인쇄 URL을 받지 못했습니다.');
          x.win!.location.href = url;
        } catch (e) {
          try { x.win?.close(); } catch (ignore) {}
          errors.push(`${x.row.name}: ${e instanceof Error ? e.message : '오류'}`);
        }
      }
      if (errors.length > 0) {
        alert(`일부 출력이 실패했습니다.\n\n${errors.join('\n')}`);
      }
    })();
  };

  const passEligibleCount = rows.filter(
    (r) => selectedCourseUserIds.includes(r.courseUserId) && canPrintPass(r)
  ).length;

  // 학사 과목: A/B/C/D/F 성적 판정 UI
  if (isHaksaCourse) {
    return (
      <HaksaGradingContent
        courseId={course?.id}
      />
    );
  }

  // 프리즘 과목: 기존 수료/과락 판정 UI
  return (
    <div>
      <div className="mb-4 p-4 bg-gray-50 border border-gray-200 rounded-lg">
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-700 mb-1">수료 기준</div>
            <div className="text-gray-600">
              진도율 {completionCriteria.progressRate}% 이상
              {completionCriteria.totalScore > 0 ? `, 총점 ${completionCriteria.totalScore}점 이상` : ''}
            </div>
          </div>
          <div>
            <div className="text-gray-700 mb-1">합격 기준</div>
            <div className="text-gray-600">
              {passEnabled
                ? `진도율 ${passCriteria.progressRate}% 이상${passCriteria.totalScore > 0 ? `, 총점 ${passCriteria.totalScore}점 이상` : ''}`
                : '미사용(과목 설정에서 pass_yn=Y일 때 적용)'}
            </div>
          </div>
        </div>
      </div>

      <div className="mb-4 flex flex-wrap gap-2 justify-end">
        <button
          onClick={() => void fetchCompletions()}
          className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
          disabled={loading || actionLoading}
        >
          새로고침
        </button>
        <button
          onClick={() => handleAction('complete_y', '수료/합격 처리')}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300"
          disabled={actionLoading}
        >
          수료/합격 처리
        </button>
        <button
          onClick={() => handleAction('complete_n', '판정 초기화')}
          className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:bg-gray-200"
          disabled={actionLoading}
        >
          판정 초기화
        </button>
        <button
          onClick={() => handleAction('close_y', '종료(마감) 처리')}
          className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:bg-gray-300"
          disabled={actionLoading}
        >
          종료(마감)
        </button>
        <button
          onClick={() => handleAction('close_n', '종료 해제')}
          className="px-4 py-2 border border-purple-200 text-purple-700 rounded-lg hover:bg-purple-50 transition-colors disabled:bg-gray-200"
          disabled={actionLoading}
        >
          종료 해제
        </button>
      </div>

      <div className="mb-4 flex gap-2 justify-end">
        <button
          onClick={() => handlePrintBulk('C')}
          disabled={selectedCourseUserIds.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          <Download className="w-4 h-4" />
          <span>수료증 일괄출력 ({selectedCourseUserIds.length})</span>
        </button>
        <button
          onClick={() => handlePrintBulk('P')}
          disabled={selectedCourseUserIds.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          <Download className="w-4 h-4" />
          <span>합격증 일괄출력 ({passEligibleCount})</span>
        </button>
      </div>

      {errorMessage && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
          {errorMessage}
        </div>
      )}

      {loading && <div className="p-6 text-center text-gray-500">수료 정보를 불러오는 중...</div>}

      {!loading && (
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-center">
                  <input
                    type="checkbox"
                    onChange={handleSelectAll}
                    checked={rows.length > 0 && selectedCourseUserIds.length === rows.length}
                    className="w-4 h-4 text-blue-600 rounded"
                  />
                </th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">이름</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">학번</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">진도율</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">총점</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">상태</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">판정/종료</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">증명서 출력</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {rows.map((data: any) => (
                <tr key={data.courseUserId} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4 text-center">
                    <input
                      type="checkbox"
                      checked={selectedCourseUserIds.includes(data.courseUserId)}
                      onChange={() => handleSelectStudent(data.courseUserId)}
                      className="w-4 h-4 text-blue-600 rounded"
                    />
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-900">{data.name}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-600">{data.studentId}</td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {Math.round(data.progressRatio * 10) / 10}%
                  </td>
                  <td className="px-4 py-4 text-center text-sm text-gray-900">
                    {Math.round(data.totalScore * 100) / 100}점
                  </td>
                  <td className="px-4 py-4 text-center">
                    <span className={`inline-flex px-3 py-1 rounded-full text-xs ${getStatusBadge(data.statusLabel)}`}>
                      {data.statusLabel || '미판정'}
                    </span>
                  </td>
                  <td className="px-4 py-4 text-center text-xs text-gray-600">
                    <div>판정: {data.completeStatus || '-'}</div>
                    <div>종료: {data.closeYn || '-'}</div>
                  </td>
                  <td className="px-4 py-4 text-center">
                    <div className="flex gap-2 justify-center">
                      <button
                        onClick={() => openCertificate(data.courseUserId, 'C')}
                        disabled={!canPrintCompletion(data)}
                        className="px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                      >
                        수료증
                      </button>
                      <button
                        onClick={() => openCertificate(data.courseUserId, 'P')}
                        disabled={!canPrintPass(data)}
                        className="px-3 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                      >
                        합격증
                      </button>
                    </div>
                  </td>
                </tr>
              ))}

              {rows.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-4 py-10 text-center text-gray-500">
                    수료 데이터가 없습니다.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

// 학사 과목 시험 관리 컴포넌트
function HaksaExamContent({
  courseId,
  haksaExams,
  setHaksaExams,
}: {
  courseId?: string;
  haksaExams: any[];
  setHaksaExams: React.Dispatch<React.SetStateAction<any[]>>;
}) {
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingExam, setEditingExam] = useState<any | null>(null); // 수정 중인 시험
  const [examList, setExamList] = useState<any[]>([]);
  const [selectedExamId, setSelectedExamId] = useState('');
  
  // 오늘 날짜 기본값
  const today = new Date().toISOString().split('T')[0];
  const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
  
  const [examSettings, setExamSettings] = useState({
    startDate: today,
    startTime: '09:00',
    endDate: nextWeek,
    endTime: '18:00',
    points: 0,
    allowRetake: false,
    retakeScore: 0,
    retakeCount: 0,
    showResults: true,
  });

  // 시험관리 목록 불러오기
  useEffect(() => {
    if (showAddModal) {
      try {
        const saved = localStorage.getItem('tutor_exams');
        if (saved) {
          setExamList(JSON.parse(saved));
        }
      } catch {
        setExamList([]);
      }
    }
  }, [showAddModal]);

  // 선택한 시험 정보
  const selectedExam = examList.find(e => e.id === selectedExamId);

  useEffect(() => {
    if (selectedExam) {
      setExamSettings(prev => ({ ...prev, points: selectedExam.totalPoints || 0 }));
    }
  }, [selectedExam]);

  const resetSettings = () => {
    setSelectedExamId('');
    setExamSettings({
      startDate: today,
      startTime: '09:00',
      endDate: nextWeek,
      endTime: '18:00',
      points: 0,
      allowRetake: false,
      retakeScore: 0,
      retakeCount: 0,
      showResults: true,
    });
  };

  const handleAddExam = () => {
    if (!selectedExamId || !selectedExam) return;

    const newExam = {
      id: `exam_${Date.now()}`,
      examId: selectedExamId,
      title: selectedExam.title,
      description: selectedExam.description,
      questionCount: selectedExam.questionIds?.length || 0,
      totalPoints: selectedExam.totalPoints,
      type: 'exam',
      weekNumber: 0,
      createdAt: new Date().toISOString(),
      settings: { ...examSettings },
    };

    const updated = [...haksaExams, newExam];
    setHaksaExams(updated);

    // 로컬스토리지 저장
    if (courseId) {
      try {
        localStorage.setItem(`haksa_exams_${courseId}`, JSON.stringify(updated));
      } catch {}
    }

    setShowAddModal(false);
    resetSettings();
  };

  // 시험 수정 시작
  const handleEditExam = (exam: any) => {
    setEditingExam(exam);
    setSelectedExamId(exam.examId);
    setExamSettings({
      startDate: exam.settings?.startDate || today,
      startTime: exam.settings?.startTime || '09:00',
      endDate: exam.settings?.endDate || nextWeek,
      endTime: exam.settings?.endTime || '18:00',
      points: exam.settings?.points || exam.totalPoints || 0,
      allowRetake: exam.settings?.allowRetake || false,
      retakeScore: exam.settings?.retakeScore || 0,
      retakeCount: exam.settings?.retakeCount || 0,
      showResults: exam.settings?.showResults !== false,
    });
  };

  // 시험 수정 저장
  const handleSaveEdit = () => {
    if (!editingExam) return;

    const updated = haksaExams.map(e => {
      if (e.id === editingExam.id) {
        return {
          ...e,
          settings: { ...examSettings },
        };
      }
      return e;
    });
    
    setHaksaExams(updated);
    if (courseId) {
      try {
        localStorage.setItem(`haksa_exams_${courseId}`, JSON.stringify(updated));
      } catch {}
    }

    setEditingExam(null);
    resetSettings();
  };

  const handleDeleteExam = (examId: string) => {
    if (!confirm('이 시험을 삭제하시겠습니까?')) return;
    const updated = haksaExams.filter(e => e.id !== examId);
    setHaksaExams(updated);
    if (courseId) {
      try {
        localStorage.setItem(`haksa_exams_${courseId}`, JSON.stringify(updated));
      } catch {}
    }
  };

  // 과목의 시험 목록 로드 (초기화)
  useEffect(() => {
    if (courseId) {
      try {
        const saved = localStorage.getItem(`haksa_exams_${courseId}`);
        if (saved) {
          setHaksaExams(JSON.parse(saved));
        }
      } catch {}
    }
  }, [courseId]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-medium text-gray-900">등록된 시험</h3>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          <span>시험 추가</span>
        </button>
      </div>

      {haksaExams.length > 0 ? (
        <div className="space-y-3">
          {haksaExams.map((exam: any) => (
            <div
              key={exam.id}
              className="p-4 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-3">
                    <ClipboardCheck className="w-5 h-5 text-red-600" />
                    <span className="font-medium text-gray-900">{exam.title}</span>
                    <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                      {exam.questionCount || 0}문제
                    </span>
                  </div>
                  
                  {/* 설정 항목들 테이블 형태로 표시 */}
                  <div className="ml-7 text-sm space-y-2 bg-gray-50 p-3 rounded-lg">
                    <div className="flex items-center">
                      <span className="w-24 text-gray-500">응시기간</span>
                      <span className="text-gray-900">
                        {exam.settings?.startDate || '-'} {exam.settings?.startTime || ''} ~ {exam.settings?.endDate || '-'} {exam.settings?.endTime || ''}
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span className="w-24 text-gray-500">배점</span>
                      <span className="text-gray-900">{exam.settings?.points || exam.totalPoints || 0}점</span>
                    </div>
                    <div className="flex items-center">
                      <span className="w-24 text-gray-500">재응시 가능</span>
                      <span className="text-gray-900">
                        {exam.settings?.allowRetake ? (
                          <>가능 ({exam.settings.retakeScore}점 미만, {exam.settings.retakeCount}회)</>
                        ) : '불가'}
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span className="w-24 text-gray-500">시험결과노출</span>
                      <span className="text-gray-900">{exam.settings?.showResults ? '노출' : '비노출'}</span>
                    </div>
                  </div>
                </div>
                
                <div className="flex gap-1 ml-4">
                  <button
                    onClick={() => handleEditExam(exam)}
                    className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="수정"
                  >
                    <Edit className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDeleteExam(exam.id)}
                    className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="삭제"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center text-gray-500 py-12 border border-dashed border-gray-300 rounded-lg">
          <ClipboardCheck className="w-12 h-12 mx-auto text-gray-300 mb-3" />
          <p className="mb-2">등록된 시험이 없습니다.</p>
          <p className="text-sm text-gray-400">시험 추가 버튼을 눌러 시험관리에서 만든 시험을 등록하세요.</p>
        </div>
      )}

      {/* 시험 추가 모달 */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowAddModal(false)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">시험 추가</h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                ×
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* 시험 선택 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  시험 선택 <span className="text-red-500">*</span>
                </label>
                {examList.length > 0 ? (
                  <select
                    value={selectedExamId}
                    onChange={(e) => setSelectedExamId(e.target.value)}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">시험을 선택하세요</option>
                    {examList.map(exam => (
                      <option key={exam.id} value={exam.id}>
                        {exam.title} ({exam.questionIds?.length || 0}문제, {exam.totalPoints}점)
                      </option>
                    ))}
                  </select>
                ) : (
                  <div className="p-4 bg-gray-50 rounded-lg text-center text-gray-500">
                    <p className="text-sm">등록된 시험이 없습니다.</p>
                    <p className="text-xs mt-1">좌측 메뉴의 시험관리에서 먼저 시험을 생성해주세요.</p>
                  </div>
                )}
              </div>

              {/* 시험 상세 설정 */}
              {selectedExamId && (
                <div className="space-y-4 pt-4 border-t border-gray-100">
                  {/* 응시 가능 기간 */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">응시 가능 기간</label>
                    <div className="flex items-center gap-2 flex-wrap">
                      <input
                        type="date"
                        value={examSettings.startDate}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, startDate: e.target.value }))}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <input
                        type="time"
                        value={examSettings.startTime}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, startTime: e.target.value }))}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="text-gray-500">부터</span>
                      <input
                        type="date"
                        value={examSettings.endDate}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, endDate: e.target.value }))}
                        min={examSettings.startDate}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <input
                        type="time"
                        value={examSettings.endTime}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, endTime: e.target.value }))}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="text-gray-500">까지</span>
                    </div>
                  </div>

                  {/* 배점 */}
                  <div className="flex items-center gap-3">
                    <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">배점</label>
                    <input
                      type="number"
                      value={examSettings.points}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                      min={0}
                      className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-600">점</span>
                  </div>

                  {/* 재응시 가능여부 */}
                  <div className="flex items-center gap-3">
                    <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능여부</label>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={examSettings.allowRetake}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, allowRetake: e.target.checked }))}
                        className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-600">재응시 가능</span>
                    </label>
                  </div>

                  {/* 재응시 기준 점수 */}
                  {examSettings.allowRetake && (
                    <>
                      <div className="flex items-center gap-3">
                        <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 기준 점수</label>
                        <input
                          type="number"
                          value={examSettings.retakeScore}
                          onChange={(e) => setExamSettings(prev => ({ ...prev, retakeScore: parseInt(e.target.value) || 0 }))}
                          min={0}
                          max={100}
                          className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <span className="text-sm text-gray-600">점 미만일때 재응시 가능</span>
                      </div>

                      <div className="flex items-center gap-3">
                        <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능 횟수</label>
                        <input
                          type="number"
                          value={examSettings.retakeCount}
                          onChange={(e) => setExamSettings(prev => ({ ...prev, retakeCount: parseInt(e.target.value) || 0 }))}
                          min={0}
                          className="w-16 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <span className="text-sm text-gray-600">회</span>
                      </div>
                    </>
                  )}

                  {/* 시험결과노출 */}
                  <div className="flex items-center gap-3">
                    <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">시험결과노출</label>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={examSettings.showResults}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, showResults: e.target.checked }))}
                        className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-600">노출</span>
                    </label>
                    <span className="text-xs text-gray-400">▶ 응시 후 수강생이 정답을 확인할 수 있습니다.</span>
                  </div>
                </div>
              )}
            </div>

            <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={() => setShowAddModal(false)}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleAddExam}
                disabled={!selectedExamId}
                className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                시험추가
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 시험 수정 모달 */}
      {editingExam && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setEditingExam(null)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">시험 수정</h3>
              <button
                onClick={() => setEditingExam(null)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                ×
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* 시험 선택 (수정 불가) */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">시험 선택</label>
                <div className="px-4 py-2.5 bg-gray-100 border border-gray-300 rounded-lg text-gray-700">
                  {editingExam.title}
                </div>
              </div>

              {/* 시험 상세 설정 */}
              <div className="space-y-4 pt-4 border-t border-gray-100">
                {/* 응시 가능 기간 */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">응시 가능 기간</label>
                  <div className="flex items-center gap-2 flex-wrap">
                    <input
                      type="date"
                      value={examSettings.startDate}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, startDate: e.target.value }))}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <input
                      type="time"
                      value={examSettings.startTime}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, startTime: e.target.value }))}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-gray-500">부터</span>
                    <input
                      type="date"
                      value={examSettings.endDate}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, endDate: e.target.value }))}
                      min={examSettings.startDate}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <input
                      type="time"
                      value={examSettings.endTime}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, endTime: e.target.value }))}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-gray-500">까지</span>
                  </div>
                </div>

                {/* 배점 */}
                <div className="flex items-center gap-3">
                  <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">배점</label>
                  <input
                    type="number"
                    value={examSettings.points}
                    onChange={(e) => setExamSettings(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                    min={0}
                    className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-600">점</span>
                </div>

                {/* 재응시 가능여부 */}
                <div className="flex items-center gap-3">
                  <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능여부</label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={examSettings.allowRetake}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, allowRetake: e.target.checked }))}
                      className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-600">재응시 가능</span>
                  </label>
                  <span className="text-xs text-gray-400">▶ 재응시를 지정하면 기준점수 미만일 경우 횟수제한 범위안에서 재응시할 수 있습니다.</span>
                </div>

                {/* 재응시 기준 점수 */}
                {examSettings.allowRetake && (
                  <>
                    <div className="flex items-center gap-3">
                      <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 기준 점수</label>
                      <input
                        type="number"
                        value={examSettings.retakeScore}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, retakeScore: parseInt(e.target.value) || 0 }))}
                        min={0}
                        max={100}
                        className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-600">점 미만일때 재응시가 가능합니다.</span>
                      <span className="text-xs text-gray-400">▶ 100점 만점 기준입니다.</span>
                    </div>

                    <div className="flex items-center gap-3">
                      <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능 횟수</label>
                      <input
                        type="number"
                        value={examSettings.retakeCount}
                        onChange={(e) => setExamSettings(prev => ({ ...prev, retakeCount: parseInt(e.target.value) || 0 }))}
                        min={0}
                        className="w-16 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-600">회까지 재응시가 가능합니다.</span>
                    </div>
                  </>
                )}

                {/* 시험결과노출 */}
                <div className="flex items-center gap-3">
                  <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">시험결과노출</label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={examSettings.showResults}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, showResults: e.target.checked }))}
                      className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-600">노출</span>
                  </label>
                  <span className="text-xs text-gray-400">▶ 응시 후 수강생이 정답을 확인할 수 있습니다.</span>
                </div>
              </div>
            </div>

            <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={() => setEditingExam(null)}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleSaveEdit}
                className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                시험수정
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 시험 선택 모달 (시험관리에서 생성한 시험 선택)
function ExamSelectModal({
  isOpen,
  onClose,
  onSave,
}: {
  isOpen: boolean;
  onClose: () => void;
  onSave: (examData: {
    title: string;
    description?: string;
    duration: number;
    questionCount: number;
    points: number;
    allowRetake: boolean;
    showResults: boolean;
  }) => void;
}) {
  const [examList, setExamList] = useState<any[]>([]);
  const [selectedExamId, setSelectedExamId] = useState('');
  
  // 오늘 날짜 기본값
  const today = new Date().toISOString().split('T')[0];
  const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
  
  const [examSettings, setExamSettings] = useState({
    startDate: today,
    endDate: nextWeek,
    points: 0,
    allowRetake: false,
    retakeScore: 0,
    retakeCount: 0,
    showResults: true,
  });

  // 시험관리 목록 불러오기
  useEffect(() => {
    if (isOpen) {
      try {
        const saved = localStorage.getItem('tutor_exams');
        if (saved) {
          setExamList(JSON.parse(saved));
        }
      } catch {
        setExamList([]);
      }
    }
  }, [isOpen]);

  // 선택한 시험 정보
  const selectedExam = examList.find(e => e.id === selectedExamId);

  useEffect(() => {
    if (selectedExam) {
      setExamSettings(prev => ({ ...prev, points: selectedExam.totalPoints || 0 }));
    }
  }, [selectedExam]);

  const handleSave = () => {
    if (!selectedExamId || !selectedExam) return;
    
    onSave({
      title: selectedExam.title,
      description: selectedExam.description,
      duration: selectedExam.duration || 60,
      questionCount: selectedExam.questionIds?.length || 0,
      points: examSettings.points,
      allowRetake: examSettings.allowRetake,
      showResults: examSettings.showResults,
      startDate: examSettings.startDate,
      endDate: examSettings.endDate,
    });
    
    // 초기화
    setSelectedExamId('');
    setExamSettings({
      startDate: today,
      endDate: nextWeek,
      points: 0,
      allowRetake: false,
      retakeScore: 0,
      retakeCount: 0,
      showResults: true,
    });
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900">시험 추가</h3>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
          >
            ×
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* 시험 선택 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              시험 선택 <span className="text-red-500">*</span>
            </label>
            {examList.length > 0 ? (
              <select
                value={selectedExamId}
                onChange={(e) => setSelectedExamId(e.target.value)}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">시험을 선택하세요</option>
                {examList.map(exam => (
                  <option key={exam.id} value={exam.id}>
                    {exam.title} ({exam.questionIds?.length || 0}문제, {exam.totalPoints}점)
                  </option>
                ))}
              </select>
            ) : (
              <div className="p-4 bg-gray-50 rounded-lg text-center text-gray-500">
                <p className="text-sm">등록된 시험이 없습니다.</p>
                <p className="text-xs mt-1">좌측 메뉴의 시험관리에서 먼저 시험을 생성해주세요.</p>
              </div>
            )}
          </div>

          {/* 시험 상세 설정 */}
          {selectedExamId && (
            <div className="space-y-4 pt-4 border-t border-gray-100">
              {/* 응시 가능 기간 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">응시 가능 기간</label>
                <div className="flex items-center gap-2">
                  <input
                    type="date"
                    value={examSettings.startDate}
                    onChange={(e) => setExamSettings(prev => ({ ...prev, startDate: e.target.value }))}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-gray-500">~</span>
                  <input
                    type="date"
                    value={examSettings.endDate}
                    onChange={(e) => setExamSettings(prev => ({ ...prev, endDate: e.target.value }))}
                    min={examSettings.startDate}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* 배점 */}
              <div className="flex items-center gap-3">
                <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">배점</label>
                <input
                  type="number"
                  value={examSettings.points}
                  onChange={(e) => setExamSettings(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                  min={0}
                  className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <span className="text-sm text-gray-600">점</span>
              </div>

              {/* 재응시 가능여부 */}
              <div className="flex items-center gap-3">
                <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능여부</label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={examSettings.allowRetake}
                    onChange={(e) => setExamSettings(prev => ({ ...prev, allowRetake: e.target.checked }))}
                    className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-600">재응시 가능</span>
                </label>
              </div>

              {/* 재응시 기준 점수 */}
              {examSettings.allowRetake && (
                <>
                  <div className="flex items-center gap-3">
                    <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 기준 점수</label>
                    <input
                      type="number"
                      value={examSettings.retakeScore}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, retakeScore: parseInt(e.target.value) || 0 }))}
                      min={0}
                      max={100}
                      className="w-20 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-600">점 미만일때 재응시 가능</span>
                  </div>

                  <div className="flex items-center gap-3">
                    <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">재응시 가능 횟수</label>
                    <input
                      type="number"
                      value={examSettings.retakeCount}
                      onChange={(e) => setExamSettings(prev => ({ ...prev, retakeCount: parseInt(e.target.value) || 0 }))}
                      min={0}
                      className="w-16 px-3 py-2 border border-gray-300 rounded-lg text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-600">회</span>
                  </div>
                </>
              )}

              {/* 시험결과노출 */}
              <div className="flex items-center gap-3">
                <label className="w-28 text-sm font-medium text-gray-700 flex-shrink-0">시험결과노출</label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={examSettings.showResults}
                    onChange={(e) => setExamSettings(prev => ({ ...prev, showResults: e.target.checked }))}
                    className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-600">노출</span>
                </label>
                <span className="text-xs text-gray-400">▶ 응시 후 수강생이 정답을 확인할 수 있습니다.</span>
              </div>
            </div>
          )}
        </div>

        <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
          >
            취소
          </button>
          <button
            onClick={handleSave}
            disabled={!selectedExamId}
            className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            </button>
        </div>
      </div>
    </div>
  );
}

// 학사 과목 성적 판정 컴포넌트 (A/B/C/D/F)
function HaksaGradingContent({
  courseId,
}: {
  courseId?: string;
}) {
  const [students, setStudents] = useState<any[]>([]);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [bulkGrade, setBulkGrade] = useState<string>('');

  // 성적 기준
  const GRADES = [
    { value: 'A', label: 'A (90-100)', min: 90, color: 'bg-blue-100 text-blue-700' },
    { value: 'B', label: 'B (80-89)', min: 80, color: 'bg-green-100 text-green-700' },
    { value: 'C', label: 'C (70-79)', min: 70, color: 'bg-yellow-100 text-yellow-700' },
    { value: 'D', label: 'D (60-69)', min: 60, color: 'bg-orange-100 text-orange-700' },
    { value: 'F', label: 'F (0-59)', min: 0, color: 'bg-red-100 text-red-700' },
  ];

  // 점수에서 자동 등급 계산
  const calculateGrade = (score: number): string => {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  };

  // API에서 수강생 데이터 로드
  useEffect(() => {
    const numericCourseId = Number(courseId);
    
    const loadStudents = async () => {
      // 저장된 성적 데이터 먼저 로드
      let savedGrades: Record<string, string> = {};
      if (courseId) {
        try {
          const saved = localStorage.getItem(`haksa_grades_${courseId}`);
          if (saved) {
            const parsed = JSON.parse(saved);
            // id -> grade 맵 생성
            savedGrades = parsed.reduce((acc: any, s: any) => {
              acc[s.id] = s.grade;
              return acc;
            }, {});
          }
        } catch {}
      }

      // API 호출이 가능한 경우 실제 학생 데이터 로드
      if (numericCourseId && !Number.isNaN(numericCourseId) && numericCourseId > 0) {
        try {
          const res = await tutorLmsApi.getCourseStudents({ courseId: numericCourseId });
          if (res.rst_code === '0000' && res.rst_data) {
            const mapped = res.rst_data.map((row: any) => ({
              id: String(row.course_user_id || row.user_id),
              name: row.name || '-',
              studentId: row.student_id || row.login_id || '-',
              score: Number(row.total_score ?? row.progress ?? 0),
              grade: savedGrades[String(row.course_user_id || row.user_id)] || '',
            }));
            setStudents(mapped);
            return;
          }
        } catch {}
      }
      
      // API 호출 실패 또는 학사 과목인 경우 빈 배열
      setStudents([]);
    };

    loadStudents();
  }, [courseId]);

  // 저장
  const saveGrades = (updatedStudents: any[]) => {
    setStudents(updatedStudents);
    if (courseId) {
      try {
        localStorage.setItem(`haksa_grades_${courseId}`, JSON.stringify(updatedStudents));
      } catch {}
    }
  };

  // 개별 성적 변경
  const handleGradeChange = (studentId: string, grade: string) => {
    const updated = students.map(s => 
      s.id === studentId ? { ...s, grade } : s
    );
    saveGrades(updated);
  };

  // 점수 기반 자동 성적 부여
  const handleAutoGrade = () => {
    const updated = students.map(s => ({
      ...s,
      grade: calculateGrade(s.score),
    }));
    saveGrades(updated);
  };

  // 선택된 학생 일괄 성적 적용
  const handleBulkGrade = () => {
    if (!bulkGrade || selectedIds.length === 0) return;
    const updated = students.map(s =>
      selectedIds.includes(s.id) ? { ...s, grade: bulkGrade } : s
    );
    saveGrades(updated);
    setSelectedIds([]);
    setBulkGrade('');
  };

  // 전체 선택/해제
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(students.map(s => s.id));
    } else {
      setSelectedIds([]);
    }
  };

  // 개별 선택
  const handleSelect = (studentId: string) => {
    setSelectedIds(prev =>
      prev.includes(studentId)
        ? prev.filter(id => id !== studentId)
        : [...prev, studentId]
    );
  };

  const getGradeBadge = (grade: string) => {
    const found = GRADES.find(g => g.value === grade);
    return found?.color || 'bg-gray-100 text-gray-700';
  };

  return (
    <div className="space-y-6">
      {/* 성적 기준 안내 */}
      <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <h4 className="font-medium text-blue-900 mb-2">학사 과목 성적 기준</h4>
        <div className="flex flex-wrap gap-3 text-sm">
          {GRADES.map(g => (
            <span key={g.value} className={`px-3 py-1 rounded-full ${g.color}`}>
              {g.label}
            </span>
          ))}
        </div>
      </div>

      {/* 액션 버튼 */}
      <div className="flex items-center gap-3 flex-wrap">
        <button
          onClick={handleAutoGrade}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          점수 기반 자동 성적 부여
        </button>

        {selectedIds.length > 0 && (
          <div className="flex items-center gap-2">
            <select
              value={bulkGrade}
              onChange={(e) => setBulkGrade(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">성적 선택</option>
              {GRADES.map(g => (
                <option key={g.value} value={g.value}>{g.value}</option>
              ))}
            </select>
            <button
              onClick={handleBulkGrade}
              disabled={!bulkGrade}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
            >
              선택 학생 일괄 적용 ({selectedIds.length}명)
            </button>
          </div>
        )}
      </div>

      {/* 학생 목록 테이블 */}
      <div className="overflow-x-auto border border-gray-200 rounded-lg">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-center w-12">
                <input
                  type="checkbox"
                  checked={selectedIds.length === students.length && students.length > 0}
                  onChange={(e) => handleSelectAll(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded"
                />
              </th>
              <th className="px-4 py-3 text-left text-gray-700">이름</th>
              <th className="px-4 py-3 text-center text-gray-700">학번</th>
              <th className="px-4 py-3 text-center text-gray-700">점수</th>
              <th className="px-4 py-3 text-center text-gray-700">성적</th>
              <th className="px-4 py-3 text-center text-gray-700">성적 변경</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {students.map((student) => (
              <tr key={student.id} className="hover:bg-gray-50">
                <td className="px-4 py-4 text-center">
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(student.id)}
                    onChange={() => handleSelect(student.id)}
                    className="w-4 h-4 text-blue-600 rounded"
                  />
                </td>
                <td className="px-4 py-4 text-gray-900">{student.name}</td>
                <td className="px-4 py-4 text-center text-gray-600">{student.studentId}</td>
                <td className="px-4 py-4 text-center text-gray-900 font-medium">{student.score}점</td>
                <td className="px-4 py-4 text-center">
                  {student.grade ? (
                    <span className={`inline-flex px-3 py-1 rounded-full text-sm font-medium ${getGradeBadge(student.grade)}`}>
                      {student.grade}
                    </span>
                  ) : (
                    <span className="text-gray-400">미판정</span>
                  )}
                </td>
                <td className="px-4 py-4 text-center">
                  <select
                    value={student.grade || ''}
                    onChange={(e) => handleGradeChange(student.id, e.target.value)}
                    className="px-3 py-1.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                  >
                    <option value="">선택</option>
                    {GRADES.map(g => (
                      <option key={g.value} value={g.value}>{g.value}</option>
                    ))}
                  </select>
                </td>
              </tr>
            ))}

            {students.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-10 text-center text-gray-500">
                  등록된 학생이 없습니다.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* 성적 통계 */}
      {students.length > 0 && (
        <div className="p-4 bg-gray-50 border border-gray-200 rounded-lg">
          <h4 className="font-medium text-gray-900 mb-3">성적 분포</h4>
          <div className="flex flex-wrap gap-4">
            {GRADES.map(g => {
              const count = students.filter(s => s.grade === g.value).length;
              return (
                <div key={g.value} className="flex items-center gap-2">
                  <span className={`px-3 py-1 rounded-full text-sm ${g.color}`}>{g.value}</span>
                  <span className="text-gray-600">{count}명</span>
                </div>
              );
            })}
            <div className="flex items-center gap-2">
              <span className="px-3 py-1 rounded-full text-sm bg-gray-100 text-gray-700">미판정</span>
              <span className="text-gray-600">{students.filter(s => !s.grade).length}명</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
