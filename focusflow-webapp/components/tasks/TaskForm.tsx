'use client';

import { useState, useEffect } from 'react';
import type { Task, TaskRepeatRule } from '@/types';
import { X, Save } from 'lucide-react';

interface TaskFormProps {
  task?: Task | null;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (task: Omit<Task, 'id' | 'createdAt'>) => Promise<void>;
  isSubmitting?: boolean;
}

export default function TaskForm({ task, isOpen, onClose, onSubmit, isSubmitting = false }: TaskFormProps) {
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [reminderDate, setReminderDate] = useState<string>('');
  const [durationMinutes, setDurationMinutes] = useState(0);
  const [repeatRule, setRepeatRule] = useState<TaskRepeatRule>('none');

  useEffect(() => {
    if (task) {
      setTitle(task.title || '');
      setNotes(task.notes || '');
      setReminderDate(task.reminderDate ? (typeof task.reminderDate === 'string' ? task.reminderDate.split('T')[0] : new Date(task.reminderDate).toISOString().split('T')[0]) : '');
      setDurationMinutes(task.durationMinutes || 0);
      setRepeatRule(task.repeatRule || 'none');
    } else {
      setTitle('');
      setNotes('');
      setReminderDate('');
      setDurationMinutes(0);
      setRepeatRule('none');
    }
  }, [task, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) {
      return;
    }

    await onSubmit({
      sortIndex: task?.sortIndex || 0,
      title: title.trim(),
      notes: notes.trim() || undefined,
      reminderDate: reminderDate ? new Date(reminderDate).toISOString() : undefined,
      repeatRule,
      customWeekdays: task?.customWeekdays || [],
      durationMinutes,
      convertToPreset: task?.convertToPreset || false,
      presetCreated: task?.presetCreated || false,
      excludedDayKeys: task?.excludedDayKeys || [],
    });

    // Reset form if creating new task
    if (!task) {
      setTitle('');
      setNotes('');
      setReminderDate('');
      setDurationMinutes(0);
      setRepeatRule('none');
    }
    
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="card w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-[var(--border)]">
          <h2 className="text-2xl font-bold">
            {task ? 'Edit Task' : 'New Task'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 rounded-lg hover:bg-[var(--background-elevated)] transition-colors"
            disabled={isSubmitting}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Title */}
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-[var(--foreground-muted)] mb-2">
              Title <span className="text-red-500">*</span>
            </label>
            <input
              id="title"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] placeholder:text-[var(--foreground-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] transition-all"
              placeholder="Enter task title"
              required
              disabled={isSubmitting}
            />
          </div>

          {/* Notes */}
          <div>
            <label htmlFor="notes" className="block text-sm font-medium text-[var(--foreground-muted)] mb-2">
              Notes
            </label>
            <textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={4}
              className="w-full px-4 py-2.5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] placeholder:text-[var(--foreground-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] transition-all resize-none"
              placeholder="Add notes or description..."
              disabled={isSubmitting}
            />
          </div>

          {/* Reminder Date */}
          <div>
            <label htmlFor="reminderDate" className="block text-sm font-medium text-[var(--foreground-muted)] mb-2">
              Reminder Date
            </label>
            <input
              id="reminderDate"
              type="date"
              value={reminderDate}
              onChange={(e) => setReminderDate(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] transition-all"
              disabled={isSubmitting}
            />
          </div>

          {/* Duration */}
          <div>
            <label htmlFor="duration" className="block text-sm font-medium text-[var(--foreground-muted)] mb-2">
              Duration (minutes)
            </label>
            <input
              id="duration"
              type="number"
              min="0"
              value={durationMinutes}
              onChange={(e) => setDurationMinutes(parseInt(e.target.value) || 0)}
              className="w-full px-4 py-2.5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] transition-all"
              placeholder="0"
              disabled={isSubmitting}
            />
          </div>

          {/* Repeat Rule */}
          <div>
            <label htmlFor="repeatRule" className="block text-sm font-medium text-[var(--foreground-muted)] mb-2">
              Repeat
            </label>
            <select
              id="repeatRule"
              value={repeatRule}
              onChange={(e) => setRepeatRule(e.target.value as TaskRepeatRule)}
              className="w-full px-4 py-2.5 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] transition-all"
              disabled={isSubmitting}
            >
              <option value="none">None</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
              <option value="yearly">Yearly</option>
            </select>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-[var(--border)]">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 rounded-xl border border-[var(--border)] text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-elevated)] transition-all"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2.5 rounded-xl bg-[var(--accent-primary)] text-white hover:opacity-90 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={isSubmitting || !title.trim()}
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Saving...</span>
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  <span>{task ? 'Save Changes' : 'Create Task'}</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

