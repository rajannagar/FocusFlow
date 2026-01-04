import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { FocusSound } from '@/types';

interface FocusSoundStore {
  selectedSound: FocusSound | null;
  soundEnabled: boolean;
  volume: number; // 0.0 to 1.0
  
  setSelectedSound: (sound: FocusSound | null) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setVolume: (volume: number) => void;
  reset: () => void;
}

const defaultState = {
  selectedSound: null,
  soundEnabled: true,
  volume: 1.0,
};

export const useFocusSoundStore = create<FocusSoundStore>()(
  persist(
    (set) => ({
      ...defaultState,
      
      setSelectedSound: (sound) => set({ selectedSound: sound }),
      setSoundEnabled: (enabled) => set({ soundEnabled: enabled }),
      setVolume: (volume) => set({ volume: Math.max(0, Math.min(1, volume)) }),
      reset: () => set(defaultState),
    }),
    {
      name: 'focusflow-sound',
      partialize: (state) => ({
        selectedSound: state.selectedSound,
        soundEnabled: state.soundEnabled,
        volume: state.volume,
      }),
    }
  )
);

