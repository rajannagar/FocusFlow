'use client';

import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';

// All 14 ambient backgrounds from iOS app
export type AmbientMode = 
  | 'none'
  | 'minimal'
  | 'aurora'
  | 'rain'
  | 'fireplace'
  | 'ocean'
  | 'forest'
  | 'stars'
  | 'gradientFlow'
  | 'snow'
  | 'underwater'
  | 'clouds'
  | 'sakura'
  | 'lightning'
  | 'lavaLamp';

interface AmbientBackgroundProps {
  mode: AmbientMode;
  isActive: boolean;
  intensity?: number; // 0.0 to 1.0
}

export default function AmbientBackground({ 
  mode, 
  isActive, 
  intensity = 0.7 
}: AmbientBackgroundProps) {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (!isActive || mode === 'none') return;

    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({
        x: (e.clientX / window.innerWidth - 0.5) * 2,
        y: (e.clientY / window.innerHeight - 0.5) * 2,
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, [isActive, mode]);

  if (mode === 'none' || !isActive) {
    return null;
  }

  const baseStyles: Record<AmbientMode, string> = {
    none: '',
    minimal: 'bg-gradient-to-br from-[var(--background)] via-[var(--background-elevated)] to-[var(--background)]',
    aurora: 'bg-gradient-to-br from-emerald-900 via-cyan-900 to-purple-900',
    ocean: 'bg-gradient-to-br from-blue-600 via-cyan-600 to-teal-700',
    forest: 'bg-gradient-to-br from-green-800 via-emerald-700 to-teal-800',
    rain: 'bg-gradient-to-br from-slate-600 via-slate-700 to-slate-800',
    fireplace: 'bg-gradient-to-br from-orange-900 via-red-900 to-amber-900',
    stars: 'bg-gradient-to-br from-indigo-950 via-purple-950 to-black',
    gradientFlow: 'bg-gradient-to-br from-pink-600 via-purple-600 to-indigo-600',
    snow: 'bg-gradient-to-br from-slate-300 via-blue-100 to-cyan-200',
    underwater: 'bg-gradient-to-br from-blue-800 via-cyan-800 to-teal-900',
    clouds: 'bg-gradient-to-br from-sky-400 via-blue-300 to-indigo-400',
    sakura: 'bg-gradient-to-br from-pink-300 via-rose-200 to-purple-200',
    lightning: 'bg-gradient-to-br from-yellow-900 via-amber-800 to-orange-900',
    lavaLamp: 'bg-gradient-to-br from-purple-900 via-pink-800 to-red-900',
  };

  const opacity = isActive ? intensity : 0;

  return (
    <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
      <div 
        className={`absolute inset-0 ${baseStyles[mode]} transition-opacity duration-1000`}
        style={{ opacity }}
      />
      
      {/* Animated gradient overlay */}
      <motion.div
        className="absolute inset-0"
        style={{
          opacity: intensity * 0.3,
          background: getGradientAnimation(mode),
        }}
        animate={{
          background: getGradientAnimation(mode),
        }}
        transition={{
          duration: 8,
          repeat: Infinity,
          repeatType: 'reverse',
        }}
      />

      {/* Parallax particles */}
      {mode !== 'minimal' && (
        <>
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full opacity-20 blur-3xl"
              style={{
                width: `${100 + i * 50}px`,
                height: `${100 + i * 50}px`,
                background: getParticleColor(mode, i),
                left: `${20 + i * 15}%`,
                top: `${10 + i * 20}%`,
              }}
              animate={{
                x: mousePosition.x * (20 + i * 10),
                y: mousePosition.y * (20 + i * 10),
                scale: [1, 1.2, 1],
              }}
              transition={{
                duration: 3 + i * 0.5,
                repeat: Infinity,
                repeatType: 'reverse',
                ease: 'easeInOut',
              }}
            />
          ))}
        </>
      )}

      {/* Mode-specific effects */}
      {mode === 'rain' && <RainEffect intensity={intensity} />}
      {mode === 'stars' && <StarsEffect intensity={intensity} />}
      {mode === 'fireplace' && <FireplaceEffect intensity={intensity} />}
      {mode === 'snow' && <SnowEffect intensity={intensity} />}
      {mode === 'aurora' && <AuroraEffect intensity={intensity} />}
      {mode === 'lightning' && <LightningEffect intensity={intensity} />}
      {mode === 'sakura' && <SakuraEffect intensity={intensity} />}
    </div>
  );
}

