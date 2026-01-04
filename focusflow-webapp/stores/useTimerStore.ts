import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { TimerState, TimerPhase } from '@/types';

interface TimerStore extends TimerState {
  // iOS-like state
  plannedSessionTotalSeconds: number;
  didLogThisSession: boolean;
  
  // Actions
  setPhase: (phase: TimerPhase) => void;
  setTotalSeconds: (seconds: number) => void;
  setRemainingSeconds: (seconds: number) => void;
  setSessionName: (name: string) => void;
  setStartDate: (date?: Date) => void;
  setEndDate: (date?: Date) => void;
  setPresetId: (id?: string) => void;
  toggle: (sessionName: string) => void;
  pause: () => void;
  reset: () => void;
  resetToIdleKeepDuration: () => void;
  updateMinutes: (minutes: number) => void;
  tick: () => void;
  
  // Internal methods (used by public methods)
  startInternal: (isFresh: boolean, sessionName: string) => void;
  pauseInternal: () => void;
  completeIfNeeded: () => void;
  computeElapsedSeconds: () => number;
  logSessionIfNeeded: (durationSeconds: number) => void;
  
  // iOS-like methods
  smoothProgress: (now: Date) => number;
  logEarlyEndIfMeaningful: () => void;
  restoreIfNeeded: () => void;
  persistRunning: () => void;
  persistPaused: () => void;
  clearPersistedSession: () => void;
  
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

// Early-end detection rules (matching iOS)
const EARLY_END_MINIMUM_COMPLETION_RATIO = 0.40; // 40%
const EARLY_END_MINIMUM_SECONDS = 5 * 60; // 5 minutes
const EARLY_END_HARD_FLOOR_SECONDS = 60; // 1 minute

export const useTimerStore = create<TimerStore>()(
  persist(
    (set, get) => ({
      ...defaultState,
      plannedSessionTotalSeconds: 0,
      didLogThisSession: false,
      
      setPhase: (phase) => set({ phase }),
      setTotalSeconds: (totalSeconds) => set({ totalSeconds, remainingSeconds: totalSeconds }),
      setRemainingSeconds: (remainingSeconds) => set({ remainingSeconds }),
      setSessionName: (sessionName) => set({ sessionName }),
      setStartDate: (startDate) => set({ startDate }),
      setEndDate: (endDate) => set({ endDate }),
      setPresetId: (presetId) => set({ presetId }),
      
      toggle: (sessionName: string) => {
        const { phase, remainingSeconds, totalSeconds } = get();
        
        switch (phase) {
          case 'idle':
          case 'completed':
            get().startInternal(true, sessionName);
            break;
          case 'running':
            get().pauseInternal();
            break;
          case 'paused':
            get().startInternal(false, sessionName);
            break;
        }
      },
      
      pause: () => {
        get().pauseInternal();
      },
      
      startInternal: (isFresh: boolean, sessionName: string) => {
        const { remainingSeconds, phase } = get();
        if (remainingSeconds <= 0 || phase === 'running') return;
        
        const now = new Date();
        let plannedSeconds = get().plannedSessionTotalSeconds;
        
        if (isFresh || plannedSeconds === 0) {
          plannedSeconds = remainingSeconds;
          set({
            plannedSessionTotalSeconds: plannedSeconds,
            totalSeconds: plannedSeconds,
            startDate: now,
            sessionStartDate: now,
            didLogThisSession: false,
          });
        }
        
        const endDate = new Date(now.getTime() + remainingSeconds * 1000);
        
        set({
          phase: 'running',
          sessionName,
          startDate: now,
          endDate,
        });
        
        get().persistRunning();
      },
      
      pauseInternal: () => {
        const { phase } = get();
        if (phase !== 'running') return;
        
        set({ phase: 'paused' });
        get().persistPaused();
      },
      
      reset: () => {
        get().logEarlyEndIfMeaningful();
        get().clearPersistedSession();
        
        set({
          ...defaultState,
          totalSeconds: 25 * 60,
          remainingSeconds: 25 * 60,
          plannedSessionTotalSeconds: 0,
          didLogThisSession: false,
        });
      },
      
      resetToIdleKeepDuration: () => {
        get().logEarlyEndIfMeaningful();
        get().clearPersistedSession();
        
        const { totalSeconds } = get();
        set({
          phase: 'idle',
          remainingSeconds: totalSeconds,
          plannedSessionTotalSeconds: 0,
          startDate: undefined,
          endDate: undefined,
          didLogThisSession: false,
        });
      },
      
      updateMinutes: (minutes: number) => {
        get().clearPersistedSession();
        
        const totalSeconds = Math.max(1, minutes) * 60;
        set({
          totalSeconds,
          remainingSeconds: totalSeconds,
          plannedSessionTotalSeconds: 0,
          startDate: undefined,
          endDate: undefined,
          phase: 'idle',
          didLogThisSession: false,
        });
      },
      
      tick: () => {
        const { phase, endDate } = get();
        if (phase !== 'running' || !endDate) return;
        
        const now = new Date();
        const timeLeft = Math.max(0, Math.ceil((endDate.getTime() - now.getTime()) / 1000));
        
        if (timeLeft <= 0) {
          get().completeIfNeeded();
        } else {
          set({ remainingSeconds: timeLeft });
          get().persistRunning();
        }
      },
      
      completeIfNeeded: () => {
        const { phase } = get();
        if (phase === 'completed') return;
        
        set({
          remainingSeconds: 0,
          phase: 'completed',
          endDate: undefined,
        });
        
        // Log session completion
        const { plannedSessionTotalSeconds, totalSeconds } = get();
        const planned = plannedSessionTotalSeconds > 0 ? plannedSessionTotalSeconds : Math.max(totalSeconds, 1);
        get().logSessionIfNeeded(planned);
        
        get().clearPersistedSession();
      },
      
      logEarlyEndIfMeaningful: () => {
        const { phase, plannedSessionTotalSeconds, didLogThisSession } = get();
        if (phase !== 'running' && phase !== 'paused') return;
        if (plannedSessionTotalSeconds === 0) return;
        if (didLogThisSession) return;
        
        const elapsed = get().computeElapsedSeconds();
        if (elapsed < EARLY_END_HARD_FLOOR_SECONDS) return;
        
        const ratio = elapsed / plannedSessionTotalSeconds;
        const meetsRule = (elapsed >= EARLY_END_MINIMUM_SECONDS) || (ratio >= EARLY_END_MINIMUM_COMPLETION_RATIO);
        
        if (meetsRule) {
          get().logSessionIfNeeded(elapsed);
        }
      },
      
      computeElapsedSeconds: () => {
        const { phase, plannedSessionTotalSeconds, remainingSeconds, startDate, endDate, sessionStartDate } = get();
        const start = startDate || sessionStartDate;
        
        if (phase === 'running') {
          if (endDate) {
            const remaining = Math.max(0, Math.ceil((endDate.getTime() - Date.now()) / 1000));
            const elapsed = plannedSessionTotalSeconds - remaining;
            return Math.max(0, Math.min(plannedSessionTotalSeconds, elapsed));
          } else if (start) {
            const elapsed = Math.floor((Date.now() - start.getTime()) / 1000);
            return Math.max(0, Math.min(plannedSessionTotalSeconds, elapsed));
          } else {
            return Math.max(0, Math.min(plannedSessionTotalSeconds, plannedSessionTotalSeconds - remainingSeconds));
          }
        } else if (phase === 'paused') {
          return Math.max(0, Math.min(plannedSessionTotalSeconds, plannedSessionTotalSeconds - remainingSeconds));
        }
        
        return 0;
      },
      
      logSessionIfNeeded: (durationSeconds: number) => {
        const { didLogThisSession, sessionName } = get();
        if (didLogThisSession || durationSeconds <= 0) return;
        
        set({ didLogThisSession: true });
        
        // This will be called from the component to save to Supabase
        // We just mark it as logged here
      },
      
      smoothProgress: (now: Date) => {
        const { phase, totalSeconds, endDate, plannedSessionTotalSeconds } = get();
        
        if (phase === 'completed') return 1.0;
        if (totalSeconds === 0) return 0;
        
        if (phase === 'running' && endDate && plannedSessionTotalSeconds > 0) {
          const remaining = Math.max(0, (endDate.getTime() - now.getTime()) / 1000);
          const elapsed = plannedSessionTotalSeconds - remaining;
          return Math.min(Math.max(elapsed / plannedSessionTotalSeconds, 0), 1);
        }
        
        return get().getProgress();
      },
      
      persistRunning: () => {
        const { plannedSessionTotalSeconds, sessionName, startDate, remainingSeconds, endDate } = get();
        const storage = typeof window !== 'undefined' ? localStorage : null;
        if (!storage) return;
        
        try {
          storage.setItem('ff_timer_isActive', 'true');
          storage.setItem('ff_timer_isPaused', 'false');
          storage.setItem('ff_timer_plannedSeconds', String(plannedSessionTotalSeconds));
          storage.setItem('ff_timer_startDate', startDate ? startDate.getTime().toString() : '');
          storage.setItem('ff_timer_sessionName', sessionName || '');
          storage.setItem('ff_timer_remainingSeconds', String(remainingSeconds));
        } catch (e) {
          console.error('Failed to persist timer state:', e);
        }
      },
      
      persistPaused: () => {
        const { plannedSessionTotalSeconds, sessionName, startDate, remainingSeconds } = get();
        const storage = typeof window !== 'undefined' ? localStorage : null;
        if (!storage) return;
        
        try {
          storage.setItem('ff_timer_isActive', 'true');
          storage.setItem('ff_timer_isPaused', 'true');
          storage.setItem('ff_timer_plannedSeconds', String(plannedSessionTotalSeconds));
          storage.setItem('ff_timer_startDate', startDate ? startDate.getTime().toString() : '');
          storage.setItem('ff_timer_sessionName', sessionName || '');
          storage.setItem('ff_timer_pausedRemaining', String(remainingSeconds));
        } catch (e) {
          console.error('Failed to persist timer state:', e);
        }
      },
      
      clearPersistedSession: () => {
        const storage = typeof window !== 'undefined' ? localStorage : null;
        if (!storage) return;
        
        try {
          storage.removeItem('ff_timer_isActive');
          storage.removeItem('ff_timer_isPaused');
          storage.removeItem('ff_timer_plannedSeconds');
          storage.removeItem('ff_timer_startDate');
          storage.removeItem('ff_timer_sessionName');
          storage.removeItem('ff_timer_pausedRemaining');
          storage.removeItem('ff_timer_remainingSeconds');
        } catch (e) {
          console.error('Failed to clear persisted timer state:', e);
        }
      },
      
      restoreIfNeeded: () => {
        const storage = typeof window !== 'undefined' ? localStorage : null;
        if (!storage) return;
        
        try {
          const isActive = storage.getItem('ff_timer_isActive') === 'true';
          if (!isActive) return;
          
          const planned = parseInt(storage.getItem('ff_timer_plannedSeconds') || '0', 10);
          if (planned <= 0) {
            get().clearPersistedSession();
            return;
          }
          
          const sessionName = storage.getItem('ff_timer_sessionName') || '';
          const isPaused = storage.getItem('ff_timer_isPaused') === 'true';
          const startDateStr = storage.getItem('ff_timer_startDate');
          const startDate = startDateStr ? new Date(parseInt(startDateStr, 10)) : undefined;
          
          set({
            totalSeconds: planned,
            plannedSessionTotalSeconds: planned,
            sessionName,
            startDate,
            sessionStartDate: startDate,
            didLogThisSession: false,
          });
          
          if (isPaused) {
            const pausedRemaining = parseInt(storage.getItem('ff_timer_pausedRemaining') || '0', 10);
            set({
              phase: 'paused',
              remainingSeconds: Math.max(0, Math.min(planned, pausedRemaining)),
            });
          } else if (startDate) {
            const elapsed = Math.floor((Date.now() - startDate.getTime()) / 1000);
            const remaining = planned - elapsed;
            
            if (remaining <= 0) {
              set({
                phase: 'completed',
                remainingSeconds: 0,
              });
              get().logSessionIfNeeded(planned);
              get().clearPersistedSession();
            } else {
              set({
                phase: 'running',
                remainingSeconds: remaining,
                endDate: new Date(Date.now() + remaining * 1000),
              });
            }
          }
        } catch (e) {
          console.error('Failed to restore timer state:', e);
          get().clearPersistedSession();
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

