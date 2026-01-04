'use client';

import { useState } from 'react';
import type { Task } from '@/types';
import { Edit2, Trash2, Calendar, Clock } from 'lucide-react';
import { format } from 'date-fns';

interface TaskItemProps {
  task: Task;
  onEdit: (task: Task) => void;
  onDelete: (id: string) => void;
  isDeleting?: boolean;
}

export default function TaskItem({ task, onEdit, onDelete, isDeleting = false }: TaskItemProps) {
  const [showActions, setShowActions] = useState(false);

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this task?')) {
      await onDelete(task.id);
    }
  };

  return (
    <div
      className="group p-4 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-all"
      onMouseEnter={() => setShowActions(true)}
      onMouseLeave={() => setShowActions(false)}
    >
      <div className="flex items-start gap-3">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-[var(--foreground)] mb-1 break-words">
            {task.title}
          </h3>
          
          {task.notes && (
            <p className="text-sm text-[var(--foreground-muted)] mb-2 break-words">
              {task.notes}
            </p>
          )}

          <div className="flex items-center gap-4 flex-wrap">
            {task.reminderDate && (
              <div className="flex items-center gap-1.5 text-xs text-[var(--foreground-muted)]">
                <Calendar className="w-3.5 h-3.5" />
                <span>
                  {format(new Date(task.reminderDate), 'MMM d, yyyy')}
                </span>
              </div>
            )}
            
            {task.durationMinutes > 0 && (
              <div className="flex items-center gap-1.5 text-xs text-[var(--foreground-muted)]">
                <Clock className="w-3.5 h-3.5" />
                <span>{task.durationMinutes} min</span>
              </div>
            )}

            {task.repeatRule !== 'none' && (
              <span className="text-xs px-2 py-0.5 rounded-md bg-[var(--accent-primary)]/10 text-[var(--accent-primary)]">
                {task.repeatRule}
              </span>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className={`flex items-center gap-2 transition-opacity ${showActions ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}>
          <button
            onClick={() => onEdit(task)}
            className="p-2 rounded-lg hover:bg-[var(--background)] transition-colors"
            title="Edit task"
          >
            <Edit2 className="w-4 h-4 text-[var(--foreground-muted)] hover:text-[var(--accent-primary)]" />
          </button>
          <button
            onClick={handleDelete}
            disabled={isDeleting}
            className="p-2 rounded-lg hover:bg-[var(--background)] transition-colors disabled:opacity-50"
            title="Delete task"
          >
            <Trash2 className="w-4 h-4 text-[var(--foreground-muted)] hover:text-red-500" />
          </button>
        </div>
      </div>
    </div>
  );
}

