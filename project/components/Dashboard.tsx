import {
  Users,
  BookOpen,
  ClipboardCheck,
  MessageSquare,
  TrendingUp,
  Calendar,
  Clock,
} from 'lucide-react';

export function Dashboard() {
  // 통계 데이터
  const stats = [
    {
      title: '진행 중인 과목',
      value: '8',
      change: '+2',
      icon: BookOpen,
      color: 'bg-blue-100 text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: '미확인 과제',
      value: '15',
      change: '',
      icon: ClipboardCheck,
      color: 'bg-orange-100 text-orange-600',
      bgColor: 'bg-orange-50',
    },
    {
      title: '미답변 Q&A',
      value: '7',
      change: '',
      icon: MessageSquare,
      color: 'bg-purple-100 text-purple-600',
      bgColor: 'bg-purple-50',
    },
  ];

  // 진행 중인 강좌 목록
  const ongoingCourses = [
    {
      id: 1,
      name: '웹 프로그래밍 기초',
      code: 'CS101',
      students: 45,
      progress: 65,
      nextClass: '2024-12-16 10:00',
      pendingAssignments: 8,
    },
    {
      id: 2,
      name: '데이터베이스 설계',
      code: 'CS201',
      students: 38,
      progress: 42,
      nextClass: '2024-12-17 14:00',
      pendingAssignments: 3,
    },
    {
      id: 3,
      name: '알고리즘과 자료구조',
      code: 'CS301',
      students: 52,
      progress: 78,
      nextClass: '2024-12-18 09:00',
      pendingAssignments: 4,
    },
    {
      id: 4,
      name: '소프트웨어 공학',
      code: 'CS401',
      students: 41,
      progress: 55,
      nextClass: '2024-12-19 13:00',
      pendingAssignments: 0,
    },
  ];

  // 최근 제출된 과제
  const recentAssignments = [
    {
      id: 1,
      student: '김민수',
      course: '웹 프로그래밍 기초',
      assignment: '1주차 HTML/CSS 실습',
      submittedAt: '10분 전',
      status: 'pending',
    },
    {
      id: 2,
      student: '이지현',
      course: '데이터베이스 설계',
      assignment: 'ER 다이어그램 작성',
      submittedAt: '25분 전',
      status: 'pending',
    },
    {
      id: 3,
      student: '박준호',
      course: '알고리즘과 자료구조',
      assignment: '정렬 알고리즘 구현',
      submittedAt: '1시간 전',
      status: 'reviewed',
    },
    {
      id: 4,
      student: '최서연',
      course: '웹 프로그래밍 기초',
      assignment: '2주차 JavaScript 과제',
      submittedAt: '2시간 전',
      status: 'pending',
    },
    {
      id: 5,
      student: '정우진',
      course: '소프트웨어 공학',
      assignment: '요구사항 분석서',
      submittedAt: '3시간 전',
      status: 'reviewed',
    },
  ];

  // 최근 Q&A
  const recentQnA = [
    {
      id: 1,
      student: '강민지',
      course: '웹 프로그래밍 기초',
      question: 'CSS Flexbox와 Grid의 차이점이 궁금합니다',
      askedAt: '15분 전',
      answered: false,
    },
    {
      id: 2,
      student: '윤서준',
      course: '데이터베이스 설계',
      question: '정규화 3단계 적용 방법에 대해 질문드립니다',
      askedAt: '1시간 전',
      answered: false,
    },
    {
      id: 3,
      student: '장은우',
      course: '알고리즘과 자료구조',
      question: '퀵 정렬의 시간 복잡도 계산 방법',
      askedAt: '2시간 전',
      answered: true,
    },
    {
      id: 4,
      student: '한서진',
      course: '소프트웨어 공학',
      question: 'Agile과 Waterfall 방법론 비교',
      askedAt: '5시간 전',
      answered: true,
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-gray-900 mb-1">대시보드</h1>
        <p className="text-gray-600">교수자 활동 현황을 한눈에 확인하세요</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {stats.map((stat, index) => (
          <div
            key={index}
            className={`${stat.bgColor} border border-gray-200 rounded-lg p-6 transition-all hover:shadow-md`}
          >
            <div className="flex items-center justify-between mb-4">
              <div className={`${stat.color} p-3 rounded-lg`}>
                <stat.icon className="w-6 h-6" />
              </div>
              {stat.change && (
                <span className="text-sm text-green-600 flex items-center gap-1">
                  <TrendingUp className="w-4 h-4" />
                  {stat.change}
                </span>
              )}
            </div>
            <div>
              <div className="text-3xl text-gray-900 mb-1">{stat.value}</div>
              <div className="text-sm text-gray-600">{stat.title}</div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 진행 중인 강좌 */}
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-blue-600" />
                <h3 className="text-gray-900">진행 중인 강좌</h3>
              </div>
              <button className="text-sm text-blue-600 hover:text-blue-700">
                전체보기
              </button>
            </div>
          </div>
          <div className="divide-y divide-gray-200">
            {ongoingCourses.map((course) => (
              <div key={course.id} className="p-6 hover:bg-gray-50 transition-colors">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h4 className="text-gray-900 mb-1">{course.name}</h4>
                    <p className="text-sm text-gray-600">{course.code}</p>
                  </div>
                  {course.pendingAssignments > 0 && (
                    <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full">
                      과제 {course.pendingAssignments}건
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-4 text-sm text-gray-600 mb-3">
                  <span className="flex items-center gap-1">
                    <Users className="w-4 h-4" />
                    {course.students}명
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar className="w-4 h-4" />
                    {course.nextClass}
                  </span>
                </div>
                <div className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">진도율</span>
                    <span className="text-gray-900">{course.progress}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full transition-all"
                      style={{ width: `${course.progress}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 과제 목록 */}
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ClipboardCheck className="w-5 h-5 text-orange-600" />
                <h3 className="text-gray-900">과제 목록</h3>
              </div>
              <button className="text-sm text-blue-600 hover:text-blue-700">
                전체보기
              </button>
            </div>
          </div>
          <div className="divide-y divide-gray-200">
            {recentAssignments.map((assignment) => (
              <div
                key={assignment.id}
                className="p-6 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <h4 className="text-gray-900 mb-1">{assignment.assignment}</h4>
                    <p className="text-sm text-gray-600 mb-1">
                      {assignment.student} · {assignment.course}
                    </p>
                  </div>
                  {assignment.status === 'pending' ? (
                    <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded-full whitespace-nowrap">
                      미확인
                    </span>
                  ) : (
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded-full whitespace-nowrap">
                      확인완료
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-1 text-sm text-gray-500">
                  <Clock className="w-4 h-4" />
                  <span>{assignment.submittedAt}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 최근 Q&A */}
      <div className="bg-white border border-gray-200 rounded-lg">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-purple-600" />
              <h3 className="text-gray-900">최근 Q&A</h3>
            </div>
            <button className="text-sm text-blue-600 hover:text-blue-700">
              전체보기
            </button>
          </div>
        </div>
        <div className="divide-y divide-gray-200">
          {recentQnA.map((qna) => (
            <div key={qna.id} className="p-6 hover:bg-gray-50 transition-colors">
              <div className="flex items-start justify-between mb-2">
                <div className="flex-1">
                  <h4 className="text-gray-900 mb-1 line-clamp-1">
                    {qna.question}
                  </h4>
                  <p className="text-sm text-gray-600 mb-1">
                    {qna.student} · {qna.course}
                  </p>
                </div>
                {!qna.answered ? (
                  <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs rounded-full whitespace-nowrap">
                    미답변
                  </span>
                ) : (
                  <span className="px-2 py-1 bg-gray-100 text-gray-700 text-xs rounded-full whitespace-nowrap">
                    답변완료
                  </span>
                )}
              </div>
              <div className="flex items-center gap-1 text-sm text-gray-500">
                <Clock className="w-4 h-4" />
                <span>{qna.askedAt}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
