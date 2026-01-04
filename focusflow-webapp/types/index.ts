// Shared types matching iOS app structure

export type TaskRepeatRule = 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'customDays';

export interface Task {
  id: string;
  sortIndex: number;
  title: string;
  notes?: string;
  reminderDate?: Date | string;
  repeatRule: TaskRepeatRule;
  customWeekdays: number[];
  durationMinutes: number;
  convertToPreset: boolean;
  presetCreated: boolean;
  excludedDayKeys: string[];
  createdAt: Date | string;
}

export interface FocusPreset {
  id: string;
  userId?: string;
  name: string;
  durationSeconds: number;
  soundID: string;
  emoji?: string;
  isSystemDefault: boolean;
  themeRaw?: string;
  externalMusicAppRaw?: string;
  ambianceModeRaw?: string;
}

export interface FocusSession {
  id: string;
  userId: string;
  startedAt: Date | string;
  durationSeconds: number;
  sessionName?: string;
  createdAt?: Date | string;
  updatedAt?: Date | string;
}

export interface UserStats {
  userId: string;
  lifetimeFocusSeconds: number;
  lifetimeSessionCount: number;
  lifetimeBestStreak: number;
  currentStreak: number;
  lastFocusDate?: string; // YYYY-MM-DD
  totalXp: number;
  currentLevel: number;
  createdAt?: Date | string;
  updatedAt?: Date | string;
}

export interface UserSettings {
  userId: string;
  dailyGoalMinutes: number;
  theme?: string;
  createdAt?: Date | string;
  updatedAt?: Date | string;
}

// Timer state
export type TimerPhase = 'idle' | 'running' | 'paused' | 'completed';

export interface TimerState {
  phase: TimerPhase;
  totalSeconds: number;
  remainingSeconds: number;
  sessionName: string;
  startDate?: Date;
  endDate?: Date;
  presetId?: string;
}

// Sync state
export interface SyncState {
  isSyncing: boolean;
  lastSyncDate?: Date;
  syncError?: Error | null;
  isOnline: boolean;
}

