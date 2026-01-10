'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { APP_STORE_URL, CONTACT_EMAIL, COMPANY_LOCATION, SITE_DESCRIPTION } from '@/lib/constants';
import { 
  ArrowDownTrayIcon, EnvelopeIcon, MapPinIcon, SparklesIcon, ArrowUpRightIcon, 
  HeartIcon, ClockIcon, CheckCircleIcon, ChartBarIcon, UserIcon,
  ShieldCheckIcon, BoltIcon, ArrowTopRightOnSquareIcon
} from '@heroicons/react/24/solid';

export default function Footer() {
  const currentYear = new Date().getFullYear();
  const pathname = usePathname();
  
  const isActive = (path: string) => {
    if (path === '/') return pathname === '/';
    return pathname.startsWith(path);
  };

  const isPricingPage = isActive('/pricing');

  // Footer link groups
  const productLinks = [
    { href: '/features', label: 'Features' },
    { href: '/pricing', label: 'Pricing' },
    { href: APP_STORE_URL, label: 'Download', external: true },
  ];

  const companyLinks = [
    { href: '/about', label: 'About Us' },
    { href: `mailto:${CONTACT_EMAIL}`, label: 'Contact', external: true },
    { href: '/support', label: 'Support' },
    { href: '/webapp', label: 'Sign In' },
  ];

  const legalLinks = [
    { href: '/privacy', label: 'Privacy Policy' },
    { href: '/terms', label: 'Terms of Service' },
  ];

  // Feature highlights for footer
  const highlights = [
    { icon: ClockIcon, label: 'Focus Timer' },
    { icon: CheckCircleIcon, label: 'Smart Tasks' },
    { icon: ChartBarIcon, label: 'Progress' },
    { icon: ShieldCheckIcon, label: 'Privacy First' },
  ];

  return (
    <footer className="relative border-t border-[var(--border)] bg-[var(--background-elevated)]">
      {/* Subtle gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[var(--background)]/50 pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Main Footer Content */}
        <div className="py-12 md:py-16 lg:py-20">
          <div className="grid grid-cols-2 md:grid-cols-12 gap-8 md:gap-10 lg:gap-16">
            
            {/* Brand Column */}
            <div className="col-span-2 md:col-span-5 lg:col-span-4">
              {/* Logo */}
              <Link 
                href="/" 
                className="group relative inline-flex items-center gap-3 mb-6"
                onClick={() => {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                <div className="relative flex-shrink-0">
                  <div className="absolute -inset-2 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-xl blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <Image
                    src="/focusflow-logo.png"
                    alt="FocusFlow"
                    width={44}
                    height={44}
                    className="relative transition-transform duration-300 group-hover:scale-105"
                  />
                </div>
                <div className="relative">
                  <span className="text-2xl font-bold tracking-tight block whitespace-nowrap">
                    <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                      Focus
                    </span>
                    <span className="bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient" style={{ animationDelay: '0.5s' }}>
                      Flow
                    </span>
                    {isPricingPage && (
                      <span className="ml-2 bg-gradient-to-r from-[#D4A853] via-[#F4D03F] to-[#D4A853] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                        Pro
                      </span>
                    )}
                  </span>
                </div>
              </Link>

              {/* Description */}
              <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed mb-6 max-w-sm">
                {SITE_DESCRIPTION}
              </p>
              
              {/* Download CTA */}
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative inline-flex items-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-[var(--accent-primary)]/25 mb-8"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <ArrowDownTrayIcon className="w-4 h-4 relative z-10" strokeWidth={2.5} />
                <span className="relative z-10">Download on App Store</span>
              </a>

              {/* Contact Info */}
              <div className="space-y-3">
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  className="flex items-center gap-2.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors group"
                >
                  <EnvelopeIcon className="w-4 h-4 group-hover:scale-110 transition-transform" strokeWidth={2} />
                  <span>{CONTACT_EMAIL}</span>
                </a>
                <div className="flex items-center gap-2.5 text-sm text-[var(--foreground-muted)]">
                  <MapPinIcon className="w-4 h-4" strokeWidth={2} />
                  <span>{COMPANY_LOCATION}</span>
                </div>
              </div>
            </div>

            {/* Product Links */}
            <div className="col-span-1 md:col-span-2">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">
                Product
              </h3>
              <nav className="flex flex-col gap-3">
                {productLinks.map((link) => (
                  link.external ? (
                    <a
                      key={link.href}
                      href={link.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="group flex items-center gap-1.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
                    >
                      {link.label}
                      <ArrowUpRightIcon className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" strokeWidth={2} />
                    </a>
                  ) : (
                    <Link
                      key={link.href}
                      href={link.href}
                      className="group flex items-center gap-1.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
                    >
                      {link.label}
                      <ArrowUpRightIcon className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" strokeWidth={2} />
                    </Link>
                  )
                ))}
              </nav>
            </div>

            {/* Company Links */}
            <div className="col-span-1 md:col-span-2">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">
                Company
              </h3>
              <nav className="flex flex-col gap-3">
                {companyLinks.map((link) => (
                  link.external ? (
                    <a
                      key={link.href}
                      href={link.href}
                      target={link.href.startsWith('mailto:') ? undefined : '_blank'}
                      rel={link.href.startsWith('mailto:') ? undefined : 'noopener noreferrer'}
                      className="group flex items-center gap-1.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
                    >
                      {link.label}
                      <ArrowUpRightIcon className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" strokeWidth={2} />
                    </a>
                  ) : (
                    <Link
                      key={link.href}
                      href={link.href}
                      className="group flex items-center gap-1.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
                    >
                      {link.label}
                      <ArrowUpRightIcon className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" strokeWidth={2} />
                    </Link>
                  )
                ))}
              </nav>
            </div>

            {/* Legal Links + Highlights */}
            <div className="col-span-2 md:col-span-3 lg:col-span-4">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">
                Legal
              </h3>
              <nav className="flex flex-col gap-3 mb-8">
                {legalLinks.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="group flex items-center gap-1.5 text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
                  >
                    {link.label}
                    <ArrowUpRightIcon className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" strokeWidth={2} />
                  </Link>
                ))}
              </nav>

              {/* Feature Highlights */}
              <div className="hidden md:block">
                <h4 className="text-xs font-medium text-[var(--foreground-subtle)] mb-3 uppercase tracking-wider">
                  Features
                </h4>
                <div className="flex flex-wrap gap-2">
                  {highlights.map((item, i) => {
                    const IconComponent = item.icon;
                    return (
                      <div 
                        key={i}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[var(--background)] border border-[var(--border)] text-xs text-[var(--foreground-muted)]"
                      >
                        <IconComponent className="w-3 h-3 text-[var(--accent-primary)]" />
                        {item.label}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="py-6 md:py-8 border-t border-[var(--border)]">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="text-sm text-[var(--foreground-muted)] text-center md:text-left">
              © {currentYear} FocusFlow. Made by{' '}
              <span className="text-[var(--foreground)] font-medium">Soft Computers</span>. All rights reserved.
            </div>
            <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
              <HeartIcon className="w-4 h-4 text-rose-400 animate-pulse-slow" fill="currentColor" strokeWidth={0} />
              <span>Built with intention</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
