'use client';

import { useState, useEffect, useCallback } from 'react';
import { AppTheme, themes, defaultTheme } from '@/lib/themes';

/**
 * Hook for managing color themes (forest, neon, etc.)
 * Only affects accent colors, not backgrounds - keeps main website aesthetic
 */
export function useColorTheme() {
  const [colorTheme, setColorTheme] = useState<AppTheme>(defaultTheme);
  const [mounted, setMounted] = useState(false);

  // Apply color theme to document (only accent colors, with premium effects)
  const applyColorTheme = useCallback((newTheme: AppTheme) => {
    if (typeof window === 'undefined') return;
    
    const themeColors = themes[newTheme];
    if (!themeColors) return;
    
    const root = document.documentElement;
    const isDark = root.getAttribute('data-theme') === 'dark';
    
    // Extract RGB values from theme colors for calculations
    const extractRGB = (rgbString: string): [number, number, number] => {
      const match = rgbString.match(/\d+/g);
      if (match && match.length >= 3) {
        return [parseInt(match[0]), parseInt(match[1]), parseInt(match[2])];
      }
      return [139, 92, 246]; // fallback to default purple
    };
    
    const [r1, g1, b1] = extractRGB(themeColors.accentPrimary);
    const [r2, g2, b2] = extractRGB(themeColors.accentSecondary);
    
    // Apply primary accent color
    root.style.setProperty('--accent-primary', themeColors.accentPrimary);
    
    // Calculate lighter variant (20% lighter)
    const lightR = Math.min(255, Math.round(r1 + (255 - r1) * 0.2));
    const lightG = Math.min(255, Math.round(g1 + (255 - g1) * 0.2));
    const lightB = Math.min(255, Math.round(b1 + (255 - b1) * 0.2));
    root.style.setProperty('--accent-primary-light', `rgb(${lightR}, ${lightG}, ${lightB})`);
    
    // Calculate darker variant (20% darker)
    const darkR = Math.max(0, Math.round(r1 * 0.8));
    const darkG = Math.max(0, Math.round(g1 * 0.8));
    const darkB = Math.max(0, Math.round(b1 * 0.8));
    root.style.setProperty('--accent-primary-dark', `rgb(${darkR}, ${darkG}, ${darkB})`);
    
    // Apply secondary accent color
    root.style.setProperty('--accent-secondary', themeColors.accentSecondary);
    
    // Calculate lighter variant for secondary
    const lightR2 = Math.min(255, Math.round(r2 + (255 - r2) * 0.2));
    const lightG2 = Math.min(255, Math.round(g2 + (255 - g2) * 0.2));
    const lightB2 = Math.min(255, Math.round(b2 + (255 - b2) * 0.2));
    root.style.setProperty('--accent-secondary-light', `rgb(${lightR2}, ${lightG2}, ${lightB2})`);
    
    // Premium glow effects - theme-aware with opacity based on dark/light mode
    const glowOpacity = isDark ? 0.4 : 0.25;
    root.style.setProperty('--accent-glow', `rgba(${r1}, ${g1}, ${b1}, ${glowOpacity})`);
    root.style.setProperty('--accent-glow-strong', `rgba(${r1}, ${g1}, ${b1}, ${glowOpacity * 1.5})`);
    root.style.setProperty('--accent-glow-subtle', `rgba(${r1}, ${g1}, ${b1}, ${glowOpacity * 0.5})`);
    
    // Secondary glow
    root.style.setProperty('--accent-secondary-glow', `rgba(${r2}, ${g2}, ${b2}, ${glowOpacity * 0.8})`);
    
    // Gradient combinations for premium effects
    root.style.setProperty('--accent-gradient', `linear-gradient(135deg, ${themeColors.accentPrimary}, ${themeColors.accentSecondary})`);
    root.style.setProperty('--accent-gradient-reverse', `linear-gradient(135deg, ${themeColors.accentSecondary}, ${themeColors.accentPrimary})`);
    
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
