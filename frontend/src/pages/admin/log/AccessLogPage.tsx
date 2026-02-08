// pages/admin/log/AccessLogPage.tsx — ADM-Y01: 접속 로그 관리
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Search, Download, Calendar, Monitor, Globe, Clock, BarChart3, Filter, ChevronLeft, ChevronRight } from 'lucide-react';

/* ───── 접속 로그 데이터 (20건) ───── */
const mockLogs = [
  { id: 1, time: '2026-02-08 16:45:12', user: '김**', userId: '20***01', ip: '192.168.1.45', browser: 'Chrome 120', url: '/api/courses', method: 'GET', status: 200, responseTime: 45 },
  { id: 2, time: '2026-02-08 16:44:58', user: '이**', userId: '20***15', ip: '10.0.0.88', browser: 'Safari 18', url: '/api/ai/chat', method: 'POST', status: 200, responseTime: 1250 },
  { id: 3, time: '2026-02-08 16:44:33', user: '박**', userId: '20***23', ip: '172.16.0.12', browser: 'Firefox 122', url: '/api/auth/login', method: 'POST', status: 401, responseTime: 32 },
  { id: 4, time: '2026-02-08 16:44:15', user: '최**', userId: '20***32', ip: '192.168.1.102', browser: 'Chrome 120', url: '/api/homework/submit', method: 'POST', status: 200, responseTime: 230 },
  { id: 5, time: '2026-02-08 16:43:52', user: '정**', userId: '20***48', ip: '10.0.0.55', browser: 'Edge 120', url: '/api/exam/start', method: 'POST', status: 200, responseTime: 88 },
  { id: 6, time: '2026-02-08 16:43:28', user: '한**', userId: '20***12', ip: '192.168.2.33', browser: 'Chrome 120', url: '/api/video/stream', method: 'GET', status: 200, responseTime: 15 },
  { id: 7, time: '2026-02-08 16:43:05', user: '오**', userId: '20***67', ip: '172.16.0.45', browser: 'Safari 18', url: '/api/board/list', method: 'GET', status: 200, responseTime: 62 },
  { id: 8, time: '2026-02-08 16:42:41', user: '강**', userId: '20***78', ip: '10.0.0.22', browser: 'Chrome 120', url: '/api/board/write', method: 'POST', status: 200, responseTime: 105 },
  { id: 9, time: '2026-02-08 16:42:18', user: 'SYSTEM', userId: '-', ip: '127.0.0.1', browser: '-', url: '/api/health', method: 'GET', status: 200, responseTime: 2 },
  { id: 10, time: '2026-02-08 16:41:55', user: '윤**', userId: '20***89', ip: '192.168.1.78', browser: 'Chrome 120', url: '/api/ai/recommend', method: 'GET', status: 200, responseTime: 890 },
  { id: 11, time: '2026-02-08 16:41:30', user: '임**', userId: '20***95', ip: '10.0.0.33', browser: 'Firefox 122', url: '/api/auth/refresh', method: 'POST', status: 403, responseTime: 18 },
  { id: 12, time: '2026-02-08 16:41:02', user: '송**', userId: '20***02', ip: '192.168.2.88', browser: 'Chrome 120', url: '/api/courses/detail/42', method: 'GET', status: 200, responseTime: 55 },
  { id: 13, time: '2026-02-08 16:40:45', user: '배**', userId: '20***18', ip: '172.16.0.67', browser: 'Edge 120', url: '/api/files/download', method: 'GET', status: 200, responseTime: 320 },
  { id: 14, time: '2026-02-08 16:40:22', user: '노**', userId: '20***25', ip: '10.0.0.44', browser: 'Chrome 120', url: '/api/notice/list', method: 'GET', status: 200, responseTime: 38 },
  { id: 15, time: '2026-02-08 16:39:58', user: '허**', userId: '20***33', ip: '192.168.1.55', browser: 'Safari 18', url: '/api/attendance/check', method: 'POST', status: 200, responseTime: 72 },
  { id: 16, time: '2026-02-08 16:39:30', user: '유**', userId: '20***41', ip: '10.0.0.99', browser: 'Chrome 120', url: '/api/video/progress', method: 'PUT', status: 200, responseTime: 48 },
  { id: 17, time: '2026-02-08 16:39:05', user: '김**', userId: '20***01', ip: '192.168.1.45', browser: 'Chrome 120', url: '/api/mypage/dashboard', method: 'GET', status: 200, responseTime: 125 },
  { id: 18, time: '2026-02-08 16:38:42', user: 'SYSTEM', userId: '-', ip: '127.0.0.1', browser: '-', url: '/api/cron/sync', method: 'POST', status: 500, responseTime: 5200 },
  { id: 19, time: '2026-02-08 16:38:15', user: '이**', userId: '20***15', ip: '10.0.0.88', browser: 'Safari 18', url: '/api/certificate/list', method: 'GET', status: 200, responseTime: 95 },
  { id: 20, time: '2026-02-08 16:37:50', user: '최**', userId: '20***32', ip: '192.168.1.102', browser: 'Chrome 120', url: '/api/auth/login', method: 'POST', status: 200, responseTime: 280 },
];

