'use client';

import { motion } from 'framer-motion';
import { Award, TrendingUp, Zap } from 'lucide-react';
import { GlassCard } from '@/components/ui/GlassCard';

interface XPLevelDisplayProps {
  currentLevel: number;
  totalXp: number;
  xpPerLevel?: number;
  className?: string;
}

export function XPLevelDisplay({
  currentLevel,
  totalXp,
  xpPerLevel = 1000,
  className = ''
}: XPLevelDisplayProps) {
  const currentLevelXp = totalXp % xpPerLevel;
  const xpProgress = (currentLevelXp / xpPerLevel) * 100;
  const xpToNextLevel = xpPerLevel - currentLevelXp;

  return (
    <GlassCard
      variant="glow"
      className={`p-6 md:p-8 relative overflow-hidden ${className}`}
    >
      {/* Animated background gradient */}
      <div
        className="absolute inset-0 opacity-30"
        style={{
          background: `
            radial-gradient(circle at 20% 50%, rgba(234, 179, 8, 0.15) 0%, transparent 60%),
            radial-gradient(circle at 80% 50%, rgba(139, 92, 246, 0.15) 0%, transparent 60%)
          `,
        }}
      />

      <div className="relative z-10">
        <div className="flex items-start justify-between mb-6">
          {/* Header */}
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Award className="w-5 h-5 text-[#EAB308]" />
              <span className="text-sm font-semibold text-[var(--foreground-muted)] uppercase tracking-wider">
                Your Level
              </span>
            </div>
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="flex items-baseline gap-2"
            >
              <span
                className="text-6xl font-bold"
                style={{
                  background: 'linear-gradient(135deg, #EAB308 0%, #F59E0B 100%)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  filter: 'brightness(1.2)',
                }}
              >
                {currentLevel}
              </span>
              <span className="text-2xl text-[var(--foreground-muted)] font-semibold">
                / 50
              </span>
            </motion.div>
          </div>

          {/* XP Badge */}
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ duration: 0.6, delay: 0.2, type: 'spring', bounce: 0.5 }}
            className="flex flex-col items-center gap-1 px-4 py-2 rounded-xl border"
            style={{
              background: 'linear-gradient(135deg, rgba(234, 179, 8, 0.2), rgba(245, 158, 11, 0.1))',
              borderColor: 'rgba(234, 179, 8, 0.4)',
              boxShadow: '0 4px 12px rgba(234, 179, 8, 0.2)',
            }}
          >
            <Zap className="w-5 h-5 text-[#EAB308]" />
            <span className="text-lg font-bold text-[#EAB308]">
              {totalXp.toLocaleString()}
            </span>
            <span className="text-[10px] text-[var(--foreground-subtle)] uppercase tracking-wider font-semibold">
              Total XP
            </span>
          </motion.div>
        </div>

        {/* Progress Bar */}
        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm">
            <span className="text-[var(--foreground-muted)] font-medium">
              Level Progress
            </span>
            <span className="text-[var(--foreground)] font-semibold">
              {currentLevelXp.toLocaleString()} / {xpPerLevel.toLocaleString()} XP
            </span>
          </div>

          {/* Progress bar container */}
          <div className="relative h-3 bg-[var(--background-subtle)] rounded-full overflow-hidden border border-[var(--border)]">
            {/* Progress fill */}
            <motion.div
              className="absolute inset-y-0 left-0 rounded-full"
              style={{
                background: 'linear-gradient(90deg, #EAB308 0%, #F59E0B 50%, #EAB308 100%)',
                backgroundSize: '200% 100%',
                boxShadow: '0 0 12px rgba(234, 179, 8, 0.5)',
              }}
              initial={{ width: '0%' }}
              animate={{
                width: `${xpProgress}%`,
                backgroundPosition: ['0% 50%', '100% 50%', '0% 50%'],
              }}
              transition={{
                width: { duration: 1, delay: 0.3, ease: 'easeOut' },
                backgroundPosition: {
                  duration: 3,
                  repeat: Infinity,
                  ease: 'linear',
                },
              }}
            />

            {/* Shimmer effect */}
            <div
              className="absolute inset-0 opacity-50"
              style={{
                background: 'linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%)',
                backgroundSize: '200% 100%',
                animation: 'shimmer 2s infinite',
              }}
            />
          </div>

          {/* XP to next level */}
          <div className="flex items-center gap-2 text-xs text-[var(--foreground-subtle)]">
            <TrendingUp className="w-3.5 h-3.5 text-[#EAB308]" />
            <span className="font-medium">
              {xpToNextLevel.toLocaleString()} XP until Level {currentLevel + 1}
            </span>
          </div>
        </div>

        {/* Decorative elements */}
        <div className="absolute top-4 right-20 w-20 h-20 rounded-full bg-[#EAB308] opacity-5 blur-2xl" />
        <div className="absolute bottom-4 left-10 w-16 h-16 rounded-full bg-[#F59E0B] opacity-5 blur-2xl" />
      </div>

      {/* Top accent line */}
      <div
        className="absolute top-0 left-0 right-0 h-[1px]"
        style={{
          background: 'linear-gradient(90deg, transparent, rgba(234, 179, 8, 0.5), transparent)',
        }}
      />
    </GlassCard>
  );
}
