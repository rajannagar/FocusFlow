'use client';

import { Plus } from 'lucide-react';
import { motion } from 'framer-motion';
import type { FocusPreset } from '@/types';
import Link from 'next/link';

interface PresetSelectorProps {
  presets: FocusPreset[];
  selectedPresetId: string | null;
  onPresetSelect: (preset: FocusPreset) => void;
  isRunning: boolean;
  isPaused: boolean;
}

export function PresetSelector({
  presets,
  selectedPresetId,
  onPresetSelect,
  isRunning,
  isPaused,
}: PresetSelectorProps) {
  const canSelectPreset = !isRunning && !isPaused;

  return (
    <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-hide">
      {/* Add Preset Button */}
      <Link href="/presets">
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="w-10 h-10 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] flex items-center justify-center hover:border-[var(--accent-primary)]/30 transition-all flex-shrink-0"
          title="Manage presets"
        >
          <Plus className="w-4 h-4 text-[var(--foreground-muted)]" strokeWidth={2} />
        </motion.button>
      </Link>

      {/* Preset Chips */}
      {presets.map((preset) => {
        const isSelected = selectedPresetId === preset.id;
        const minutes = Math.floor(preset.durationSeconds / 60);
        
        return (
          <motion.button
            key={preset.id}
            whileHover={canSelectPreset ? { scale: 1.05 } : {}}
            whileTap={canSelectPreset ? { scale: 0.95 } : {}}
            onClick={() => canSelectPreset && onPresetSelect(preset)}
            disabled={!canSelectPreset}
            className={`px-4 py-2 rounded-full text-sm font-semibold transition-all flex items-center gap-2 flex-shrink-0 ${
              isSelected
                ? 'bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] text-white shadow-lg shadow-[var(--accent-primary)]/20'
                : 'bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/30'
            } ${!canSelectPreset ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            {preset.emoji && <span>{preset.emoji}</span>}
            <span>{preset.name}</span>
            <span className="text-xs opacity-70">({minutes}m)</span>
          </motion.button>
        );
      })}
    </div>
  );
}

