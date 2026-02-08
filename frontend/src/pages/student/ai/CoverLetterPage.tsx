// pages/student/ai/CoverLetterPage.tsx — STD-A02: AI 자소서 생성
import { useState } from 'react';
import {
  Sparkles, FileText, Download, Clock, Edit3, RotateCcw,
  Building2, Briefcase, ChevronDown, ChevronRight, CheckCircle2, Copy,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
interface CoverLetterVersion {
  id: number;
  company: string;
  position: string;
  createdAt: string;
  content: string;
}

const mockVersionHistory: CoverLetterVersion[] = [
  {
    id: 3,
    company: '삼성SDS',
    position: '백엔드 개발자',
    createdAt: '2026-02-08 14:30',
    content: '',
  },
  {
    id: 2,
    company: 'LG CNS',
    position: '풀스택 개발자',
    createdAt: '2026-02-06 10:15',
    content: '',
  },
  {
    id: 1,
    company: 'NHN',
    position: 'Java 개발자',
    createdAt: '2026-02-03 16:45',
    content: '',
  },
];

const mockGeneratedLetter = `[성장 과정 및 지원 동기]

저는 한국폴리텍대학교 컴퓨터공학과에서 실무 중심의 교육을 받으며, 소프트웨어 개발에 대한 열정을 키워왔습니다. 특히 'Python 프로그래밍 기초'와 '웹 개발 실무' 과목에서 팀 프로젝트를 진행하며, 체계적인 코드 설계와 협업의 중요성을 깊이 체감하였습니다.

삼성SDS의 기술 블로그에서 MSA(마이크로서비스 아키텍처) 전환 사례를 접하고, 대규모 시스템을 안정적으로 운영하는 기술력에 감명받아 지원하게 되었습니다.

[핵심 역량]

1. Java/Spring Boot 기반 백엔드 개발 역량
   - 'Spring Boot 실습' 과목에서 REST API 서버를 설계하고, JPA를 활용한 데이터베이스 연동 프로젝트를 수행하였습니다.
   - 정보처리기사 자격을 취득하며 소프트웨어 공학 전반에 대한 이해를 넓혔습니다.

2. 데이터 분석 및 활용 능력
   - '머신러닝 입문' 과목에서 Python과 scikit-learn을 활용한 예측 모델을 구현하고, SQLD 자격을 통해 데이터 관리 역량을 인증받았습니다.

3. 협업 및 문제 해결 능력
   - Git을 활용한 버전 관리와 코드 리뷰 문화를 실천하며, 3개의 팀 프로젝트를 성공적으로 완수하였습니다.
   - 팀원 간 갈등 상황에서 중재자 역할을 맡아 프로젝트 일정을 준수한 경험이 있습니다.

[입사 후 포부]

입사 후에는 삼성SDS의 클라우드 플랫폼 개발팀에서 안정적이고 확장 가능한 백엔드 시스템 구축에 기여하고 싶습니다. 현재 보유한 Java, Spring Boot, SQL 역량을 기반으로, 입사 후 1년 내에 AWS 기반 클라우드 아키텍처 역량을 보강하여 팀에 실질적인 기여를 하겠습니다.

궁극적으로는 기술을 통해 사회에 가치를 전달하는 개발자로 성장하겠습니다.`;

export default function CoverLetterPage() {
  const { t } = useTranslation();
  const [company, setCompany] = useState('');
  const [position, setPosition] = useState('');
  const [generating, setGenerating] = useState(false);
  const [generatedContent, setGeneratedContent] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [editContent, setEditContent] = useState('');
  const [showHistory, setShowHistory] = useState(false);
  const [copied, setCopied] = useState(false);
  const [generated, setGenerated] = useState(false);

  // AI 자소서 생성 시뮬레이션
  const handleGenerate = () => {
    if (!company.trim() || !position.trim()) return;
    setGenerating(true);
    setGenerated(false);
    setIsEditing(false);

    // 점진적 생성 시뮬레이션
    setTimeout(() => {
      setGeneratedContent(mockGeneratedLetter);
      setEditContent(mockGeneratedLetter);
      setGenerating(false);
      setGenerated(true);
    }, 2500);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(generatedContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSaveEdit = () => {
    setGeneratedContent(editContent);
    setIsEditing(false);
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center">
          <Sparkles className="w-5 h-5 text-white" />
        </div>
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.coverLetterTitle')}</h1>
          <p className="text-[10px] text-gray-400">{t('student.coverLetterDesc')}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 입력 폼 + 생성 결과 */}
        <div className="lg:col-span-2 space-y-4">
          {/* 입력 폼 */}
          <div className="card p-5 space-y-4">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">지원 정보 입력</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1.5">
                  <Building2 className="w-3.5 h-3.5 inline mr-1" />
                  지원 기업
                </label>
                <input
                  type="text"
                  value={company}
                  onChange={(e) => setCompany(e.target.value)}
                  placeholder="예: 삼성SDS"
                  className="input w-full"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1.5">
                  <Briefcase className="w-3.5 h-3.5 inline mr-1" />
                  지원 직무
                </label>
                <input
                  type="text"
                  value={position}
                  onChange={(e) => setPosition(e.target.value)}
                  placeholder="예: 백엔드 개발자"
                  className="input w-full"
                />
              </div>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={handleGenerate}
                disabled={generating || !company.trim() || !position.trim()}
                className="btn-primary text-sm flex items-center gap-1.5"
              >
                {generating ? (
                  <RotateCcw className="w-4 h-4 animate-spin" />
                ) : (
                  <Sparkles className="w-4 h-4" />
                )}
                {generating ? 'AI 생성 중...' : 'AI 자소서 생성'}
              </button>
              <span className="text-[10px] text-gray-400">
                학적정보 + 역량태그 + 이수과목 데이터가 자동 반영됩니다
              </span>
            </div>
          </div>

          {/* 생성 결과 */}
          {generating && (
            <div className="card p-8 text-center">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary-100 to-secondary-100 dark:from-primary-900/30 dark:to-secondary-900/30 flex items-center justify-center mx-auto mb-3">
                <Sparkles className="w-6 h-6 text-primary-500 animate-pulse" />
              </div>
              <p className="text-sm text-gray-600 dark:text-slate-400">
                {company} / {position} 맞춤 자소서를 생성하고 있습니다...
              </p>
              <p className="text-[10px] text-gray-400 mt-1">학적 정보, 이수 과목, 역량 태그를 분석 중입니다</p>
              <div className="w-48 h-1.5 bg-gray-100 dark:bg-slate-700 rounded-full mx-auto mt-4 overflow-hidden">
                <div className="h-full bg-primary-500 rounded-full animate-pulse" style={{ width: '60%' }} />
              </div>
            </div>
          )}

          {generated && !generating && (
            <div className="card p-5 space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-success-500" />
                  <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">
                    생성된 자기소개서
                  </h2>
                  <span className="badge-sm badge-info">{company} - {position}</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => { setIsEditing(!isEditing); setEditContent(generatedContent); }}
                    className="btn-sm btn-ghost text-xs"
                  >
                    <Edit3 className="w-3 h-3" />
                    {isEditing ? '취소' : '편집'}
                  </button>
                  <button onClick={handleCopy} className="btn-sm btn-ghost text-xs">
                    <Copy className="w-3 h-3" />
                    {copied ? '복사됨!' : '복사'}
                  </button>
                </div>
              </div>

              {isEditing ? (
                <div className="space-y-3">
                  <textarea
                    value={editContent}
                    onChange={(e) => setEditContent(e.target.value)}
                    className="input w-full min-h-[400px] text-sm leading-relaxed font-mono"
                  />
                  <div className="flex items-center gap-2">
                    <button onClick={handleSaveEdit} className="btn-primary text-xs">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      저장
                    </button>
                    <button onClick={() => setIsEditing(false)} className="btn-sm btn-ghost text-xs">취소</button>
                  </div>
                </div>
              ) : (
                <div className="p-4 bg-surface-muted dark:bg-slate-800 rounded-lg">
                  <div className="text-sm text-gray-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed">
                    {generatedContent}
                  </div>
                </div>
              )}

              {/* 다운로드 버튼 */}
              <div className="flex items-center gap-2 pt-2 border-t border-gray-100 dark:border-slate-800">
                <button className="btn-sm btn-secondary text-xs flex items-center gap-1.5">
                  <Download className="w-3.5 h-3.5" />
                  PDF 다운로드
                </button>
                <button className="btn-sm btn-secondary text-xs flex items-center gap-1.5">
                  <Download className="w-3.5 h-3.5" />
                  DOCX 다운로드
                </button>
                <span className="text-[10px] text-gray-400 ml-2">
                  생성일: {new Date().toLocaleDateString('ko-KR')}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* 버전 히스토리 사이드바 */}
        <div className="space-y-4">
          <div className="card p-4 space-y-3">
            <button
              onClick={() => setShowHistory(!showHistory)}
              className="flex items-center justify-between w-full"
            >
              <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-1.5">
                <Clock className="w-4 h-4" />
                버전 히스토리
              </h2>
              <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showHistory ? 'rotate-180' : ''}`} />
            </button>
            {showHistory && (
              <div className="space-y-2">
                {mockVersionHistory.map((v) => (
                  <button
                    key={v.id}
                    className="w-full text-left p-3 rounded-lg border border-gray-100 dark:border-slate-800
                      hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors"
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <FileText className="w-3.5 h-3.5 text-primary-500" />
                      <span className="text-xs font-medium text-gray-900 dark:text-white">{v.company}</span>
                    </div>
                    <div className="text-[10px] text-gray-500 ml-5">{v.position}</div>
                    <div className="text-[10px] text-gray-400 ml-5 mt-0.5">{v.createdAt}</div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* 참고 정보 */}
          <div className="card p-4 space-y-3 bg-gradient-to-br from-primary-50 to-secondary-50 dark:from-primary-900/10 dark:to-secondary-900/10 border-primary-100 dark:border-primary-800">
            <h3 className="text-xs font-semibold text-primary-700 dark:text-primary-400">자동 반영 데이터</h3>
            <div className="space-y-2 text-[10px]">
              <div className="flex items-center gap-1.5 text-gray-600 dark:text-slate-400">
                <ChevronRight className="w-3 h-3 text-primary-400" />
                학과: 컴퓨터공학과 / GPA: 3.72
              </div>
              <div className="flex items-center gap-1.5 text-gray-600 dark:text-slate-400">
                <ChevronRight className="w-3 h-3 text-primary-400" />
                자격증: 정보처리기사, SQLD
              </div>
              <div className="flex items-center gap-1.5 text-gray-600 dark:text-slate-400">
                <ChevronRight className="w-3 h-3 text-primary-400" />
                핵심 역량: Java, Python, Spring Boot
              </div>
              <div className="flex items-center gap-1.5 text-gray-600 dark:text-slate-400">
                <ChevronRight className="w-3 h-3 text-primary-400" />
                주요 과목: 웹 개발 실무, 머신러닝 입문
              </div>
            </div>
          </div>

          {/* 작성 팁 */}
          <div className="card p-4 space-y-2">
            <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300">자소서 작성 팁</h3>
            <ul className="space-y-1.5 text-[10px] text-gray-500 dark:text-slate-400">
              <li className="flex items-start gap-1.5">
                <span className="text-primary-500 mt-0.5">1.</span>
                생성된 내용을 그대로 사용하지 마세요
              </li>
              <li className="flex items-start gap-1.5">
                <span className="text-primary-500 mt-0.5">2.</span>
                본인의 경험과 감정을 구체적으로 추가하세요
              </li>
              <li className="flex items-start gap-1.5">
                <span className="text-primary-500 mt-0.5">3.</span>
                지원 기업의 인재상에 맞게 수정하세요
              </li>
              <li className="flex items-start gap-1.5">
                <span className="text-primary-500 mt-0.5">4.</span>
                맞춤법과 어투를 최종 검토하세요
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
