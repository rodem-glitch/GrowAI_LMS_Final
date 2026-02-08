// pages/admin/log/PrivacyAccessLogPage.tsx — ADM-Y02: 개인정보 열람 로그
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Shield, AlertTriangle, Eye, Lock, Search, Calendar, User, FileText, X, Activity, BarChart3 } from 'lucide-react';

/* ───── 개인정보 열람 로그 (15건, 이상탐지 2건 포함) ───── */
const mockLogs = [
  { id: 1, viewTime: '2026-02-08 16:30:15', viewer: '관리자A (admin01)', target: '김** (20***01)', reason: '수강 이력 확인', fields: ['이름', '학번', '수강이력'], sensitivity: 'normal', ip: '192.168.1.10', isAnomaly: false },
  { id: 2, viewTime: '2026-02-08 16:15:42', viewer: '관리자B (admin02)', target: '이** (20***15)', reason: '상담 목적', fields: ['이름', '연락처', '상담이력'], sensitivity: 'high', ip: '192.168.1.11', isAnomaly: false },
  { id: 3, viewTime: '2026-02-08 15:58:30', viewer: '관리자A (admin01)', target: '다수 (52건)', reason: '-', fields: ['이름', '학번', '연락처', '주소', '성적'], sensitivity: 'critical', ip: '192.168.1.10', isAnomaly: true, anomalyType: '대량 조회' },
  { id: 4, viewTime: '2026-02-08 15:45:18', viewer: '교수C (prof003)', target: '박** (20***23)', reason: '성적 확인', fields: ['이름', '학번', '성적'], sensitivity: 'normal', ip: '10.0.0.55', isAnomaly: false },
  { id: 5, viewTime: '2026-02-08 15:30:05', viewer: '관리자A (admin01)', target: '최** (20***32)', reason: '학적 변동 처리', fields: ['이름', '학번', '주민번호(뒷자리)', '주소'], sensitivity: 'high', ip: '192.168.1.10', isAnomaly: false },
  { id: 6, viewTime: '2026-02-08 14:55:22', viewer: '상담사D (counsel01)', target: '정** (20***48)', reason: '진로 상담 준비', fields: ['이름', '학번', '수강이력', '성적'], sensitivity: 'normal', ip: '192.168.2.33', isAnomaly: false },
  { id: 7, viewTime: '2026-02-08 14:20:11', viewer: '교수E (prof005)', target: '한** (20***12)', reason: '과제 평가', fields: ['이름', '학번'], sensitivity: 'low', ip: '10.0.0.88', isAnomaly: false },
  { id: 8, viewTime: '2026-02-08 13:45:33', viewer: '관리자B (admin02)', target: '다수 (38건)', reason: '-', fields: ['이름', '학번', '연락처', '이메일'], sensitivity: 'critical', ip: '192.168.1.11', isAnomaly: true, anomalyType: '대량 조회' },
  { id: 9, viewTime: '2026-02-08 13:30:48', viewer: '관리자A (admin01)', target: '오** (20***67)', reason: '미접속 학생 확인', fields: ['이름', '학번', '로그인이력'], sensitivity: 'normal', ip: '192.168.1.10', isAnomaly: false },
  { id: 10, viewTime: '2026-02-08 12:15:20', viewer: '교수F (prof006)', target: '강** (20***78)', reason: '출석 확인', fields: ['이름', '학번', '출석현황'], sensitivity: 'low', ip: '10.0.0.22', isAnomaly: false },
  { id: 11, viewTime: '2026-02-08 11:50:07', viewer: '상담사D (counsel01)', target: '윤** (20***89)', reason: '학업 상담', fields: ['이름', '학번', '성적', '상담이력'], sensitivity: 'normal', ip: '192.168.2.33', isAnomaly: false },
  { id: 12, viewTime: '2026-02-08 10:30:45', viewer: '관리자B (admin02)', target: '임** (20***95)', reason: '차단 해제 검토', fields: ['이름', '학번', '로그인이력', '차단사유'], sensitivity: 'high', ip: '192.168.1.11', isAnomaly: false },
  { id: 13, viewTime: '2026-02-08 09:45:12', viewer: '교수C (prof003)', target: '송** (20***02)', reason: '추천서 작성', fields: ['이름', '학번', '수강이력', '성적'], sensitivity: 'normal', ip: '10.0.0.55', isAnomaly: false },
  { id: 14, viewTime: '2026-02-08 09:20:30', viewer: '관리자A (admin01)', target: '배** (20***18)', reason: '장학금 심사', fields: ['이름', '학번', '성적', '소득분위'], sensitivity: 'high', ip: '192.168.1.10', isAnomaly: false },
  { id: 15, viewTime: '2026-02-08 08:55:18', viewer: '상담사G (counsel02)', target: '노** (20***25)', reason: '심리 상담', fields: ['이름', '학번', '상담이력', '심리검사결과'], sensitivity: 'critical', ip: '192.168.2.44', isAnomaly: false },
];

