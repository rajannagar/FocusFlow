'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { Check } from 'lucide-react';
import { Button } from '@/components/common/Button';

interface CompletionOverlayProps {
  isOpen: boolean;
  sessionName: string;
  durationText: string;
  onDone: () => void;
}

export function CompletionOverlay({
  isOpen,
  sessionName,
  durationText,
  onDone,
}: CompletionOverlayProps) {
  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        />

        {/* Overlay Card */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.9, y: 20 }}
          className="relative z-10 w-full max-w-md mx-4"
        >
          <div className="card p-8 text-center">
            {/* Success Icon */}
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', delay: 0.2 }}
              className="mb-6 flex justify-center"
            >
              <div
                className="w-20 h-20 rounded-full flex items-center justify-center"
                style={{
                  background: 'var(--accent-gradient)',
                  boxShadow: '0 0 40px var(--accent-glow)',
                }}
              >
                <Check className="w-10 h-10 text-black" strokeWidth={3} />
              </div>
            </motion.div>

            {/* Title */}
            <h2 className="text-2xl font-bold text-[var(--foreground)] mb-2">
              Session Complete
            </h2>

            {/* Session Name */}
            <p className="text-[var(--foreground-muted)] mb-4">
              You finished "{sessionName}"
            </p>

            {/* Ready Text */}
            <p className="text-sm text-[var(--foreground-subtle)] mb-6">
              Ready for another {durationText} session
            </p>

            {/* Done Button */}
            <Button
              variant="accent"
              onClick={onDone}
              className="w-full"
            >
              Done
            </Button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}

