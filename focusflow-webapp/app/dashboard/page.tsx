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
import UserMenu from '@/components/common/UserMenu';
import { motion } from 'framer-motion';
import { Target, Calendar } from 'lucide-react';

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

  // Section Divider Component (matching main site style)
  const SectionDivider = () => (
    <div className="relative h-px w-full bg-gradient-to-r from-transparent via-[var(--border)] to-transparent my-12 md:my-16" />
  );

  return (
    <div className="min-h-screen flex bg-[var(--background)] relative overflow-hidden">
      {/* Animated Background - Matching main site */}
      <AnimatedBackground variant="aurora" showGrid={true} />
      
      <Sidebar />
      
      <main className="flex-1 flex flex-col lg:ml-0 relative z-10 pt-4">
        {/* Top Bar - Compact Professional Header */}
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="sticky top-4 z-30 bg-[var(--background-elevated)]/90 backdrop-blur-xl border border-[var(--border)] rounded-2xl mx-4 md:mx-6 lg:mx-8 shadow-sm"
        >
          <div className="px-4 md:px-6">
            <div className="flex items-center justify-between h-12 md:h-14">
              {/* Left: Welcome & Date - Compact */}
              <div className="flex items-center gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-[var(--foreground)]">Welcome back</span>
                    {user.email && (
                      <span className="text-sm font-semibold text-[var(--accent-primary)]">
                        {user.email.split('@')[0]}
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-[var(--foreground-muted)] flex items-center gap-1.5 mt-0.5">
                    <Calendar className="w-3 h-3" />
                    {new Date().toLocaleDateString('en-US', { 
                      weekday: 'short', 
                      month: 'short', 
                      day: 'numeric' 
                    })}
                    <span className="text-[var(--foreground-subtle)]">•</span>
                    <span className="flex items-center gap-1">
                      <Target className="w-3 h-3" />
                      {Math.round(goalProgress)}% goal
                    </span>
                  </p>
                </div>
              </div>
              
              {/* Right: User Menu & Theme Toggle */}
              <div className="flex items-center gap-2">
                <UserMenu />
                <DarkModeToggle />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Main Content - Premium Layout (matching main site) */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8 py-6 md:py-8">
            
            {/* Hero Timer Section */}
            <motion.section
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mb-8 md:mb-12"
            >
              <DashboardHero />
            </motion.section>

            <SectionDivider />

            {/* Stats and Quick Actions Section */}
            <section className="mb-8 md:mb-12">
              <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 lg:gap-8">
                
                {/* Stats Grid - Left Column (2/3 width on xl) */}
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

                {/* Quick Actions - Right Column (1/3 width on xl) */}
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
            </section>

            {/* Recent Activity Section */}
            {(recentSessions.length > 0 || activeTasks.length > 0) && (
              <>
                <SectionDivider />
                <motion.section
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: 0.4 }}
                >
                  <RecentActivity
                    sessions={recentSessions}
                    tasks={activeTasks}
                    loading={sessionsLoading || tasksLoading}
                  />
                </motion.section>
              </>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
