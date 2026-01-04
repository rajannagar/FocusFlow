'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import { Sidebar } from '@/components/layout/Sidebar';
import AnimatedBackground from '@/components/common/AnimatedBackground';
import { useSessions } from '@/hooks/supabase/useSessions';
import { useUserStats } from '@/hooks/supabase/useUserStats';
import { useTasks } from '@/hooks/supabase/useTasks';
import { useSessionsStore } from '@/stores/useSessionsStore';
import { DashboardHero } from '@/components/dashboard/DashboardHero';
import { StatsGrid } from '@/components/dashboard/StatsGrid';
import { QuickActions } from '@/components/dashboard/QuickActions';
import { RecentActivity } from '@/components/dashboard/RecentActivity';
import DarkModeToggle from '@/components/common/DarkModeToggle';
import { motion } from 'framer-motion';
import { Sparkles, TrendingUp, Target } from 'lucide-react';

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

  // Calculate daily goal progress (assuming 2 hours = 7200 seconds as default goal)
  const dailyGoal = 7200; // 2 hours in seconds
  const goalProgress = Math.min((todayFocusTime / dailyGoal) * 100, 100);

  return (
    <div className="min-h-screen flex bg-[var(--background)] relative overflow-hidden">
      {/* Animated Background */}
      <AnimatedBackground variant="aurora" showGrid={true} />
      
      <Sidebar />
      
      <main className="flex-1 flex flex-col lg:ml-0 relative z-10">
        {/* Top Bar - Enhanced Premium Header */}
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="sticky top-0 z-30 bg-[var(--background)]/80 backdrop-blur-xl border-b border-[var(--border)] px-6 lg:px-8 py-4"
        >
          <div className="max-w-[1600px] mx-auto">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
              <div>
                  <motion.h1 
                    className="text-xl md:text-2xl font-bold flex items-center gap-2"
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 }}
                  >
                    <span>Welcome back</span>
                    {user.email && (
                      <span className="text-[var(--accent-primary)]">
                        {user.email.split('@')[0]}
                      </span>
                    )}
                    <Sparkles className="w-5 h-5 text-[var(--accent-secondary)]" />
                  </motion.h1>
                  <p className="text-sm text-[var(--foreground-muted)] mt-1 flex items-center gap-2">
                  {new Date().toLocaleDateString('en-US', { 
                    weekday: 'long', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                    <span className="text-[var(--foreground-subtle)]">•</span>
                    <span className="flex items-center gap-1">
                      <Target className="w-3.5 h-3.5" />
                      {Math.round(goalProgress)}% of daily goal
                    </span>
                </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <DarkModeToggle />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Main Content - Enhanced Layout */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-[1600px] mx-auto p-6 lg:p-8">
            {/* Hero Timer Section - Full Width */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mb-8"
            >
              <DashboardHero />
            </motion.div>

            {/* Two Column Layout for Stats and Quick Actions */}
            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 lg:gap-8 mb-8">
              {/* Left Column - Stats Grid (2/3 width on xl) */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
                className="xl:col-span-2"
            >
              <StatsGrid
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

              {/* Right Column - Quick Actions (1/3 width on xl) */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
                className="xl:col-span-1"
            >
              <QuickActions 
                totalTasks={tasks?.length || 0}
              />
            </motion.div>
            </div>

            {/* Recent Activity - Full Width */}
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
