'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import AppHeader from '@/components/layout/AppHeader';
import StatsCard from '@/components/dashboard/StatsCard';
import ComingSoonCard from '@/components/dashboard/ComingSoonCard';
import { Timer, CheckSquare, TrendingUp, Download } from 'lucide-react';

export default function DashboardPage() {
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
        <div className="space-y-8">
          {/* Welcome Section */}
          <div className="space-y-2">
            <h1 className="text-3xl md:text-4xl font-bold">
              Welcome back{user.email ? `, ${user.email.split('@')[0]}` : ''}
            </h1>
            <p className="text-[var(--foreground-muted)]">
              Manage your focus sessions, tasks, and track your progress.
            </p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
            <StatsCard
              title="Focus Sessions"
              value="0"
              icon={Timer}
              description="Total sessions completed"
            />
            <StatsCard
              title="Tasks Completed"
              value="0"
              icon={CheckSquare}
              description="Tasks finished this week"
            />
            <StatsCard
              title="Focus Time"
              value="0h"
              icon={TrendingUp}
              description="Total time focused"
            />
          </div>

          {/* Coming Soon Features */}
          <div className="space-y-4">
            <h2 className="text-2xl font-bold">Features</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <ComingSoonCard
                title="Focus Timer"
                description="Start a focus session and track your deep work time. Syncs with your iOS app."
                icon={Timer}
              />
              <ComingSoonCard
                title="Task Management"
                description="Create and manage your tasks. Organize your work and stay productive."
                icon={CheckSquare}
              />
              <ComingSoonCard
                title="Progress Tracking"
                description="View your focus statistics, streaks, and progress over time."
                icon={TrendingUp}
              />
              <div className="card p-6">
                <div className="flex items-start gap-4">
                  <div className="p-3 rounded-xl bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20">
                    <Download className="w-6 h-6 text-[var(--accent-primary)]" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-[var(--foreground)] mb-1">
                      Download iOS App
                    </h3>
                    <p className="text-sm text-[var(--foreground-muted)] mb-4">
                      Get the full FocusFlow experience on your iPhone or iPad.
                    </p>
                    <a
                      href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="btn btn-accent"
                    >
                      <Download className="w-4 h-4" />
                      Download on App Store
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

