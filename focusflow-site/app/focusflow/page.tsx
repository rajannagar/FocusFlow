'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container, PhoneSimulator } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';
import { generateSoftwareAppSchema } from '@/lib/seo';
import { 
  ClockIcon, CheckCircleIcon, ChartBarIcon, UserIcon, StarIcon, 
  ArrowRightIcon, SparklesIcon, ShieldCheckIcon, MusicalNoteIcon, CloudIcon, 
  DevicePhoneMobileIcon, AcademicCapIcon, ChevronDownIcon, BoltIcon, CheckIcon,
  PlayIcon, ArrowDownTrayIcon, ClockIcon as ClockIconAlt, TagIcon, HeartIcon, LightBulbIcon
} from '@heroicons/react/24/solid';

// Feature data for the tabbed section
const features = [
  {
    id: 'timer',
    label: 'Focus Timer',
    icon: ClockIcon,
    color: 'violet',
    headline: 'Deep focus, beautiful ambiance',
    description: 'Start timed sessions with customizable durations. Choose from ambient backgrounds or connect your music app (Pro).',
    highlights: [
      { title: '14 Ambient Backgrounds', desc: 'Aurora, Rain, Fireplace, Ocean, Forest, and more' },
      { title: '11 Focus Sounds', desc: 'Light Rain, Fireplace, Soft Ambience, and more' },
      { title: 'Music Integration', desc: 'Spotify, Apple Music, or YouTube Music (Pro)' },
      { title: 'Live Activity', desc: 'See your timer in Dynamic Island (Pro)' },
      { title: 'Session Intentions', desc: 'Set focus goals for each session' },
    ],
    screenshots: ['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png'],
    screenData: [
      { icon: '⏱️', title: 'Timer', desc: 'Start session', gradient: 'from-violet-500 to-purple-600' },
      { icon: '⏱️', title: 'Timer', desc: 'In progress', gradient: 'from-violet-500 to-purple-600' },
      { icon: '⏱️', title: 'Timer', desc: 'Complete', gradient: 'from-violet-500 to-purple-600' },
    ],
    gradient: 'from-violet-500 to-purple-600',
    bgGradient: 'from-violet-500/20 to-purple-500/10',
    accentColor: 'rgb(139, 92, 246)',
  },
  {
    id: 'tasks',
    label: 'Tasks',
    icon: CheckCircleIcon,
    color: 'emerald',
    headline: 'Smart task management',
    description: 'Organize your to-do list with reminders, recurring schedules, and focus session integration.',
    highlights: [
      { title: 'Recurring Tasks', desc: 'Daily, weekly, monthly, or custom' },
      { title: 'Duration Estimates', desc: 'Track actual vs estimated time' },
      { title: 'Task Limits', desc: '3 tasks (Free) or unlimited (Pro)' },
      { title: 'Smart Reminders', desc: 'Never miss important tasks' },
    ],
    screenshots: ['/images/screen-tasks-1.png', '/images/screen-tasks-2.png', '/images/screen-tasks-3.png'],
    screenData: [
      { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-emerald-500 to-teal-600' },
      { icon: '✅', title: 'Tasks', desc: 'Create task', gradient: 'from-emerald-500 to-teal-600' },
      { icon: '✅', title: 'Tasks', desc: 'Details', gradient: 'from-emerald-500 to-teal-600' },
    ],
    gradient: 'from-emerald-500 to-teal-600',
    bgGradient: 'from-emerald-500/20 to-teal-500/10',
    accentColor: 'rgb(16, 185, 129)',
  },
  {
    id: 'progress',
    label: 'Progress',
    icon: ChartBarIcon,
    color: 'amber',
    headline: 'Track your growth',
    description: 'Earn XP, level up through 50 ranks, maintain streaks, and unlock achievement badges (Pro).',
    highlights: [
      { title: 'XP & 50 Levels', desc: 'Earn XP for sessions and tasks (Pro)' },
      { title: 'Achievement Badges', desc: 'Unlock milestones and rewards (Pro)' },
      { title: 'Journey View', desc: 'Daily summaries and weekly reviews (Pro)' },
      { title: 'Progress History', desc: 'Last 3 days (Free) or full history (Pro)' },
      { title: 'Streak Tracking', desc: 'Build consistency over time' },
    ],
    screenshots: ['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png'],
    screenData: [
      { icon: '📈', title: 'Progress', desc: 'Summary', gradient: 'from-amber-500 to-orange-600' },
      { icon: '📈', title: 'Progress', desc: 'Journey', gradient: 'from-amber-500 to-orange-600' },
      { icon: '📈', title: 'Progress', desc: 'Badges', gradient: 'from-amber-500 to-orange-600' },
    ],
    gradient: 'from-amber-500 to-orange-600',
    bgGradient: 'from-amber-500/20 to-orange-500/10',
    accentColor: 'rgb(245, 158, 11)',
  },
  {
    id: 'profile',
    label: 'Profile',
    icon: UserIcon,
    color: 'rose',
    headline: 'Make it yours',
    description: 'Personalize every aspect of your experience. Choose your avatar, pick your theme, and sync across all your devices (Pro).',
    highlights: [
      { title: '10 Beautiful Themes', desc: 'Forest, Neon (Free), plus 8 Pro themes' },
      { title: '50+ Symbol Avatars', desc: 'Express yourself without photos' },
      { title: 'Custom Focus Presets', desc: '3 presets (Free) or unlimited (Pro)' },
      { title: 'Cloud Sync', desc: 'Sync across all devices (Pro + sign-in)' },
      { title: 'Interactive Widgets', desc: 'Control timer from home screen (Pro)' },
    ],
    screenshots: ['/images/screen-profile.png', '/images/screen-profile-2.png', '/images/screen-profile-3.png'],
    screenData: [
      { icon: '👤', title: 'Profile', desc: 'Your space', gradient: 'from-rose-500 to-pink-600' },
      { icon: '👤', title: 'Profile', desc: 'Themes', gradient: 'from-rose-500 to-pink-600' },
      { icon: '👤', title: 'Profile', desc: 'Settings', gradient: 'from-rose-500 to-pink-600' },
    ],
    gradient: 'from-rose-500 to-pink-600',
    bgGradient: 'from-rose-500/20 to-pink-500/10',
    accentColor: 'rgb(244, 63, 94)',
  },
];

// Values section data
const valueProps = [
  { icon: ShieldCheckIcon, label: 'Privacy First', desc: 'No tracking, no ads' },
  { icon: DevicePhoneMobileIcon, label: 'Widgets', desc: 'Home screen control' },
  { icon: BoltIcon, label: 'Live Activity', desc: 'Dynamic Island support' },
  { icon: CloudIcon, label: 'Offline', desc: 'Works everywhere' },
  { icon: MusicalNoteIcon, label: 'Music', desc: 'Your favorite tunes' },
  { icon: AcademicCapIcon, label: 'Gamified', desc: 'XP & achievements' },
];

export default function FocusFlowPage() {
  const mousePosition = useThrottledMouse();
  const [activeFeature, setActiveFeature] = useState(0);
  const [visibleSections, setVisibleSections] = useState<Set<string>>(new Set());
  const appSchema = generateSoftwareAppSchema();

  // Intersection observer for scroll animations
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setVisibleSections((prev) => new Set([...prev, entry.target.id]));
          }
        });
      },
      { threshold: 0.1, rootMargin: '-50px' }
    );

    document.querySelectorAll('section[id]').forEach((section) => {
      observer.observe(section);
    });

    return () => observer.disconnect();
  }, []);

  const currentFeature = features[activeFeature];

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(appSchema) }}
      />

      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section id="hero" className="relative pt-8 md:pt-16 pb-16 md:pb-32 overflow-hidden">
        {/* Animated background gradients */}
        <div className="absolute inset-0 pointer-events-none">
          <div 
            className="absolute top-0 left-1/4 w-[400px] md:w-[700px] h-[400px] md:h-[700px] rounded-full blur-[80px] md:blur-[120px] opacity-30 transition-transform duration-1000 ease-out"
            style={{
              background: 'radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)',
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
          <div 
            className="absolute bottom-1/4 right-1/4 w-[300px] md:w-[500px] h-[300px] md:h-[500px] rounded-full blur-[60px] md:blur-[100px] opacity-20 transition-transform duration-1000 ease-out"
            style={{
              background: 'radial-gradient(circle, rgba(212, 168, 83, 0.4) 0%, transparent 70%)',
              transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
            }}
          />
        </div>

        {/* Grid background */}
        <div className="absolute inset-0 bg-grid opacity-30" />

        <Container>
          <div className="max-w-6xl mx-auto relative z-10">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              
              {/* Left - Content */}
              <div className={`text-center lg:text-left ${visibleSections.has('hero') ? 'animate-slide-up' : 'opacity-0'}`}>
                {/* App Icon & Name */}
                <div className="flex items-center gap-5 md:gap-6 mb-8 md:mb-10 justify-center lg:justify-start">
                  <div className="relative group flex-shrink-0">
                    {/* Glow */}
                    <div className="absolute -inset-4 md:-inset-5 bg-gradient-to-br from-[var(--accent-primary)]/40 to-[var(--accent-secondary)]/30 rounded-[28px] md:rounded-[36px] blur-2xl md:blur-3xl opacity-60 group-hover:opacity-80 transition-all duration-500" />
                    <Image
                      src="/focusflow_app_icon.jpg"
                      alt="FocusFlow - Be Present"
                      width={120}
                      height={120}
                      className="relative rounded-[24px] md:rounded-[32px] shadow-2xl transition-all duration-500 group-hover:scale-105 w-[100px] h-[100px] md:w-[140px] md:h-[140px]"
                      style={{ 
                        boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1) inset'
                      }}
                      priority
                    />
                  </div>
                  <div>
                    <h1 className="text-5xl md:text-7xl font-bold tracking-tight text-[var(--foreground)] mb-2">
                      FocusFlow
                    </h1>
                    <p className="text-lg md:text-xl text-[var(--foreground-muted)] font-medium">Be Present</p>
                  </div>
                </div>
                
                {/* Tagline */}
                <p className="text-xl md:text-3xl text-[var(--foreground)] leading-relaxed mb-4 md:mb-6 max-w-xl mx-auto lg:mx-0 font-medium">
                  The all-in-one app for <span className="text-gradient">focused work.</span>
                </p>

                <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed mb-8 md:mb-10 max-w-xl mx-auto lg:mx-0">
                  Timer, tasks, and progress tracking in one beautiful experience. Privacy-first. No ads. No tracking.
                </p>
                
                {/* CTAs */}
                <div className="flex flex-col sm:flex-row gap-4 mb-10 justify-center lg:justify-start">
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="group relative inline-flex items-center justify-center gap-3 px-8 py-4 rounded-2xl text-lg font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] shadow-lg shadow-[var(--accent-primary)]/30"
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                    <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                    <svg className="w-6 h-6 relative z-10" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                    </svg>
                    <span className="relative z-10">Download Free</span>
                  </a>
                  <Link 
                    href="#features" 
                    className="group inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl text-lg font-semibold text-[var(--foreground)] bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-all duration-300"
                  >
                    <PlayIcon className="w-5 h-5" />
                    Explore Features
                  </Link>
                </div>
                
                {/* App Store Rating */}
                <div className="flex items-center gap-4 justify-center lg:justify-start">
                  <div className="inline-flex items-center gap-2 px-5 py-3 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
                    <div className="flex">
                      {[...Array(5)].map((_, i) => (
                        <StarIcon key={i} className="w-5 h-5 text-amber-400 fill-amber-400" />
                      ))}
                    </div>
                    <span className="text-base font-semibold text-[var(--foreground)]">5.0</span>
                    <span className="text-sm text-[var(--foreground-muted)]">on App Store</span>
                  </div>
                </div>
              </div>

              {/* Right - Phone Mockup */}
              <div className={`flex justify-center lg:justify-end order-first lg:order-last mb-8 lg:mb-0 ${visibleSections.has('hero') ? 'animate-slide-up' : 'opacity-0'}`} style={{ animationDelay: '0.2s' }}>
                <div className="relative">
                  {/* Phone glow */}
                  <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 blur-[100px] scale-150" />
                  
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

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 hidden md:flex flex-col items-center gap-2 animate-bounce-slow">
          <span className="text-xs text-[var(--foreground-subtle)] uppercase tracking-wider">Scroll</span>
          <ChevronDownIcon className="w-5 h-5 text-[var(--foreground-subtle)]" />
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FEATURES - INTERACTIVE SHOWCASE
          ═══════════════════════════════════════════════════════════════ */}
      <section id="features" className="py-20 md:py-32 relative overflow-hidden">
        {/* Background */}
        <div className="absolute inset-0 bg-[var(--background-elevated)]" />
        <div className="absolute inset-0 bg-mesh opacity-40" />
        
        {/* Dynamic color orbs based on active feature */}
        <div 
          className="absolute top-1/4 -left-1/4 w-[500px] md:w-[700px] h-[500px] md:h-[700px] rounded-full blur-[120px] md:blur-[150px] opacity-25 transition-all duration-700"
          style={{ background: `radial-gradient(circle, ${currentFeature.accentColor}50 0%, transparent 70%)` }}
        />
        <div 
          className="absolute bottom-1/4 -right-1/4 w-[400px] md:w-[600px] h-[400px] md:h-[600px] rounded-full blur-[100px] md:blur-[120px] opacity-20 transition-all duration-700"
          style={{ background: `radial-gradient(circle, ${currentFeature.accentColor}40 0%, transparent 70%)` }}
        />

        <Container>
          <div className="max-w-7xl mx-auto relative z-10">
            {/* Section Header */}
            <div className={`text-center mb-12 md:mb-16 px-4 ${visibleSections.has('features') ? 'animate-slide-up' : 'opacity-0'}`}>
              <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                <SparklesIcon className="w-4 h-4" />
                <span>Core Features</span>
              </div>
              <h2 className="mb-4">Everything in <span className="text-gradient">one app.</span></h2>
              <p className="text-lg md:text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto">
                Focus, tasks, progress, and personalization — beautifully designed.
              </p>
            </div>

            {/* Feature Navigation - Tabs */}
            <div className={`flex justify-center mb-10 md:mb-16 px-2 ${visibleSections.has('features') ? 'animate-slide-up' : 'opacity-0'}`} style={{ animationDelay: '0.1s' }}>
              <div className="grid grid-cols-4 gap-2 md:gap-4 w-full max-w-3xl">
                {features.map((feature, index) => {
                  const IconComponent = feature.icon;
                  return (
                    <button
                      key={feature.id}
                      onClick={() => setActiveFeature(index)}
                      className={`
                        relative group p-4 md:p-6 rounded-2xl border transition-all duration-500 text-center
                        ${activeFeature === index 
                          ? `bg-gradient-to-br ${feature.bgGradient} border-[${feature.accentColor}]/50 shadow-lg` 
                          : 'bg-[var(--background)] border-[var(--border)] hover:border-[var(--accent-primary)]/30'
                        }
                      `}
                      style={activeFeature === index ? { 
                        borderColor: `${feature.accentColor}50`,
                        boxShadow: `0 10px 40px ${feature.accentColor}20`
                      } : {}}
                    >
                      {/* Active indicator */}
                      <div 
                        className={`absolute bottom-0 left-1/2 -translate-x-1/2 h-1 rounded-full transition-all duration-500 ${activeFeature === index ? 'w-10 md:w-12' : 'w-0'}`}
                        style={{ background: `linear-gradient(to right, ${feature.accentColor}, ${feature.accentColor})` }}
                      />
                      
                      <div className={`mb-2 md:mb-3 transition-transform duration-300 flex justify-center ${activeFeature === index ? 'scale-110' : 'group-hover:scale-105'}`}>
                        <IconComponent 
                          className="w-8 h-8 md:w-10 md:h-10" 
                          style={{ color: activeFeature === index ? feature.accentColor : 'var(--foreground-muted)' }}
                          strokeWidth={1.5}
                        />
                      </div>
                      <div className={`text-xs md:text-sm font-semibold transition-colors duration-300 ${activeFeature === index ? 'text-[var(--foreground)]' : 'text-[var(--foreground-muted)]'}`}>
                        {feature.label}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Feature Content */}
            <div className="relative">
              {features.map((feature, index) => (
                <div
                  key={feature.id}
                  className={`transition-all duration-500 ${activeFeature === index ? 'opacity-100 relative' : 'opacity-0 absolute inset-0 pointer-events-none'}`}
                >
                  {/* Premium glass card */}
                  <div className="relative rounded-3xl overflow-hidden mx-2 md:mx-0">
                    {/* Gradient border effect */}
                    <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/20 via-transparent to-[var(--accent-secondary)]/20 rounded-3xl" />
                    <div className="absolute inset-[1px] rounded-3xl bg-[var(--background)]" />
                    
                    <div className="relative p-6 md:p-12 lg:p-16">
                      <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center">
                        {/* Phone */}
                        <div className="flex justify-center order-1">
                          <div className="relative">
                            <div className={`absolute inset-0 bg-gradient-to-r ${feature.bgGradient} blur-[80px] scale-150 opacity-60`} />
                            <PhoneSimulator 
                              screenshots={feature.screenshots}
                              screenData={feature.screenData}
                            />
                          </div>
                        </div>
                        
                        {/* Content */}
                        <div className="order-2 text-center lg:text-left">
                          <h3 className="text-3xl md:text-4xl lg:text-5xl font-bold text-[var(--foreground)] mb-4 md:mb-6">
                            {feature.headline}
                          </h3>
                          <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed mb-8 md:mb-10">
                            {feature.description}
                          </p>
                          
                          {/* Feature Highlights */}
                          <div className="space-y-4">
                            {feature.highlights.map((highlight, i) => (
                              <div key={i} className="flex items-start gap-4 group text-left">
                                <div 
                                  className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 transition-transform duration-300 group-hover:scale-110"
                                  style={{
                                    background: `linear-gradient(135deg, ${feature.accentColor}20, ${feature.accentColor}10)`,
                                    border: `1px solid ${feature.accentColor}30`,
                                  }}
                                >
                                   <CheckIcon className="w-5 h-5" style={{ color: feature.accentColor }} />
                                </div>
                                <div>
                                  <h4 className="font-semibold text-[var(--foreground)] mb-0.5">
                                    {highlight.title}
                                  </h4>
                                  <p className="text-sm text-[var(--foreground-muted)]">
                                    {highlight.desc}
                                  </p>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TESTIMONIAL / SOCIAL PROOF
          ═══════════════════════════════════════════════════════════════ */}
      <section id="testimonial" className="py-16 md:py-24">
        <Container>
          <div className={`max-w-4xl mx-auto px-4 ${visibleSections.has('testimonial') ? 'animate-slide-up' : 'opacity-0'}`}>
            <div className="card-glass p-8 md:p-14 text-center relative overflow-hidden">
              {/* Subtle glow */}
              <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/5 via-transparent to-[var(--accent-secondary)]/5" />
              
              <div className="relative z-10">
                {/* Stars */}
                <div className="flex justify-center gap-1 mb-6">
                  {[...Array(5)].map((_, i) => (
                    <StarIcon key={i} className="w-6 h-6 md:w-7 md:h-7 text-amber-400 fill-amber-400" />
                  ))}
                </div>
                
                <blockquote className="text-xl md:text-2xl lg:text-3xl text-[var(--foreground)] leading-relaxed mb-6 font-medium">
                  "Finally, a focus app that actually helps me focus. The ambient backgrounds are beautiful, and the XP system keeps me motivated."
                </blockquote>
                
                <div className="text-sm md:text-base text-[var(--foreground-muted)]">
                  — App Store Review
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          VALUES STRIP
          ═══════════════════════════════════════════════════════════════ */}
      <section id="values" className="py-12 md:py-20 bg-[var(--background-elevated)]">
        <Container>
          <div className={`max-w-6xl mx-auto px-4 ${visibleSections.has('values') ? 'animate-slide-up' : 'opacity-0'}`}>
            <h3 className="text-center text-base md:text-lg font-medium text-[var(--foreground-muted)] mb-8">
              Built for people who value
            </h3>
            
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 md:gap-4">
              {valueProps.map((item, i) => {
                const IconComponent = item.icon;
                return (
                  <div 
                    key={i} 
                    className="flex flex-col items-center gap-2 p-4 md:p-5 rounded-2xl bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-300 group"
                  >
                    <IconComponent className="w-6 h-6 text-[var(--accent-primary)] group-hover:scale-110 transition-transform duration-300" />
                    <span className="text-sm font-semibold text-[var(--foreground)]">{item.label}</span>
                    <span className="text-xs text-[var(--foreground-subtle)]">{item.desc}</span>
                  </div>
                );
              })}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRICING SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section id="pricing" className="py-20 md:py-32 relative overflow-hidden">
        {/* Background */}
        <div className="absolute inset-0 bg-mesh opacity-40" />
        <div className="absolute top-1/4 left-1/4 w-[600px] h-[600px] rounded-full blur-[120px] opacity-20 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)]" />
        
        <Container>
          <div className="max-w-6xl mx-auto relative z-10">
            {/* Header */}
            <div className={`text-center mb-12 md:mb-16 px-4 ${visibleSections.has('pricing') ? 'animate-slide-up' : 'opacity-0'}`}>
              <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                <BoltIcon className="w-4 h-4" />
                <span>Premium Experience</span>
              </div>
              <h2 className="mb-4">FocusFlow <span className="text-gradient">Pro</span></h2>
              <p className="text-lg md:text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto mb-8">
                Unlock the full potential. Advanced features for power users.
              </p>
              
            </div>

            {/* Pricing Cards */}
            <div className={`grid md:grid-cols-3 gap-6 mb-16 items-end pt-12 px-2 md:px-0 ${visibleSections.has('pricing') ? 'animate-slide-up' : 'opacity-0'}`} style={{ animationDelay: '0.1s' }}>
              
              {/* Free */}
              <div className="card p-6 md:p-8 flex flex-col h-full order-2 md:order-1">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold text-[var(--foreground)] mb-2">Free</h3>
                  <div className="text-4xl font-bold text-[var(--foreground)] mb-1">$0</div>
                  <p className="text-sm text-[var(--foreground-subtle)]">Forever free</p>
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {['Focus timer', '3 backgrounds', '3 focus sounds', '2 themes', '3 tasks', 'Basic history'].map((feature, i) => (
                    <li key={i} className="flex items-start gap-3 text-sm text-[var(--foreground-muted)]">
                      <CheckIcon className="w-4 h-4 text-[var(--foreground-subtle)] flex-shrink-0 mt-0.5" />
                      {feature}
                    </li>
                  ))}
                </ul>
                <div className="btn btn-secondary w-full justify-center opacity-50 cursor-not-allowed mt-auto">
                  Current Plan
                </div>
              </div>

              {/* Pro Yearly - Featured */}
              <div className="relative pt-6 md:-mt-8 order-1 md:order-2">
                {/* Best Value Badge */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 z-20">
                  <div className="px-5 py-2 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white text-sm font-semibold shadow-lg shadow-[var(--accent-primary)]/40">
                    Best Value
                  </div>
                </div>
                
                <div className="card p-8 md:p-10 border-2 border-[var(--accent-primary)]/60 flex flex-col h-full shadow-xl shadow-[var(--accent-primary)]/10">
                  <div className="text-center mb-8">
                    <h3 className="text-2xl font-semibold text-gradient mb-3">Pro Yearly</h3>
                    <div className="text-5xl font-bold text-[var(--foreground)] mb-2">
                      $59.99
                    </div>
                    <p className="text-sm text-[var(--foreground-subtle)]">per year</p>
                    <div className="mt-4 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--success)]/15 text-[var(--success)] text-sm font-medium border border-[var(--success)]/20">
                      Save $11.89/year (≈17%)
                    </div>
                  </div>
                  <ul className="space-y-3 mb-10 flex-1">
                    {[
                      'Everything in Free',
                      'All 14 backgrounds',
                      'All 11 focus sounds',
                      '10 premium themes',
                      'Unlimited tasks',
                      'Full progress history',
                      'XP & leveling (50 levels)',
                      'Achievement badges',
                      'Cloud sync',
                      'Interactive widgets',
                      'Live Activity',
                      'Music integration',
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3 text-sm text-[var(--foreground-muted)]">
                        <CheckIcon className="w-5 h-5 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-accent btn-lg w-full justify-center mt-auto"
                  >
                    Start Free Trial
                  </a>
                </div>
              </div>

              {/* Pro Monthly */}
              <div className="card p-6 md:p-8 flex flex-col h-full order-3">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold text-gradient mb-2">Pro Monthly</h3>
                  <div className="text-4xl font-bold text-[var(--foreground)] mb-1">
                    $5.99
                  </div>
                  <p className="text-sm text-[var(--foreground-subtle)]">per month</p>
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {['All Pro features', 'Cancel anytime', 'Instant access', 'Full support'].map((feature, i) => (
                    <li key={i} className="flex items-start gap-3 text-sm text-[var(--foreground-muted)]">
                      <CheckIcon className="w-4 h-4 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" />
                      {feature}
                    </li>
                  ))}
                </ul>
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn btn-secondary w-full justify-center mt-auto"
                >
                  Start Free Trial
                </a>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section id="cta" className="py-20 md:py-32 bg-[var(--background-elevated)]">
        <Container>
          <div className={`max-w-3xl mx-auto text-center px-4 ${visibleSections.has('cta') ? 'animate-slide-up' : 'opacity-0'}`}>
            {/* App Icon */}
            <div className="mb-10 flex justify-center">
              <div className="relative group">
                <div className="absolute -inset-4 md:-inset-5 bg-gradient-to-br from-[var(--accent-primary)]/40 to-[var(--accent-secondary)]/30 rounded-[24px] md:rounded-[32px] blur-2xl md:blur-3xl opacity-60 group-hover:opacity-80 transition-all duration-500" />
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={120}
                  height={120}
                  className="relative rounded-[20px] md:rounded-[28px] shadow-2xl transition-all duration-500 group-hover:scale-105 w-[100px] h-[100px] md:w-[120px] md:h-[120px]"
                  style={{ 
                    boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1) inset'
                  }}
                />
              </div>
            </div>
            
            <h2 className="mb-6">Ready to build better focus habits?</h2>
            <p className="text-lg md:text-xl text-[var(--foreground-muted)] mb-10 leading-relaxed">
              Download FocusFlow and start your journey to more focused, productive work.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative inline-flex items-center justify-center gap-3 px-8 py-4 rounded-2xl text-lg font-semibold text-white overflow-hidden transition-all duration-300 hover:scale-[1.02] shadow-lg shadow-[var(--accent-primary)]/30"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]" />
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <ArrowDownTrayIcon className="w-5 h-5 relative z-10" />
                <span className="relative z-10">Download on App Store</span>
              </a>
              <Link 
                href="/support" 
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl text-lg font-semibold text-[var(--foreground)] bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-all duration-300"
              >
                Get Support
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
