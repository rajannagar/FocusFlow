'use client';

import Link from 'next/link';
import { Container, PhoneSimulator } from '@/components';
import { APP_STORE_URL } from '@/lib/constants';

export default function FeaturesPage() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* Hero */}
      <section className="pt-40 pb-32">
        <Container>
          <div className="max-w-3xl mx-auto text-center px-4">
            <h1 className="text-8xl md:text-9xl font-bold mb-8 leading-[0.9]">Features</h1>
            <p className="text-2xl text-[var(--foreground-muted)] font-light">Everything you need to focus.</p>
          </div>
        </Container>
      </section>

      {/* Focus Timer - Full Width */}
      <section className="py-32 md:py-48">
        <Container>
          <div className="max-w-6xl mx-auto px-4">
            <div className="mb-20 text-center">
              <h2 className="text-6xl md:text-7xl font-bold mb-6">Focus Timer</h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] font-light max-w-2xl mx-auto">
                14 ambient backgrounds. 11 focus sounds. Music integration. Live Activity.
              </p>
            </div>
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute -inset-16 bg-gradient-to-br from-violet-500/20 to-purple-500/10 blur-[120px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png']}
                  screenData={[
                    { icon: '⏱️', title: 'Timer', desc: 'Start session', gradient: 'from-violet-500 to-purple-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Tasks - Full Width */}
      <section className="py-32 md:py-48 bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto px-4">
            <div className="mb-20 text-center">
              <h2 className="text-6xl md:text-7xl font-bold mb-6">Tasks</h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] font-light max-w-2xl mx-auto">
                Recurring schedules. Duration tracking. Smart reminders. Unlimited tasks.
              </p>
            </div>
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute -inset-16 bg-gradient-to-br from-emerald-500/20 to-teal-500/10 blur-[120px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-tasks-1.png', '/images/screen-tasks-2.png', '/images/screen-tasks-3.png']}
                  screenData={[
                    { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-emerald-500 to-teal-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Progress - Full Width */}
      <section className="py-32 md:py-48">
        <Container>
          <div className="max-w-6xl mx-auto px-4">
            <div className="mb-20 text-center">
              <h2 className="text-6xl md:text-7xl font-bold mb-6">Progress</h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] font-light max-w-2xl mx-auto">
                50 levels. Achievement badges. Journey view. Full history.
              </p>
            </div>
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute -inset-16 bg-gradient-to-br from-amber-500/20 to-orange-500/10 blur-[120px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png']}
                  screenData={[
                    { icon: '📈', title: 'Progress', desc: 'Summary', gradient: 'from-amber-500 to-orange-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Personalization - Full Width */}
      <section className="py-32 md:py-48 bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto px-4">
            <div className="mb-20 text-center">
              <h2 className="text-6xl md:text-7xl font-bold mb-6">Personalization</h2>
              <p className="text-xl md:text-2xl text-[var(--foreground-muted)] font-light max-w-2xl mx-auto">
                10 themes. 50+ avatars. Unlimited presets. Cloud sync.
              </p>
            </div>
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute -inset-16 bg-gradient-to-br from-rose-500/20 to-pink-500/10 blur-[120px] rounded-full" />
                <PhoneSimulator 
                  screenshots={['/images/screen-profile.png', '/images/screen-profile-2.png', '/images/screen-profile-3.png']}
                  screenData={[
                    { icon: '🎨', title: 'Profile', desc: 'Your space', gradient: 'from-rose-500 to-pink-600' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* More Features - Simple List */}
      <section className="py-32 md:py-48">
        <Container>
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-5xl md:text-6xl font-bold text-center mb-16">And more</h2>
            <div className="grid md:grid-cols-3 gap-12 text-center">
              <div>
                <div className="text-4xl mb-3">📱</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Widgets</div>
                <div className="text-sm text-[var(--foreground-muted)]">Home screen</div>
              </div>
              <div>
                <div className="text-4xl mb-3">🔔</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Live Activity</div>
                <div className="text-sm text-[var(--foreground-muted)]">Dynamic Island</div>
              </div>
              <div>
                <div className="text-4xl mb-3">☁️</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Cloud Sync</div>
                <div className="text-sm text-[var(--foreground-muted)]">All devices</div>
              </div>
              <div>
                <div className="text-4xl mb-3">🎵</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Music</div>
                <div className="text-sm text-[var(--foreground-muted)]">Spotify, Apple Music</div>
              </div>
              <div>
                <div className="text-4xl mb-3">✈️</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Offline</div>
                <div className="text-sm text-[var(--foreground-muted)]">Works offline</div>
              </div>
              <div>
                <div className="text-4xl mb-3">🔒</div>
                <div className="text-lg font-medium text-[var(--foreground)] mb-1">Privacy</div>
                <div className="text-sm text-[var(--foreground-muted)]">Always encrypted</div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* CTA */}
      <section className="py-32 md:py-48 bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-3xl mx-auto text-center px-4">
            <h2 className="text-5xl md:text-6xl font-bold mb-8">Try FocusFlow</h2>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-3 px-10 py-5 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg hover:scale-[1.02] transition-transform"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              Download on App Store
            </a>
          </div>
        </Container>
      </section>
    </div>
  );
}
