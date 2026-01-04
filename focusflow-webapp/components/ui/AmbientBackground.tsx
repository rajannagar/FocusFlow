'use client';

import { motion } from 'framer-motion';
import { useMemo } from 'react';

export type AmbientMode =
  | 'minimal'
  | 'aurora'
  | 'rain'
  | 'stars'
  | 'ocean'
  | 'forest'
  | 'gradient-flow'
  | 'sakura'
  | 'fireplace'
  | 'snow'
  | 'clouds'
  | 'underwater';

interface AmbientBackgroundProps {
  mode: AmbientMode;
  intensity?: number; // 0-1
  className?: string;
}

export function AmbientBackground({
  mode,
  intensity = 0.7,
  className = ''
}: AmbientBackgroundProps) {
  const particles = useMemo(() => {
    const count = mode === 'stars' ? 80 : mode === 'rain' || mode === 'snow' ? 50 : mode === 'sakura' ? 30 : 0;
    return Array.from({ length: count }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      delay: Math.random() * 5,
      duration: 3 + Math.random() * 4,
      size: mode === 'stars' ? 1 + Math.random() * 2 : 4 + Math.random() * 6,
    }));
  }, [mode]);

  if (mode === 'minimal') {
    return <div className={`fixed inset-0 pointer-events-none ${className}`} />;
  }

  if (mode === 'aurora') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        <motion.div
          className="absolute inset-0"
          style={{
            background: `
              radial-gradient(ellipse at 30% 20%, rgba(139, 92, 246, ${0.2 * intensity}) 0%, transparent 50%),
              radial-gradient(ellipse at 70% 60%, rgba(52, 211, 153, ${0.15 * intensity}) 0%, transparent 50%),
              radial-gradient(ellipse at 50% 80%, rgba(212, 168, 83, ${0.1 * intensity}) 0%, transparent 50%)
            `
          }}
          animate={{
            scale: [1, 1.1, 1],
            opacity: [0.8, 1, 0.8],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </div>
    );
  }

  if (mode === 'stars') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        {particles.map((particle) => (
          <motion.div
            key={particle.id}
            className="absolute rounded-full bg-white"
            style={{
              width: particle.size,
              height: particle.size,
              left: `${particle.x}%`,
              top: `${particle.y}%`,
              opacity: 0.3 * intensity,
            }}
            animate={{
              opacity: [0.3 * intensity, 0.8 * intensity, 0.3 * intensity],
              scale: [1, 1.2, 1],
            }}
            transition={{
              duration: particle.duration,
              repeat: Infinity,
              delay: particle.delay,
              ease: 'easeInOut',
            }}
          />
        ))}
      </div>
    );
  }

  if (mode === 'rain' || mode === 'snow') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        {particles.map((particle) => (
          <motion.div
            key={particle.id}
            className="absolute rounded-full"
            style={{
              width: mode === 'rain' ? 2 : particle.size,
              height: mode === 'rain' ? 12 : particle.size,
              left: `${particle.x}%`,
              background: mode === 'rain'
                ? `linear-gradient(180deg, rgba(139, 92, 246, ${0.4 * intensity}), transparent)`
                : `rgba(255, 255, 255, ${0.6 * intensity})`,
            }}
            initial={{
              top: '-10%',
            }}
            animate={{
              top: '110%',
              x: mode === 'rain' ? [-10, 10] : [0, 20, 0],
            }}
            transition={{
              duration: particle.duration,
              repeat: Infinity,
              delay: particle.delay,
              ease: mode === 'rain' ? 'linear' : 'easeInOut',
            }}
          />
        ))}
      </div>
    );
  }

  if (mode === 'sakura') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        {particles.map((particle) => (
          <motion.div
            key={particle.id}
            className="absolute"
            style={{
              width: particle.size,
              height: particle.size,
              left: `${particle.x}%`,
            }}
            initial={{
              top: '-10%',
              rotate: 0,
            }}
            animate={{
              top: '110%',
              rotate: 360,
              x: [0, 30, -20, 40, 0],
            }}
            transition={{
              duration: particle.duration + 8,
              repeat: Infinity,
              delay: particle.delay,
              ease: 'easeInOut',
            }}
          >
            <div
              className="w-full h-full rounded-full"
              style={{
                background: `radial-gradient(circle, rgba(236, 72, 153, ${0.6 * intensity}), rgba(219, 39, 119, ${0.3 * intensity}))`,
              }}
            />
          </motion.div>
        ))}
      </div>
    );
  }

  if (mode === 'ocean') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        {[1, 2, 3].map((i) => (
          <motion.div
            key={i}
            className="absolute bottom-0 left-0 right-0"
            style={{
              height: '40%',
              background: `linear-gradient(180deg, transparent, rgba(59, 130, 246, ${0.1 * intensity * (4 - i) / 3}))`,
              borderRadius: '100% 100% 0 0',
            }}
            animate={{
              y: [0, -10, 0],
              scaleX: [1, 1.02, 1],
            }}
            transition={{
              duration: 5 + i * 2,
              repeat: Infinity,
              ease: 'easeInOut',
              delay: i * 0.5,
            }}
          />
        ))}
      </div>
    );
  }

  if (mode === 'forest') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        <motion.div
          className="absolute inset-0"
          style={{
            background: `
              radial-gradient(ellipse at 50% 100%, rgba(34, 197, 94, ${0.15 * intensity}) 0%, transparent 60%),
              radial-gradient(ellipse at 20% 50%, rgba(22, 163, 74, ${0.1 * intensity}) 0%, transparent 50%),
              radial-gradient(ellipse at 80% 40%, rgba(21, 128, 61, ${0.08 * intensity}) 0%, transparent 50%)
            `
          }}
          animate={{
            opacity: [0.8, 1, 0.8],
          }}
          transition={{
            duration: 8,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </div>
    );
  }

  if (mode === 'gradient-flow') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        <motion.div
          className="absolute inset-0"
          style={{
            background: `
              linear-gradient(135deg,
                rgba(139, 92, 246, ${0.15 * intensity}) 0%,
                rgba(236, 72, 153, ${0.12 * intensity}) 25%,
                rgba(59, 130, 246, ${0.1 * intensity}) 50%,
                rgba(212, 168, 83, ${0.12 * intensity}) 75%,
                rgba(139, 92, 246, ${0.15 * intensity}) 100%
              )
            `,
            backgroundSize: '400% 400%',
          }}
          animate={{
            backgroundPosition: ['0% 50%', '100% 50%', '0% 50%'],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: 'linear',
          }}
        />
      </div>
    );
  }

  if (mode === 'fireplace') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        <motion.div
          className="absolute bottom-0 left-0 right-0 h-1/2"
          style={{
            background: `
              radial-gradient(ellipse at 50% 100%, rgba(251, 146, 60, ${0.2 * intensity}) 0%, transparent 60%),
              radial-gradient(ellipse at 30% 90%, rgba(249, 115, 22, ${0.15 * intensity}) 0%, transparent 50%),
              radial-gradient(ellipse at 70% 85%, rgba(234, 88, 12, ${0.1 * intensity}) 0%, transparent 50%)
            `
          }}
          animate={{
            opacity: [0.8, 1, 0.85, 1, 0.8],
            scale: [1, 1.05, 0.98, 1.02, 1],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </div>
    );
  }

  if (mode === 'clouds') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        {[1, 2, 3, 4].map((i) => (
          <motion.div
            key={i}
            className="absolute rounded-full blur-3xl"
            style={{
              width: `${150 + i * 50}px`,
              height: `${80 + i * 30}px`,
              background: `rgba(255, 255, 255, ${0.03 * intensity})`,
              top: `${10 + i * 20}%`,
              left: `${i * 15}%`,
            }}
            animate={{
              x: [-100, 100],
            }}
            transition={{
              duration: 30 + i * 10,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        ))}
      </div>
    );
  }

  if (mode === 'underwater') {
    return (
      <div className={`fixed inset-0 pointer-events-none overflow-hidden ${className}`}>
        <motion.div
          className="absolute inset-0"
          style={{
            background: `
              radial-gradient(ellipse at 50% 30%, rgba(6, 182, 212, ${0.15 * intensity}) 0%, transparent 60%),
              radial-gradient(ellipse at 80% 70%, rgba(14, 165, 233, ${0.1 * intensity}) 0%, transparent 50%)
            `
          }}
          animate={{
            y: [-20, 20, -20],
            opacity: [0.8, 1, 0.8],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
        {/* Bubbles */}
        {Array.from({ length: 15 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full"
            style={{
              width: 8 + Math.random() * 12,
              height: 8 + Math.random() * 12,
              background: `rgba(255, 255, 255, ${0.2 * intensity})`,
              left: `${Math.random() * 100}%`,
            }}
            initial={{
              bottom: '-5%',
            }}
            animate={{
              bottom: '105%',
              x: [0, 20, -10, 15, 0],
            }}
            transition={{
              duration: 6 + Math.random() * 4,
              repeat: Infinity,
              delay: Math.random() * 5,
              ease: 'easeInOut',
            }}
          />
        ))}
      </div>
    );
  }

  return null;
}
