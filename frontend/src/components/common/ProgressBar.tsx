// components/common/ProgressBar.tsx — 진행률 바
interface ProgressBarProps {
  value: number;
  showPercent?: boolean;
  size?: 'sm' | 'md';
  variant?: 'default' | 'success' | 'danger';
  label?: string;
}

export default function ProgressBar({ value, showPercent = true, size = 'md', variant = 'default', label }: ProgressBarProps) {
  const height = size === 'sm' ? 'h-1.5' : 'h-2.5';
  const color = variant === 'success' ? 'bg-success-500' : variant === 'danger' ? 'bg-danger-500' : 'bg-primary-500';
  return (
    <div>
      {label && <div className="flex justify-between text-[10px] text-gray-500 mb-1"><span>{label}</span>{showPercent && <span>{value}%</span>}</div>}
      <div className={`w-full ${height} bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden`}>
        <div className={`${height} ${color} rounded-full transition-all duration-500`} style={{ width: `${Math.min(value, 100)}%` }} />
      </div>
      {!label && showPercent && <div className="text-[10px] text-gray-500 mt-0.5 text-right">{value}%</div>}
    </div>
  );
}
