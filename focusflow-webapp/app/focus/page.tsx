'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import { Sidebar } from '@/components/layout/Sidebar';
import AnimatedBackground from '@/components/common/AnimatedBackground';
import { usePresets } from '@/hooks/supabase/usePresets';
import { useQueryClient } from '@tanstack/react-query';
import { useTimerStore } from '@/stores/useTimerStore';
import { usePresetsStore } from '@/stores/usePresetsStore';
import { useColorTheme } from '@/hooks/useColorTheme';
import { soundManager } from '@/lib/soundManager';
import { focusSounds } from '@/lib/focusSounds';
import { FocusTimerCard } from '@/components/focus/FocusTimerCard';
import { SessionNameInput } from '@/components/focus/SessionNameInput';
import { PresetSelector } from '@/components/focus/PresetSelector';
import { SoundPicker } from '@/components/focus/SoundPicker';
import { AmbientPicker } from '@/components/focus/AmbientPicker';
import { TimePicker } from '@/components/focus/TimePicker';
import { PresetManager } from '@/components/focus/PresetManager';
import { FullScreenFocus } from '@/components/focus/FullScreenFocus';
import DarkModeToggle from '@/components/common/DarkModeToggle';
import UserMenu from '@/components/common/UserMenu';
import { motion } from 'framer-motion';
import { Timer, Maximize2, Volume2, VolumeX } from 'lucide-react';
import { Button } from '@/components/common/Button';
import type { AmbientMode } from '@/components/focus/AmbientBackground';
import type { FocusPreset } from '@/types';
import { createPreset, updatePreset, deletePreset } from '@/lib/supabase/presets';

