// pages/student/classroom/VideoPlayerPage.tsx — 동영상 플레이어 (다국어 지원)
import { useState } from 'react';
import { Play, Pause, SkipForward, SkipBack, Volume2, Maximize, List } from 'lucide-react';
import { useTranslation } from '@/i18n';

export default function VideoPlayerPage() {
  const [playing, setPlaying] = useState(false);
  const { t } = useTranslation();

  return (
    <div className="space-y-4">
      <div className="player-shell relative group">
        <div className="absolute inset-0 flex items-center justify-center">
          <button onClick={() => setPlaying(!playing)} className="w-16 h-16 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center hover:bg-white/30 transition-colors">
            {playing ? <Pause className="w-8 h-8 text-white" /> : <Play className="w-8 h-8 text-white ml-1" />}
          </button>
        </div>
        <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
          <div className="w-full h-1 bg-white/30 rounded-full mb-3 cursor-pointer"><div className="h-full w-[45%] bg-primary-500 rounded-full" /></div>
          <div className="flex items-center justify-between text-white text-xs">
            <div className="flex items-center gap-3">
              <button onClick={() => setPlaying(!playing)}>{playing ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}</button>
              <SkipBack className="w-4 h-4 cursor-pointer" />
              <SkipForward className="w-4 h-4 cursor-pointer" />
              <Volume2 className="w-4 h-4 cursor-pointer" />
              <span>13:45 / 30:00</span>
            </div>
            <div className="flex items-center gap-3">
              <select className="bg-transparent text-white text-xs border-none">
                <option>1.0x</option><option>1.25x</option><option>1.5x</option><option>2.0x</option>
              </select>
              <Maximize className="w-4 h-4 cursor-pointer" />
            </div>
          </div>
        </div>
      </div>
      <div className="card p-4">
        <h2 className="text-base font-semibold">{t('videoPlayer.lectureTitle')}</h2>
        <p className="text-sm text-gray-500 mt-1">{t('videoPlayer.lectureDesc')}</p>
      </div>
    </div>
  );
}
