'use client';

import { useState } from 'react';
import { X, Palette } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import type { AmbientMode } from './AmbientBackground';

interface AmbientPickerProps {
  isOpen: boolean;
  onClose: () => void;
  selectedMode: AmbientMode;
  onSelectMode: (mode: AmbientMode) => void;
}

const ambientModes: { mode: AmbientMode; emoji: string; name: string }[] = [
  { mode: 'none', emoji: '⚪', name: 'None' },
  { mode: 'minimal', emoji: '⚫', name: 'Minimal' },
  { mode: 'aurora', emoji: '🌌', name: 'Aurora' },
  { mode: 'ocean', emoji: '🌊', name: 'Ocean' },
  { mode: 'forest', emoji: '🌲', name: 'Forest' },
  { mode: 'rain', emoji: '🌧️', name: 'Rain' },
  { mode: 'fireplace', emoji: '🔥', name: 'Fireplace' },
  { mode: 'stars', emoji: '✨', name: 'Stars' },
  { mode: 'gradientFlow', emoji: '🌈', name: 'Gradient Flow' },
  { mode: 'snow', emoji: '❄️', name: 'Snow' },
  { mode: 'underwater', emoji: '🌊', name: 'Underwater' },
  { mode: 'clouds', emoji: '☁️', name: 'Clouds' },
  { mode: 'sakura', emoji: '🌸', name: 'Sakura' },
  { mode: 'lightning', emoji: '⚡', name: 'Lightning' },
  { mode: 'lavaLamp', emoji: '🪔', name: 'Lava Lamp' },
];

export function AmbientPicker({
  isOpen,
  onClose,
  selectedMode,
  onSelectMode,
}: AmbientPickerProps) {
  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          onClick={(e) => e.stopPropagation()}
          className="relative w-full max-w-2xl mx-4 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] shadow-2xl overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-[var(--border)]">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-secondary)]/20 to-[var(--accent-secondary)]/10 flex items-center justify-center">
                <Palette className="w-5 h-5 text-[var(--accent-secondary)]" strokeWidth={1.5} />
              </div>
              <div>
                <h3 className="text-lg font-bold text-[var(--foreground)]">Ambient Background</h3>
                <p className="text-sm text-[var(--foreground-muted)]">Choose visual ambiance</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-lg hover:bg-[var(--background-subtle)] flex items-center justify-center transition-colors"
            >
              <X className="w-5 h-5 text-[var(--foreground-muted)]" />
            </button>
          </div>

          {/* Ambient Modes Grid */}
          <div className="p-6 max-h-[60vh] overflow-y-auto">
            <div className="grid grid-cols-3 md:grid-cols-5 lg:grid-cols-7 gap-3">
              {ambientModes.map((item) => {
                const isSelected = selectedMode === item.mode;
                return (
                  <motion.button
                    key={item.mode}
                    whileHover={{ scale: 1.05, y: -2 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => {
                      onSelectMode(item.mode);
                      onClose();
                    }}
                    className={`p-4 rounded-xl text-center transition-all ${
                      isSelected
                        ? 'bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)] shadow-md'
                        : 'bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30'
                    }`}
                  >
                    <div className="text-3xl mb-2">{item.emoji}</div>
                    <div className={`text-xs font-medium ${isSelected ? 'text-[var(--accent-primary)]' : 'text-[var(--foreground-muted)]'}`}>
                      {item.name}
                    </div>
                  </motion.button>
                );
              })}
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}

