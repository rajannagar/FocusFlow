'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useThrottledMouse } from '@/hooks';
import { useAuth } from '@/contexts/AuthContext';
import { createClient } from '@/lib/supabase/client';
import { APP_STORE_URL } from '@/lib/constants';
import { Mail, Lock, LogIn, UserPlus, Loader2, Sparkles, AlertCircle, CheckCircle } from 'lucide-react';

export default function SignInPage() {
  const mousePosition = useThrottledMouse();
  const router = useRouter();
  const { user, signUp, signIn, resetPassword } = useAuth();
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isResetting, setIsResetting] = useState(false);

  // Redirect if already signed in
  useEffect(() => {
    if (user) {
      router.push('/');
    }
  }, [user, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setIsLoading(true);

    try {
      if (isSignUp) {
        const { error } = await signUp(email, password);
        if (error) {
          setError(error.message || 'Failed to create account. Please try again.');
        } else {
          setSuccess('Account created! Please check your email to verify your account.');
          setEmail('');
          setPassword('');
        }
      } else {
        const { error } = await signIn(email, password);
        if (error) {
          setError(error.message || 'Invalid email or password. Please try again.');
        } else {
          // Success - user will be redirected by useEffect
          router.push('/');
        }
      }
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetPassword = async () => {
    if (!email) {
      setError('Please enter your email address first.');
      return;
    }

    setError(null);
    setSuccess(null);
    setIsResetting(true);

    try {
      const { error } = await resetPassword(email);
      if (error) {
        setError(error.message || 'Failed to send reset email. Please try again.');
      } else {
        setSuccess('Password reset email sent! Check your inbox for instructions.');
      }
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred. Please try again.');
    } finally {
      setIsResetting(false);
    }
  };

  const handleOAuthSignIn = async (provider: 'apple' | 'google') => {
    setError(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/signin`,
      },
    });
    if (error) {
      setError(error.message || `Failed to sign in with ${provider}. Please try again.`);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--background)] flex">
      {/* ═══════════════════════════════════════════════════════════════
          LEFT SIDE - Visual & Welcome Message
          ═══════════════════════════════════════════════════════════════ */}
      <div className="hidden lg:flex lg:w-1/3 xl:w-2/5 relative overflow-hidden bg-[var(--background-elevated)]">
        {/* Subtle gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/3 via-transparent to-[var(--accent-secondary)]/3" />

        {/* Content */}
        <div className="relative z-10 flex flex-col justify-between p-12 xl:p-16 h-full">
          {/* Top - Logo */}
          <div>
            <Link href="/" className="inline-flex items-center gap-2 mb-8 group">
              <Image
                src="/focusflow-logo.png"
                alt="FocusFlow"
                width={32}
                height={32}
                className="relative z-10"
              />
              <span className="text-xl font-bold tracking-tight text-[var(--foreground)] group-hover:text-[var(--accent-primary)] transition-colors">
                FocusFlow
              </span>
            </Link>
          </div>

          {/* Middle - Welcome Message */}
          <div className="flex-1 flex flex-col justify-center">
            <div className="space-y-6 max-w-sm">
              {isSignUp ? (
                <>
                  <h2 className="text-4xl xl:text-5xl font-bold text-[var(--foreground)] leading-tight">
                    Welcome to FocusFlow
                  </h2>
                  <p className="text-lg text-[var(--foreground-muted)] leading-relaxed font-light">
                    Start your journey to better focus and productivity. Create your account and begin building better habits today.
                  </p>
                </>
              ) : (
                <>
                  <h2 className="text-4xl xl:text-5xl font-bold text-[var(--foreground)] leading-tight">
                    Welcome back!
                  </h2>
                  <p className="text-lg text-[var(--foreground-muted)] leading-relaxed font-light">
                    Ready to dive in and continue where you left off? Sign in to access your sessions, tasks, and progress.
                  </p>
                </>
              )}
            </div>
          </div>

          {/* Bottom - Decorative elements */}
          <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)]">
            <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" />
            <span>Built for deep work</span>
          </div>
        </div>
      </div>

      {/* ═══════════════════════════════════════════════════════════════
          RIGHT SIDE - Sign In Form
          ═══════════════════════════════════════════════════════════════ */}
      <div className="flex-1 lg:w-2/3 xl:w-3/5 flex items-center justify-center p-6 md:p-12 lg:p-16">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden mb-8">
            <Link href="/" className="inline-flex items-center gap-2 group">
              <Image
                src="/focusflow-logo.png"
                alt="FocusFlow"
                width={32}
                height={32}
                className="relative z-10"
              />
              <span className="text-xl font-bold tracking-tight text-[var(--foreground)] group-hover:text-[var(--accent-primary)] transition-colors">
                FocusFlow
              </span>
            </Link>
          </div>

          {/* Title */}
          <h1 className="text-4xl md:text-5xl font-bold text-[var(--foreground)] mb-2">
            {isSignUp ? 'Create account' : 'Sign in to FocusFlow'}
          </h1>
          <p className="text-base text-[var(--foreground-muted)] mb-8 font-light">
            {isSignUp 
              ? 'Start your journey to better focus' 
              : 'Sign in with Apple, Google or Email'
            }
          </p>

          {/* Error/Success Messages */}
          {error && (
            <div className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/20 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-400">{error}</p>
            </div>
          )}
          {success && (
            <div className="mb-6 p-4 rounded-xl bg-green-500/10 border border-green-500/20 flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-green-400">{success}</p>
            </div>
          )}

          {/* Social Sign-in Buttons */}
          <div className="space-y-3 mb-6">
            <button
              type="button"
              onClick={() => handleOAuthSignIn('apple')}
              disabled={isLoading}
              className="w-full px-6 py-4 rounded-xl bg-[var(--background)] border-2 border-[var(--border)] text-[var(--foreground)] hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.96-3.24-1.5-1.84-.78-2.9-1.21-4.63-1.95-2.15-1.1-3.72-2.38-3.72-4.5 0-1.02.33-1.98.92-2.73 1.11-1.15 2.56-1.78 4.15-1.78 1.12 0 2.19.39 3.07 1.1.35.29.66.59.96.89.6-.6 1.3-1.1 2.07-1.45 1.78-.8 3.96-1.05 5.26-.36 1.02.54 1.85 1.52 2.47 2.75-2.23 1.25-3.57 3.11-3.57 5.31 0 2.12 1.34 3.98 3.57 5.23-.62 1.23-1.45 2.21-2.47 2.75-.5.26-1.07.38-1.66.38-.45 0-.9-.07-1.34-.2z"/>
              </svg>
              <span>Continue with Apple</span>
            </button>
            <button
              type="button"
              onClick={() => handleOAuthSignIn('google')}
              disabled={isLoading}
              className="w-full px-6 py-4 rounded-xl bg-[var(--background)] border-2 border-[var(--border)] text-[var(--foreground)] hover:border-[var(--accent-primary)]/50 hover:bg-[var(--background-elevated)] transition-all duration-300 flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
              <span>Continue with Google</span>
            </button>
          </div>

          {/* Divider */}
          <div className="relative my-8">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-[var(--border)]"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-[var(--background)] text-[var(--foreground-muted)] text-xs uppercase tracking-wider">
                {isSignUp ? 'Or sign up with email' : 'Or sign in with email'}
              </span>
            </div>
          </div>

          {/* Email/Password Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email */}
            <div>
              <label htmlFor="email" className="block text-xs font-semibold text-[var(--foreground-muted)] uppercase tracking-wider mb-2">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] placeholder-[var(--foreground-subtle)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)]/50 focus:border-[var(--accent-primary)] transition-all"
                placeholder="e.g. hello@focusflowbepresent.com"
              />
            </div>

            {/* Password */}
            <div>
              <label htmlFor="password" className="block text-xs font-semibold text-[var(--foreground-muted)] uppercase tracking-wider mb-2">
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
                className="w-full px-4 py-3 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] placeholder-[var(--foreground-subtle)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)]/50 focus:border-[var(--accent-primary)] transition-all"
                placeholder="Strong password"
              />
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full px-6 py-4 rounded-xl bg-[var(--foreground)] text-[var(--background)] font-semibold hover:opacity-90 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  <span>{isSignUp ? 'Creating account...' : 'Signing in...'}</span>
                </>
              ) : (
                <>
                  {isSignUp ? <UserPlus className="w-5 h-5" /> : <LogIn className="w-5 h-5" />}
                  <span>{isSignUp ? 'Create account' : 'Sign in'}</span>
                </>
              )}
            </button>
          </form>

          {/* Links */}
          <div className="mt-8 flex items-center justify-between text-sm">
            {isSignUp ? (
              <button
                onClick={() => setIsSignUp(false)}
                className="text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors"
              >
                Already have an account? Sign in
              </button>
            ) : (
              <>
                <button
                  onClick={handleResetPassword}
                  disabled={isResetting}
                  className="text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors disabled:opacity-50"
                >
                  {isResetting ? 'Sending...' : 'Reset password'}
                </button>
                <button
                  onClick={() => {
                    setIsSignUp(true);
                    setError(null);
                    setSuccess(null);
                  }}
                  className="text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors"
                >
                  Create new account
                </button>
              </>
            )}
          </div>

          {/* Info Notice */}
          <div className="mt-12 p-6 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-center">
            <p className="text-sm text-[var(--foreground-muted)] mb-4 font-light">
              Sign in to sync your data across all devices. The web app is coming soon!
            </p>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-sm text-[var(--accent-primary)] hover:underline font-medium"
            >
              Download iOS App
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
