// pages/haksa/LogsPage.tsx -- 연동 로그
import { useState, useMemo } from 'react';
import { Search, ChevronLeft, ChevronRight, Info, AlertTriangle, XCircle, X, Copy, CheckCircle } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { useTranslation } from '@/i18n';

interface LogEntry {
  id: number;
  timestamp: string;
  level: 'INFO' | 'WARN' | 'ERROR';
  module: string;
  message: string;
}

// 충분한 Mock 데이터 생성 (156건)
const generateLogs = (): LogEntry[] => {
  const templates: Omit<LogEntry, 'id'>[] = [
    { timestamp: '2026-02-08 10:32:15', level: 'INFO', module: '학적', message: '학적 데이터 동기화 완료 (1,532건 처리, 0건 오류)' },
    { timestamp: '2026-02-08 10:30:00', level: 'INFO', module: '학적', message: '학적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-08 09:05:23', level: 'WARN', module: '성적', message: '성적 연동 부분 실패: 3건 오류 (학번: 20200112, 20220078, 20190034)' },
    { timestamp: '2026-02-08 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 증분 동기화 시작 (대상: 856건)' },
    { timestamp: '2026-02-07 18:05:10', level: 'INFO', module: '수강', message: '수강 데이터 동기화 완료 (2,104건 처리, 0건 오류)' },
    { timestamp: '2026-02-07 18:00:00', level: 'INFO', module: '수강', message: '수강 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-07 14:22:45', level: 'ERROR', module: '학적', message: '학적 시스템 연결 실패: Connection timeout (retry 3/3)' },
    { timestamp: '2026-02-07 14:20:30', level: 'WARN', module: '학적', message: '학적 시스템 응답 지연: 5,230ms (임계치: 3,000ms)' },
    { timestamp: '2026-02-07 09:05:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 완료 (1,285건 처리)' },
    { timestamp: '2026-02-07 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-06 22:00:00', level: 'INFO', module: '수강', message: '수강 데이터 야간 배치 동기화 완료 (3,211건)' },
    { timestamp: '2026-02-06 18:30:00', level: 'WARN', module: '수강', message: '수강 취소 처리 지연: 대기열 12건' },
    { timestamp: '2026-02-06 15:00:00', level: 'INFO', module: '학적', message: '학적 데이터 증분 동기화 완료 (45건)' },
    { timestamp: '2026-02-06 14:00:00', level: 'ERROR', module: '성적', message: '성적 시스템 DB 연결 풀 초과: max_connections=100' },
    { timestamp: '2026-02-06 12:00:00', level: 'INFO', module: '학적', message: '학적 변동 알림 발송 완료 (대상: 23건)' },
    { timestamp: '2026-02-06 09:30:00', level: 'INFO', module: '성적', message: '성적 증분 동기화 완료 (128건 처리)' },
    { timestamp: '2026-02-06 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 증분 동기화 시작' },
    { timestamp: '2026-02-06 08:00:00', level: 'WARN', module: '학적', message: '학적 API 응답 지연: 평균 2,100ms' },
    { timestamp: '2026-02-05 23:00:00', level: 'INFO', module: '수강', message: '수강 야간 전체 동기화 완료 (4,502건)' },
    { timestamp: '2026-02-05 18:00:00', level: 'INFO', module: '수강', message: '수강 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-05 15:30:00', level: 'ERROR', module: '수강', message: '수강 신청 연동 실패: 학사 시스템 점검 중 (503 Service Unavailable)' },
    { timestamp: '2026-02-05 14:00:00', level: 'INFO', module: '학적', message: '학적 데이터 증분 동기화 완료 (67건)' },
    { timestamp: '2026-02-05 12:00:00', level: 'WARN', module: '성적', message: '성적 데이터 불일치 감지: 12건 (자동 보정 처리)' },
    { timestamp: '2026-02-05 09:05:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 완료 (1,302건)' },
    { timestamp: '2026-02-05 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-04 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (2,890건)' },
    { timestamp: '2026-02-04 18:30:00', level: 'INFO', module: '학적', message: '학적 전체 동기화 완료 (1,498건)' },
    { timestamp: '2026-02-04 18:00:00', level: 'INFO', module: '학적', message: '학적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-04 14:45:00', level: 'ERROR', module: '학적', message: '학적 데이터 무결성 검증 실패: 중복 학번 2건 감지' },
    { timestamp: '2026-02-04 12:00:00', level: 'WARN', module: '수강', message: '수강 신청 데이터 지연: 큐 대기 시간 45초' },
    { timestamp: '2026-02-04 09:05:00', level: 'INFO', module: '성적', message: '성적 증분 동기화 완료 (234건)' },
    { timestamp: '2026-02-04 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 증분 동기화 시작' },
    { timestamp: '2026-02-03 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (3,105건)' },
    { timestamp: '2026-02-03 18:00:00', level: 'INFO', module: '수강', message: '수강 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-03 15:00:00', level: 'WARN', module: '성적', message: '성적 API 타임아웃 발생: 3회 재시도 후 성공' },
    { timestamp: '2026-02-03 14:00:00', level: 'INFO', module: '학적', message: '학적 데이터 증분 동기화 완료 (89건)' },
    { timestamp: '2026-02-03 12:30:00', level: 'ERROR', module: '수강', message: '수강 데이터 동기화 실패: 네트워크 오류 (ECONNRESET)' },
    { timestamp: '2026-02-03 09:05:00', level: 'INFO', module: '성적', message: '성적 전체 동기화 완료 (1,450건)' },
    { timestamp: '2026-02-03 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-02 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (2,760건)' },
    { timestamp: '2026-02-02 18:30:00', level: 'INFO', module: '학적', message: '학적 전체 동기화 완료 (1,510건)' },
    { timestamp: '2026-02-02 18:00:00', level: 'INFO', module: '학적', message: '학적 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-02 14:00:00', level: 'WARN', module: '학적', message: '학적 시스템 점검 예정 알림 수신 (02-03 03:00~05:00)' },
    { timestamp: '2026-02-02 09:05:00', level: 'INFO', module: '성적', message: '성적 증분 동기화 완료 (567건)' },
    { timestamp: '2026-02-02 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 증분 동기화 시작' },
    { timestamp: '2026-02-01 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (4,200건)' },
    { timestamp: '2026-02-01 18:00:00', level: 'INFO', module: '수강', message: '수강 데이터 전체 동기화 시작' },
    { timestamp: '2026-02-01 15:20:00', level: 'ERROR', module: '성적', message: '성적 시스템 인증 실패: Token expired (갱신 필요)' },
    { timestamp: '2026-02-01 14:00:00', level: 'INFO', module: '학적', message: '학적 증분 동기화 완료 (112건)' },
    { timestamp: '2026-02-01 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 시작' },
    { timestamp: '2026-01-31 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (3,560건)' },
    { timestamp: '2026-01-31 18:30:00', level: 'INFO', module: '학적', message: '학적 전체 동기화 완료 (1,525건)' },
    { timestamp: '2026-01-31 15:00:00', level: 'WARN', module: '수강', message: '수강 데이터 동기화 지연: 대기열 28건' },
    { timestamp: '2026-01-31 12:00:00', level: 'INFO', module: '성적', message: '성적 증분 동기화 완료 (345건)' },
    { timestamp: '2026-01-31 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 증분 동기화 시작' },
    { timestamp: '2026-01-30 22:00:00', level: 'INFO', module: '수강', message: '수강 야간 배치 완료 (2,980건)' },
    { timestamp: '2026-01-30 18:00:00', level: 'INFO', module: '학적', message: '학적 전체 동기화 완료 (1,512건)' },
    { timestamp: '2026-01-30 14:45:00', level: 'ERROR', module: '학적', message: '학적 데이터 파싱 오류: 잘못된 날짜 형식 (학번: 20210045)' },
    { timestamp: '2026-01-30 09:05:00', level: 'INFO', module: '성적', message: '성적 전체 동기화 완료 (1,390건)' },
    { timestamp: '2026-01-30 09:00:00', level: 'INFO', module: '성적', message: '성적 데이터 전체 동기화 시작' },
  ];
  return templates.map((t, i) => ({ ...t, id: i + 1 }));
};

