// pages/admin/cms/BannerManagePage.tsx — ADM-O01: 배너/팝업 관리
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { Image, Plus, Edit3, Trash2, GripVertical, Eye, EyeOff, Calendar, Link as LinkIcon, Maximize2, Move, X, Save } from 'lucide-react';

/* ───── 배너 데이터 ───── */
const mockBanners = [
  {
    id: 1,
    title: '2026학년도 1학기 수강신청 안내',
    imageUrl: '/banners/enrollment-2026.jpg',
    linkUrl: 'https://lms.polytech.ac.kr/enrollment',
    startDate: '2026-02-01',
    endDate: '2026-03-15',
    status: 'active',
    order: 1,
  },
  {
    id: 2,
    title: 'AI 학습 도우미 서비스 오픈',
    imageUrl: '/banners/ai-assistant.jpg',
    linkUrl: 'https://lms.polytech.ac.kr/ai-chat',
    startDate: '2026-01-20',
    endDate: '2026-06-30',
    status: 'active',
    order: 2,
  },
  {
    id: 3,
    title: '폴리텍 창업경진대회 참가자 모집',
    imageUrl: '/banners/startup-contest.jpg',
    linkUrl: 'https://lms.polytech.ac.kr/contest',
    startDate: '2026-03-01',
    endDate: '2026-04-30',
    status: 'scheduled',
    order: 3,
  },
];

const mockPopups = [
  {
    id: 101,
    title: '시스템 점검 안내 (2/15 02:00-06:00)',
    imageUrl: '/popups/maintenance-notice.jpg',
    width: 480,
    height: 360,
    posX: 200,
    posY: 150,
    startDate: '2026-02-10',
    endDate: '2026-02-15',
    status: 'active',
  },
  {
    id: 102,
    title: '개인정보 처리방침 변경 안내',
    imageUrl: '/popups/privacy-update.jpg',
    width: 520,
    height: 400,
    posX: 180,
    posY: 120,
    startDate: '2026-02-01',
    endDate: '2026-02-28',
    status: 'active',
  },
];

type Tab = 'banners' | 'popups';

interface BannerForm {
  title: string;
  linkUrl: string;
  startDate: string;
  endDate: string;
}

interface PopupForm {
  title: string;
  width: number;
  height: number;
  posX: number;
  posY: number;
  startDate: string;
  endDate: string;
}

