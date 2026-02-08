// pages/admin/user/UserDetailPage.tsx — 회원 상세 정보
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, User, Mail, Phone, BookOpen, Calendar, Shield, Edit3 } from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

export default function UserDetailPage() {
  const { memberKey } = useParams();

  return (
    <div className="space-y-6">
      <Link to="/admin/users" className="inline-flex items-center gap-1 text-sm text-content-muted hover:text-primary">
        <ArrowLeft className="w-4 h-4" /> 회원 목록으로
      </Link>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile */}
        <div className="card text-center">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-primary-400 to-secondary-500 flex items-center justify-center text-white text-2xl font-bold mx-auto mb-4">
            홍
          </div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">홍길동</h2>
          <p className="text-sm text-content-muted mb-4">컴퓨터공학과 | 서울강서캠퍼스</p>

          <div className="space-y-3 text-left">
            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-400">
              <User className="w-4 h-4 text-gray-400" />
              <span>회원키: {memberKey}</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-400">
              <Shield className="w-4 h-4 text-gray-400" />
              <span>학번: 2024001</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-400">
              <Mail className="w-4 h-4 text-gray-400" />
              <span>hong@kopo.ac.kr</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-400">
              <Phone className="w-4 h-4 text-gray-400" />
              <span>010-****-1234</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-400">
              <Calendar className="w-4 h-4 text-gray-400" />
              <span>가입일: 2024-03-02</span>
            </div>
          </div>

          <button className="btn-secondary w-full mt-4"><Edit3 className="w-4 h-4" /> 정보 수정</button>
        </div>

        {/* Course & Activity */}
        <div className="lg:col-span-2 space-y-4">
          <div className="card">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300 mb-4">수강 이력</h3>
            <div className="space-y-3">
              {[
                { name: 'Python 프로그래밍 기초', code: 'CS101', progress: 85, semester: '2026-1', status: '수강중' },
                { name: '데이터베이스 설계', code: 'CS201', progress: 62, semester: '2026-1', status: '수강중' },
                { name: '컴퓨터개론', code: 'CS100', progress: 100, semester: '2025-2', status: '수료' },
              ].map((c) => (
                <div key={c.code} className="flex items-center gap-4 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                  <BookOpen className="w-5 h-5 text-primary shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-gray-800 dark:text-white">{c.name}</div>
                    <div className="text-[10px] text-gray-400">{c.code} | {c.semester}</div>
                  </div>
                  <div className="w-20"><ProgressBar value={c.progress} size="sm" showPercent={false} /></div>
                  <span className={`badge-micro ${c.status === '수료' ? 'badge-success' : 'badge-info'}`}>{c.status}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="card">
            <h3 className="text-sm font-semibold text-gray-700 dark:text-slate-300 mb-4">최근 활동 로그</h3>
            <div className="space-y-2">
              {[
                { action: '로그인', time: '2026-02-08 09:30', ip: '192.168.1.***' },
                { action: 'CS101 3주차 강의 수강', time: '2026-02-08 09:35', ip: '192.168.1.***' },
                { action: 'CS201 과제 제출', time: '2026-02-07 14:22', ip: '192.168.1.***' },
                { action: '로그인', time: '2026-02-07 14:00', ip: '10.0.0.***' },
              ].map((log, i) => (
                <div key={i} className="flex items-center justify-between text-xs text-gray-600 dark:text-slate-400 py-1.5 border-b border-gray-50 dark:border-slate-800 last:border-0">
                  <span>{log.action}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-[10px] text-gray-400">{log.ip}</span>
                    <span className="text-[10px] text-gray-400">{log.time}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
