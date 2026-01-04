'use client';

import { Timer, TrendingUp, Flame, Award, CheckSquare, Target, Calendar, Clock } from 'lucide-react';
import { formatDuration } from '@/lib/utils';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface StatsGridProps {
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

const StatCard = ({ 
  icon: Icon, 
  label, 
  value, 
  subtitle, 
  color, 
  delay = 0,
  loading = false 
}: { 
  icon: any;
  label: string;
  value: string | number;
  subtitle?: string;
  color: string;
  delay?: number;
  loading?: boolean;
}) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
      className="group relative p-6 md:p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500 hover:shadow-xl hover:shadow-[var(--accent-primary)]/10"
      whileHover={{ y: -4, scale: 1.01 }}
    >
      {/* Subtle gradient background on hover - matching main site */}
      <div 
        className="absolute inset-0 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
        style={{
          background: `linear-gradient(135deg, ${color}08, transparent 50%)`,
        }}
      />
      
      <div className="relative z-10">
        {/* Icon - Premium style matching main site */}
        <div className="w-16 h-16 md:w-20 md:h-20 rounded-2xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg">
          <Icon 
            className="w-8 h-8 md:w-10 md:h-10 text-[var(--accent-primary)]" 
            strokeWidth={1.5}
          />
        </div>
        
        {/* Content */}
        <div className="space-y-2">
          {loading ? (
            <>
              <div className="h-10 w-32 bg-[var(--background-subtle)] rounded animate-pulse mb-2" />
              <div className="h-4 w-24 bg-[var(--background-subtle)] rounded animate-pulse" />
            </>
          ) : (
            <>
              <motion.div 
                className="text-3xl md:text-4xl font-bold text-[var(--foreground)]"
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: delay + 0.2, duration: 0.3 }}
              >
                {value}
              </motion.div>
              <h3 className="text-lg md:text-xl font-semibold text-[var(--foreground)]">
                {label}
              </h3>
              {subtitle && (
                <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">
                  {subtitle}
                </p>
              )}
            </>
          )}
        </div>
      </div>
    </motion.div>
  );
};

export function StatsGrid({ stats, loading }: StatsGridProps) {
  const statsConfig = [
    {
      icon: Timer,
      label: 'Today',
      value: formatDuration(stats.todayFocusTime),
      subtitle: `${stats.todaySessions} session${stats.todaySessions !== 1 ? 's' : ''}`,
      color: 'var(--accent-primary)',
      delay: 0,
    },
    {
      icon: Calendar,
      label: 'This Week',
      value: formatDuration(stats.weeklyFocusTime),
      subtitle: `${stats.weeklySessions} session${stats.weeklySessions !== 1 ? 's' : ''}`,
      color: 'var(--accent-secondary)',
      delay: 0.1,
    },
    {
      icon: Flame,
      label: 'Streak',
      value: `${stats.currentStreak}`,
      subtitle: 'days in a row',
      color: '#F97316',
      delay: 0.2,
    },
    {
      icon: Award,
      label: 'Level',
      value: `${stats.currentLevel}`,
      subtitle: `${stats.totalXp.toLocaleString()} XP`,
      color: '#EAB308',
      delay: 0.3,
    },
    {
      icon: Clock,
      label: 'Total Time',
      value: formatDuration(stats.totalFocusTime),
      subtitle: `${stats.totalSessions} total sessions`,
      color: 'var(--accent-primary)',
      delay: 0.4,
    },
    {
      icon: CheckSquare,
      label: 'Tasks',
      value: `${stats.activeTasks}`,
      subtitle: `${stats.totalTasks} total`,
      color: 'var(--accent-secondary)',
      delay: 0.5,
    },
  ];

  return (
    <div>
      {/* Header - Matching main site style */}
      <div className="mb-8 md:mb-12">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
          <TrendingUp className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
          <span>Your Progress</span>
        </div>
        <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 leading-tight">
          Track your <span className="text-gradient">focus journey</span>
        </h2>
        <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-2xl">
          See how your focus sessions add up over time. Every moment counts.
        </p>
      </div>
      
      {/* Stats Grid - Premium Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
        {statsConfig.map((stat, index) => (
          <StatCard
            key={stat.label}
            {...stat}
            loading={loading}
          />
        ))}
      </div>
    </div>
  );
}

