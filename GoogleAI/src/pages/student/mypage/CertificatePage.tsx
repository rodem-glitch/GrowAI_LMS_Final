// pages/student/mypage/CertificatePage.tsx — 수료증 목록 및 출력
import { Award, Download, Printer, Calendar, CheckCircle2 } from 'lucide-react';

const certificates = [
  { id: 1, courseName: '컴퓨터개론', semester: '2025-2', completedAt: '2025-12-20', grade: 'A+', certNo: 'CERT-2025-001' },
  { id: 2, courseName: 'HTML/CSS 기초', semester: '2025-2', completedAt: '2025-12-18', grade: 'A', certNo: 'CERT-2025-002' },
  { id: 3, courseName: '프로그래밍 논리', semester: '2025-1', completedAt: '2025-06-25', grade: 'A+', certNo: 'CERT-2025-003' },
  { id: 4, courseName: '정보처리 실습', semester: '2025-1', completedAt: '2025-06-20', grade: 'B+', certNo: 'CERT-2025-004' },
];

export default function CertificatePage() {
  return (
    <div className="page-container space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">수료증 관리</h1>
          <p className="text-sm text-content-secondary mt-1">발급된 수료증 목록</p>
        </div>
        <span className="badge badge-info">{certificates.length}건</span>
      </div>

      <div className="space-y-3">
        {certificates.map((cert) => (
          <div key={cert.id} className="card-hover">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-amber-50 to-orange-50 flex items-center justify-center shrink-0">
                <Award className="w-7 h-7 text-amber-500" />
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="text-sm font-semibold text-gray-800 dark:text-white">{cert.courseName}</h3>
                <div className="flex items-center gap-3 mt-1 text-[10px] text-gray-400">
                  <span>{cert.semester}</span>
                  <span className="flex items-center gap-1"><Calendar className="w-3 h-3" /> {cert.completedAt}</span>
                  <span className="badge-micro badge-success">{cert.grade}</span>
                </div>
                <p className="text-[10px] text-gray-400 mt-0.5">인증번호: {cert.certNo}</p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <button className="btn-ghost text-xs">
                  <Printer className="w-4 h-4" /> 출력
                </button>
                <button className="btn-primary text-xs">
                  <Download className="w-4 h-4" /> 다운로드
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
