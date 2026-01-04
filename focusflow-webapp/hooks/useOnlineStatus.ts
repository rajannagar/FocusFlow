'use client';

import { useEffect } from 'react';
import { useSyncStore } from '@/stores/useSyncStore';

/**
 * Monitors online/offline status and updates sync store
 */
export function useOnlineStatus() {
  const { setOnline } = useSyncStore();

  useEffect(() => {
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);

    // Set initial state
    setOnline(navigator.onLine);

    // Listen for changes
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [setOnline]);
}

