'use client';

import { useState } from 'react';
import Image from 'next/image';

interface iPhoneSimulatorProps {
  screenshots?: string[];
  screenData?: Array<{ icon: string; title: string; desc: string; gradient: string }>;
}

export default function iPhoneSimulator({ 
  screenshots = [], 
  screenData = [
    { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-violet-500 to-purple-600' },
    { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-emerald-500 to-teal-600' },
    { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-amber-500 to-orange-600' },
    { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-rose-500 to-pink-600' },
  ]
}: iPhoneSimulatorProps) {
  const [currentScreen, setCurrentScreen] = useState(0);
  const [imageError, setImageError] = useState<Record<number, boolean>>({});

  const defaultScreens = [
    '/images/screen-focus.png',
    '/images/screen-tasks.png',
    '/images/screen-progress.png',
    '/images/screen-profile.png',
  ];

  const screens = screenshots.length > 0 ? screenshots : defaultScreens;
  const displayData = screenData.length > 0 ? screenData : [
    { icon: '⏱️', title: 'FocusFlow', desc: 'Be Present', gradient: 'from-violet-500 to-purple-600' },
  ];

  const handleImageError = (index: number) => {
    setImageError(prev => ({ ...prev, [index]: true }));
  };

  const showFallback = imageError[currentScreen] || !screens.length || !screens[currentScreen];

  return (
    <div className="relative animate-float">
      {/* iPhone Frame */}
      <div className="relative mx-auto" style={{ width: '340px', maxWidth: '100%' }}>
        {/* Glow effect behind phone */}
        <div className="absolute inset-0 blur-3xl opacity-30" style={{
          background: `linear-gradient(135deg, var(--accent-primary) 0%, var(--accent-secondary) 100%)`,
          transform: 'scale(0.9)',
        }} />
        
        {/* iPhone Outer Frame - Premium titanium look */}
        <div className="relative bg-gradient-to-b from-[#2A2A2E] via-[#1C1C1E] to-[#0A0A0B] rounded-[3.5rem] p-[10px] shadow-2xl" style={{ 
          boxShadow: '0 30px 60px -15px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.08) inset, 0 0 60px rgba(139, 92, 246, 0.1)'
        }}>
          {/* Side buttons - Volume */}
          <div className="absolute -left-[3px] top-32 w-[3px] h-8 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-l-sm" />
          <div className="absolute -left-[3px] top-44 w-[3px] h-8 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-l-sm" />
          {/* Side button - Power */}
          <div className="absolute -right-[3px] top-36 w-[3px] h-12 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-r-sm" />
          
          {/* Screen Bezel */}
          <div className="bg-[#0A0A0B] rounded-[3rem] p-[5px] overflow-hidden">
            {/* Dynamic Island */}
            <div className="absolute top-[14px] left-1/2 transform -translate-x-1/2 w-28 h-[26px] bg-black rounded-full z-20" style={{
              boxShadow: '0 0 0 2px rgba(30, 30, 32, 0.8) inset'
            }} />
            
            {/* Screen */}
            <div className="relative bg-black rounded-[2.5rem] overflow-hidden" style={{ aspectRatio: '9/19.5' }}>
              {!showFallback ? (
                <div className="relative w-full h-full bg-black">
                  <Image
                    src={screens[currentScreen]}
                    alt={`FocusFlow screen ${currentScreen + 1}`}
                    fill
                    className="object-cover"
                    priority={currentScreen === 0}
                    quality={95}
                    onError={() => handleImageError(currentScreen)}
                    sizes="340px"
                  />
                </div>
              ) : (
                <div className={`w-full h-full bg-gradient-to-br ${displayData[currentScreen]?.gradient || 'from-violet-500 to-purple-600'} flex items-center justify-center`}>
                  <div className="text-center text-white p-8">
                    <div className="text-5xl mb-4">{displayData[currentScreen]?.icon || '⏱️'}</div>
                    <div className="text-xl font-semibold mb-1">{displayData[currentScreen]?.title || 'FocusFlow'}</div>
                    <div className="text-sm opacity-80">{displayData[currentScreen]?.desc || 'Focus Timer'}</div>
                  </div>
                </div>
              )}
              
              {/* Home indicator */}
              <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-white/30 rounded-full" />
            </div>
          </div>
        </div>

        {/* Screen Navigation Dots */}
        {screens.length > 1 && (
          <div className="flex justify-center gap-2 mt-8">
            {screens.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentScreen(index)}
                className={`h-2 rounded-full transition-all duration-300 ${
                  index === currentScreen 
                    ? 'w-8 bg-[var(--accent-primary)]' 
                    : 'w-2 bg-[var(--foreground-subtle)] hover:bg-[var(--foreground-muted)]'
                }`}
                aria-label={`View screen ${index + 1}`}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
