'use client';

import { useEffect, useState } from 'react';
import { useTimerStore } from '@/stores/useTimerStore';
import { Play, Pause, RotateCcw, X, Maximize2 } from 'lucide-react';
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
    tick 
  } = useTimerStore();
  
  const [ambientMode, setAmbientMode] = useState<AmbientMode>('ocean');
  const [showControls, setShowControls] = useState(true);
  
  const progress = getProgress();
  const isRunning = phase === 'running';
  const isPaused = phase === 'paused';
  const isIdle = phase === 'idle';

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
        className="fixed inset-0 z-50 flex items-center justify-center"
        onClick={() => setShowControls(!showControls)}
      >
        {/* Ambient Background */}
        <AmbientBackground 
          mode={ambientMode} 
          isActive={isRunning || isPaused}
          intensity={0.8}
        />

        {/* Timer Display */}
        <div className="relative z-10 text-center">
          {/* Session Name */}
          {sessionName && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: showControls ? 1 : 0.3, y: 0 }}
              className="mb-8"
            >
              <h2 className="text-2xl md:text-3xl font-semibold text-white/90">
                {sessionName}
              </h2>
            </motion.div>
          )}

          {/* Circular Progress */}
          <div className="relative w-80 h-80 md:w-96 md:h-96 mx-auto mb-12">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
              {/* Background circle */}
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="rgba(255, 255, 255, 0.1)"
                strokeWidth="6"
              />
              {/* Progress circle */}
              <motion.circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="url(#gradient)"
                strokeWidth="6"
                strokeLinecap="round"
                strokeDasharray={`${2 * Math.PI * 45}`}
                initial={{ strokeDashoffset: 2 * Math.PI * 45 }}
                animate={{ strokeDashoffset: 2 * Math.PI * 45 * (1 - progress) }}
                transition={{ duration: 0.3, ease: 'linear' }}
              />
              <defs>
                <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#8B5CF6" />
                  <stop offset="100%" stopColor="#D4A853" />
                </linearGradient>
              </defs>
            </svg>
            
            {/* Time Display */}
            <div className="absolute inset-0 flex items-center justify-center">
              <motion.div
                key={remainingSeconds}
                initial={{ scale: 1.1 }}
                animate={{ scale: 1 }}
                className="text-center"
              >
                <div className="text-7xl md:text-8xl font-bold tabular-nums text-white mb-4">
                  {getFormattedTime()}
                </div>
                <div className="text-lg md:text-xl text-white/70">
                  {isIdle && 'Ready to focus'}
                  {isRunning && 'Focusing...'}
                  {isPaused && 'Paused'}
                </div>
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
                  <button
                    onClick={() => setPhase('running')}
                    className="px-8 py-4 bg-white/20 backdrop-blur-xl rounded-full text-white font-semibold hover:bg-white/30 transition-all flex items-center gap-3"
                  >
                    <Play className="w-6 h-6" />
                    Start
                  </button>
                )}
                
                {isRunning && (
                  <>
                    <button
                      onClick={() => setPhase('paused')}
                      className="px-8 py-4 bg-white/20 backdrop-blur-xl rounded-full text-white font-semibold hover:bg-white/30 transition-all flex items-center gap-3"
                    >
                      <Pause className="w-6 h-6" />
                      Pause
                    </button>
                    <button
                      onClick={reset}
                      className="px-6 py-4 bg-white/10 backdrop-blur-xl rounded-full text-white/80 hover:bg-white/20 transition-all"
                    >
                      <RotateCcw className="w-5 h-5" />
                    </button>
                  </>
                )}
                
                {isPaused && (
                  <>
                    <button
                      onClick={() => setPhase('running')}
                      className="px-8 py-4 bg-white/20 backdrop-blur-xl rounded-full text-white font-semibold hover:bg-white/30 transition-all flex items-center gap-3"
                    >
                      <Play className="w-6 h-6" />
                      Resume
                    </button>
                    <button
                      onClick={reset}
                      className="px-6 py-4 bg-white/10 backdrop-blur-xl rounded-full text-white/80 hover:bg-white/20 transition-all"
                    >
                      <RotateCcw className="w-5 h-5" />
                    </button>
                  </>
                )}

                <button
                  onClick={onClose}
                  className="px-6 py-4 bg-white/10 backdrop-blur-xl rounded-full text-white/80 hover:bg-white/20 transition-all"
                >
                  <X className="w-5 h-5" />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Keyboard Shortcuts Hint */}
          {showControls && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="mt-8 text-white/50 text-sm"
            >
              <p>Space: {isRunning ? 'Pause' : 'Start'} • Esc: Exit • R: Reset</p>
            </motion.div>
          )}
        </div>
      </motion.div>
    </AnimatePresence>
  );
}

