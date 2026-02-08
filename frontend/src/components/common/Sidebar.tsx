// components/common/Sidebar.tsx — 사이드바 (서브메뉴 지원)
import { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { ChevronDown } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

export interface SidebarItem {
  label: string;
  path: string;
  icon: LucideIcon;
  children?: { label: string; path: string }[];
}

export interface SidebarSection { title: string; items: SidebarItem[]; }
interface SidebarProps { sections: SidebarSection[]; isOpen: boolean; onClose: () => void; }

export default function Sidebar({ sections, isOpen, onClose }: SidebarProps) {
  const location = useLocation();
  const [expanded, setExpanded] = useState<Record<string, boolean>>(() => {
    // 현재 경로에 맞는 서브메뉴 자동 확장
    const init: Record<string, boolean> = {};
    sections.forEach(sec => sec.items.forEach(item => {
      if (item.children?.some(c => location.pathname === c.path || location.pathname.startsWith(c.path + '/'))) {
        init[item.label] = true;
      }
    }));
    return init;
  });

  const toggleExpand = (label: string) => {
    setExpanded(prev => ({ ...prev, [label]: !prev[label] }));
  };

  const isChildActive = (item: SidebarItem) =>
    item.children?.some(c => location.pathname === c.path || location.pathname.startsWith(c.path + '/'));

  return (
    <>
      {isOpen && <div className="fixed inset-0 bg-black/30 z-40 lg:hidden" onClick={onClose} />}
      <aside className={`fixed lg:sticky top-14 left-0 z-40 w-60 h-[calc(100vh-3.5rem)] bg-white dark:bg-surface-dark border-r border-gray-100 dark:border-slate-800 overflow-y-auto transition-transform duration-300 ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        <nav className="p-3 space-y-5">
          {sections.map((sec) => (
            <div key={sec.title}>
              <div className="px-3 mb-2 text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-slate-500">{sec.title}</div>
              <div className="space-y-0.5">
                {sec.items.map((item) =>
                  item.children ? (
                    // 서브메뉴가 있는 항목
                    <div key={item.label}>
                      <button
                        onClick={() => toggleExpand(item.label)}
                        className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                          expanded[item.label] || isChildActive(item)
                            ? 'bg-primary-600 text-white font-medium'
                            : 'text-gray-600 hover:bg-gray-50 dark:text-slate-400 dark:hover:bg-slate-800'
                        }`}
                      >
                        <item.icon className="w-4 h-4 shrink-0" />
                        <span className="flex-1 text-left">{item.label}</span>
                        <ChevronDown className={`w-4 h-4 shrink-0 transition-transform ${expanded[item.label] ? 'rotate-0' : '-rotate-90'}`} />
                      </button>
                      {expanded[item.label] && (
                        <div className="mt-0.5 ml-2 space-y-0.5">
                          {item.children.map(child => (
                            <NavLink
                              key={child.path}
                              to={child.path}
                              end
                              onClick={onClose}
                              className={({ isActive }) =>
                                `flex items-center gap-2 pl-7 pr-3 py-1.5 rounded-lg text-sm transition-colors ${
                                  isActive
                                    ? 'bg-primary-50 text-primary-700 font-medium dark:bg-primary-900/30 dark:text-primary-400'
                                    : 'text-gray-500 hover:bg-gray-50 dark:text-slate-400 dark:hover:bg-slate-800'
                                }`
                              }
                            >
                              <span className="w-1.5 h-1.5 rounded-full bg-current shrink-0" />
                              {child.label}
                            </NavLink>
                          ))}
                        </div>
                      )}
                    </div>
                  ) : (
                    // 단일 메뉴 항목
                    <NavLink
                      key={item.path}
                      to={item.path}
                      end
                      onClick={onClose}
                      className={({ isActive }) =>
                        `flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                          isActive
                            ? 'bg-primary-50 text-primary-700 font-medium dark:bg-primary-900/30 dark:text-primary-400'
                            : 'text-gray-600 hover:bg-gray-50 dark:text-slate-400 dark:hover:bg-slate-800'
                        }`
                      }
                    >
                      <item.icon className="w-4 h-4 shrink-0" />
                      {item.label}
                    </NavLink>
                  )
                )}
              </div>
            </div>
          ))}
        </nav>
      </aside>
    </>
  );
}
