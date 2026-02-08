// pages/student/profile/StudentProfilePage.tsx — STD-001: 학적 정보 동기화
import { useState } from 'react';
import {
  User, GraduationCap, Building2, Calendar, RefreshCw, CheckCircle2,
  BookOpen, Award, Clock, MapPin, Hash, TrendingUp,
} from 'lucide-react';
import StatCard from '@/components/common/StatCard';
import ProgressBar from '@/components/common/ProgressBar';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
const mockProfile = {
  name: '김민수',
  studentId: '2023010042',
  campus: '서울강서캠퍼스',
  department: '컴퓨터공학과',
  grade: 3,
  semester: 1,
  admissionYear: 2023,
  status: '재학',
  email: 'minsu.kim@kopo.ac.kr',
  phone: '010-1234-5678',
  advisor: '이진호 교수',
};

const mockAcademic = {
  gpa: 3.72,
  maxGpa: 4.5,
  totalCredits: 96,
  requiredCredits: 140,
  majorCredits: 68,
  requiredMajorCredits: 84,
  generalCredits: 28,
  requiredGeneralCredits: 42,
  practicalCredits: 0,
  requiredPracticalCredits: 14,
  rank: 8,
  totalStudents: 42,
};

const semesterGrades = [
  { semester: '2023-1', gpa: 3.5, credits: 18 },
  { semester: '2023-2', gpa: 3.6, credits: 18 },
  { semester: '2024-1', gpa: 3.8, credits: 21 },
  { semester: '2024-2', gpa: 3.9, credits: 21 },
  { semester: '2025-1', gpa: 3.7, credits: 18 },
];

