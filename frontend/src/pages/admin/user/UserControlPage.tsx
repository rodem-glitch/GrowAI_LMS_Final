// pages/admin/user/UserControlPage.tsx — ADM-M01: 사용자 조회/제어
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Search, Shield, ShieldOff, LogOut, X, Users, Clock, Bot, MessageSquare, AlertTriangle, Eye, ChevronRight } from 'lucide-react';

/* ───── 사용자 목록 (15명) ───── */
const mockUsers = [
  { id: 1, name: '김민수', maskedName: '김**', studentId: '2024001', maskedId: '20***01', campus: '서울강서', department: '소프트웨어공학과', status: 'active', lastLogin: '2026-02-08 16:30', activity: '수강중' },
  { id: 2, name: '이수진', maskedName: '이**', studentId: '2024015', maskedId: '20***15', campus: '서울강서', department: '인공지능학과', status: 'active', lastLogin: '2026-02-08 16:25', activity: 'AI 챗봇 이용' },
  { id: 3, name: '박영호', maskedName: '박**', studentId: '2024023', maskedId: '20***23', campus: '인천', department: '데이터사이언스학과', status: 'blocked', lastLogin: '2026-02-05 09:10', activity: '차단됨' },
  { id: 4, name: '최지은', maskedName: '최**', studentId: '2024032', maskedId: '20***32', campus: '인천', department: '정보보안학과', status: 'active', lastLogin: '2026-02-08 15:45', activity: '과제 제출' },
  { id: 5, name: '정우성', maskedName: '정**', studentId: '2024048', maskedId: '20***48', campus: '대전', department: '전자공학과', status: 'active', lastLogin: '2026-02-08 14:20', activity: '시험 응시' },
  { id: 6, name: '한예슬', maskedName: '한**', studentId: '2023112', maskedId: '20***12', campus: '대전', department: '디지털미디어학과', status: 'active', lastLogin: '2026-02-08 13:55', activity: '수강중' },
  { id: 7, name: '오세훈', maskedName: '오**', studentId: '2024067', maskedId: '20***67', campus: '광주', department: '소프트웨어공학과', status: 'inactive', lastLogin: '2026-01-15 10:30', activity: '미접속 (24일)' },
  { id: 8, name: '강민정', maskedName: '강**', studentId: '2024078', maskedId: '20***78', campus: '광주', department: '경영학과', status: 'active', lastLogin: '2026-02-08 12:10', activity: '게시판 글 작성' },
  { id: 9, name: '윤서준', maskedName: '윤**', studentId: '2024089', maskedId: '20***89', campus: '부산', department: '인공지능학과', status: 'active', lastLogin: '2026-02-08 11:35', activity: 'AI 학습 추천' },
  { id: 10, name: '임하은', maskedName: '임**', studentId: '2023095', maskedId: '20***95', campus: '부산', department: '데이터사이언스학과', status: 'blocked', lastLogin: '2026-02-01 08:22', activity: '차단됨' },
  { id: 11, name: '송태희', maskedName: '송**', studentId: '2024102', maskedId: '20***02', campus: '서울강서', department: '기계공학과', status: 'active', lastLogin: '2026-02-08 10:15', activity: '수강중' },
  { id: 12, name: '배준호', maskedName: '배**', studentId: '2024118', maskedId: '20***18', campus: '인천', department: '소프트웨어공학과', status: 'active', lastLogin: '2026-02-08 09:50', activity: '자료 다운로드' },
  { id: 13, name: '노현진', maskedName: '노**', studentId: '2024125', maskedId: '20***25', campus: '대전', department: '정보보안학과', status: 'inactive', lastLogin: '2026-01-28 16:40', activity: '미접속 (11일)' },
  { id: 14, name: '허재민', maskedName: '허**', studentId: '2024133', maskedId: '20***33', campus: '광주', department: '인공지능학과', status: 'active', lastLogin: '2026-02-08 08:30', activity: '출석 체크' },
  { id: 15, name: '유다은', maskedName: '유**', studentId: '2024141', maskedId: '20***41', campus: '부산', department: '디지털미디어학과', status: 'active', lastLogin: '2026-02-07 22:15', activity: '영상 시청' },
];