// Rain Effect
function RainEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity * 0.4 }}>
      {[...Array(50)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-0.5 bg-white/40"
          style={{
            left: `${(i * 2) % 100}%`,
            top: '-10px',
            height: '20px',
          }}
          animate={{
            y: typeof window !== 'undefined' ? window.innerHeight + 20 : 1000,
          }}
          transition={{
            duration: 0.5 + Math.random() * 0.5,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: 'linear',
          }}
        />
      ))}
    </div>
  );
}

// Stars Effect
function StarsEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity }}>
      {[...Array(30)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-1 h-1 bg-white rounded-full"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            opacity: Math.random() * 0.8 + 0.2,
          }}
          animate={{
            opacity: [0.2, 1, 0.2],
            scale: [0.5, 1, 0.5],
          }}
          transition={{
            duration: 2 + Math.random() * 3,
            repeat: Infinity,
            delay: Math.random() * 2,
          }}
        />
      ))}
    </div>
  );
}

// Fireplace Effect
function FireplaceEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity * 0.5 }}>
      {[...Array(8)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute rounded-full opacity-30 blur-xl"
          style={{
            width: `${80 + i * 20}px`,
            height: `${80 + i * 20}px`,
            background: `radial-gradient(circle, rgba(255, ${100 + i * 20}, 0, 0.8), transparent)`,
            bottom: '10%',
            left: `${40 + i * 5}%`,
          }}
          animate={{
            y: [0, -20, 0],
            scale: [1, 1.1, 1],
            opacity: [0.2, 0.4, 0.2],
          }}
          transition={{
            duration: 2 + Math.random(),
            repeat: Infinity,
            delay: i * 0.3,
          }}
        />
      ))}
    </div>
  );
}

// Snow Effect
function SnowEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity * 0.6 }}>
      {[...Array(40)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-2 h-2 bg-white rounded-full"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10px',
            opacity: Math.random() * 0.5 + 0.3,
          }}
          animate={{
            y: typeof window !== 'undefined' ? window.innerHeight + 20 : 1000,
            x: [0, Math.random() * 50 - 25, 0],
          }}
          transition={{
            duration: 3 + Math.random() * 2,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: 'linear',
          }}
        />
      ))}
    </div>
  );
}

// Aurora Effect
function AuroraEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity }}>
      {[...Array(5)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-full h-32 blur-2xl"
          style={{
            background: `linear-gradient(90deg, 
              ${i === 0 ? 'rgba(34, 197, 94, 0.4)' : ''}
              ${i === 1 ? 'rgba(6, 182, 212, 0.4)' : ''}
              ${i === 2 ? 'rgba(139, 92, 246, 0.4)' : ''}
              ${i === 3 ? 'rgba(236, 72, 153, 0.4)' : ''}
              ${i === 4 ? 'rgba(59, 130, 246, 0.4)' : ''}
              transparent)`,
            top: `${20 + i * 15}%`,
          }}
          animate={{
            x: [-100, 100, -100],
            opacity: [0.3, 0.6, 0.3],
          }}
          transition={{
            duration: 8 + i * 2,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      ))}
    </div>
  );
}

// Lightning Effect
function LightningEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity * 0.3 }}>
      {[...Array(3)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-1 bg-yellow-300 blur-sm"
          style={{
            left: `${30 + i * 20}%`,
            top: '0%',
            height: '100%',
            opacity: 0,
          }}
          animate={{
            opacity: [0, 1, 0],
          }}
          transition={{
            duration: 0.1,
            repeat: Infinity,
            delay: 3 + i * 2 + Math.random() * 2,
            repeatDelay: 5 + Math.random() * 3,
          }}
        />
      ))}
    </div>
  );
}

// Sakura Effect
function SakuraEffect({ intensity }: { intensity: number }) {
  return (
    <div className="absolute inset-0" style={{ opacity: intensity * 0.5 }}>
      {[...Array(20)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute text-2xl"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10px',
          }}
          animate={{
            y: typeof window !== 'undefined' ? window.innerHeight + 20 : 1000,
            x: [0, Math.random() * 100 - 50, 0],
            rotate: [0, 360],
          }}
          transition={{
            duration: 5 + Math.random() * 3,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: 'linear',
          }}
        >
          🌸
        </motion.div>
      ))}
    </div>
  );
}

