// pages/student/career/JobDetailPage.tsx — STD-C02: 공고 상세/스크랩
import { useState } from 'react';
import {
  Heart, ExternalLink, MapPin, DollarSign, Building2, Clock,
  ChevronRight, Bell, BellOff, Bookmark, Users, Calendar,
  CheckCircle2, AlertCircle, ArrowLeft, Share2, MessageSquare,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
const mockJob = {
  id: 1,
  company: '삼성SDS',
  title: '신입 백엔드 개발자 (Java/Spring)',
  location: '서울 송파구 잠실동',
  salary: '4,500~5,500만원',
  companySize: '대기업',
  employees: '약 10,000명',
  matchScore: 95,
  matchedTags: ['Java', 'Spring Boot', 'SQL', '정보처리기사'],
  missingTags: ['Kubernetes', 'AWS'],
  deadline: '2026-02-28',
  dDay: 20,
  postedDate: '2026-02-01',
  logoColor: 'from-blue-500 to-blue-700',
  applyUrl: 'https://www.samsungsds.com/kr/careers',
  companyDescription:
    '삼성SDS는 대한민국 대표 IT 서비스 기업으로, 클라우드, AI, 보안, 물류 등 다양한 분야에서 혁신적인 디지털 솔루션을 제공합니다.',
  jobDescription: `[주요 업무]
- MSA 기반 백엔드 서비스 설계 및 개발
- REST API 설계 및 구현
- 대규모 트래픽 처리를 위한 서버 최적화
- CI/CD 파이프라인 관리 및 자동화
- 코드 리뷰 및 기술 문서 작성

[자격 요건]
- Java/Kotlin 기반 백엔드 개발 경험
- Spring Boot, Spring MVC 프레임워크 이해
- RDBMS (MySQL, PostgreSQL) 사용 경험
- Git 기반 버전 관리 경험
- 컴퓨터공학 또는 관련 학과 졸업(예정)자

[우대 사항]
- 정보처리기사 자격증 보유자
- AWS/GCP 클라우드 환경 경험
- Docker, Kubernetes 사용 경험
- 대용량 데이터 처리 경험
- 오픈소스 기여 경험`,
  benefits: [
    '4대보험 완비',
    '성과급 지급',
    '자기개발비 연 200만원',
    '통근버스 운행',
    '사내 식당 운영',
    '건강검진 지원',
    '경조사 지원',
    '휴양시설 이용',
  ],
  workConditions: {
    workType: '정규직',
    workHours: '주 5일 (09:00~18:00)',
    probation: '3개월',
    location: '서울특별시 송파구 올림픽로35길 125',
  },
};

const relatedJobs = [
  { id: 2, company: 'LG CNS', title: '풀스택 개발자', matchScore: 91, dDay: 25 },
  { id: 3, company: '카카오', title: '서버 개발자', matchScore: 85, dDay: 12 },
  { id: 5, company: '토스', title: 'Backend Engineer', matchScore: 78, dDay: 35 },
  { id: 6, company: '우아한형제들', title: '주니어 백엔드 개발자', matchScore: 74, dDay: 17 },
];

export default function JobDetailPage() {
  const { t } = useTranslation();
  const [scrapped, setScrapped] = useState(true);
  const [alertEnabled, setAlertEnabled] = useState(false);
  const [memo, setMemo] = useState('삼성SDS 상반기 공채 - 서류 마감 2/28');
  const [memoSaved, setMemoSaved] = useState(false);

  const handleSaveMemo = () => {
    setMemoSaved(true);
    setTimeout(() => setMemoSaved(false), 2000);
  };

  return (
    <div className="space-y-6">
      {/* 뒤로가기 + 액션 바 */}
      <div className="flex items-center justify-between">
        <Link
          to="/career/jobs"
          className="flex items-center gap-1 text-xs text-gray-500 dark:text-slate-400 hover:text-primary-600 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          공고 목록으로
        </Link>
        <div className="flex items-center gap-2">
          <button className="btn-sm btn-ghost text-xs">
            <Share2 className="w-3.5 h-3.5" />
            공유
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 메인 콘텐츠 */}
        <div className="lg:col-span-2 space-y-4">
          {/* 공고 헤더 */}
          <div className="card p-5">
            <div className="flex items-start gap-4">
              <div className={`w-14 h-14 rounded-xl bg-gradient-to-br ${mockJob.logoColor} flex items-center justify-center shrink-0`}>
                <span className="text-white text-xl font-bold">{mockJob.company[0]}</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs text-gray-500">{mockJob.company}</span>
                  <span className="badge-sm badge-info">{mockJob.companySize}</span>
                </div>
                <h1 className="text-lg font-bold text-gray-900 dark:text-white mb-2">{t('student.jobDetailTitle')}</h1>
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500 dark:text-slate-400">
                  <span className="flex items-center gap-1"><MapPin className="w-3.5 h-3.5" />{mockJob.location}</span>
                  <span className="flex items-center gap-1"><DollarSign className="w-3.5 h-3.5" />{mockJob.salary}</span>
                  <span className="flex items-center gap-1"><Users className="w-3.5 h-3.5" />{mockJob.employees}</span>
                  <span className="flex items-center gap-1 text-danger-600 font-medium">
                    <Clock className="w-3.5 h-3.5" />D-{mockJob.dDay} ({mockJob.deadline})
                  </span>
                </div>
              </div>
            </div>

            {/* 매칭 스코어 */}
            <div className="mt-4 p-3 bg-success-50 dark:bg-success-900/10 border border-success-100 dark:border-success-800 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-medium text-success-700 dark:text-success-400">역량 매칭률</span>
                <span className="text-xl font-bold text-success-600">{mockJob.matchScore}%</span>
              </div>
              <div className="flex flex-wrap gap-1.5">
                {mockJob.matchedTags.map(tag => (
                  <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-400 flex items-center gap-1">
                    <CheckCircle2 className="w-2.5 h-2.5" />#{tag}
                  </span>
                ))}
                {mockJob.missingTags.map(tag => (
                  <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-warning-100 dark:bg-warning-900/30 text-warning-700 dark:text-warning-400 flex items-center gap-1">
                    <AlertCircle className="w-2.5 h-2.5" />#{tag} (미보유)
                  </span>
                ))}
              </div>
            </div>

            {/* 액션 버튼 */}
            <div className="flex items-center gap-3 mt-4">
              <a
                href={mockJob.applyUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="btn-primary text-sm flex items-center gap-1.5"
              >
                <ExternalLink className="w-4 h-4" />
                외부 지원하기
              </a>
              <button
                onClick={() => setScrapped(!scrapped)}
                className={`btn-sm ${scrapped ? 'btn-secondary' : 'btn-ghost'} text-xs flex items-center gap-1.5`}
              >
                <Heart className={`w-3.5 h-3.5 ${scrapped ? 'fill-danger-500 text-danger-500' : ''}`} />
                {scrapped ? '스크랩됨' : '스크랩'}
              </button>
              <button
                onClick={() => setAlertEnabled(!alertEnabled)}
                className={`btn-sm ${alertEnabled ? 'btn-secondary' : 'btn-ghost'} text-xs flex items-center gap-1.5`}
              >
                {alertEnabled ? <BellOff className="w-3.5 h-3.5" /> : <Bell className="w-3.5 h-3.5" />}
                {alertEnabled ? '알림 해제' : '마감 알림'}
              </button>
            </div>
          </div>

          {/* 기업 소개 */}
          <div className="card p-5 space-y-3">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">기업 소개</h2>
            <p className="text-sm text-gray-600 dark:text-slate-400 leading-relaxed">
              {mockJob.companyDescription}
            </p>
          </div>

          {/* 직무 상세 */}
          <div className="card p-5 space-y-3">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">직무 상세</h2>
            <div className="text-sm text-gray-600 dark:text-slate-400 whitespace-pre-wrap leading-relaxed bg-surface-muted dark:bg-slate-800 p-4 rounded-lg">
              {mockJob.jobDescription}
            </div>
          </div>

          {/* 복리후생 */}
          <div className="card p-5 space-y-3">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">복리후생</h2>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {mockJob.benefits.map(benefit => (
                <div
                  key={benefit}
                  className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-center text-xs text-gray-600 dark:text-slate-400"
                >
                  {benefit}
                </div>
              ))}
            </div>
          </div>

          {/* 근무 조건 */}
          <div className="card p-5 space-y-3">
            <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">근무 조건</h2>
            <div className="grid grid-cols-2 gap-3">
              {Object.entries({
                '고용형태': mockJob.workConditions.workType,
                '근무시간': mockJob.workConditions.workHours,
                '수습기간': mockJob.workConditions.probation,
                '근무지': mockJob.workConditions.location,
              }).map(([label, value]) => (
                <div key={label} className="flex items-center gap-2 text-xs">
                  <span className="text-gray-400 w-16 shrink-0">{label}</span>
                  <span className="text-gray-700 dark:text-slate-300">{value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 사이드바 */}
        <div className="space-y-4">
          {/* 스크랩 메모 */}
          <div className="card p-4 space-y-3">
            <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-1.5">
              <Bookmark className="w-3.5 h-3.5" />
              스크랩 메모
            </h3>
            <textarea
              value={memo}
              onChange={(e) => setMemo(e.target.value)}
              placeholder="이 공고에 대한 메모를 남겨보세요..."
              className="input w-full min-h-[80px] text-xs"
            />
            <button
              onClick={handleSaveMemo}
              className="btn-sm btn-primary w-full text-xs flex items-center justify-center gap-1"
            >
              {memoSaved ? <CheckCircle2 className="w-3.5 h-3.5" /> : <MessageSquare className="w-3.5 h-3.5" />}
              {memoSaved ? '저장 완료!' : '메모 저장'}
            </button>
          </div>

          {/* 마감 알림 설정 */}
          <div className="card p-4 space-y-3">
            <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-1.5">
              <Bell className="w-3.5 h-3.5" />
              마감 알림 설정
            </h3>
            <div className="space-y-2">
              {['마감 7일 전', '마감 3일 전', '마감 1일 전'].map((label) => (
                <label key={label} className="flex items-center gap-2 text-xs text-gray-600 dark:text-slate-400 cursor-pointer">
                  <input
                    type="checkbox"
                    defaultChecked={label === '마감 3일 전'}
                    className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                  />
                  {label}
                </label>
              ))}
            </div>
            <button
              onClick={() => setAlertEnabled(!alertEnabled)}
              className={`btn-sm w-full text-xs ${alertEnabled ? 'btn-secondary' : 'btn-ghost'}`}
            >
              {alertEnabled ? '알림 활성화됨' : '알림 설정하기'}
            </button>
          </div>

          {/* 공고 타임라인 */}
          <div className="card p-4 space-y-3">
            <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5" />
              채용 일정
            </h3>
            <div className="space-y-3">
              {[
                { label: '공고 게시일', date: mockJob.postedDate, done: true },
                { label: '서류 마감', date: mockJob.deadline, done: false },
                { label: '코딩테스트', date: '2026-03-10 (예상)', done: false },
                { label: '면접', date: '2026-03-20 (예상)', done: false },
              ].map((step, i) => (
                <div key={i} className="flex items-start gap-2">
                  <div className={`w-2 h-2 rounded-full mt-1 shrink-0 ${step.done ? 'bg-success-500' : 'bg-gray-300 dark:bg-slate-600'}`} />
                  <div>
                    <div className="text-xs text-gray-700 dark:text-slate-300">{step.label}</div>
                    <div className="text-[10px] text-gray-400">{step.date}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* 관련 공고 */}
          <div className="card p-4 space-y-3">
            <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300">관련 공고</h3>
            <div className="space-y-2">
              {relatedJobs.map(job => (
                <Link
                  key={job.id}
                  to={`/career/jobs/${job.id}`}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors"
                >
                  <div className="min-w-0 flex-1">
                    <div className="text-xs font-medium text-gray-900 dark:text-white text-truncate">{job.title}</div>
                    <div className="text-[10px] text-gray-400">{job.company} · D-{job.dDay}</div>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <span className="text-[10px] font-bold text-primary-600">{job.matchScore}%</span>
                    <ChevronRight className="w-3 h-3 text-gray-300" />
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
