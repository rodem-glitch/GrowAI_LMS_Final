// pages/haksa/DashboardPage.tsx -- 학사정보 연동 대시보드
import { Users, BookOpen, RefreshCw, AlertTriangle, CheckCircle, Database, Server } from 'lucide-react';
import { useTranslation } from '@/i18n';

const recentHistory = [
  { no: 1, type: '학적 데이터 전체 동기화', status: '성공', count: '1,532', duration: '2분 34초', startedAt: '2026-02-08 10:30:00' },
  { no: 2, type: '성적 데이터 증분 동기화', status: '부분실패', count: '856', duration: '1분 12초', startedAt: '2026-02-08 09:00:00' },
  { no: 3, type: '수강신청 데이터 동기화', status: '성공', count: '2,104', duration: '3분 05초', startedAt: '2026-02-07 18:00:00' },
];

const systems = [
  { name: '학적 시스템', status: '정상', statusColor: 'text-success-600', dotColor: 'bg-success-500', lastSync: '2026-02-08 10:30', icon: Database },
  { name: '성적 시스템', status: '정상', statusColor: 'text-success-600', dotColor: 'bg-success-500', lastSync: '2026-02-08 09:00', icon: Server },
  { name: '수강신청 시스템', status: '점검중', statusColor: 'text-amber-600', dotColor: 'bg-amber-500', lastSync: '2026-02-07 18:00', icon: Server },
];

export default function DashboardPage() {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.dashboardTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.dashboardDesc')}</p>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/30">
              <Users className="w-4 h-4 text-blue-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">3,256명</div>
          <div className="text-[10px] text-gray-500 mt-0.5">전체 학생 수</div>
        </div>

        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-green-50 dark:bg-green-900/30">
              <BookOpen className="w-4 h-4 text-green-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">128개</div>
          <div className="text-[10px] text-gray-500 mt-0.5">금학기 개설 과목</div>
        </div>

        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-amber-50 dark:bg-amber-900/30">
              <RefreshCw className="w-4 h-4 text-amber-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">2시간 전</div>
          <div className="text-[10px] text-gray-500 mt-0.5">최근 동기화</div>
        </div>

        <div className="card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 rounded-lg bg-red-50 dark:bg-red-900/30">
              <AlertTriangle className="w-4 h-4 text-red-600" />
            </div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">3건</div>
          <div className="text-[10px] text-gray-500 mt-0.5">연동 오류</div>
        </div>
      </div>

      {/* 최근 연동 이력 */}
      <section className="card space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">최근 연동 이력</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">No</th>
                <th className="table-th">연동 유형</th>
                <th className="table-th-center">상태</th>
                <th className="table-th-center">처리 건수</th>
                <th className="table-th-center">소요시간</th>
                <th className="table-th-center">시작일시</th>
              </tr>
            </thead>
            <tbody>
              {recentHistory.map((row) => (
                <tr key={row.no} className="table-row">
                  <td className="table-td-center">{row.no}</td>
                  <td className="table-td font-medium">{row.type}</td>
                  <td className="table-td-center">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                      row.status === '성공'
                        ? 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                        : 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
                    }`}>
                      {row.status === '성공' && <CheckCircle className="w-3 h-3" />}
                      {row.status === '부분실패' && <AlertTriangle className="w-3 h-3" />}
                      {row.status}
                    </span>
                  </td>
                  <td className="table-td-center">{row.count}</td>
                  <td className="table-td-center text-[10px]">{row.duration}</td>
                  <td className="table-td-center text-[10px]">{row.startedAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* 시스템 연동 현황 */}
      <section className="space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">시스템 연동 현황</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {systems.map((sys) => (
            <div key={sys.name} className="card p-4 space-y-3">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gray-50 dark:bg-slate-800">
                  <sys.icon className="w-5 h-5 text-gray-600 dark:text-slate-400" />
                </div>
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white">{sys.name}</h3>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500 dark:text-slate-400">연동 상태</span>
                  <span className={`flex items-center gap-1.5 text-xs font-medium ${sys.statusColor}`}>
                    <span className={`w-2 h-2 rounded-full ${sys.dotColor}`} />
                    {sys.status}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500 dark:text-slate-400">마지막 동기화</span>
                  <span className="text-xs text-gray-700 dark:text-slate-300">{sys.lastSync}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
