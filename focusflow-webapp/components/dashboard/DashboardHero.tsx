'use client';

import { useEffect } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import { Button } from '@/components/common/Button';
import { Play, Pause, RotateCcw, Settings, Maximize2 } from 'lucide-react';
import { formatTime } from '@/lib/utils';
import { motion } from 'framer-motion';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export function DashboardHero() {
  const { phase, remainingSeconds, totalSeconds, getFormattedTime, setPhase, reset, tick } = useTimerStore();
  const router = useRouter();
  
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

  return (
    <div className="relative">
      {/* Main Timer Card */}
      <div 
        className="card p-8 md:p-12 lg:p-16 relative overflow-hidden transition-all duration-500"
        style={{
          borderColor: `var(--accent-primary)30`,
          background: `linear-gradient(135deg, var(--background-elevated), var(--background-elevated))`,
          boxShadow: `
            0 0 0 1px var(--accent-primary)20,
            0 8px 32px rgba(0, 0, 0, 0.12),
            0 0 80px var(--accent-primary)08
          `
        }}
      >
        {/* Gradient Overlay - More prominent theme colors */}
        <div 
          className="absolute inset-0 pointer-events-none transition-opacity duration-500"
          style={{
            background: `linear-gradient(135deg, var(--accent-primary)12, transparent 40%, var(--accent-secondary)12)`,
          }}
        />
        
        {/* Theme-colored border glow */}
        <div 
          className="absolute inset-0 rounded-2xl pointer-events-none"
          style={{
            boxShadow: `inset 0 0 0 1px var(--accent-primary)25`,
          }}
        />
        
        {/* Grid Pattern Overlay */}
        <div className="absolute inset-0 bg-grid opacity-[0.03] pointer-events-none" />
        
        <div className="relative z-10">
          <div className="flex flex-col lg:flex-row items-center lg:items-start gap-8 lg:gap-12">
            {/* Timer Display - Left Side */}
            <div className="flex-1 flex flex-col items-center lg:items-start">
              <div className="relative mb-8">
                {/* Progress Ring */}
                <svg className="w-64 h-64 md:w-80 md:h-80 lg:w-96 lg:h-96 transform -rotate-90" viewBox="0 0 100 100">
                  {/* Background circle */}
                  <circle
                    cx="50"
                    cy="50"
                    r="45"
                    fill="none"
                    stroke="var(--border)"
                    strokeWidth="3"
                    opacity="0.3"
                  />
                  {/* Progress circle */}
                  <motion.circle
                    cx="50"
                    cy="50"
                    r="45"
                    fill="none"
                    stroke="url(#timerGradient)"
                    strokeWidth="4"
                    strokeLinecap="round"
                    initial={{ pathLength: 0 }}
                    animate={{ pathLength: progress }}
                    transition={{ duration: 0.3, ease: "easeOut" }}
                  />
                  <defs>
                    <linearGradient id="timerGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor="var(--accent-primary)" />
                      <stop offset="100%" stopColor="var(--accent-secondary)" />
                    </linearGradient>
                  </defs>
                </svg>
                
                {/* Time Text */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <motion.div
                    key={remainingSeconds}
                    initial={{ scale: 1.1, opacity: 0.8 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.2 }}
                    className="text-center"
                  >
                    <div 
                      className="text-6xl md:text-7xl lg:text-8xl font-bold tabular-nums"
                      style={{
                        background: `linear-gradient(135deg, var(--accent-primary), var(--accent-secondary), var(--accent-primary))`,
                        backgroundSize: '200% 100%',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        backgroundClip: 'text',
                        animation: 'gradient 3s ease infinite',
                        filter: 'brightness(1.1)'
                      }}
                    >
                      {getFormattedTime()}
                    </div>
                    <motion.div 
                      className="text-sm md:text-base text-[var(--foreground-muted)] mt-3 font-medium"
                      animate={{ opacity: isRunning ? [1, 0.5, 1] : 1 }}
                      transition={{ duration: 2, repeat: isRunning ? Infinity : 0 }}
                    >
                      {isIdle && 'Ready to focus'}
                      {isRunning && 'Focusing...'}
                      {isPaused && 'Paused'}
                      {isCompleted && 'Session complete!'}
                    </motion.div>
                  </motion.div>
                </div>
              </div>

              {/* Controls */}
              <div className="flex items-center gap-3 flex-wrap justify-center lg:justify-start">
                {isIdle && (
                  <Button
                    variant="accent"
                    size="lg"
                    onClick={handleStart}
                    className="px-8 group"
                  >
                    <Play className="w-5 h-5 group-hover:scale-110 transition-transform" />
                    Start Focus
                  </Button>
                )}
                
                {isRunning && (
                  <>
                    <Button
                      variant="secondary"
                      size="lg"
                      onClick={handlePause}
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
                    className="px-8"
                  >
                    <RotateCcw className="w-5 h-5" />
                    Start New Session
                  </Button>
                )}
              </div>
            </div>

            {/* Right Side - Quick Actions & Info */}
            <div className="w-full lg:w-auto lg:min-w-[280px] space-y-4">
              {/* Full Screen Button */}
              <button
                onClick={handleFullScreen}
                className="w-full lg:w-auto card p-4 transition-all group"
                style={{
                  borderColor: 'var(--accent-primary)20'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = 'var(--accent-primary)40';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = 'var(--accent-primary)20';
                }}
              >
                <div className="flex items-center gap-3">
                  <div 
                    className="p-2 rounded-xl border group-hover:scale-110 transition-transform"
                    style={{
                      background: `linear-gradient(135deg, var(--accent-primary)25, var(--accent-secondary)25)`,
                      borderColor: `var(--accent-primary)40`
                    }}
                  >
                    <Maximize2 
                      className="w-5 h-5" 
                      style={{ 
                        color: 'var(--accent-primary)',
                        filter: 'brightness(1.15) saturate(1.2)'
                      }} 
                    />
                  </div>
                  <div className="flex-1 text-left">
                    <div className="font-semibold text-sm">Full Screen Mode</div>
                    <div className="text-xs text-[var(--foreground-muted)]">Immersive focus</div>
                  </div>
                </div>
              </button>

              {/* Configure Timer */}
              <Link
                href="/focus"
                className="w-full lg:w-auto card p-4 transition-all group block"
                style={{
                  borderColor: 'var(--accent-primary)20'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = 'var(--accent-primary)40';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = 'var(--accent-primary)20';
                }}
              >
                <div className="flex items-center gap-3">
                  <div 
                    className="p-2 rounded-xl border group-hover:scale-110 transition-transform"
                    style={{
                      background: `linear-gradient(135deg, var(--accent-primary)20, var(--accent-secondary)20)`,
                      borderColor: `var(--accent-primary)30`
                    }}
                  >
                    <Settings 
                      className="w-5 h-5" 
                      style={{ 
                        color: 'var(--accent-primary)',
                        filter: 'brightness(1.1)'
                      }} 
                    />
                  </div>
                  <div className="flex-1 text-left">
                    <div className="font-semibold text-sm">Configure Timer</div>
                    <div className="text-xs text-[var(--foreground-muted)]">Set presets & ambient</div>
                  </div>
                </div>
              </Link>

              {/* Timer Info */}
              <div 
                className="card p-4 transition-all"
                style={{
                  backgroundColor: 'var(--background-subtle)',
                  borderColor: 'var(--accent-primary)15'
                }}
              >
                <div className="text-xs font-medium text-[var(--foreground-muted)] uppercase tracking-wider mb-2">
                  Session Info
                </div>
                <div className="space-y-1.5 text-sm">
                  <div className="flex justify-between">
                    <span className="text-[var(--foreground-muted)]">Duration</span>
                    <span className="font-medium">
                      {totalSeconds > 0 ? formatTime(totalSeconds) : 'Not set'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[var(--foreground-muted)]">Progress</span>
                    <span className="font-medium">
                      {Math.round(progress * 100)}%
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

