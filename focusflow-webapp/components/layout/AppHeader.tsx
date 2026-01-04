'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import DarkModeToggle from '@/components/common/DarkModeToggle';
import { LogOut, User, LayoutDashboard, Timer, CheckSquare, TrendingUp, Settings } from 'lucide-react';

export default function AppHeader() {
  const { user, signOut } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  const handleSignOut = async () => {
    await signOut();
    router.push('/signin');
  };

  const isActive = (path: string) => {
    if (path === '/dashboard') return pathname === '/dashboard';
    return pathname.startsWith(path);
  };

  const navLinks = [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/focus', label: 'Focus Timer', icon: Timer },
    { href: '/tasks', label: 'Tasks', icon: CheckSquare },
    { href: '/progress', label: 'Progress', icon: TrendingUp },
  ];

  return (
    <>
      {/* Dark Mode Toggle - Fixed Top Right */}
      <div className="fixed top-4 right-4 z-[60]">
        <DarkModeToggle />
      </div>
      <header className="sticky top-0 z-50 bg-[var(--background)]/80 backdrop-blur-xl border-b border-[var(--border)]">
        <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8">
          <div className="flex h-16 md:h-20 items-center justify-between gap-4">
            {/* Logo */}
            <Link 
              href="/dashboard" 
              className="group relative flex items-center gap-2 md:gap-3 z-50 min-w-0 flex-shrink"
            >
              <div className="relative flex-shrink-0">
                <div className="absolute -inset-1 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-lg blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <Image
                  src="/focusflow-logo.png"
                  alt="FocusFlow"
                  width={32}
                  height={32}
                  className="relative transition-transform duration-300 group-hover:scale-105 md:w-9 md:h-9"
                  priority
                />
              </div>
              <div className="relative min-w-0 hidden sm:block">
                <span className="relative z-10 text-lg md:text-xl lg:text-2xl font-bold tracking-tight block whitespace-nowrap">
                  <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                    Focus
                  </span>
                  <span className="bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient" style={{ animationDelay: '0.5s' }}>
                    Flow
                  </span>
                  <span className="ml-1.5 text-sm md:text-base font-medium text-[var(--foreground-muted)]">Pro</span>
                </span>
              </div>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden md:flex items-center gap-1 flex-1 justify-center">
              {navLinks.map((link) => {
                const Icon = link.icon;
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={`relative px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-300 flex items-center gap-2 ${
                      isActive(link.href)
                        ? 'text-[var(--foreground)] bg-[var(--background-elevated)]' 
                        : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50'
                    }`}
                  >
                    <Icon className="w-4 h-4" strokeWidth={2} />
                    <span>{link.label}</span>
                    {isActive(link.href) && (
                      <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-[var(--accent-primary)]" />
                    )}
                  </Link>
                );
              })}
            </nav>

            {/* Right Side - User Info & Actions */}
            <div className="flex items-center gap-3">
              {user && (
                <>
                  {/* Profile/Settings Button */}
                  <Link
                    href="/profile"
                    className={`p-2 rounded-xl transition-all ${
                      isActive('/profile')
                        ? 'bg-[var(--background-elevated)] text-[var(--foreground)]'
                        : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50'
                    }`}
                    title="Profile & Settings"
                  >
                    <User className="w-5 h-5" strokeWidth={2} />
                  </Link>
                  
                  {/* User Email (Desktop) */}
                  <div className="hidden lg:flex items-center gap-2 px-4 py-2 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)]">
                    <span className="text-sm text-[var(--foreground-muted)] truncate max-w-[200px]">
                      {user.email}
                    </span>
                  </div>
                  
                  {/* Sign Out */}
                  <button
                    onClick={handleSignOut}
                    className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)] transition-all"
                  >
                    <LogOut className="w-4 h-4" />
                    <span className="hidden md:inline">Sign Out</span>
                  </button>
                </>
              )}
            </div>
          </div>

          {/* Mobile Navigation */}
          <nav className="md:hidden flex items-center gap-1 overflow-x-auto pb-2 -mb-2 scrollbar-hide">
            {navLinks.map((link) => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`relative px-3 py-2 rounded-lg text-xs font-medium transition-all flex items-center gap-1.5 flex-shrink-0 ${
                    isActive(link.href)
                      ? 'text-[var(--foreground)] bg-[var(--background-elevated)]' 
                      : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50'
                  }`}
                >
                  <Icon className="w-4 h-4" strokeWidth={2} />
                  <span>{link.label}</span>
                </Link>
              );
            })}
          </nav>
        </div>
      </header>
    </>
  );
}
