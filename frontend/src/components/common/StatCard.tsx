// components/common/StatCard.tsx — 통계 카드
import type { LucideIcon } from 'lucide-react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface StatCardProps {
  icon: LucideIcon;
  label: string;
  value: string;
  change?: string;
  trend?: 'up' | 'down';
}

export default function StatCard({ icon: Icon, label, value, change, trend }: StatCardProps) {
  return (
    <div className="card p-4">
      <div className="flex items-center justify-between mb-2">
        <div className="p-2 rounded-lg bg-primary-50 dark:bg-primary-900/30">
          <Icon className="w-4 h-4 text-primary-600" />
        </div>
        {change && (
          <span className={`flex items-center gap-0.5 text-[10px] font-medium ${trend === 'up' ? 'text-success-600' : trend === 'down' ? 'text-danger-600' : 'text-gray-400'}`}>
            {trend === 'up' ? <TrendingUp className="w-3 h-3" /> : trend === 'down' ? <TrendingDown className="w-3 h-3" /> : null}
            {change}
          </span>
        )}
      </div>
      <div className="text-xl font-bold text-gray-900 dark:text-white">{value}</div>
      <div className="text-[10px] text-gray-500 mt-0.5">{label}</div>
    </div>
  );
}
