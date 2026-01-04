import { create } from 'zustand';
import type { FocusSession } from '@/types';

interface SessionsState {
  sessions: FocusSession[];
  isLoading: boolean;
  
  // Actions
  setSessions: (sessions: FocusSession[]) => void;
  addSession: (session: FocusSession) => void;
  updateSession: (id: string, updates: Partial<FocusSession>) => void;
  deleteSession: (id: string) => void;
  setLoading: (loading: boolean) => void;
  
  // Computed getters
  getTotalFocusTime: () => number; // in seconds
  getTotalSessions: () => number;
  getTodayFocusTime: () => number;
  getTodaySessions: () => FocusSession[];
  getThisWeekFocusTime: () => number;
  getThisMonthFocusTime: () => number;
}

export const useSessionsStore = create<SessionsState>((set, get) => ({
  sessions: [],
  isLoading: false,
  
  setSessions: (sessions) => set({ sessions }),
  
  addSession: (session) => set((state) => ({
    sessions: [session, ...state.sessions].sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    ),
  })),
  
  updateSession: (id, updates) => set((state) => ({
    sessions: state.sessions.map((session) =>
      session.id === id ? { ...session, ...updates } : session
    ),
  })),
  
  deleteSession: (id) => set((state) => ({
    sessions: state.sessions.filter((session) => session.id !== id),
  })),
  
  setLoading: (loading) => set({ isLoading: loading }),
  
  getTotalFocusTime: () => {
    return get().sessions.reduce((sum, session) => sum + session.durationSeconds, 0);
  },
  
  getTotalSessions: () => {
    return get().sessions.length;
  },
  
  getTodayFocusTime: () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    return get().sessions
      .filter((session) => {
        const sessionDate = new Date(session.startedAt);
        return sessionDate >= today && sessionDate < tomorrow;
      })
      .reduce((sum, session) => sum + session.durationSeconds, 0);
  },
  
  getTodaySessions: () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    return get().sessions.filter((session) => {
      const sessionDate = new Date(session.startedAt);
      return sessionDate >= today && sessionDate < tomorrow;
    });
  },
  
  getThisWeekFocusTime: () => {
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay());
    weekStart.setHours(0, 0, 0, 0);
    
    return get().sessions
      .filter((session) => {
        const sessionDate = new Date(session.startedAt);
        return sessionDate >= weekStart;
      })
      .reduce((sum, session) => sum + session.durationSeconds, 0);
  },
  
  getThisMonthFocusTime: () => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    
    return get().sessions
      .filter((session) => {
        const sessionDate = new Date(session.startedAt);
        return sessionDate >= monthStart;
      })
      .reduce((sum, session) => sum + session.durationSeconds, 0);
  },
}));

