import { create } from 'zustand';
import type { SyncState } from '@/types';

interface SyncStore extends SyncState {
  // Actions
  setSyncing: (isSyncing: boolean) => void;
  setLastSyncDate: (date?: Date) => void;
  setSyncError: (error: Error | null) => void;
  setOnline: (isOnline: boolean) => void;
  reset: () => void;
}

const defaultState: SyncState = {
  isSyncing: false,
  isOnline: typeof navigator !== 'undefined' ? navigator.onLine : true,
};

export const useSyncStore = create<SyncStore>((set) => ({
  ...defaultState,
  
  setSyncing: (isSyncing) => set({ isSyncing }),
  setLastSyncDate: (lastSyncDate) => set({ lastSyncDate }),
  setSyncError: (syncError) => set({ syncError }),
  setOnline: (isOnline) => set({ isOnline }),
  
  reset: () => set({
    isSyncing: false,
    lastSyncDate: undefined,
    syncError: null,
  }),
}));

