'use client';

import { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { CONTACT_EMAIL } from '@/lib/constants';
import { 
  Mail, MessageSquare, HelpCircle, ChevronDown, ChevronUp,
  Cloud, User, CreditCard, Trash2, Wifi, RotateCcw, Download,
  Lightbulb, Shield, FileText, Sparkles, ArrowRight, Clock
} from 'lucide-react';

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

// FAQ Accordion Item
const FAQItem = ({ 
  question, 
  answer, 
  icon: Icon,
  isOpen, 
  onToggle 
}: { 
  question: string; 
  answer: string; 
  icon: React.ElementType;
  isOpen: boolean; 
  onToggle: () => void;
}) => {
  return (
    <div className={`group rounded-2xl border transition-all duration-300 ${isOpen ? 'bg-[var(--background)] border-[var(--accent-primary)]/30 shadow-lg' : 'bg-[var(--background-elevated)] border-[var(--border)] hover:border-[var(--accent-primary)]/20'}`}>
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-4 p-6 text-left"
      >
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 transition-all ${isOpen ? 'bg-[var(--accent-primary)]/20 text-[var(--accent-primary)]' : 'bg-[var(--background)] text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)]'}`}>
          <Icon className="w-5 h-5" strokeWidth={1.5} />
        </div>
        <span className={`flex-1 text-lg font-semibold transition-colors ${isOpen ? 'text-[var(--accent-primary)]' : 'text-[var(--foreground)]'}`}>
          {question}
        </span>
        <div className={`w-8 h-8 rounded-full flex items-center justify-center transition-all ${isOpen ? 'bg-[var(--accent-primary)] text-white rotate-180' : 'bg-[var(--background)] text-[var(--foreground-muted)]'}`}>
          <ChevronDown className="w-5 h-5" />
        </div>
      </button>
      <div className={`overflow-hidden transition-all duration-300 ${isOpen ? 'max-h-96 opacity-100' : 'max-h-0 opacity-0'}`}>
        <p className="px-6 pb-6 text-[var(--foreground-muted)] leading-relaxed pl-20">
          {answer}
        </p>
      </div>
    </div>
  );
};

export default function SupportClient() {
  const mousePosition = useThrottledMouse();
  const [openFAQ, setOpenFAQ] = useState<number | null>(0);

  const faqs = [
    {
      icon: Cloud,
      q: 'How do I sync my data across devices?',
      a: 'Sign in with your Apple, Google, or email account to enable cloud sync. Your sessions, tasks, presets, and settings will automatically sync across all your devices. Changes appear instantly.',
    },
    {
      icon: User,
      q: 'Can I use FocusFlow without an account?',
      a: 'Yes! Guest Mode allows you to use FocusFlow with all features except cloud sync. All your data stays securely on your device. You can create an account later if you want to enable sync.',
    },
    {
      icon: CreditCard,
      q: 'How do I cancel my FocusFlow Pro subscription?',
      a: 'Cancel anytime through your Apple ID settings. Go to Settings → [Your Name] → Subscriptions, find FocusFlow Pro, and tap Cancel Subscription. You\'ll keep Pro features until the end of your billing period.',
    },
    {
      icon: Trash2,
      q: 'How do I delete my account?',
      a: 'Go to Profile → Settings → Delete Account. Confirm by typing "DELETE". All your data will be permanently removed from our servers within 30 days. This action cannot be undone.',
    },
    {
      icon: Wifi,
      q: 'Does FocusFlow work offline?',
      a: 'Yes! Focus sessions and tasks work perfectly without an internet connection. Your data syncs automatically when you\'re back online. The app is designed to work seamlessly offline.',
    },
    {
      icon: RotateCcw,
      q: 'How do I restore my Pro subscription?',
      a: 'If you previously had FocusFlow Pro, you can restore it by going to Profile → Settings → Restore Purchases. This will reactivate your subscription if it\'s still valid under your Apple ID.',
    },
    {
      icon: Download,
      q: 'Can I export my data?',
      a: 'Yes! Go to Profile → Settings → Backup & Export to download a JSON file with all your data. This is useful for backup or if you want to review your focus history.',
    },
    {
      icon: Lightbulb,
      q: 'What if I have a feature request?',
      a: `We love hearing from you! Email us at ${CONTACT_EMAIL} with your ideas. We review all feedback and consider it for future updates. Many features came directly from user suggestions.`,
    },
  ];

  return (
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[50vh] flex items-center justify-center overflow-hidden pt-24 pb-12">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/3 left-1/4 w-[600px] h-[600px] rounded-full blur-[150px] opacity-[0.06] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.8) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
        </div>
        
        <div className="absolute inset-0 bg-grid opacity-[0.02]" />

        <Container>
          <div className="relative z-10 max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm mb-8">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>We're Here to Help</span>
            </div>
            
            <h1 className="text-5xl md:text-7xl font-bold mb-6 leading-[0.95]">
              <span className="text-[var(--foreground)]">Support &</span>
              <br />
              <span className="text-gradient">Contact</span>
            </h1>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-2xl mx-auto font-light">
              Get help, find answers, or share feedback. We typically respond within 24 hours.
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          EMAIL SUPPORT - HIGHLIGHTED
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-16 md:py-24">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="relative p-8 md:p-12 rounded-3xl bg-gradient-to-br from-[var(--accent-primary)]/10 via-[var(--background-elevated)] to-[var(--accent-secondary)]/5 border border-[var(--accent-primary)]/20 overflow-hidden">
              {/* Decorative glow */}
              <div className="absolute top-0 right-0 w-64 h-64 bg-[var(--accent-primary)]/10 rounded-full blur-[100px]" />
              
              <div className="relative z-10 flex flex-col md:flex-row items-center gap-8">
                <div className="flex-shrink-0">
                  <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] flex items-center justify-center shadow-xl shadow-[var(--accent-primary)]/30">
                    <Mail className="w-10 h-10 text-white" strokeWidth={1.5} />
                  </div>
                </div>
                
                <div className="flex-1 text-center md:text-left">
                  <h2 className="text-2xl md:text-3xl font-bold text-[var(--foreground)] mb-2">Email Support</h2>
                  <p className="text-[var(--foreground-muted)] mb-4">
                    For support, feedback, or general questions
                  </p>
                  <a
                    href={`mailto:${CONTACT_EMAIL}`}
                    className="inline-block text-2xl md:text-3xl font-bold text-gradient hover:opacity-80 transition-opacity"
                  >
                    {CONTACT_EMAIL}
                  </a>
                </div>
                
                <div className="flex-shrink-0">
                  <a
                    href={`mailto:${CONTACT_EMAIL}`}
                    className="group flex items-center gap-2 px-6 py-3 rounded-xl bg-[var(--foreground)] text-[var(--background)] font-semibold hover:scale-105 transition-transform"
                  >
                    <span>Send Email</span>
                    <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </a>
                </div>
              </div>
              
              <div className="relative z-10 mt-8 pt-8 border-t border-[var(--border)]">
                <div className="flex items-center gap-3 text-sm text-[var(--foreground-muted)]">
                  <Clock className="w-4 h-4 text-emerald-500" />
                  <span>Typical response time: <strong className="text-[var(--foreground)]">Within 24 hours</strong></span>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          FAQ SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background)] border border-[var(--border)] text-[var(--foreground-muted)] text-sm mb-6">
                <HelpCircle className="w-4 h-4" />
                <span>FAQ</span>
              </div>
              <h2 className="text-4xl md:text-5xl font-bold mb-4">
                Frequently asked <span className="text-gradient">questions</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)]">
                Find quick answers to common questions
              </p>
            </div>
            
            <div className="space-y-4">
              {faqs.map((faq, i) => (
                <FAQItem
                  key={i}
                  icon={faq.icon}
                  question={faq.q}
                  answer={faq.a}
                  isOpen={openFAQ === i}
                  onToggle={() => setOpenFAQ(openFAQ === i ? null : i)}
                />
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          PRO TIP
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-16 md:py-24">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="p-8 rounded-3xl bg-amber-500/10 border border-amber-500/20">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-amber-500/20 flex items-center justify-center flex-shrink-0">
                  <Sparkles className="w-6 h-6 text-amber-500" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-[var(--foreground)] mb-2">Pro Tip</h3>
                  <p className="text-[var(--foreground-muted)] leading-relaxed">
                    When contacting support, include your device model, iOS version, and a brief description of the issue. 
                    Screenshots help too! This helps us resolve your issue faster.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          ADDITIONAL RESOURCES
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Additional <span className="text-gradient">resources</span>
            </h2>
            <p className="text-xl text-[var(--foreground-muted)] mb-12">
              Learn more about FocusFlow policies and features
            </p>
            
            <div className="grid md:grid-cols-3 gap-6">
              {[
                { icon: Shield, title: 'Privacy Policy', desc: 'How we protect your data', href: '/privacy' },
                { icon: FileText, title: 'Terms of Service', desc: 'Our service agreement', href: '/terms' },
                { icon: Sparkles, title: 'Features', desc: 'Explore all features', href: '/features' },
              ].map((item, i) => (
                <Link
                  key={i}
                  href={item.href}
                  className="group p-8 rounded-2xl bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-300 hover:shadow-lg"
                >
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 flex items-center justify-center mb-4 mx-auto group-hover:scale-110 transition-transform">
                    <item.icon className="w-7 h-7 text-[var(--accent-primary)]" strokeWidth={1.5} />
                  </div>
                  <h3 className="text-lg font-bold text-[var(--foreground)] mb-2 group-hover:text-[var(--accent-primary)] transition-colors">{item.title}</h3>
                  <p className="text-[var(--foreground-muted)] text-sm">{item.desc}</p>
                </Link>
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>
    </div>
  );
}
