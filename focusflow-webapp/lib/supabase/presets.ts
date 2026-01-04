import { createClient } from './client';
import type { FocusPreset } from '@/types';

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

export async function createPreset(
  userId: string,
  preset: Omit<FocusPreset, 'id' | 'userId'>
): Promise<FocusPreset> {
  const supabase = createClient();
  
  const { data, error } = await supabase
    .from('focus_presets')
    .insert({
      user_id: userId,
      name: preset.name,
      duration_seconds: preset.durationSeconds,
      sound_id: preset.soundID || null,
      emoji: preset.emoji || null,
      is_system_default: preset.isSystemDefault || false,
      theme_raw: preset.themeRaw || null,
      external_music_app_raw: preset.externalMusicAppRaw || null,
      ambiance_mode_raw: preset.ambianceModeRaw || null,
    })
    .select()
    .single();

  if (error) throw error;
  return transformPreset(data);
}

export async function updatePreset(
  userId: string,
  id: string,
  updates: Partial<FocusPreset>
): Promise<FocusPreset> {
  const supabase = createClient();
  
  const updateData: any = {};
  if (updates.name !== undefined) updateData.name = updates.name;
  if (updates.durationSeconds !== undefined) updateData.duration_seconds = updates.durationSeconds;
  if (updates.soundID !== undefined) updateData.sound_id = updates.soundID || null;
  if (updates.emoji !== undefined) updateData.emoji = updates.emoji || null;
  if (updates.themeRaw !== undefined) updateData.theme_raw = updates.themeRaw || null;
  if (updates.externalMusicAppRaw !== undefined) updateData.external_music_app_raw = updates.externalMusicAppRaw || null;
  if (updates.ambianceModeRaw !== undefined) updateData.ambiance_mode_raw = updates.ambianceModeRaw || null;

  const { data, error } = await supabase
    .from('focus_presets')
    .update(updateData)
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) throw error;
  return transformPreset(data);
}

export async function deletePreset(
  userId: string,
  id: string
): Promise<void> {
  const supabase = createClient();
  
  const { error } = await supabase
    .from('focus_presets')
    .delete()
    .eq('id', id)
    .eq('user_id', userId);

  if (error) throw error;
}

