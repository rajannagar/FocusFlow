'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container, PhoneSimulator } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL, FOCUSFLOW } from '@/lib/constants';
import { 
  Smartphone, Globe, Timer, CheckSquare, TrendingUp, 
  Shield, Palette, Zap, Moon, Star, ArrowRight, Download,
  Sparkles
} from 'lucide-react';

export default function Home() {
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

  const SectionDivider = () => (
    <div className="relative h-px w-full bg-gradient-to-r from-transparent via-[var(--border)] to-transparent my-16 md:my-24" />
  );

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION - Ultra Premium, Minimal, Powerful
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
        {/* Subtle animated background - more refined */}
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/3 left-1/4 w-[400px] md:w-[800px] h-[400px] md:h-[800px] rounded-full blur-[100px] md:blur-[150px] opacity-[0.08] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.6) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
          <div 
            className="absolute bottom-1/3 right-1/4 w-[350px] md:w-[700px] h-[350px] md:h-[700px] rounded-full blur-[80px] md:blur-[120px] opacity-[0.06] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(212, 168, 83, 0.5) 0%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.008}px, ${-mousePosition.y * 0.008}px)`,
            }}
          />
        </div>

        {/* Subtle grid overlay */}
        <div className="absolute inset-0 bg-grid opacity-[0.03]" />

              <Container>
          <div className="relative z-10 max-w-7xl mx-auto px-4 md:px-6 lg:px-8">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              
              {/* Left - Content */}
              <div className="text-center lg:text-left space-y-8 md:space-y-10">
                  {/* Badge */}
                <div className="flex flex-wrap items-center gap-2 justify-center lg:justify-start">
                  <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-sm text-[var(--foreground-muted)]">
                    <Smartphone className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
                    <span>Available on iOS</span>
                  </div>
                  <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-sm text-[var(--foreground-muted)]">
                    <Globe className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
                    <span>Web Coming Soon</span>
                  </div>
                  </div>

                {/* Main Headline - More Impactful */}
                <div className="space-y-4 md:space-y-6">
                  <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold tracking-tight leading-[1.1]">
                    <span className="block text-[var(--foreground)]">Focus.</span>
                    <span className="block text-gradient">Flow.</span>
                    <span className="block text-[var(--foreground)] text-3xl md:text-4xl lg:text-5xl font-normal mt-2 md:mt-4">
                      Be Present.
                    </span>
                  </h1>

                  <p className="text-xl md:text-2xl lg:text-3xl text-[var(--foreground-muted)] leading-relaxed max-w-2xl mx-auto lg:mx-0 font-light">
                    The all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work.
                  </p>
                </div>

                {/* CTA Buttons - Premium Style */}
                <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start pt-4">
                  <a
                    href={APP_STORE_URL}
                        target="_blank"
                        rel="noopener noreferrer"
                    className="group relative px-8 py-4 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/30"
                      >
                    <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                    <div className="relative z-10 flex items-center justify-center gap-3">
                      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                        </svg>
                      <span>Download on App Store</span>
                    </div>
                  </a>
                  <Link 
                    href="/features"
                    className="px-8 py-4 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300"
                  >
                    Explore Features
                  </Link>
                  </div>

                {/* Trust Indicators */}
                <div className="flex items-center justify-center lg:justify-start gap-6 pt-4">
                  <div className="flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-5 h-5 text-amber-400 fill-amber-400" strokeWidth={0} />
                    ))}
                    <span className="ml-2 text-sm text-[var(--foreground-muted)]">5.0 App Store</span>
                  </div>
                  <div className="h-4 w-px bg-[var(--border)]" />
                  <span className="text-sm text-[var(--foreground-muted)]">Privacy First</span>
                  <div className="h-4 w-px bg-[var(--border)]" />
                  <span className="text-sm text-[var(--foreground-muted)]">No Ads</span>
                </div>
              </div>

              {/* Right - Phone Mockup */}
              <div className="flex justify-center lg:justify-end order-first lg:order-last">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 blur-[60px] md:blur-[100px] scale-150" />
                  <PhoneSimulator 
                    screenshots={[
                      '/images/screen-focus.png',
                      '/images/screen-tasks.png',
                      '/images/screen-progress.png',
                      '/images/screen-profile.png',
                    ]}
                    screenData={[
                      { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-rose-500 to-pink-600' },
                    ]}
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHAT IS FOCUSFLOW - Thoughtful Introduction
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
            <div className="text-center mb-12 md:mb-16">
              <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8 leading-tight">
                One app. <span className="text-gradient">Three tools.</span> Infinite focus.
              </h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto font-light">
                FocusFlow combines a focus timer, task manager, and progress tracker into one seamless experience. No switching apps. No context switching. Just flow.
              </p>
            </div>

            {/* Three Core Features - Premium Cards */}
            <div className="grid md:grid-cols-3 gap-6 md:gap-8">
              {[
                {
                  icon: Timer,
                  title: 'Focus Timer',
                  description: 'Start timed sessions with beautiful ambient backgrounds. Stay anchored in the present moment.',
                  color: 'violet',
                },
                {
                  icon: CheckSquare,
                  title: 'Smart Tasks',
                  description: 'Organize your to-dos with recurring schedules and reminders. Never miss what matters.',
                  color: 'emerald',
                },
                {
                  icon: TrendingUp,
                  title: 'Progress Tracking',
                  description: 'Earn XP, level up, and unlock achievements. See your growth over time.',
                  color: 'amber',
                },
              ].map((feature, i) => {
                const Icon = feature.icon;
                return (
                  <div 
                    key={i}
                    className="group relative p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500 hover:shadow-xl hover:shadow-[var(--accent-primary)]/10"
                  >
                    <div className="w-16 h-16 md:w-20 md:h-20 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg">
                      <Icon className="w-8 h-8 md:w-10 md:h-10 text-[var(--accent-primary)]" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-2xl md:text-3xl font-bold text-[var(--foreground)] mb-4">
                      {feature.title}
                    </h3>
                    <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed">
                      {feature.description}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHY FOCUSFLOW - The Philosophy
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[1] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto px-4 md:px-6">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Philosophy Text */}
              <div className="space-y-6 md:space-y-8">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
                  <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" />
                  <span>Our Philosophy</span>
                </div>
                <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                  Built for <span className="text-gradient">deep work</span>
                </h2>
                <div className="space-y-4 text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  <p>
                    FocusFlow was designed around a simple truth: the best work happens when you're fully present. Not distracted. Not multitasking. Just you, your work, and the tools that help you stay in flow.
                  </p>
                  <p>
                    Every feature—from the ambient backgrounds to the XP system—is crafted to support this state of deep focus. We believe productivity tools should be beautiful, private, and respectful of your attention.
                  </p>
                  <p>
                    No ads. No tracking. No unnecessary notifications. Just pure focus.
                  </p>
                </div>
                <Link 
                  href="/about"
                  className="inline-flex items-center gap-2 text-[var(--accent-primary)] font-semibold hover:gap-3 transition-all duration-300 group"
                >
                  Learn more about FocusFlow
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" strokeWidth={2} />
                </Link>
              </div>

              {/* Right - Feature Showcase */}
              <div className="space-y-6">
                {[
                  { icon: Shield, title: 'Privacy First', desc: 'Your data stays yours. Always encrypted, never sold.' },
                  { icon: Palette, title: 'Beautiful Design', desc: 'Every pixel crafted for clarity and calm.' },
                  { icon: Zap, title: 'Lightning Fast', desc: 'Instant sync. Smooth animations. Zero lag.' },
                  { icon: Moon, title: 'Works Offline', desc: 'No internet? No problem. Full functionality offline.' },
                ].map((item, i) => {
                  const Icon = item.icon;
                  return (
                    <div key={i} className="flex items-start gap-4 p-6 rounded-2xl bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all group">
                      <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                        <Icon className="w-6 h-6 text-[var(--accent-primary)]" strokeWidth={1.5} />
                      </div>
                      <div>
                        <h3 className="text-xl font-semibold text-[var(--foreground)] mb-1">{item.title}</h3>
                        <p className="text-[var(--foreground-muted)]">{item.desc}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WEB APP - Coming Soon
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[2] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto px-4 md:px-6">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Content */}
              <div className="space-y-6 md:space-y-8">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)]">
                  <Globe className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
                  <span>Coming Soon</span>
                </div>
                <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                  Use FocusFlow <span className="text-gradient">anywhere</span>
                </h2>
                <div className="space-y-4 text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  <p>
                    The FocusFlow web app is coming soon. Access your sessions, tasks, and progress from any browser. Same account, same data, syncs seamlessly across all your devices.
                  </p>
                  <p>
                    Sign in to get notified when the web app launches, and be among the first to experience FocusFlow on desktop.
                  </p>
                </div>
                <div className="flex flex-col sm:flex-row gap-4 pt-4">
                  <Link 
                    href="/webapp"
                    className="px-8 py-4 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/30 transition-all duration-300 text-center"
                  >
                    Sign In to Get Notified
                  </Link>
                  <Link 
                    href="/features"
                    className="px-8 py-4 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 text-center"
                  >
                    Learn More
                  </Link>
                </div>
            </div>

              {/* Right - Browser Mockup */}
              <div className="relative">
                <div className="relative rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] p-8 md:p-12 shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="mb-6 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-500/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-500/50" />
                      <div className="w-3 h-3 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 h-8 rounded-lg bg-[var(--background-subtle)] border border-[var(--border)] ml-4" />
                  </div>
                  {/* Browser Content */}
                  <div className="aspect-video bg-gradient-to-br from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10 rounded-2xl flex items-center justify-center border border-[var(--border)]">
                    <div className="text-center">
                      <Globe className="w-16 h-16 text-[var(--accent-primary)] mx-auto mb-4" strokeWidth={1.5} />
                      <p className="text-lg text-[var(--foreground-muted)]">Web App Preview</p>
                    </div>
                  </div>
                </div>
                {/* Glow effect */}
                <div className="absolute -inset-4 bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-3xl blur-2xl -z-10" />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TESTIMONIAL - Social Proof
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[3] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto px-4 md:px-6">
            <div className="relative p-12 md:p-16 rounded-3xl bg-[var(--background)] border border-[var(--border)]">
              <div className="absolute top-8 left-8 text-6xl opacity-10">"</div>
              <blockquote className="text-2xl md:text-3xl lg:text-4xl text-[var(--foreground)] leading-relaxed font-light mb-8 relative z-10">
                Finally, a focus app that actually helps me focus. The ambient backgrounds are beautiful, and the XP system keeps me motivated.
            </blockquote>
              <div className="flex items-center gap-4">
                <div className="flex gap-1">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-6 h-6 text-amber-400 fill-amber-400" strokeWidth={0} />
                  ))}
                </div>
                <div className="text-sm text-[var(--foreground-muted)]">App Store Review</div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRICING PREVIEW - Thoughtful CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[4] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto text-center px-4 md:px-6">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">
              Start free. <span className="text-gradient">Upgrade when ready.</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 md:mb-16 leading-relaxed font-light max-w-2xl mx-auto">
              FocusFlow is free forever with core features. Unlock Pro for unlimited tasks, all themes, cloud sync, and more.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link 
                href="/pricing"
                className="px-8 py-4 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/30 transition-all duration-300"
              >
                View Pricing
              </Link>
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="px-8 py-4 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background)] transition-all duration-300"
              >
                Download Free
              </a>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA - Premium Close
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-24 overflow-hidden">
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-5xl mx-auto text-center px-4 md:px-6">
            <div className="relative inline-block mb-12">
              <div className="absolute -inset-6 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-[40px] blur-2xl" />
              <Image
                src="/focusflow-app-icon.jpg"
                alt="FocusFlow"
                width={120}
                height={120}
                className="relative rounded-[32px] shadow-2xl"
                style={{
                  boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4)'
                }}
              />
            </div>
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">
              Ready to <span className="text-gradient">focus?</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 md:mb-16 leading-relaxed font-light max-w-2xl mx-auto">
              Download FocusFlow and start your journey to more focused, productive work.
            </p>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="group relative inline-flex items-center gap-3 px-8 md:px-10 py-4 md:py-5 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg md:text-xl overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/40"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <Download className="w-6 h-6 relative z-10" strokeWidth={2} />
              <span className="relative z-10">Download on App Store</span>
            </a>
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
