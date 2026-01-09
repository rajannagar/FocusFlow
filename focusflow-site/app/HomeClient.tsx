'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container, PhoneSimulator } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';
import { 
  Timer, CheckSquare, TrendingUp, Shield, Zap, Moon, Star, 
  ArrowRight, Play, Sparkles, Bot, Clock, Target, Award,
  Music, Cloud, Smartphone, ChevronDown, Quote, Users,
  Heart, Flame, Brain, Waves
} from 'lucide-react';

// Floating particle component
const FloatingParticle = ({ delay, duration, size, left, top }: { 
  delay: number; duration: number; size: number; left: string; top: string 
}) => (
  <div 
    className="absolute rounded-full bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] opacity-20 blur-sm animate-float"
    style={{ 
      width: size, 
      height: size, 
      left, 
      top,
      animationDelay: `${delay}s`,
      animationDuration: `${duration}s`,
    }}
  />
);

// Animated counter component
const AnimatedCounter = ({ end, duration = 2000, suffix = '' }: { end: number; duration?: number; suffix?: string }) => {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const hasAnimated = useRef(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !hasAnimated.current) {
          hasAnimated.current = true;
          let start = 0;
          const increment = end / (duration / 16);
          const timer = setInterval(() => {
            start += increment;
            if (start >= end) {
              setCount(end);
              clearInterval(timer);
            } else {
              setCount(Math.floor(start));
            }
          }, 16);
        }
      },
      { threshold: 0.5 }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [end, duration]);

  return <span ref={ref}>{count.toLocaleString()}{suffix}</span>;
};

// Feature card with hover effects
const FeatureCard = ({ 
  icon: Icon, 
  title, 
  description, 
  gradient,
  delay = 0 
}: { 
  icon: React.ElementType; 
  title: string; 
  description: string; 
  gradient: string;
  delay?: number;
}) => (
  <div 
    className="group relative"
    style={{ animationDelay: `${delay}ms` }}
  >
    {/* Glow effect on hover */}
    <div className={`absolute -inset-0.5 bg-gradient-to-r ${gradient} rounded-3xl blur opacity-0 group-hover:opacity-30 transition-opacity duration-500`} />
    
    <div className="relative h-full p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-transparent transition-all duration-500 overflow-hidden">
      {/* Background pattern */}
      <div className="absolute top-0 right-0 w-32 h-32 opacity-5">
        <Icon className="w-full h-full" strokeWidth={0.5} />
      </div>
      
      <div className={`w-14 h-14 md:w-16 md:h-16 rounded-2xl bg-gradient-to-br ${gradient} flex items-center justify-center mb-6 group-hover:scale-110 group-hover:rotate-3 transition-all duration-500 shadow-lg`}>
        <Icon className="w-7 h-7 md:w-8 md:h-8 text-white" strokeWidth={1.5} />
      </div>
      
      <h3 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-3 group-hover:text-gradient transition-all duration-300">
        {title}
      </h3>
      <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed">
        {description}
      </p>
      
      {/* Hover arrow */}
      <div className="mt-6 flex items-center gap-2 text-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transform translate-x-[-10px] group-hover:translate-x-0 transition-all duration-300">
        <span className="text-sm font-semibold">Learn more</span>
        <ArrowRight className="w-4 h-4" />
      </div>
    </div>
  </div>
);

