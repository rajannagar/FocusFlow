'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Container } from '@/components';
import { useThrottledMouse } from '@/hooks';
import { APP_STORE_URL } from '@/lib/constants';

export default function SignInPage() {
  const mousePosition = useThrottledMouse();
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    setTimeout(() => {
      setIsLoading(false);
      alert('Authentication coming soon! The web app is currently in development.');
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-[var(--background)] flex items-center justify-center py-12 md:py-24 relative overflow-hidden">
      {/* Subtle background */}
      <div className="absolute inset-0">
        <div 
          className="absolute top-1/3 left-1/4 w-[400px] md:w-[800px] h-[400px] md:h-[800px] rounded-full blur-[100px] md:blur-[150px] opacity-[0.05] transition-transform duration-[3000ms] ease-out"
          style={{
            background: `radial-gradient(circle, rgba(139, 92, 246, 0.6) 0%, transparent 70%)`,
            transform: `translate(${mousePosition.x * 0.01}px, ${mousePosition.y * 0.01}px)`,
          }}
        />
      </div>
      <div className="absolute inset-0 bg-grid opacity-[0.02]" />

      <Container>
        <div className="relative z-10 max-w-md mx-auto px-4 md:px-6 w-full">
          {/* App Icon */}
          <div className="flex justify-center mb-8 md:mb-12">
            <div className="relative">
              <div className="absolute -inset-6 bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 rounded-[40px] blur-2xl" />
              <Image
                src="/focusflow-app-icon.jpg"
                alt="FocusFlow - Be Present"
                width={100}
                height={100}
                className="relative rounded-[28px] shadow-2xl"
                style={{
                  boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4)'
                }}
              />
            </div>
          </div>

          {/* Card */}
          <div className="p-8 md:p-12 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] backdrop-blur-xl">
            <h1 className="text-4xl md:text-5xl font-bold text-center mb-3">
              {isSignUp ? 'Create Account' : 'Sign In'}
            </h1>
            <p className="text-center text-lg text-[var(--foreground-muted)] mb-8 md:mb-10 font-light">
              {isSignUp 
                ? 'Start your journey to better focus' 
                : 'Welcome back to FocusFlow'
              }
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Email */}
              <div>
                <label htmlFor="email" className="block text-sm font-semibold text-[var(--foreground)] mb-2">
                  Email
                </label>
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full px-5 py-4 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)] placeholder-[var(--foreground-subtle)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)]/50 focus:border-[var(--accent-primary)] transition-all text-lg"
                  placeholder="you@example.com"
                />
              </div>

              {/* Password */}
              <div>
                <label htmlFor="password" className="block text-sm font-semibold text-[var(--foreground)] mb-2">
                  Password
                </label>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  className="w-full px-5 py-4 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)] placeholder-[var(--foreground-subtle)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)]/50 focus:border-[var(--accent-primary)] transition-all text-lg"
                  placeholder="••••••••"
                />
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="group relative w-full px-8 py-4 rounded-2xl bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white font-semibold text-lg overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-xl hover:shadow-[var(--accent-primary)]/30 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                {isLoading ? (
                  <div className="relative z-10 flex items-center justify-center gap-3">
                    <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{isSignUp ? 'Creating Account...' : 'Signing In...'}</span>
                  </div>
                ) : (
                  <span className="relative z-10">{isSignUp ? 'Create Account' : 'Sign In'}</span>
                )}
              </button>
            </form>

            {/* Divider */}
            <div className="relative my-8 md:my-10">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-[var(--border)]"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-[var(--background-elevated)] text-[var(--foreground-muted)]">Or continue with</span>
              </div>
            </div>

            {/* OAuth Buttons */}
            <div className="space-y-4">
              <button
                type="button"
                className="w-full px-5 py-4 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)] hover:border-[var(--accent-primary)]/30 transition-all flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
                disabled
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                </svg>
                <span>Google (Coming Soon)</span>
              </button>
              <button
                type="button"
                className="w-full px-5 py-4 rounded-2xl bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)] hover:border-[var(--accent-primary)]/30 transition-all flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
                disabled
              >
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.96-3.24-1.5-1.84-.78-2.9-1.21-4.63-1.95-2.15-1.1-3.72-2.38-3.72-4.5 0-1.02.33-1.98.92-2.73 1.11-1.15 2.56-1.78 4.15-1.78 1.12 0 2.19.39 3.07 1.1.35.29.66.59.96.89.6-.6 1.3-1.1 2.07-1.45 1.78-.8 3.96-1.05 5.26-.36 1.02.54 1.85 1.52 2.47 2.75-2.23 1.25-3.57 3.11-3.57 5.31 0 2.12 1.34 3.98 3.57 5.23-.62 1.23-1.45 2.21-2.47 2.75-.5.26-1.07.38-1.66.38-.45 0-.9-.07-1.34-.2z"/>
                </svg>
                <span>Apple (Coming Soon)</span>
              </button>
            </div>

            {/* Toggle Sign Up / Sign In */}
            <div className="mt-8 md:mt-10 text-center text-base text-[var(--foreground-muted)]">
              {isSignUp ? (
                <>
                  Already have an account?{' '}
                  <button
                    onClick={() => setIsSignUp(false)}
                    className="text-[var(--accent-primary)] hover:underline font-semibold"
                  >
                    Sign in
                  </button>
                </>
              ) : (
                <>
                  Don't have an account?{' '}
                  <button
                    onClick={() => setIsSignUp(true)}
                    className="text-[var(--accent-primary)] hover:underline font-semibold"
                  >
                    Sign up
                  </button>
                </>
              )}
            </div>
          </div>

          {/* Web App Coming Soon Notice */}
          <div className="mt-8 md:mt-12 p-8 md:p-10 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] text-center backdrop-blur-xl">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-6">
              <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
              </svg>
              <span>Coming Soon</span>
            </div>
            <p className="text-lg md:text-xl text-[var(--foreground-muted)] mb-6 font-light">
              The FocusFlow web app is currently in development. Sign in will be available soon!
            </p>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl border-2 border-[var(--border)] text-[var(--foreground)] font-semibold hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background)] transition-all duration-300"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              Download iOS App
            </a>
          </div>
        </div>
      </Container>
    </div>
  );
}
