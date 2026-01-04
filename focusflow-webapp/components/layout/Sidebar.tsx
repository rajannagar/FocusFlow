'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard,
  Timer,
  CheckSquare,
  TrendingUp,
  BookOpen,
  Settings,
  User,
  Menu,
  X,
  Keyboard,
  Sparkles,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useColorTheme } from '@/hooks/useColorTheme';
import { useAuth } from '@/contexts/AuthContext';
import { themes } from '@/lib/themes';

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string | number;
}

const navItems: NavItem[] = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Focus', href: '/focus', icon: Timer },
  { name: 'Tasks', href: '/tasks', icon: CheckSquare },
  { name: 'Progress', href: '/progress', icon: TrendingUp },
  { name: 'Journey', href: '/journey', icon: BookOpen },
  { name: 'Settings', href: '/settings', icon: Settings },
  { name: 'Profile', href: '/profile', icon: User },
];

export function Sidebar() {
  const [isOpen, setIsOpen] = useState(true);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const pathname = usePathname();
  const { colorTheme, changeColorTheme, themes: availableThemes } = useColorTheme();
  const { user } = useAuth();

  const isActive = (href: string) => pathname === href;

  return (
    <>
      {/* Mobile Menu Button */}
      <button
        onClick={() => setIsMobileOpen(!isMobileOpen)}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-colors"
      >
        {isMobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
      </button>

      {/* Sidebar */}
      <AnimatePresence>
        {(isOpen || isMobileOpen) && (
          <motion.aside
            initial={{ x: -300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: -300, opacity: 0 }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className={cn(
              'fixed lg:sticky top-0 left-0 z-40 h-screen w-72 bg-[var(--background-elevated)] border-r border-[var(--border)] flex flex-col',
              'lg:translate-x-0',
              isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
            )}
          >
            {/* Header */}
            <div className="p-6 border-b border-[var(--border)]">
              <div className="flex items-center justify-between mb-4">
                <Link href="/dashboard" className="group flex items-center gap-2.5">
                  <div className="relative flex-shrink-0">
                    <div className="absolute -inset-1 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-lg blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                    <Image
                      src="/focusflow-logo.png"
                      alt="FocusFlow"
                      width={32}
                      height={32}
                      className="relative transition-transform duration-300 group-hover:scale-105"
                      priority
                    />
                  </div>
                  <span className="relative z-10 text-lg font-bold tracking-tight">
                    <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                      Focus
                    </span>
                    <span className="bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient" style={{ animationDelay: '0.5s' }}>
                      Flow
                    </span>
                    <span className="ml-1.5 text-xs font-medium text-[var(--foreground-muted)]">Pro</span>
                  </span>
                </Link>
                <button
                  onClick={() => setIsOpen(!isOpen)}
                  className="hidden lg:block p-1.5 rounded-xl hover:bg-[var(--background-subtle)] text-[var(--foreground-muted)] transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
              {user && (
                <div className="text-sm text-[var(--foreground-muted)]">
                  {user.email?.split('@')[0] || 'User'}
                </div>
              )}
            </div>

            {/* Navigation */}
            <nav className="flex-1 overflow-y-auto p-4 space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                const active = isActive(item.href);
                
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setIsMobileOpen(false)}
                    className={cn(
                      'relative flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300',
                      active
                        ? 'bg-[var(--background-elevated)] text-[var(--foreground)]'
                        : 'text-[var(--foreground-muted)] hover:bg-[var(--background-subtle)] hover:text-[var(--foreground)]'
                    )}
                  >
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{item.name}</span>
                    {item.badge && (
                      <span className="ml-auto px-2 py-0.5 text-xs rounded-full bg-[var(--accent-primary)]/20 text-[var(--accent-primary-light)]">
                        {item.badge}
                      </span>
                    )}
                    {active && (
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 rounded-r-full bg-[var(--accent-primary)]" />
                    )}
                  </Link>
                );
              })}
            </nav>

            {/* Quick Stats */}
            <div className="p-4 border-t border-[var(--border)] space-y-2">
              <div className="text-xs font-medium text-[var(--foreground-muted)] uppercase tracking-wider mb-2">
                Quick Stats
              </div>
              {/* Quick stats will be populated from store */}
              <div className="text-sm text-[var(--foreground-muted)]">
                Coming soon
              </div>
            </div>

            {/* Color Theme Selector */}
            <div className="p-4 border-t border-[var(--border)]">
              <div className="text-xs font-medium text-[var(--foreground-muted)] uppercase tracking-wider mb-3">
                Accent Color
              </div>
              <div className="grid grid-cols-5 gap-2">
                {availableThemes.map((t) => {
                  const themeColors = themes[t];
                  const isActive = colorTheme === t;
                  return (
                    <button
                      key={t}
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        changeColorTheme(t);
                      }}
                      className={cn(
                        'w-10 h-10 rounded-lg border-2 transition-all relative group cursor-pointer',
                        'focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] focus:ring-offset-2 focus:ring-offset-[var(--background-elevated)]',
                        isActive
                          ? 'border-[var(--accent-primary)] scale-110 ring-2 ring-[var(--accent-primary)]/50 shadow-lg'
                          : 'border-[var(--border)] hover:border-[var(--accent-primary)]/50 hover:scale-105'
                      )}
                      style={{
                        background: `linear-gradient(135deg, ${themeColors.accentPrimary}, ${themeColors.accentSecondary})`,
                      }}
                      title={t.charAt(0).toUpperCase() + t.slice(1)}
                      aria-label={`Switch to ${t} accent color`}
                      aria-pressed={isActive}
                    >
                      {isActive && (
                        <motion.div
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          className="absolute inset-0 flex items-center justify-center"
                        >
                          <div className="w-3 h-3 rounded-full bg-white/90 shadow-sm" />
                        </motion.div>
                      )}
                    </button>
                  );
                })}
              </div>
              <div className="mt-3 text-xs text-[var(--foreground-muted)] text-center capitalize font-medium">
                {colorTheme.charAt(0).toUpperCase() + colorTheme.slice(1)}
              </div>
            </div>
          </motion.aside>
        )}
      </AnimatePresence>

      {/* Mobile Overlay */}
      {isMobileOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setIsMobileOpen(false)}
          className="lg:hidden fixed inset-0 bg-black/50 z-30"
        />
      )}
    </>
  );
}

