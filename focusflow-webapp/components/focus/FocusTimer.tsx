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
      
      <div className="relative p-8 md:p-12 lg:p-16 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500 space-y-8 relative z-10">
      {/* Session Name */}
      {sessionName && (
        <div className="text-center mb-4">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-2">
            <span>Session</span>
          </div>
          <h3 className="text-xl md:text-2xl font-bold text-[var(--foreground)]">
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
              <div 
                className="text-5xl md:text-6xl lg:text-7xl font-bold mb-2 font-mono tabular-nums"
                style={{
                  color: 'var(--foreground)',
                  textShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
                }}
              >
                {formattedTime}
              </div>
              <div 
                className="text-sm md:text-base font-medium"
                style={{
                  color: 'var(--foreground)',
                  textShadow: '0 1px 4px rgba(0, 0, 0, 0.1)',
                }}
              >
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
        <div className="space-y-6 pt-6 border-t border-[var(--border)]">
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
              <span>Quick Start</span>
            </div>
            <h4 className="text-lg font-semibold text-[var(--foreground)] mb-4">
              Select a Preset
            </h4>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {presets.slice(0, 8).map((preset) => {
                const minutes = Math.floor(preset.durationSeconds / 60);
                const isSelected = selectedPresetId === preset.id;
                return (
                  <motion.button
                    key={preset.id}
                    onClick={() => handlePresetSelect(preset.id)}
                    whileHover={{ scale: 1.02, y: -2 }}
                    whileTap={{ scale: 0.98 }}
                    className={`p-4 rounded-2xl text-left transition-all duration-300 ${
                      isSelected
                        ? 'bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)] shadow-lg shadow-[var(--accent-primary)]/20'
                        : 'bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 hover:shadow-md'
                    }`}
                  >
                    <div className="flex items-center gap-2 mb-2">
                      {preset.emoji && <span className="text-xl">{preset.emoji}</span>}
                      <span className={`text-sm font-semibold ${isSelected ? 'text-[var(--accent-primary)]' : 'text-[var(--foreground)]'}`}>
                        {preset.name}
                      </span>
                    </div>
                    <p className="text-xs text-[var(--foreground-muted)]">
                      {minutes} minutes
                    </p>
                  </motion.button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Ambient Background Selection (when idle or paused) */}
      {(phase === 'idle' || phase === 'paused') && (
        <div className="space-y-6 pt-6 border-t border-[var(--border)]">
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
              <span>Ambient</span>
            </div>
            <h4 className="text-lg font-semibold text-[var(--foreground)] mb-4">
              Choose Background
            </h4>
            <div className="grid grid-cols-3 md:grid-cols-5 lg:grid-cols-7 gap-3">
              {([
                'none', 'minimal', 'aurora', 'ocean', 'forest', 'rain', 
                'fireplace', 'stars', 'gradientFlow', 'snow', 'underwater', 
                'clouds', 'sakura', 'lightning', 'lavaLamp'
              ] as AmbientMode[]).map((mode) => {
                const isSelected = ambientMode === mode;
                const labels: Record<string, { emoji: string; name: string }> = {
                  none: { emoji: '⚪', name: 'None' },
                  minimal: { emoji: '⚫', name: 'Minimal' },
                  aurora: { emoji: '🌌', name: 'Aurora' },
                  ocean: { emoji: '🌊', name: 'Ocean' },
                  forest: { emoji: '🌲', name: 'Forest' },
                  rain: { emoji: '🌧️', name: 'Rain' },
                  fireplace: { emoji: '🔥', name: 'Fire' },
                  stars: { emoji: '✨', name: 'Stars' },
                  gradientFlow: { emoji: '🌈', name: 'Gradient' },
                  snow: { emoji: '❄️', name: 'Snow' },
                  underwater: { emoji: '🌊', name: 'Underwater' },
                  clouds: { emoji: '☁️', name: 'Clouds' },
                  sakura: { emoji: '🌸', name: 'Sakura' },
                  lightning: { emoji: '⚡', name: 'Lightning' },
                  lavaLamp: { emoji: '🪔', name: 'Lava' },
                };
                const label = labels[mode] || { emoji: '⚪', name: mode };
                return (
                  <motion.button
                    key={mode}
                    onClick={() => setAmbientMode(mode)}
                    whileHover={{ scale: 1.05, y: -2 }}
                    whileTap={{ scale: 0.95 }}
                    className={`p-3 rounded-xl text-center transition-all duration-300 ${
                      isSelected
                        ? 'bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)] shadow-md'
                        : 'bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30'
                    }`}
                    title={label.name}
                  >
                    <div className="text-2xl mb-1">{label.emoji}</div>
                    <div className={`text-xs font-medium ${isSelected ? 'text-[var(--accent-primary)]' : 'text-[var(--foreground-muted)]'}`}>
                      {label.name}
                    </div>
                  </motion.button>
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

