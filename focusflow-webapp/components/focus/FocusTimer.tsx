'use client';

import { useEffect, useState } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import { usePresetsStore } from '@/stores/usePresetsStore';
import { useSessions } from '@/hooks/supabase/useSessions';
import { useAuthStore } from '@/stores/useAuthStore';
import AmbientBackground, { type AmbientMode } from './AmbientBackground';
import { Play, Pause, RotateCcw, Settings } from 'lucide-react';
import { motion } from 'framer-motion';

export default function FocusTimer() {
  const {
    phase,
    totalSeconds,
    remainingSeconds,
    sessionName,
    startDate,
    setPhase,
    setTotalSeconds,
    setRemainingSeconds,
    setSessionName,
    setStartDate,
    tick,
    reset,
    getProgress,
    getFormattedTime,
  } = useTimerStore();

  const { presets, selectedPresetId, setSelectedPresetId } = usePresetsStore();
  const { user } = useAuthStore();
  const { addSession } = useSessions(user?.id);
  const [isInitialized, setIsInitialized] = useState(false);
  const [hasCompleted, setHasCompleted] = useState(false);
  const [ambientMode, setAmbientMode] = useState<AmbientMode>('none' as AmbientMode);

  // Timer tick effect
  useEffect(() => {
    if (phase === 'running' && remainingSeconds > 0) {
      const interval = setInterval(() => {
        tick();
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [phase, remainingSeconds, tick]);

  // Handle session completion
  useEffect(() => {
    if (phase === 'completed' && remainingSeconds === 0 && totalSeconds > 0 && !hasCompleted) {
      setHasCompleted(true);
      handleSessionComplete();
    }
  }, [phase, remainingSeconds, totalSeconds, hasCompleted]);

  // Initialize timer on mount
  useEffect(() => {
    if (!isInitialized && selectedPresetId) {
      const preset = presets.find((p) => p.id === selectedPresetId);
      if (preset) {
        setTotalSeconds(preset.durationSeconds);
        setSessionName(preset.name);
        setIsInitialized(true);
      }
    }
  }, [selectedPresetId, presets, isInitialized, setTotalSeconds, setSessionName]);

  const handleStart = () => {
    if (phase === 'idle' || phase === 'completed') {
      setPhase('running');
      setStartDate(new Date());
      setHasCompleted(false);
      // Activate ambient background when starting (if none selected, default to ocean)
      const currentMode: AmbientMode = ambientMode;
      if (currentMode === 'none') {
        setAmbientMode('ocean');
      }
    } else if (phase === 'paused') {
      setPhase('running');
    }
  };

  const handlePause = () => {
    if (phase === 'running') {
      setPhase('paused');
    }
  };

  const handleReset = () => {
    reset();
    setPhase('idle');
    setStartDate(undefined);
    setHasCompleted(false);
    setAmbientMode('none');
  };

  const handleSessionComplete = async () => {
    if (!user || hasCompleted) return;

    const duration = totalSeconds; // Total duration since we started
    if (duration < 60) return; // Don't save sessions less than 1 minute

    try {
      // Use stored start date or calculate from now
      const startTime = startDate || new Date(Date.now() - duration * 1000);
      
      await addSession({
        userId: user.id,
        startedAt: startTime.toISOString(),
        durationSeconds: duration,
        sessionName: sessionName || 'Focus Session',
      });
      
      setHasCompleted(true);
    } catch (error) {
      console.error('Failed to save session:', error);
    }
  };

  const handlePresetSelect = (presetId: string) => {
    const preset = presets.find((p) => p.id === presetId);
    if (preset && phase === 'idle') {
      setSelectedPresetId(presetId);
      setTotalSeconds(preset.durationSeconds);
      setSessionName(preset.name);
    }
  };

  const progress = getProgress();
  const formattedTime = getFormattedTime();

  const isTimerActive = phase === 'running' || phase === 'paused';

  return (
    <>
      {/* Ambient Background */}
      <AmbientBackground 
        mode={ambientMode} 
        isActive={isTimerActive} 
      />
      
      <div className="card p-8 md:p-12 space-y-8 relative z-10">
      {/* Session Name */}
      {sessionName && (
        <div className="text-center">
          <h3 className="text-lg md:text-xl font-semibold text-[var(--foreground-muted)]">
            {sessionName}
          </h3>
        </div>
      )}

      {/* Timer Display */}
      <div className="flex flex-col items-center space-y-6">
        {/* Circular Progress */}
        <div className="relative w-64 h-64 md:w-80 md:h-80">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
            {/* Background circle */}
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="var(--background-subtle)"
              strokeWidth="8"
            />
            {/* Progress circle */}
            <motion.circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="var(--accent-primary)"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${2 * Math.PI * 45}`}
              initial={{ strokeDashoffset: 2 * Math.PI * 45 }}
              animate={{ strokeDashoffset: 2 * Math.PI * 45 * (1 - progress) }}
              transition={{ duration: 0.3, ease: 'linear' }}
            />
          </svg>
          
          {/* Time Display */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <div className="text-5xl md:text-6xl font-bold text-[var(--foreground)] mb-2 font-mono">
                {formattedTime}
              </div>
              <div className="text-sm text-[var(--foreground-muted)]">
                {phase === 'running' && 'Focusing...'}
                {phase === 'paused' && 'Paused'}
                {phase === 'idle' && 'Ready to focus'}
                {phase === 'completed' && 'Session complete!'}
              </div>
            </div>
          </div>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-4">
          {phase === 'idle' || phase === 'completed' ? (
            <button
              onClick={handleStart}
              className="btn btn-accent btn-lg"
            >
              <Play className="w-5 h-5" />
              Start
            </button>
          ) : phase === 'running' ? (
            <button
              onClick={handlePause}
              className="btn btn-secondary btn-lg"
            >
              <Pause className="w-5 h-5" />
              Pause
            </button>
          ) : (
            <button
              onClick={handleStart}
              className="btn btn-accent btn-lg"
            >
              <Play className="w-5 h-5" />
              Resume
            </button>
          )}

          {(phase === 'running' || phase === 'paused') && (
            <button
              onClick={handleReset}
              className="btn btn-secondary btn-lg"
            >
              <RotateCcw className="w-5 h-5" />
              Reset
            </button>
          )}
        </div>
      </div>

      {/* Preset Selection (when idle) */}
      {phase === 'idle' && presets.length > 0 && (
        <div className="space-y-4">
          <div className="text-center">
            <h4 className="text-sm font-medium text-[var(--foreground-muted)] mb-4">
              Quick Start Presets
            </h4>
            <div className="flex flex-wrap gap-2 justify-center">
              {presets.slice(0, 4).map((preset) => {
                const minutes = Math.floor(preset.durationSeconds / 60);
                const isSelected = selectedPresetId === preset.id;
                return (
                  <button
                    key={preset.id}
                    onClick={() => handlePresetSelect(preset.id)}
                    className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                      isSelected
                        ? 'bg-[var(--accent-primary)] text-white'
                        : 'bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50'
                    }`}
                  >
                    {preset.emoji && <span className="mr-1">{preset.emoji}</span>}
                    {preset.name} ({minutes}m)
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Ambient Background Selection (when idle or paused) */}
      {(phase === 'idle' || phase === 'paused') && (
        <div className="space-y-4 pt-4 border-t border-[var(--border)]">
          <div className="text-center">
            <h4 className="text-sm font-medium text-[var(--foreground-muted)] mb-4">
              Ambient Background
            </h4>
            <div className="flex flex-wrap gap-2 justify-center max-w-2xl mx-auto">
              {([
                'none', 'minimal', 'aurora', 'ocean', 'forest', 'rain', 
                'fireplace', 'stars', 'gradientFlow', 'snow', 'underwater', 
                'clouds', 'sakura', 'lightning', 'lavaLamp'
              ] as AmbientMode[]).map((mode) => {
                const isSelected = ambientMode === mode;
                const labels: Record<string, string> = {
                  none: 'None',
                  minimal: 'Minimal',
                  aurora: '🌌 Aurora',
                  ocean: '🌊 Ocean',
                  forest: '🌲 Forest',
                  rain: '🌧️ Rain',
                  fireplace: '🔥 Fireplace',
                  stars: '✨ Stars',
                  gradientFlow: '🌈 Gradient Flow',
                  snow: '❄️ Snow',
                  underwater: '🌊 Underwater',
                  clouds: '☁️ Clouds',
                  sakura: '🌸 Sakura',
                  lightning: '⚡ Lightning',
                  lavaLamp: '🪔 Lava Lamp',
                };
                return (
                  <button
                    key={mode}
                    onClick={() => setAmbientMode(mode)}
                    className={`px-3 py-2 rounded-xl text-xs md:text-sm font-medium transition-all ${
                      isSelected
                        ? 'bg-[var(--accent-primary)] text-white'
                        : 'bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50'
                    }`}
                  >
                    {labels[mode]}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Session Complete Message */}
      {phase === 'completed' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center p-4 rounded-xl bg-[var(--success)]/10 border border-[var(--success)]/20"
        >
          <p className="text-[var(--success)] font-medium">
            🎉 Great work! Your focus session has been saved.
          </p>
        </motion.div>
      )}
      </div>
    </>
  );
}

