'use client';

import { useState, useEffect } from 'react';
import { X, Clock } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/common/Button';

interface TimePickerProps {
  isOpen: boolean;
  onClose: () => void;
  currentMinutes: number;
  onConfirm: (minutes: number) => void;
}

export function TimePicker({
  isOpen,
  onClose,
  currentMinutes,
  onConfirm,
}: TimePickerProps) {
  const [hours, setHours] = useState(0);
  const [minutes, setMinutes] = useState(25);

  useEffect(() => {
    if (isOpen) {
      setHours(Math.floor(currentMinutes / 60));
      setMinutes(currentMinutes % 60);
    }
  }, [isOpen, currentMinutes]);

  const handleConfirm = () => {
    const totalMinutes = hours * 60 + minutes;
    if (totalMinutes > 0) {
      onConfirm(totalMinutes);
      onClose();
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
                <Clock className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={1.5} />
              </div>
              <div>
                <h3 className="text-lg font-bold text-[var(--foreground)]">Session Length</h3>
                <p className="text-sm text-[var(--foreground-muted)]">Set duration</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-lg hover:bg-[var(--background-subtle)] flex items-center justify-center transition-colors"
            >
              <X className="w-5 h-5 text-[var(--foreground-muted)]" />
            </button>
          </div>

          {/* Time Picker */}
          <div className="p-6">
            <div className="flex items-center gap-4 mb-6">
              {/* Hours */}
              <div className="flex-1">
                <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block text-center">
                  Hours
                </label>
                <div className="flex flex-col gap-2 max-h-48 overflow-y-auto scrollbar-hide">
                  {Array.from({ length: 13 }, (_, i) => (
                    <button
                      key={i}
                      onClick={() => setHours(i)}
                      className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                        hours === i
                          ? 'bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 text-[var(--accent-primary)] border border-[var(--accent-primary)]'
                          : 'text-[var(--foreground-muted)] hover:bg-[var(--background-subtle)]'
                      }`}
                    >
                      {i}
                    </button>
                  ))}
                </div>
              </div>

              <div className="text-2xl font-bold text-[var(--foreground-muted)]">:</div>

              {/* Minutes */}
              <div className="flex-1">
                <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block text-center">
                  Minutes
                </label>
                <div className="flex flex-col gap-2 max-h-48 overflow-y-auto scrollbar-hide">
                  {Array.from({ length: 60 }, (_, i) => (
                    <button
                      key={i}
                      onClick={() => setMinutes(i)}
                      className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                        minutes === i
                          ? 'bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 text-[var(--accent-primary)] border border-[var(--accent-primary)]'
                          : 'text-[var(--foreground-muted)] hover:bg-[var(--background-subtle)]'
                      }`}
                    >
                      {String(i).padStart(2, '0')}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Selected Time Display */}
            <div className="mb-6 p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] text-center">
              <div className="text-sm text-[var(--foreground-muted)] mb-1">Selected Duration</div>
              <div className="text-2xl font-bold text-[var(--foreground)]">
                {hours > 0 ? `${hours}h ` : ''}{minutes}m
              </div>
            </div>

            {/* Actions */}
            <div className="flex gap-3">
              <Button
                variant="secondary"
                onClick={onClose}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                variant="accent"
                onClick={handleConfirm}
                className="flex-1"
                disabled={hours === 0 && minutes === 0}
              >
                Set
              </Button>
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}

