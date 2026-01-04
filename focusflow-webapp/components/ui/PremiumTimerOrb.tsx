'use client';

import { motion } from 'framer-motion';

interface PremiumTimerOrbProps {
  progress: number; // 0 to 1
  timeDisplay: string;
  status: string;
  isRunning: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export function PremiumTimerOrb({
  progress,
  timeDisplay,
  status,
  isRunning,
  size = 'lg'
}: PremiumTimerOrbProps) {
  const sizeMap = {
    sm: { container: 200, svg: 200, r: 90, strokeWidth: 6, fontSize: '3rem' },
    md: { container: 280, svg: 280, r: 130, strokeWidth: 7, fontSize: '4rem' },
    lg: { container: 384, svg: 384, r: 180, strokeWidth: 8, fontSize: '5rem' },
    xl: { container: 480, svg: 480, r: 225, strokeWidth: 9, fontSize: '6.5rem' }
  };

  const config = sizeMap[size];
  const circumference = 2 * Math.PI * config.r;
  const offset = circumference - progress * circumference;

  return (
    <div className="relative flex items-center justify-center">
      {/* Outer breathing glow */}
      <motion.div
        className="absolute rounded-full blur-[60px]"
        style={{
          width: config.container + 80,
          height: config.container + 80,
          background: 'radial-gradient(circle, var(--accent-primary) 0%, transparent 70%)',
          opacity: isRunning ? 0.25 : 0.15,
        }}
        animate={isRunning ? {
          scale: [1, 1.1, 1],
          opacity: [0.25, 0.35, 0.25],
        } : {}}
        transition={{
          duration: 2.4,
          repeat: isRunning ? Infinity : 0,
          ease: 'easeInOut',
        }}
      />

      {/* Main orb container */}
      <motion.div
        className="relative"
        style={{
          width: config.container,
          height: config.container,
        }}
        animate={isRunning ? {
          scale: [0.98, 1.02, 0.98],
        } : {}}
        transition={{
          duration: 2.4,
          repeat: isRunning ? Infinity : 0,
          ease: 'easeInOut',
        }}
      >
        {/* Rotating ring background */}
        <motion.div
          className="absolute inset-0"
          animate={{
            rotate: 360,
          }}
          transition={{
            duration: 16,
            repeat: Infinity,
            ease: 'linear',
          }}
        >
          <svg
            width={config.svg}
            height={config.svg}
            viewBox={`0 0 ${config.svg} ${config.svg}`}
            className="transform -rotate-90"
          >
            <defs>
              {/* Angular gradient for rotating ring */}
              <linearGradient id="rotatingRingGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="var(--accent-primary)" stopOpacity="0.3" />
                <stop offset="50%" stopColor="var(--accent-secondary)" stopOpacity="0.2" />
                <stop offset="100%" stopColor="var(--accent-primary)" stopOpacity="0.3" />
              </linearGradient>
            </defs>

            {/* Background track ring */}
            <circle
              cx={config.svg / 2}
              cy={config.svg / 2}
              r={config.r}
              fill="none"
              stroke="rgba(245, 240, 232, 0.05)"
              strokeWidth={config.strokeWidth + 2}
            />

            {/* Rotating decorative ring */}
            <circle
              cx={config.svg / 2}
              cy={config.svg / 2}
              r={config.r}
              fill="none"
              stroke="url(#rotatingRingGradient)"
              strokeWidth={config.strokeWidth}
              strokeLinecap="round"
              strokeDasharray={`${circumference * 0.15} ${circumference * 0.85}`}
            />
          </svg>
        </motion.div>

        {/* Progress ring */}
        <svg
          width={config.svg}
          height={config.svg}
          viewBox={`0 0 ${config.svg} ${config.svg}`}
          className="absolute inset-0 transform -rotate-90"
        >
          <defs>
            {/* Progress gradient */}
            <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="var(--accent-primary)" />
              <stop offset="100%" stopColor="var(--accent-secondary)" />
            </linearGradient>

            {/* Glow filter */}
            <filter id="glow">
              <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
              <feMerge>
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          </defs>

          {/* Background track */}
          <circle
            cx={config.svg / 2}
            cy={config.svg / 2}
            r={config.r}
            fill="none"
            stroke="rgba(255, 255, 255, 0.08)"
            strokeWidth={config.strokeWidth}
          />

          {/* Progress circle */}
          <motion.circle
            cx={config.svg / 2}
            cy={config.svg / 2}
            r={config.r}
            fill="none"
            stroke="url(#progressGradient)"
            strokeWidth={config.strokeWidth}
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            filter="url(#glow)"
            initial={{ strokeDashoffset: circumference }}
            animate={{ strokeDashoffset: offset }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
          />
        </svg>

        {/* Inner orb with time display */}
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{
            margin: config.strokeWidth * 2,
          }}
        >
          <div
            className="w-full h-full rounded-full flex items-center justify-center relative overflow-hidden"
            style={{
              background: 'linear-gradient(135deg, rgba(17, 17, 19, 0.95) 0%, rgba(24, 24, 27, 0.95) 100%)',
              border: '1px solid rgba(139, 92, 246, 0.3)',
              boxShadow: 'inset 0 0 60px rgba(139, 92, 246, 0.1), 0 8px 32px rgba(0, 0, 0, 0.3)',
            }}
          >
            {/* Inner gradient glow */}
            <div
              className="absolute inset-0"
              style={{
                background: 'radial-gradient(circle at center, rgba(139, 92, 246, 0.15) 0%, transparent 70%)',
              }}
            />

            {/* Time display */}
            <div className="relative z-10 text-center">
              <motion.div
                key={timeDisplay}
                initial={{ scale: 1.05, opacity: 0.8 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.2 }}
                className="font-bold tabular-nums"
                style={{
                  fontSize: config.fontSize,
                  background: 'linear-gradient(135deg, var(--accent-primary), var(--accent-secondary), var(--accent-primary))',
                  backgroundSize: '200% 100%',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  filter: 'brightness(1.2)',
                  animation: 'gradient 3s ease infinite',
                }}
              >
                {timeDisplay}
              </motion.div>

              <motion.div
                className="text-sm md:text-base text-[var(--foreground-muted)] mt-2 font-medium uppercase tracking-wider"
                animate={{ opacity: isRunning ? [1, 0.5, 1] : 1 }}
                transition={{ duration: 2, repeat: isRunning ? Infinity : 0 }}
                style={{
                  fontSize: size === 'sm' ? '0.7rem' : size === 'md' ? '0.8rem' : '0.9rem',
                }}
              >
                {status}
              </motion.div>
            </div>
          </div>
        </div>

        {/* Border highlight */}
        <div
          className="absolute inset-0 rounded-full pointer-events-none"
          style={{
            boxShadow: 'inset 0 0 0 1px rgba(139, 92, 246, 0.2)',
            margin: config.strokeWidth * 2,
          }}
        />
      </motion.div>
    </div>
  );
}
