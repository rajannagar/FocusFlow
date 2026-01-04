'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';

interface PremiumBackgroundProps {
  variant?: 'default' | 'intense' | 'subtle';
  showParticles?: boolean;
  particleCount?: number;
}

export function PremiumBackground({
  variant = 'default',
  showParticles = true,
  particleCount = 16
}: PremiumBackgroundProps) {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({
        x: (e.clientX / window.innerWidth) * 20 - 10,
        y: (e.clientY / window.innerHeight) * 20 - 10,
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  const intensityMap = {
    default: { primary: 0.15, secondary: 0.10, center: 0.08 },
    intense: { primary: 0.25, secondary: 0.18, center: 0.12 },
    subtle: { primary: 0.08, secondary: 0.05, center: 0.04 }
  };

  const intensity = intensityMap[variant];

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden">
      {/* Base Mesh Gradient */}
      <div
        className="absolute inset-0"
        style={{
          background: `
            radial-gradient(ellipse at 20% 30%, rgba(139, 92, 246, ${intensity.primary}) 0%, transparent 50%),
            radial-gradient(ellipse at 80% 70%, rgba(212, 168, 83, ${intensity.secondary}) 0%, transparent 50%),
            radial-gradient(ellipse at 50% 50%, rgba(139, 92, 246, ${intensity.center}) 0%, transparent 70%)
          `
        }}
      />

      {/* Animated Glow Orbs */}
      <motion.div
        className="absolute w-[360px] h-[360px] rounded-full blur-[100px] opacity-20"
        style={{
          background: 'radial-gradient(circle, var(--accent-primary) 0%, transparent 70%)',
          top: '10%',
          left: '15%',
        }}
        animate={{
          x: mousePosition.x * 2,
          y: mousePosition.y * 2,
          scale: [1, 1.1, 1],
        }}
        transition={{
          x: { duration: 0.5, ease: 'easeOut' },
          y: { duration: 0.5, ease: 'easeOut' },
          scale: { duration: 8, repeat: Infinity, ease: 'easeInOut' }
        }}
      />

      <motion.div
        className="absolute w-[280px] h-[280px] rounded-full blur-[90px] opacity-15"
        style={{
          background: 'radial-gradient(circle, var(--accent-secondary) 0%, transparent 70%)',
          bottom: '15%',
          right: '20%',
        }}
        animate={{
          x: mousePosition.x * -1.5,
          y: mousePosition.y * -1.5,
          scale: [1, 1.15, 1],
        }}
        transition={{
          x: { duration: 0.5, ease: 'easeOut' },
          y: { duration: 0.5, ease: 'easeOut' },
          scale: { duration: 10, repeat: Infinity, ease: 'easeInOut' }
        }}
      />

      <motion.div
        className="absolute w-[200px] h-[200px] rounded-full blur-[80px] opacity-10"
        style={{
          background: 'radial-gradient(circle, var(--accent-primary) 0%, transparent 70%)',
          top: '60%',
          right: '10%',
        }}
        animate={{
          x: mousePosition.x,
          y: mousePosition.y,
          scale: [1, 1.2, 1],
        }}
        transition={{
          x: { duration: 0.5, ease: 'easeOut' },
          y: { duration: 0.5, ease: 'easeOut' },
          scale: { duration: 12, repeat: Infinity, ease: 'easeInOut' }
        }}
      />

      {/* Floating Particles */}
      {showParticles && (
        <div className="absolute inset-0">
          {Array.from({ length: particleCount }).map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-1 h-1 rounded-full"
              style={{
                background: i % 2 === 0 ? 'var(--accent-primary)' : 'var(--accent-secondary)',
                opacity: 0.3,
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
              }}
              animate={{
                x: [0, (Math.random() - 0.5) * 40],
                y: [0, (Math.random() - 0.5) * 40],
                opacity: [0.3, 0.6, 0.3],
              }}
              transition={{
                duration: 3 + Math.random() * 4,
                repeat: Infinity,
                ease: 'easeInOut',
                delay: Math.random() * 2,
              }}
            />
          ))}
        </div>
      )}

      {/* Grid Pattern */}
      <div
        className="absolute inset-0 bg-grid opacity-[0.02]"
        style={{
          backgroundImage: `
            linear-gradient(rgba(245, 240, 232, 0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(245, 240, 232, 0.03) 1px, transparent 1px)
          `,
          backgroundSize: '60px 60px',
        }}
      />

      {/* Vignette Overlay */}
      <div
        className="absolute inset-0"
        style={{
          background: 'radial-gradient(ellipse at center, transparent 0%, var(--background) 100%)',
          opacity: 0.6,
        }}
      />
    </div>
  );
}
