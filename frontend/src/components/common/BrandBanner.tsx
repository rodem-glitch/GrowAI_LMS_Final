// components/common/BrandBanner.tsx — 브랜드 슬라이딩 카드 배너
import { useState, useEffect, useCallback, useRef } from 'react';
import {
  X, Bot, GraduationCap, Brain, Briefcase, BarChart3,
  Shield, Sparkles, ChevronLeft, ChevronRight,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

interface BrandBannerProps {
  isOpen: boolean;
  onClose: () => void;
}

interface BannerCard {
  icon: React.ElementType;
  gradient: string;
  iconColor: string;
}

const cardMeta: BannerCard[] = [
  { icon: Bot, gradient: 'from-blue-500 to-indigo-600', iconColor: 'text-blue-100' },
  { icon: Brain, gradient: 'from-purple-500 to-pink-600', iconColor: 'text-purple-100' },
  { icon: GraduationCap, gradient: 'from-emerald-500 to-teal-600', iconColor: 'text-emerald-100' },
  { icon: Briefcase, gradient: 'from-orange-500 to-red-500', iconColor: 'text-orange-100' },
  { icon: BarChart3, gradient: 'from-cyan-500 to-blue-600', iconColor: 'text-cyan-100' },
  { icon: Shield, gradient: 'from-slate-600 to-slate-800', iconColor: 'text-slate-200' },
];

export default function BrandBanner({ isOpen, onClose }: BrandBannerProps) {
  const { t } = useTranslation();
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);
  const [slideDirection, setSlideDirection] = useState<'left' | 'right'>('left');
  const autoPlayRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  // 카드 데이터 (i18n)
  const cards = [
    { ...cardMeta[0], title: t('brand.card1Title'), desc: t('brand.card1Desc'), tag: t('brand.card1Tag') },
    { ...cardMeta[1], title: t('brand.card2Title'), desc: t('brand.card2Desc'), tag: t('brand.card2Tag') },
    { ...cardMeta[2], title: t('brand.card3Title'), desc: t('brand.card3Desc'), tag: t('brand.card3Tag') },
    { ...cardMeta[3], title: t('brand.card4Title'), desc: t('brand.card4Desc'), tag: t('brand.card4Tag') },
    { ...cardMeta[4], title: t('brand.card5Title'), desc: t('brand.card5Desc'), tag: t('brand.card5Tag') },
    { ...cardMeta[5], title: t('brand.card6Title'), desc: t('brand.card6Desc'), tag: t('brand.card6Tag') },
  ];

  const goTo = useCallback((index: number, direction: 'left' | 'right') => {
    if (isAnimating) return;
    setIsAnimating(true);
    setSlideDirection(direction);
    setTimeout(() => {
      setCurrentIndex(index);
      setTimeout(() => setIsAnimating(false), 300);
    }, 150);
  }, [isAnimating]);

  const goNext = useCallback(() => {
    goTo((currentIndex + 1) % cards.length, 'left');
  }, [currentIndex, cards.length, goTo]);

  const goPrev = useCallback(() => {
    goTo((currentIndex - 1 + cards.length) % cards.length, 'right');
  }, [currentIndex, cards.length, goTo]);

  // 자동 슬라이드
  useEffect(() => {
    if (!isOpen) return;
    autoPlayRef.current = setInterval(goNext, 4000);
    return () => { if (autoPlayRef.current) clearInterval(autoPlayRef.current); };
  }, [isOpen, goNext]);

  // 외부 클릭 닫기
  useEffect(() => {
    if (!isOpen) return;
    const handleClick = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
        onClose();
      }
    };
    setTimeout(() => document.addEventListener('mousedown', handleClick), 100);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [isOpen, onClose]);

  // ESC 닫기
  useEffect(() => {
    if (!isOpen) return;
    const handleKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [isOpen, onClose]);

  // 초기화
  useEffect(() => {
    if (isOpen) { setCurrentIndex(0); setIsAnimating(false); }
  }, [isOpen]);

  if (!isOpen) return null;

  const card = cards[currentIndex];
  const CardIcon = card.icon;

  return (
    <div
      ref={panelRef}
      className="absolute left-0 top-full mt-2 z-[200] w-[420px] animate-in slide-in-from-top-2 fade-in duration-300"
    >
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-gray-100 dark:border-slate-700 overflow-hidden">
        {/* 헤더 */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-gray-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <div>
              <span className="text-sm font-bold text-gray-900 dark:text-white">GrowAI LMS</span>
              <span className="text-[10px] text-gray-400 dark:text-gray-500 ml-2">v5.0</span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
          >
            <X className="w-4 h-4 text-gray-400" />
          </button>
        </div>

        {/* 캐치프라이즈 */}
        <div className="px-5 pt-4 pb-2">
          <p className="text-lg font-bold text-gray-900 dark:text-white leading-snug">
            {t('brand.headline')}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {t('brand.subheadline')}
          </p>
        </div>

        {/* 슬라이딩 카드 */}
        <div className="px-5 py-3">
          <div className="relative overflow-hidden rounded-xl">
            <div
              className={`bg-gradient-to-br ${card.gradient} rounded-xl p-5 transition-all duration-300 ${
                isAnimating
                  ? slideDirection === 'left'
                    ? 'opacity-0 -translate-x-4'
                    : 'opacity-0 translate-x-4'
                  : 'opacity-100 translate-x-0'
              }`}
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center flex-shrink-0">
                  <CardIcon className={`w-6 h-6 ${card.iconColor}`} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1.5">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-white/70 bg-white/20 px-2 py-0.5 rounded-full">
                      {card.tag}
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white leading-snug">
                    {card.title}
                  </h3>
                  <p className="text-xs text-white/80 mt-1.5 leading-relaxed">
                    {card.desc}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 네비게이션 + 인디케이터 */}
        <div className="px-5 pb-4 flex items-center justify-between">
          <button
            onClick={() => { goPrev(); if (autoPlayRef.current) clearInterval(autoPlayRef.current); }}
            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
          >
            <ChevronLeft className="w-4 h-4 text-gray-400" />
          </button>

          <div className="flex items-center gap-1.5">
            {cards.map((_, idx) => (
              <button
                key={idx}
                onClick={() => {
                  goTo(idx, idx > currentIndex ? 'left' : 'right');
                  if (autoPlayRef.current) clearInterval(autoPlayRef.current);
                }}
                className={`transition-all duration-300 rounded-full ${
                  idx === currentIndex
                    ? 'w-6 h-2 bg-blue-500'
                    : 'w-2 h-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600'
                }`}
              />
            ))}
          </div>

          <button
            onClick={() => { goNext(); if (autoPlayRef.current) clearInterval(autoPlayRef.current); }}
            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
          >
            <ChevronRight className="w-4 h-4 text-gray-400" />
          </button>
        </div>

        {/* 푸터 */}
        <div className="px-5 py-3 bg-gray-50 dark:bg-slate-800/50 border-t border-gray-100 dark:border-slate-800">
          <p className="text-[10px] text-gray-400 dark:text-gray-500 text-center">
            {t('brand.footer')}
          </p>
        </div>
      </div>
    </div>
  );
}
