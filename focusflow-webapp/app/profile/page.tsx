'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import AppHeader from '@/components/layout/AppHeader';
import { User, Mail, Calendar } from 'lucide-react';

export default function ProfilePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/signin');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-[var(--foreground-muted)]">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null; // Will redirect
  }

  return (
    <div className="min-h-screen flex flex-col bg-[var(--background)]">
      <AppHeader />
      <main className="flex-1 container-wide px-4 md:px-6 lg:px-8 py-8 md:py-12">
        <div className="max-w-2xl mx-auto space-y-8">
          <div className="space-y-2">
            <h1 className="text-3xl md:text-4xl font-bold">Profile</h1>
            <p className="text-[var(--foreground-muted)]">
              Manage your account information and settings.
            </p>
          </div>

          <div className="card p-6 md:p-8 space-y-6">
            <div className="flex items-center gap-4 pb-6 border-b border-[var(--border)]">
              <div className="p-4 rounded-xl bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20">
                <User className="w-8 h-8 text-[var(--accent-primary)]" />
              </div>
              <div>
                <h2 className="text-xl font-semibold text-[var(--foreground)]">Account</h2>
                <p className="text-sm text-[var(--foreground-muted)]">Your account details</p>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-start gap-4">
                <Mail className="w-5 h-5 text-[var(--foreground-muted)] mt-1 flex-shrink-0" />
                <div className="flex-1">
                  <label className="block text-sm font-medium text-[var(--foreground-muted)] mb-1">
                    Email
                  </label>
                  <p className="text-[var(--foreground)]">{user.email}</p>
                </div>
              </div>

              {user.created_at && (
                <div className="flex items-start gap-4">
                  <Calendar className="w-5 h-5 text-[var(--foreground-muted)] mt-1 flex-shrink-0" />
                  <div className="flex-1">
                    <label className="block text-sm font-medium text-[var(--foreground-muted)] mb-1">
                      Member Since
                    </label>
                    <p className="text-[var(--foreground)]">
                      {new Date(user.created_at).toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                      })}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

