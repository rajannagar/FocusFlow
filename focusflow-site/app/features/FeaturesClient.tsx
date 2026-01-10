'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { Container, PhoneSimulator } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';
import { 
  ClockIcon, CheckCircleIcon, ChartBarIcon, SwatchIcon, 
  MusicalNoteIcon, CalendarIcon, ClockIcon as ClockIconAlt, BellIcon, TagIcon, Cog6ToothIcon, CloudArrowUpIcon, 
  DevicePhoneMobileIcon, AcademicCapIcon, BookOpenIcon, ChartBarIcon as ChartBarIconAlt, FireIcon,
  HandRaisedIcon, ArrowTopRightOnSquareIcon, ShieldCheckIcon, LightBulbIcon, ChatBubbleLeftIcon, 
  LightBulbIcon as LightBulbIconAlt, SparklesIcon, ArrowRightIcon, StarIcon, BoltIcon, MoonIcon,
  PhotoIcon, SpeakerXMarkIcon, PlayIcon, ArrowPathIcon, UsersIcon
} from '@heroicons/react/24/solid';

// Animated section wrapper
const AnimatedSection = ({ 
  children, 
  className = '',
  id 
}: { 
  children: React.ReactNode; 
  className?: string;
  id?: string;
}) => {
  const ref = useRef<HTMLElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return (
    <section 
      ref={ref}
      id={id}
      className={`transition-all duration-1000 ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'} ${className}`}
    >
      {children}
    </section>
  );
};