export default function BannerManagePage() {
  const { t } = useTranslation();
  const [tab, setTab] = useState<Tab>('banners');
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [bannerForm, setBannerForm] = useState<BannerForm>({ title: '', linkUrl: '', startDate: '', endDate: '' });
  const [popupForm, setPopupForm] = useState<PopupForm>({ title: '', width: 480, height: 360, posX: 200, posY: 150, startDate: '', endDate: '' });
  const [previewPopup, setPreviewPopup] = useState<typeof mockPopups[0] | null>(null);

  const statusBadge = (status: string) => {
    switch (status) {
      case 'active': return <span className="badge-sm badge-success">게시중</span>;
      case 'scheduled': return <span className="badge-sm badge-info">예약</span>;
      case 'ended': return <span className="badge-sm badge-gray">종료</span>;
      default: return <span className="badge-sm badge-gray">{status}</span>;
    }
  };

  const openBannerEdit = (banner: typeof mockBanners[0]) => {
    setEditId(banner.id);
    setBannerForm({ title: banner.title, linkUrl: banner.linkUrl, startDate: banner.startDate, endDate: banner.endDate });
    setShowForm(true);
  };

  const openPopupEdit = (popup: typeof mockPopups[0]) => {
    setEditId(popup.id);
    setPopupForm({ title: popup.title, width: popup.width, height: popup.height, posX: popup.posX, posY: popup.posY, startDate: popup.startDate, endDate: popup.endDate });
    setShowForm(true);
  };

  const resetForm = () => {
    setShowForm(false);
    setEditId(null);
    setBannerForm({ title: '', linkUrl: '', startDate: '', endDate: '' });
    setPopupForm({ title: '', width: 480, height: 360, posX: 200, posY: 150, startDate: '', endDate: '' });
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.bannerTitle')}</h1>
        <button
          onClick={() => { resetForm(); setShowForm(true); }}
          className="btn-primary"
        >
          <Plus className="w-4 h-4" /> {tab === 'banners' ? '배너 추가' : '팝업 추가'}
        </button>
      </div>

      {/* 탭 */}
      <div className="flex gap-1 border-b border-gray-200 dark:border-slate-700">
        {[
          { key: 'banners' as const, label: '메인 배너', count: mockBanners.length },
          { key: 'popups' as const, label: '팝업 관리', count: mockPopups.length },
        ].map(t => (
          <button
            key={t.key}
            onClick={() => { setTab(t.key); resetForm(); }}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              tab === t.key
                ? 'border-primary-500 text-primary-600 dark:text-primary-400'
                : 'border-transparent text-gray-400 hover:text-gray-600'
            }`}
          >
            {t.label} <span className="ml-1 text-[10px] bg-gray-100 dark:bg-slate-700 px-1.5 py-0.5 rounded-full">{t.count}</span>
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 목록 */}
        <section className="card space-y-4 lg:col-span-2">
          {tab === 'banners' ? (
            <>
              <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">배너 목록</h2>
              <div className="space-y-3">
                {mockBanners.map(banner => (
                  <div key={banner.id} className="flex items-center gap-4 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                    {/* 순서 핸들 */}
                    <div className="cursor-grab text-gray-300 dark:text-slate-600 hover:text-gray-500">
                      <GripVertical className="w-4 h-4" />
                    </div>
                    {/* 썸네일 */}
                    <div className="w-24 h-14 bg-gradient-to-br from-primary-200 to-primary-400 dark:from-primary-800 dark:to-primary-600 rounded-lg flex items-center justify-center text-white text-[10px] flex-shrink-0">
                      <Image className="w-5 h-5 opacity-60" />
                    </div>
                    {/* 정보 */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-gray-900 dark:text-white truncate">{banner.title}</span>
                        {statusBadge(banner.status)}
                      </div>
                      <div className="flex items-center gap-3 text-[10px] text-gray-400">
                        <span className="flex items-center gap-1"><LinkIcon className="w-3 h-3" />{banner.linkUrl}</span>
                      </div>
                      <div className="flex items-center gap-1 text-[10px] text-gray-400 mt-1">
                        <Calendar className="w-3 h-3" />
                        {banner.startDate} ~ {banner.endDate}
                      </div>
                    </div>
                    {/* 액션 */}
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button onClick={() => openBannerEdit(banner)} className="p-1.5 text-gray-400 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/30 rounded-lg">
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
              <p className="text-[10px] text-gray-400 text-center">드래그하여 배너 노출 순서를 변경할 수 있습니다</p>
            </>
          ) : (
            <>
              <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">팝업 목록</h2>
              <div className="space-y-3">
                {mockPopups.map(popup => (
                  <div key={popup.id} className="flex items-center gap-4 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                    {/* 썸네일 */}
                    <div className="w-16 h-16 bg-gradient-to-br from-amber-200 to-amber-400 dark:from-amber-800 dark:to-amber-600 rounded-lg flex items-center justify-center text-white flex-shrink-0">
                      <Maximize2 className="w-5 h-5 opacity-60" />
                    </div>
                    {/* 정보 */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-gray-900 dark:text-white truncate">{popup.title}</span>
                        {statusBadge(popup.status)}
                      </div>
                      <div className="flex items-center gap-3 text-[10px] text-gray-400">
                        <span className="flex items-center gap-1"><Maximize2 className="w-3 h-3" />{popup.width} x {popup.height}px</span>
                        <span className="flex items-center gap-1"><Move className="w-3 h-3" />X:{popup.posX} Y:{popup.posY}</span>
                      </div>
                      <div className="flex items-center gap-1 text-[10px] text-gray-400 mt-1">
                        <Calendar className="w-3 h-3" />
                        {popup.startDate} ~ {popup.endDate}
                      </div>
                    </div>
                    {/* 액션 */}
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button onClick={() => setPreviewPopup(popup)} className="p-1.5 text-gray-400 hover:text-green-600 hover:bg-green-50 dark:hover:bg-green-900/30 rounded-lg">
                        <Eye className="w-4 h-4" />
                      </button>
                      <button onClick={() => openPopupEdit(popup)} className="p-1.5 text-gray-400 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/30 rounded-lg">
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </section>

        {/* 등록/수정 폼 & 미리보기 */}
        <section className="card space-y-4">
          {showForm ? (
            <>
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">
                  {editId ? '수정' : '신규 등록'}
                </h2>
                <button onClick={resetForm} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>

              {tab === 'banners' ? (
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">{t('common.name')}</label>
                    <input
                      type="text"
                      value={bannerForm.title}
                      onChange={e => setBannerForm(f => ({ ...f, title: e.target.value }))}
                      placeholder="배너 제목"
                      className="w-full p-2.5 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  {/* 이미지 업로드 영역 */}
                  <div>
                    <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">이미지</label>
                    <div className="border-2 border-dashed border-gray-300 dark:border-slate-700 rounded-lg p-8 text-center hover:border-primary-400 transition-colors cursor-pointer">
                      <Image className="w-8 h-8 mx-auto text-gray-300 dark:text-slate-600 mb-2" />
                      <p className="text-xs text-gray-500">클릭하여 이미지 업로드</p>
                      <p className="text-[10px] text-gray-400 mt-1">권장: 1920 x 480px, 최대 2MB</p>
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">링크 URL</label>
                    <input
                      type="url"
                      value={bannerForm.linkUrl}
                      onChange={e => setBannerForm(f => ({ ...f, linkUrl: e.target.value }))}
                      placeholder="https://"
                      className="w-full p-2.5 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">시작일</label>
                      <input
                        type="date"
                        value={bannerForm.startDate}
                        onChange={e => setBannerForm(f => ({ ...f, startDate: e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">종료일</label>
                      <input
                        type="date"
                        value={bannerForm.endDate}
                        onChange={e => setBannerForm(f => ({ ...f, endDate: e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                  </div>
                  <button className="w-full btn-primary"><Save className="w-4 h-4" /> {t('common.save')}</button>
                </div>
              ) : (
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">{t('common.name')}</label>
                    <input
                      type="text"
                      value={popupForm.title}
                      onChange={e => setPopupForm(f => ({ ...f, title: e.target.value }))}
                      placeholder="팝업 제목"
                      className="w-full p-2.5 text-sm border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  {/* 이미지 업로드 */}
                  <div>
                    <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">이미지</label>
                    <div className="border-2 border-dashed border-gray-300 dark:border-slate-700 rounded-lg p-6 text-center hover:border-primary-400 transition-colors cursor-pointer">
                      <Image className="w-6 h-6 mx-auto text-gray-300 dark:text-slate-600 mb-2" />
                      <p className="text-xs text-gray-500">이미지 업로드</p>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">너비 (px)</label>
                      <input
                        type="number"
                        value={popupForm.width}
                        onChange={e => setPopupForm(f => ({ ...f, width: +e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">높이 (px)</label>
                      <input
                        type="number"
                        value={popupForm.height}
                        onChange={e => setPopupForm(f => ({ ...f, height: +e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">위치 X</label>
                      <input
                        type="number"
                        value={popupForm.posX}
                        onChange={e => setPopupForm(f => ({ ...f, posX: +e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">위치 Y</label>
                      <input
                        type="number"
                        value={popupForm.posY}
                        onChange={e => setPopupForm(f => ({ ...f, posY: +e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">시작일</label>
                      <input
                        type="date"
                        value={popupForm.startDate}
                        onChange={e => setPopupForm(f => ({ ...f, startDate: e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">종료일</label>
                      <input
                        type="date"
                        value={popupForm.endDate}
                        onChange={e => setPopupForm(f => ({ ...f, endDate: e.target.value }))}
                        className="w-full p-2.5 text-xs border border-gray-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                      />
                    </div>
                  </div>
                  <button className="w-full btn-primary"><Save className="w-4 h-4" /> {t('common.save')}</button>
                </div>
              )}
            </>
          ) : (
            /* 미리보기 영역 */
            <div>
              <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 mb-4">미리보기</h2>
              {tab === 'banners' ? (
                <div className="space-y-3">
                  {mockBanners.filter(b => b.status === 'active').map(b => (
                    <div key={b.id} className="relative overflow-hidden rounded-lg">
                      <div className="w-full h-20 bg-gradient-to-r from-primary-400 to-primary-600 flex items-center justify-center">
                        <span className="text-white text-xs font-medium text-center px-4">{b.title}</span>
                      </div>
                      <div className="absolute bottom-1 right-1">
                        <span className="bg-black/50 text-white text-[8px] px-1.5 py-0.5 rounded">#{b.order}</span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="relative w-full h-64 bg-gray-100 dark:bg-slate-800 rounded-lg overflow-hidden border border-gray-200 dark:border-slate-700">
                  <div className="absolute inset-0 flex items-center justify-center text-[10px] text-gray-300 dark:text-slate-600">
                    브라우저 화면 시뮬레이션
                  </div>
                  {mockPopups.filter(p => p.status === 'active').map(p => {
                    const scale = 0.25;
                    return (
                      <div
                        key={p.id}
                        className="absolute bg-white dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded shadow-lg"
                        style={{
                          width: p.width * scale,
                          height: p.height * scale,
                          left: p.posX * scale,
                          top: p.posY * scale,
                        }}
                      >
                        <div className="h-4 bg-gray-200 dark:bg-slate-600 rounded-t flex items-center px-1">
                          <div className="flex gap-0.5">
                            <span className="w-1.5 h-1.5 rounded-full bg-red-400" />
                            <span className="w-1.5 h-1.5 rounded-full bg-yellow-400" />
                            <span className="w-1.5 h-1.5 rounded-full bg-green-400" />
                          </div>
                        </div>
                        <div className="p-1 text-[7px] text-gray-500 dark:text-slate-400 truncate">{p.title}</div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </section>
      </div>

      {/* 팝업 미리보기 모달 */}
      {previewPopup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div
            className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl overflow-hidden"
            style={{ width: Math.min(previewPopup.width, 600), maxWidth: '90vw' }}
          >
            <div className="flex items-center justify-between px-4 py-2 bg-gray-100 dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
              <span className="text-xs font-medium text-gray-700 dark:text-slate-300">{previewPopup.title}</span>
              <button onClick={() => setPreviewPopup(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="p-6" style={{ minHeight: Math.min(previewPopup.height - 40, 300) }}>
              <div className="w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 dark:from-slate-800 dark:to-slate-700 rounded-lg flex items-center justify-center" style={{ minHeight: 200 }}>
                <div className="text-center">
                  <Image className="w-12 h-12 mx-auto text-gray-300 dark:text-slate-600 mb-2" />
                  <p className="text-sm text-gray-500 dark:text-slate-400">{previewPopup.title}</p>
                  <p className="text-[10px] text-gray-400 mt-2">{previewPopup.width} x {previewPopup.height}px</p>
                </div>
              </div>
            </div>
            <div className="px-4 py-2 bg-gray-50 dark:bg-slate-800 border-t border-gray-200 dark:border-slate-700 flex items-center justify-between">
              <label className="flex items-center gap-2 text-xs text-gray-500">
                <input type="checkbox" className="rounded" />
                오늘 하루 보지 않기
              </label>
              <button onClick={() => setPreviewPopup(null)} className="text-xs text-primary-600 hover:text-primary-700 font-medium">{t('common.close')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
