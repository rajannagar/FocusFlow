'use client';

import { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { CONTACT_EMAIL } from '@/lib/constants';
import { 
  DocumentTextIcon, ShieldCheckIcon, UserIcon, CreditCardIcon, LightBulbIcon, ExclamationTriangleIcon, 
  ScaleIcon, LockClosedIcon, TrashIcon, ChevronRightIcon, EnvelopeIcon, SparklesIcon
} from '@heroicons/react/24/solid';

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

export default function TermsClient() {
  const mousePosition = useThrottledMouse();
  const [activeSection, setActiveSection] = useState('');

  const sections = [
    { id: 'acceptance', title: 'Acceptance of Terms' },
    { id: 'service', title: 'Description of Service' },
    { id: 'accounts', title: 'User Accounts' },
    { id: 'subscription', title: 'FocusFlow Pro Subscription' },
    { id: 'ai-terms', title: 'AI Assistant Terms' },
    { id: 'acceptable-use', title: 'Acceptable Use' },
    { id: 'intellectual-property', title: 'Intellectual Property' },
    { id: 'user-content', title: 'User Content' },
    { id: 'privacy', title: 'Data and Privacy' },
    { id: 'third-party', title: 'Third-Party Services' },
    { id: 'deletion', title: 'Account Deletion' },
    { id: 'disclaimers', title: 'Disclaimers' },
    { id: 'liability', title: 'Limitation of Liability' },
    { id: 'indemnification', title: 'Indemnification' },
    { id: 'changes', title: 'Changes to Terms' },
    { id: 'termination', title: 'Termination' },
    { id: 'governing-law', title: 'Governing Law' },
    { id: 'contact', title: 'Contact' },
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
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.8) 0%, transparent 70%)`,
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
              <span className="text-[var(--foreground)]">Terms of Service</span>
            </div>
            
            {/* Header */}
            <div className="flex items-start gap-6 mb-8">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] flex items-center justify-center flex-shrink-0 shadow-lg shadow-[var(--accent-primary)]/20">
                <DocumentTextIcon className="w-8 h-8 text-white" strokeWidth={1.5} />
              </div>
              <div>
                <h1 className="text-4xl md:text-5xl font-bold text-[var(--foreground)] mb-2">Terms of Service</h1>
                <p className="text-[var(--foreground-muted)]">Effective: January 9, 2026</p>
              </div>
            </div>
            
            {/* Intro */}
            <p className="text-lg text-[var(--foreground-muted)] leading-relaxed p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
              These Terms of Service ("Terms") govern your use of FocusFlow - Be Present ("FocusFlow", "the app").
              By using FocusFlow, you agree to these Terms. Soft Computers ("we", "us") is the developer of FocusFlow.
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
              <div className="sticky top-24 p-4 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] max-h-[calc(100vh-120px)] overflow-y-auto">
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
                
                {/* 1. Acceptance of Terms */}
                <AnimatedSection>
                  <section id="acceptance" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">1</span>
                      Acceptance of Terms
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      By downloading, installing, or using FocusFlow, you agree to be bound by these Terms. If you do not agree to these Terms, do not use the app.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 2. Description of Service */}
                <AnimatedSection>
                  <section id="service" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">2</span>
                      Description of Service
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-4">FocusFlow is a productivity application that helps you:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'Track focus sessions with customizable durations, 14 animated ambient backgrounds, and 11 focus sounds',
                        'Manage tasks with reminders, recurring schedules, duration estimates, and completion tracking',
                        'View progress statistics, streaks, XP points, 50-level progression system, achievement badges, and Journey view',
                        'Sync data across devices with cloud backup (Pro feature) or use Guest Mode for local-only storage',
                        'Customize your experience with 10 premium themes, symbol-based avatars, unlimited focus presets, and interactive widgets',
                        'Use Live Activity and Dynamic Island integration to control sessions from your Lock Screen (Pro)',
                        'Integrate with music apps (Spotify, Apple Music, YouTube Music) during focus sessions (Pro)',
                        'Get AI-powered productivity assistance with Flow, powered by OpenAI GPT-4o (Pro)',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 3. User Accounts */}
                <AnimatedSection>
                  <section id="accounts" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">3</span>
                      User Accounts
                    </h2>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Guest Mode', text: 'You may use FocusFlow without creating an account. Data is stored locally on your device.' },
                        { label: 'Signed-in Mode', text: 'Create an account using Sign in with Apple, Google, or email/password. This enables cloud sync and Pro features.' },
                        { label: '', text: 'You are responsible for maintaining the security of your account credentials.' },
                        { label: '', text: 'You must provide accurate information when creating an account.' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span>
                            {item.label && <strong className="text-[var(--foreground)]">{item.label}:</strong>} {item.text}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 4. FocusFlow Pro Subscription */}
                <AnimatedSection>
                  <section id="subscription" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center text-amber-400 text-sm font-bold">4</span>
                      FocusFlow Pro Subscription
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-6">FocusFlow offers optional paid subscriptions ("FocusFlow Pro") that unlock premium features:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Subscription Options', text: 'Monthly and yearly plans available. Yearly plans offer significant savings.' },
                        { label: 'Free Trial', text: 'New subscribers may be eligible for a free trial. Cancel before it ends to avoid charges.' },
                        { label: 'Billing', text: 'Payment is processed through Apple\'s App Store and charged to your Apple ID.' },
                        { label: 'Auto-Renewal', text: 'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.' },
                        { label: 'Price Changes', text: 'We may change prices with advance notice. Cancel before changes take effect to avoid new pricing.' },
                        { label: 'Cancellation', text: 'Cancel through Apple ID settings (Settings → [Your Name] → Subscriptions). Access continues until end of billing period.' },
                        { label: 'Refunds', text: 'Refund requests are handled by Apple according to their App Store policies.' },
                        { label: 'Pro Features', text: 'Includes all backgrounds, sounds, themes, unlimited presets/tasks, full history, XP system, badges, Journey view, cloud sync, widgets, Live Activity, music integration, and Flow AI.' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-amber-500 mt-1">•</span>
                          <span><strong className="text-[var(--foreground)]">{item.label}:</strong> {item.text}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 5. AI Assistant Terms */}
                <AnimatedSection>
                  <section id="ai-terms" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-purple-500/10 flex items-center justify-center text-purple-400 text-sm font-bold">5</span>
                      AI Assistant Terms
                    </h2>
                    <div className="p-6 rounded-2xl bg-purple-500/10 border border-purple-500/20 mb-6">
                      <div className="flex items-center gap-3 mb-4">
                        <SparklesIcon className="w-6 h-6 text-purple-400" />
                        <span className="font-semibold text-[var(--foreground)]">Flow AI — Powered by OpenAI GPT-4o</span>
                      </div>
                    </div>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'Flow is powered by OpenAI\'s GPT-4o model. By using Flow, you also agree to OpenAI\'s usage policies.',
                        'Your messages and app context are sent to OpenAI for processing. OpenAI retains data for up to 30 days for abuse monitoring.',
                        'Your data is NOT used to train OpenAI models (we use their zero-data-retention API).',
                        'Flow provides suggestions and information but should not be considered professional advice.',
                        'We do not guarantee the accuracy, completeness, or reliability of AI-generated responses.',
                        'Do not share sensitive personal information (financial, medical, legal) with the AI assistant.',
                        'Flow\'s responses may vary and may occasionally be inaccurate or inappropriate.',
                        'You may delete your AI conversation history at any time within the app.',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-purple-400 mt-1">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 6. Acceptable Use */}
                <AnimatedSection>
                  <section id="acceptable-use" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">6</span>
                      Acceptable Use
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-4">You agree not to:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        'Use the app for any illegal purpose',
                        'Attempt to reverse engineer, decompile, or disassemble the app',
                        'Interfere with or disrupt the app\'s operation',
                        'Use automated tools to access or scrape the app',
                        'Impersonate others or provide false information',
                        'Use the AI assistant to generate harmful, illegal, or inappropriate content',
                        'Share account credentials with others',
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-rose-500 mt-1">✕</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </section>
                </AnimatedSection>

                {/* 7. Intellectual Property */}
                <AnimatedSection>
                  <section id="intellectual-property" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">7</span>
                      Intellectual Property
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      FocusFlow, including its design, code, graphics, animations, sounds, and content, is owned by Soft Computers and protected by intellectual property laws. You may not copy, modify, distribute, or create derivative works without our written permission.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 8. User Content */}
                <AnimatedSection>
                  <section id="user-content" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">8</span>
                      User Content
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      You retain ownership of content you create (task names, notes, session intentions, AI conversations). By using cloud sync, you grant us a limited license to store and transmit this content solely to provide the service.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 9. Data and Privacy */}
                <AnimatedSection>
                  <section id="privacy" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">9</span>
                      Data and Privacy
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      Your use of FocusFlow is also governed by our <Link href="/privacy" className="text-[var(--accent-primary)] hover:underline">Privacy Policy</Link>, which explains how we collect, use, and protect your data.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 10. Third-Party Services */}
                <AnimatedSection>
                  <section id="third-party" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">10</span>
                      Third-Party Services
                    </h2>
                    <p className="text-[var(--foreground-muted)] mb-4">FocusFlow integrates with third-party services:</p>
                    <ul className="space-y-3 text-[var(--foreground-muted)]">
                      {[
                        { label: 'Apple Sign In & StoreKit', text: 'For authentication and subscription management' },
                        { label: 'Google Sign In', text: 'For authentication' },
                        { label: 'Supabase', text: 'For cloud data storage and sync' },
                        { label: 'OpenAI', text: 'For AI assistant functionality (GPT-4o)' },
                        { label: 'Music Services', text: 'Spotify, Apple Music, YouTube Music integration' },
                      ].map((item, i) => (
                        <li key={i} className="flex gap-3">
                          <span className="text-[var(--accent-primary)] mt-1">•</span>
                          <span><strong className="text-[var(--foreground)]">{item.label}:</strong> {item.text}</span>
                        </li>
                      ))}
                    </ul>
                    <p className="text-[var(--foreground-muted)] mt-4">
                      Your use of these services is subject to their respective terms and privacy policies.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 11. Account Deletion */}
                <AnimatedSection>
                  <section id="deletion" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-rose-500/10 flex items-center justify-center text-rose-400 text-sm font-bold">11</span>
                      Account Deletion
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      You can delete your account at any time from Profile → Settings → Delete Account. Deletion is permanent and removes all your data from our servers within 30 days.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 12. Disclaimers */}
                <AnimatedSection>
                  <section id="disclaimers" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center text-amber-400 text-sm font-bold">12</span>
                      Disclaimers
                    </h2>
                    <div className="p-6 rounded-2xl bg-amber-500/10 border border-amber-500/20">
                      <p className="text-[var(--foreground-muted)]">
                        FocusFlow is provided "as is" without warranties of any kind. We do not guarantee the app will be error-free, uninterrupted, or meet your specific requirements. The AI assistant provides informational content only and should not be considered professional advice.
                      </p>
                    </div>
                  </section>
                </AnimatedSection>

                {/* 13. Limitation of Liability */}
                <AnimatedSection>
                  <section id="liability" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">13</span>
                      Limitation of Liability
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      To the maximum extent permitted by law, Soft Computers shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of FocusFlow. Our total liability shall not exceed the amount you paid for FocusFlow Pro in the past 12 months.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 14. Indemnification */}
                <AnimatedSection>
                  <section id="indemnification" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">14</span>
                      Indemnification
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      You agree to indemnify and hold harmless Soft Computers from any claims, damages, or expenses arising from your violation of these Terms or misuse of the app.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 15. Changes to Terms */}
                <AnimatedSection>
                  <section id="changes" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">15</span>
                      Changes to Terms
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      We may update these Terms from time to time. We will notify you of material changes by updating the "Effective" date. Continued use after changes constitutes acceptance of the updated Terms.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 16. Termination */}
                <AnimatedSection>
                  <section id="termination" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">16</span>
                      Termination
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      We may suspend or terminate your access to FocusFlow if you violate these Terms. Upon termination, your right to use the app ceases immediately. You may also terminate your use at any time by deleting the app and your account.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 17. Governing Law */}
                <AnimatedSection>
                  <section id="governing-law" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">17</span>
                      Governing Law
                    </h2>
                    <p className="text-[var(--foreground-muted)]">
                      These Terms are governed by the laws of Canada, without regard to conflict of law principles. Any disputes shall be resolved in the courts of Canada.
                    </p>
                  </section>
                </AnimatedSection>

                {/* 18. Contact */}
                <AnimatedSection>
                  <section id="contact" className="scroll-mt-24">
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-6 pb-4 border-b border-[var(--border)] flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg bg-[var(--accent-primary)]/10 flex items-center justify-center text-[var(--accent-primary)] text-sm font-bold">18</span>
                      Contact
                    </h2>
                    <div className="p-8 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] text-center">
                      <p className="text-[var(--foreground-muted)] mb-6">
                        If you have any questions about these Terms, please contact us.
                      </p>
                      <a
                        href={`mailto:${CONTACT_EMAIL}`}
                        className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[var(--accent-primary)] text-white font-semibold hover:bg-[var(--accent-primary-dark)] transition-colors"
                      >
                        <EnvelopeIcon className="w-5 h-5" />
                        <span>{CONTACT_EMAIL}</span>
                      </a>
                    </div>
                  </section>
                </AnimatedSection>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
