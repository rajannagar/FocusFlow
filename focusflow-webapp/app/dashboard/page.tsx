'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import { Sidebar } from '@/components/layout/Sidebar';
import { useSessions } from '@/hooks/supabase/useSessions';
import { useUserStats } from '@/hooks/supabase/useUserStats';
import { useTasks } from '@/hooks/supabase/useTasks';
import { useSessionsStore } from '@/stores/useSessionsStore';
import { PremiumDashboardHero } from '@/components/dashboard/PremiumDashboardHero';
import { PremiumStatsGrid } from '@/components/dashboard/PremiumStatsGrid';
import { XPLevelDisplay } from '@/components/dashboard/XPLevelDisplay';
import { QuickActions } from '@/components/dashboard/QuickActions';
import { RecentActivity } from '@/components/dashboard/RecentActivity';
import { PremiumBackground } from '@/components/ui/PremiumBackground';
import DarkModeToggle from '@/components/common/DarkModeToggle';
import { motion } from 'framer-motion';

export default function DashboardPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  
  // Sync auth state with stores
  useSyncAuth();
  useOnlineStatus();
  
  // Fetch data from Supabase
  const userId = user?.id;
  const { sessions, isLoading: sessionsLoading } = useSessions(userId);
  const { data: stats, isLoading: statsLoading } = useUserStats(userId);
  const { tasks, isLoading: tasksLoading } = useTasks(userId);
  
  // Get stores
  const { getTotalSessions, getTotalFocusTime, getTodayFocusTime, getTodaySessions } = useSessionsStore();
  
  useEffect(() => {
    if (!loading && !user) {
      router.push('/signin');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="text-[var(--foreground-muted)]">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null; // Will redirect
  }

  const todaySessions = getTodaySessions();
  const todayFocusTime = getTodayFocusTime();
  const totalFocusTime = getTotalFocusTime();
  const totalSessions = getTotalSessions();
  const recentSessions = sessions?.slice(0, 5) || [];
  const activeTasks = tasks?.slice(0, 5) || [];

  // Calculate weekly stats
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - now.getDay());
  weekStart.setHours(0, 0, 0, 0);
  const weeklySessions = sessions?.filter(s => {
    const sessionDate = new Date(s.startedAt);
    return sessionDate >= weekStart;
  }) || [];
  const weeklyFocusTime = weeklySessions.reduce((acc, s) => acc + s.durationSeconds, 0);

  return (
    <div className="min-h-screen flex bg-[var(--background)] relative overflow-hidden">
      {/* Premium Background */}
      <PremiumBackground variant="intense" showParticles={true} particleCount={20} />

      <Sidebar />
      
      <main className="flex-1 flex flex-col lg:ml-0 relative z-10">
        {/* Top Bar - Minimal & Premium */}
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="sticky top-0 z-30 bg-[var(--background)]/80 backdrop-blur-xl border-b border-[var(--border)] px-6 lg:px-8 py-3"
        >
          <div className="max-w-7xl mx-auto">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-lg md:text-xl font-semibold">
                  Welcome back{user.email ? `, ${user.email.split('@')[0]}` : ''}
                </h1>
                <p className="text-xs text-[var(--foreground-muted)] mt-0.5">
                  {new Date().toLocaleDateString('en-US', { 
                    weekday: 'long', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <DarkModeToggle />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-7xl mx-auto p-6 lg:p-8 space-y-8">
            {/* Hero Timer Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
            >
              <PremiumDashboardHero />
            </motion.div>

            {/* XP Level Display */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.15 }}
            >
              <XPLevelDisplay
                currentLevel={stats?.currentLevel || 1}
                totalXp={stats?.totalXp || 0}
                xpPerLevel={1000}
              />
            </motion.div>

            {/* Premium Stats Grid */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              <PremiumStatsGrid
                stats={{
                  todayFocusTime,
                  todaySessions: todaySessions.length,
                  weeklyFocusTime,
                  weeklySessions: weeklySessions.length,
                  totalFocusTime,
                  totalSessions,
                  currentStreak: stats?.currentStreak || 0,
                  currentLevel: stats?.currentLevel || 1,
                  totalXp: stats?.totalXp || 0,
                  activeTasks: activeTasks.length,
                  totalTasks: tasks?.length || 0,
                }}
                loading={statsLoading || sessionsLoading}
              />
            </motion.div>

            {/* Quick Actions */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
            >
              <QuickActions 
                totalTasks={tasks?.length || 0}
              />
            </motion.div>

            {/* Recent Activity */}
            {(recentSessions.length > 0 || activeTasks.length > 0) && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.4 }}
              >
                <RecentActivity
                  sessions={recentSessions}
                  tasks={activeTasks}
                  loading={sessionsLoading || tasksLoading}
                />
              </motion.div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
