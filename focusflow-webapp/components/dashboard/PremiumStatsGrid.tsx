'use client';

import { Timer, TrendingUp, Flame, Award, CheckSquare, Clock, Zap, Target } from 'lucide-react';
import { formatDuration } from '@/lib/utils';
import { motion } from 'framer-motion';
import { GlassCard } from '@/components/ui/GlassCard';

interface PremiumStatsGridProps {
  stats: {
    todayFocusTime: number;
    todaySessions: number;
    weeklyFocusTime: number;
    weeklySessions: number;
    totalFocusTime: number;
    totalSessions: number;
    currentStreak: number;
    currentLevel: number;
    totalXp: number;
    activeTasks: number;
    totalTasks: number;
  };
  loading?: boolean;
}

interface StatCardProps {
  icon: any;
  label: string;
  value: string | number;
  subtitle?: string;
  color: string;
  delay?: number;
  loading?: boolean;
  progress?: number; // 0-100
  showRing?: boolean;
}

const PremiumStatCard = ({
  icon: Icon,
  label,
  value,
  subtitle,
  color,
  delay = 0,
  loading = false,
  progress,
  showRing = false
}: StatCardProps) => {
  const circumference = 2 * Math.PI * 36;
  const offset = progress ? circumference - (progress / 100) * circumference : circumference;

  return (
    <GlassCard
      variant="subtle"
      glow
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay, ease: [0.16, 1, 0.3, 1] }}
      className="p-6 group relative overflow-hidden"
    >
      {/* Accent gradient glow */}
      <div
        className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
        style={{
          background: `radial-gradient(circle at top left, ${color}15, transparent 70%)`,
        }}
      />

      <div className="relative z-10">
        {/* Header with icon */}
        <div className="flex items-start justify-between mb-4">
          <div
            className="relative p-3 rounded-xl border transition-all duration-500 group-hover:scale-110 group-hover:rotate-3"
            style={{
              background: `linear-gradient(135deg, ${color}20, ${color}10)`,
              borderColor: `${color}40`,
              boxShadow: `0 4px 12px ${color}20`,
            }}
          >
            <Icon
              className="w-5 h-5 relative z-10"
              style={{
                color: color,
                filter: 'brightness(1.2) drop-shadow(0 2px 4px rgba(0,0,0,0.3))',
              }}
            />

            {/* Icon glow */}
            <div
              className="absolute inset-0 rounded-xl blur-md opacity-50"
              style={{ background: color }}
            />
          </div>

          {/* Optional progress ring */}
          {showRing && progress !== undefined && (
            <div className="relative w-14 h-14">
              <svg className="transform -rotate-90 w-14 h-14">
                {/* Background circle */}
                <circle
                  cx="28"
                  cy="28"
                  r="24"
                  fill="none"
                  stroke="rgba(255, 255, 255, 0.05)"
                  strokeWidth="4"
                />
                {/* Progress circle */}
                <motion.circle
                  cx="28"
                  cy="28"
                  r="24"
                  fill="none"
                  stroke={color}
                  strokeWidth="4"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  initial={{ strokeDashoffset: circumference }}
                  animate={{ strokeDashoffset: offset }}
                  transition={{ duration: 1, delay: delay + 0.3, ease: 'easeOut' }}
                />
              </svg>
              <div
                className="absolute inset-0 flex items-center justify-center text-[10px] font-bold"
                style={{ color }}
              >
                {Math.round(progress)}%
              </div>
            </div>
          )}
        </div>

        {/* Stats */}
        <div className="space-y-1.5">
          {loading ? (
            <>
              <div className="h-9 w-28 bg-[var(--background-subtle)] rounded-lg animate-pulse mb-2" />
              <div className="h-4 w-36 bg-[var(--background-subtle)] rounded animate-pulse" />
            </>
          ) : (
            <>
              <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.5, delay: delay + 0.2 }}
                className="text-4xl font-bold tracking-tight"
                style={{
                  background: `linear-gradient(135deg, ${color}, ${color}cc)`,
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  filter: 'brightness(1.1)',
                }}
              >
                {value}
              </motion.div>
              <div className="text-sm font-semibold text-[var(--foreground)] uppercase tracking-wider">
                {label}
              </div>
              {subtitle && (
                <div className="text-xs text-[var(--foreground-subtle)] font-medium mt-1.5 flex items-center gap-1">
                  <div
                    className="w-1 h-1 rounded-full"
                    style={{ background: color, opacity: 0.6 }}
                  />
                  {subtitle}
                </div>
              )}
            </>
          )}
        </div>

        {/* Bottom accent line */}
        <div
          className="absolute bottom-0 left-0 right-0 h-[2px] opacity-0 group-hover:opacity-100 transition-opacity duration-500"
          style={{
            background: `linear-gradient(90deg, transparent, ${color}, transparent)`,
          }}
        />
      </div>
    </GlassCard>
  );
};

