'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL, CONTACT_EMAIL } from '@/lib/constants';
import { 
  SwatchIcon, CodeBracketIcon, SparklesIcon, EnvelopeIcon, ArrowDownTrayIcon, HeartIcon, ShieldCheckIcon, 
  ClockIcon, TagIcon, UsersIcon, ArrowRightIcon, StarIcon, BoltIcon, LockClosedIcon, EyeIcon
} from '@heroicons/react/24/solid';

// Animated section wrapper
const AnimatedSection = ({ 
  children, 
  className = '',
  delay = 0
}: { 
  children: React.ReactNode; 
  className?: string;
  delay?: number;
}) => {
  const ref = useRef<HTMLElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setTimeout(() => setIsVisible(true), delay);
        }
      },
      { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [delay]);

  return (
    <section 
      ref={ref}
      className={`transition-all duration-1000 ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'} ${className}`}
    >
      {children}
    </section>
  );
};

export default function AboutClient() {
  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO - Cinematic & Personal
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[70vh] flex items-center justify-center overflow-hidden pt-24 pb-12">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/4 left-1/3 w-[800px] h-[800px] rounded-full blur-[200px] opacity-[0.08] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `conic-gradient(from 180deg, rgba(139, 92, 246, 0.8), rgba(212, 168, 83, 0.6), rgba(139, 92, 246, 0.8))`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
        </div>
        
        <div className="absolute inset-0 bg-grid opacity-[0.02]" />

        <Container>
          <div className="relative z-10 max-w-5xl mx-auto text-center">
            {/* App icon with glow */}
            <div className="relative mb-10 inline-block">
              <div className="absolute -inset-8 bg-gradient-to-br from-[var(--accent-primary)]/40 to-[var(--accent-secondary)]/30 rounded-[60px] blur-3xl animate-pulse-slow" />
              <Image
                src="/focusflow-app-icon.jpg"
                alt="FocusFlow - Be Present"
                width={160}
                height={160}
                className="relative rounded-[40px] shadow-2xl"
                style={{
                  boxShadow: '0 25px 80px rgba(0, 0, 0, 0.5)'
                }}
              />
            </div>
            
            <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold mb-8 leading-[0.95]">
              <span className="text-[var(--foreground)]">Built with</span>
              <br />
              <span className="text-gradient">intention.</span>
            </h1>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto font-light">
              FocusFlow isn't just another productivity app. It's a philosophy — that when you're truly present, 
              work flows naturally.
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          THE STORY - Emotional Narrative
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-[var(--accent-primary)]/20 to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 text-[var(--accent-primary)] text-sm mb-6">
                <HeartIcon className="w-4 h-4" />
                <span>Our Story</span>
              </div>
              <h2 className="text-4xl md:text-6xl font-bold">
                Why we built <span className="text-gradient">FocusFlow</span>
              </h2>
            </div>

            <div className="space-y-12">
              {/* Story blocks */}
              <div className="relative pl-8 border-l-2 border-[var(--accent-primary)]/30">
                <div className="absolute -left-3 top-0 w-6 h-6 rounded-full bg-[var(--accent-primary)] flex items-center justify-center">
                  <span className="text-white text-xs font-bold">1</span>
                </div>
                <h3 className="text-2xl font-bold text-[var(--foreground)] mb-4">The Problem</h3>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  Most productivity apps are either too complex, too distracting, or too focused on a single feature. 
                  They add to the noise instead of cutting through it. We wanted something different.
                </p>
              </div>

              <div className="relative pl-8 border-l-2 border-[var(--accent-secondary)]/30">
                <div className="absolute -left-3 top-0 w-6 h-6 rounded-full bg-[var(--accent-secondary)] flex items-center justify-center">
                  <span className="text-white text-xs font-bold">2</span>
                </div>
                <h3 className="text-2xl font-bold text-[var(--foreground)] mb-4">The Vision</h3>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  We envisioned an app that combines the best parts of focus timers, task management, and 
                  progress tracking — all in one beautiful, cohesive experience. No clutter, no distractions.
                </p>
              </div>

              <div className="relative pl-8 border-l-2 border-emerald-500/30">
                <div className="absolute -left-3 top-0 w-6 h-6 rounded-full bg-emerald-500 flex items-center justify-center">
                  <span className="text-white text-xs font-bold">3</span>
                </div>
                <h3 className="text-2xl font-bold text-[var(--foreground)] mb-4">The Result</h3>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  FocusFlow was born. Every feature — from the ambient backgrounds to the XP system to the AI assistant — 
                  is crafted to help you enter a state of deep work, maintain it, and track your progress over time.
                </p>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          OUR VALUES
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold mb-4">
                What we <span className="text-gradient">believe</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)]">The principles that guide everything we build</p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
              {[
                {
                  icon: EyeIcon,
                  title: 'Presence Over Productivity',
                  desc: 'True productivity comes from being fully present. We design for focus, not just output.',
                  color: 'from-violet-500 to-purple-600'
                },
                {
                  icon: LockClosedIcon,
                  title: 'Privacy First',
                  desc: 'No ads, no tracking, no selling your data. Your focus journey is yours alone.',
                  color: 'from-emerald-500 to-teal-600'
                },
                {
                  icon: SparklesIcon,
                  title: 'Beauty Matters',
                  desc: 'When your tools are beautiful, you want to use them. Design is functional.',
                  color: 'from-amber-500 to-orange-600'
                },
                {
                  icon: HeartIcon,
                  title: 'Respect Attention',
                  desc: 'Every notification, every interaction is carefully considered. Your attention is sacred.',
                  color: 'from-rose-500 to-pink-600'
                },
                {
                  icon: BoltIcon,
                  title: 'Simplicity Wins',
                  desc: 'Complex problems deserve elegant solutions. We obsess over making things simple.',
                  color: 'from-cyan-500 to-blue-600'
                },
                {
                  icon: UsersIcon,
                  title: 'Community Driven',
                  desc: 'Built with constant user feedback. Your voice shapes our roadmap.',
                  color: 'from-indigo-500 to-violet-600'
                },
              ].map((value, i) => (
                <div 
                  key={i}
                  className="group relative p-8 rounded-3xl bg-[var(--background)] border border-[var(--border)] hover:border-transparent transition-all duration-300"
                >
                  <div className={`absolute inset-0 rounded-3xl bg-gradient-to-br ${value.color} opacity-0 group-hover:opacity-[0.08] transition-opacity duration-300`} />
                  
                  <div className="relative z-10">
                    <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${value.color} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg`}>
                      <value.icon className="w-7 h-7 text-white" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-xl font-bold text-[var(--foreground)] mb-3">{value.title}</h3>
                    <p className="text-[var(--foreground-muted)] leading-relaxed">{value.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          THE TEAM
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-6xl font-bold mb-4">
                The <span className="text-gradient">team</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto">
                A small, passionate team united by a shared mission: helping people focus and build better habits.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8 mb-16">
              {[
                { icon: SwatchIcon, title: 'Design', desc: 'Crafting beautiful, intuitive experiences that feel natural' },
                { icon: CodeBracketIcon, title: 'Engineering', desc: 'Building robust, performant software with attention to detail' },
                { icon: SparklesIcon, title: 'Product', desc: 'Shaping the future of focus tools through user research' },
              ].map((role, i) => (
                <div key={i} className="text-center group">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 mx-auto mb-6 flex items-center justify-center group-hover:scale-110 transition-transform border border-[var(--accent-primary)]/30">
                    <role.icon className="w-10 h-10 text-[var(--accent-primary)]" strokeWidth={1.5} />
                  </div>
                  <h3 className="text-xl font-bold text-[var(--foreground)] mb-2">{role.title}</h3>
                  <p className="text-[var(--foreground-muted)]">{role.desc}</p>
                </div>
              ))}
            </div>

            <div className="text-center p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)]">
              <p className="text-lg text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto">
                We're a distributed team working from different parts of the world, but united by a shared vision: 
                to help people focus, be present, and build better habits through thoughtful design and technology. 
                Every pixel, every animation, and every interaction is carefully considered.
              </p>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          SOFT COMPUTERS
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-gradient-to-b from-[var(--background-elevated)] via-[var(--accent-primary)]/5 to-[var(--background-elevated)]">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="relative p-12 md:p-16 rounded-3xl bg-[var(--background)] border border-[var(--border)] text-center overflow-hidden">
              {/* Decorative gradients */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)]" />
              <div className="absolute -top-20 -right-20 w-40 h-40 bg-[var(--accent-primary)]/10 rounded-full blur-3xl" />
              <div className="absolute -bottom-20 -left-20 w-40 h-40 bg-[var(--accent-secondary)]/10 rounded-full blur-3xl" />
              
              <div className="relative z-10">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 text-[var(--accent-primary)] text-sm mb-6">
                  <StarIcon className="w-4 h-4" />
                  <span>Our Company</span>
                </div>
                
                <h3 className="text-3xl md:text-4xl font-bold text-[var(--foreground)] mb-6">
                  Built by <span className="text-gradient">Soft Computers</span>
                </h3>
                
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-2xl mx-auto">
                  A software company dedicated to creating premium, privacy-focused applications 
                  that help people do meaningful work — calmly, consistently, and with intention.
                </p>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-24 md:py-32">
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-6xl font-bold mb-6">
              Have questions or <span className="text-gradient">feedback?</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 font-light">
              We'd love to hear from you. Your feedback shapes our roadmap.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href={`mailto:${CONTACT_EMAIL}`}
                className="group relative px-10 py-5 rounded-2xl bg-[var(--foreground)] text-[var(--background)] font-semibold text-xl overflow-hidden transition-all duration-500 hover:scale-[1.02] hover:shadow-[0_30px_80px_rgba(245,240,232,0.3)]"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                <div className="relative z-10 flex items-center justify-center gap-3 group-hover:text-white transition-colors">
                  <EnvelopeIcon className="w-6 h-6" />
                  <span>Contact Us</span>
                </div>
              </a>
              
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="px-10 py-5 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-xl hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3"
              >
                <ArrowDownTrayIcon className="w-6 h-6" />
                <span>Download App</span>
              </a>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
