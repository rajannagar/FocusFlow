'use client';

import { useState, useEffect } from 'react';

export type DarkMode = 'dark' | 'light';

/**
 * Hook for managing dark/light mode (like main site)
 */
export function useDarkMode() {
  const [theme, setTheme] = useState<DarkMode>('dark');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    // Only run on client
    setMounted(true);
    
    // Get theme from localStorage or default to dark
    const savedTheme = localStorage.getItem('focusflow-dark-mode') as DarkMode | null;
    const initialTheme = savedTheme || 'dark';
    
    setTheme(initialTheme);
    applyTheme(initialTheme);
  }, []);

  const applyTheme = (newTheme: DarkMode) => {
    const root = document.documentElement;
    root.setAttribute('data-theme', newTheme);
    
    // Update meta theme-color for mobile browsers
    const metaThemeColor = document.querySelector('meta[name="theme-color"]');
    if (metaThemeColor) {
      metaThemeColor.setAttribute(
        'content',
        newTheme === 'dark' ? '#0A0A0B' : '#F5F0E8'
      );
    }
  };

  const toggleTheme = () => {
    const newTheme: DarkMode = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    localStorage.setItem('focusflow-dark-mode', newTheme);
    applyTheme(newTheme);
  };

  return {
    theme,
    toggleTheme,
    mounted,
  };
}

