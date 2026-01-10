'use client';

import { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { CONTACT_EMAIL } from '@/lib/constants';
import { ShieldCheckIcon, LockClosedIcon, EyeIcon, ServerIcon, TrashIcon, LightBulbIcon, ChevronRightIcon, SparklesIcon } from '@heroicons/react/24/solid';

// Animated section wrapper
const AnimatedSection = ({ 
  children, 
  className = ''
}: { 
  children: React.ReactNode; 
  className?: string;
}) => {
  const ref = useRef<HTMLElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) setIsVisible(true);
      },
      { threshold: 0.1 }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return (
    <section 
      ref={ref}
      className={`transition-all duration-700 ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'} ${className}`}
    >
      {children}
    </section>
  );
};

export default function PrivacyClient() {
  const mousePosition = useThrottledMouse();
  const [activeSection, setActiveSection] = useState('');

  const sections = [
    { id: 'summary', title: 'Summary', icon: EyeIcon },
    { id: 'data-stored', title: 'Data the App Stores', icon: ServerIcon },
    { id: 'data-location', title: 'Where Your Data is Stored', icon: ServerIcon },
    { id: 'not-collected', title: 'What We Do Not Collect', icon: LockClosedIcon },
    { id: 'data-use', title: 'How We Use Data', icon: EyeIcon },
    { id: 'sharing', title: 'Sharing', icon: EyeIcon },
    { id: 'ai-assistant', title: 'AI Assistant (Flow)', icon: SparklesIcon },
    { id: 'diagnostics', title: 'Diagnostics', icon: EyeIcon },
    { id: 'retention', title: 'Retention', icon: ServerIcon },
    { id: 'your-rights', title: 'Your Rights', icon: ShieldCheckIcon },
    { id: 'account-deletion', title: 'Account Deletion', icon: TrashIcon },
    { id: 'children', title: "Children's Privacy", icon: ShieldCheckIcon },
    { id: 'changes', title: 'Changes', icon: EyeIcon },
  ];

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection(entry.target.id);
          }
        });
      },
      { rootMargin: '-100px 0px -60% 0px' }
    );

    sections.forEach((section) => {
      const el = document.getElementById(section.id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-24 pb-12 overflow-hidden">
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/3 left-1/4 w-[500px] h-[500px] rounded-full blur-[150px] opacity-[0.05] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(16, 185, 129, 0.8) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
        </div>
        
        <Container>
          <div className="max-w-4xl mx-auto">
            {/* Breadcrumb */}
            <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)] mb-6">
              <Link href="/" className="hover:text-[var(--accent-primary)] transition-colors">Home</Link>
              <ChevronRightIcon className="w-4 h-4" />
              <span className="text-[var(--foreground)]">Privacy Policy</span>
            </div>
            
            {/* Header */}
            <div className="flex items-start gap-6 mb-8">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center flex-shrink-0 shadow-lg shadow-emerald-500/20">
                <ShieldCheckIcon className="w-8 h-8 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <h1 className="text-4xl md:text-5xl font-bold text-[var(--foreground)] mb-2">Privacy Policy</h1>
                <p className="text-[var(--foreground-muted)]">Effective: January 9, 2026</p>
              </div>
            </div>
            
            {/* Intro */}
            <p className="text-lg text-[var(--foreground-muted)] leading-relaxed p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
              This Privacy Policy explains how FocusFlow - Be Present ("FocusFlow", "the app") handles your information. 
              Soft Computers ("we", "us") is the developer of FocusFlow.
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          MAIN CONTENT WITH SIDEBAR NAV
          ═══════════════════════════════════════════════════════════════ */}
      <section className="py-12 md:py-16">
        <Container>
          <div className="max-w-6xl mx-auto flex gap-12">
            
            {/* Sidebar Navigation - Desktop */}
            <nav className="hidden lg:block w-64 flex-shrink-0">
              <div className="sticky top-24 p-4 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
                <h3 className="text-sm font-semibold text-[var(--foreground)] uppercase tracking-wider mb-4 px-3">Contents</h3>
                <ul className="space-y-1">
                  {sections.map((section, i) => (
                    <li key={section.id}>
                      <a 
                        href={`#${section.id}`}
                        className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all ${
                          activeSection === section.id 
                            ? 'bg-[var(--accent-primary)]/10 text-[var(--accent-primary)] font-medium' 
                            : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background)]'
                        }`}
                      >
                        <span className="w-5 text-center text-xs opacity-50">{i + 1}</span>
                        <span className="truncate">{section.title}</span>
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            </nav>

            {/* Main Content */}
            <div className="flex-1 max-w-3xl">
              <div className="space-y-16">
                
                {/* 1. Summary */}
                <AnimatedSection>
                  <section id="summary" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">1</span>
                      Summary
                    </h2>
                    <ul className="space-y-4">
                      {[
                        { label: 'Guest Mode', text: 'Your data is stored locally on your device only.' },
                        { label: 'Signed-in Mode', text: 'Your data may be synced to a secure cloud backend to support backup and multi-device use.' },
                        { label: '', text: 'We do not sell personal information and the app is not ad-supported.' },
                        { label: 'AI Assistant', text: 'The optional AI assistant (Flow) uses OpenAI to process your queries. Your messages and relevant app context are sent to OpenAI for processing, retained for 30 days, and are not used to train AI models.' },
                        { label: '', text: 'We do not require photo library access (avatars are symbol-based).' },
                        { label: '', text: 'You can delete your account and all associated data at any time from within the app.' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-4 p-4 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)]">
                          <span className="text-emerald-500 mt-1">✓</span>
                          <span className="text-[var(--foreground-muted)]">
                            {item.label && <strong className="text-[var(--foreground)]">{item.label}:</strong>} {item.text}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 2. Data the App Stores */}
                <AnimatedSection>
                  <section id="data-stored" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">2</span>
                      Data the App Stores
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-6">Depending on how you use FocusFlow, we may store:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Account data (Signed-in Mode only)', text: 'Email address (if provided), display name, and authentication identifiers.' },
                        { label: 'Focus data', text: 'Session duration, timestamps, session names/intentions, ambient background selections, focus sound preferences, and derived statistics.' },
                        { label: 'Task data', text: 'Task titles, notes, schedules, reminders, duration estimates, completion records, and task status.' },
                        { label: 'Preset data', text: 'Custom focus presets including names, durations, ambient background selections, focus sound preferences, and theme preferences.' },
                        { label: 'Progress data', text: 'XP points, level progression, achievement badges, journey milestones, and historical session data.' },
                        { label: 'Settings & preferences', text: 'Theme selections, daily goals, reminder preferences, sound/haptic settings, avatar selection, notification preferences, and app customization options.' },
                        { label: 'AI conversation data (Pro, optional)', text: 'When you use the Flow AI assistant, conversation history is stored locally and in the cloud (if signed in). Messages are also sent to OpenAI for processing.' },
                        { label: 'Subscription data', text: 'Apple handles all payment information. We only receive confirmation of your Pro subscription status.' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span><strong className="text-[var(--foreground)]">{item.label}:</strong> {item.text}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 3. Where Your Data is Stored */}
                <AnimatedSection>
                  <section id="data-location" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">3</span>
                      Where Your Data is Stored
                    </h2>
                    <div className="space-y-4">
                      <div className="p-5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)]">
                        <h3 className="font-semibold text-[var(--foreground)] mb-2">Guest Mode</h3>
                        <p className="text-[var(--foreground-muted)]">On your device only. Data is never sent to our servers.</p>
                      </div>
                      <div className="p-5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)]">
                        <h3 className="font-semibold text-[var(--foreground)] mb-2">Signed-in Mode</h3>
                        <p className="text-[var(--foreground-muted)]">Synced to a secure cloud backend (Supabase) with Row-Level Security (RLS) policies designed to isolate each user's data. Infrastructure is hosted on Amazon Web Services (AWS) with data centers primarily in the United States.</p>
                      </div>
                    </div>
                  </section>
                </AnimatedSection>

                {/* 4. What We Do Not Collect */}
                <AnimatedSection>
                  <section id="not-collected" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">4</span>
                      What We Do Not Collect
                    </h2>
                    <div className="grid sm:grid-cols-2 gap-4">
                      {[
                        'Photos, contacts, or precise location',
                        'Analytics or tracking SDKs',
                        'Advertisements',
                        'Personal information for sale',
                      ].map((item, i) => (
                        <div key={i} className="flex items-center gap-3 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                          <LockClosedIcon className="w-5 h-5 flex-shrink-0" />
                          <span className="text-[var(--foreground-muted)]">No {item.toLowerCase()}</span>
                        </div>
                      ))}
                    </div>
                  </section>
                </AnimatedSection>

                {/* 5. How We Use Data */}
                <AnimatedSection>
                  <section id="data-use" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">5</span>
                      How We Use Data
                    </h2>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'To provide app functionality (focus sessions, tasks, progress tracking)',
                        'To sync your data across devices (if signed in)',
                        'To process AI assistant queries (if you use Flow)',
                        'To verify subscription status with Apple',
                        'To respond to support requests',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 6. Sharing */}
                <AnimatedSection>
                  <section id="sharing" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">6</span>
                      Sharing
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-4">We do not sell or share your personal information with third parties except:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Cloud infrastructure', text: 'Supabase (for data storage and sync)' },
                        { label: 'AI processing', text: 'OpenAI (for Flow AI assistant queries, Pro feature only)' },
                        { label: 'Payment processing', text: 'Apple (for subscription verification)' },
                        { label: 'Legal requirements', text: 'If required by law or to protect our rights' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span><strong className="text-[var(--foreground)]">{item.label}:</strong> {item.text}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 7. AI Assistant (Flow) */}
                <AnimatedSection>
                  <section id="ai-assistant" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-purple-500/10 flex items-center justify-center text-purple-400 text-sm font-bold">7</span>
                      AI Assistant (Flow)
                    </h2>
                    <div className="p-6 rounded-2xl bg-purple-500/10 border border-purple-500/20 mb-6">
                      <div className="flex items-center gap-3 mb-4">
                        <SparklesIcon className="w-6 h-6 text-purple-400" />
                        <span className="font-semibold text-[var(--foreground)]">Pro Feature — Powered by OpenAI GPT-4o</span>
                      </div>
                      <p className="text-[var(--foreground-muted)]">
                        Flow is an optional AI assistant that helps with task management and productivity insights.
                      </p>
                    </div>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'Your messages and relevant app context (tasks, sessions, preferences) are sent to OpenAI for processing',
                        'OpenAI retains data for up to 30 days for abuse monitoring, then deletes it',
                        'Your data is NOT used to train OpenAI models (we use their zero-data-retention API)',
                        'Conversation history is stored locally on your device and in the cloud (if signed in)',
                        'You can delete your AI conversation history at any time',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-purple-400 mt-1">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 8. Diagnostics */}
                <AnimatedSection>
                  <section id="diagnostics" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">8</span>
                      Diagnostics
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      We do not use third-party analytics or crash reporting SDKs. If you choose to send feedback, you may optionally include diagnostic information.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 9. Retention */}
                <AnimatedSection>
                  <section id="retention" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">9</span>
                      Retention
                    </h2>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Guest Mode', text: 'Data exists only on your device until you delete the app' },
                        { label: 'Signed-in Mode', text: 'Data is retained until you delete your account' },
                        { label: 'AI conversations', text: 'OpenAI retains data for 30 days, then deletes it' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span><strong className="text-[var(--foreground)]">{item.label}:</strong> {item.text}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 10. Your Rights */}
                <AnimatedSection>
                  <section id="your-rights" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">10</span>
                      Your Rights
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-4">Depending on your location, you may have rights including:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'Access your personal data',
                        'Correct inaccurate data',
                        'Delete your data',
                        'Export your data',
                        'Object to processing',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                    <p className="text-[var(--foreground-muted)] mt-4">
                      Contact us at <a href={`mailto:${CONTACT_EMAIL}`} className="text-[var(--accent-primary)] hover:underline">{CONTACT_EMAIL}</a> to exercise these rights.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 11. Account Deletion */}
                <AnimatedSection>
                  <section id="account-deletion" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-rose-500/10 flex items-center justify-center text-rose-400 text-sm font-bold">11</span>
                      Account Deletion
                    </h2>
                    <div className="p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
                      <p className="text-[var(--foreground-muted)] mb-4">
                        You can delete your account and all associated data at any time:
                      </p>
                      <ol className="space-y-2 text-[var(--foreground-muted)]">
                        <li className="flex gap-3">
                          <span className="text-[var(--accent-primary)] font-semibold">1.</span>
                          <span>Go to Profile → Settings → Delete Account</span>
                        </li>
                        <li className="flex gap-3">
                          <span className="text-[var(--accent-primary)] font-semibold">2.</span>
                          <span>Confirm by typing "DELETE"</span>
                        </li>
                        <li className="flex gap-3">
                          <span className="text-[var(--accent-primary)] font-semibold">3.</span>
                          <span>All data will be permanently removed within 30 days</span>
                        </li>
                      </ol>
                    </div>
                  </section>
                </AnimatedSection>

                {/* 12. Children's Privacy */}
                <AnimatedSection>
                  <section id="children" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">12</span>
                      Children's Privacy
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      FocusFlow is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us immediately.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 13. Changes */}
                <AnimatedSection>
                  <section id="changes" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">13</span>
                      Changes
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the "Effective" date at the top of this policy. Continued use of the app after changes constitutes acceptance of the updated policy.
                    </p>
                  </section>
                </AnimatedSection>

                {/* Contact */}
                <AnimatedSection>
                  <div className="p-8 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] text-center">
                    <h3 className="text-xl font-bold text-[var(--foreground)] mb-4">Questions?</h3>
                    <p className="text-[var(--foreground-muted)] mb-6">
                      If you have any questions about this Privacy Policy, please contact us.
                    </p>
                    <a
                      href={`mailto:${CONTACT_EMAIL}`}
                      className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[var(--accent-primary)] text-white font-semibold hover:bg-[var(--accent-primary-dark)] transition-colors"
                    >
                      <span>{CONTACT_EMAIL}</span>
                    </a>
                  </div>
                </AnimatedSection>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
