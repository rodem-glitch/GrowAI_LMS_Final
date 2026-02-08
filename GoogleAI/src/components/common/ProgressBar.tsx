// components/common/ProgressBar.tsx — 프로그레스 바
import clsx from 'clsx';

interface ProgressBarProps {
  value: number;       // 0~100
  variant?: 'default' | 'success';
  label?: string;
  showPercent?: boolean;
  size?: 'sm' | 'md';
}

export default function ProgressBar({ value, variant = 'default', label, showPercent = true, size = 'md' }: ProgressBarProps) {
  const clamped = Math.min(100, Math.max(0, value));

  return (
    <div>
      {(label || showPercent) && (
        <div className="flex items-center justify-between mb-1">
          {label && <span className="text-xs text-content-secondary">{label}</span>}
          {showPercent && <span className="text-xs font-medium text-content-default">{clamped}%</span>}
        </div>
      )}
      <div className={clsx('progress-track', size === 'sm' && 'h-1.5')}>
        <div
          className={variant === 'success' ? 'progress-fill-success' : 'progress-fill'}
          style={{ width: `${clamped}%` }}
        />
      </div>
    </div>
  );
}
