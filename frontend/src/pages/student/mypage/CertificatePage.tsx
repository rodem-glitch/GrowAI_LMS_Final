// pages/student/mypage/CertificatePage.tsx — 수료증 다운로드/인쇄
import { useState } from 'react';
import { Award, Download, Printer, X, GraduationCap } from 'lucide-react';
import { useTranslation } from '@/i18n';

const certs = [
  { id: 1, title: '자바 프로그래밍', date: '2025-12-20', grade: 'A', instructor: '박교수', hours: 45 },
  { id: 2, title: 'C언어 기초', date: '2025-06-15', grade: 'B+', instructor: '최교수', hours: 40 },
  { id: 3, title: '웹 개발 실무', date: '2025-12-18', grade: 'A+', instructor: '김교수', hours: 60 },
  { id: 4, title: 'Spring Boot 실습', date: '2025-12-15', grade: 'A', instructor: '이교수', hours: 50 },
  { id: 5, title: 'SQL 활용', date: '2025-06-20', grade: 'A', instructor: '박교수', hours: 35 },
  { id: 6, title: '알고리즘과 자료구조', date: '2025-06-18', grade: 'B+', instructor: '최교수', hours: 45 },
  { id: 7, title: 'Linux 시스템 관리', date: '2024-12-18', grade: 'A+', instructor: '박교수', hours: 40 },
  { id: 8, title: 'Git & GitHub 실습', date: '2024-12-15', grade: 'A+', instructor: '최교수', hours: 30 },
  { id: 9, title: 'Docker & Kubernetes 입문', date: '2025-12-19', grade: 'A', instructor: '박교수', hours: 50 },
  { id: 10, title: 'REST API 설계', date: '2025-12-16', grade: 'A+', instructor: '최교수', hours: 35 },
];

interface CertData { id: number; title: string; date: string; grade: string; instructor: string; hours: number; }

function generateCertHTML(c: CertData) {
  return `<html><head><title>수료증 - ${c.title}</title>
<style>
@page{size:A4 landscape;margin:0}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Malgun Gothic',sans-serif;display:flex;justify-content:center;align-items:center;min-height:100vh;background:#f8f9fa}
.cert{width:900px;padding:60px;background:white;border:3px solid #1e40af;position:relative;box-shadow:0 4px 20px rgba(0,0,0,.1)}
.cert::before{content:'';position:absolute;inset:8px;border:1px solid #93c5fd;pointer-events:none}
.header{text-align:center;margin-bottom:40px}
.header h1{font-size:36px;color:#1e40af;letter-spacing:8px;margin-bottom:8px}
.header p{color:#6b7280;font-size:14px}
.body{text-align:center;margin-bottom:40px}
.name{font-size:28px;font-weight:bold;color:#111;margin:20px 0;border-bottom:2px solid #1e40af;display:inline-block;padding:0 40px 8px}
.course{font-size:20px;color:#374151;margin:16px 0}
.detail{font-size:14px;color:#6b7280;margin:8px 0}
.footer{display:flex;justify-content:space-between;align-items:flex-end;margin-top:40px}
.footer .left{text-align:left;font-size:12px;color:#9ca3af}
.footer .right{text-align:center}
.footer .right .stamp{width:80px;height:80px;border:2px solid #dc2626;border-radius:50%;display:flex;align-items:center;justify-content:center;color:#dc2626;font-size:14px;font-weight:bold;transform:rotate(-15deg)}
.grade{display:inline-block;background:#1e40af;color:white;padding:4px 16px;border-radius:20px;font-size:16px;font-weight:bold;margin:8px 0}
</style></head><body>
<div class="cert">
<div class="header"><h1>수 료 증</h1><p>GrowAI LMS - 한국폴리텍대학교</p></div>
<div class="body">
<p class="detail">성명</p><div class="name">김학생</div>
<p class="course">${c.title}</p>
<p class="detail">교육기간: ${c.hours}시간 | 수료일: ${c.date}</p>
<p class="detail">담당교수: ${c.instructor}</p>
<div class="grade">성적: ${c.grade}</div>
<p style="margin-top:24px;font-size:15px;color:#374151;line-height:1.8">위 사람은 상기 과정을 성실히 이수하였으므로<br>이 증서를 수여합니다.</p>
</div>
<div class="footer">
<div class="left"><p>${c.date}</p><p>증서번호: CERT-${String(c.id).padStart(4, '0')}</p></div>
<div class="right"><div class="stamp">한국<br>폴리텍</div><p style="font-size:12px;color:#6b7280;margin-top:4px">한국폴리텍대학교 총장</p></div>
</div></div></body></html>`;
}