/* ───── 상세 이력 데이터 ───── */
const loginHistory = [
  { time: '2026-02-08 16:30:12', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
  { time: '2026-02-08 08:15:33', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
  { time: '2026-02-07 19:22:41', ip: '10.0.0.88', browser: 'Safari 18', result: '성공' },
  { time: '2026-02-07 08:05:18', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
  { time: '2026-02-06 14:30:55', ip: '192.168.1.45', browser: 'Chrome 120', result: '실패 (비밀번호 오류)' },
  { time: '2026-02-06 14:31:12', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
  { time: '2026-02-05 09:10:22', ip: '172.16.0.12', browser: 'Firefox 122', result: '성공' },
  { time: '2026-02-04 20:45:08', ip: '10.0.0.88', browser: 'Safari 18', result: '성공' },
  { time: '2026-02-03 11:20:33', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
  { time: '2026-02-02 15:55:47', ip: '192.168.1.45', browser: 'Chrome 120', result: '성공' },
];

const counselHistory = [
  { date: '2026-02-05', counselor: '이상담', type: '학업상담', summary: '수학 기초 보충 필요, 튜터링 연결' },
  { date: '2026-01-22', counselor: '김지도', type: '진로상담', summary: 'AI 분야 관심, 관련 자격증 안내' },
  { date: '2025-12-15', counselor: '이상담', type: '학업상담', summary: '중간고사 성적 우수, 격려' },
];

const aiHistory = [
  { date: '2026-02-08 16:15', agent: 'AI 학습 도우미', action: 'Python 자료구조 질문', tokens: 1250 },
  { date: '2026-02-08 14:30', agent: 'AI 과제 피드백', action: '과제 코드 리뷰 요청', tokens: 2100 },
  { date: '2026-02-07 19:10', agent: 'AI 학습 추천', action: '다음 학습 추천 요청', tokens: 850 },
  { date: '2026-02-06 15:45', agent: 'AI 면접 연습', action: '모의 면접 세션', tokens: 3500 },
  { date: '2026-02-05 10:20', agent: 'AI 학습 도우미', action: 'SQL 쿼리 질문', tokens: 980 },
];

type ModalType = 'forceLogout' | 'block' | 'unblock' | null;

export default function UserControlPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [selectedUser, setSelectedUser] = useState<typeof mockUsers[0] | null>(null);
  const [modal, setModal] = useState<ModalType>(null);
  const [reason, setReason] = useState('');
  const [detailTab, setDetailTab] = useState<'login' | 'counsel' | 'ai'>('login');

  const filtered = mockUsers.filter(u =>
    u.maskedName.includes(search) || u.maskedId.includes(search) || u.studentId.includes(search) || u.name.includes(search)
  );

  const statusBadge = (status: string) => {
    switch (status) {
      case 'active': return <span className="badge-sm badge-success">활성</span>;
      case 'blocked': return <span className="badge-sm badge-danger">차단</span>;
      case 'inactive': return <span className="badge-sm badge-warning">미접속</span>;
      default: return <span className="badge-sm badge-gray">{status}</span>;
    }
  };

  const handleAction = () => {
    // 모의 액션 수행
    setModal(null);
    setReason('');
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.userControlTitle')}</h1>
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <Users className="w-4 h-4" />
          <span>총 {mockUsers.length}명</span>
          <span className="text-green-500 font-medium">(활성 {mockUsers.filter(u => u.status === 'active').length})</span>
          <span className="text-red-500 font-medium">(차단 {mockUsers.filter(u => u.status === 'blocked').length})</span>
        </div>
      </div>

      {/* 검색 */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder={t('common.searchPlaceholder')}
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="input-with-icon"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 사용자 테이블 */}
        <section className="card space-y-4 lg:col-span-2">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">사용자 목록</h2>
          <div className="table-container max-h-[600px] overflow-y-auto">
            <table className="w-full">
              <thead className="table-head sticky top-0">
                <tr>
                  <th className="table-th">{t('common.name')}</th>
                  <th className="table-th">학번</th>
                  <th className="table-th-center">캠퍼스</th>
                  <th className="table-th-center">{t('common.status')}</th>
                  <th className="table-th-center">최근 로그인</th>
                  <th className="table-th">활동</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(u => (
                  <tr
                    key={u.id}
                    className={`table-row cursor-pointer ${selectedUser?.id === u.id ? 'bg-primary-50 dark:bg-primary-900/20' : ''}`}
                    onClick={() => { setSelectedUser(u); setDetailTab('login'); }}
                  >
                    <td className="table-td font-medium flex items-center gap-2">
                      <Eye className="w-3 h-3 text-gray-400" />
                      {u.maskedName}
                    </td>
                    <td className="table-td font-mono text-xs">{u.maskedId}</td>
                    <td className="table-td-center text-xs">{u.campus}</td>
                    <td className="table-td-center">{statusBadge(u.status)}</td>
                    <td className="table-td-center text-[10px] text-gray-400">{u.lastLogin}</td>
                    <td className="table-td text-xs text-gray-500 dark:text-slate-400">{u.activity}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 && (
            <div className="text-center py-8 text-gray-400 text-sm">{t('common.noData')}</div>
          )}
        </section>

        {/* 상세 패널 */}
        <section className="card space-y-4">
          {selectedUser ? (
            <>
              {/* 사용자 정보 헤더 */}
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">사용자 상세</h2>
                <button onClick={() => setSelectedUser(null)} className="text-gray-400 hover:text-gray-600">
                  <X className="w-4 h-4" />
                </button>
              </div>
              <div className="p-3 bg-surface-muted dark:bg-slate-800 rounded-lg space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-gray-900 dark:text-white">{selectedUser.maskedName}</span>
                  {statusBadge(selectedUser.status)}
                </div>
                <div className="grid grid-cols-2 gap-1 text-[10px] text-gray-500">
                  <span>학번: {selectedUser.maskedId}</span>
                  <span>캠퍼스: {selectedUser.campus}</span>
                  <span>학과: {selectedUser.department}</span>
                  <span>최근: {selectedUser.lastLogin}</span>
                </div>
              </div>

              {/* 액션 버튼 */}
              <div className="flex gap-2">
                <button
                  onClick={() => setModal('forceLogout')}
                  className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-xs font-medium bg-amber-50 text-amber-700 rounded-lg hover:bg-amber-100 dark:bg-amber-900/30 dark:text-amber-400 dark:hover:bg-amber-900/50"
                >
                  <LogOut className="w-3 h-3" /> 강제 로그아웃
                </button>
                {selectedUser.status === 'blocked' ? (
                  <button
                    onClick={() => setModal('unblock')}
                    className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-xs font-medium bg-green-50 text-green-700 rounded-lg hover:bg-green-100 dark:bg-green-900/30 dark:text-green-400 dark:hover:bg-green-900/50"
                  >
                    <ShieldOff className="w-3 h-3" /> 차단 해제
                  </button>
                ) : (
                  <button
                    onClick={() => setModal('block')}
                    className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-xs font-medium bg-red-50 text-red-700 rounded-lg hover:bg-red-100 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50"
                  >
                    <Shield className="w-3 h-3" /> 차단
                  </button>
                )}
              </div>

              {/* 이력 탭 */}
              <div className="flex gap-1 border-b border-gray-200 dark:border-slate-700">
                {[
                  { key: 'login' as const, label: '로그인 이력', icon: Clock },
                  { key: 'counsel' as const, label: '상담 이력', icon: MessageSquare },
                  { key: 'ai' as const, label: 'AI 활용', icon: Bot },
                ].map(tab => (
                  <button
                    key={tab.key}
                    onClick={() => setDetailTab(tab.key)}
                    className={`flex items-center gap-1 px-3 py-2 text-[10px] font-medium border-b-2 transition-colors ${
                      detailTab === tab.key
                        ? 'border-primary-500 text-primary-600 dark:text-primary-400'
                        : 'border-transparent text-gray-400 hover:text-gray-600'
                    }`}
                  >
                    <tab.icon className="w-3 h-3" /> {tab.label}
                  </button>
                ))}
              </div>

              {/* 탭 내용 */}
              <div className="max-h-[300px] overflow-y-auto space-y-2">
                {detailTab === 'login' && loginHistory.map((log, i) => (
                  <div key={i} className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-[10px]">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-gray-500">{log.time}</span>
                      <span className={`font-medium ${log.result === '성공' ? 'text-green-600' : 'text-red-500'}`}>{log.result}</span>
                    </div>
                    <div className="text-gray-400">IP: {log.ip} | {log.browser}</div>
                  </div>
                ))}
                {detailTab === 'counsel' && counselHistory.map((c, i) => (
                  <div key={i} className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-[10px]">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-medium text-gray-700 dark:text-slate-300">{c.type}</span>
                      <span className="text-gray-400">{c.date}</span>
                    </div>
                    <div className="text-gray-500">상담사: {c.counselor}</div>
                    <div className="text-gray-600 dark:text-slate-400 mt-1">{c.summary}</div>
                  </div>
                ))}
                {detailTab === 'ai' && aiHistory.map((a, i) => (
                  <div key={i} className="p-2 bg-surface-muted dark:bg-slate-800 rounded-lg text-[10px]">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-medium text-gray-700 dark:text-slate-300">{a.agent}</span>
                      <span className="text-gray-400">{a.date}</span>
                    </div>
                    <div className="text-gray-500">{a.action}</div>
                    <div className="text-gray-400 mt-1">토큰: {a.tokens.toLocaleString()}</div>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="flex flex-col items-center justify-center py-16 text-gray-400">
              <Users className="w-10 h-10 mb-3 opacity-30" />
              <p className="text-sm">사용자를 선택하면</p>
              <p className="text-sm">상세 정보가 표시됩니다</p>
            </div>
          )}
        </section>
      </div>

      {/* 확인 모달 */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center gap-3 mb-4">
              <div className={`p-2 rounded-full ${
                modal === 'block' ? 'bg-red-100 dark:bg-red-900/40' :
                modal === 'unblock' ? 'bg-green-100 dark:bg-green-900/40' :
                'bg-amber-100 dark:bg-amber-900/40'
              }`}>
                {modal === 'block' ? <Shield className="w-5 h-5 text-red-600" /> :
                 modal === 'unblock' ? <ShieldOff className="w-5 h-5 text-green-600" /> :
                 <LogOut className="w-5 h-5 text-amber-600" />}
              </div>
              <div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {modal === 'forceLogout' && '강제 로그아웃'}
                  {modal === 'block' && '사용자 차단'}
                  {modal === 'unblock' && '차단 해제'}
                </h3>
                <p className="text-[10px] text-gray-500">
                  대상: {selectedUser?.maskedName} ({selectedUser?.maskedId})
                </p>
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">
                사유 입력 <span className="text-red-500">*</span>
              </label>
              <textarea
                value={reason}
                onChange={e => setReason(e.target.value)}
                placeholder="사유를 입력해주세요..."
                className="w-full p-3 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white resize-none h-24 focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <div className="flex items-center gap-2 text-[10px] text-amber-600 dark:text-amber-400 mb-4">
              <AlertTriangle className="w-3 h-3" />
              <span>이 작업은 감사 로그에 기록됩니다.</span>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => { setModal(null); setReason(''); }}
                className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600"
              >
                {t('common.cancel')}
              </button>
              <button
                onClick={handleAction}
                disabled={!reason.trim()}
                className={`flex-1 px-4 py-2 text-sm font-medium text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed ${
                  modal === 'block' ? 'bg-red-600 hover:bg-red-700' :
                  modal === 'unblock' ? 'bg-green-600 hover:bg-green-700' :
                  'bg-amber-600 hover:bg-amber-700'
                }`}
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
