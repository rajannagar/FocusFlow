'use client';

import { memo } from 'react';
import { usePresetsStore } from '@/stores/usePresetsStore';
import { useTimerStore } from '@/stores/useTimerStore';
import { Plus } from 'lucide-react';
import { motion } from 'framer-motion';

interface PresetSelectorCardProps {
  onPresetSelect?: (presetId: string) => void;
  onAddPreset?: () => void;
}

export const PresetSelectorCard = memo(function PresetSelectorCard({ onPresetSelect, onAddPreset }: PresetSelectorCardProps) {
  const presets = usePresetsStore((state) => state.presets);
  const selectedPresetId = usePresetsStore((state) => state.selectedPresetId);
  const setSelectedPresetId = usePresetsStore((state) => state.setSelectedPresetId);
  const phase = useTimerStore((state) => state.phase);

  const handlePresetClick = (presetId: string) => {
    if (phase === 'idle' || phase === 'completed') {
      setSelectedPresetId(presetId);
      onPresetSelect?.(presetId);
    } else {
      // Show confirmation if session is active
      if (confirm('Switch preset? This will reset your current session.')) {
        setSelectedPresetId(presetId);
        onPresetSelect?.(presetId);
      }
    }
  };

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-[var(--foreground)]">Presets</h3>
        {onAddPreset && (
          <button
            onClick={onAddPreset}
            className="p-2 rounded-xl hover:bg-[var(--background-subtle)] transition-colors"
            title="Add preset"
          >
            <Plus className="w-4 h-4 text-[var(--foreground-muted)]" />
          </button>
        )}
      </div>

      <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-2">
        {/* Add Preset Button */}
        {onAddPreset && (
          <button
            onClick={onAddPreset}
            className="flex-shrink-0 px-4 py-2 rounded-xl border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-colors flex items-center gap-2"
          >
            <Plus className="w-4 h-4 text-[var(--foreground-muted)]" />
            <span className="text-sm font-medium text-[var(--foreground-muted)]">Add</span>
          </button>
        )}

        {/* Preset Chips */}
        {presets.map((preset) => {
          const isSelected = selectedPresetId === preset.id;
          const minutes = Math.floor(preset.durationSeconds / 60);

          return (
            <motion.button
              key={preset.id}
              onClick={() => handlePresetClick(preset.id)}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className={`flex-shrink-0 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
                isSelected
                  ? 'bg-[var(--accent-gradient)] text-white shadow-lg'
                  : 'bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50'
              }`}
            >
              {preset.emoji && <span className="mr-1">{preset.emoji}</span>}
              {preset.name} ({minutes}m)
            </motion.button>
          );
        })}
      </div>
    </div>
  );
});

