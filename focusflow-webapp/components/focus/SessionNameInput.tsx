'use client';

import { Sparkles, Headphones, Palette } from 'lucide-react';
import { motion } from 'framer-motion';

interface SessionNameInputProps {
  sessionName: string;
  onSessionNameChange: (name: string) => void;
  onSoundClick: () => void;
  onAmbientClick: () => void;
  selectedSound: string | null;
  ambientMode: string;
}

export function SessionNameInput({
  sessionName,
  onSessionNameChange,
  onSoundClick,
  onAmbientClick,
  selectedSound,
  ambientMode,
}: SessionNameInputProps) {
  return (
    <div className="flex items-center gap-3">
      {/* Sound Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={onSoundClick}
        className="w-10 h-10 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] flex items-center justify-center hover:border-[var(--accent-primary)]/30 transition-all group"
        title="Focus sound"
      >
        <Headphones className="w-4 h-4 text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)] transition-colors" strokeWidth={2} />
        {selectedSound && (
          <div className="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
        )}
      </motion.button>

      {/* Ambient Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={onAmbientClick}
        className="w-10 h-10 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] flex items-center justify-center hover:border-[var(--accent-primary)]/30 transition-all group"
        title="Ambient background"
      >
        <Palette className="w-4 h-4 text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)] transition-colors" strokeWidth={2} />
        {ambientMode !== 'none' && (
          <div className="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-[var(--accent-secondary)]" />
        )}
      </motion.button>

      {/* Session Name Input */}
      <div className="flex-1 relative">
        <div className="absolute left-3 top-1/2 -translate-y-1/2">
          <Sparkles className="w-4 h-4 text-[var(--accent-primary)] opacity-70" strokeWidth={2} />
        </div>
        <input
          type="text"
          value={sessionName}
          onChange={(e) => onSessionNameChange(e.target.value)}
          placeholder="Deep work, exam prep, client project..."
          className="w-full pl-10 pr-4 py-3 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground)] placeholder:text-[var(--foreground-muted)] focus:outline-none focus:border-[var(--accent-primary)]/50 transition-all font-medium"
        />
      </div>
    </div>
  );
}

