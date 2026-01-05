'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { APP_STORE_URL, CONTACT_EMAIL, COMPANY_LOCATION, SITE_DESCRIPTION } from '@/lib/constants';
import { Download, Mail, MapPin, Sparkles, ArrowUpRight } from 'lucide-react';

export default function Footer() {
  const currentYear = new Date().getFullYear();
  const pathname = usePathname();
  
  const isActive = (path: string) => {
    if (path === '/') return pathname === '/';
    return pathname.startsWith(path);
  };

  const isPricingPage = isActive('/pricing');

  return (
    <footer className="relative border-t border-[var(--border)] bg-[var(--background-elevated)]">
      {/* Subtle gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-[var(--background)]/50 via-transparent to-transparent pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 md:px-6 lg:px-8">
        
        {/* Main Footer Content */}
        <div className="py-12 md:py-16 lg:py-20">
          <div className="grid md:grid-cols-12 gap-8 md:gap-12 lg:gap-16">
            
            {/* Brand Column - Takes more space */}
            <div className="md:col-span-5 lg:col-span-4">
              <Link 
                href="/" 
                className="group relative inline-flex items-center gap-2.5 md:gap-3 mb-6"
                onClick={() => {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                <div className="relative flex-shrink-0">
                  <div className="absolute -inset-1 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-lg blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <Image
                    src="/focusflow-logo.png"
                    alt="FocusFlow"
                    width={40}
                    height={40}
                    className="relative transition-transform duration-300 group-hover:scale-105"
                  />
                </div>
                <div className="relative min-w-0">
                  {/* Main text with gradient - matching header style */}
                  <span className="relative z-10 text-2xl font-bold tracking-tight block whitespace-nowrap">
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
                  <span className="absolute inset-0 text-2xl font-bold tracking-tight opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-sm whitespace-nowrap">
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
                  <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] group-hover:w-full transition-all duration-700 rounded-full" />
                </div>
              </Link>
              <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed mb-6 max-w-md font-light">
                {SITE_DESCRIPTION}
              </p>
              
              {/* Download CTA */}
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative inline-flex items-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-[var(--accent-primary)]/30 mb-6"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <Download className="w-4 h-4 relative z-10" strokeWidth={2.5} />
                <span className="relative z-10">Download on App Store</span>
              </a>

              {/* Location & Contact */}
              <div className="space-y-3">
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  className="flex items-center gap-2 text-sm text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors group"
                >
                  <Mail className="w-4 h-4" strokeWidth={2} />
                  <span>{CONTACT_EMAIL}</span>
                </a>
                <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
                  <MapPin className="w-4 h-4" strokeWidth={2} />
                  <span>{COMPANY_LOCATION}</span>
                </div>
              </div>
            </div>

            {/* Product Column */}
            <div className="md:col-span-2 lg:col-span-2">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-6 uppercase tracking-wider">
                Product
              </h3>
              <nav className="flex flex-col gap-3">
                <Link
                  href="/features"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Features
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
                <Link
                  href="/pricing"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Pricing
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Download
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </a>
              </nav>
            </div>

            {/* Company Column */}
            <div className="md:col-span-2 lg:col-span-2">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-6 uppercase tracking-wider">
                Company
              </h3>
              <nav className="flex flex-col gap-3">
                <Link
                  href="/about"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  About Us
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Contact
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </a>
                <Link
                  href="/webapp"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Sign In
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
              </nav>
            </div>

            {/* Legal Column */}
            <div className="md:col-span-3 lg:col-span-4">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-6 uppercase tracking-wider">
                Legal
              </h3>
              <nav className="flex flex-col gap-3">
                <Link
                  href="/privacy"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Privacy Policy
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
                <Link
                  href="/terms"
                  className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group"
                >
                  Terms of Service
                  <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" strokeWidth={2} />
                </Link>
              </nav>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="py-6 md:py-8 border-t border-[var(--border)]">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="text-sm text-[var(--foreground-muted)] font-light">
              © {currentYear} FocusFlow. Made by{' '}
              <span className="text-[var(--foreground)] font-medium">Soft Computers</span>. All rights reserved.
            </div>
            <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
              <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
              <span className="font-light">Built with intention</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
