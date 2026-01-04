'use client';

import { useEffect, useState } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import { Button } from '@/components/common/Button';
import { Play, Pause, RotateCcw, Settings, Maximize2, Sparkles } from 'lucide-react';
import { formatTime } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { PremiumTimerOrb } from '@/components/ui/PremiumTimerOrb';
import { AmbientBackground, type AmbientMode } from '@/components/ui/AmbientBackground';
import { GlassCard } from '@/components/ui/GlassCard';

const AMBIENT_MODES: AmbientMode[] = [
  'minimal',
  'aurora',
  'stars',
  'gradient-flow',
  'rain',
  'ocean',
  'forest',
];

export function PremiumDashboardHero() {
  console.log('🎉 PREMIUM DASHBOARD HERO LOADED!');
  const { phase, remainingSeconds, totalSeconds, getFormattedTime, setPhase, reset, tick } = useTimerStore();
  const router = useRouter();
  const [ambientMode, setAmbientMode] = useState<AmbientMode>('aurora');

  // Auto-tick when running
  useEffect(() => {
    if (phase === 'running') {
      const interval = setInterval(() => {
        tick();
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [phase, tick]);

  const progress = totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;
  const isRunning = phase === 'running';
  const isPaused = phase === 'paused';
  const isIdle = phase === 'idle';
  const isCompleted = phase === 'completed';

  const handleStart = () => {
    if (isIdle) {
      const currentTotal = useTimerStore.getState().totalSeconds;
      if (currentTotal === 0) {
        useTimerStore.setState({ totalSeconds: 25 * 60, remainingSeconds: 25 * 60 });
      }
    }
    setPhase('running');
  };

  const handlePause = () => setPhase('paused');
  const handleResume = () => setPhase('running');
  const handleReset = () => reset();
  const handleFullScreen = () => router.push('/focus');

  const statusText = isIdle ? 'Ready to focus' : isRunning ? 'Focusing...' : isPaused ? 'Paused' : 'Session complete!';

  return (
    <div className="relative">
      {/* Ambient Background */}
      <div className="absolute inset-0 -mx-6 lg:-mx-8 -mt-8 rounded-3xl overflow-hidden pointer-events-none">
        <AmbientBackground mode={ambientMode} intensity={0.6} />
      </div>

      {/* Main Timer Card */}
      <GlassCard
        variant="elevated"
        glow={isRunning}
        className="p-8 md:p-12 lg:p-16 relative overflow-hidden"
        style={{
          borderColor: 'var(--accent-primary)20',
          boxShadow: isRunning
            ? '0 0 80px rgba(139, 92, 246, 0.15), 0 8px 32px rgba(0, 0, 0, 0.2)'
            : '0 8px 32px rgba(0, 0, 0, 0.15)',
        }}
      >
        <div className="relative z-10">
          <div className="flex flex-col lg:flex-row items-center lg:items-start gap-8 lg:gap-12">
            {/* Timer Orb - Center/Left */}
            <div className="flex-1 flex flex-col items-center lg:items-start">
              <PremiumTimerOrb
                progress={progress}
                timeDisplay={getFormattedTime()}
                status={statusText}
                isRunning={isRunning}
                size="xl"
              />

              {/* Controls */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="flex items-center gap-3 flex-wrap justify-center lg:justify-start mt-8"
              >
                {isIdle && (
                  <Button
                    variant="accent"
                    size="lg"
                    onClick={handleStart}
                    className="px-10 text-lg group"
                  >
                    <Play className="w-5 h-5 group-hover:scale-110 transition-transform" />
                    Start Focus Session
                  </Button>
                )}

                {isRunning && (
                  <>
                    <Button
                      variant="secondary"
                      size="lg"
                      onClick={handlePause}
                      className="px-8"
                    >
                      <Pause className="w-5 h-5" />
                      Pause
                    </Button>
                    <Button
                      variant="ghost"
                      size="lg"
                      onClick={handleReset}
                    >
                      <RotateCcw className="w-5 h-5" />
                      Reset
                    </Button>
                  </>
                )}

                {isPaused && (
                  <>
                    <Button
                      variant="accent"
                      size="lg"
                      onClick={handleResume}
                      className="px-8"
                    >
                      <Play className="w-5 h-5" />
                      Resume
                    </Button>
                    <Button
                      variant="ghost"
                      size="lg"
                      onClick={handleReset}
                    >
                      <RotateCcw className="w-5 h-5" />
                      Reset
                    </Button>
                  </>
                )}

                {isCompleted && (
                  <Button
                    variant="accent"
                    size="lg"
                    onClick={handleReset}
                    className="px-10"
                  >
                    <RotateCcw className="w-5 h-5" />
                    Start New Session
                  </Button>
                )}
              </motion.div>
            </div>

            {/* Right Side - Quick Actions & Ambient Selector */}
            <div className="w-full lg:w-auto lg:min-w-[320px] space-y-4">
              {/* Full Screen Mode */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.1 }}
              >
                <GlassCard
                  variant="subtle"
                  className="p-4 cursor-pointer group"
                  onClick={handleFullScreen}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <div className="flex items-center gap-3">
                    <div
                      className="p-2.5 rounded-xl border transition-all duration-300 group-hover:scale-110"
                      style={{
                        background: 'linear-gradient(135deg, var(--accent-primary)25, var(--accent-secondary)15)',
                        borderColor: 'var(--accent-primary)40',
                      }}
                    >
                      <Maximize2
                        className="w-5 h-5"
                        style={{ color: 'var(--accent-primary)' }}
                      />
                    </div>
                    <div className="flex-1">
                      <div className="font-semibold text-sm">Immersive Mode</div>
                      <div className="text-xs text-[var(--foreground-muted)]">Full screen focus</div>
                    </div>
                  </div>
                </GlassCard>
              </motion.div>

              {/* Configure Timer */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.2 }}
              >
                <Link href="/focus">
                  <GlassCard
                    variant="subtle"
                    className="p-4 cursor-pointer group"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="p-2.5 rounded-xl border transition-all duration-300 group-hover:scale-110"
                        style={{
                          background: 'linear-gradient(135deg, var(--accent-primary)20, var(--accent-secondary)10)',
                          borderColor: 'var(--accent-primary)30',
                        }}
                      >
                        <Settings
                          className="w-5 h-5"
                          style={{ color: 'var(--accent-primary)' }}
                        />
                      </div>
                      <div className="flex-1">
                        <div className="font-semibold text-sm">Configure</div>
                        <div className="text-xs text-[var(--foreground-muted)]">Presets & settings</div>
                      </div>
                    </div>
                  </GlassCard>
                </Link>
              </motion.div>

              {/* Ambient Mode Selector */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.3 }}
              >
                <GlassCard variant="subtle" className="p-4">
                  <div className="flex items-center gap-2 mb-3">
                    <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" />
                    <span className="text-xs font-semibold text-[var(--foreground-muted)] uppercase tracking-wider">
                      Ambient
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-2">
                    {AMBIENT_MODES.slice(0, 6).map((mode) => (
                      <button
                        key={mode}
                        onClick={() => setAmbientMode(mode)}
                        className={`
                          px-3 py-2 rounded-lg text-xs font-medium transition-all duration-300
                          ${ambientMode === mode
                            ? 'bg-[var(--accent-primary)] text-white shadow-lg shadow-[var(--accent-primary)]30'
                            : 'bg-[var(--background-subtle)] text-[var(--foreground-muted)] hover:bg-[var(--background-muted)]'
                          }
                        `}
                      >
                        {mode.charAt(0).toUpperCase() + mode.slice(1).replace('-', ' ')}
                      </button>
                    ))}
                  </div>
                </GlassCard>
              </motion.div>

              {/* Session Info */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.4 }}
              >
                <GlassCard variant="subtle" className="p-4">
                  <div className="text-xs font-semibold text-[var(--foreground-muted)] uppercase tracking-wider mb-3">
                    Session Info
                  </div>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between items-center">
                      <span className="text-[var(--foreground-muted)]">Duration</span>
                      <span className="font-semibold">
                        {totalSeconds > 0 ? formatTime(totalSeconds) : 'Not set'}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-[var(--foreground-muted)]">Progress</span>
                      <span className="font-semibold">
                        {Math.round(progress * 100)}%
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-[var(--foreground-muted)]">Status</span>
                      <span
                        className="font-semibold px-2 py-0.5 rounded text-xs"
                        style={{
                          background: isRunning
                            ? 'rgba(34, 197, 94, 0.2)'
                            : isPaused
                            ? 'rgba(251, 146, 60, 0.2)'
                            : 'rgba(139, 92, 246, 0.2)',
                          color: isRunning
                            ? '#22C55E'
                            : isPaused
                            ? '#FB923C'
                            : 'var(--accent-primary)',
                        }}
                      >
                        {statusText}
                      </span>
                    </div>
                  </div>
                </GlassCard>
              </motion.div>
            </div>
          </div>
        </div>
      </GlassCard>
    </div>
  );
}
