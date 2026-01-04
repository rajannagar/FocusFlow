'use client';

import { useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useAuthStore } from '@/stores/useAuthStore';

/**
 * Syncs AuthContext with Zustand auth store
 * This ensures both systems stay in sync
 */
export function useSyncAuth() {
  const { user, session, loading } = useAuth();
  const { setUser, setSession, setLoading } = useAuthStore();

  useEffect(() => {
    setUser(user);
    setSession(session);
    setLoading(loading);
  }, [user, session, loading, setUser, setSession, setLoading]);
}