/* ───── 통계 ───── */
const stats = {
  dailyAvg: 42,
  todayCount: 15,
  anomalyCount: 2,
  highSensitivityCount: 4,
};

/* ───── 민감도 레벨 ───── */
const sensitivityConfig: Record<string, { label: string; badge: string; color: string }> = {
  low: { label: '낮음', badge: 'badge-gray', color: 'text-gray-500' },
  normal: { label: '보통', badge: 'badge-info', color: 'text-blue-500' },
  high: { label: '높음', badge: 'badge-warning', color: 'text-amber-500' },
  critical: { label: '매우 높음', badge: 'badge-danger', color: 'text-red-500' },
};

export default function PrivacyAccessLogPage() {
  const { t } = useTranslation();
  const [viewerFilter, setViewerFilter] = useState('');
  const [startDate, setStartDate] = useState('2026-02-08');
  const [endDate, setEndDate] = useState('2026-02-08');
  const [showReasonModal, setShowReasonModal] = useState(false);
  const [reasonInput, setReasonInput] = useState('');
  const [selectedLog, setSelectedLog] = useState<typeof mockLogs[0] | null>(null);
  const [detailLog, setDetailLog] = useState<typeof mockLogs[0] | null>(null);

  const filtered = mockLogs.filter(log => {
    if (viewerFilter && !log.viewer.includes(viewerFilter)) return false;
    return true;
  });

  const handleViewStudent = () => {
    setShowReasonModal(true);
    setReasonInput('');
  };

  const handleReasonSubmit = () => {
    setShowReasonModal(false);
    setReasonInput('');
    // 사유 기록 후 열람 허용 시뮬레이션
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.privacyLogTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{t('admin.privacyLogDesc')}</p>
        </div>
        <button onClick={handleViewStudent} className="btn-secondary">
          <Eye className="w-4 h-4" /> 학생정보 열람
        </button>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/30"><BarChart3 className="w-4 h-4 text-blue-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">{stats.dailyAvg}</div>
          <div className="text-[10px] text-gray-500">일평균 열람건수</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-green-50 dark:bg-green-900/30"><Eye className="w-4 h-4 text-green-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">{stats.todayCount}</div>
          <div className="text-[10px] text-gray-500">금일 열람건수</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-red-50 dark:bg-red-900/30"><AlertTriangle className="w-4 h-4 text-red-600" /></div>
          </div>
          <div className="text-xl font-bold text-red-600 dark:text-red-400">{stats.anomalyCount}</div>
          <div className="text-[10px] text-gray-500">대량조회 발생건수</div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 rounded-lg bg-amber-50 dark:bg-amber-900/30"><Lock className="w-4 h-4 text-amber-600" /></div>
          </div>
          <div className="text-xl font-bold text-gray-900 dark:text-white">{stats.highSensitivityCount}</div>
          <div className="text-[10px] text-gray-500">고민감도 열람</div>
        </div>
      </div>

      {/* 이상탐지 알림 */}
      {mockLogs.filter(l => l.isAnomaly).map(anomaly => (
        <div key={anomaly.id} className="flex items-start gap-3 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-sm font-bold text-red-700 dark:text-red-400">대량 조회 경고</span>
              <span className="badge-sm badge-danger">{(anomaly as any).anomalyType}</span>
            </div>
            <p className="text-xs text-red-600 dark:text-red-400">
              <strong>{anomaly.viewer}</strong>이(가) {anomaly.viewTime}에 <strong>{anomaly.target}</strong>의 개인정보를 일괄 조회하였습니다.
            </p>
            <p className="text-[10px] text-red-500 dark:text-red-400/70 mt-1">
              열람 항목: {anomaly.fields.join(', ')} | IP: {anomaly.ip}
            </p>
          </div>
          <button className="text-xs text-red-600 hover:text-red-700 font-medium whitespace-nowrap">상세 확인</button>
        </div>
      ))}

      {/* 필터 */}
      <div className="card p-4">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">열람자</label>
            <div className="relative">
              <User className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
              <input
                type="text"
                value={viewerFilter}
                onChange={e => setViewerFilter(e.target.value)}
                placeholder="열람자 검색"
                className="pl-8 pr-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 w-40"
              />
            </div>
          </div>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">시작일</label>
            <input
              type="date"
              value={startDate}
              onChange={e => setStartDate(e.target.value)}
              className="px-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
          <span className="text-gray-400 pb-2">~</span>
          <div>
            <label className="block text-[10px] font-medium text-gray-500 dark:text-slate-400 mb-1">종료일</label>
            <input
              type="date"
              value={endDate}
              onChange={e => setEndDate(e.target.value)}
              className="px-3 py-2 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
          <button className="btn-primary py-2">
            <Search className="w-3.5 h-3.5" /> {t('common.search')}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 로그 테이블 */}
        <section className="card space-y-4 lg:col-span-2">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
            <FileText className="w-4 h-4" /> 열람 로그
          </h2>
          <div className="table-container overflow-x-auto">
            <table className="w-full min-w-[800px]">
              <thead className="table-head">
                <tr>
                  <th className="table-th-center">{t('common.date')}</th>
                  <th className="table-th">열람자</th>
                  <th className="table-th">대상자</th>
                  <th className="table-th">열람사유</th>
                  <th className="table-th-center">민감도</th>
                  <th className="table-th">IP</th>
                  <th className="table-th-center">{t('common.detail')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(log => (
                  <tr key={log.id} className={`table-row ${log.isAnomaly ? 'bg-red-50/50 dark:bg-red-900/10' : ''}`}>
                    <td className="table-td-center text-[10px] text-gray-400 whitespace-nowrap">{log.viewTime}</td>
                    <td className="table-td text-xs font-medium">{log.viewer}</td>
                    <td className="table-td text-xs">
                      <div className="flex items-center gap-1">
                        {log.isAnomaly && <AlertTriangle className="w-3 h-3 text-red-500 flex-shrink-0" />}
                        <span className={log.isAnomaly ? 'text-red-600 dark:text-red-400 font-medium' : ''}>{log.target}</span>
                      </div>
                    </td>
                    <td className="table-td text-xs text-gray-500 dark:text-slate-400">{log.reason}</td>
                    <td className="table-td-center">
                      <span className={`badge-sm ${sensitivityConfig[log.sensitivity].badge}`}>
                        {sensitivityConfig[log.sensitivity].label}
                      </span>
                    </td>
                    <td className="table-td font-mono text-[10px]">{log.ip}</td>
                    <td className="table-td-center">
                      <button
                        onClick={() => setDetailLog(log)}
                        className="p-1 text-gray-400 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/30 rounded"
                      >
                        <Eye className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* 상세 패널 */}
        <section className="card space-y-4">
          {detailLog ? (
            <>
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">열람 상세</h2>
                <button onClick={() => setDetailLog(null)} className="text-gray-400 hover:text-gray-600">
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* 기본 정보 */}
              <div className="p-3 bg-surface-muted dark:bg-slate-800 rounded-lg space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-gray-700 dark:text-slate-300">{detailLog.viewer}</span>
                  {detailLog.isAnomaly && <span className="badge-sm badge-danger">이상탐지</span>}
                </div>
                <div className="grid grid-cols-1 gap-1.5 text-[10px] text-gray-500">
                  <div className="flex justify-between"><span>열람일시</span><span className="text-gray-700 dark:text-slate-300">{detailLog.viewTime}</span></div>
                  <div className="flex justify-between"><span>대상자</span><span className="text-gray-700 dark:text-slate-300">{detailLog.target}</span></div>
                  <div className="flex justify-between"><span>IP 주소</span><span className="font-mono text-gray-700 dark:text-slate-300">{detailLog.ip}</span></div>
                  <div className="flex justify-between"><span>열람사유</span><span className="text-gray-700 dark:text-slate-300">{detailLog.reason}</span></div>
                </div>
              </div>

              {/* 조회 항목 (민감도별) */}
              <div>
                <h3 className="text-xs font-semibold text-gray-700 dark:text-slate-300 mb-2">조회 항목 및 민감도</h3>
                <div className="space-y-1.5">
                  {detailLog.fields.map(field => {
                    const fieldSensitivity = (() => {
                      if (['주민번호(뒷자리)', '소득분위', '심리검사결과'].includes(field)) return 'critical';
                      if (['연락처', '주소', '이메일', '상담이력', '차단사유'].includes(field)) return 'high';
                      if (['성적', '수강이력', '로그인이력', '출석현황'].includes(field)) return 'normal';
                      return 'low';
                    })();
                    const config = sensitivityConfig[fieldSensitivity];
                    return (
                      <div key={field} className="flex items-center justify-between p-2 bg-surface-muted dark:bg-slate-800 rounded-lg">
                        <div className="flex items-center gap-2">
                          <Lock className={`w-3 h-3 ${config.color}`} />
                          <span className="text-xs text-gray-700 dark:text-slate-300">{field}</span>
                        </div>
                        <span className={`badge-sm ${config.badge}`}>{config.label}</span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* 전체 민감도 레벨 */}
              <div className={`p-3 rounded-lg border ${
                detailLog.sensitivity === 'critical' ? 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-800' :
                detailLog.sensitivity === 'high' ? 'bg-amber-50 border-amber-200 dark:bg-amber-900/20 dark:border-amber-800' :
                'bg-blue-50 border-blue-200 dark:bg-blue-900/20 dark:border-blue-800'
              }`}>
                <div className="flex items-center gap-2">
                  <Shield className={`w-4 h-4 ${sensitivityConfig[detailLog.sensitivity].color}`} />
                  <span className="text-xs font-medium">
                    전체 민감도: <strong>{sensitivityConfig[detailLog.sensitivity].label}</strong>
                  </span>
                </div>
              </div>
            </>
          ) : (
            <div className="flex flex-col items-center justify-center py-16 text-gray-400">
              <Shield className="w-10 h-10 mb-3 opacity-30" />
              <p className="text-sm">로그를 선택하면</p>
              <p className="text-sm">상세 정보가 표시됩니다</p>
            </div>
          )}
        </section>
      </div>

      {/* 열람 사유 입력 모달 */}
      {showReasonModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 rounded-full bg-blue-100 dark:bg-blue-900/40">
                <Eye className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">개인정보 열람 사유 입력</h3>
                <p className="text-[10px] text-gray-500">학생 개인정보를 열람하기 위해 사유를 입력해야 합니다.</p>
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                열람 사유 <span className="text-red-500">*</span>
              </label>
              <textarea
                value={reasonInput}
                onChange={e => setReasonInput(e.target.value)}
                placeholder="구체적인 열람 사유를 입력해주세요. (예: 장학금 심사를 위한 성적 확인)"
                className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white resize-none h-28 focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <div className="flex items-start gap-2 text-[10px] text-amber-600 dark:text-amber-400 mb-4 p-2 bg-amber-50 dark:bg-amber-900/20 rounded-lg">
              <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-medium">개인정보 열람 안내</p>
                <p className="mt-0.5 text-amber-500">모든 열람 행위는 감사 로그에 기록되며, 업무 목적 외 열람 시 개인정보보호법에 의해 처벌될 수 있습니다.</p>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => { setShowReasonModal(false); setReasonInput(''); }}
                className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600"
              >
                {t('common.cancel')}
              </button>
              <button
                onClick={handleReasonSubmit}
                disabled={!reasonInput.trim() || reasonInput.trim().length < 5}
                className="flex-1 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {t('common.confirm')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
