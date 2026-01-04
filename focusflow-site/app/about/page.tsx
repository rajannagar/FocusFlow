'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL, CONTACT_EMAIL } from '@/lib/constants';
import { Palette, Code, Sparkles, Mail, Download } from 'lucide-react';

export default function AboutPage() {
  const mousePosition = useThrottledMouse();
  const sectionRefs = useRef<(HTMLElement | null)[]>([]);

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

    sectionRefs.current.forEach((ref) => {
      if (ref) observer.observe(ref);
    });

    return () => {
      sectionRefs.current.forEach((ref) => {
        if (ref) observer.unobserve(ref);
      });
    };
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO - Premium & Beautiful
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-24 md:pt-32 pb-16 md:pb-24 overflow-hidden">
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/3 left-1/4 w-[500px] md:w-[1000px] h-[500px] md:h-[1000px] rounded-full blur-[120px] md:blur-[200px] opacity-[0.06] transition-transform duration-[4000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.6) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.008}px, ${mousePosition.y * 0.008}px)`,
            }}
          />
          <div 
            className="absolute bottom-1/3 right-1/4 w-[400px] md:w-[800px] h-[400px] md:h-[800px] rounded-full blur-[100px] md:blur-[180px] opacity-[0.04] transition-transform duration-[4000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(212, 168, 83, 0.5) 0%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.006}px, ${-mousePosition.y * 0.006}px)`,
            }}
          />
        </div>
        <div className="absolute inset-0 bg-grid opacity-[0.02]" />

        <Container>
          <div className="relative z-10 max-w-6xl mx-auto px-4 md:px-6">
            <div className="flex flex-col items-center text-center">
              <div className="relative mb-8 md:mb-12">
                <div className="absolute -inset-8 bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 rounded-[50px] blur-3xl" />
                <Image
                  src="/focusflow-app-icon.jpg"
                  alt="FocusFlow - Be Present"
                  width={140}
                  height={140}
                  className="relative rounded-[36px] shadow-2xl"
                  style={{
                    boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4)'
                  }}
                />
              </div>
              <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold mb-6 md:mb-8 leading-tight">
                About <span className="text-gradient">FocusFlow</span>
              </h1>
              <p className="text-xl md:text-2xl lg:text-3xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-3xl mx-auto">
                The story behind the app that helps you be present, stay focused, and build better habits.
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHY FOCUSFLOW - Flowing Narrative
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[0] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Subtle gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-[var(--accent-primary)]/5 via-transparent to-transparent pointer-events-none" />
        
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-5xl mx-auto px-4 md:px-6">
            <div className="mb-12 md:mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-6">
                <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" />
                <span>Our Story</span>
              </div>
              <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-8 md:mb-12 leading-tight">
                Why <span className="text-gradient">FocusFlow?</span>
              </h2>
            </div>

            <div className="space-y-8 md:space-y-12">
              <div className="relative">
                <div className="absolute -left-4 md:-left-8 top-0 bottom-0 w-1 bg-gradient-to-b from-[var(--accent-primary)] to-[var(--accent-secondary)] rounded-full opacity-30" />
                <div className="pl-8 md:pl-12">
                  <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    FocusFlow was born from a simple observation: most productivity apps are either too complex, too distracting, or too focused on a single feature. We wanted something different—an app that combines the best parts of focus timers, task management, and progress tracking into one beautiful, cohesive experience.
                  </p>
                </div>
              </div>

              <div className="relative">
                <div className="absolute -left-4 md:-left-8 top-0 bottom-0 w-1 bg-gradient-to-b from-[var(--accent-primary)] to-[var(--accent-secondary)] rounded-full opacity-30" />
                <div className="pl-8 md:pl-12">
                  <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    The name "FocusFlow" reflects our core philosophy: when you're truly focused, work flows naturally. The app is designed to help you enter that state of deep work, maintain it, and track your progress over time. Every feature—from the ambient backgrounds to the XP system—is crafted to support this goal.
                  </p>
                </div>
              </div>

              <div className="relative">
                <div className="absolute -left-4 md:-left-8 top-0 bottom-0 w-1 bg-gradient-to-b from-[var(--accent-primary)] to-[var(--accent-secondary)] rounded-full opacity-30" />
                <div className="pl-8 md:pl-12">
                  <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    We believe that productivity tools should be beautiful, private, and respectful of your attention. That's why FocusFlow has no ads, no tracking, and no unnecessary notifications. It's just you, your work, and the tools you need to stay focused.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          THE TEAM - Creative Layout
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[1] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-5xl mx-auto px-4 md:px-6">
            <div className="text-center mb-12 md:mb-16">
              <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">The Team</h2>
            </div>
            
            <div className="grid md:grid-cols-3 gap-8 md:gap-12 mb-12 md:mb-16">
              <div className="text-center group">
                <div className="w-20 h-20 md:w-24 md:h-24 rounded-full bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 mx-auto mb-6 flex items-center justify-center group-hover:scale-110 transition-transform shadow-lg">
                  <Palette className="w-10 h-10 md:w-12 md:h-12 text-[var(--accent-primary)]" strokeWidth={1.5} />
                </div>
                <h3 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-3">Design</h3>
                <p className="text-[var(--foreground-muted)] leading-relaxed">
                  Crafting beautiful, intuitive experiences
                </p>
              </div>
              <div className="text-center group">
                <div className="w-20 h-20 md:w-24 md:h-24 rounded-full bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 mx-auto mb-6 flex items-center justify-center group-hover:scale-110 transition-transform shadow-lg">
                  <Code className="w-10 h-10 md:w-12 md:h-12 text-[var(--accent-primary)]" strokeWidth={1.5} />
                </div>
                <h3 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-3">Engineering</h3>
                <p className="text-[var(--foreground-muted)] leading-relaxed">
                  Building robust, performant software
                </p>
              </div>
              <div className="text-center group">
                <div className="w-20 h-20 md:w-24 md:h-24 rounded-full bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 mx-auto mb-6 flex items-center justify-center group-hover:scale-110 transition-transform shadow-lg">
                  <Sparkles className="w-10 h-10 md:w-12 md:h-12 text-[var(--accent-primary)]" strokeWidth={1.5} />
                </div>
                <h3 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-3">Product</h3>
                <p className="text-[var(--foreground-muted)] leading-relaxed">
                  Shaping the future of focus tools
                </p>
              </div>
            </div>

            <div className="text-center space-y-6 text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
              <p>
                FocusFlow is built by a small, passionate team of designers and developers who care deeply about creating tools that help people do their best work. We're a diverse group with backgrounds in software engineering, product design, and user experience.
              </p>
              <p>
                We're committed to building software that is both beautiful and functional. Every pixel, every animation, and every interaction is carefully considered to create an experience that feels natural and delightful to use.
              </p>
              <p>
                Our team is distributed, working from different parts of the world, but united by a shared vision: to help people focus, be present, and build better habits through thoughtful design and technology.
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          SOFT COMPUTERS - Elegant Mention
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[2] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto px-4 md:px-6">
            <div className="relative p-12 md:p-16 rounded-3xl bg-gradient-to-br from-[var(--accent-primary)]/10 via-[var(--background-elevated)] to-[var(--accent-secondary)]/10 border border-[var(--border)] text-center">
              <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--accent-primary)]/50 to-transparent" />
              <h3 className="text-3xl md:text-4xl font-bold text-[var(--foreground)] mb-6">Built by Soft Computers</h3>
              <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-2xl mx-auto">
                FocusFlow is proudly built by <strong className="text-[var(--foreground)] font-semibold">Soft Computers</strong>, a software company dedicated to creating premium, privacy-focused applications that help people do meaningful work, calmly and consistently, with intention.
              </p>
              <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--accent-secondary)]/50 to-transparent" />
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          CONTACT & FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-24 bg-[var(--background-elevated)]">
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto text-center px-4 md:px-6">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">
              Have questions or <span className="text-gradient">feedback?</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 md:mb-16 leading-relaxed font-light">
              We'd love to hear from you. Reach out anytime.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href={`mailto:${CONTACT_EMAIL}`}
                className="group relative px-8 md:px-10 py-4 md:py-5 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg md:text-xl overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/30"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div className="relative z-10 flex items-center justify-center gap-3">
                  <Mail className="w-6 h-6" strokeWidth={2} />
                  <span>Contact Us</span>
                </div>
              </a>
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative px-8 md:px-10 py-4 md:py-5 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg md:text-xl hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background)] transition-all duration-300 flex items-center justify-center gap-3"
              >
                <Download className="w-6 h-6" strokeWidth={2} />
                <span>Download FocusFlow</span>
              </a>
            </div>
          </div>
        </Container>
      </section>

      <style jsx>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        .animate-fade-in {
          animation: fadeIn 0.8s ease-out forwards;
        }
      `}</style>
    </div>
  );
}
