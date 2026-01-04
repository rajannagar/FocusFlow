import { create } from 'zustand';
import type { FocusPreset } from '@/types';

interface PresetsState {
  presets: FocusPreset[];
  selectedPresetId: string | null;
  isLoading: boolean;
  
  // Actions
  setPresets: (presets: FocusPreset[]) => void;
  addPreset: (preset: FocusPreset) => void;
  updatePreset: (id: string, updates: Partial<FocusPreset>) => void;
  deletePreset: (id: string) => void;
  setSelectedPresetId: (id: string | null) => void;
  setLoading: (loading: boolean) => void;
  
  // Computed getters
  getSystemPresets: () => FocusPreset[];
  getCustomPresets: () => FocusPreset[];
}

export const usePresetsStore = create<PresetsState>((set, get) => ({
  presets: [],
  selectedPresetId: null,
  isLoading: false,
  
  setPresets: (presets) => set({ presets }),
  
  addPreset: (preset) => set((state) => ({
    presets: [...state.presets, preset],
  })),
  
  updatePreset: (id, updates) => set((state) => ({
    presets: state.presets.map((preset) =>
      preset.id === id ? { ...preset, ...updates } : preset
    ),
  })),
  
  deletePreset: (id) => set((state) => ({
    presets: state.presets.filter((preset) => preset.id !== id),
    selectedPresetId: state.selectedPresetId === id ? null : state.selectedPresetId,
  })),
  
  setSelectedPresetId: (id) => set({ selectedPresetId: id }),
  setLoading: (loading) => set({ isLoading: loading }),
  
  getSystemPresets: () => {
    return get().presets.filter((p) => p.isSystemDefault);
  },
  
  getCustomPresets: () => {
    return get().presets.filter((p) => !p.isSystemDefault);
  },
}));

