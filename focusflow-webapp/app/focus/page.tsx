'use client';

import { useEffect, useState, useCallback, useRef, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import { Sidebar } from '@/components/layout/Sidebar';
import AnimatedBackground from '@/components/common/AnimatedBackground';
import { FocusTimerDisplay } from '@/components/focus/FocusTimerDisplay';
import { PresetSelectorCard } from '@/components/focus/PresetSelectorCard';
import { AmbientBackgroundCard } from '@/components/focus/AmbientBackgroundCard';
import { SoundSettingsCard } from '@/components/focus/SoundSettingsCard';
import { TimePickerModal } from '@/components/focus/TimePickerModal';
import { CompletionOverlay } from '@/components/focus/CompletionOverlay';
import AmbientBackground, { type AmbientMode } from '@/components/focus/AmbientBackground';
import { useTimerStore } from '@/stores/useTimerStore';
import { usePresetsStore } from '@/stores/usePresetsStore';
import { useFocusSoundStore } from '@/stores/useFocusSoundStore';
import { useSessions } from '@/hooks/supabase/useSessions';
import { usePresets } from '@/hooks/supabase/usePresets';
import { useUserStats } from '@/hooks/supabase/useUserStats';
import { useSessionsStore } from '@/stores/useSessionsStore';
import { focusSoundManager } from '@/lib/FocusSoundManager';
import { themes, type AppTheme } from '@/lib/themes';
// Removed heavy motion animations for performance
import { Sun, Flame } from 'lucide-react';
import { formatTime } from '@/lib/utils';

export default function FocusPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  // Sync auth state
  useSyncAuth();
  useOnlineStatus();

  // Stores - use selectors to avoid unnecessary re-renders
  // Use stable selectors to prevent infinite loops
  const phase = useTimerStore((state) => state.phase);
  const totalSeconds = useTimerStore((state) => state.totalSeconds);
  const sessionName = useTimerStore((state) => state.sessionName);
  const presets = usePresetsStore((state) => state.presets);
  const selectedPresetId = usePresetsStore((state) => state.selectedPresetId);
  const selectedSound = useFocusSoundStore((state) => state.selectedSound);
  const soundEnabled = useFocusSoundStore((state) => state.soundEnabled);
  
  // Subscribe to sessions array and compute values with useMemo
  const sessions = useSessionsStore((state) => state.sessions);
  const todayFocusTime = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    return sessions
      .filter((session) => {
        const sessionDate = new Date(session.startedAt);
        return sessionDate >= today && sessionDate < tomorrow;
      })
      .reduce((sum, session) => sum + session.durationSeconds, 0);
  }, [sessions]);
  
  const todaySessions = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    return sessions.filter((session) => {
      const sessionDate = new Date(session.startedAt);
      return sessionDate >= today && sessionDate < tomorrow;
    });
  }, [sessions]);

  // Hooks
  const userId = user?.id;
  const { isLoading: presetsLoading } = usePresets(userId); // Hook already syncs to store
  const { addSession } = useSessions(userId);
  const { data: stats } = useUserStats(userId);

  // State
  const [ambientMode, setAmbientMode] = useState<AmbientMode>('minimal');
  const [ambientIntensity, setAmbientIntensity] = useState(0.7);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [showCompletion, setShowCompletion] = useState(false);
  const [currentTheme, setCurrentTheme] = useState<AppTheme>('forest');
  const hasHandledCompletion = useRef(false);

  // Apply theme to CSS variables
  useEffect(() => {
    const theme = themes[currentTheme];
    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--accent-primary', theme.accentPrimary);
      document.documentElement.style.setProperty('--accent-secondary', theme.accentSecondary);
    }
  }, [currentTheme]);

  // Handle session completion
  const handleSessionComplete = useCallback(async () => {
    if (!user) return;

    const state = useTimerStore.getState();
    const { plannedSessionTotalSeconds, totalSeconds, sessionName, startDate } = state;
    const duration = plannedSessionTotalSeconds > 0 ? plannedSessionTotalSeconds : totalSeconds;

    if (duration < 60) return; // Don't save sessions less than 1 minute

    try {
      const startTime = startDate || new Date(Date.now() - duration * 1000);

      await addSession({
        userId: user.id,
        startedAt: startTime.toISOString(),
        durationSeconds: duration,
        sessionName: sessionName || 'Focus Session',
      });
    } catch (error) {
      console.error('Failed to save session:', error);
    }
  }, [user, addSession]);

  // Handle preset selection
  const handlePresetSelect = useCallback((presetId: string) => {
    const preset = presets.find((p) => p.id === presetId);
    if (!preset) return;

    const timerStore = useTimerStore.getState();

    // Apply preset settings
    if (preset.durationSeconds > 0) {
      timerStore.updateMinutes(Math.floor(preset.durationSeconds / 60));
    }

    if (preset.themeRaw) {
      const theme = preset.themeRaw as AppTheme;
      if (themes[theme]) {
        setCurrentTheme(theme);
      }
    }

    if (preset.ambianceModeRaw) {
      setAmbientMode(preset.ambianceModeRaw as AmbientMode);
    }

    timerStore.setPresetId(presetId);
    timerStore.setSessionName(preset.name);
  }, [presets]);

  // Handle timer phase changes - sound management
  useEffect(() => {
    // Handle sound based on phase
    if (phase === 'running') {
      if (soundEnabled && selectedSound) {
        focusSoundManager.play(selectedSound).catch(console.error);
      }
    } else if (phase === 'paused') {
      focusSoundManager.pause();
    } else if (phase === 'idle' || phase === 'completed') {
      focusSoundManager.stop();
    }
  }, [phase, soundEnabled, selectedSound]);

  // Handle completion separately to avoid dependency loops
  useEffect(() => {
    if (phase === 'completed' && !hasHandledCompletion.current) {
      hasHandledCompletion.current = true;
      setShowCompletion(true);
      handleSessionComplete();
    } else if (phase !== 'completed') {
      // Reset when phase changes away from completed
      hasHandledCompletion.current = false;
      setShowCompletion(false);
    }
  }, [phase, handleSessionComplete]);

  // Handle time picker
  const handleTimePickerConfirm = (hours: number, minutes: number) => {
    const totalMinutes = hours * 60 + minutes;
    if (totalMinutes > 0) {
      timerStore.updateMinutes(totalMinutes);
    }
  };

  // Handle completion overlay done
  const handleCompletionDone = () => {
    setShowCompletion(false);
    timerStore.resetToIdleKeepDuration();
  };

  // Calculate stats (memoized)
  const currentStreak = stats?.currentStreak || 0;

  useEffect(() => {
    if (!loading && !user) {
      router.push('/signin');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="text-[var(--foreground-muted)]">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const isTimerActive = phase === 'running' || phase === 'paused';

  return (
    <div className="min-h-screen flex bg-[var(--background)] relative overflow-hidden">
      {/* Background - Only show one at a time for performance */}
      {isTimerActive ? (
        <AmbientBackground mode={ambientMode} isActive={isTimerActive} intensity={ambientIntensity} />
      ) : (
        <AnimatedBackground variant="aurora" showGrid={true} />
      )}

      <Sidebar />

      <main className="flex-1 flex flex-col lg:ml-0 relative z-10 pt-4">
        {/* Top Bar - Same as Dashboard */}
        <div className="sticky top-4 z-30 bg-[var(--background-elevated)]/90 backdrop-blur-xl border border-[var(--border)] rounded-2xl mx-4 md:mx-6 lg:mx-8 shadow-sm"
        >
          <div className="px-4 md:px-6">
            <div className="flex items-center justify-between h-12 md:h-14">
              <div className="flex items-center gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-[var(--foreground)]">Focus Timer</span>
                  </div>
                  <p className="text-xs text-[var(--foreground-muted)] flex items-center gap-1.5 mt-0.5">
                    <Sun className="w-3 h-3" />
                    {formatTime(todayFocusTime)} today
                    <span className="text-[var(--foreground-subtle)]">•</span>
                    <Flame className="w-3 h-3" />
                    {currentStreak} day streak
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8 py-6 md:py-8">
            {/* Hero Timer Section */}
            <section className="mb-8 md:mb-12">
              <FocusTimerDisplay onLengthClick={() => setShowTimePicker(true)} />
            </section>

            {/* Settings Grid */}
            <section className="grid grid-cols-1 xl:grid-cols-2 gap-6 lg:gap-8"
            >
              {/* Left Column */}
              <div className="space-y-6">
                <PresetSelectorCard
                  onPresetSelect={handlePresetSelect}
                  onAddPreset={() => {
                    // TODO: Open preset manager
                    console.log('Open preset manager');
                  }}
                />
                <AmbientBackgroundCard
                  mode={ambientMode}
                  intensity={ambientIntensity}
                  onModeChange={setAmbientMode}
                  onIntensityChange={setAmbientIntensity}
                />
              </div>

              {/* Right Column */}
              <div className="space-y-6">
                <SoundSettingsCard />
              </div>
            </section>
          </div>
        </div>
      </main>

      {/* Time Picker Modal - Lazy loaded */}
      {showTimePicker && (
        <TimePickerModal
          isOpen={showTimePicker}
          onClose={() => setShowTimePicker(false)}
          onConfirm={handleTimePickerConfirm}
          initialHours={Math.floor(totalSeconds / 3600)}
          initialMinutes={Math.floor((totalSeconds % 3600) / 60)}
        />
      )}

      {/* Completion Overlay - Lazy loaded */}
      {showCompletion && (
        <CompletionOverlay
          isOpen={showCompletion}
          sessionName={sessionName || 'Focus Session'}
          durationText={`${Math.floor(totalSeconds / 60)} min`}
          onDone={handleCompletionDone}
        />
      )}
    </div>
  );
}
