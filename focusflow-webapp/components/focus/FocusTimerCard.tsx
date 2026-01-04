'use client';

import { useEffect } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import AmbientBackground, { type AmbientMode } from './AmbientBackground';
import { Play, Pause, RotateCcw, Clock } from 'lucide-react';
import { motion } from 'framer-motion';
import { Button } from '@/components/common/Button';

interface FocusTimerCardProps {
  ambientMode: AmbientMode;
  onAmbientModeChange: (mode: AmbientMode) => void;
  selectedSound: string | null;
  onSoundChange: (sound: string | null) => void;
  sessionName: string;
  onSessionNameChange: (name: string) => void;
  onLengthClick: () => void;
  onReset: () => void;
}

export function FocusTimerCard({
  ambientMode,
  onAmbientModeChange,
  selectedSound,
  onSoundChange,
  sessionName,
  onSessionNameChange,
  onLengthClick,
  onReset,
}: FocusTimerCardProps) {
  const {
    phase,
    remainingSeconds,
    totalSeconds,
    getFormattedTime,
    getProgress,
    setPhase,
    tick,
  } = useTimerStore();

  const isRunning = phase === 'running';
  const isPaused = phase === 'paused';
  const isIdle = phase === 'idle';
  const isCompleted = phase === 'completed';

  // Auto-tick when running
  useEffect(() => {
    if (isRunning) {
      const interval = setInterval(() => {
        tick();
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [isRunning, tick]);

  const progress = getProgress();
  const formattedTime = getFormattedTime();
  const totalMinutes = Math.floor(totalSeconds / 60);

  const handleStart = () => {
    if (isIdle || isCompleted) {
      setPhase('running');
    } else if (isPaused) {
      setPhase('running');
    }
  };

  const handlePause = () => {
    if (isRunning) {
      setPhase('paused');
    }
  };

  const handleReset = () => {
    onReset();
  };

  // Show ambient background only when timer is active
  const showAmbient = isRunning || isPaused;

  return (
    <div className="relative">
      {/* Timer Card with Ambient Background */}
      <div className="relative p-8 md:p-12 lg:p-16 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] overflow-hidden">
        {/* Ambient Background - Only on timer card */}
        {showAmbient && (
          <div className="absolute inset-0 pointer-events-none">
            <AmbientBackground 
              mode={ambientMode} 
              isActive={showAmbient}
              intensity={0.15}
            />
          </div>
        )}

        {/* Subtle gradient overlay when ambient is active */}
        {showAmbient && (
          <div 
            className="absolute inset-0 pointer-events-none"
            style={{
              background: `var(--accent-gradient)`,
              opacity: 0.05,
            }}
          />
        )}

        {/* Grid Pattern Overlay */}
        <div className="absolute inset-0 bg-grid opacity-[0.02] pointer-events-none" />

        {/* Content */}
        <div className="relative z-10">
          {/* Timer Display - Similar to Dashboard Hero */}
          <div className="flex flex-col items-center mb-8">
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
                <div className="text-center">
                  <div 
                    className="text-6xl md:text-7xl lg:text-8xl font-bold tabular-nums"
                    style={{
                      color: 'var(--foreground)',
                      textShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
                    }}
                  >
                    {formattedTime}
                  </div>
                  <div 
                    className="text-sm md:text-base font-medium mt-3"
                    style={{
                      color: 'var(--foreground)',
                      textShadow: '0 1px 4px rgba(0, 0, 0, 0.1)',
                    }}
                  >
                    {isIdle && 'Ready to focus'}
                    {isRunning && 'Focusing...'}
                    {isPaused && 'Paused'}
                    {isCompleted && 'Session complete!'}
                  </div>
                  <div className="text-xs text-[var(--foreground-muted)] mt-2">
                    {totalMinutes}-minute session
                  </div>
                </div>
              </div>
            </div>

            {/* Controls */}
            <div className="flex items-center gap-3 flex-wrap justify-center">
              {isIdle && (
                <Button
                  variant="accent"
                  size="lg"
                  onClick={handleStart}
                  className="px-8"
                >
                  <Play className="w-5 h-5" />
                  Start
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
                    onClick={handleStart}
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
                  onClick={handleStart}
                  className="px-8"
                >
                  <Play className="w-5 h-5" />
                  Start again
                </Button>
              )}

              {/* Length Button */}
              {(isIdle || isPaused || isCompleted) && (
                <Button
                  variant="ghost"
                  size="lg"
                  onClick={onLengthClick}
                >
                  <Clock className="w-5 h-5" />
                  Length
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

