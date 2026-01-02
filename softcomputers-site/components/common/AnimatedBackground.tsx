'use client';

import { useThrottledMouse } from '@/hooks/useThrottledMouse';

interface AnimatedBackgroundProps {
  /** Show the grid pattern overlay */
  showGrid?: boolean;
  /** Variant of the background style */
  variant?: 'aurora' | 'mesh' | 'subtle';
  /** Custom class names */
  className?: string;
}

/**
 * Reusable animated background with mouse-following gradient orbs
 * Used across hero sections for visual consistency
 */
export default function AnimatedBackground({ 
  showGrid = true, 
  variant = 'aurora',
  className = '' 
}: AnimatedBackgroundProps) {
  const mousePosition = useThrottledMouse();

  return (
    <>
      {/* Aurora background with animated orbs */}
      <div className={`absolute inset-0 ${variant === 'aurora' ? 'bg-aurora' : variant === 'mesh' ? 'bg-mesh' : ''} ${className}`}>
        {/* Primary gradient orb - purple */}
        <div 
          className="absolute top-1/4 left-1/4 w-[300px] md:w-[600px] h-[300px] md:h-[600px] rounded-full blur-[60px] md:blur-[80px] opacity-25 md:opacity-30 transition-transform duration-1000 ease-out"
          style={{
            background: `radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)`,
            transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            willChange: 'transform',
          }}
        />
        {/* Secondary gradient orb - gold */}
        <div 
          className="absolute bottom-1/4 right-1/4 w-[250px] md:w-[500px] h-[250px] md:h-[500px] rounded-full blur-[40px] md:blur-[60px] opacity-15 md:opacity-20 transition-transform duration-1000 ease-out"
          style={{
            background: `radial-gradient(circle, rgba(212, 168, 83, 0.3) 0%, transparent 70%)`,
            transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
            willChange: 'transform',
          }}
        />
      </div>

      {/* Grid pattern overlay */}
      {showGrid && (
        <div className="absolute inset-0 bg-grid opacity-30" />
      )}
    </>
  );
}

