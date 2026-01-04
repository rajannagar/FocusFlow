'use client';

import { useState, useEffect, memo } from 'react';
import { Volume2, VolumeX, Play, Pause } from 'lucide-react';
import { motion } from 'framer-motion';
import { useFocusSoundStore } from '@/stores/useFocusSoundStore';
import { focusSoundManager } from '@/lib/FocusSoundManager';
import { FocusSound, FocusSoundDisplayNames } from '@/types';

export const SoundSettingsCard = memo(function SoundSettingsCard() {
  const { selectedSound, soundEnabled, setSelectedSound, setSoundEnabled } = useFocusSoundStore();
  const [isPreviewing, setIsPreviewing] = useState(false);

  const allSounds = Object.values(FocusSound);

  const handleSoundSelect = async (sound: FocusSound) => {
    if (selectedSound === sound) {
      // Toggle sound off
      setSelectedSound(null);
      focusSoundManager.stop();
    } else {
      // Select new sound
      setSelectedSound(sound);
      setSoundEnabled(true);
      
      // Preview the sound
      setIsPreviewing(true);
      await focusSoundManager.play(sound);
    }
  };

  const handleToggleSound = () => {
    const newEnabled = !soundEnabled;
    setSoundEnabled(newEnabled);
    
    if (newEnabled && selectedSound) {
      focusSoundManager.play(selectedSound);
    } else {
      focusSoundManager.pause();
    }
  };

  const handlePreview = async () => {
    if (!selectedSound) return;
    
    if (isPreviewing) {
      focusSoundManager.pause();
      setIsPreviewing(false);
    } else {
      setIsPreviewing(true);
      await focusSoundManager.play(selectedSound);
    }
  };

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (isPreviewing) {
        focusSoundManager.stop();
      }
    };
  }, [isPreviewing]);

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-[var(--foreground)]">Focus Sound</h3>
        <button
          onClick={handleToggleSound}
          className={`p-2 rounded-xl transition-colors ${
            soundEnabled
              ? 'bg-[var(--accent-primary)]/10 text-[var(--accent-primary)]'
              : 'bg-[var(--background-subtle)] text-[var(--foreground-muted)]'
          }`}
          title={soundEnabled ? 'Disable sound' : 'Enable sound'}
        >
          {soundEnabled ? (
            <Volume2 className="w-4 h-4" />
          ) : (
            <VolumeX className="w-4 h-4" />
          )}
        </button>
      </div>

      {/* Sound Grid */}
      <div className="grid grid-cols-2 gap-2 mb-4">
        {allSounds.map((sound) => {
          const isSelected = selectedSound === sound;
          const displayName = FocusSoundDisplayNames[sound];

          return (
            <motion.button
              key={sound}
              onClick={() => handleSoundSelect(sound)}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className={`p-3 rounded-xl text-sm font-medium transition-all text-left ${
                isSelected
                  ? 'bg-[var(--accent-gradient)] text-white shadow-lg'
                  : 'bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground-muted)] hover:border-[var(--accent-primary)]/50'
              }`}
            >
              {displayName}
            </motion.button>
          );
        })}
      </div>

      {/* Preview Button */}
      {selectedSound && (
        <button
          onClick={handlePreview}
          className="w-full px-4 py-2 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/50 transition-colors flex items-center justify-center gap-2 text-sm font-medium text-[var(--foreground-muted)]"
        >
          {isPreviewing ? (
            <>
              <Pause className="w-4 h-4" />
              Stop Preview
            </>
          ) : (
            <>
              <Play className="w-4 h-4" />
              Preview Sound
            </>
          )}
        </button>
      )}
    </div>
  );
});

