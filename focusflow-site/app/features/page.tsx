'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import { Container, PhoneSimulator } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';
import { 
  Timer, CheckSquare, TrendingUp, Palette, Link2,
  Music, Radio, 
  Calendar, Clock, Bell, Target, Settings, CloudUpload, 
  Smartphone, Award, BookOpen, BarChart3, Flame as FlameIcon,
  Headphones, Plane, Shield
} from 'lucide-react';

export default function FeaturesPage() {
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
        </div>
        <div className="absolute inset-0 bg-grid opacity-[0.02]" />

        <Container>
          <div className="relative z-10 max-w-6xl mx-auto px-4 md:px-6">
            <div className="text-center mb-12 md:mb-16">
              <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold mb-6 md:mb-8 leading-tight">
                Everything flows <span className="text-gradient">together</span>
              </h1>
              <p className="text-xl md:text-2xl lg:text-3xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-3xl mx-auto">
                FocusFlow isn't just separate features—it's a seamless system where timer, tasks, and progress work together to help you build better focus habits.
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FOCUS TIMER SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[0] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Subtle violet gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-violet-500/5 via-transparent to-transparent pointer-events-none" />
        
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto px-4 md:px-6">
            {/* Section number badge */}
            <div className="flex items-center gap-4 mb-8 md:mb-12">
              <div className="flex items-center gap-2 md:gap-3">
                <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-gradient-to-br from-violet-500/20 to-violet-600/10 flex items-center justify-center border border-violet-500/20">
                  <span className="text-lg md:text-xl font-bold text-violet-400">1</span>
                </div>
                <div className="h-px w-12 md:w-16 bg-gradient-to-r from-violet-500/30 to-transparent" />
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center mb-16 md:mb-20">
              <div className="flex justify-center order-1">
                <div className="relative w-full max-w-[280px] md:max-w-[320px]">
                  <div className="absolute -inset-6 md:-inset-8 bg-gradient-to-r from-violet-500/30 to-purple-500/20 blur-[60px] md:blur-[80px] scale-150" />
                  <PhoneSimulator 
                    screenshots={['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png']}
                    screenData={[
                      { icon: '⏱️', title: 'Timer', desc: 'Start session', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '⏱️', title: 'Timer', desc: 'In progress', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '⏱️', title: 'Timer', desc: 'Complete', gradient: 'from-violet-500 to-purple-600' },
                    ]}
                  />
                </div>
              </div>
              <div className="order-2 space-y-6">
                <div>
                  <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 md:mb-6">Deep focus, beautiful ambiance</h2>
                  <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Start timed sessions with customizable durations. Choose from 14 ambient backgrounds, 11 focus sounds, or connect your music app. Set session intentions to stay focused on what matters.
                  </p>
                </div>
                <div className="space-y-3">
                  {[
                    { icon: Palette, title: '14 Ambient Backgrounds', desc: 'Aurora, Rain, Fireplace, Ocean, Forest, Stars, Snow, Underwater, Clouds, Sakura, Lightning, Lava Lamp, Gradient Flow, Minimal (3 free, 14 Pro)' },
                    { icon: Music, title: '11 Focus Sounds', desc: 'Light Rain, Cozy Fireplace, Soft Ambience, Floating Garden, Underwater, French Street Market, The Light Between Us, Angels by My Side, Hearty, Long Night, Yesterday (3 free, 11 Pro)' },
                    { icon: Headphones, title: 'Music Integration', desc: 'Connect Spotify, Apple Music, or YouTube Music to play your favorite tracks during focus sessions (Pro)' },
                    { icon: Bell, title: 'Live Activity', desc: 'See your timer in Dynamic Island and Lock Screen. Control without opening the app (Pro)' },
                    { icon: Target, title: 'Session Intentions', desc: 'Set a focus goal for each session to stay anchored on what you want to accomplish' },
                    { icon: Settings, title: 'Custom Presets', desc: 'Save your favorite combinations of duration, background, sound, and theme for quick access (3 free, unlimited Pro)' },
                  ].map((item, i) => {
                    const Icon = item.icon;
                    return (
                      <div key={i} className="group relative p-5 md:p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all hover:shadow-lg">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                            <Icon className="w-6 h-6 md:w-7 md:h-7 text-[var(--accent-primary)]" strokeWidth={1.5} />
                          </div>
                          <div className="flex-1 pt-1">
                            <h3 className="text-base md:text-lg font-semibold text-[var(--foreground)] mb-1 md:mb-2">{item.title}</h3>
                            <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TASKS SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[1] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Subtle emerald gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-emerald-500/5 via-transparent to-transparent pointer-events-none" />
        
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-emerald-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto px-4 md:px-6">
            {/* Section number badge */}
            <div className="flex items-center gap-4 mb-8 md:mb-12">
              <div className="flex items-center gap-2 md:gap-3">
                <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 flex items-center justify-center border border-emerald-500/20">
                  <span className="text-lg md:text-xl font-bold text-emerald-400">2</span>
                </div>
                <div className="h-px w-12 md:w-16 bg-gradient-to-r from-emerald-500/30 to-transparent" />
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center mb-16 md:mb-20">
              <div className="order-2 lg:order-1 space-y-6">
                <div>
                  <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 md:mb-6">Smart task management</h2>
                  <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Organize your to-dos with recurring schedules, reminders, and focus session integration. Track duration estimates and see your progress at a glance.
                  </p>
                </div>
                <div className="space-y-3">
                  {[
                    { icon: Calendar, title: 'Recurring Tasks', desc: 'Set tasks to repeat daily, weekly, monthly, or create custom schedules. Perfect for habits and routines.' },
                    { icon: Clock, title: 'Duration Estimates', desc: 'Set how long each task should take. Track actual vs estimated time to improve your planning.' },
                    { icon: CheckSquare, title: 'Task Limits', desc: '3 tasks (Free) or unlimited tasks (Pro). Organize everything without limits.' },
                    { icon: Bell, title: 'Smart Reminders', desc: 'Never miss important tasks. Get notified at the right time to stay on track.' },
                    { icon: Link2, title: 'Focus Session Integration', desc: 'Link tasks to focus sessions. Complete tasks while in flow state for maximum productivity.' },
                    { icon: Calendar, title: 'Date-Based View', desc: 'See all your tasks for any day. Navigate through your calendar to plan ahead or review past days.' },
                  ].map((item, i) => {
                    const Icon = item.icon;
                    return (
                      <div key={i} className="group relative p-5 md:p-6 rounded-2xl bg-[var(--background)] border border-[var(--border)] hover:border-emerald-500/30 transition-all hover:shadow-lg">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                            <Icon className="w-6 h-6 md:w-7 md:h-7 text-emerald-400" strokeWidth={1.5} />
                          </div>
                          <div className="flex-1 pt-1">
                            <h3 className="text-base md:text-lg font-semibold text-[var(--foreground)] mb-1 md:mb-2">{item.title}</h3>
                            <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
              <div className="flex justify-center order-1 lg:order-2">
                <div className="relative w-full max-w-[280px] md:max-w-[320px]">
                  <div className="absolute -inset-6 md:-inset-8 bg-gradient-to-r from-emerald-500/30 to-teal-500/20 blur-[60px] md:blur-[80px] scale-150" />
                  <PhoneSimulator 
                    screenshots={['/images/screen-tasks-1.png', '/images/screen-tasks-2.png', '/images/screen-tasks-3.png']}
                    screenData={[
                      { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Create task', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Details', gradient: 'from-emerald-500 to-teal-600' },
                    ]}
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PROGRESS SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[2] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Subtle amber gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-amber-500/5 via-transparent to-transparent pointer-events-none" />
        
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-amber-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto px-4 md:px-6">
            {/* Section number badge */}
            <div className="flex items-center gap-4 mb-8 md:mb-12">
              <div className="flex items-center gap-2 md:gap-3">
                <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-gradient-to-br from-amber-500/20 to-amber-600/10 flex items-center justify-center border border-amber-500/20">
                  <span className="text-lg md:text-xl font-bold text-amber-400">3</span>
                </div>
                <div className="h-px w-12 md:w-16 bg-gradient-to-r from-amber-500/30 to-transparent" />
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center mb-16 md:mb-20">
              <div className="flex justify-center order-1">
                <div className="relative w-full max-w-[280px] md:max-w-[320px]">
                  <div className="absolute -inset-6 md:-inset-8 bg-gradient-to-r from-amber-500/30 to-orange-500/20 blur-[60px] md:blur-[80px] scale-150" />
                  <PhoneSimulator 
                    screenshots={['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png']}
                    screenData={[
                      { icon: '📈', title: 'Progress', desc: 'Summary', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '📈', title: 'Progress', desc: 'Journey', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '📈', title: 'Progress', desc: 'Badges', gradient: 'from-amber-500 to-orange-600' },
                    ]}
                  />
                </div>
              </div>
              <div className="order-2 space-y-6">
                <div>
                  <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 md:mb-6">Track your growth</h2>
                  <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Every focus session and completed task earns XP. Level up through 50 ranks, unlock achievement badges, and see your journey unfold.
                  </p>
                </div>
                <div className="space-y-3">
                  {[
                    { icon: Award, title: 'XP & 50 Levels', desc: 'Earn XP for every completed focus session and task. Progress through 50 levels from Beginner to Transcendent (Pro)' },
                    { icon: Award, title: 'Achievement Badges', desc: 'Unlock milestones and rewards as you build consistency. Celebrate your progress with beautiful badges (Pro)' },
                    { icon: BookOpen, title: 'Journey View', desc: 'See daily summaries and weekly reviews. Reflect on your progress and understand your patterns (Pro)' },
                    { icon: BarChart3, title: 'Progress History', desc: 'Last 3 days (Free) or full history (Pro). See how you\'ve grown over time with detailed analytics.' },
                    { icon: FlameIcon, title: 'Streak Tracking', desc: 'Build consistency over time. Track your daily focus streaks and maintain momentum.' },
                    { icon: TrendingUp, title: 'Focus Score', desc: 'Get insights into your focus patterns. Compare weeks and see trends in your productivity.' },
                  ].map((item, i) => {
                    const Icon = item.icon;
                    return (
                      <div key={i} className="group relative p-5 md:p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-amber-500/30 transition-all hover:shadow-lg">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-amber-500/20 to-amber-600/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                            <Icon className="w-6 h-6 md:w-7 md:h-7 text-amber-400" strokeWidth={1.5} />
                          </div>
                          <div className="flex-1 pt-1">
                            <h3 className="text-base md:text-lg font-semibold text-[var(--foreground)] mb-1 md:mb-2">{item.title}</h3>
                            <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PERSONALIZATION SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[3] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Subtle rose gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-rose-500/5 via-transparent to-transparent pointer-events-none" />
        
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-rose-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto px-4 md:px-6">
            {/* Section number badge */}
            <div className="flex items-center gap-4 mb-8 md:mb-12">
              <div className="flex items-center gap-2 md:gap-3">
                <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-gradient-to-br from-rose-500/20 to-rose-600/10 flex items-center justify-center border border-rose-500/20">
                  <span className="text-lg md:text-xl font-bold text-rose-400">4</span>
                </div>
                <div className="h-px w-12 md:w-16 bg-gradient-to-r from-rose-500/30 to-transparent" />
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center mb-16 md:mb-20">
              <div className="order-2 lg:order-1 space-y-6">
                <div>
                  <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 md:mb-6">Make it yours</h2>
                  <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Personalize every aspect of your experience. Choose your avatar, pick your theme, create custom presets, and sync across all your devices.
                  </p>
                </div>
                <div className="space-y-3">
                  {[
                    { icon: Palette, title: '10 Beautiful Themes', desc: 'Forest, Neon (Free), plus 8 Pro themes: Soft Peach, Cyber Violet, Ocean Mist, Sunrise Coral, Solar Amber, Mint Aura, Royal Indigo, Cosmic Slate' },
                    { icon: Settings, title: '50+ Symbol Avatars', desc: 'Express yourself without photos. Choose from a wide selection of symbol avatars to represent you.' },
                    { icon: Settings, title: 'Custom Focus Presets', desc: 'Save your favorite combinations: duration, background, sound, theme, and music app. Quick access to your perfect focus setup (3 free, unlimited Pro)' },
                    { icon: CloudUpload, title: 'Cloud Sync', desc: 'Sync your sessions, tasks, progress, presets, and settings across all your devices. Your data is encrypted and secure (Pro + sign-in required)' },
                    { icon: Smartphone, title: 'Interactive Widgets', desc: 'Control your timer from your home screen. Start, pause, and see progress without opening the app (Pro)' },
                    { icon: Bell, title: 'Notification Settings', desc: 'Customize when and how you receive reminders. Control your focus environment completely.' },
                  ].map((item, i) => {
                    const Icon = item.icon;
                    return (
                      <div key={i} className="group relative p-5 md:p-6 rounded-2xl bg-[var(--background)] border border-[var(--border)] hover:border-rose-500/30 transition-all hover:shadow-lg">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-rose-500/20 to-rose-600/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                            <Icon className="w-6 h-6 md:w-7 md:h-7 text-rose-400" strokeWidth={1.5} />
                          </div>
                          <div className="flex-1 pt-1">
                            <h3 className="text-base md:text-lg font-semibold text-[var(--foreground)] mb-1 md:mb-2">{item.title}</h3>
                            <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
              <div className="flex justify-center order-1 lg:order-2">
                <div className="relative w-full max-w-[280px] md:max-w-[320px]">
                  <div className="absolute -inset-6 md:-inset-8 bg-gradient-to-r from-rose-500/30 to-pink-500/20 blur-[60px] md:blur-[80px] scale-150" />
                  <PhoneSimulator 
                    screenshots={['/images/screen-profile.png', '/images/screen-profile-2.png', '/images/screen-profile-3.png']}
                    screenData={[
                      { icon: '👤', title: 'Profile', desc: 'Your space', gradient: 'from-rose-500 to-pink-600' },
                      { icon: '👤', title: 'Profile', desc: 'Themes', gradient: 'from-rose-500 to-pink-600' },
                      { icon: '👤', title: 'Profile', desc: 'Settings', gradient: 'from-rose-500 to-pink-600' },
                    ]}
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          ADDITIONAL FEATURES
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-24">
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto px-4 md:px-6">
            <h2 className="text-3xl md:text-5xl font-bold text-center mb-12 md:mb-16">And so much more</h2>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                { icon: Smartphone, title: 'Widgets', desc: 'View timer and tasks on your home screen. Interactive widgets let you control the timer (Pro)' },
                { icon: Bell, title: 'Live Activity', desc: 'See your timer in Dynamic Island and Lock Screen. Control without opening the app (Pro)' },
                { icon: CloudUpload, title: 'Cloud Sync', desc: 'Sync your sessions, tasks, progress, and settings across all devices. Encrypted and secure (Pro)' },
                { icon: Headphones, title: 'Music Integration', desc: 'Connect Spotify, Apple Music, or YouTube Music to play during focus sessions (Pro)' },
                { icon: Plane, title: 'Offline Mode', desc: 'Full functionality without internet. Works perfectly offline, syncs when you\'re back online' },
                { icon: Shield, title: 'Privacy First', desc: 'Your data stays yours. Always encrypted, never sold. No ads, no tracking, just pure focus' },
              ].map((feature, i) => {
                const Icon = feature.icon;
                return (
                  <div key={i} className="group p-6 md:p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-all hover:scale-105 hover:shadow-xl">
                    <div className="w-16 h-16 md:w-18 md:h-18 rounded-3xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center mb-4 md:mb-6 group-hover:scale-110 transition-transform shadow-lg">
                      <Icon className="w-8 h-8 md:w-9 md:h-9 text-[var(--accent-primary)]" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-lg md:text-xl font-bold text-[var(--foreground)] mb-2 md:mb-3">{feature.title}</h3>
                    <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{feature.desc}</p>
                  </div>
                );
              })}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-24 bg-[var(--background-elevated)]">
        {/* Section divider - top */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto text-center px-4 md:px-6">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">
              Experience the <span className="text-gradient">flow</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 md:mb-16 leading-relaxed font-light">
              Download FocusFlow and discover how timer, tasks, and progress work together to help you build better focus habits.
            </p>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="group relative inline-flex items-center gap-3 px-8 md:px-10 py-4 md:py-5 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg md:text-xl overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl hover:shadow-[var(--accent-primary)]/40"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <svg className="w-6 h-6 relative z-10" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
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
