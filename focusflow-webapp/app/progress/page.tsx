'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import AppHeader from '@/components/layout/AppHeader';
import { useSessions } from '@/hooks/supabase/useSessions';
import { useUserStats } from '@/hooks/supabase/useUserStats';
import { useSessionsStore } from '@/stores/useSessionsStore';
import StatsCard from '@/components/dashboard/StatsCard';
import { Timer, TrendingUp, Award, Flame } from 'lucide-react';

// Helper function to format focus time
function formatFocusTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

export default function ProgressPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  
  // Sync auth state with stores
  useSyncAuth();
  useOnlineStatus();
  
  // Fetch data
  const userId = user?.id;
  const { sessions, isLoading: sessionsLoading } = useSessions(userId);
  const { data: stats, isLoading: statsLoading } = useUserStats(userId);
  
  // Get computed stats from store
  const { getTotalSessions, getTotalFocusTime, getTodayFocusTime, getThisWeekFocusTime, getThisMonthFocusTime } = useSessionsStore();
  
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
        <div className="max-w-6xl mx-auto space-y-8">
          {/* Page Header */}
          <div className="space-y-2">
            <h1 className="text-3xl md:text-4xl font-bold">Progress</h1>
            <p className="text-[var(--foreground-muted)]">
              Track your focus statistics and see your progress over time
            </p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
            <StatsCard
              title="Total Sessions"
              value={sessionsLoading ? '...' : String(getTotalSessions())}
              icon={Timer}
              description="All time sessions"
            />
            <StatsCard
              title="Total Focus Time"
              value={sessionsLoading ? '...' : formatFocusTime(getTotalFocusTime())}
              icon={TrendingUp}
              description="All time focus"
            />
            <StatsCard
              title="Current Streak"
              value={statsLoading ? '...' : String(stats?.currentStreak || 0)}
              icon={Flame}
              description="Days in a row"
            />
            <StatsCard
              title="Level"
              value={statsLoading ? '...' : String(stats?.currentLevel || 1)}
              icon={Award}
              description={`${stats?.totalXp || 0} XP`}
            />
          </div>

          {/* Time Period Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
            <StatsCard
              title="Today"
              value={sessionsLoading ? '...' : formatFocusTime(getTodayFocusTime())}
              icon={Timer}
              description="Focus time today"
            />
            <StatsCard
              title="This Week"
              value={sessionsLoading ? '...' : formatFocusTime(getThisWeekFocusTime())}
              icon={TrendingUp}
              description="Focus time this week"
            />
            <StatsCard
              title="This Month"
              value={sessionsLoading ? '...' : formatFocusTime(getThisMonthFocusTime())}
              icon={TrendingUp}
              description="Focus time this month"
            />
          </div>

          {/* Coming Soon */}
          <div className="card p-8 text-center">
            <p className="text-[var(--foreground-muted)] mb-4">
              Advanced analytics, charts, and insights coming soon!
            </p>
            <div className="badge badge-secondary">Coming Soon</div>
          </div>
        </div>
      </main>
    </div>
  );
}

