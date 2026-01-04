'use client';

import { useQuery } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import type { UserStats } from '@/types';

function transformStats(row: any): UserStats {
  return {
    userId: row.user_id,
    lifetimeFocusSeconds: row.lifetime_focus_seconds || 0,
    lifetimeSessionCount: row.lifetime_session_count || 0,
    lifetimeBestStreak: row.lifetime_best_streak || 0,
    currentStreak: row.current_streak || 0,
    lastFocusDate: row.last_focus_date,
    totalXp: row.total_xp || 0,
    currentLevel: row.current_level || 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function useUserStats(userId?: string) {
  const supabase = createClient();

  return useQuery({
    queryKey: ['userStats', userId],
    queryFn: async () => {
      if (!userId) return null;
      
      const { data, error } = await supabase
        .from('user_stats')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error) {
        // If stats don't exist yet, return default stats
        if (error.code === 'PGRST116') {
          return {
            userId,
            lifetimeFocusSeconds: 0,
            lifetimeSessionCount: 0,
            lifetimeBestStreak: 0,
            currentStreak: 0,
            totalXp: 0,
            currentLevel: 1,
          } as UserStats;
        }
        throw error;
      }
      
      return transformStats(data);
    },
    enabled: !!userId,
    staleTime: 1000 * 60, // 1 minute
  });
}

