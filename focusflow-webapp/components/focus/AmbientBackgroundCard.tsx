'use client';

import { useState, memo } from 'react';
import { Settings } from 'lucide-react';
import { motion } from 'framer-motion';
import type { AmbientMode } from './AmbientBackground';

interface AmbientBackgroundCardProps {
  mode: AmbientMode;
  intensity: number;
  onModeChange: (mode: AmbientMode) => void;
  onIntensityChange: (intensity: number) => void;
}

const ambientModes: { value: AmbientMode; label: string; icon: string }[] = [
  { value: 'none', label: 'None', icon: '○' },
  { value: 'minimal', label: 'Minimal', icon: '◉' },
  { value: 'aurora', label: 'Aurora', icon: '🌌' },
  { value: 'ocean', label: 'Ocean', icon: '🌊' },
  { value: 'forest', label: 'Forest', icon: '🌲' },
  { value: 'rain', label: 'Rain', icon: '🌧️' },
  { value: 'fireplace', label: 'Fireplace', icon: '🔥' },
  { value: 'stars', label: 'Stars', icon: '✨' },
  { value: 'gradientFlow', label: 'Gradient', icon: '🌈' },
  { value: 'snow', label: 'Snow', icon: '❄️' },
];

export const AmbientBackgroundCard = memo(function AmbientBackgroundCard({
  mode,
  intensity,
  onModeChange,
  onIntensityChange,
}: AmbientBackgroundCardProps) {
  const [showIntensity, setShowIntensity] = useState(false);

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-[var(--foreground)]">Ambient Background</h3>
        <button
          onClick={() => setShowIntensity(!showIntensity)}
          className="p-2 rounded-xl hover:bg-[var(--background-subtle)] transition-colors"
          title="Adjust intensity"
        >
          <Settings className="w-4 h-4 text-[var(--foreground-muted)]" />
        </button>
      </div>

      {/* Intensity Slider */}
      {showIntensity && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="mb-4"
        >
          <div className="flex items-center gap-3">
            <span className="text-xs text-[var(--foreground-muted)] w-16">Intensity</span>
            <input
              type="range"
              min="0.1"
              max="1"
              step="0.1"
              value={intensity}
              onChange={(e) => onIntensityChange(parseFloat(e.target.value))}
              className="flex-1 h-2 rounded-full appearance-none bg-[var(--background-subtle)] accent-[var(--accent-primary)]"
            />
            <span className="text-xs text-[var(--foreground-muted)] w-12 text-right">
              {Math.round(intensity * 100)}%
            </span>
          </div>
        </motion.div>
      )}

      {/* Mode Grid */}
      <div className="grid grid-cols-3 gap-2">
        {ambientModes.map((ambient) => {
          const isSelected = mode === ambient.value;
          return (
            <motion.button
              key={ambient.value}
              onClick={() => onModeChange(ambient.value)}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className={`p-3 rounded-xl text-sm font-medium transition-all ${
                isSelected
                  ? 'bg-[var(--accent-gradient)] text-white shadow-lg'
                  : 'bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50'
              }`}
            >
              <div className="text-lg mb-1">{ambient.icon}</div>
              <div className="text-xs">{ambient.label}</div>
            </motion.button>
          );
        })}
      </div>
    </div>
  );
});

