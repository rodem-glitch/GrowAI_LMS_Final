// components/common/StatCard.tsx — 대시보드 통계 카드
import type { LucideIcon } from 'lucide-react';
import clsx from 'clsx';

interface StatCardProps {
  icon: LucideIcon;
  label: string;
  value: string | number;
  change?: string;
  trend?: 'up' | 'down' | 'neutral';
  iconColor?: string;
}

export default function StatCard({ icon: Icon, label, value, change, trend, iconColor = 'text-primary' }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className="flex items-center justify-between mb-3">
        <div className={clsx('w-10 h-10 rounded-xl flex items-center justify-center', iconColor === 'text-primary' ? 'bg-primary-50' : 'bg-gray-100')}>
          <Icon className={clsx('w-5 h-5', iconColor)} />
        </div>
        {change && (
          <span className={clsx(
            'badge-micro',
            trend === 'up' ? 'badge-success' : trend === 'down' ? 'badge-danger' : 'badge-gray',
          )}>
            {change}
          </span>
        )}
      </div>
      <div className="stat-value">{value}</div>
      <div className="stat-label mt-1">{label}</div>
    </div>
  );
}
