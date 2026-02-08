// pages/haksa/EnrollmentPage.tsx -- 수강 신청 연동
import { useState } from 'react';
import { RefreshCw, CheckCircle, Clock, AlertCircle } from 'lucide-react';
import { useTranslation } from '@/i18n';

const enrollments = [
  { no: 1, studentId: '20210001', name: '김민수', courseCode: 'CS301', courseName: '데이터베이스', section: 'A반', status: '연동완료', syncedAt: '2026-02-08 10:30:00' },
  { no: 2, studentId: '20210045', name: '이서연', courseCode: 'EE201', courseName: '회로이론', section: 'B반', status: '대기', syncedAt: '-' },
  { no: 3, studentId: '20200112', name: '박지훈', courseCode: 'ME301', courseName: '열역학', section: 'A반', status: '연동완료', syncedAt: '2026-02-08 10:30:00' },
  { no: 4, studentId: '20220078', name: '최예은', courseCode: 'CS201', courseName: '자료구조', section: 'C반', status: '오류', syncedAt: '2026-02-08 10:28:00' },
  { no: 5, studentId: '20190034', name: '정우진', courseCode: 'CS401', courseName: '소프트웨어공학', section: 'A반', status: '연동완료', syncedAt: '2026-02-08 10:30:00' },
];

const statusConfig: Record<string, { color: string; icon: typeof CheckCircle }> = {
  '연동완료': { color: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400', icon: CheckCircle },
  '대기': { color: 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400', icon: Clock },
  '오류': { color: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400', icon: AlertCircle },
};

export default function EnrollmentPage() {
  const { t } = useTranslation();
  const [syncing, setSyncing] = useState(false);
  const [lastSync, setLastSync] = useState('2026-02-08 10:30:00');
  const [toast, setToast] = useState('');

  const handleSync = () => {
    setSyncing(true);
    setTimeout(() => {
      setSyncing(false);
      const now = new Date().toLocaleString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' });
      setLastSync(now);
      setToast('동기화가 완료되었습니다.');
      setTimeout(() => setToast(''), 2500);
    }, 1500);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.enrollmentTitle')}</h1>
          <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.enrollmentDesc')}</p>
        </div>
        <button
          onClick={handleSync}
          disabled={syncing}
          className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white text-sm font-medium rounded-lg hover:bg-primary-700 transition-colors disabled:opacity-60"
        >
          <RefreshCw className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
          {syncing ? '동기화 중...' : '동기화 실행'}
        </button>
      </div>

      {/* 마지막 동기화 정보 */}
      <div className="card p-4">
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-slate-400">
          <Clock className="w-4 h-4" />
          <span>마지막 동기화: <strong className="text-gray-900 dark:text-white">{lastSync}</strong></span>
        </div>
      </div>

      {/* 수강 신청 테이블 */}
      <section className="card space-y-4">
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th-center">No</th>
                <th className="table-th">학번</th>
                <th className="table-th">이름</th>
                <th className="table-th">과목코드</th>
                <th className="table-th">과목명</th>
                <th className="table-th-center">분반</th>
                <th className="table-th-center">연동상태</th>
                <th className="table-th-center">연동일시</th>
              </tr>
            </thead>
            <tbody>
              {enrollments.map((e) => {
                const config = statusConfig[e.status];
                const StatusIcon = config.icon;
                return (
                  <tr key={e.no} className="table-row">
                    <td className="table-td-center">{e.no}</td>
                    <td className="table-td font-medium text-primary-600 dark:text-primary-400">{e.studentId}</td>
                    <td className="table-td font-medium">{e.name}</td>
                    <td className="table-td">{e.courseCode}</td>
                    <td className="table-td">{e.courseName}</td>
                    <td className="table-td-center">{e.section}</td>
                    <td className="table-td-center">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
                        <StatusIcon className="w-3 h-3" />
                        {e.status}
                      </span>
                    </td>
                    <td className="table-td-center text-[10px]">{e.syncedAt}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      {/* 토스트 */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-green-600 text-white px-5 py-3 rounded-xl shadow-lg">
          <CheckCircle className="w-5 h-5" />
          <span className="text-sm font-medium">{toast}</span>
        </div>
      )}
    </div>
  );
}
