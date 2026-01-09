'use client';

import Link from 'next/link';
import { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { ThemeToggle } from '@/components/common';
import { APP_STORE_URL } from '@/lib/constants';
import { Menu, X, Download, LogIn, ChevronRight, Sparkles, Timer, CheckSquare, TrendingUp, Crown } from 'lucide-react';

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const pathname = usePathname();
  const menuButtonRef = useRef<HTMLButtonElement>(null);

  // Handle scroll state
  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu when route changes
  useEffect(() => {
    setIsMenuOpen(false);
  }, [pathname]);

  // Prevent body scroll when menu is open
  useEffect(() => {
    if (isMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMenuOpen]);

  // Close menu when clicking outside
  useEffect(() => {
    if (!isMenuOpen) return;

    const handleClickOutside = (event: MouseEvent | TouchEvent) => {
      const target = event.target as HTMLElement;
      if (
        menuButtonRef.current &&
        !menuButtonRef.current.contains(target) &&
        !target.closest('[data-mobile-menu]')
      ) {
        setIsMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('touchstart', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [isMenuOpen]);

  const isActive = (path: string) => {
    if (path === '/') return pathname === '/';
    return pathname.startsWith(path);
  };

  const isPricingPage = isActive('/pricing');

  // Navigation links
  const navLinks = [
    { href: '/', label: 'Home' },
    { href: '/features', label: 'Features' },
    { href: '/pricing', label: 'Pricing' },
    { href: '/about', label: 'About' },
  ];

  // Mobile menu links with icons
  const mobileNavLinks = [
    { href: '/', label: 'Home', icon: Sparkles, desc: 'Discover FocusFlow' },
    { href: '/features', label: 'Features', icon: Timer, desc: 'Explore capabilities' },
    { href: '/pricing', label: 'Pricing', icon: Crown, desc: 'Plans & pricing' },
    { href: '/about', label: 'About', icon: CheckSquare, desc: 'Our story' },
  ];

  const toggleMenu = () => {
    setIsMenuOpen((prev) => !prev);
  };

  return (
    <>
      {/* Header */}
      <header
        className={`fixed top-0 left-0 right-0 z-[100] transition-all duration-300 ${
          scrolled
            ? 'bg-[var(--background)]/90 backdrop-blur-xl border-b border-[var(--border)] shadow-sm'
            : 'bg-transparent'
        }`}
        style={{
          paddingTop: 'env(safe-area-inset-top, 0px)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 sm:h-18 md:h-20 items-center justify-between">
            
            {/* Logo */}
            <Link
              href="/"
              className="flex items-center gap-2.5 sm:gap-3 group relative"
              onClick={() => {
                if (pathname === '/') {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }
              }}
            >
              {/* Logo glow effect */}
              <div className="absolute -inset-3 bg-gradient-to-r from-[var(--accent-primary)]/0 to-[var(--accent-primary)]/0 group-hover:from-[var(--accent-primary)]/10 group-hover:to-[var(--accent-secondary)]/10 rounded-2xl blur-xl transition-all duration-500 opacity-0 group-hover:opacity-100" />
              
              <div className="relative flex-shrink-0">
                <Image
                  src="/focusflow-logo.png"
                  alt="FocusFlow"
                  width={36}
                  height={36}
                  className="w-8 h-8 sm:w-9 sm:h-9 md:w-10 md:h-10 transition-transform duration-300 group-hover:scale-110"
                  priority
                />
              </div>
              <div className="relative">
                <span className="text-lg sm:text-xl md:text-2xl font-bold tracking-tight block whitespace-nowrap">
                  <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                    Focus
                  </span>
                  <span
                    className="bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient"
                    style={{ animationDelay: '0.5s' }}
                  >
                    Flow
                  </span>
                  {isPricingPage && (
                    <span className="ml-1.5 sm:ml-2 bg-gradient-to-r from-[#D4A853] via-[#F4D03F] via-[#F7DC6F] to-[#D4A853] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                      Pro
                    </span>
                  )}
                </span>
              </div>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden lg:flex items-center gap-1">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`relative px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group ${
                    isActive(link.href)
                      ? 'text-[var(--foreground)]'
                      : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
                  }`}
                >
                  {/* Active background */}
                  {isActive(link.href) && (
                    <span className="absolute inset-0 bg-[var(--background-elevated)] rounded-xl" />
                  )}
                  {/* Hover background */}
                  <span className="absolute inset-0 bg-[var(--background-elevated)] rounded-xl opacity-0 group-hover:opacity-50 transition-opacity duration-200" />
                  <span className="relative">{link.label}</span>
                </Link>
              ))}
            </nav>

            {/* Desktop Actions */}
            <div className="hidden lg:flex items-center gap-2">
              {/* Sign In */}
              <Link
                href="/webapp"
                className="group relative px-4 py-2.5 rounded-xl text-sm font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-all duration-200 flex items-center gap-2"
              >
                <span className="absolute inset-0 bg-[var(--background-elevated)] rounded-xl opacity-0 group-hover:opacity-50 transition-opacity duration-200" />
                <LogIn className="w-4 h-4 relative" strokeWidth={2} />
                <span className="relative">Sign In</span>
              </Link>
              
              {/* Download Button */}
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative px-5 py-2.5 rounded-xl text-sm font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-[var(--accent-primary)]/25"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div className="relative z-10 flex items-center gap-2">
                  <Download className="w-4 h-4" strokeWidth={2.5} />
                  <span>Download</span>
                </div>
              </a>
              
              {/* Theme Toggle */}
              <div className="ml-1">
                <ThemeToggle />
              </div>
            </div>

            {/* Mobile: Theme Toggle + Menu Button */}
            <div className="flex lg:hidden items-center gap-1">
              <ThemeToggle />
              <button
                ref={menuButtonRef}
                onClick={toggleMenu}
                className="relative p-2.5 rounded-xl text-[var(--foreground)] hover:bg-[var(--background-elevated)] active:bg-[var(--background-muted)] transition-all duration-200 touch-manipulation"
                aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
                aria-expanded={isMenuOpen}
                style={{
                  minWidth: '44px',
                  minHeight: '44px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                <div className="relative w-6 h-6">
                  <Menu 
                    className={`absolute inset-0 w-6 h-6 transition-all duration-300 ${isMenuOpen ? 'opacity-0 rotate-90 scale-0' : 'opacity-100 rotate-0 scale-100'}`} 
                    strokeWidth={2} 
                  />
                  <X 
                    className={`absolute inset-0 w-6 h-6 transition-all duration-300 ${isMenuOpen ? 'opacity-100 rotate-0 scale-100' : 'opacity-0 -rotate-90 scale-0'}`} 
                    strokeWidth={2} 
                  />
                </div>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Mobile Menu Overlay */}
      <div
        className={`lg:hidden fixed inset-0 bg-black/60 backdrop-blur-sm z-[90] transition-opacity duration-300 ${
          isMenuOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        onClick={toggleMenu}
        aria-hidden="true"
        style={{
          top: 'calc(env(safe-area-inset-top, 0px) + 4rem)',
        }}
      />

      {/* Mobile Menu */}
      <div
        data-mobile-menu
        className={`lg:hidden fixed left-0 right-0 z-[95] bg-[var(--background)] border-t border-[var(--border)] transition-all duration-300 ease-out shadow-2xl ${
          isMenuOpen ? 'translate-y-0 opacity-100' : '-translate-y-4 opacity-0 pointer-events-none'
        }`}
        style={{
          top: 'calc(env(safe-area-inset-top, 0px) + 4rem)',
          maxHeight: 'calc(100vh - env(safe-area-inset-top, 0px) - 4rem)',
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        }}
      >
        <div 
          className="overflow-y-auto overscroll-contain" 
          style={{ maxHeight: 'calc(100vh - env(safe-area-inset-top, 0px) - 4rem - env(safe-area-inset-bottom, 0px))' }}
        >
          <div className="px-4 py-6 space-y-2">
            {/* Navigation Links */}
            {mobileNavLinks.map((link) => {
              const IconComponent = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={toggleMenu}
                  className={`group flex items-center gap-4 px-4 py-4 rounded-2xl transition-all duration-200 touch-manipulation ${
                    isActive(link.href)
                      ? 'bg-gradient-to-r from-[var(--accent-primary)]/10 to-[var(--accent-primary)]/5 border border-[var(--accent-primary)]/20'
                      : 'hover:bg-[var(--background-elevated)] active:bg-[var(--background-elevated)] border border-transparent'
                  }`}
                  style={{
                    minHeight: '56px',
                    WebkitTapHighlightColor: 'transparent',
                  }}
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 ${
                    isActive(link.href) 
                      ? 'bg-[var(--accent-primary)]/20 text-[var(--accent-primary)]' 
                      : 'bg-[var(--background-subtle)] text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)] group-hover:bg-[var(--accent-primary)]/10'
                  }`}>
                    <IconComponent className="w-5 h-5" strokeWidth={1.5} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className={`text-base font-semibold transition-colors ${
                      isActive(link.href) ? 'text-[var(--foreground)]' : 'text-[var(--foreground)] group-hover:text-[var(--foreground)]'
                    }`}>
                      {link.label}
                    </div>
                    <div className="text-xs text-[var(--foreground-muted)]">
                      {link.desc}
                    </div>
                  </div>
                  <ChevronRight className={`w-5 h-5 text-[var(--foreground-subtle)] transition-all duration-300 ${
                    isActive(link.href) ? 'text-[var(--accent-primary)]' : 'group-hover:text-[var(--accent-primary)] group-hover:translate-x-1'
                  }`} />
                </Link>
              );
            })}

            {/* Divider */}
            <div className="pt-4 mt-4 border-t border-[var(--border)]" />

            {/* Mobile Actions */}
            <div className="space-y-3">
              {/* Sign In */}
              <Link
                href="/webapp"
                onClick={toggleMenu}
                className="flex items-center justify-center gap-2 px-4 py-4 rounded-2xl text-base font-medium text-[var(--foreground)] bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all touch-manipulation"
                style={{
                  minHeight: '56px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                <LogIn className="w-5 h-5" strokeWidth={2} />
                Sign In
              </Link>
              
              {/* Download Button */}
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                onClick={toggleMenu}
                className="group relative flex items-center justify-center gap-2 px-4 py-4 rounded-2xl text-base font-semibold text-white overflow-hidden transition-all duration-300 touch-manipulation"
                style={{
                  minHeight: '56px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-active:opacity-100 transition-opacity duration-200" />
                <Download className="w-5 h-5 relative z-10" strokeWidth={2.5} />
                <span className="relative z-10">Download FocusFlow</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
