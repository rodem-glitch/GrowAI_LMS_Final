// components/common/Sidebar.tsx — 사이드바 내비게이션
import { NavLink } from 'react-router-dom';
import clsx from 'clsx';
import type { LucideIcon } from 'lucide-react';

export interface SidebarItem {
  label: string;
  path: string;
  icon: LucideIcon;
  badge?: string;
}

export interface SidebarSection {
  title: string;
  items: SidebarItem[];
}

interface SidebarProps {
  sections: SidebarSection[];
  isOpen: boolean;
  onClose?: () => void;
}

export default function Sidebar({ sections, isOpen, onClose }: SidebarProps) {
  return (
    <>
      {/* Overlay (mobile) */}
      {isOpen && (
        <div className="fixed inset-0 bg-black/30 z-40 lg:hidden" onClick={onClose} />
      )}

      <aside
        className={clsx(
          'fixed top-0 left-0 z-40 h-full w-sidebar bg-white dark:bg-slate-900 border-r border-surface-border',
          'pt-16 pb-4 overflow-y-auto transition-transform duration-300',
          'lg:translate-x-0 lg:static lg:z-auto',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        <nav className="px-3 py-4 space-y-6">
          {sections.map((section) => (
            <div key={section.title}>
              <p className="px-3 mb-2 text-[10px] font-semibold uppercase tracking-wider text-gray-400 dark:text-slate-500">
                {section.title}
              </p>
              <ul className="space-y-0.5">
                {section.items.map((item) => (
                  <li key={item.path}>
                    <NavLink
                      to={item.path}
                      end={item.path === '/' || item.path === '/admin' || item.path === '/instructor'}
                      className={({ isActive }) =>
                        clsx(
                          'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                          isActive
                            ? 'bg-primary-50 text-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                            : 'text-gray-600 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-800',
                        )
                      }
                    >
                      <item.icon className="w-4 h-4 shrink-0" />
                      <span className="flex-1">{item.label}</span>
                      {item.badge && (
                        <span className="badge-micro badge-danger">{item.badge}</span>
                      )}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>
      </aside>
    </>
  );
}
