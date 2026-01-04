'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { Container, CurrencySelector } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL, PRICING } from '@/lib/constants';
import { Check, DollarSign, HelpCircle } from 'lucide-react';

export default function PricingPage() {
  const mousePosition = useThrottledMouse();
  const [selectedCurrency, setSelectedCurrency] = useState<'USD' | 'CAD'>('CAD');
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

  const proMonthlyPrice = PRICING.pro.monthly[selectedCurrency];
  const proYearlyPrice = PRICING.pro.yearly[selectedCurrency];
  const monthlyEquivalentYearly = proMonthlyPrice * 12;
  const savings = monthlyEquivalentYearly - proYearlyPrice;
  const savingsPercentage = ((savings / monthlyEquivalentYearly) * 100).toFixed(0);

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
                Choose your <span className="text-gradient">plan</span>
              </h1>
              <p className="text-xl md:text-2xl lg:text-3xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-3xl mx-auto mb-8 md:mb-12">
                Start free, upgrade when you're ready. Unlock the full potential of FocusFlow.
              </p>
              
              {/* Currency Selector */}
              <div className="flex justify-center">
                <CurrencySelector onCurrencyChange={setSelectedCurrency} defaultCurrency="CAD" />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRICING CARDS - Premium Layout
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
          <div className="relative z-10 max-w-7xl mx-auto px-4 md:px-6">
            <div className="grid md:grid-cols-3 gap-6 md:gap-8 items-stretch">
              
              {/* Free Plan */}
              <div className="relative group">
                <div className="h-full p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border-2 border-[var(--border)] flex flex-col transition-all duration-300 hover:border-[var(--accent-primary)]/30 hover:shadow-xl">
                  <div className="text-center mb-8">
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
                      Free Forever
                    </div>
                    <h3 className="text-3xl md:text-4xl font-bold text-[var(--foreground)] mb-3">Free</h3>
                    <div className="text-6xl md:text-7xl font-bold text-[var(--foreground)] mb-2">$0</div>
                    <p className="text-[var(--foreground-muted)]">Perfect for getting started</p>
                  </div>
                  
                  <ul className="space-y-4 mb-8 flex-1">
                    {[
                      'Focus timer',
                      '3 ambient backgrounds',
                      '3 focus sounds',
                      '2 themes (Forest, Neon)',
                      '3 custom presets',
                      '3 tasks',
                      'Last 3 days history',
                      'View-only widgets',
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-6 h-6 text-[var(--foreground-subtle)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        <span className="text-[var(--foreground-muted)]">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  
                  <div className="px-6 py-4 rounded-2xl bg-[var(--background-subtle)] border border-[var(--border)] text-center text-[var(--foreground-muted)] font-medium">
                    Current Plan
                  </div>
                </div>
              </div>

              {/* Pro Yearly - Featured */}
              <div className="relative group md:-mt-8">
                {/* Best Value Badge */}
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 z-20">
                  <div className="px-6 py-2 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white text-sm font-bold shadow-xl shadow-[var(--accent-primary)]/40 whitespace-nowrap">
                    ⭐ Best Value
                  </div>
                </div>
                
                <div className="h-full p-8 md:p-10 rounded-3xl border-2 border-[var(--accent-primary)]/60 bg-gradient-to-br from-[var(--accent-primary)]/10 to-[var(--accent-primary)]/5 flex flex-col shadow-2xl shadow-[var(--accent-primary)]/20">
                  <div className="text-center mb-8">
                    <h3 className="text-3xl md:text-4xl font-bold text-gradient mb-3">Pro Yearly</h3>
                    <div className="text-6xl md:text-7xl font-bold text-[var(--foreground)] mb-2">
                      ${proYearlyPrice}
                    </div>
                    <p className="text-[var(--foreground-muted)] mb-4">per year</p>
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--success)]/20 text-[var(--success)] text-sm font-semibold border border-[var(--success)]/30">
                      <DollarSign className="w-4 h-4" />
                      Save {savingsPercentage}% ({selectedCurrency === 'USD' ? '$' : 'C$'}{savings.toFixed(2)}/year)
                    </div>
                  </div>
                  
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
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-6 h-6 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        <span className="text-[var(--foreground-muted)] font-medium">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="group relative px-8 py-4 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-bold text-lg text-center overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-xl hover:shadow-[var(--accent-primary)]/40"
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                    <span className="relative z-10">Start Free Trial</span>
                  </a>
                </div>
              </div>

              {/* Pro Monthly */}
              <div className="relative group">
                <div className="h-full p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border-2 border-[var(--border)] flex flex-col transition-all duration-300 hover:border-[var(--accent-primary)]/30 hover:shadow-xl">
                  <div className="text-center mb-8">
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/30 text-sm text-[var(--accent-primary)] mb-4">
                      Pro
                    </div>
                    <h3 className="text-3xl md:text-4xl font-bold text-gradient mb-3">Pro Monthly</h3>
                    <div className="text-6xl md:text-7xl font-bold text-[var(--foreground)] mb-2">
                      ${proMonthlyPrice}
                    </div>
                    <p className="text-[var(--foreground-muted)]">per month</p>
                  </div>
                  
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
                    ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-6 h-6 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" strokeWidth={2} />
                        <span className="text-[var(--foreground-muted)]">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-8 py-4 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold text-lg text-center hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background)] transition-all duration-300"
                  >
                    Start Free Trial
                  </a>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FEATURE COMPARISON - Visual Table
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[1] = el; }}
        className="relative py-16 md:py-24 bg-[var(--background-elevated)] overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-6xl mx-auto px-4 md:px-6">
            <h2 className="text-4xl md:text-6xl font-bold text-center mb-12 md:mb-16">Feature Comparison</h2>
            
            <div className="rounded-3xl bg-[var(--background)] border border-[var(--border)] overflow-hidden">
              <div className="overflow-x-auto -mx-4 md:mx-0 px-4 md:px-0">
                <table className="w-full min-w-[500px] md:min-w-0">
                  <thead>
                    <tr className="border-b border-[var(--border)] bg-[var(--background-elevated)]">
                      <th className="text-left py-4 md:py-6 px-4 md:px-6 lg:px-8 text-sm md:text-lg font-bold text-[var(--foreground)]">Feature</th>
                      <th className="text-center py-4 md:py-6 px-4 md:px-6 lg:px-8 text-sm md:text-lg font-bold text-[var(--foreground)]">Free</th>
                      <th className="text-center py-4 md:py-6 px-4 md:px-6 lg:px-8 text-sm md:text-lg font-bold text-gradient">Pro</th>
                    </tr>
                  </thead>
                  <tbody>
                    {[
                      { feature: 'Focus Timer', free: '✓', pro: '✓' },
                      { feature: 'Ambient Backgrounds', free: '3', pro: '14' },
                      { feature: 'Focus Sounds', free: '3', pro: '11' },
                      { feature: 'Themes', free: '2', pro: '10' },
                      { feature: 'Focus Presets', free: '3', pro: 'Unlimited' },
                      { feature: 'Tasks', free: '3', pro: 'Unlimited' },
                      { feature: 'Progress History', free: '3 days', pro: 'Full history' },
                      { feature: 'XP & Levels', free: '—', pro: '50 levels' },
                      { feature: 'Achievement Badges', free: '—', pro: '✓' },
                      { feature: 'Journey View', free: '—', pro: '✓' },
                      { feature: 'Cloud Sync', free: '—', pro: '✓' },
                      { feature: 'Interactive Widgets', free: '—', pro: '✓' },
                      { feature: 'Live Activity', free: '—', pro: '✓' },
                      { feature: 'Music Integration', free: '—', pro: '✓' },
                    ].map((row, i) => (
                      <tr key={i} className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--background-elevated)] transition-colors">
                        <td className="py-4 md:py-6 px-4 md:px-6 lg:px-8 text-sm md:text-lg text-[var(--foreground)] font-medium">{row.feature}</td>
                        <td className="py-4 md:py-6 px-4 md:px-6 lg:px-8 text-center text-sm md:text-lg text-[var(--foreground-muted)]">{row.free}</td>
                        <td className="py-4 md:py-6 px-4 md:px-6 lg:px-8 text-center text-sm md:text-lg text-[var(--accent-primary)] font-semibold">{row.pro}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FAQ - Premium Cards
          ═══════════════════════════════════════════════════════════════ */}
      <section 
        ref={(el) => { sectionRefs.current[2] = el; }}
        className="relative py-16 md:py-24 overflow-hidden opacity-0 transition-opacity duration-1000"
      >
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto px-4 md:px-6">
            <div className="text-center mb-12 md:mb-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-elevated)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-6">
                <HelpCircle className="w-4 h-4 text-[var(--accent-primary)]" />
                <span>Got Questions?</span>
              </div>
              <h2 className="text-4xl md:text-6xl font-bold">Frequently Asked Questions</h2>
            </div>
            
            <div className="space-y-6">
              {[
                {
                  q: 'Is there a free trial?',
                  a: 'Yes! All Pro features are available with a free trial. You can cancel anytime during the trial period.',
                },
                {
                  q: 'Can I switch between monthly and yearly?',
                  a: 'Yes, you can change your subscription plan at any time from your account settings.',
                },
                {
                  q: 'What happens if I cancel?',
                  a: 'You\'ll keep access to Pro features until the end of your billing period. After that, you\'ll revert to the Free plan.',
                },
                {
                  q: 'Do I need to sign in for Pro?',
                  a: 'Yes, Pro features require an account for cloud sync and cross-device access. The Free plan works offline without an account.',
                },
                {
                  q: 'Can I use Pro on multiple devices?',
                  a: 'Yes! With Pro, you can sign in and sync your data across all your devices (iOS, Web, macOS).',
                },
              ].map((faq, i) => (
                <div key={i} className="group p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-all hover:scale-[1.01] hover:shadow-lg">
                  <h3 className="text-2xl md:text-3xl font-bold text-[var(--foreground)] mb-4">{faq.q}</h3>
                  <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-24 bg-[var(--background-elevated)]">
        {/* Section divider */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[var(--border)] to-transparent" />
        
        <Container>
          <div className="max-w-4xl mx-auto text-center px-4 md:px-6">
            <h2 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 md:mb-8">
              Ready to unlock <span className="text-gradient">Pro?</span>
            </h2>
            <p className="text-xl md:text-2xl text-[var(--foreground-muted)] mb-12 md:mb-16 leading-relaxed font-light">
              Start your free trial and experience the full power of FocusFlow.
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
