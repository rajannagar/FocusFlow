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
  sessionStartDate?: Date; // iOS-like: captured start time for restoration
}

// Sync state
export interface SyncState {
  isSyncing: boolean;
  lastSyncDate?: Date;
  syncError?: Error | null;
  isOnline: boolean;
}

// Focus Sound (matching iOS)
export enum FocusSound {
  angelsByMySide = 'angelsbymyside',
  fireplace = 'fireplace',
  floatingGarden = 'floatinggarden',
  hearty = 'hearty',
  lightRainAmbient = 'light-rain-ambient',
  longNight = 'longnight',
  soundAmbience = 'sound-ambience',
  streetMarketFrance = 'street-market-gap-france',
  theLightBetweenUs = 'thelightbetweenus',
  underwater = 'underwater',
  yesterday = 'yesterday',
}

export const FocusSoundDisplayNames: Record<FocusSound, string> = {
  [FocusSound.angelsByMySide]: 'Angels by My Side',
  [FocusSound.fireplace]: 'Cozy Fireplace',
  [FocusSound.floatingGarden]: 'Floating Garden',
  [FocusSound.hearty]: 'Hearty',
  [FocusSound.lightRainAmbient]: 'Light Rain (Ambient)',
  [FocusSound.longNight]: 'Long Night',
  [FocusSound.soundAmbience]: 'Soft Ambience',
  [FocusSound.streetMarketFrance]: 'French Street Market',
  [FocusSound.theLightBetweenUs]: 'The Light Between Us',
  [FocusSound.underwater]: 'Underwater',
  [FocusSound.yesterday]: 'Yesterday',
};

