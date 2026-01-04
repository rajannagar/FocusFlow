'use client';

import { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/common/Button';

interface TimePickerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (hours: number, minutes: number) => void;
  initialHours?: number;
  initialMinutes?: number;
}

export function TimePickerModal({
  isOpen,
  onClose,
  onConfirm,
  initialHours = 0,
  initialMinutes = 25,
}: TimePickerModalProps) {
  const [selectedHours, setSelectedHours] = useState(initialHours);
  const [selectedMinutes, setSelectedMinutes] = useState(initialMinutes);

  useEffect(() => {
    if (isOpen) {
      setSelectedHours(initialHours);
      setSelectedMinutes(initialMinutes);
    }
  }, [isOpen, initialHours, initialMinutes]);

  const handleConfirm = () => {
    const totalMinutes = selectedHours * 60 + selectedMinutes;
    if (totalMinutes > 0) {
      onConfirm(selectedHours, selectedMinutes);
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        />

        {/* Modal */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="relative z-10 w-full max-w-md mx-4"
        >
          <div className="card p-6 md:p-8">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-bold text-[var(--foreground)]">Session Length</h2>
                <p className="text-sm text-[var(--foreground-muted)] mt-1">
                  Set a length that fits what you're about to do
                </p>
              </div>
              <button
                onClick={onClose}
                className="p-2 rounded-xl hover:bg-[var(--background-subtle)] transition-colors"
              >
                <X className="w-5 h-5 text-[var(--foreground-muted)]" />
              </button>
            </div>

            {/* Time Pickers */}
            <div className="flex gap-4 mb-6">
              {/* Hours */}
              <div className="flex-1">
                <label className="block text-sm font-medium text-[var(--foreground-muted)] mb-2 text-center">
                  Hours
                </label>
                <div className="relative">
                  <select
                    value={selectedHours}
                    onChange={(e) => setSelectedHours(parseInt(e.target.value, 10))}
                    className="w-full p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground)] text-center text-2xl font-bold appearance-none cursor-pointer hover:border-[var(--accent-primary)]/50 transition-colors"
                  >
                    {Array.from({ length: 13 }, (_, i) => (
                      <option key={i} value={i}>
                        {i}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Minutes */}
              <div className="flex-1">
                <label className="block text-sm font-medium text-[var(--foreground-muted)] mb-2 text-center">
                  Minutes
                </label>
                <div className="relative">
                  <select
                    value={selectedMinutes}
                    onChange={(e) => setSelectedMinutes(parseInt(e.target.value, 10))}
                    className="w-full p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] text-[var(--foreground)] text-center text-2xl font-bold appearance-none cursor-pointer hover:border-[var(--accent-primary)]/50 transition-colors"
                  >
                    {Array.from({ length: 60 }, (_, i) => (
                      <option key={i} value={i}>
                        {String(i).padStart(2, '0')}
                      </option>
                    ))}
                  </select>
                </div>
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
                disabled={selectedHours === 0 && selectedMinutes === 0}
              >
                Set
              </Button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}

