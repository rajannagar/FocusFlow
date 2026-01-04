'use client';

import { useState } from 'react';
import { X, Headphones } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { focusSounds } from '@/lib/focusSounds';

interface SoundPickerProps {
  isOpen: boolean;
  onClose: () => void;
  selectedSound: string | null;
  onSelectSound: (sound: string | null) => void;
}

export function SoundPicker({
  isOpen,
  onClose,
  selectedSound,
  onSelectSound,
}: SoundPickerProps) {
  const handleSelect = (soundId: string) => {
    if (selectedSound === soundId) {
      onSelectSound(null); // Toggle off
    } else {
      onSelectSound(soundId);
    }
  };

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
          className="relative w-full max-w-md mx-4 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] shadow-2xl overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-[var(--border)]">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center">
                <Headphones className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={1.5} />
              </div>
              <div>
                <h3 className="text-lg font-bold text-[var(--foreground)]">Focus Sounds</h3>
                <p className="text-sm text-[var(--foreground-muted)]">Choose ambient sound</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-lg hover:bg-[var(--background-subtle)] flex items-center justify-center transition-colors"
            >
              <X className="w-5 h-5 text-[var(--foreground-muted)]" />
            </button>
          </div>

          {/* Sounds List */}
          <div className="p-4 max-h-[60vh] overflow-y-auto">
            {/* None Option */}
            <button
              onClick={() => {
                onSelectSound(null);
                onClose();
              }}
              className={`w-full p-4 rounded-xl text-left transition-all mb-2 ${
                selectedSound === null
                  ? 'bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)]'
                  : 'bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="text-2xl">🔇</div>
                <div>
                  <div className="font-semibold text-[var(--foreground)]">None</div>
                  <div className="text-xs text-[var(--foreground-muted)]">No sound</div>
                </div>
              </div>
            </button>

            {/* Sound Options */}
            <div className="grid grid-cols-1 gap-2">
              {focusSounds.map((sound) => {
                const isSelected = selectedSound === sound.id;
                return (
                  <motion.button
                    key={sound.id}
                    whileHover={{ scale: 1.02, x: 4 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => handleSelect(sound.id)}
                    className={`w-full p-4 rounded-xl text-left transition-all ${
                      isSelected
                        ? 'bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-2 border-[var(--accent-primary)]'
                        : 'bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="text-2xl">{sound.emoji}</div>
                      <div className="flex-1">
                        <div className={`font-semibold ${isSelected ? 'text-[var(--accent-primary)]' : 'text-[var(--foreground)]'}`}>
                          {sound.name}
                        </div>
                      </div>
                      {isSelected && (
                        <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                      )}
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

