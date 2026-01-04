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
      whileHover={{ y: -4, scale: 1.02 }}
    >
      {/* Animated gradient background */}
      <div 
        className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl"
        style={{
          background: `linear-gradient(135deg, ${color}08, transparent 40%, ${color}08)`,
          opacity: 0.6,
        }}
      />
      <div 
        className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
        style={{
          background: `linear-gradient(135deg, ${color}20, transparent 50%, ${color}20)`,
          animation: 'gradient-shift 4s ease infinite',
          backgroundSize: '200% 200%',
        }}
      />
      
      {/* Animated glow effect on hover */}
      <div 
        className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
        style={{
          boxShadow: `0 0 60px ${color}25, 0 0 120px ${color}15`,
          animation: 'glow-pulse 3s ease-in-out infinite',
        }}
      />
      
      {/* Floating orb effect */}
      <div 
        className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
        style={{
          background: `radial-gradient(circle at 50% 50%, ${color}20, transparent 70%)`,
          animation: 'float-gradient 6s ease-in-out infinite',
        }}
      />
      
      <div className="relative z-10">
        <div className="flex items-start justify-between mb-4">
          <div 
            className="p-3 rounded-xl transition-all group-hover:scale-110 group-hover:rotate-3"
            style={{
              backgroundColor: `${color}15`,
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
              <motion.div 
                className="text-3xl md:text-4xl font-bold"
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: delay + 0.2, duration: 0.3 }}
              >
                {value}
              </motion.div>
              <div className="text-sm font-medium text-[var(--foreground-muted)] uppercase tracking-wide mt-1">
                {label}
              </div>
              {subtitle && (
                <div className="text-xs text-[var(--foreground-subtle)] mt-1.5">
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
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl md:text-3xl font-bold mb-2 flex items-center gap-2">
            <TrendingUp className="w-6 h-6 text-[var(--accent-primary)]" />
            Your Stats
          </h2>
        <p className="text-[var(--foreground-muted)]">
          Track your progress and stay motivated
        </p>
        </div>
      </div>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-6">
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