export default function StudentProfilePage() {
  const { t } = useTranslation();
  const [syncing, setSyncing] = useState(false);
  const [lastSync, setLastSync] = useState('2026-02-08 09:30:15');
  const [syncSuccess, setSyncSuccess] = useState(false);

  // 학사 API 동기화 시뮬레이션
  const handleSync = () => {
    setSyncing(true);
    setSyncSuccess(false);
    setTimeout(() => {
      setSyncing(false);
      setSyncSuccess(true);
      setLastSync(new Date().toLocaleString('ko-KR', {
        year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', second: '2-digit',
      }));
      setTimeout(() => setSyncSuccess(false), 3000);
    }, 2000);
  };

  const creditPercent = Math.round((mockAcademic.totalCredits / mockAcademic.requiredCredits) * 100);
  const majorPercent = Math.round((mockAcademic.majorCredits / mockAcademic.requiredMajorCredits) * 100);
  const generalPercent = Math.round((mockAcademic.generalCredits / mockAcademic.requiredGeneralCredits) * 100);
  const practicalPercent = Math.round((mockAcademic.practicalCredits / mockAcademic.requiredPracticalCredits) * 100);

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.profileTitle')}</h1>
        <div className="flex items-center gap-3">
          <span className="text-[10px] text-gray-400 flex items-center gap-1">
            <Clock className="w-3 h-3" />
            마지막 동기화: {lastSync}
          </span>
          <button
            onClick={handleSync}
            disabled={syncing}
            className="btn-primary text-xs flex items-center gap-1.5"
          >
            {syncing ? (
              <RefreshCw className="w-3.5 h-3.5 animate-spin" />
            ) : syncSuccess ? (
              <CheckCircle2 className="w-3.5 h-3.5" />
            ) : (
              <RefreshCw className="w-3.5 h-3.5" />
            )}
            {syncing ? '동기화 중...' : syncSuccess ? '완료!' : '정보 업데이트'}
          </button>
        </div>
      </div>

      {/* 프로필 카드 */}
      <div className="card p-5">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center shrink-0">
            <span className="text-2xl font-bold text-primary-600">{mockProfile.name[0]}</span>
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{mockProfile.name}</h2>
              <span className="badge-sm badge-success">{mockProfile.status}</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-y-1.5 gap-x-6 text-xs text-gray-500 dark:text-slate-400">
              <span className="flex items-center gap-1.5"><Hash className="w-3 h-3 text-gray-400" />{mockProfile.studentId}</span>
              <span className="flex items-center gap-1.5"><Building2 className="w-3 h-3 text-gray-400" />{mockProfile.campus}</span>
              <span className="flex items-center gap-1.5"><GraduationCap className="w-3 h-3 text-gray-400" />{mockProfile.department}</span>
              <span className="flex items-center gap-1.5"><Calendar className="w-3 h-3 text-gray-400" />{mockProfile.admissionYear}년 입학 / {mockProfile.grade}학년</span>
              <span className="flex items-center gap-1.5"><User className="w-3 h-3 text-gray-400" />지도교수: {mockProfile.advisor}</span>
              <span className="flex items-center gap-1.5"><MapPin className="w-3 h-3 text-gray-400" />{mockProfile.email}</span>
            </div>
          </div>
        </div>
      </div>

      {/* 통계 카드 */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={TrendingUp} label="평점 (GPA)" value={`${mockAcademic.gpa} / ${mockAcademic.maxGpa}`} />
        <StatCard icon={BookOpen} label="이수 학점" value={`${mockAcademic.totalCredits}`} change={`/ ${mockAcademic.requiredCredits}`} />
        <StatCard icon={Award} label="학과 석차" value={`${mockAcademic.rank}등`} change={`/ ${mockAcademic.totalStudents}명`} />
        <StatCard icon={GraduationCap} label="졸업 이수율" value={`${creditPercent}%`} change="+3%" trend="up" />
      </div>

      {/* 학점 이수 현황 + 학기별 성적 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 학점 이수 현황 */}
        <div className="card p-5 space-y-5">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">학점 이수 현황</h2>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-gray-600 dark:text-slate-400">전체 학점</span>
                <span className="font-medium text-gray-900 dark:text-white">{mockAcademic.totalCredits} / {mockAcademic.requiredCredits}</span>
              </div>
              <ProgressBar value={creditPercent} size="md" />
            </div>
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-gray-600 dark:text-slate-400">전공 학점</span>
                <span className="font-medium text-gray-900 dark:text-white">{mockAcademic.majorCredits} / {mockAcademic.requiredMajorCredits}</span>
              </div>
              <ProgressBar value={majorPercent} size="md" />
            </div>
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-gray-600 dark:text-slate-400">교양 학점</span>
                <span className="font-medium text-gray-900 dark:text-white">{mockAcademic.generalCredits} / {mockAcademic.requiredGeneralCredits}</span>
              </div>
              <ProgressBar value={generalPercent} size="md" />
            </div>
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-gray-600 dark:text-slate-400">현장실습 학점</span>
                <span className="font-medium text-gray-900 dark:text-white">{mockAcademic.practicalCredits} / {mockAcademic.requiredPracticalCredits}</span>
              </div>
              <ProgressBar value={practicalPercent} size="md" />
            </div>
          </div>
        </div>

        {/* 학기별 성적 추이 */}
        <div className="card p-5 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">학기별 성적 추이</h2>
          <div className="table-container">
            <table className="w-full">
              <thead className="table-head">
                <tr>
                  <th className="table-th">학기</th>
                  <th className="table-th-center">학점</th>
                  <th className="table-th-center">평점</th>
                  <th className="table-th-center">그래프</th>
                </tr>
              </thead>
              <tbody>
                {semesterGrades.map((s) => (
                  <tr key={s.semester} className="table-row">
                    <td className="table-td font-medium">{s.semester}</td>
                    <td className="table-td-center">{s.credits}</td>
                    <td className="table-td-center">
                      <span className={`font-semibold ${s.gpa >= 3.8 ? 'text-success-600' : s.gpa >= 3.5 ? 'text-primary-600' : 'text-warning-600'}`}>
                        {s.gpa.toFixed(1)}
                      </span>
                    </td>
                    <td className="table-td-center">
                      <div className="w-full h-2 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                        <div
                          className="h-2 bg-primary-500 rounded-full transition-all"
                          style={{ width: `${(s.gpa / 4.5) * 100}%` }}
                        />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="flex items-center justify-between p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
            <span className="text-xs text-gray-500">누적 평균 평점</span>
            <span className="text-base font-bold text-primary-600">{mockAcademic.gpa}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