/* ───── IP 빈도 Top 10 ───── */
const ipFrequency = [
  { ip: '192.168.1.45', count: 12450, label: '서울강서 강의실' },
  { ip: '10.0.0.88', count: 9820, label: '인천 도서관' },
  { ip: '172.16.0.12', count: 7650, label: '대전 실습실' },
  { ip: '192.168.1.102', count: 6890, label: '서울강서 기숙사' },
  { ip: '10.0.0.55', count: 5430, label: '대전 강의실' },
  { ip: '192.168.2.33', count: 4210, label: '광주 도서관' },
  { ip: '172.16.0.45', count: 3890, label: '부산 실습실' },
  { ip: '10.0.0.22', count: 3120, label: '광주 강의실' },
  { ip: '127.0.0.1', count: 2880, label: 'System (localhost)' },
  { ip: '192.168.1.78', count: 2340, label: '부산 기숙사' },
];

export default function AccessLogPage() {
  const { t } = useTranslation();
  const [startDate, setStartDate] = useState('2026-02-08');
  const [endDate, setEndDate] = useState('2026-02-08');
  const [ipFilter, setIpFilter] = useState('');
  const [browserFilter, setBrowserFilter] = useState('');
  const [urlFilter, setUrlFilter] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  const totalCount = 1245678;
  const pageSize = 20;
  const totalPages = Math.ceil(totalCount / pageSize);

  const maxIpCount = ipFrequency[0].count;

  const statusColor = (code: number) => {
    if (code >= 200 && code < 300) return 'text-green-600 dark:text-green-400';
    if (code >= 400 && code < 500) return 'text-amber-600 dark:text-amber-400';
    if (code >= 500) return 'text-red-600 dark:text-red-400';
    return 'text-gray-600';
  };

  const responseTimeColor = (ms: number) => {
    if (ms < 100) return 'text-green-600 dark:text-green-400';
    if (ms < 500) return 'text-amber-600 dark:text-amber-400';
    return 'text-red-600 dark:text-red-400';
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.accessLogTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{t('admin.accessLogDesc')}</p>
        </div>
        <button className="btn-secondary">
          <Download className="w-4 h-4" /> CSV 내보내기
        </button>
      </div>

      {/* 필터 영역 */}
      <div className="card p-4">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">시작일</label>
            <div className="relative">
              <Calendar className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
              <input
                type="date"
                value={startDate}
                onChange={e => setStartDate(e.target.value)}
                className="pl-8 pr-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          </div>
          <span className="text-gray-400 pb-2">~</span>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">종료일</label>
            <div className="relative">
              <Calendar className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
              <input
                type="date"
                value={endDate}
                onChange={e => setEndDate(e.target.value)}
                className="pl-8 pr-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          </div>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">IP</label>
            <input
              type="text"
              value={ipFilter}
              onChange={e => setIpFilter(e.target.value)}
              placeholder="IP 주소"
              className="px-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 w-32"
            />
          </div>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">브라우저</label>
            <input
              type="text"
              value={browserFilter}
              onChange={e => setBrowserFilter(e.target.value)}
              placeholder="브라우저"
              className="px-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 w-28"
            />
          </div>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">URL 패턴</label>
            <input
              type="text"
              value={urlFilter}
              onChange={e => setUrlFilter(e.target.value)}
              placeholder="/api/..."
              className="px-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 w-36"
            />
          </div>
          <button className="btn-primary py-2">
            <Search className="w-3.5 h-3.5" /> {t('common.search')}
          </button>
        </div>
      </div>

      {/* 로그 테이블 */}
      <section className="card space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
            <Monitor className="w-4 h-4" /> 접속 로그
          </h2>
          <span className="text-xs text-gray-400">
            총 <span className="font-bold text-gray-600 dark:text-slate-300">{totalCount.toLocaleString()}</span>건 중{' '}
            <span className="font-medium">{((currentPage - 1) * pageSize + 1).toLocaleString()}-{Math.min(currentPage * pageSize, totalCount).toLocaleString()}</span>
          </span>
        </div>
        <div className="table-container overflow-x-auto">
          <table className="w-full min-w-[900px]">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">{t('common.date')}</th>
                <th className="table-th">{t('common.user')}</th>
                <th className="table-th">IP</th>
                <th className="table-th">브라우저</th>
                <th className="table-th">요청 URL</th>
                <th className="table-th-center">{t('common.status')}</th>
                <th className="table-th-center">응답시간</th>
              </tr>
            </thead>
            <tbody>
              {mockLogs.map(log => (
                <tr key={log.id} className="table-row">
                  <td className="table-td-center text-[10px] text-gray-400 whitespace-nowrap">{log.time}</td>
                  <td className="table-td text-xs">
                    <div className="font-medium text-gray-700 dark:text-slate-300">{log.user}</div>
                    <div className="text-[10px] text-gray-400">{log.userId}</div>
                  </td>
                  <td className="table-td font-mono text-[10px]">{log.ip}</td>
                  <td className="table-td text-xs text-gray-500">{log.browser}</td>
                  <td className="table-td text-xs">
                    <span className={`inline-block mr-1 px-1 py-0.5 rounded text-[8px] font-bold ${
                      log.method === 'GET' ? 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400' :
                      log.method === 'POST' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400' :
                      'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400'
                    }`}>
                      {log.method}
                    </span>
                    <span className="text-gray-600 dark:text-slate-400 font-mono">{log.url}</span>
                  </td>
                  <td className="table-td-center">
                    <span className={`font-bold text-xs ${statusColor(log.status)}`}>{log.status}</span>
                  </td>
                  <td className="table-td-center">
                    <span className={`text-xs font-medium ${responseTimeColor(log.responseTime)}`}>
                      {log.responseTime}ms
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* 페이지네이션 */}
        <div className="flex items-center justify-between">
          <div className="text-[10px] text-gray-400">
            페이지 {currentPage} / {totalPages.toLocaleString()}
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-30"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            {[1, 2, 3, 4, 5].map(p => (
              <button
                key={p}
                onClick={() => setCurrentPage(p)}
                className={`w-8 h-8 rounded-lg text-xs font-medium ${
                  currentPage === p
                    ? 'bg-primary-500 text-white'
                    : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-slate-700'
                }`}
              >
                {p}
              </button>
            ))}
            <span className="text-gray-400 text-xs px-1">...</span>
            <button
              onClick={() => setCurrentPage(p => p + 1)}
              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-slate-700"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </section>

      {/* IP 빈도 차트 */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
          <Globe className="w-4 h-4" /> IP 접속 빈도 Top 10
        </h2>
        <div className="space-y-2">
          {ipFrequency.map((item, i) => (
            <div key={item.ip} className="flex items-center gap-3">
              <span className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${
                i < 3 ? 'bg-primary-100 text-primary-700 dark:bg-primary-900/40 dark:text-primary-400' : 'bg-gray-100 text-gray-500 dark:bg-slate-700 dark:text-slate-400'
              }`}>
                {i + 1}
              </span>
              <div className="w-28 flex-shrink-0">
                <span className="font-mono text-xs text-gray-700 dark:text-slate-300">{item.ip}</span>
              </div>
              <div className="flex-1">
                <div className="w-full h-2 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                  <div
                    className="h-2 bg-primary-500 rounded-full"
                    style={{ width: `${(item.count / maxIpCount) * 100}%` }}
                  />
                </div>
              </div>
              <span className="text-xs font-medium text-gray-600 dark:text-slate-400 min-w-[60px] text-right">
                {item.count.toLocaleString()}
              </span>
              <span className="text-[10px] text-gray-400 min-w-[80px]">{item.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* 보관 안내 */}
      <div className="flex items-center justify-center gap-2 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
        <Clock className="w-4 h-4 text-amber-600 dark:text-amber-400 flex-shrink-0" />
        <span className="text-xs text-amber-700 dark:text-amber-400">
          접속 로그는 개인정보보호법에 따라 <strong>1년간</strong> 보관 후 자동 삭제됩니다. (현재 보관 기간: 2025-02-08 ~ 2026-02-08)
        </span>
      </div>
    </div>
  );
}
