import { Award, Download, Printer } from 'lucide-react';
import { useTranslation } from '@/i18n';

const certs = [
  { id: 1, title: '자바 프로그래밍', date: '2025-12-20', grade: 'A' },
  { id: 2, title: 'C언어 기초', date: '2025-06-15', grade: 'B+' },
];

export default function CertificatePage() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold">{t('student.certificateTitle')}</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {certs.map(c => (
          <div key={c.id} className="card p-5 text-center">
            <Award className="w-10 h-10 text-warning-500 mx-auto mb-3" />
            <div className="text-sm font-semibold mb-1">{c.title}</div>
            <div className="text-[10px] text-gray-400">수료일: {c.date} · 성적: {c.grade}</div>
            <div className="flex justify-center gap-2 mt-4">
              <button className="btn-sm btn-secondary"><Download className="w-3 h-3" />다운로드</button>
              <button className="btn-sm btn-ghost"><Printer className="w-3 h-3" />인쇄</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
