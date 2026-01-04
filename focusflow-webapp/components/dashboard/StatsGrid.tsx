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
      className="card p-6 group transition-all relative overflow-hidden"
      style={{
        borderColor: `${color}20`
      }}
    >
      {/* Gradient overlay on hover - more prominent */}
      <div 
        className="absolute inset-0 transition-all duration-500 pointer-events-none rounded-2xl"
        style={{
          background: `linear-gradient(135deg, ${color}05, transparent 50%, ${color}05)`,
        }}
      />
      <div 
        className="absolute inset-0 transition-all duration-500 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
        style={{
          background: `linear-gradient(135deg, ${color}12, transparent 50%, ${color}12)`,
        }}
      />
      
      <div className="relative z-10">
        <div className="flex items-start justify-between mb-4">
          <div 
            className="p-3 rounded-xl border transition-all group-hover:scale-110"
            style={{
              backgroundColor: `${color}15`,
              borderColor: `${color}30`
            }}
          >
            <Icon 
              className="w-5 h-5" 
              style={{ 
                color: color,
                filter: 'brightness(1.2) contrast(1.1)'
              }} 
            />
          </div>
        </div>
        
        <div className="space-y-1">
          {loading ? (
            <>
              <div className="h-8 w-24 bg-[var(--background-subtle)] rounded animate-pulse mb-2" />
              <div className="h-4 w-32 bg-[var(--background-subtle)] rounded animate-pulse" />
            </>
          ) : (
            <>
              <div className="text-3xl font-bold">{value}</div>
              <div className="text-sm font-medium text-[var(--foreground-muted)] uppercase tracking-wide">
                {label}
              </div>
              {subtitle && (
                <div className="text-xs text-[var(--foreground-subtle)] mt-1">
                  {subtitle}
                </div>
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
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-2">Your Stats</h2>
        <p className="text-[var(--foreground-muted)]">
          Track your progress and stay motivated
        </p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
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