export default function CertificatePage() {
  const { t } = useTranslation();
  const [preview, setPreview] = useState<CertData | null>(null);

  const handleDownload = (c: CertData) => {
    const html = generateCertHTML(c);
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `수료증_${c.title}.html`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handlePrint = (c: CertData) => {
    const win = window.open('', '_blank');
    if (!win) return;
    win.document.write(generateCertHTML(c));
    win.document.close();
    setTimeout(() => win.print(), 500);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <GraduationCap className="w-6 h-6 text-warning-500" />
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.certificateTitle')}</h1>
        <span className="text-xs text-gray-400 ml-2">{certs.length}건</span>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {certs.map(c => (
          <div key={c.id} className="card p-5 text-center hover:shadow-card-hover transition-all cursor-pointer group"
            onClick={() => setPreview(c)}>
            <Award className="w-10 h-10 text-warning-500 mx-auto mb-3 group-hover:scale-110 transition-transform" />
            <div className="text-sm font-semibold text-gray-900 dark:text-white mb-1">{c.title}</div>
            <div className="text-[10px] text-gray-400">수료일: {c.date} · 성적: {c.grade}</div>
            <div className="text-[10px] text-gray-400">{c.instructor} · {c.hours}시간</div>
            <div className="flex justify-center gap-2 mt-4">
              <button onClick={(e) => { e.stopPropagation(); handleDownload(c); }}
                className="btn-sm btn-secondary text-xs flex items-center gap-1">
                <Download className="w-3 h-3" />다운로드
              </button>
              <button onClick={(e) => { e.stopPropagation(); handlePrint(c); }}
                className="btn-sm btn-ghost text-xs flex items-center gap-1">
                <Printer className="w-3 h-3" />인쇄
              </button>
            </div>
          </div>
        ))}
      </div>

      {preview && (
        <div className="fixed inset-0 z-50 flex items-start justify-center pt-12 bg-black/40 backdrop-blur-sm"
          onClick={() => setPreview(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-2xl mx-4 overflow-hidden animate-in slide-in-from-top-4 fade-in duration-300"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700">
              <h2 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Award className="w-5 h-5 text-warning-500" />{preview.title} 수료증
              </h2>
              <button onClick={() => setPreview(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
            <div className="p-8 text-center">
              <div className="border-2 border-primary-600 p-8 rounded-lg relative">
                <div className="absolute inset-2 border border-primary-200 rounded pointer-events-none" />
                <h3 className="text-2xl font-bold text-primary-700 tracking-widest mb-2">수 료 증</h3>
                <p className="text-xs text-gray-400 mb-6">GrowAI LMS - 한국폴리텍대학교</p>
                <p className="text-xs text-gray-500 mb-1">성명</p>
                <p className="text-xl font-bold text-gray-900 dark:text-white border-b-2 border-primary-600 inline-block px-8 pb-1 mb-4">김학생</p>
                <p className="text-lg text-gray-700 dark:text-gray-300 mb-2">{preview.title}</p>
                <p className="text-xs text-gray-500">교육기간: {preview.hours}시간 | 수료일: {preview.date} | 담당교수: {preview.instructor}</p>
                <div className="inline-block bg-primary-600 text-white px-4 py-1 rounded-full text-sm font-bold mt-3">성적: {preview.grade}</div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-4 leading-relaxed">위 사람은 상기 과정을 성실히 이수하였으므로<br/>이 증서를 수여합니다.</p>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-700 flex justify-center gap-3">
              <button onClick={() => handleDownload(preview)} className="btn-primary text-sm flex items-center gap-1.5">
                <Download className="w-4 h-4" />다운로드
              </button>
              <button onClick={() => handlePrint(preview)} className="btn-secondary text-sm flex items-center gap-1.5">
                <Printer className="w-4 h-4" />인쇄
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
