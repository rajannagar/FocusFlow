'use client';

import { ReactNode } from 'react';
import { motion, HTMLMotionProps } from 'framer-motion';
import { cn } from '@/lib/utils';

interface GlassCardProps extends Omit<HTMLMotionProps<'div'>, 'children'> {
  children: ReactNode;
  variant?: 'default' | 'subtle' | 'glow' | 'elevated';
  hover?: boolean;
  glow?: boolean;
  className?: string;
}

export function GlassCard({
  children,
  variant = 'default',
  hover = true,
  glow = false,
  className,
  ...props
}: GlassCardProps) {
  const variantStyles = {
    default: {
      background: 'var(--background-elevated)',
      border: '1px solid var(--border)',
      opacity: 0.95,
    },
    subtle: {
      background: 'rgba(17, 17, 19, 0.6)',
      border: '1px solid rgba(245, 240, 232, 0.06)',
      opacity: 1,
    },
    glow: {
      background: 'var(--background-elevated)',
      border: '1px solid var(--accent-primary)30',
      opacity: 1,
    },
    elevated: {
      background: 'rgba(17, 17, 19, 0.9)',
      border: '1px solid rgba(245, 240, 232, 0.1)',
      opacity: 1,
    },
  };

  const hoverEffects = hover
    ? {
        borderColor: 'var(--accent-primary)40',
        boxShadow: glow
          ? '0 0 40px rgba(139, 92, 246, 0.15), 0 8px 32px rgba(0, 0, 0, 0.12)'
          : '0 8px 32px rgba(0, 0, 0, 0.12)',
      }
    : {};

  return (
    <motion.div
      className={cn(
        'relative overflow-hidden rounded-2xl backdrop-blur-xl transition-all duration-500',
        className
      )}
      style={{
        ...variantStyles[variant],
      }}
      whileHover={hover ? { y: -4, ...hoverEffects } : undefined}
      transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
      {...props}
    >
      {/* Top highlight */}
      <div
        className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-white/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"
        style={{
          background: 'linear-gradient(90deg, transparent, rgba(245, 240, 232, 0.1), transparent)',
        }}
      />

      {/* Gradient overlay on hover */}
      {glow && (
        <div
          className="absolute inset-0 opacity-0 hover:opacity-100 transition-opacity duration-500 pointer-events-none rounded-2xl"
          style={{
            background: 'linear-gradient(135deg, var(--accent-primary)08, transparent 40%, var(--accent-secondary)08)',
          }}
        />
      )}

      {/* Content */}
      <div className="relative z-10">{children}</div>
    </motion.div>
  );
}
