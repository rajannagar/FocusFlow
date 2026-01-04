'use client';

import { useState } from 'react';
import { Plus, Edit2, Trash2, X, Save } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import type { FocusPreset } from '@/types';
import { focusSounds } from '@/lib/focusSounds';
import type { AmbientMode } from './AmbientBackground';
import { Button } from '@/components/common/Button';

interface PresetManagerProps {
  presets: FocusPreset[];
  onAddPreset: (preset: Omit<FocusPreset, 'id'>) => void;
  onUpdatePreset: (id: string, updates: Partial<FocusPreset>) => void;
  onDeletePreset: (id: string) => void;
  onSelectPreset: (preset: FocusPreset) => void;
  selectedPresetId: string | null;
}

export function PresetManager({
  presets,
  onAddPreset,
  onUpdatePreset,
  onDeletePreset,
  onSelectPreset,
  selectedPresetId,
}: PresetManagerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    durationMinutes: 25,
    soundID: '',
    emoji: '🎯',
    ambianceMode: 'minimal' as AmbientMode,
  });

  const handleAdd = () => {
    if (!formData.name.trim()) return;
    
    onAddPreset({
      name: formData.name,
      durationSeconds: formData.durationMinutes * 60,
      soundID: formData.soundID,
      emoji: formData.emoji,
      isSystemDefault: false,
      ambianceModeRaw: formData.ambianceMode,
    });
    
    setFormData({
      name: '',
      durationMinutes: 25,
      soundID: '',
      emoji: '🎯',
      ambianceMode: 'minimal',
    });
  };

  const handleEdit = (preset: FocusPreset) => {
    setEditingId(preset.id);
    setFormData({
      name: preset.name,
      durationMinutes: Math.floor(preset.durationSeconds / 60),
      soundID: preset.soundID || '',
      emoji: preset.emoji || '🎯',
      ambianceMode: (preset.ambianceModeRaw as AmbientMode) || 'minimal',
    });
  };

  const handleSave = () => {
    if (!editingId || !formData.name.trim()) return;
    
    onUpdatePreset(editingId, {
      name: formData.name,
      durationSeconds: formData.durationMinutes * 60,
      soundID: formData.soundID,
      emoji: formData.emoji,
      ambianceModeRaw: formData.ambianceMode,
    });
    
    setEditingId(null);
    setFormData({
      name: '',
      durationMinutes: 25,
      soundID: '',
      emoji: '🎯',
      ambianceMode: 'minimal',
    });
  };

  const handleCancel = () => {
    setEditingId(null);
    setFormData({
      name: '',
      durationMinutes: 25,
      soundID: '',
      emoji: '🎯',
      ambianceMode: 'minimal',
    });
  };

  return (
    <>
      <Button
        variant="secondary"
        onClick={() => setIsOpen(true)}
        className="w-full"
      >
        <Plus className="w-4 h-4" />
        Manage Presets
      </Button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
            onClick={() => setIsOpen(false)}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="relative w-full max-w-2xl mx-4 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
            >
              {/* Header */}
              <div className="flex items-center justify-between p-6 border-b border-[var(--border)]">
                <div>
                  <h3 className="text-xl font-bold text-[var(--foreground)]">Preset Manager</h3>
                  <p className="text-sm text-[var(--foreground-muted)] mt-1">Create and manage your focus presets</p>
                </div>
                <button
                  onClick={() => setIsOpen(false)}
                  className="w-8 h-8 rounded-lg hover:bg-[var(--background-subtle)] flex items-center justify-center transition-colors"
                >
                  <X className="w-5 h-5 text-[var(--foreground-muted)]" />
                </button>
              </div>

              {/* Content */}
              <div className="flex-1 overflow-y-auto p-6">
                {/* Form */}
                <div className="mb-6 p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)]">
                  <h4 className="text-sm font-semibold text-[var(--foreground)] mb-4">
                    {editingId ? 'Edit Preset' : 'Create New Preset'}
                  </h4>
                  
                  <div className="space-y-4">
                    <div>
                      <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block">
                        Name
                      </label>
                      <input
                        type="text"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        placeholder="e.g., Deep Work"
                        className="w-full px-4 py-2 rounded-lg bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] placeholder:text-[var(--foreground-muted)] focus:outline-none focus:border-[var(--accent-primary)]/50"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block">
                          Duration (minutes)
                        </label>
                        <input
                          type="number"
                          min="1"
                          max="480"
                          value={formData.durationMinutes}
                          onChange={(e) => setFormData({ ...formData, durationMinutes: parseInt(e.target.value) || 25 })}
                          className="w-full px-4 py-2 rounded-lg bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:border-[var(--accent-primary)]/50"
                        />
                      </div>

                      <div>
                        <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block">
                          Emoji
                        </label>
                        <input
                          type="text"
                          maxLength={2}
                          value={formData.emoji}
                          onChange={(e) => setFormData({ ...formData, emoji: e.target.value })}
                          placeholder="🎯"
                          className="w-full px-4 py-2 rounded-lg bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:border-[var(--accent-primary)]/50"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-xs font-medium text-[var(--foreground-muted)] mb-2 block">
                        Sound
                      </label>
                      <select
                        value={formData.soundID}
                        onChange={(e) => setFormData({ ...formData, soundID: e.target.value })}
                        className="w-full px-4 py-2 rounded-lg bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:border-[var(--accent-primary)]/50"
                      >
                        <option value="">None</option>
                        {focusSounds.map((sound) => (
                          <option key={sound.id} value={sound.id}>
                            {sound.emoji} {sound.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="flex gap-2">
                      {editingId ? (
                        <>
                          <Button variant="accent" onClick={handleSave} className="flex-1">
                            <Save className="w-4 h-4" />
                            Save
                          </Button>
                          <Button variant="secondary" onClick={handleCancel} className="flex-1">
                            Cancel
                          </Button>
                        </>
                      ) : (
                        <Button variant="accent" onClick={handleAdd} className="flex-1" disabled={!formData.name.trim()}>
                          <Plus className="w-4 h-4" />
                          Add Preset
                        </Button>
                      )}
                    </div>
                  </div>
                </div>

                {/* Presets List */}
                <div>
                  <h4 className="text-sm font-semibold text-[var(--foreground)] mb-4">Your Presets</h4>
                  <div className="space-y-2">
                    {presets.map((preset) => {
                      const minutes = Math.floor(preset.durationSeconds / 60);
                      const isSelected = selectedPresetId === preset.id;
                      
                      return (
                        <div
                          key={preset.id}
                          className={`p-4 rounded-xl border transition-all ${
                            isSelected
                              ? 'bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/10 border-[var(--accent-primary)]'
                              : 'bg-[var(--background-subtle)] border-[var(--border)] hover:border-[var(--accent-primary)]/30'
                          }`}
                        >
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3 flex-1">
                              <span className="text-2xl">{preset.emoji || '🎯'}</span>
                              <div className="flex-1 min-w-0">
                                <div className="font-semibold text-[var(--foreground)]">{preset.name}</div>
                                <div className="text-xs text-[var(--foreground-muted)]">
                                  {minutes}m • {preset.soundID ? focusSounds.find(s => s.id === preset.soundID)?.name || 'Sound' : 'No sound'}
                                </div>
                              </div>
                            </div>
                            <div className="flex items-center gap-2">
                              <button
                                onClick={() => onSelectPreset(preset)}
                                className="px-3 py-1.5 text-xs font-medium rounded-lg bg-[var(--accent-primary)]/10 text-[var(--accent-primary)] hover:bg-[var(--accent-primary)]/20 transition-colors"
                              >
                                Use
                              </button>
                              {!preset.isSystemDefault && (
                                <>
                                  <button
                                    onClick={() => handleEdit(preset)}
                                    className="w-8 h-8 rounded-lg hover:bg-[var(--background-elevated)] flex items-center justify-center transition-colors"
                                  >
                                    <Edit2 className="w-4 h-4 text-[var(--foreground-muted)]" />
                                  </button>
                                  <button
                                    onClick={() => {
                                      if (confirm(`Delete "${preset.name}"?`)) {
                                        onDeletePreset(preset.id);
                                      }
                                    }}
                                    className="w-8 h-8 rounded-lg hover:bg-red-500/10 flex items-center justify-center transition-colors"
                                  >
                                    <Trash2 className="w-4 h-4 text-red-500" />
                                  </button>
                                </>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}