export default function HomeClient() {
  const mousePosition = useThrottledMouse();
  const [isVideoPlaying, setIsVideoPlaying] = useState(false);
  const sectionRefs = useRef<(HTMLElement | null)[]>([]);
  const heroRef = useRef<HTMLDivElement>(null);
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px',
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-fade-in');
          entry.target.classList.remove('opacity-0');
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
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION - Immersive & Cinematic
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[100dvh] flex items-center justify-center overflow-hidden">
        {/* Animated gradient orbs */}
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/4 left-1/4 w-[600px] md:w-[1000px] h-[600px] md:h-[1000px] rounded-full blur-[120px] md:blur-[200px] opacity-[0.15] transition-transform duration-[2000ms] ease-out"
            style={{
              background: `conic-gradient(from 0deg, rgba(139, 92, 246, 0.8), rgba(212, 168, 83, 0.6), rgba(139, 92, 246, 0.8))`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px) rotate(${scrollY * 0.02}deg)`,
            }}
          />
          <div 
            className="absolute bottom-1/4 right-1/4 w-[500px] md:w-[800px] h-[500px] md:h-[800px] rounded-full blur-[100px] md:blur-[180px] opacity-[0.1] transition-transform duration-[2500ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(212, 168, 83, 0.7) 0%, rgba(139, 92, 246, 0.4) 50%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
            }}
          />
        </div>

        {/* Floating particles */}
        <div className="absolute inset-0 pointer-events-none">
          <FloatingParticle delay={0} duration={8} size={4} left="10%" top="20%" />
          <FloatingParticle delay={1} duration={10} size={6} left="85%" top="15%" />
          <FloatingParticle delay={2} duration={7} size={3} left="70%" top="70%" />
          <FloatingParticle delay={3} duration={9} size={5} left="20%" top="80%" />
          <FloatingParticle delay={4} duration={11} size={4} left="50%" top="10%" />
          <FloatingParticle delay={5} duration={8} size={6} left="90%" top="60%" />
        </div>

        {/* Grid pattern */}
        <div className="absolute inset-0 bg-grid opacity-[0.03]" />
        
        {/* Radial gradient overlay */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_0%,var(--background)_70%)]" />

        <Container>
          <div 
            ref={heroRef}
            className="relative z-10 max-w-7xl mx-auto pt-20 md:pt-0"
            style={{ transform: `translateY(${scrollY * 0.1}px)` }}
          >
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
              
              {/* Left - Content */}
              <div className="text-center lg:text-left space-y-8">
                {/* Animated Badge */}
                <div className="inline-flex items-center gap-3 px-5 py-2.5 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10 border border-[var(--accent-primary)]/20 backdrop-blur-sm animate-pulse-slow">
                  <div className="flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-3.5 h-3.5 text-amber-400 fill-amber-400" strokeWidth={0} />
                    ))}
                  </div>
                  <span className="text-sm font-medium text-[var(--foreground)]">Rated 5.0 on App Store</span>
                  <span className="text-[var(--foreground-subtle)]">•</span>
                  <span className="text-sm text-[var(--foreground-muted)]">Free Download</span>
                </div>

                {/* Main Headline - Dramatic */}
                <div className="space-y-4">
                  <h1 className="text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-bold tracking-tight leading-[0.95]">
                    <span className="block text-[var(--foreground)] animate-slide-up" style={{ animationDelay: '0.1s' }}>
                      Your mind
                    </span>
                    <span className="block text-gradient animate-slide-up" style={{ animationDelay: '0.2s' }}>
                      deserves
                    </span>
                    <span className="block text-[var(--foreground)] animate-slide-up" style={{ animationDelay: '0.3s' }}>
                      focus.
                    </span>
                  </h1>

                  <p className="text-lg sm:text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-xl mx-auto lg:mx-0 font-light animate-slide-up" style={{ animationDelay: '0.4s' }}>
                    The beautifully crafted focus timer that helps you do deep work, track progress, and build better habits. <span className="text-[var(--foreground)]">No distractions. No ads. Just flow.</span>
                  </p>
                </div>

                {/* CTA Buttons */}
                <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start animate-slide-up" style={{ animationDelay: '0.5s' }}>
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="group relative px-8 py-4 rounded-2xl bg-[var(--foreground)] text-[var(--background)] font-semibold text-lg overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-[0_20px_60px_rgba(245,240,232,0.3)]"
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                    <div className="relative z-10 flex items-center justify-center gap-3 group-hover:text-white transition-colors">
                      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                      </svg>
                      <span>Download Free</span>
                    </div>
                  </a>
                  
                  <button
                    onClick={() => setIsVideoPlaying(true)}
                    className="group px-8 py-4 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3"
                  >
                    <div className="w-10 h-10 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center group-hover:bg-[var(--accent-primary)]/20 group-hover:scale-110 transition-all">
                      <Play className="w-4 h-4 text-[var(--accent-primary)] ml-0.5" fill="currentColor" />
                    </div>
                    <span>Watch Demo</span>
                  </button>
                </div>

                {/* Trust Badges */}
                <div className="flex flex-wrap items-center justify-center lg:justify-start gap-6 pt-4 animate-slide-up" style={{ animationDelay: '0.6s' }}>
                  <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
                    <Shield className="w-4 h-4 text-emerald-400" />
                    <span>Privacy First</span>
                  </div>
                  <div className="h-4 w-px bg-[var(--border)]" />
                  <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
                    <Zap className="w-4 h-4 text-amber-400" />
                    <span>No Ads Ever</span>
                  </div>
                  <div className="h-4 w-px bg-[var(--border)]" />
                  <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
                    <Moon className="w-4 h-4 text-blue-400" />
                    <span>Works Offline</span>
                  </div>
                </div>
              </div>

              {/* Right - Phone Mockup with Glow */}
              <div className="flex justify-center lg:justify-end order-first lg:order-last">
                <div className="relative animate-slide-up" style={{ animationDelay: '0.3s' }}>
                  {/* Outer glow rings */}
                  <div className="absolute inset-0 scale-[1.3]">
                    <div className="absolute inset-0 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 blur-[80px] animate-pulse-slow" />
                  </div>
                  
                  {/* Phone */}
                  <PhoneSimulator 
                    screenshots={[
                      '/images/screen-focus.png',
                      '/images/screen-tasks.png',
                      '/images/screen-progress.png',
                    ]}
                    screenData={[
                      { icon: '⏱️', title: 'Focus', desc: 'Deep work mode', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Get things done', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '📈', title: 'Progress', desc: 'Level up', gradient: 'from-amber-500 to-orange-600' },
                    ]}
                  />
                </div>
              </div>
            </div>

            {/* Scroll indicator */}
            <div className="absolute bottom-8 left-1/2 -translate-x-1/2 hidden md:flex flex-col items-center gap-2 animate-bounce-slow">
              <span className="text-xs text-[var(--foreground-subtle)] uppercase tracking-widest">Scroll to explore</span>
              <ChevronDown className="w-5 h-5 text-[var(--foreground-subtle)]" />
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          SOCIAL PROOF BAR - Trust Building
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-8 md:py-12 border-y border-[var(--border)] bg-[var(--background-elevated)]/50 backdrop-blur-sm">
        <Container>
          <div className="flex flex-wrap items-center justify-center gap-8 md:gap-16">
            <div className="text-center">
              <div className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">
                <AnimatedCounter end={10000} suffix="+" />
              </div>
              <div className="text-sm text-[var(--foreground-muted)]">Active Users</div>
            </div>
            <div className="h-8 w-px bg-[var(--border)] hidden md:block" />
            <div className="text-center">
              <div className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">
                <AnimatedCounter end={50000} suffix="+" />
              </div>
              <div className="text-sm text-[var(--foreground-muted)]">Focus Sessions</div>
            </div>
            <div className="h-8 w-px bg-[var(--border)] hidden md:block" />
            <div className="text-center">
              <div className="flex items-center justify-center gap-1 mb-1">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-5 h-5 text-amber-400 fill-amber-400" strokeWidth={0} />
                ))}
              </div>
              <div className="text-sm text-[var(--foreground-muted)]">5.0 App Store Rating</div>
            </div>
            <div className="h-8 w-px bg-[var(--border)] hidden md:block" />
            <div className="text-center">
              <div className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">
                <AnimatedCounter end={100} suffix="%" />
              </div>
              <div className="text-sm text-[var(--foreground-muted)]">Privacy Focused</div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          THE PROBLEM - Emotional Connection
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[0] = el; }}
        className="relative py-24 md:py-32 overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-red-500/10 border border-red-500/20 text-red-400 text-sm mb-8">
              <Brain className="w-4 h-4" />
              <span>The focus crisis is real</span>
            </div>
            
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-8 leading-tight">
              Your attention is under <span className="text-red-400">attack.</span>
            </h2>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed mb-12 font-light">
              The average person checks their phone <span className="text-[var(--foreground)] font-medium">96 times a day</span>. 
              Social media, notifications, and endless distractions are stealing your ability to do deep, meaningful work.
            </p>

            <div className="grid md:grid-cols-3 gap-6 mb-12">
              {[
                { stat: '2.5 hrs', label: 'Average daily screen time on distractions' },
                { stat: '23 min', label: 'Time to refocus after an interruption' },
                { stat: '47%', label: 'Of the day spent mind-wandering' },
              ].map((item, i) => (
                <div key={i} className="p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
                  <div className="text-3xl md:text-4xl font-bold text-red-400 mb-2">{item.stat}</div>
                  <div className="text-sm text-[var(--foreground-muted)]">{item.label}</div>
                </div>
              ))}
            </div>

            <p className="text-2xl md:text-3xl text-[var(--foreground)] font-medium">
              It's time to <span className="text-gradient">take back control.</span>
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          THE SOLUTION - FocusFlow Introduction
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[1] = el; }}
        className="relative py-24 md:py-32 bg-gradient-to-b from-[var(--background)] via-[var(--accent-primary)]/5 to-[var(--background)] overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16 md:mb-20">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 text-[var(--accent-primary)] text-sm mb-8">
                <Sparkles className="w-4 h-4" />
                <span>Introducing FocusFlow</span>
              </div>
              
              <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-8 leading-tight">
                One app to <span className="text-gradient">rule your focus.</span>
              </h2>
              
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto font-light">
                A beautifully designed focus timer, task manager, and progress tracker — all in one. 
                Built for people who want to do their best work.
              </p>
            </div>

            {/* Feature Cards Grid */}
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              <FeatureCard
                icon={Timer}
                title="Focus Timer"
                description="Immersive timed sessions with 14 ambient backgrounds and 11 focus sounds. Enter flow state effortlessly."
                gradient="from-violet-500 to-purple-600"
                delay={0}
              />
              <FeatureCard
                icon={CheckSquare}
                title="Smart Tasks"
                description="Organize your work with intelligent task management. Recurring schedules, reminders, and priorities."
                gradient="from-emerald-500 to-teal-600"
                delay={100}
              />
              <FeatureCard
                icon={TrendingUp}
                title="Progress Tracking"
                description="Earn XP, level up through 50 ranks, unlock achievements. Gamification that actually motivates."
                gradient="from-amber-500 to-orange-600"
                delay={200}
              />
              <FeatureCard
                icon={Bot}
                title="Flow AI"
                description="Your intelligent productivity companion. Powered by GPT-4o to help you work smarter."
                gradient="from-purple-500 to-pink-600"
                delay={300}
              />
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FEATURE DEEP DIVE - Focus Timer
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[2] = el; }}
        className="relative py-24 md:py-32 overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-7xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Phone */}
              <div className="relative order-2 lg:order-1">
                <div className="absolute -inset-4 bg-gradient-to-r from-violet-500/20 to-purple-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png']}
                  screenData={[
                    { icon: '🌲', title: 'Forest', desc: 'Ambient scene', gradient: 'from-emerald-500 to-teal-600' },
                    { icon: '🌌', title: 'Night Sky', desc: 'Ambient scene', gradient: 'from-indigo-500 to-purple-600' },
                    { icon: '🌊', title: 'Ocean', desc: 'Ambient scene', gradient: 'from-cyan-500 to-blue-600' },
                  ]}
                />
              </div>

              {/* Right - Content */}
              <div className="order-1 lg:order-2 space-y-8">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 text-violet-400 text-sm">
                  <Timer className="w-4 h-4" />
                  <span>Focus Timer</span>
                </div>

                <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                  Enter your <span className="text-gradient">flow state</span>
                </h2>

                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  Transform any moment into focused productivity. Choose from stunning ambient backgrounds, 
                  calming focus sounds, and set your intention before each session.
                </p>

                <div className="space-y-4">
                  {[
                    { icon: Waves, text: '14 immersive ambient backgrounds' },
                    { icon: Music, text: '11 focus-enhancing sounds' },
                    { icon: Clock, text: 'Customizable session lengths' },
                    { icon: Target, text: 'Session intentions to stay on track' },
                  ].map((item, i) => (
                    <div key={i} className="flex items-center gap-4 p-4 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)]">
                      <div className="w-10 h-10 rounded-lg bg-violet-500/10 flex items-center justify-center">
                        <item.icon className="w-5 h-5 text-violet-400" />
                      </div>
                      <span className="text-[var(--foreground)]">{item.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FEATURE DEEP DIVE - Progress & Gamification
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[3] = el; }}
        className="relative py-24 md:py-32 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-7xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Content */}
              <div className="space-y-8">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-sm">
                  <Award className="w-4 h-4" />
                  <span>Progress & Gamification</span>
                </div>

                <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                  Level up your <span className="text-gradient">productivity</span>
                </h2>

                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                  Turn focus into a game you'll want to play. Earn XP for every session, 
                  climb through 50 levels, and unlock achievement badges that celebrate your growth.
                </p>

                <div className="grid grid-cols-2 gap-4">
                  {[
                    { value: '50', label: 'Levels to unlock', icon: TrendingUp },
                    { value: '20+', label: 'Achievements', icon: Award },
                    { value: '∞', label: 'XP to earn', icon: Sparkles },
                    { value: '365', label: 'Day streaks', icon: Flame },
                  ].map((item, i) => (
                    <div key={i} className="p-5 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-center group hover:border-amber-500/30 transition-colors">
                      <item.icon className="w-6 h-6 text-amber-400 mx-auto mb-2 group-hover:scale-110 transition-transform" />
                      <div className="text-2xl md:text-3xl font-bold text-[var(--foreground)]">{item.value}</div>
                      <div className="text-sm text-[var(--foreground-muted)]">{item.label}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Right - Phone */}
              <div className="relative">
                <div className="absolute -inset-4 bg-gradient-to-r from-amber-500/20 to-orange-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png']}
                  screenData={[
                    { icon: '📈', title: 'Stats', desc: 'Your journey', gradient: 'from-amber-500 to-orange-600' },
                    { icon: '🏆', title: 'Achievements', desc: 'Unlock badges', gradient: 'from-amber-500 to-orange-600' },
                    { icon: '⚡', title: 'Levels', desc: 'Level up', gradient: 'from-amber-500 to-orange-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TESTIMONIALS - Social Proof
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[4] = el; }}
        className="relative py-24 md:py-32 overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-8">
                <Heart className="w-4 h-4 text-red-400" />
                <span>Loved by thousands</span>
              </div>
              
              <h2 className="text-4xl md:text-6xl font-bold mb-6">
                What people are <span className="text-gradient">saying</span>
              </h2>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
              {[
                {
                  quote: "Finally, a focus app that actually helps me focus. The ambient backgrounds are beautiful, and the XP system keeps me motivated to stay consistent.",
                  author: "Sarah K.",
                  role: "Designer",
                  rating: 5
                },
                {
                  quote: "I've tried every productivity app out there. FocusFlow is the first one that stuck. The combination of timer, tasks, and progress tracking is perfect.",
                  author: "Michael R.",
                  role: "Software Engineer",
                  rating: 5
                },
                {
                  quote: "The Flow AI feature is a game-changer. It's like having a personal productivity coach that actually understands how I work.",
                  author: "Emily T.",
                  role: "Entrepreneur",
                  rating: 5
                },
              ].map((testimonial, i) => (
                <div 
                  key={i} 
                  className="group relative p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500"
                >
                  <Quote className="w-10 h-10 text-[var(--accent-primary)]/20 mb-4" />
                  
                  <div className="flex gap-1 mb-4">
                    {[...Array(testimonial.rating)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 text-amber-400 fill-amber-400" strokeWidth={0} />
                    ))}
                  </div>
                  
                  <p className="text-lg text-[var(--foreground)] mb-6 leading-relaxed">
                    &quot;{testimonial.quote}&quot;
                  </p>
                  
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] flex items-center justify-center text-white font-bold">
                      {testimonial.author[0]}
                    </div>
                    <div>
                      <div className="font-semibold text-[var(--foreground)]">{testimonial.author}</div>
                      <div className="text-sm text-[var(--foreground-muted)]">{testimonial.role}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRICING PREVIEW
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[5] = el; }}
        className="relative py-24 md:py-32 bg-gradient-to-b from-[var(--background-elevated)] to-[var(--background)] overflow-hidden opacity-0 transition-all duration-1000"
      >
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6">
              Start free. <span className="text-gradient">Stay focused.</span>
            </h2>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 font-light">
              FocusFlow is free forever with core features. Upgrade to Pro for unlimited everything, 
              Flow AI, cloud sync, and all premium content.
            </p>

            <div className="grid md:grid-cols-2 gap-6 max-w-2xl mx-auto mb-12">
              {/* Free */}
              <div className="p-8 rounded-3xl bg-[var(--background)] border border-[var(--border)]">
                <div className="text-sm text-[var(--foreground-muted)] mb-2">Free Forever</div>
                <div className="text-4xl font-bold text-[var(--foreground)] mb-6">$0</div>
                <ul className="space-y-3 text-left text-[var(--foreground-muted)]">
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Focus timer with 3 backgrounds
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    3 tasks & presets
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Basic progress tracking
                  </li>
                </ul>
              </div>

              {/* Pro */}
              <div className="relative p-8 rounded-3xl bg-gradient-to-br from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)]/30">
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] text-white text-sm font-medium">
                  Most Popular
                </div>
                <div className="text-sm text-[var(--accent-primary)] mb-2">Pro</div>
                <div className="text-4xl font-bold text-[var(--foreground)] mb-1">$3.99<span className="text-lg font-normal text-[var(--foreground-muted)]">/mo</span></div>
                <div className="text-sm text-[var(--foreground-muted)] mb-6">or $44.99/year (save 6%)</div>
                <ul className="space-y-3 text-left text-[var(--foreground-muted)]">
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-[var(--accent-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Everything in Free
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-[var(--accent-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Unlimited everything
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-[var(--accent-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Flow AI (GPT-4o)
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/20 flex items-center justify-center">
                      <svg className="w-3 h-3 text-[var(--accent-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    Cloud sync & all themes
                  </li>
                </ul>
              </div>
            </div>

            <Link 
              href="/pricing"
              className="inline-flex items-center gap-2 text-[var(--accent-primary)] font-semibold hover:gap-3 transition-all"
            >
              View full pricing details
              <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA - Strong Close
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-24 md:py-32 overflow-hidden">
        {/* Background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-[var(--background)] via-[var(--accent-primary)]/5 to-[var(--background)]" />
        
        <Container>
          <div className="relative max-w-4xl mx-auto text-center">
            {/* App Icon */}
            <div className="relative inline-block mb-12">
              <div className="absolute -inset-8 bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 rounded-full blur-3xl animate-pulse-slow" />
              <Image
                src="/focusflow-app-icon.jpg"
                alt="FocusFlow"
                width={140}
                height={140}
                className="relative rounded-[36px] shadow-2xl"
                style={{ boxShadow: '0 30px 80px rgba(0, 0, 0, 0.5)' }}
              />
            </div>

            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-8 leading-tight">
              Your best work <br className="hidden md:block" />
              <span className="text-gradient">starts now.</span>
            </h2>

            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 font-light max-w-2xl mx-auto">
              Join thousands of people who have transformed their productivity with FocusFlow. 
              Download free and start your focus journey today.
            </p>

            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="group relative inline-flex items-center gap-4 px-10 py-5 rounded-2xl bg-[var(--foreground)] text-[var(--background)] font-semibold text-xl overflow-hidden transition-all duration-500 hover:scale-[1.02] hover:shadow-[0_30px_80px_rgba(245,240,232,0.3)]"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
              <svg className="w-7 h-7 relative z-10 group-hover:text-white transition-colors" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <span className="relative z-10 group-hover:text-white transition-colors">Download on App Store</span>
            </a>

            <p className="mt-6 text-sm text-[var(--foreground-muted)]">
              Free to download • No credit card required • Cancel anytime
            </p>
          </div>
        </Container>
      </section>

      {/* Video Modal (placeholder for demo video) */}
      {isVideoPlaying && (
        <div 
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-sm"
          onClick={() => setIsVideoPlaying(false)}
        >
          <div className="relative w-full max-w-4xl mx-4 aspect-video bg-[var(--background-elevated)] rounded-2xl flex items-center justify-center">
            <div className="text-center">
              <Play className="w-16 h-16 text-[var(--accent-primary)] mx-auto mb-4" />
              <p className="text-[var(--foreground-muted)]">Demo video coming soon</p>
            </div>
            <button 
              className="absolute top-4 right-4 w-10 h-10 rounded-full bg-[var(--foreground)]/10 flex items-center justify-center text-[var(--foreground)] hover:bg-[var(--foreground)]/20 transition-colors"
              onClick={() => setIsVideoPlaying(false)}
            >
              ✕
            </button>
          </div>
        </div>
      )}

      <style jsx>{`
        @keyframes slide-up {
          from {
            opacity: 0;
            transform: translateY(30px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        .animate-slide-up {
          opacity: 0;
          animation: slide-up 0.8s var(--ease-out-expo) forwards;
        }

        @keyframes fade-in {
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
          animation: fade-in 0.8s var(--ease-out-expo) forwards;
        }

        @keyframes bounce-slow {
          0%, 100% {
            transform: translateY(0) translateX(-50%);
          }
          50% {
            transform: translateY(10px) translateX(-50%);
          }
        }
        
        .animate-bounce-slow {
          animation: bounce-slow 2s ease-in-out infinite;
        }

        @keyframes pulse-slow {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0.7;
          }
        }
        
        .animate-pulse-slow {
          animation: pulse-slow 3s ease-in-out infinite;
        }

        @keyframes float {
          0%, 100% {
            transform: translateY(0px) translateX(0px);
          }
          25% {
            transform: translateY(-10px) translateX(5px);
          }
          50% {
            transform: translateY(-5px) translateX(-5px);
          }
          75% {
            transform: translateY(-15px) translateX(3px);
          }
        }
        
        .animate-float {
          animation: float 8s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
}

