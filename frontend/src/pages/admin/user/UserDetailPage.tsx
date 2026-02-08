import { useParams } from 'react-router-dom';
import { User, Mail, Phone, MapPin, BookOpen } from 'lucide-react';
import { useTranslation } from '@/i18n';

export default function UserDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('admin.userDetailTitle')}</h1>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="card p-5 text-center">
          <div className="w-16 h-16 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center mx-auto mb-3">
            <User className="w-8 h-8 text-primary-600" />
          </div>
          <div className="text-base font-semibold">박학생</div>
          <div className="text-xs text-gray-400">student001 · 2024001</div>
          <div className="badge-sm badge-gray mt-2">학생</div>
          <div className="mt-4 space-y-2 text-sm text-left">
            <div className="flex items-center gap-2 text-gray-500"><Mail className="w-4 h-4" />park@kopo.ac.kr</div>
            <div className="flex items-center gap-2 text-gray-500"><Phone className="w-4 h-4" />010-1234-5678</div>
            <div className="flex items-center gap-2 text-gray-500"><MapPin className="w-4 h-4" />서울강서 · 컴퓨터공학과</div>
          </div>
        </div>
        <div className="lg:col-span-2 space-y-4">
          <div className="card p-5">
            <h2 className="text-sm font-semibold mb-3">수강 이력</h2>
            <div className="space-y-2">
              {['Python 프로그래밍 기초', '데이터베이스 설계'].map((c, i) => (
                <div key={i} className="flex items-center gap-3 p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                  <BookOpen className="w-4 h-4 text-primary-500" />
                  <span className="text-sm flex-1">{c}</span>
                  <span className="badge-sm badge-success">{i === 0 ? '수강중' : '수강중'}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