const allLogs = generateLogs();

const levelConfig: Record<string, { badge: string; icon: LucideIcon }> = {
  INFO: {
    badge: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    icon: Info,
  },
  WARN: {
    badge: 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
    icon: AlertTriangle,
  },
  ERROR: {
    badge: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    icon: XCircle,
  },
};

const ITEMS_PER_PAGE = 10;

export default function LogsPage() {
  const { t } = useTranslation();
  const [logLevel, setLogLevel] = useState('전체');
  const [module, setModule] = useState('전체');
  const [startDate, setStartDate] = useState('2026-02-07');
  const [endDate, setEndDate] = useState('2026-02-08');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null);
  const [copied, setCopied] = useState(false);

  // 실제 필터링 적용
  const filtered = useMemo(() => {
    return allLogs.filter((log) => {
      const logDate = log.timestamp.split(' ')[0];
      const matchLevel = logLevel === '전체' || log.level === logLevel;
      const matchModule = module === '전체' || log.module === module;
      const matchStart = !startDate || logDate >= startDate;
      const matchEnd = !endDate || logDate <= endDate;
      return matchLevel && matchModule && matchStart && matchEnd;
    });
  }, [logLevel, module, startDate, endDate]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paged = filtered.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

  const handleSearch = () => {
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  // 페이지네이션 번호 계산
  const getPageNumbers = (): (number | '...')[] => {
    const pages: (number | '...')[] = [];
    if (totalPages <= 5) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (currentPage > 3) pages.push('...');
      const start = Math.max(2, currentPage - 1);
      const end = Math.min(totalPages - 1, currentPage + 1);
      for (let i = start; i <= end; i++) pages.push(i);
      if (currentPage < totalPages - 2) pages.push('...');
      pages.push(totalPages);
    }
    return pages;
  };

  const handleCopyLog = (log: LogEntry) => {
    const text = `[${log.timestamp}] [${log.level}] [${log.module}] ${log.message}`;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.logsTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.logsDesc')}</p>
      </div>

      {/* 필터 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="flex items-center gap-2 flex-1">
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
            />
            <span className="text-gray-400 text-sm">~</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
            />
          </div>
          <select
            value={logLevel}
            onChange={(e) => setLogLevel(e.target.value)}
            className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="전체">{t('common.all')}</option>
            <option value="INFO">INFO</option>
            <option value="WARN">WARN</option>
            <option value="ERROR">ERROR</option>
          </select>
          <select
            value={module}
            onChange={(e) => setModule(e.target.value)}
            className="px-3 py-2 border border-gray-200 dark:border-slate-700 rounded-lg text-sm bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="전체">{t('common.all')}</option>
            <option value="학적">학적</option>
            <option value="성적">성적</option>
            <option value="수강">수강</option>
          </select>
          <button
            onClick={handleSearch}
            className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors"
          >
            <Search className="w-4 h-4" />
            {t('common.search')}
          </button>
        </div>
      </div>

      {/* 로그 목록 */}
      <div className="space-y-2">
        {paged.length > 0 ? (
          paged.map((log) => {
            const config = levelConfig[log.level];
            const LevelIcon = config.icon;
            return (
              <div
                key={log.id}
                onClick={() => setSelectedLog(log)}
                className="card p-3 flex items-start gap-3 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-800 transition-all cursor-pointer"
              >
                {/* 타임스탬프 */}
                <div className="flex-shrink-0 text-[10px] text-gray-400 dark:text-slate-500 font-mono min-w-[130px] pt-0.5">
                  {log.timestamp}
                </div>

                {/* 레벨 뱃지 */}
                <span className={`flex-shrink-0 inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold min-w-[60px] justify-center ${config.badge}`}>
                  <LevelIcon className="w-3 h-3" />
                  {log.level}
                </span>

                {/* 모듈 */}
                <span className="flex-shrink-0 inline-flex px-2 py-0.5 rounded bg-gray-100 dark:bg-slate-700 text-[10px] font-medium text-gray-600 dark:text-slate-400 min-w-[40px] justify-center">
                  {log.module}
                </span>

                {/* 메시지 */}
                <p className="flex-1 text-sm text-gray-700 dark:text-slate-300">{log.message}</p>
              </div>
            );
          })
        ) : (
          <div className="card p-12 flex flex-col items-center gap-2">
            <Info className="w-10 h-10 text-gray-300 dark:text-gray-600" />
            <p className="text-sm text-gray-400 dark:text-gray-500">{t('common.noData')}</p>
          </div>
        )}
      </div>

      {/* 페이지네이션 */}
      {filtered.length > 0 && (
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500 dark:text-slate-400">
            총 {filtered.length}건 중 {(currentPage - 1) * ITEMS_PER_PAGE + 1}-{Math.min(currentPage * ITEMS_PER_PAGE, filtered.length)} 표시
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => handlePageChange(currentPage - 1)}
              disabled={currentPage === 1}
              className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-400 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            {getPageNumbers().map((page, idx) =>
              page === '...' ? (
                <span key={`dots-${idx}`} className="text-gray-400 text-sm px-1">...</span>
              ) : (
                <button
                  key={page}
                  onClick={() => handlePageChange(page)}
                  className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                    currentPage === page
                      ? 'bg-primary-600 text-white'
                      : 'hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400'
                  }`}
                >
                  {page}
                </button>
              )
            )}
            <button
              onClick={() => handlePageChange(currentPage + 1)}
              disabled={currentPage === totalPages}
              className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* 로그 상세 모달 */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedLog(null)}>
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
          <div className="relative bg-white dark:bg-slate-800 rounded-2xl shadow-2xl w-full max-w-lg p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">로그 상세</h3>
              <button onClick={() => setSelectedLog(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between items-center">
                <span className="text-gray-500">시간</span>
                <span className="font-mono font-medium text-gray-900 dark:text-white">{selectedLog.timestamp}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-500">레벨</span>
                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold ${levelConfig[selectedLog.level].badge}`}>
                  {(() => { const Icon = levelConfig[selectedLog.level].icon; return <Icon className="w-3 h-3" />; })()}
                  {selectedLog.level}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-500">모듈</span>
                <span className="inline-flex px-2 py-0.5 rounded bg-gray-100 dark:bg-slate-700 text-xs font-medium text-gray-600 dark:text-slate-400">
                  {selectedLog.module}
                </span>
              </div>
              <div>
                <span className="text-gray-500 block mb-1">메시지</span>
                <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3 text-sm text-gray-800 dark:text-slate-200 font-mono leading-relaxed">
                  {selectedLog.message}
                </div>
              </div>
            </div>
            <div className="mt-5 flex gap-2">
              <button
                onClick={() => handleCopyLog(selectedLog)}
                className="flex-1 flex items-center justify-center gap-2 py-2 border border-gray-200 dark:border-slate-700 text-sm font-medium rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors text-gray-700 dark:text-slate-300"
              >
                {copied ? <CheckCircle className="w-4 h-4 text-green-500" /> : <Copy className="w-4 h-4" />}
                {copied ? '복사됨' : '로그 복사'}
              </button>
              <button
                onClick={() => setSelectedLog(null)}
                className="flex-1 py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors"
              >
                {t('common.close')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
