// pages/admin/settings/SiteSettingsPage.tsx — 사이트 설정
import { useState } from 'react';
import { Settings, Save, Globe, Palette, Bell, Shield, Database, RefreshCw } from 'lucide-react';

export default function SiteSettingsPage() {
  const [siteName, setSiteName] = useState('GrowAI LMS');
  const [siteUrl, setSiteUrl] = useState('https://lms.kopo.ac.kr');
  const [adminEmail, setAdminEmail] = useState('admin@kopo.ac.kr');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">사이트 설정</h1>
          <p className="text-sm text-content-secondary mt-1">기본 설정 및 시스템 구성</p>
        </div>
        <button className="btn-primary"><Save className="w-4 h-4" /> 저장</button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 기본 설정 */}
        <div className="card space-y-5">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300">
            <Globe className="w-4 h-4 text-primary" /> 기본 정보
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">사이트명</label>
            <input type="text" value={siteName} onChange={(e) => setSiteName(e.target.value)} className="input" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">사이트 URL</label>
            <input type="text" value={siteUrl} onChange={(e) => setSiteUrl(e.target.value)} className="input" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">관리자 이메일</label>
            <input type="email" value={adminEmail} onChange={(e) => setAdminEmail(e.target.value)} className="input" />
          </div>
        </div>

        {/* 테마 설정 */}
        <div className="card space-y-5">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300">
            <Palette className="w-4 h-4 text-secondary" /> 테마 설정
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-2">Primary 컬러</label>
            <div className="flex items-center gap-3">
              {['#2563eb', '#9333ea', '#059669', '#dc2626', '#d97706'].map((color) => (
                <button
                  key={color}
                  className="w-8 h-8 rounded-full border-2 border-white shadow-sm ring-2 ring-transparent hover:ring-gray-300 transition-all"
                  style={{ backgroundColor: color }}
                />
              ))}
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">다크모드</label>
            <select className="input">
              <option>시스템 설정 따름</option>
              <option>항상 라이트</option>
              <option>항상 다크</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">로고 이미지</label>
            <div className="border-2 border-dashed border-gray-200 dark:border-slate-700 rounded-lg p-4 text-center text-xs text-gray-400">
              드래그하여 업로드 (PNG, SVG, 최대 2MB)
            </div>
          </div>
        </div>

        {/* 알림 설정 */}
        <div className="card space-y-5">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300">
            <Bell className="w-4 h-4 text-warning" /> 알림 설정
          </div>

          <div className="space-y-3">
            {[
              { label: '수강신청 알림', desc: '새로운 수강신청 시 관리자 알림', checked: true },
              { label: '수료 알림', desc: '학생 수료 시 이메일 발송', checked: true },
              { label: '시스템 오류 알림', desc: '서버 오류 발생 시 즉시 알림', checked: true },
              { label: '일일 통계 리포트', desc: '매일 오전 9시 통계 이메일', checked: false },
            ].map((item) => (
              <div key={item.label} className="flex items-center justify-between p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                <div>
                  <div className="text-sm font-medium text-gray-800 dark:text-white">{item.label}</div>
                  <div className="text-[10px] text-gray-400">{item.desc}</div>
                </div>
                <input type="checkbox" defaultChecked={item.checked} className="w-4 h-4 rounded border-gray-300" />
              </div>
            ))}
          </div>
        </div>

        {/* 동기화 설정 */}
        <div className="card space-y-5">
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-slate-300">
            <Database className="w-4 h-4 text-info" /> 학사 연동 설정
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">연동 엔드포인트</label>
            <input type="text" defaultValue="https://e-poly.kopo.ac.kr/api" className="input" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-slate-400 mb-1">동기화 주기</label>
            <select className="input">
              <option>매 6시간</option>
              <option>매 12시간</option>
              <option>매일 새벽 2시</option>
              <option>수동</option>
            </select>
          </div>
          <div className="flex items-center gap-2">
            <button className="btn btn-sm bg-info/10 text-info hover:bg-info/20">
              <RefreshCw className="w-3 h-3" /> 즉시 동기화
            </button>
            <span className="text-[10px] text-gray-400">마지막 동기화: 2026-02-08 14:30</span>
          </div>
        </div>
      </div>
    </div>
  );
}
