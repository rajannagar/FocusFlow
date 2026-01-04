import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { TimerState, TimerPhase } from '@/types';

interface TimerStore extends TimerState {
  // Actions
  setPhase: (phase: TimerPhase) => void;
  setTotalSeconds: (seconds: number) => void;
  setRemainingSeconds: (seconds: number) => void;
  setSessionName: (name: string) => void;
  setStartDate: (date?: Date) => void;
  setEndDate: (date?: Date) => void;
  setPresetId: (id?: string) => void;
  reset: () => void;
  resetToDefault: () => void;
  tick: () => void;
  
  // Computed getters
  getProgress: () => number;
  getFormattedTime: () => string;
}

const defaultState: TimerState = {
  phase: 'idle',
  totalSeconds: 25 * 60,
  remainingSeconds: 25 * 60,
  sessionName: '',
};

export const useTimerStore = create<TimerStore>()(
  persist(
    (set, get) => ({
      ...defaultState,
      
      setPhase: (phase) => set({ phase }),
      setTotalSeconds: (totalSeconds) => set({ totalSeconds, remainingSeconds: totalSeconds }),
      setRemainingSeconds: (remainingSeconds) => set({ remainingSeconds }),
      setSessionName: (sessionName) => set({ sessionName }),
      setStartDate: (startDate) => set({ startDate }),
      setEndDate: (endDate) => set({ endDate }),
      setPresetId: (presetId) => set({ presetId }),
      
      startSession: () => {
        set({ phase: 'running', startDate: new Date() });
      },
      
      reset: () => {
        const state = get();
        set({
          phase: 'idle',
          remainingSeconds: state.totalSeconds,
          sessionName: '',
          startDate: undefined,
          endDate: undefined,
          presetId: undefined,
        });
      },
      
      resetToDefault: () => set({
        ...defaultState,
      }),
      
      tick: () => {
        const { remainingSeconds, phase } = get();
        if (phase === 'running' && remainingSeconds > 0) {
          const newRemaining = remainingSeconds - 1;
          set({ remainingSeconds: newRemaining });
          
          // Auto-complete when timer reaches 0
          if (newRemaining === 0) {
            set({ phase: 'completed', remainingSeconds: 0 });
          }
        }
      },
      
      getProgress: () => {
        const { totalSeconds, remainingSeconds } = get();
        if (totalSeconds === 0) return 0;
        return (totalSeconds - remainingSeconds) / totalSeconds;
      },
      
      getFormattedTime: () => {
        const { remainingSeconds } = get();
        const minutes = Math.floor(remainingSeconds / 60);
        const seconds = remainingSeconds % 60;
        return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
      },
    }),
    {
      name: 'focusflow-timer',
      partialize: (state) => ({
        phase: state.phase,
        totalSeconds: state.totalSeconds,
        remainingSeconds: state.remainingSeconds,
        sessionName: state.sessionName,
        presetId: state.presetId,
      }),
    }
  )
);

