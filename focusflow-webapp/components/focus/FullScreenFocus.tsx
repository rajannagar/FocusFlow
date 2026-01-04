'use client';

import { useEffect, useState } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import { Play, Pause, RotateCcw, X, Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import AmbientBackground, { type AmbientMode } from './AmbientBackground';

interface FullScreenFocusProps {
  isOpen: boolean;
  onClose: () => void;
}

export function FullScreenFocus({ isOpen, onClose }: FullScreenFocusProps) {
  const {
    phase,
    remainingSeconds,
    totalSeconds,
    sessionName,
    getFormattedTime,
    getProgress,
    setPhase,
    reset,
    tick,
  } = useTimerStore();

  const [ambientMode, setAmbientMode] = useState<AmbientMode>('ocean');
  const [showControls, setShowControls] = useState(true);

  const progress = getProgress();
  const isRunning = phase === 'running';
  const isPaused = phase === 'paused';
  const isIdle = phase === 'idle';
  const isCompleted = phase === 'completed';

  // Auto-tick when running
  useEffect(() => {
    if (isRunning && remainingSeconds > 0) {
      const interval = setInterval(() => {
        tick();
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [isRunning, remainingSeconds, tick]);

  // Hide controls after 3 seconds of inactivity
  useEffect(() => {
    if (!isOpen) return;

    let timeout: NodeJS.Timeout;
    if (isRunning) {
      timeout = setTimeout(() => setShowControls(false), 3000);
    } else {
      setShowControls(true);
    }

    return () => clearTimeout(timeout);
  }, [isOpen, isRunning]);

  // Handle keyboard shortcuts
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyPress = (e: KeyboardEvent) => {
      if (e.key === ' ') {
        e.preventDefault();
        if (isRunning) {
          setPhase('paused');
        } else if (isPaused) {
          setPhase('running');
        } else if (isIdle) {
          setPhase('running');
        }
      } else if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'r' || e.key === 'R') {
        reset();
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [isOpen, isRunning, isPaused, isIdle, setPhase, reset, onClose]);

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 flex items-center justify-center bg-[var(--background)]"
        onClick={() => setShowControls(!showControls)}
      >
        {/* Ambient Background */}
        <AmbientBackground mode={ambientMode} isActive={isRunning || isPaused} intensity={0.8} />

        {/* Floating Gradient Orbs */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: `
              radial-gradient(circle at 20% 30%, var(--accent-glow-subtle) 0%, transparent 40%),
              radial-gradient(circle at 80% 70%, var(--accent-secondary-glow) 0%, transparent 40%),
              radial-gradient(circle at 50% 50%, var(--accent-glow-subtle) 0%, transparent 60%)
            `,
            animation: 'float-gradient 12s ease-in-out infinite',
            opacity: 0.6,
          }}
        />

        {/* Grid Pattern Overlay */}
        <div className="absolute inset-0 bg-grid opacity-[0.03] pointer-events-none" />

        {/* Timer Display */}
        <div className="relative z-10 text-center">
          {/* Session Name */}
          {sessionName && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: showControls ? 1 : 0.3, y: 0 }}
              className="mb-8"
            >
              <div className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[var(--background-elevated)]/30 backdrop-blur-xl border border-[var(--border)]/30">
                <Sparkles className="w-5 h-5 text-[var(--accent-secondary)]" />
                <h2 className="text-2xl md:text-3xl font-semibold text-[var(--foreground)]">
                  {sessionName}
                </h2>
              </div>
            </motion.div>
          )}

          {/* Circular Progress with Glow */}
          <div className="relative w-80 h-80 md:w-96 md:h-96 lg:w-[28rem] lg:h-[28rem] mx-auto mb-12">
            {/* Glow behind the ring */}
            <div
              className="absolute inset-0 rounded-full pointer-events-none"
              style={{
                background: `var(--accent-gradient)`,
                opacity: 0.2,
                filter: 'blur(40px)',
                animation: 'glow-pulse 4s ease-in-out infinite',
                transform: 'scale(1.1)',
              }}
            />

            <svg className="w-full h-full transform -rotate-90 relative z-10" viewBox="0 0 100 100">
              {/* Background circle */}
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="var(--border)"
                strokeWidth="2"
                opacity="0.2"
              />
              {/* Progress circle */}
              <motion.circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="url(#fullscreenGradient)"
                strokeWidth="3"
                strokeLinecap="round"
                initial={{ pathLength: 0 }}
                animate={{ pathLength: progress }}
                transition={{ duration: 0.3, ease: 'easeOut' }}
              />
              <defs>
                <linearGradient id="fullscreenGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="var(--accent-primary)" />
                  <stop offset="100%" stopColor="var(--accent-secondary)" />
                </linearGradient>
              </defs>
            </svg>

            {/* Time Display */}
            <div className="absolute inset-0 flex items-center justify-center z-20">
              <motion.div
                key={remainingSeconds}
                initial={{ scale: 1.05 }}
                animate={{ scale: 1 }}
                className="text-center"
              >
                <div
                  className="text-7xl md:text-8xl lg:text-9xl font-bold tabular-nums font-mono"
                  style={{
                    background: `linear-gradient(135deg, var(--accent-primary), var(--accent-secondary), var(--accent-primary))`,
                    backgroundSize: '200% 100%',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    backgroundClip: 'text',
                    animation: 'gradient 3s ease infinite',
                    filter: 'brightness(1.15)',
                  }}
                >
                  {getFormattedTime()}
                </div>
                <motion.div
                  className="text-lg md:text-xl text-[var(--foreground-muted)] mt-4 font-medium"
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
          <AnimatePresence>
            {showControls && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 20 }}
                className="flex items-center justify-center gap-4"
                onClick={(e) => e.stopPropagation()}
              >
                {isIdle && (
                  <motion.button
                    onClick={() => setPhase('running')}
                    className="px-8 py-4 rounded-full font-semibold transition-all flex items-center gap-3 group"
                    style={{
                      background: 'var(--accent-gradient)',
                      backgroundSize: '200% 200%',
                      animation: 'gradient-shift 4s ease infinite',
                    }}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Play className="w-6 h-6 group-hover:scale-110 transition-transform" />
                    <span className="text-white">Start</span>
                  </motion.button>
                )}

                {isRunning && (
                  <>
                    <motion.button
                      onClick={() => setPhase('paused')}
                      className="px-8 py-4 bg-[var(--background-elevated)]/50 backdrop-blur-xl rounded-full font-semibold hover:bg-[var(--background-elevated)]/70 transition-all flex items-center gap-3 border border-[var(--border)]/30"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Pause className="w-6 h-6" />
                      Pause
                    </motion.button>
                    <motion.button
                      onClick={reset}
                      className="p-4 bg-[var(--background-elevated)]/30 backdrop-blur-xl rounded-full text-[var(--foreground-muted)] hover:bg-[var(--background-elevated)]/50 transition-all border border-[var(--border)]/20"
                      whileHover={{ scale: 1.1, rotate: -180 }}
                      whileTap={{ scale: 0.9 }}
                    >
                      <RotateCcw className="w-5 h-5" />
                    </motion.button>
                  </>
                )}

                {isPaused && (
                  <>
                    <motion.button
                      onClick={() => setPhase('running')}
                      className="px-8 py-4 rounded-full font-semibold transition-all flex items-center gap-3 group"
                      style={{
                        background: 'var(--accent-gradient)',
                        backgroundSize: '200% 200%',
                        animation: 'gradient-shift 4s ease infinite',
                      }}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Play className="w-6 h-6 group-hover:scale-110 transition-transform" />
                      <span className="text-white">Resume</span>
                    </motion.button>
                    <motion.button
                      onClick={reset}
                      className="p-4 bg-[var(--background-elevated)]/30 backdrop-blur-xl rounded-full text-[var(--foreground-muted)] hover:bg-[var(--background-elevated)]/50 transition-all border border-[var(--border)]/20"
                      whileHover={{ scale: 1.1, rotate: -180 }}
                      whileTap={{ scale: 0.9 }}
                    >
                      <RotateCcw className="w-5 h-5" />
                    </motion.button>
                  </>
                )}

                {isCompleted && (
                  <motion.button
                    onClick={reset}
                    className="px-8 py-4 rounded-full font-semibold transition-all flex items-center gap-3 group"
                    style={{
                      background: 'var(--accent-gradient)',
                      backgroundSize: '200% 200%',
                      animation: 'gradient-shift 4s ease infinite',
                    }}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <RotateCcw className="w-6 h-6 group-hover:rotate-[-360deg] transition-transform duration-500" />
                    <span className="text-white">New Session</span>
                  </motion.button>
                )}

                <motion.button
                  onClick={onClose}
                  className="p-4 bg-[var(--background-elevated)]/30 backdrop-blur-xl rounded-full text-[var(--foreground-muted)] hover:bg-[var(--background-elevated)]/50 transition-all border border-[var(--border)]/20"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                >
                  <X className="w-5 h-5" />
                </motion.button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Keyboard Shortcuts Hint */}
          {showControls && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="mt-8 text-[var(--foreground-subtle)] text-sm"
            >
              <div className="inline-flex items-center gap-4 px-4 py-2 rounded-full bg-[var(--background-elevated)]/20 backdrop-blur-sm border border-[var(--border)]/20">
                <span>
                  <kbd className="px-2 py-1 rounded bg-[var(--background-elevated)]/50 text-xs mr-1">
                    Space
                  </kbd>
                  {isRunning ? 'Pause' : 'Start'}
                </span>
                <span className="text-[var(--border)]">|</span>
                <span>
                  <kbd className="px-2 py-1 rounded bg-[var(--background-elevated)]/50 text-xs mr-1">
                    Esc
                  </kbd>
                  Exit
                </span>
                <span className="text-[var(--border)]">|</span>
                <span>
                  <kbd className="px-2 py-1 rounded bg-[var(--background-elevated)]/50 text-xs mr-1">
                    R
                  </kbd>
                  Reset
                </span>
              </div>
            </motion.div>
          )}
        </div>
      </motion.div>
    </AnimatePresence>
  );
}
