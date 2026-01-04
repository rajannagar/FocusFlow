'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import type { FocusSession } from '@/types';
import { useSessionsStore } from '@/stores/useSessionsStore';
import { useEffect, useRef, useMemo } from 'react';

// Transform database row to FocusSession
function transformSession(row: any): FocusSession {
  return {
    id: row.id,
    userId: row.user_id,
    startedAt: row.started_at,
    durationSeconds: row.duration_seconds,
    sessionName: row.session_name,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function useSessions(userId?: string) {
  const supabase = createClient();
  const { setSessions, setLoading } = useSessionsStore();
  const queryClient = useQueryClient();
  const lastSyncedDataRef = useRef<string | null>(null);

  const query = useQuery({
    queryKey: ['sessions', userId],
    queryFn: async () => {
      if (!userId) return [];
      
      setLoading(true);
      const { data, error } = await supabase
        .from('focus_sessions')
        .select('*')
        .eq('user_id', userId)
        .order('started_at', { ascending: false })
        .limit(100);

      if (error) throw error;
      
      const sessions = (data || []).map(transformSession);
      setLoading(false);
      return sessions;
    },
    enabled: !!userId,
    staleTime: 1000 * 30, // 30 seconds
  });

  // Memoize data to prevent unnecessary re-renders
  const sessionsData = useMemo(() => query.data || [], [query.data]);
  
  // Sync store when query data changes (only sync when data actually changes)
  useEffect(() => {
    if (sessionsData.length >= 0) {
      // Compare by creating a simple hash of the data
      const currentHash = JSON.stringify(sessionsData.map(s => ({ id: s.id, duration: s.durationSeconds })));
      const lastHash = lastSyncedDataRef.current;
      
      if (currentHash !== lastHash) {
        lastSyncedDataRef.current = currentHash;
        setSessions(sessionsData);
      }
    }
  }, [sessionsData, setSessions]);

  const addSession = useMutation({
    mutationFn: async (session: Omit<FocusSession, 'id' | 'createdAt' | 'updatedAt'>) => {
      const { data, error } = await supabase
        .from('focus_sessions')
        .insert({
          user_id: session.userId,
          started_at: session.startedAt,
          duration_seconds: session.durationSeconds,
          session_name: session.sessionName,
        })
        .select()
        .single();

      if (error) throw error;
      return transformSession(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sessions', userId] });
    },
  });

  return {
    sessions: sessionsData,
    isLoading: query.isLoading,
    error: query.error,
    addSession: addSession.mutateAsync,
  };
}