export function PremiumStatsGrid({ stats, loading }: PremiumStatsGridProps) {
  // Calculate XP progress to next level (assuming 1000 XP per level)
  const xpPerLevel = 1000;
  const currentLevelXp = stats.totalXp % xpPerLevel;
  const xpProgress = (currentLevelXp / xpPerLevel) * 100;

  // Calculate task completion percentage
  const taskProgress = stats.totalTasks > 0 ? (stats.activeTasks / stats.totalTasks) * 100 : 0;

  const statsConfig: StatCardProps[] = [
    {
      icon: Timer,
      label: 'Today',
      value: formatDuration(stats.todayFocusTime),
      subtitle: `${stats.todaySessions} session${stats.todaySessions !== 1 ? 's' : ''}`,
      color: '#8B5CF6',
      delay: 0,
      showRing: false,
    },
    {
      icon: Flame,
      label: 'Streak',
      value: `${stats.currentStreak}`,
      subtitle: stats.currentStreak === 1 ? '1 day' : `${stats.currentStreak} days in a row`,
      color: '#F97316',
      delay: 0.1,
      progress: Math.min((stats.currentStreak / 30) * 100, 100), // Max 30 days
      showRing: true,
    },
    {
      icon: Award,
      label: 'Level',
      value: `${stats.currentLevel}`,
      subtitle: `${currentLevelXp.toLocaleString()} / ${xpPerLevel.toLocaleString()} XP`,
      color: '#EAB308',
      delay: 0.2,
      progress: xpProgress,
      showRing: true,
    },
    {
      icon: Clock,
      label: 'This Week',
      value: formatDuration(stats.weeklyFocusTime),
      subtitle: `${stats.weeklySessions} session${stats.weeklySessions !== 1 ? 's' : ''}`,
      color: '#D4A853',
      delay: 0.3,
      showRing: false,
    },
    {
      icon: Target,
      label: 'Total Time',
      value: formatDuration(stats.totalFocusTime),
      subtitle: `${stats.totalSessions} total sessions`,
      color: '#06B6D4',
      delay: 0.4,
      showRing: false,
    },
    {
      icon: CheckSquare,
      label: 'Tasks',
      value: `${stats.activeTasks}`,
      subtitle: `of ${stats.totalTasks} total`,
      color: '#10B981',
      delay: 0.5,
      progress: taskProgress,
      showRing: true,
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex items-end justify-between"
      >
        <div>
          <h2 className="text-3xl font-bold mb-2 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] bg-clip-text text-transparent">
            Your Stats
          </h2>
          <p className="text-[var(--foreground-muted)] text-sm font-medium">
            Track your progress and stay motivated
          </p>
        </div>
        <Zap className="w-6 h-6 text-[var(--accent-primary)]" />
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-5">
        {statsConfig.map((stat) => (
          <PremiumStatCard key={stat.label} {...stat} loading={loading} />
        ))}
      </div>
    </div>
  );
}