export default function FocusPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  
  // Sync auth state
  useSyncAuth();
  useOnlineStatus();
  
  // Fetch data
  const userId = user?.id;
  const { presets } = usePresets(userId);
  const queryClient = useQueryClient();
  
  // Stores
  const {
    phase,
    totalSeconds,
    remainingSeconds,
    sessionName,
    setPhase,
    setTotalSeconds,
    setRemainingSeconds,
    setSessionName,
    reset,
    tick,
  } = useTimerStore();

  const { selectedPresetId, setSelectedPresetId } = usePresetsStore();
  const { changeColorTheme } = useColorTheme();
  
  // Local state
  const [ambientMode, setAmbientMode] = useState<AmbientMode>('minimal');
  const [selectedSound, setSelectedSound] = useState<string | null>(null);
  const [soundVolume, setSoundVolume] = useState(0.5);
  const [isSoundEnabled, setIsSoundEnabled] = useState(true);
  const [showSoundPicker, setShowSoundPicker] = useState(false);
  const [showAmbientPicker, setShowAmbientPicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [isFullScreen, setIsFullScreen] = useState(false);
  
  // Auto-tick timer
  useEffect(() => {
    if (phase === 'running') {
      const interval = setInterval(() => {
        tick();
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [phase, tick]);

  // Handle sound playback
  useEffect(() => {
    if (phase === 'running' && selectedSound && isSoundEnabled) {
      soundManager.setVolume(soundVolume);
      soundManager.play(selectedSound);
    } else if (phase === 'paused') {
      soundManager.pause();
    } else if (phase === 'idle' || phase === 'completed') {
      soundManager.stop();
    }

    return () => {
      // Cleanup on unmount
      if (phase !== 'running') {
        soundManager.stop();
      }
    };
  }, [phase, selectedSound, isSoundEnabled, soundVolume]);

  // Handle preset selection
  const handlePresetSelect = (preset: FocusPreset) => {
    if (phase === 'running' || phase === 'paused') {
      if (confirm('Switch preset? This will reset your current session.')) {
        reset();
        applyPreset(preset);
      }
    } else {
      applyPreset(preset);
    }
  };

  const applyPreset = (preset: FocusPreset) => {
    setTotalSeconds(preset.durationSeconds);
    setRemainingSeconds(preset.durationSeconds);
    
    if (preset.themeRaw) {
      changeColorTheme(preset.themeRaw as any);
    }
    
    if (preset.ambianceModeRaw) {
      setAmbientMode(preset.ambianceModeRaw as AmbientMode);
    }
    
    if (preset.soundID) {
      setSelectedSound(preset.soundID);
    } else {
      setSelectedSound(null);
    }
    
    if (!sessionName || sessionName === '') {
      setSessionName(preset.name);
    }
    
    setSelectedPresetId(preset.id);
  };

  // Preset management
  const handleAddPreset = async (presetData: Omit<FocusPreset, 'id'>) => {
    if (!userId) return;
    
    try {
      const newPreset = await createPreset(userId, presetData);
      queryClient.invalidateQueries({ queryKey: ['presets', userId] });
    } catch (error) {
      console.error('Error creating preset:', error);
      alert('Failed to create preset');
    }
  };

  const handleUpdatePreset = async (id: string, updates: Partial<FocusPreset>) => {
    if (!userId) return;
    
    try {
      await updatePreset(userId, id, updates);
      queryClient.invalidateQueries({ queryKey: ['presets', userId] });
    } catch (error) {
      console.error('Error updating preset:', error);
      alert('Failed to update preset');
    }
  };

  const handleDeletePreset = async (id: string) => {
    if (!userId) return;
    
    try {
      await deletePreset(userId, id);
      queryClient.invalidateQueries({ queryKey: ['presets', userId] });
      if (selectedPresetId === id) {
        setSelectedPresetId(null);
      }
    } catch (error) {
      console.error('Error deleting preset:', error);
      alert('Failed to delete preset');
    }
  };

  const handleReset = () => {
    if (phase === 'running' || phase === 'paused') {
      if (confirm('Reset session? This will stop the current session.')) {
        reset();
        setSelectedPresetId(null);
        setSelectedSound(null);
        setAmbientMode('minimal');
        setSessionName('');
      }
    } else {
      reset();
    }
  };

  const handleLengthConfirm = (minutes: number) => {
    setTotalSeconds(minutes * 60);
    setRemainingSeconds(minutes * 60);
    if (phase === 'running' || phase === 'paused') {
      reset();
    }
  };

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

  const isRunning = phase === 'running';
  const isPaused = phase === 'paused';

  return (
    <>
      <div className="min-h-screen flex bg-[var(--background)] relative overflow-hidden">
        <AnimatedBackground variant="aurora" showGrid={true} />
        
        <Sidebar />
        
        <main className="flex-1 flex flex-col lg:ml-0 relative z-10 pt-4">
          {/* Top Bar - Clean Header Matching Dashboard */}
          <motion.div 
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="sticky top-4 z-30 bg-[var(--background-elevated)]/90 backdrop-blur-xl border border-[var(--border)] rounded-2xl mx-4 md:mx-6 lg:mx-8 shadow-sm mb-6"
          >
            <div className="px-4 md:px-6">
              <div className="flex items-center justify-between h-14">
                {/* Left: Title */}
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center">
                    <Timer className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={1.5} />
                  </div>
                  <div>
                    <h1 className="text-base font-bold text-[var(--foreground)]">Focus Timer</h1>
                  </div>
                </div>
                
                {/* Right: Actions */}
                <div className="flex items-center gap-2">
                  <Button
                    variant="secondary"
                    onClick={() => setIsFullScreen(true)}
                    className="flex items-center gap-2 text-sm"
                  >
                    <Maximize2 className="w-4 h-4" />
                    <span className="hidden sm:inline">Full Screen</span>
                  </Button>
                  <UserMenu />
                  <DarkModeToggle />
                </div>
              </div>
            </div>
          </motion.div>

          {/* Main Content - Two Column Layout */}
          <div className="flex-1 overflow-y-auto">
            <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8 pb-8">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">
                
                {/* Left Column: Timer (2/3 width) */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.1 }}
                  className="lg:col-span-2 space-y-6"
                >
                  {/* Session Name Input */}
                  <SessionNameInput
                    sessionName={sessionName}
                    onSessionNameChange={setSessionName}
                    onSoundClick={() => setShowSoundPicker(true)}
                    onAmbientClick={() => setShowAmbientPicker(true)}
                    selectedSound={selectedSound}
                    ambientMode={ambientMode}
                  />

                  {/* Preset Selector */}
                  {presets && presets.length > 0 && (
                    <PresetSelector
                      presets={presets}
                      selectedPresetId={selectedPresetId}
                      onPresetSelect={handlePresetSelect}
                      isRunning={isRunning}
                      isPaused={isPaused}
                    />
                  )}

                  {/* Timer Card */}
                  <FocusTimerCard
                    ambientMode={ambientMode}
                    onAmbientModeChange={setAmbientMode}
                    selectedSound={selectedSound}
                    onSoundChange={setSelectedSound}
                    sessionName={sessionName}
                    onSessionNameChange={setSessionName}
                    onLengthClick={() => setShowTimePicker(true)}
                    onReset={handleReset}
                  />
                </motion.div>

                {/* Right Column: Controls & Settings (1/3 width) */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.2 }}
                  className="space-y-6"
                >
                  {/* Sound Controls */}
                  <div className="p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)]">
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="text-sm font-semibold text-[var(--foreground)]">Sound</h3>
                      <button
                        onClick={() => {
                          setIsSoundEnabled(!isSoundEnabled);
                          if (!isSoundEnabled) {
                            soundManager.resume();
                          } else {
                            soundManager.pause();
                          }
                        }}
                        className="w-8 h-8 rounded-lg hover:bg-[var(--background-subtle)] flex items-center justify-center transition-colors"
                      >
                        {isSoundEnabled ? (
                          <Volume2 className="w-4 h-4 text-[var(--accent-primary)]" />
                        ) : (
                          <VolumeX className="w-4 h-4 text-[var(--foreground-muted)]" />
                        )}
                      </button>
                    </div>
                    
                    {selectedSound && (
                      <div className="mb-4 p-3 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)]">
                        <div className="text-sm font-medium text-[var(--foreground)]">
                          {focusSounds.find(s => s.id === selectedSound)?.name || 'Unknown'}
                        </div>
                        <div className="text-xs text-[var(--foreground-muted)] mt-1">
                          {soundManager.getIsPlaying() ? 'Playing' : 'Paused'}
                        </div>
                      </div>
                    )}

                    <input
                      type="range"
                      min="0"
                      max="1"
                      step="0.1"
                      value={soundVolume}
                      onChange={(e) => {
                        const vol = parseFloat(e.target.value);
                        setSoundVolume(vol);
                        soundManager.setVolume(vol);
                      }}
                      className="w-full"
                    />
                    <div className="text-xs text-[var(--foreground-muted)] mt-2 text-center">
                      Volume: {Math.round(soundVolume * 100)}%
                    </div>
                  </div>

                  {/* Preset Manager */}
                  <PresetManager
                    presets={presets || []}
                    onAddPreset={handleAddPreset}
                    onUpdatePreset={handleUpdatePreset}
                    onDeletePreset={handleDeletePreset}
                    onSelectPreset={handlePresetSelect}
                    selectedPresetId={selectedPresetId}
                  />
                </motion.div>
              </div>
            </div>
          </div>
        </main>
      </div>

      {/* Modals */}
      <SoundPicker
        isOpen={showSoundPicker}
        onClose={() => setShowSoundPicker(false)}
        selectedSound={selectedSound}
        onSelectSound={setSelectedSound}
      />

      <AmbientPicker
        isOpen={showAmbientPicker}
        onClose={() => setShowAmbientPicker(false)}
        selectedMode={ambientMode}
        onSelectMode={setAmbientMode}
      />

      <TimePicker
        isOpen={showTimePicker}
        onClose={() => setShowTimePicker(false)}
        currentMinutes={Math.floor(totalSeconds / 60)}
        onConfirm={handleLengthConfirm}
      />

      <FullScreenFocus 
        isOpen={isFullScreen} 
        onClose={() => setIsFullScreen(false)} 
      />
    </>
  );
}
