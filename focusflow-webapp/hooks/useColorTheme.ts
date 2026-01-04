'use client';

import { useState, useEffect, useCallback } from 'react';
import { AppTheme, themes, defaultTheme } from '@/lib/themes';

/**
 * Hook for managing color themes (forest, neon, etc.)
 * Only affects accent colors, not backgrounds
 */
export function useColorTheme() {
  const [colorTheme, setColorTheme] = useState<AppTheme>(defaultTheme);
  const [mounted, setMounted] = useState(false);

  // Apply color theme to document (only accent colors)
  const applyColorTheme = useCallback((newTheme: AppTheme) => {
    if (typeof window === 'undefined') return;
    
    const themeColors = themes[newTheme];
    if (!themeColors) return;
    
    const root = document.documentElement;
    
    // Only override accent colors, NOT backgrounds
    root.style.setProperty('--accent-primary', themeColors.accentPrimary);
    root.style.setProperty('--accent-secondary', themeColors.accentSecondary);
    
    // Calculate lighter/darker variants for better contrast
    root.style.setProperty('--accent-primary-light', themeColors.accentPrimary);
    root.style.setProperty('--accent-primary-dark', themeColors.accentPrimary);
    root.style.setProperty('--accent-secondary-light', themeColors.accentSecondary);
    
    // Update accent glow to use theme color
    const isDark = root.getAttribute('data-theme') === 'dark';
    root.style.setProperty('--accent-glow', isDark 
      ? `${themeColors.accentPrimary}40`
      : `${themeColors.accentPrimary}25`
    );
    
    // Store in localStorage
    try {
      localStorage.setItem('focusflow-color-theme', newTheme);
    } catch (e) {
      console.warn('Failed to save color theme to localStorage:', e);
    }
  }, []);

  // Load color theme from localStorage on mount
  useEffect(() => {
    if (typeof window === 'undefined') return;
    
    try {
      const savedTheme = localStorage.getItem('focusflow-color-theme') as AppTheme | null;
      const themeToApply = (savedTheme && themes[savedTheme]) ? savedTheme : defaultTheme;
      
      setColorTheme(themeToApply);
      applyColorTheme(themeToApply);
      setMounted(true);
    } catch (e) {
      console.warn('Failed to load color theme from localStorage:', e);
      applyColorTheme(defaultTheme);
      setMounted(true);
    }
  }, [applyColorTheme]);

  // Change color theme
  const changeColorTheme = useCallback((newTheme: AppTheme) => {
    if (!themes[newTheme]) {
      console.warn('Invalid color theme:', newTheme);
      return;
    }
    
    setColorTheme(newTheme);
    applyColorTheme(newTheme);
  }, [applyColorTheme]);

  return {
    colorTheme,
    changeColorTheme,
    themes: Object.keys(themes) as AppTheme[],
    mounted,
  };
}

