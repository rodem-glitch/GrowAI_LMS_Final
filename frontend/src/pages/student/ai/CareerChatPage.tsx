// pages/student/ai/CareerChatPage.tsx — STD-A01: AI 진로 상담 챗봇
import { useState, useRef, useEffect } from 'react';
import {
  Bot, Send, User, Sparkles, MessageSquare, Clock, BookOpen,
  GraduationCap, Tags, Trash2, Plus, ChevronRight, FileText,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

// --- 타입 정의 ---
interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  ragSources?: string[];
  timestamp: string;
}

interface ChatSession {
  id: number;
  title: string;
  date: string;
  messageCount: number;
}

// --- Mock Data ---
const mockStudentContext = {
  name: '김민수',
  department: '컴퓨터공학과',
  grade: 3,
  gpa: 3.72,
  campus: '서울강서캠퍼스',
  competencyTags: ['Java', 'Python', 'SQL', 'React', 'Spring Boot', '데이터분석', '머신러닝'],
  certifications: ['정보처리기사', 'SQLD'],
  recentCourses: ['웹 개발 실무', '머신러닝 입문', 'Python 프로그래밍'],
};

const mockSessions: ChatSession[] = [
  { id: 1, title: 'NCS 기반 직무 추천', date: '2026-02-08', messageCount: 6 },
  { id: 2, title: '백엔드 개발자 진로 상담', date: '2026-02-07', messageCount: 8 },
  { id: 3, title: '자격증 취득 전략', date: '2026-02-05', messageCount: 4 },
];

const examplePrompts = [
  '내 성적으로 갈 수 있는 직무 추천해줘',
  'NCS 기반 추천 직무는?',
  '데이터 분석가가 되려면 어떤 역량이 더 필요해?',
  '현재 보유 자격증으로 취업 가능한 분야는?',
];

// AI 응답 시뮬레이션 데이터
const mockResponses: Record<string, { content: string; ragSources: string[] }> = {
  '내 성적으로 갈 수 있는 직무 추천해줘': {
    content: `김민수님의 학적 정보를 분석한 결과, 다음 직무를 추천드립니다.

**1. 백엔드 개발자 (적합도: 92%)**
- Java, Spring Boot, SQL 역량이 우수합니다
- 정보처리기사 자격이 큰 강점입니다

**2. 풀스택 개발자 (적합도: 85%)**
- React + Spring Boot 조합이 좋습니다
- 프론트/백엔드 모두 경험이 있어 유리합니다

**3. 데이터 엔지니어 (적합도: 78%)**
- Python, SQL, 데이터분석 역량 보유
- 머신러닝 과목 이수로 기초가 탄탄합니다

평점 3.72는 상위 20% 수준으로, 대부분의 IT 기업 서류 전형에서 경쟁력이 있습니다.`,
    ragSources: ['학사DB_성적정보', 'NCS_직무분류_20분류', '채용공고_분석_2026Q1'],
  },
  'NCS 기반 추천 직무는?': {
    content: `NCS 국가직무능력표준 기반으로 분석한 결과입니다.

**보유 NCS 역량 매핑:**
| NCS 분류 | 역량 | 숙련도 |
|---------|------|--------|
| 응용SW엔지니어링 | Java, Spring Boot | 상 |
| DB엔지니어링 | SQL, SQLD | 상 |
| UI/UX엔지니어링 | React | 중상 |
| 데이터분석 | Python, 머신러닝 | 중상 |

**추천 NCS 직무 (상위 3개):**
1. **응용SW개발** (20010101) - 매칭률 94%
2. **DB관리개발** (20010203) - 매칭률 87%
3. **빅데이터분석** (20010302) - 매칭률 76%

추가로 클라우드 관련 역량을 보강하시면 DevOps 엔지니어 직무도 추천드릴 수 있습니다.`,
    ragSources: ['NCS_20대분류_매핑DB', '역량태그_프로파일', 'NCS_학습모듈_2026'],
  },
  default: {
    content: `질문을 분석 중입니다. 김민수님의 학적 정보와 역량 태그를 기반으로 맞춤형 답변을 드리겠습니다.

현재 보유하신 핵심 역량(Java, Python, Spring Boot)과 자격증(정보처리기사, SQLD)을 종합적으로 고려한 분석 결과, IT 개발 직군에서 높은 경쟁력을 보유하고 계십니다.

보다 구체적인 상담을 원하시면 관심 직무나 기업 유형을 알려주세요.`,
    ragSources: ['학사DB_기본정보', '역량태그_프로파일'],
  },
};

