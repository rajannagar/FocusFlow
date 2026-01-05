'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';
import { Clock, Sparkles, Download, ArrowLeft } from 'lucide-react';

export default function WebAppClient() {
  const mousePosition = useThrottledMouse();
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -100px 0px',
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-fade-in');
        }
      });
    }, observerOptions);

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => {
      if (sectionRef.current) {
        observer.unobserve(sectionRef.current);
      }
    };
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* Hero Section */}
      <section 
        ref={sectionRef}
        className="relative py-12 md:py-16 lg:py-20 overflow-hidden"
      >
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/3 left-1/4 w-[500px] md:w-[1000px] h-[500px] md:h-[1000px] rounded-full blur-[120px] md:blur-[200px] opacity-[0.06] transition-transform duration-[4000ms] ease-out"
            style={{
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
              background: `radial-gradient(circle, var(--accent-primary) 0%, transparent 70%)`,
            }}
          />
          <div 
            className="absolute bottom-1/4 right-1/4 w-[400px] md:w-[800px] h-[400px] md:h-[800px] rounded-full blur-[100px] md:blur-[180px] opacity-[0.04] transition-transform duration-[5000ms] ease-out"
            style={{
              transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
              background: `radial-gradient(circle, var(--accent-secondary) 0%, transparent 70%)`,
            }}
          />
        </div>

        <Container>
          <div className="relative z-10 max-w-3xl mx-auto text-center px-4">
            {/* Icon */}
            <div className="relative inline-flex mb-6 md:mb-8">
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 rounded-2xl blur-xl" />
              <div className="relative bg-[var(--background-elevated)] border border-[var(--border)] rounded-2xl p-6">
                <Clock className="w-12 h-12 text-[var(--accent-primary)]" strokeWidth={1.5} />
              </div>
            </div>

            {/* Title */}
            <h1 className="text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold mb-4 md:mb-6 leading-tight">
              <span className="bg-gradient-to-r from-[var(--foreground)] via-[var(--accent-primary)] to-[var(--foreground)] bg-clip-text text-transparent bg-[length:200%_100%] animate-gradient">
                Web App Coming Soon
              </span>
            </h1>

            {/* Description */}
            <p className="text-base md:text-lg lg:text-xl text-[var(--foreground-muted)] mb-8 md:mb-12 max-w-2xl mx-auto leading-relaxed px-4">
              We're working hard to bring you the full FocusFlow experience on the web. 
              Stay tuned for updates!
            </p>

            {/* Features Preview */}
            <div className="grid sm:grid-cols-2 md:grid-cols-3 gap-4 md:gap-6 mt-8 md:mt-12 mb-8 md:mb-12">
              <div className="bg-[var(--background-elevated)] border border-[var(--border)] rounded-xl p-5 md:p-6 text-left">
                <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 flex items-center justify-center mb-4">
                  <Sparkles className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={2} />
                </div>
                <h3 className="font-semibold text-[var(--foreground)] mb-2 text-base">Full Feature Set</h3>
                <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">
                  All the powerful features from the iOS app, optimized for web
                </p>
              </div>

              <div className="bg-[var(--background-elevated)] border border-[var(--border)] rounded-xl p-5 md:p-6 text-left">
                <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 flex items-center justify-center mb-4">
                  <Clock className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={2} />
                </div>
                <h3 className="font-semibold text-[var(--foreground)] mb-2 text-base">Cloud Sync</h3>
                <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">
                  Seamlessly sync your data across all your devices
                </p>
              </div>

              <div className="bg-[var(--background-elevated)] border border-[var(--border)] rounded-xl p-5 md:p-6 text-left sm:col-span-2 md:col-span-1">
                <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 flex items-center justify-center mb-4">
                  <Download className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={2} />
                </div>
                <h3 className="font-semibold text-[var(--foreground)] mb-2 text-base">Cross-Platform</h3>
                <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">
                  Access FocusFlow from any device, anywhere
                </p>
              </div>
            </div>

            {/* CTA */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-8 md:mt-12">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative px-6 py-3 rounded-xl text-base font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-[var(--accent-primary)]/30 w-full sm:w-auto"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div className="relative z-10 flex items-center justify-center gap-2">
                  <Download className="w-5 h-5" strokeWidth={2.5} />
                  <span>Download iOS App</span>
                </div>
              </a>
              <Link
                href="/"
                className="px-6 py-3 rounded-xl text-base font-medium text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)] transition-all duration-300 w-full sm:w-auto text-center"
              >
                Learn More
              </Link>
            </div>

            {/* Back to Home */}
            <div className="flex justify-center mt-6 md:mt-8">
              <Link
                href="/"
                className="inline-flex items-center gap-2 text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors group"
              >
                <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
                <span className="text-sm font-medium">Back to Home</span>
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}

