'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { ThemeToggle } from '@/components/common';
import { APP_STORE_URL } from '@/lib/constants';
import { Menu, X, Download, LogIn } from 'lucide-react';

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
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
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isMenuOpen]);

  const isActive = (path: string) => {
    if (path === '/') return pathname === '/';
    return pathname.startsWith(path);
  };

  const isPricingPage = isActive('/pricing');

  const navLinks = [
    { href: '/', label: 'Home' },
    { href: '/features', label: 'Features' },
    { href: '/pricing', label: 'Pricing' },
    { href: '/about', label: 'About' },
  ];

  return (
    <header 
      className={`fixed top-0 left-0 right-0 z-[10002] transition-all duration-500 ${
        scrolled 
          ? 'bg-[var(--background)]/80 backdrop-blur-xl border-b border-[var(--border)] shadow-lg shadow-black/5' 
          : 'bg-transparent border-b border-transparent'
      }`}
      style={{
        paddingTop: 'env(safe-area-inset-top, 0px)',
      }}
    >
      <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8 relative">
        <div className="flex h-16 md:h-20 items-center justify-between gap-2 md:gap-4 relative">
          
          {/* Logo */}
          <Link 
            href="/" 
            className="group relative flex items-center gap-2 md:gap-3 z-50 min-w-0 flex-shrink"
            onClick={() => {
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
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
            <div className="relative min-w-0">
              {/* Main text with gradient - responsive sizing */}
              <span className="relative z-10 text-lg md:text-xl lg:text-2xl font-bold tracking-tight block whitespace-nowrap">
                <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                  Focus
                </span>
                <span className="bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient" style={{ animationDelay: '0.5s' }}>
                  Flow
                </span>
                {isPricingPage && (
                  <span className="ml-2 bg-gradient-to-r from-[#D4A853] via-[#F4D03F] via-[#F7DC6F] to-[#D4A853] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                    Pro
                  </span>
                )}
              </span>
              {/* Glow effect on hover */}
              <span className="absolute inset-0 text-lg md:text-xl lg:text-2xl font-bold tracking-tight opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-sm whitespace-nowrap">
                <span className="bg-gradient-to-r from-[var(--accent-primary)]/60 via-[var(--accent-secondary)]/60 to-[var(--accent-primary)]/60 bg-clip-text text-transparent">
                  Focus
                </span>
                <span className="bg-gradient-to-r from-[var(--accent-secondary)]/60 via-[var(--accent-primary)]/60 to-[var(--accent-secondary)]/60 bg-clip-text text-transparent">
                  Flow
                </span>
                {isPricingPage && (
                  <span className="ml-2 bg-gradient-to-r from-[#D4A853]/60 via-[#F4D03F]/60 to-[#D4A853]/60 bg-clip-text text-transparent">
                    Pro
                  </span>
                )}
              </span>
              {/* Animated underline accent */}
              <span className="absolute -bottom-1 md:-bottom-1.5 left-0 w-0 h-0.5 bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] group-hover:w-full transition-all duration-700 rounded-full" />
            </div>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`relative px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-300 ${
                  isActive(link.href)
                    ? 'text-[var(--foreground)] bg-[var(--background-elevated)]' 
                    : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50'
                }`}
                onClick={() => {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                {link.label}
                {isActive(link.href) && (
                  <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-[var(--accent-primary)]" />
                )}
              </Link>
            ))}
          </nav>

          {/* Desktop Actions */}
          <div className="hidden md:flex items-center gap-3">
            <Link
              href="/webapp"
              className="px-5 py-2.5 rounded-xl text-sm font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]/50 transition-all duration-300 flex items-center gap-2"
            >
              <LogIn className="w-4 h-4" strokeWidth={2} />
              Sign In
            </Link>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="group relative px-5 py-2.5 rounded-xl text-sm font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-[var(--accent-primary)]/30"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <div className="relative z-10 flex items-center gap-2">
                <Download className="w-4 h-4" strokeWidth={2.5} />
                <span>Download</span>
              </div>
            </a>
            <ThemeToggle />
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setIsMenuOpen((prev) => !prev);
            }}
            onTouchStart={(e) => {
              e.stopPropagation();
            }}
            className="md:hidden relative p-2.5 rounded-xl hover:bg-[var(--background-elevated)] active:bg-[var(--background-elevated)] transition-colors text-[var(--foreground)] z-[10003] touch-manipulation"
            aria-label="Menu"
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

        {/* Mobile Menu */}
        <div 
          className={`md:hidden fixed top-16 left-0 right-0 bottom-0 bg-[var(--background)] border-t border-[var(--border)] transition-transform duration-300 ease-out z-[10001] ${
            isMenuOpen 
              ? 'translate-y-0 pointer-events-auto' 
              : '-translate-y-full pointer-events-none'
          }`}
          style={{
            paddingTop: 'env(safe-area-inset-top, 0px)',
          }}
        >
          <div className="h-full overflow-y-auto">
            <div className="px-4 py-6 space-y-2">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`block px-4 py-3.5 rounded-xl text-base font-medium transition-all ${
                    isActive(link.href)
                      ? 'text-[var(--foreground)] bg-[var(--background-elevated)]' 
                      : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)]'
                  }`}
                  onClick={() => {
                    setIsMenuOpen(false);
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                >
                  {link.label}
                </Link>
              ))}
              
              {/* Mobile Actions */}
              <div className="pt-6 mt-6 border-t border-[var(--border)] space-y-3">
                <Link
                  href="/webapp"
                  className="flex items-center justify-center gap-2 px-4 py-3.5 rounded-xl text-base font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)] transition-all"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <LogIn className="w-5 h-5" strokeWidth={2} />
                  Sign In
                </Link>
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group relative flex items-center justify-center gap-2 px-4 py-3.5 rounded-xl text-base font-semibold text-white overflow-hidden transition-all duration-300"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                  <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <Download className="w-5 h-5 relative z-10" strokeWidth={2.5} />
                  <span className="relative z-10">Download FocusFlow</span>
                </a>
                <div className="flex items-center justify-between px-4 py-3 rounded-xl bg-[var(--background-elevated)]">
                  <span className="text-sm font-medium text-[var(--foreground-muted)]">Theme</span>
                  <ThemeToggle />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