function getCurrentTime(): string {
  return new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' });
}

export default function CareerChatPage() {
  const { t } = useTranslation();
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      role: 'assistant',
      content: '안녕하세요, 김민수님! 저는 GrowAI 진로상담 챗봇입니다.\n\n학적 정보와 역량 태그를 기반으로 맞춤형 진로 상담을 도와드립니다. 궁금한 점을 자유롭게 물어보세요!',
      ragSources: ['학사DB_기본정보'],
      timestamp: '09:30',
    },
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [sessions] = useState(mockSessions);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = (text?: string) => {
    const msgText = text || input.trim();
    if (!msgText || loading) return;
    setInput('');

    const userMessage: ChatMessage = {
      role: 'user',
      content: msgText,
      timestamp: getCurrentTime(),
    };
    setMessages((prev) => [...prev, userMessage]);
    setLoading(true);

    // AI 응답 시뮬레이션
    setTimeout(() => {
      const response = mockResponses[msgText] || mockResponses.default;
      const aiMessage: ChatMessage = {
        role: 'assistant',
        content: response.content,
        ragSources: response.ragSources,
        timestamp: getCurrentTime(),
      };
      setMessages((prev) => [...prev, aiMessage]);
      setLoading(false);
    }, 1800);
  };

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* 세션 히스토리 사이드바 */}
      <div className={`${sidebarOpen ? 'w-64' : 'w-0'} transition-all overflow-hidden shrink-0 hidden lg:block`}>
        <div className="card h-full p-0 flex flex-col">
          <div className="p-3 border-b border-gray-100 dark:border-slate-800">
            <button className="btn-primary w-full text-xs flex items-center justify-center gap-1.5">
              <Plus className="w-3.5 h-3.5" />
              새 상담 시작
            </button>
          </div>
          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            {sessions.map((s) => (
              <button
                key={s.id}
                className="w-full text-left p-2.5 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors group"
              >
                <div className="flex items-center gap-2">
                  <MessageSquare className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                  <span className="text-xs font-medium text-gray-700 dark:text-slate-300 text-truncate flex-1">
                    {s.title}
                  </span>
                  <Trash2 className="w-3 h-3 text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
                <div className="flex items-center gap-2 mt-1 ml-5.5">
                  <span className="text-[10px] text-gray-400">{s.date}</span>
                  <span className="text-[10px] text-gray-300">|</span>
                  <span className="text-[10px] text-gray-400">{s.messageCount}개 메시지</span>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* 메인 채팅 영역 */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* 채팅 헤더 */}
        <div className="flex items-center gap-2 mb-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
          <div className="flex-1">
            <h1 className="text-base font-bold text-gray-900 dark:text-white">{t('student.careerChatTitle')}</h1>
            <p className="text-[10px] text-gray-400">{t('student.careerChatDesc')}</p>
          </div>
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="btn-sm btn-ghost text-xs hidden lg:flex"
          >
            <MessageSquare className="w-3.5 h-3.5" />
            히스토리
          </button>
        </div>

        {/* 메시지 영역 */}
        <div className="flex-1 overflow-y-auto space-y-4 pb-4 scrollbar-hidden">
          {messages.map((msg, i) => (
            <div key={i} className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : ''}`}>
              {msg.role === 'assistant' && (
                <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center shrink-0">
                  <Bot className="w-4 h-4 text-white" />
                </div>
              )}
              <div className="max-w-[75%] space-y-1">
                <div
                  className={`rounded-2xl px-4 py-3 text-sm ${
                    msg.role === 'user'
                      ? 'bg-primary-600 text-white'
                      : 'bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 text-gray-700 dark:text-slate-300'
                  }`}
                >
                  <div className="whitespace-pre-wrap">{msg.content}</div>
                </div>
                {/* RAG 소스 표시 */}
                {msg.ragSources && msg.ragSources.length > 0 && (
                  <div className="flex items-center gap-1.5 flex-wrap px-1">
                    <FileText className="w-3 h-3 text-gray-300" />
                    {msg.ragSources.map((src, j) => (
                      <span
                        key={j}
                        className="text-[9px] bg-gray-100 dark:bg-slate-800 text-gray-400 px-1.5 py-0.5 rounded"
                      >
                        {src}
                      </span>
                    ))}
                  </div>
                )}
                <div className={`text-[10px] text-gray-300 dark:text-slate-600 ${msg.role === 'user' ? 'text-right' : ''}`}>
                  {msg.timestamp}
                </div>
              </div>
              {msg.role === 'user' && (
                <div className="w-7 h-7 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center shrink-0">
                  <User className="w-4 h-4 text-primary-600" />
                </div>
              )}
            </div>
          ))}
          {loading && (
            <div className="flex gap-3">
              <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center shrink-0">
                <Bot className="w-4 h-4 text-white" />
              </div>
              <div className="bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 rounded-2xl px-4 py-3">
                <div className="flex gap-1">
                  <span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" />
                  <span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }} />
                  <span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                </div>
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* 예시 프롬프트 */}
        {messages.length <= 1 && (
          <div className="flex flex-wrap gap-2 pb-3">
            {examplePrompts.map((prompt, i) => (
              <button
                key={i}
                onClick={() => handleSend(prompt)}
                className="text-xs px-3 py-1.5 rounded-full border border-gray-200 dark:border-slate-700
                  text-gray-600 dark:text-slate-400 hover:bg-primary-50 dark:hover:bg-primary-900/20
                  hover:border-primary-200 dark:hover:border-primary-800 hover:text-primary-600 transition-colors
                  flex items-center gap-1"
              >
                <ChevronRight className="w-3 h-3" />
                {prompt}
              </button>
            ))}
          </div>
        )}

        {/* 입력 */}
        <div className="flex gap-2 pt-3 border-t border-gray-100 dark:border-slate-800">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder="진로에 대해 궁금한 점을 물어보세요..."
            className="input flex-1"
          />
          <button
            onClick={() => handleSend()}
            disabled={loading || !input.trim()}
            className="btn-primary"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* 학생 컨텍스트 사이드바 */}
      <div className="w-64 shrink-0 hidden xl:block">
        <div className="card h-full p-4 space-y-4 overflow-y-auto">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase tracking-wider">
            학생 컨텍스트
          </h3>

          {/* 기본 정보 */}
          <div className="space-y-2">
            <div className="flex items-center gap-2 p-2 bg-surface-muted dark:bg-slate-800 rounded-lg">
              <GraduationCap className="w-4 h-4 text-primary-600 shrink-0" />
              <div>
                <div className="text-xs font-medium text-gray-900 dark:text-white">{mockStudentContext.name}</div>
                <div className="text-[10px] text-gray-400">{mockStudentContext.department} {mockStudentContext.grade}학년</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-center">
                <div className="text-[10px] text-gray-400">GPA</div>
                <div className="text-sm font-bold text-primary-600">{mockStudentContext.gpa}</div>
              </div>
              <div className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-center">
                <div className="text-[10px] text-gray-400">캠퍼스</div>
                <div className="text-[10px] font-medium text-gray-700 dark:text-slate-300">서울강서</div>
              </div>
            </div>
          </div>

          {/* 역량 태그 */}
          <div>
            <div className="flex items-center gap-1.5 mb-2">
              <Tags className="w-3.5 h-3.5 text-gray-400" />
              <span className="text-[10px] font-semibold text-gray-500 dark:text-slate-400">보유 역량</span>
            </div>
            <div className="flex flex-wrap gap-1">
              {mockStudentContext.competencyTags.map((tag) => (
                <span
                  key={tag}
                  className="text-[10px] px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border border-blue-100 dark:border-blue-800"
                >
                  #{tag}
                </span>
              ))}
            </div>
          </div>

          {/* 자격증 */}
          <div>
            <div className="flex items-center gap-1.5 mb-2">
              <Clock className="w-3.5 h-3.5 text-gray-400" />
              <span className="text-[10px] font-semibold text-gray-500 dark:text-slate-400">자격증</span>
            </div>
            <div className="space-y-1">
              {mockStudentContext.certifications.map((cert) => (
                <div
                  key={cert}
                  className="text-[10px] px-2 py-1 rounded bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400"
                >
                  {cert}
                </div>
              ))}
            </div>
          </div>

          {/* 최근 수강 */}
          <div>
            <div className="flex items-center gap-1.5 mb-2">
              <BookOpen className="w-3.5 h-3.5 text-gray-400" />
              <span className="text-[10px] font-semibold text-gray-500 dark:text-slate-400">최근 수강</span>
            </div>
            <div className="space-y-1">
              {mockStudentContext.recentCourses.map((course) => (
                <div
                  key={course}
                  className="text-[10px] text-gray-600 dark:text-slate-400 flex items-center gap-1"
                >
                  <ChevronRight className="w-2.5 h-2.5 text-gray-300" />
                  {course}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
