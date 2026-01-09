'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { Container, CurrencySelector } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL, PRICING } from '@/lib/constants';
import { 
  Check, X, DollarSign, HelpCircle, Sparkles, Infinity, Cloud, Award, Music, 
  LayoutGrid, Zap, Bot, ArrowRight, Crown, Shield, Star, Timer, Palette,
  TrendingUp, MessageSquare, Smartphone, Bell
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

export default function PricingClient() {
  const mousePosition = useThrottledMouse();
  const [selectedCurrency, setSelectedCurrency] = useState<'USD' | 'CAD'>('CAD');
  const [hoveredPlan, setHoveredPlan] = useState<string | null>(null);

  const proMonthlyPrice = PRICING.pro.monthly[selectedCurrency];
  const proYearlyPrice = PRICING.pro.yearly[selectedCurrency];
  const monthlyEquivalentYearly = proMonthlyPrice * 12;
  const savings = monthlyEquivalentYearly - proYearlyPrice;
  const savingsPercentage = ((savings / monthlyEquivalentYearly) * 100).toFixed(0);
  const yearlyMonthlyPrice = (proYearlyPrice / 12).toFixed(2);

  return (
    <div className="min-h-screen bg-[var(--background)] overflow-x-hidden">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO - Premium & Aspirational
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[60vh] flex items-center justify-center overflow-hidden pt-24 pb-12">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          <div 
            className="absolute top-1/3 left-1/4 w-[600px] md:w-[1000px] h-[600px] md:h-[1000px] rounded-full blur-[150px] md:blur-[200px] opacity-[0.08] transition-transform duration-[3000ms] ease-out"
            style={{
              background: `conic-gradient(from 180deg, rgba(139, 92, 246, 0.8), rgba(212, 168, 83, 0.8), rgba(139, 92, 246, 0.8))`,
              transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
            }}
          />
        </div>
        
        <div className="absolute inset-0 bg-grid opacity-[0.02]" />

        <Container>
          <div className="relative z-10 max-w-5xl mx-auto text-center">
            {/* Pro badge */}
            <div className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border border-[var(--accent-primary)]/30 text-[var(--accent-primary)] text-sm font-medium mb-8">
              <Crown className="w-4 h-4" />
              <span>Unlock Your Full Potential</span>
            </div>
            
            <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold mb-6 leading-[0.95]">
              <span className="text-[var(--foreground)]">Choose your</span>
              <br />
              <span className="text-gradient">focus journey</span>
            </h1>
            
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto font-light mb-12">
              Start free, upgrade when you're ready. Every feature is designed to help you build better focus habits.
            </p>

            {/* Currency selector */}
            <div className="flex justify-center">
              <CurrencySelector onCurrencyChange={setSelectedCurrency} defaultCurrency="CAD" />
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRICING CARDS - Premium Layout
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-16 md:py-24">
        <Container>
          <div className="max-w-7xl mx-auto">
            <div className="grid lg:grid-cols-3 gap-8 items-stretch">
              
              {/* ─────────────────────────────────────────────────────────
                  FREE PLAN
                  ───────────────────────────────────────────────────────── */}
              <div 
                className="relative group"
                onMouseEnter={() => setHoveredPlan('free')}
                onMouseLeave={() => setHoveredPlan(null)}
              >
                <div className={`h-full p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border-2 flex flex-col transition-all duration-500 ${hoveredPlan === 'free' ? 'border-[var(--border)] shadow-2xl scale-[1.02]' : 'border-[var(--border)]'}`}>
                  {/* Header */}
                  <div className="text-center mb-8">
                    <div className="w-16 h-16 mx-auto mb-6 rounded-2xl bg-[var(--background)] border border-[var(--border)] flex items-center justify-center">
                      <Timer className="w-8 h-8 text-[var(--foreground-muted)]" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-2xl font-bold text-[var(--foreground)] mb-2">Free</h3>
                    <p className="text-[var(--foreground-muted)]">Perfect for getting started</p>
                  </div>
                  
                  {/* Price */}
                  <div className="text-center mb-8">
                    <div className="text-6xl font-bold text-[var(--foreground)] mb-1">$0</div>
                    <p className="text-[var(--foreground-muted)]">Free forever</p>
                  </div>
                  
                  {/* Features */}
                  <ul className="space-y-4 mb-8 flex-1">
                    {[
                      { text: 'Focus timer', included: true },
                      { text: '3 ambient backgrounds', included: true },
                      { text: '3 focus sounds', included: true },
                      { text: '2 themes', included: true },
                      { text: '3 presets', included: true },
                      { text: '3 tasks', included: true },
                      { text: 'Last 3 days history', included: true },
                      { text: 'View-only widgets', included: true },
                      { text: 'XP & Levels', included: false },
                      { text: 'Cloud sync', included: false },
                      { text: 'Flow AI', included: false },
                    ].map((feature, i) => (
                      <li key={i} className={`flex items-start gap-3 ${!feature.included ? 'opacity-40' : ''}`}>
                        {feature.included ? (
                          <Check className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" strokeWidth={2} />
                        ) : (
                          <X className="w-5 h-5 text-[var(--foreground-subtle)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        )}
                        <span className="text-[var(--foreground-muted)]">{feature.text}</span>
                      </li>
                    ))}
                  </ul>
                  
                  {/* CTA */}
                  <div className="px-6 py-4 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-center text-[var(--foreground-muted)] font-medium">
                    Current Plan
                  </div>
                </div>
              </div>

              {/* ─────────────────────────────────────────────────────────
                  PRO YEARLY - FEATURED
                  ───────────────────────────────────────────────────────── */}
              <div 
                className="relative group lg:-mt-8 lg:-mb-8"
                onMouseEnter={() => setHoveredPlan('yearly')}
                onMouseLeave={() => setHoveredPlan(null)}
              >
                {/* Best value badge */}
                <div className="absolute -top-5 left-1/2 -translate-x-1/2 z-20">
                  <div className="flex items-center gap-2 px-6 py-2.5 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] text-white text-sm font-bold shadow-xl shadow-[var(--accent-primary)]/40">
                    <Star className="w-4 h-4" />
                    <span>Best Value</span>
                  </div>
                </div>
                
                {/* Glow effect */}
                <div className="absolute -inset-1 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] rounded-[28px] opacity-20 blur-xl group-hover:opacity-30 transition-opacity" />
                
                <div className={`relative h-full p-8 md:p-10 rounded-3xl border-2 border-[var(--accent-primary)]/50 bg-gradient-to-br from-[var(--accent-primary)]/10 via-[var(--background-elevated)] to-[var(--accent-secondary)]/5 flex flex-col transition-all duration-500 ${hoveredPlan === 'yearly' ? 'shadow-2xl shadow-[var(--accent-primary)]/30 scale-[1.02]' : ''}`}>
                  {/* Header */}
                  <div className="text-center mb-8">
                    <div className="w-16 h-16 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-secondary)] flex items-center justify-center shadow-lg shadow-[var(--accent-primary)]/30">
                      <Crown className="w-8 h-8 text-white" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-2xl font-bold text-gradient mb-2">Pro Yearly</h3>
                    <p className="text-[var(--foreground-muted)]">For dedicated focus masters</p>
                  </div>
                  
                  {/* Price */}
                  <div className="text-center mb-4">
                    <div className="text-6xl font-bold text-[var(--foreground)] mb-1">
                      ${proYearlyPrice}
                    </div>
                    <p className="text-[var(--foreground-muted)]">per year</p>
                  </div>
                  
                  {/* Savings badge */}
                  <div className="flex justify-center mb-8">
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-emerald-500/20 text-emerald-400 text-sm font-semibold border border-emerald-500/30">
                      <DollarSign className="w-4 h-4" />
                      Save {savingsPercentage}% — Just ${yearlyMonthlyPrice}/mo
                    </div>
                  </div>
                  
                  {/* Features */}
                  <ul className="space-y-4 mb-8 flex-1">
                    {[
                      'Everything in Free',
                      'All 14 ambient backgrounds',
                      'All 11 focus sounds',
                      'All 10 premium themes',
                      'Unlimited presets & tasks',
                      'Full progress history',
                      'XP & 50 level system',
                      'Achievement badges',
                      'Journey view',
                      'Cloud sync',
                      'Interactive widgets',
                      'Live Activity',
                      'Music integration',
                      'Flow AI assistant',
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-5 h-5 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        <span className="text-[var(--foreground)] font-medium">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  
                  {/* CTA */}
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="group/btn relative px-8 py-5 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] text-white font-bold text-lg text-center overflow-hidden transition-all duration-300 hover:shadow-xl hover:shadow-[var(--accent-primary)]/40"
                  >
                    <div className="absolute inset-0 bg-white/20 opacity-0 group-hover/btn:opacity-100 transition-opacity duration-300" />
                    <span className="relative z-10 flex items-center justify-center gap-2">
                      Start Free Trial
                      <ArrowRight className="w-5 h-5 group-hover/btn:translate-x-1 transition-transform" />
                    </span>
                  </a>
                </div>
              </div>

              {/* ─────────────────────────────────────────────────────────
                  PRO MONTHLY
                  ───────────────────────────────────────────────────────── */}
              <div 
                className="relative group"
                onMouseEnter={() => setHoveredPlan('monthly')}
                onMouseLeave={() => setHoveredPlan(null)}
              >
                <div className={`h-full p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border-2 flex flex-col transition-all duration-500 ${hoveredPlan === 'monthly' ? 'border-[var(--accent-primary)]/50 shadow-2xl scale-[1.02]' : 'border-[var(--border)]'}`}>
                  {/* Header */}
                  <div className="text-center mb-8">
                    <div className="w-16 h-16 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border border-[var(--accent-primary)]/30 flex items-center justify-center">
                      <Zap className="w-8 h-8 text-[var(--accent-primary)]" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-2xl font-bold text-[var(--foreground)] mb-2">Pro Monthly</h3>
                    <p className="text-[var(--foreground-muted)]">Flexible month-to-month</p>
                  </div>
                  
                  {/* Price */}
                  <div className="text-center mb-8">
                    <div className="text-6xl font-bold text-[var(--foreground)] mb-1">
                      ${proMonthlyPrice}
                    </div>
                    <p className="text-[var(--foreground-muted)]">per month</p>
                  </div>
                  
                  {/* Features */}
                  <ul className="space-y-4 mb-8 flex-1">
                    {[
                      'Everything in Free',
                      'All 14 ambient backgrounds',
                      'All 11 focus sounds',
                      'All 10 premium themes',
                      'Unlimited presets & tasks',
                      'Full progress history',
                      'XP & 50 level system',
                      'Achievement badges',
                      'Journey view',
                      'Cloud sync',
                      'Interactive widgets',
                      'Live Activity',
                      'Music integration',
                      'Flow AI assistant',
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-5 h-5 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        <span className="text-[var(--foreground-muted)]">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  
                  {/* CTA */}
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-8 py-5 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg text-center hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background)] transition-all duration-300 flex items-center justify-center gap-2"
                  >
                    Start Free Trial
                    <ArrowRight className="w-5 h-5" />
                  </a>
                </div>
              </div>
            </div>

            {/* Trust badges */}
            <div className="mt-12 flex flex-wrap justify-center items-center gap-6 text-[var(--foreground-muted)]">
              <div className="flex items-center gap-2">
                <Shield className="w-5 h-5 text-emerald-500" />
                <span>Cancel anytime</span>
              </div>
              <div className="w-px h-4 bg-[var(--border)]" />
              <div className="flex items-center gap-2">
                <Zap className="w-5 h-5 text-amber-500" />
                <span>Instant access</span>
              </div>
              <div className="w-px h-4 bg-[var(--border)]" />
              <div className="flex items-center gap-2">
                <Cloud className="w-5 h-5 text-[var(--accent-primary)]" />
                <span>Sync across devices</span>
              </div>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          WHAT YOU GET WITH PRO - Visual Feature Grid
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32 bg-[var(--background-elevated)]">
        <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-[var(--accent-primary)]/20 to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 text-[var(--accent-primary)] text-sm mb-6">
                <Sparkles className="w-4 h-4" />
                <span>Pro Features</span>
              </div>
              <h2 className="text-4xl md:text-6xl font-bold mb-4">
                Unlock <span className="text-gradient">everything</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto">
                Premium features designed to transform how you focus
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                { 
                  icon: LayoutGrid, 
                  title: 'All Premium Content', 
                  desc: '14 backgrounds, 11 sounds, 10 themes',
                  color: 'from-violet-500 to-purple-600'
                },
                { 
                  icon: Infinity, 
                  title: 'Unlimited Everything', 
                  desc: 'Tasks, presets, and full history',
                  color: 'from-emerald-500 to-teal-600'
                },
                { 
                  icon: Award, 
                  title: 'Gamification', 
                  desc: 'XP, 50 levels, badges & journey view',
                  color: 'from-amber-500 to-orange-600'
                },
                { 
                  icon: Cloud, 
                  title: 'Cloud Sync', 
                  desc: 'Access everything on all devices',
                  color: 'from-cyan-500 to-blue-600'
                },
                { 
                  icon: Smartphone, 
                  title: 'Interactive Widgets', 
                  desc: 'Control timer from home screen',
                  color: 'from-rose-500 to-pink-600'
                },
                { 
                  icon: Bell, 
                  title: 'Live Activity', 
                  desc: 'Dynamic Island & Lock Screen',
                  color: 'from-indigo-500 to-violet-600'
                },
                { 
                  icon: Music, 
                  title: 'Music Integration', 
                  desc: 'Spotify, Apple Music, YouTube Music',
                  color: 'from-green-500 to-emerald-600'
                },
                { 
                  icon: Bot, 
                  title: 'Flow AI', 
                  desc: 'Intelligent assistant powered by GPT-4o',
                  color: 'from-purple-500 to-pink-600'
                },
                { 
                  icon: Shield, 
                  title: 'Priority Support', 
                  desc: 'Direct access to our team',
                  color: 'from-slate-500 to-slate-600'
                },
              ].map((feature, i) => (
                <div 
                  key={i}
                  className="group relative p-8 rounded-3xl bg-[var(--background)] border border-[var(--border)] hover:border-transparent transition-all duration-300"
                >
                  {/* Hover glow */}
                  <div className={`absolute inset-0 rounded-3xl bg-gradient-to-br ${feature.color} opacity-0 group-hover:opacity-[0.08] transition-opacity duration-300`} />
                  
                  <div className="relative z-10">
                    <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${feature.color} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg`}>
                      <feature.icon className="w-7 h-7 text-white" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-xl font-bold text-[var(--foreground)] mb-2">{feature.title}</h3>
                    <p className="text-[var(--foreground-muted)]">{feature.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          COMPARISON TABLE
          ═══════════════════════════════════════════════════════════════ */}
      <AnimatedSection className="relative py-24 md:py-32">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold mb-4">
                Free vs <span className="text-gradient">Pro</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)]">See everything you unlock</p>
            </div>

            <div className="rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] overflow-hidden">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-6 px-8 text-lg font-bold text-[var(--foreground)]">Feature</th>
                    <th className="text-center py-6 px-6 text-lg font-bold text-[var(--foreground)]">Free</th>
                    <th className="text-center py-6 px-6 text-lg font-bold text-gradient">Pro</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    { feature: 'Ambient Backgrounds', free: '3', pro: '14' },
                    { feature: 'Focus Sounds', free: '3', pro: '11' },
                    { feature: 'Themes', free: '2', pro: '10' },
                    { feature: 'Focus Presets', free: '3', pro: '∞' },
                    { feature: 'Tasks', free: '3', pro: '∞' },
                    { feature: 'Progress History', free: '3 days', pro: 'Forever' },
                    { feature: 'XP & Levels', free: '—', pro: '50 levels' },
                    { feature: 'Achievement Badges', free: '—', pro: '20+' },
                    { feature: 'Journey View', free: '—', pro: '✓' },
                    { feature: 'Cloud Sync', free: '—', pro: '✓' },
                    { feature: 'Interactive Widgets', free: '—', pro: '✓' },
                    { feature: 'Live Activity', free: '—', pro: '✓' },
                    { feature: 'Music Integration', free: '—', pro: '✓' },
                    { feature: 'Flow AI Assistant', free: '—', pro: '✓' },
                  ].map((row, i) => (
                    <tr key={i} className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--background)] transition-colors">
                      <td className="py-5 px-8 text-[var(--foreground)] font-medium">{row.feature}</td>
                      <td className="py-5 px-6 text-center text-[var(--foreground-muted)]">{row.free}</td>
                      <td className="py-5 px-6 text-center text-[var(--accent-primary)] font-semibold">{row.pro}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          FAQ
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
              <h2 className="text-4xl md:text-5xl font-bold">Common questions</h2>
            </div>
            
            <div className="space-y-4">
              {[
                {
                  q: 'Is there a free trial?',
                  a: 'Yes! All Pro features are available with a free trial. You can cancel anytime during the trial period and won\'t be charged.',
                },
                {
                  q: 'Can I switch between monthly and yearly?',
                  a: 'Absolutely. You can change your subscription plan at any time from your account settings in the app.',
                },
                {
                  q: 'What happens when I cancel?',
                  a: 'You\'ll keep access to Pro features until the end of your billing period. After that, you\'ll automatically switch to the Free plan.',
                },
                {
                  q: 'Do I need to create an account?',
                  a: 'Pro features require an account for cloud sync and cross-device access. The Free plan works fully offline without an account.',
                },
                {
                  q: 'Can I use Pro on multiple devices?',
                  a: 'Yes! Sign in on any device and your progress, tasks, and settings will sync automatically.',
                },
                {
                  q: 'What payment methods do you accept?',
                  a: 'Payments are handled securely through the App Store. You can use any payment method configured in your Apple ID.',
                },
              ].map((faq, i) => (
                <div 
                  key={i} 
                  className="group p-8 rounded-3xl bg-[var(--background)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-300"
                >
                  <h3 className="text-xl font-bold text-[var(--foreground)] mb-3 group-hover:text-[var(--accent-primary)] transition-colors">{faq.q}</h3>
                  <p className="text-[var(--foreground-muted)] leading-relaxed">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </AnimatedSection>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-24 md:py-32 overflow-hidden">
        {/* Background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-[var(--background-elevated)] via-[var(--accent-primary)]/5 to-[var(--background)]" />
        
        <Container>
          <div className="relative max-w-4xl mx-auto text-center">
            {/* Floating glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-full blur-[150px] opacity-50" />
            
            <div className="relative z-10">
              <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6">
                Ready to <span className="text-gradient">focus better?</span>
              </h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 font-light">
                Join thousands who've transformed their productivity with FocusFlow.
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
                  href="/features"
                  className="px-10 py-5 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-xl hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3"
                >
                  Explore Features
                  <ArrowRight className="w-5 h-5" />
                </Link>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}

