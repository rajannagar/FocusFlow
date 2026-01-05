'use client';

import Link from 'next/link';
import { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { ThemeToggle } from '@/components/common';
import { APP_STORE_URL } from '@/lib/constants';
import { Menu, X, Download, LogIn } from 'lucide-react';

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

  // Navigation links - reordered for better UX
  const navLinks = [
    { href: '/', label: 'Home' },
    { href: '/features', label: 'Features' },
    { href: '/pricing', label: 'Pricing' },
    { href: '/about', label: 'About' },
  ];

  const toggleMenu = () => {
    setIsMenuOpen((prev) => !prev);
  };

  return (
    <>
      {/* Header */}
      <header
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled
            ? 'bg-[var(--background)]/95 backdrop-blur-md border-b border-[var(--border)] shadow-sm'
            : 'bg-transparent border-b border-transparent'
        }`}
        style={{
          paddingTop: 'env(safe-area-inset-top, 0px)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 sm:h-20 md:h-20 items-center justify-between">
            {/* Logo */}
            <Link
              href="/"
              className="flex items-center gap-2 sm:gap-3 group"
              onClick={() => {
                if (pathname === '/') {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }
              }}
            >
              <div className="relative flex-shrink-0">
                <Image
                  src="/focusflow-logo.png"
                  alt="FocusFlow"
                  width={32}
                  height={32}
                  className="w-7 h-7 sm:w-8 sm:h-8 md:w-9 md:h-9 transition-transform duration-300 group-hover:scale-105"
                  priority
                />
              </div>
              <div className="relative">
                <span className="text-base sm:text-lg md:text-xl lg:text-2xl font-bold tracking-tight block whitespace-nowrap">
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
                    <span className="ml-1 sm:ml-2 bg-gradient-to-r from-[#D4A853] via-[#F4D03F] via-[#F7DC6F] to-[#D4A853] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
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
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                    isActive(link.href)
                      ? 'text-[var(--foreground)] bg-[var(--background-elevated)]'
                      : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50'
                  }`}
                >
                  {link.label}
                </Link>
              ))}
            </nav>

            {/* Desktop Actions */}
            <div className="hidden lg:flex items-center gap-3">
              <Link
                href="/webapp"
                className="px-4 py-2 rounded-lg text-sm font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50 transition-all duration-200 flex items-center gap-2"
              >
                <LogIn className="w-4 h-4" strokeWidth={2} />
                <span>Sign In</span>
              </Link>
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative px-5 py-2.5 rounded-lg text-sm font-semibold text-white overflow-hidden transition-all duration-200 hover:scale-[1.02]"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                <div className="relative z-10 flex items-center gap-2">
                  <Download className="w-4 h-4" strokeWidth={2.5} />
                  <span>Download</span>
                </div>
              </a>
              <ThemeToggle />
            </div>

            {/* Mobile Menu Button */}
            <button
              ref={menuButtonRef}
              onClick={toggleMenu}
              className="lg:hidden p-2 rounded-lg text-[var(--foreground)] hover:bg-[var(--background-elevated)] active:bg-[var(--background-elevated)] transition-colors touch-manipulation"
              aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
              aria-expanded={isMenuOpen}
              style={{
                minWidth: '44px',
                minHeight: '44px',
                WebkitTapHighlightColor: 'transparent',
              }}
            >
              {isMenuOpen ? (
                <X className="w-6 h-6" strokeWidth={2} />
              ) : (
                <Menu className="w-6 h-6" strokeWidth={2} />
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Menu Overlay */}
      {isMenuOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 backdrop-blur-sm z-40 transition-opacity duration-300"
          onClick={toggleMenu}
          aria-hidden="true"
          style={{
            top: 'calc(env(safe-area-inset-top, 0px) + 4rem)',
          }}
        />
      )}

      {/* Mobile Menu */}
      <div
        data-mobile-menu
        className={`lg:hidden fixed left-0 right-0 z-50 bg-[var(--background)] border-t border-[var(--border)] transition-transform duration-300 ease-out ${
          isMenuOpen ? 'translate-y-0' : '-translate-y-full'
        }`}
        style={{
          top: 'calc(env(safe-area-inset-top, 0px) + 4rem)',
          maxHeight: 'calc(100vh - env(safe-area-inset-top, 0px) - 4rem)',
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        }}
      >
        <div className="overflow-y-auto overscroll-contain" style={{ maxHeight: 'calc(100vh - env(safe-area-inset-top, 0px) - 4rem - env(safe-area-inset-bottom, 0px))' }}>
          <div className="px-4 py-6 space-y-2">
            {/* Navigation Links */}
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={toggleMenu}
                className={`block px-4 py-3.5 rounded-lg text-base font-medium transition-all touch-manipulation ${
                  isActive(link.href)
                    ? 'text-[var(--foreground)] bg-[var(--background-elevated)]'
                    : 'text-[var(--foreground-muted)] active:text-[var(--foreground)] active:bg-[var(--background-elevated)]'
                }`}
                style={{
                  minHeight: '44px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                {link.label}
              </Link>
            ))}

            {/* Mobile Actions */}
            <div className="pt-6 mt-6 border-t border-[var(--border)] space-y-3">
              <Link
                href="/webapp"
                onClick={toggleMenu}
                className="flex items-center justify-center gap-2 px-4 py-3.5 rounded-lg text-base font-medium text-[var(--foreground-muted)] active:text-[var(--foreground)] active:bg-[var(--background-elevated)] transition-all touch-manipulation"
                style={{
                  minHeight: '44px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                <LogIn className="w-5 h-5" strokeWidth={2} />
                Sign In
              </Link>
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                onClick={toggleMenu}
                className="group relative flex items-center justify-center gap-2 px-4 py-3.5 rounded-lg text-base font-semibold text-white overflow-hidden transition-all duration-200 touch-manipulation"
                style={{
                  minHeight: '44px',
                  WebkitTapHighlightColor: 'transparent',
                }}
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-active:opacity-100 transition-opacity duration-200" />
                <Download className="w-5 h-5 relative z-10" strokeWidth={2.5} />
                <span className="relative z-10">Download FocusFlow</span>
              </a>
              <div
                className="flex items-center justify-between px-4 py-3 rounded-lg bg-[var(--background-elevated)] touch-manipulation"
                style={{ minHeight: '44px' }}
              >
                <span className="text-sm font-medium text-[var(--foreground-muted)]">Theme</span>
                <ThemeToggle />
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