function getGradientAnimation(mode: AmbientMode): string {
  const gradients: Record<AmbientMode, string> = {
    none: '',
    minimal: '',
    aurora: 'radial-gradient(circle at 30% 50%, rgba(34, 197, 94, 0.5), transparent 50%), radial-gradient(circle at 70% 50%, rgba(6, 182, 212, 0.5), transparent 50%)',
    ocean: 'radial-gradient(circle at 30% 50%, rgba(59, 130, 246, 0.5), transparent 50%), radial-gradient(circle at 70% 50%, rgba(6, 182, 212, 0.5), transparent 50%)',
    forest: 'radial-gradient(circle at 30% 50%, rgba(34, 197, 94, 0.5), transparent 50%), radial-gradient(circle at 70% 50%, rgba(20, 184, 166, 0.5), transparent 50%)',
    rain: 'radial-gradient(circle at 50% 50%, rgba(71, 85, 105, 0.4), transparent 70%)',
    fireplace: 'radial-gradient(circle at 50% 80%, rgba(251, 146, 60, 0.6), transparent 60%)',
    stars: 'radial-gradient(circle at 50% 50%, rgba(99, 102, 241, 0.3), transparent 70%)',
    gradientFlow: 'radial-gradient(circle at 30% 50%, rgba(236, 72, 153, 0.5), transparent 50%), radial-gradient(circle at 70% 50%, rgba(139, 92, 246, 0.5), transparent 50%)',
    snow: 'radial-gradient(circle at 50% 50%, rgba(147, 197, 253, 0.4), transparent 70%)',
    underwater: 'radial-gradient(circle at 50% 50%, rgba(14, 165, 233, 0.5), transparent 70%)',
    clouds: 'radial-gradient(circle at 30% 30%, rgba(147, 197, 253, 0.4), transparent 50%), radial-gradient(circle at 70% 70%, rgba(191, 219, 254, 0.4), transparent 50%)',
    sakura: 'radial-gradient(circle at 30% 50%, rgba(251, 113, 133, 0.3), transparent 50%), radial-gradient(circle at 70% 50%, rgba(196, 181, 253, 0.3), transparent 50%)',
    lightning: 'radial-gradient(circle at 50% 50%, rgba(251, 191, 36, 0.4), transparent 70%)',
    lavaLamp: 'radial-gradient(circle at 30% 50%, rgba(168, 85, 247, 0.5), transparent 50%), radial-gradient(circle at 70% 50%, rgba(236, 72, 153, 0.5), transparent 50%)',
  };
  return gradients[mode];
}

function getParticleColor(mode: AmbientMode, index: number): string {
  const colors: Record<AmbientMode, string[]> = {
    none: [],
    minimal: [],
    aurora: ['rgba(34, 197, 94, 0.4)', 'rgba(6, 182, 212, 0.4)', 'rgba(139, 92, 246, 0.4)'],
    ocean: ['rgba(59, 130, 246, 0.4)', 'rgba(6, 182, 212, 0.4)', 'rgba(14, 165, 233, 0.4)'],
    forest: ['rgba(34, 197, 94, 0.4)', 'rgba(20, 184, 166, 0.4)', 'rgba(5, 150, 105, 0.4)'],
    rain: ['rgba(148, 163, 184, 0.3)', 'rgba(100, 116, 139, 0.3)', 'rgba(71, 85, 105, 0.3)'],
    fireplace: ['rgba(251, 146, 60, 0.4)', 'rgba(239, 68, 68, 0.4)', 'rgba(245, 158, 11, 0.4)'],
    stars: ['rgba(99, 102, 241, 0.3)', 'rgba(139, 92, 246, 0.3)', 'rgba(79, 70, 229, 0.3)'],
    gradientFlow: ['rgba(236, 72, 153, 0.4)', 'rgba(139, 92, 246, 0.4)', 'rgba(99, 102, 241, 0.4)'],
    snow: ['rgba(255, 255, 255, 0.3)', 'rgba(191, 219, 254, 0.3)', 'rgba(147, 197, 253, 0.3)'],
    underwater: ['rgba(14, 165, 233, 0.4)', 'rgba(6, 182, 212, 0.4)', 'rgba(8, 145, 178, 0.4)'],
    clouds: ['rgba(147, 197, 253, 0.3)', 'rgba(191, 219, 254, 0.3)', 'rgba(59, 130, 246, 0.3)'],
    sakura: ['rgba(251, 113, 133, 0.3)', 'rgba(196, 181, 253, 0.3)', 'rgba(167, 139, 250, 0.3)'],
    lightning: ['rgba(251, 191, 36, 0.4)', 'rgba(245, 158, 11, 0.4)', 'rgba(217, 119, 6, 0.4)'],
    lavaLamp: ['rgba(168, 85, 247, 0.4)', 'rgba(236, 72, 153, 0.4)', 'rgba(219, 39, 119, 0.4)'],
  };
  return colors[mode]?.[index % (colors[mode]?.length || 1)] || colors[mode]?.[0] || 'rgba(255, 255, 255, 0.1)';
}
