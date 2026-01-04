'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import type { FocusPreset } from '@/types';
import { usePresetsStore } from '@/stores/usePresetsStore';
import { useEffect } from 'react';

function transformPreset(row: any): FocusPreset {
  return {
    id: row.id,
    userId: row.user_id,
    name: row.name,
    durationSeconds: row.duration_seconds,
    soundID: row.sound_id,
    emoji: row.emoji,
    isSystemDefault: row.is_system_default || false,
    themeRaw: row.theme_raw,
    externalMusicAppRaw: row.external_music_app_raw,
    ambianceModeRaw: row.ambiance_mode_raw,
  };
}

export function usePresets(userId?: string) {
  const supabase = createClient();
  const { setPresets, setLoading } = usePresetsStore();
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['presets', userId],
    queryFn: async () => {
      if (!userId) {
        // Return default presets if not logged in
        return getDefaultPresets();
      }
      
      setLoading(true);
      const { data, error } = await supabase
        .from('focus_presets')
        .select('*')
        .eq('user_id', userId)
        .order('is_system_default', { ascending: false })
        .order('name', { ascending: true });

      if (error) {
        // If table doesn't exist or error, return defaults
        console.warn('Error fetching presets:', error);
        return getDefaultPresets();
      }
      
      const presets = (data || []).map(transformPreset);
      
      // Add default presets if none exist
      if (presets.length === 0) {
        const defaults = getDefaultPresets();
        setPresets(defaults);
        setLoading(false);
        return defaults;
      }
      
      setPresets(presets);
      setLoading(false);
      return presets;
    },
    enabled: true, // Always fetch (will use defaults if no userId)
    staleTime: 1000 * 60, // 1 minute
  });

  useEffect(() => {
    if (query.data) {
      setPresets(query.data);
    }
  }, [query.data, setPresets]);

  const addPreset = useMutation({
    mutationFn: async (preset: Omit<FocusPreset, 'id' | 'userId'>) => {
      if (!userId) throw new Error('Must be logged in to create presets');
      
      const { data, error } = await supabase
        .from('focus_presets')
        .insert({
          user_id: userId,
          name: preset.name,
          duration_seconds: preset.durationSeconds,
          sound_id: preset.soundID,
          emoji: preset.emoji,
          is_system_default: preset.isSystemDefault,
          theme_raw: preset.themeRaw,
          external_music_app_raw: preset.externalMusicAppRaw,
          ambiance_mode_raw: preset.ambianceModeRaw,
        })
        .select()
        .single();

      if (error) throw error;
      return transformPreset(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['presets', userId] });
    },
  });

  return {
    presets: query.data || getDefaultPresets(),
    isLoading: query.isLoading,
    error: query.error,
    addPreset: addPreset.mutateAsync,
  };
}

// Default presets (matching iOS app defaults)
function getDefaultPresets(): FocusPreset[] {
  return [
    {
      id: 'default-25',
      name: 'Pomodoro',
      durationSeconds: 25 * 60,
      soundID: 'light-rain-ambient',
      isSystemDefault: true,
      emoji: '🍅',
    },
    {
      id: 'default-45',
      name: 'Deep Work',
      durationSeconds: 45 * 60,
      soundID: 'fireplace',
      isSystemDefault: true,
      emoji: '🔥',
    },
    {
      id: 'default-15',
      name: 'Quick Focus',
      durationSeconds: 15 * 60,
      soundID: 'sound-ambience',
      isSystemDefault: true,
      emoji: '⚡',
    },
    {
      id: 'default-60',
      name: 'Hour Focus',
      durationSeconds: 60 * 60,
      soundID: 'underwater',
      isSystemDefault: true,
      emoji: '⏰',
    },
  ];
}