// Feature list item component
const FeatureListItem = ({ 
  icon: Icon, 
  title, 
  description,
  color = 'violet' 
}: { 
  icon: React.ElementType; 
  title: string; 
  description: string;
  color?: string;
}) => {
  const colorClasses = {
    violet: 'from-violet-500/20 to-purple-500/10 text-violet-400 group-hover:border-violet-500/30',
    emerald: 'from-emerald-500/20 to-teal-500/10 text-emerald-400 group-hover:border-emerald-500/30',
    amber: 'from-amber-500/20 to-orange-500/10 text-amber-400 group-hover:border-amber-500/30',
    rose: 'from-rose-500/20 to-pink-500/10 text-rose-400 group-hover:border-rose-500/30',
    purple: 'from-purple-500/20 to-violet-500/10 text-purple-400 group-hover:border-purple-500/30',
  };

  return (
    <div className={`group flex items-start gap-4 p-5 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] hover:shadow-lg transition-all duration-300 ${colorClasses[color as keyof typeof colorClasses]}`}>
      <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${colorClasses[color as keyof typeof colorClasses].split(' ').slice(0, 2).join(' ')} flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform`}>
        <Icon className={`w-6 h-6 ${colorClasses[color as keyof typeof colorClasses].split(' ')[2]}`} strokeWidth={1.5} />
      </div>
      <div>
        <h3 className="text-lg font-semibold text-[var(--foreground)] mb-1">{title}</h3>
        <p className="text-[var(--foreground-muted)] leading-relaxed">{description}</p>
      </div>
    </div>
  );
};

export default function FeaturesClient() {
  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO - Immersive Features Showcase
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[70vh] flex items-center justify-center overflow-hidden pt-24">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/4 left-1/3 w-[800px] h-[800px] rounded-full blur-[200px] opacity-[0.1] transition-transform duration-[2000ms] ease-out"
            style={{
              background: `conic-gradient(from 180deg, rgba(139, 92, 246, 0.8), rgba(212, 168, 83, 0.6), rgba(139, 92, 246, 0.8))`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
        </div>
        
        <div className="absolute inset-0 bg-grid opacity-[0.03]" />
        
        <Container>
          <div className="relative z-10 max-w-5xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 text-[var(--accent-primary)] text-sm mb-8">
              <SparklesIcon className="w-4 h-4" />
              <span>Explore Features</span>
            </div>
            
            <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold mb-8 leading-[0.95]">
              <span className="text-[var(--foreground)]">Everything you need to</span>
              <br />
              <span className="text-gradient">master focus.</span>
            </h1>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto font-light mb-12">
              A complete productivity system with a beautiful focus timer, intelligent task management, 
              gamified progress tracking, and AI assistance — all in one elegant app.
            </p>

            {/* Quick nav pills */}
            <div className="flex flex-wrap justify-center gap-3">
              {[
                { label: 'Focus Timer', href: '#focus', icon: ClockIcon },
                { label: 'Tasks', href: '#tasks', icon: CheckCircleIcon },
                { label: 'Progress', href: '#progress', icon: ChartBarIcon },
                { label: 'AI Assistant', href: '#ai', icon: SparklesIcon },
                { label: 'Personalization', href: '#personalization', icon: SwatchIcon },
              ].map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  className="group flex items-center gap-2 px-5 py-3 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50 hover:text-[var(--foreground)] transition-all"
                >
                  <item.icon className="w-4 h-4 group-hover:text-[var(--accent-primary)] transition-colors" />
                  <span>{item.label}</span>
                </a>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FOCUS TIMER SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection id="focus" className="relative py-24 md:py-32">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-violet-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto">
            {/* Section header */}
            <div className="flex items-center gap-4 mb-12">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center shadow-lg shadow-violet-500/25">
                <ClockIcon className="w-7 h-7 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <span className="text-violet-400 text-sm font-medium">01</span>
                <h2 className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">Focus Timer</h2>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Content */}
              <div className="space-y-8">
                <div>
                  <h3 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                    Enter your <span className="text-gradient">flow state</span>
                  </h3>
                  <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Transform any moment into deep, focused work. Choose from stunning visuals and sounds 
                    designed to help you concentrate and stay present.
                  </p>
                </div>

                <div className="grid gap-4">
                  <FeatureListItem 
                    icon={PhotoIcon}
                    title="14 Ambient Backgrounds"
                    description="From serene forests to cosmic starfields — immersive visuals that help you focus."
                    color="violet"
                  />
                  <FeatureListItem 
                    icon={SpeakerXMarkIcon}
                    title="11 Focus Sounds"
                    description="Light rain, fireplace, ocean waves, and more — scientifically-designed soundscapes."
                    color="violet"
                  />
                  <FeatureListItem 
                    icon={MusicalNoteIcon}
                    title="Music Integration"
                    description="Connect Spotify, Apple Music, or YouTube Music to play your focus playlist (Pro)."
                    color="violet"
                  />
                  <FeatureListItem 
                    icon={TagIcon}
                    title="Session Intentions"
                    description="Set your goal before each session. Stay anchored to what matters most."
                    color="violet"
                  />
                </div>
              </div>

              {/* Right - Phone */}
              <div className="relative">
                <div className="absolute -inset-8 bg-gradient-to-r from-violet-500/20 to-purple-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png']}
                  screenData={[
                    { icon: '🌲', title: 'Forest', desc: 'Ambient scene', gradient: 'from-emerald-500 to-teal-600' },
                    { icon: '🌌', title: 'Night Sky', desc: 'Ambient scene', gradient: 'from-indigo-500 to-purple-600' },
                    { icon: '🌊', title: 'Ocean', desc: 'Ambient scene', gradient: 'from-cyan-500 to-blue-600' },
                  ]}
                />
              </div>
            </div>

            {/* Backgrounds showcase */}
            <div className="mt-16 p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)]">
              <h4 className="text-lg font-semibold text-[var(--foreground)] mb-6 text-center">All Ambient Backgrounds</h4>
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-7 gap-3">
                {[
                  { name: 'Minimal', free: true },
                  { name: 'Stars', free: true },
                  { name: 'Forest', free: true },
                  { name: 'Aurora', free: false },
                  { name: 'Night Sky', free: false },
                  { name: 'Ocean', free: false },
                  { name: 'Desert', free: false },
                  { name: 'Mountains', free: false },
                  { name: 'Fireplace', free: false },
                  { name: 'Rain', free: false },
                  { name: 'Sakura', free: false },
                  { name: 'Underwater', free: false },
                  { name: 'Nebula', free: false },
                  { name: 'Northern Lights', free: false },
                ].map((bg, i) => (
                  <div 
                    key={i} 
                    className={`relative p-3 rounded-xl text-center ${bg.free ? 'bg-[var(--background)]' : 'bg-gradient-to-br from-[var(--accent-primary)]/5 to-[var(--accent-secondary)]/5'} border border-[var(--border)]`}
                  >
                    <span className="text-sm text-[var(--foreground-muted)]">{bg.name}</span>
                    {!bg.free && (
                      <span className="absolute -top-2 -right-2 px-1.5 py-0.5 rounded text-[10px] font-medium bg-[var(--accent-primary)] text-white">PRO</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          SMART TASKS SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection id="tasks" className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-emerald-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto">
            {/* Section header */}
            <div className="flex items-center gap-4 mb-12">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center shadow-lg shadow-emerald-500/25">
                <CheckCircleIcon className="w-7 h-7 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <span className="text-emerald-400 text-sm font-medium">02</span>
                <h2 className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">Smart Tasks</h2>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Phone */}
              <div className="relative order-2 lg:order-1">
                <div className="absolute -inset-8 bg-gradient-to-r from-emerald-500/20 to-teal-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-tasks-1.png', '/images/screen-tasks-2.png', '/images/screen-tasks-3.png']}
                  screenData={[
                    { icon: '✅', title: 'Tasks', desc: 'Your list', gradient: 'from-emerald-500 to-teal-600' },
                    { icon: '➕', title: 'Add Task', desc: 'Create new', gradient: 'from-emerald-500 to-teal-600' },
                    { icon: '📋', title: 'Details', desc: 'Task info', gradient: 'from-emerald-500 to-teal-600' },
                  ]}
                />
              </div>

              {/* Right - Content */}
              <div className="space-y-8 order-1 lg:order-2">
                <div>
                  <h3 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                    Never miss <span className="text-gradient">what matters</span>
                  </h3>
                  <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Intelligent task management that adapts to how you work. Set priorities, 
                    schedule recurring tasks, and let smart reminders keep you on track.
                  </p>
                </div>

                <div className="grid gap-4">
                  <FeatureListItem 
                    icon={CalendarIcon}
                    title="Recurring Tasks"
                    description="Daily, weekly, monthly, or custom schedules. Build habits that stick."
                    color="emerald"
                  />
                  <FeatureListItem 
                    icon={BellIcon}
                    title="Smart Reminders"
                    description="Get notified at the right time. Never forget an important task again."
                    color="emerald"
                  />
                  <FeatureListItem 
                    icon={TagIcon}
                    title="Priority Levels"
                    description="High, medium, low — organize your tasks by what needs attention first."
                    color="emerald"
                  />
                  <FeatureListItem 
                    icon={ArrowPathIcon}
                    title="Quick Completion"
                    description="Swipe to complete. Satisfying interactions that make productivity fun."
                    color="emerald"
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          PROGRESS & GAMIFICATION SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection id="progress" className="relative py-24 md:py-32">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-amber-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto">
            {/* Section header */}
            <div className="flex items-center gap-4 mb-12">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center shadow-lg shadow-amber-500/25">
                <ChartBarIcon className="w-7 h-7 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <span className="text-amber-400 text-sm font-medium">03</span>
                <h2 className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">Progress & Gamification</h2>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Content */}
              <div className="space-y-8">
                <div>
                  <h3 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                    Level up your <span className="text-gradient">productivity</span>
                  </h3>
                  <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Turn focus into a game you'll want to play every day. Earn XP, unlock achievements, 
                    and watch yourself transform from Beginner to Transcendent.
                  </p>
                </div>

                {/* Stats grid */}
                <div className="grid grid-cols-2 gap-4">
                  {[
                    { value: '50', label: 'Levels', icon: ChartBarIcon },
                    { value: '20+', label: 'Achievements', icon: AcademicCapIcon },
                    { value: '∞', label: 'XP Potential', icon: SparklesIcon },
                    { value: '365', label: 'Day Streaks', icon: FireIcon },
                  ].map((stat, i) => (
                    <div key={i} className="p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] text-center group hover:border-amber-500/30 transition-all">
                      <stat.icon className="w-6 h-6 text-amber-400 mx-auto mb-3 group-hover:scale-110 transition-transform" />
                      <div className="text-3xl font-bold text-[var(--foreground)]">{stat.value}</div>
                      <div className="text-sm text-[var(--foreground-muted)]">{stat.label}</div>
                    </div>
                  ))}
                </div>

                <div className="grid gap-4">
                  <FeatureListItem 
                    icon={AcademicCapIcon}
                    title="Achievement Badges"
                    description="Unlock beautiful badges for milestones. Celebrate every win (Pro)."
                    color="amber"
                  />
                  <FeatureListItem 
                    icon={BookOpenIcon}
                    title="Journey View"
                    description="See daily summaries and weekly reviews. Reflect on your growth (Pro)."
                    color="amber"
                  />
                  <FeatureListItem 
                    icon={ChartBarIconAlt}
                    title="Detailed Analytics"
                    description="Track focus time, completion rates, and patterns over time."
                    color="amber"
                  />
                </div>
              </div>

              {/* Right - Phone */}
              <div className="relative">
                <div className="absolute -inset-8 bg-gradient-to-r from-amber-500/20 to-orange-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png']}
                  screenData={[
                    { icon: '📈', title: 'Stats', desc: 'Overview', gradient: 'from-amber-500 to-orange-600' },
                    { icon: '🏆', title: 'Badges', desc: 'Achievements', gradient: 'from-amber-500 to-orange-600' },
                    { icon: '📅', title: 'Journey', desc: 'Your history', gradient: 'from-amber-500 to-orange-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          AI ASSISTANT SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection id="ai" className="relative py-24 md:py-32 bg-gradient-to-b from-[var(--background-elevated)] via-purple-500/5 to-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-purple-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto">
            {/* Section header */}
            <div className="flex items-center gap-4 mb-12">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-purple-500 to-pink-600 flex items-center justify-center shadow-lg shadow-purple-500/25">
                <SparklesIcon className="w-7 h-7 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-purple-400 text-sm font-medium">04</span>
                  <span className="px-2 py-0.5 rounded-full bg-purple-500/20 text-purple-400 text-xs font-medium">PRO</span>
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">Flow AI Assistant</h2>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Phone */}
              <div className="relative order-2 lg:order-1">
                <div className="absolute -inset-8 bg-gradient-to-r from-purple-500/20 to-pink-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-focus.png', '/images/screen-tasks.png', '/images/screen-progress.png']}
                  screenData={[
                    { icon: '🤖', title: 'Flow', desc: 'AI Chat', gradient: 'from-purple-500 to-pink-600' },
                    { icon: '💡', title: 'Insights', desc: 'AI Analysis', gradient: 'from-purple-500 to-pink-600' },
                    { icon: '✨', title: 'Suggestions', desc: 'AI Tips', gradient: 'from-purple-500 to-pink-600' },
                  ]}
                />
              </div>

              {/* Right - Content */}
              <div className="space-y-8 order-1 lg:order-2">
                <div>
                  <h3 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                    Meet <span className="text-gradient">Flow</span>, your AI companion
                  </h3>
                  <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Your intelligent productivity partner powered by GPT-4o. Get help with task management, 
                    receive personalized insights, and have natural conversations about your work.
                  </p>
                </div>

                <div className="grid gap-4">
                  <FeatureListItem 
                    icon={LightBulbIcon}
                    title="Powered by GPT-4o"
                    description="Advanced AI that understands context and provides intelligent, personalized responses."
                    color="purple"
                  />
                  <FeatureListItem 
                    icon={ChatBubbleLeftIcon}
                    title="Natural Conversations"
                    description="Chat naturally like you would with a productivity coach. Ask anything."
                    color="purple"
                  />
                  <FeatureListItem 
                    icon={LightBulbIcon}
                    title="Smart Suggestions"
                    description="Get task recommendations and productivity tips based on your patterns."
                    color="purple"
                  />
                  <FeatureListItem 
                    icon={ShieldCheckIcon}
                    title="Privacy Protected"
                    description="Your conversations aren't used to train AI. OpenAI deletes data after 30 days."
                    color="purple"
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          PERSONALIZATION SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection id="personalization" className="relative py-24 md:py-32">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-rose-500/20 to-transparent" />
        
        <Container>
          <div className="max-w-7xl mx-auto">
            {/* Section header */}
            <div className="flex items-center gap-4 mb-12">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-rose-500 to-pink-600 flex items-center justify-center shadow-lg shadow-rose-500/25">
                <SwatchIcon className="w-7 h-7 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <span className="text-rose-400 text-sm font-medium">05</span>
                <h2 className="text-3xl md:text-4xl font-bold text-[var(--foreground)]">Personalization</h2>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
              {/* Left - Content */}
              <div className="space-y-8">
                <div>
                  <h3 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                    Make it <span className="text-gradient">yours</span>
                  </h3>
                  <p className="text-xl text-[var(--foreground-muted)] leading-relaxed font-light">
                    Customize every aspect of your FocusFlow experience. Choose themes, create presets, 
                    and sync everything across all your devices.
                  </p>
                </div>

                <div className="grid gap-4">
                  <FeatureListItem 
                    icon={SwatchIcon}
                    title="10 Beautiful Themes"
                    description="Forest, Neon (Free), plus 8 Pro themes to match your style."
                    color="rose"
                  />
                  <FeatureListItem 
                    icon={Cog6ToothIcon}
                    title="Custom Presets"
                    description="Save your favorite combinations of timer, sounds, and settings."
                    color="rose"
                  />
                  <FeatureListItem 
                    icon={CloudArrowUpIcon}
                    title="Cloud Sync"
                    description="Access your data from any device. Encrypted and secure (Pro)."
                    color="rose"
                  />
                  <FeatureListItem 
                    icon={DevicePhoneMobileIcon}
                    title="Interactive Widgets"
                    description="Control your timer right from your home screen (Pro)."
                    color="rose"
                  />
                </div>
              </div>

              {/* Right - Phone */}
              <div className="relative">
                <div className="absolute -inset-8 bg-gradient-to-r from-rose-500/20 to-pink-500/10 blur-[100px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-profile.png', '/images/screen-profile.png', '/images/screen-profile.png']}
                  screenData={[
                    { icon: '👤', title: 'Profile', desc: 'Your space', gradient: 'from-rose-500 to-pink-600' },
                    { icon: '🎨', title: 'Themes', desc: 'Customize', gradient: 'from-rose-500 to-pink-600' },
                    { icon: '⚙️', title: 'Settings', desc: 'Configure', gradient: 'from-rose-500 to-pink-600' },
                  ]}
                />
              </div>
            </div>

            {/* Themes showcase */}
            <div className="mt-16 p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)]">
              <h4 className="text-lg font-semibold text-[var(--foreground)] mb-6 text-center">Available Themes</h4>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
                {[
                  { name: 'Forest', color: 'bg-emerald-600', free: true },
                  { name: 'Neon Glow', color: 'bg-violet-600', free: true },
                  { name: 'Soft Peach', color: 'bg-orange-300', free: false },
                  { name: 'Cyber Violet', color: 'bg-purple-600', free: false },
                  { name: 'Ocean Mist', color: 'bg-cyan-500', free: false },
                  { name: 'Sunrise Coral', color: 'bg-rose-400', free: false },
                  { name: 'Solar Amber', color: 'bg-amber-500', free: false },
                  { name: 'Mint Aura', color: 'bg-teal-400', free: false },
                  { name: 'Royal Indigo', color: 'bg-indigo-600', free: false },
                  { name: 'Cosmic Slate', color: 'bg-slate-600', free: false },
                ].map((theme, i) => (
                  <div key={i} className="relative text-center">
                    <div className={`w-full aspect-[3/2] ${theme.color} rounded-xl mb-2`} />
                    <span className="text-sm text-[var(--foreground-muted)]">{theme.name}</span>
                    {!theme.free && (
                      <span className="absolute top-1 right-1 px-1.5 py-0.5 rounded text-[10px] font-medium bg-black/50 text-white">PRO</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          MORE FEATURES
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold mb-4">
                And <span className="text-gradient">so much more</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)]">Features designed to help you focus better</p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                { icon: DevicePhoneMobileIcon, title: 'Home Screen Widgets', desc: 'View and control your timer from your home screen (Pro)', pro: true },
                { icon: BellIcon, title: 'Live Activity', desc: 'See your timer in Dynamic Island and Lock Screen (Pro)', pro: true },
                { icon: HandRaisedIcon, title: 'Offline Mode', desc: 'Works perfectly without internet. Syncs when online', pro: false },
                { icon: ShieldCheckIcon, title: 'Privacy First', desc: 'No ads, no tracking. Your data stays encrypted', pro: false },
                { icon: BoltIcon, title: 'Lightning Fast', desc: 'Smooth animations and instant sync', pro: false },
                { icon: UsersIcon, title: 'Cross-Platform', desc: 'iOS app now, Web app coming soon', pro: false },
              ].map((feature, i) => (
                <div 
                  key={i}
                  className="group relative p-8 rounded-3xl bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-300"
                >
                  {feature.pro && (
                    <span className="absolute top-4 right-4 px-2 py-1 rounded-full bg-[var(--accent-primary)]/10 text-[var(--accent-primary)] text-xs font-medium">PRO</span>
                  )}
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                    <feature.icon className="w-7 h-7 text-[var(--accent-primary)]" strokeWidth={1.5} />
                  </div>
                  <h3 className="text-xl font-bold text-[var(--foreground)] mb-2">{feature.title}</h3>
                  <p className="text-[var(--foreground-muted)]">{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          CTA SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-24 md:py-32 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-[var(--background-elevated)] via-[var(--accent-primary)]/5 to-[var(--background)]" />
        
        <Container>
          <div className="relative max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-8">
              Experience the <span className="text-gradient">flow</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 font-light">
              Download FocusFlow and discover how all these features work together 
              to help you build better focus habits.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group relative px-10 py-5 rounded-2xl bg-[var(--foreground)] text-[var(--background)] font-semibold text-xl overflow-hidden transition-all duration-500 hover:scale-[1.02] hover:shadow-[0_30px_80px_rgba(245,240,232,0.3)]"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                <div className="relative z-10 flex items-center justify-center gap-3 group-hover:text-white transition-colors">
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  <span>Download Free</span>
                </div>
              </a>
              
              <Link
                href="/pricing"
                className="px-10 py-5 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-xl hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3"
              >
                View Pricing
                <ArrowRightIcon className="w-5 h-5" />
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
