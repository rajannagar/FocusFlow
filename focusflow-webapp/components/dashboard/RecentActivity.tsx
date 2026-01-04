'use client';

import Link from 'next/link';
import { Clock, CheckSquare, ArrowRight } from 'lucide-react';
import { formatDuration } from '@/lib/utils';
import { motion } from 'framer-motion';
import type { FocusSession } from '@/types';
import type { Task } from '@/types';

interface RecentActivityProps {
  sessions: FocusSession[];
  tasks: Task[];
  loading?: boolean;
}

export function RecentActivity({ sessions, tasks, loading }: RecentActivityProps) {
  // Don't render if both are empty
  if (!loading && sessions.length === 0 && tasks.length === 0) {
    return null;
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Recent Sessions */}
      {(sessions.length > 0 || loading) && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
        >
          <div className="card p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl font-bold mb-1">Recent Sessions</h3>
                <p className="text-sm text-[var(--foreground-muted)]">
                  Your latest focus sessions
                </p>
              </div>
              <Link 
                href="/progress" 
                className="text-sm text-[var(--accent-primary)] hover:underline flex items-center gap-1"
              >
                View all
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            
            <div className="space-y-3">
              {loading ? (
                [...Array(3)].map((_, i) => (
                  <div key={i} className="h-16 bg-[var(--background-subtle)] rounded-xl animate-pulse" />
                ))
              ) : (
                sessions.slice(0, 5).map((session, index) => (
                  <motion.div
                    key={session.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.3, delay: index * 0.1 }}
                    className="flex items-center justify-between p-4 rounded-xl bg-[var(--background-subtle)] border transition-all group"
                    style={{
                      borderColor: 'var(--accent-primary)15',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.borderColor = 'var(--accent-primary)30';
                      e.currentTarget.style.backgroundColor = 'var(--background-muted)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.borderColor = 'var(--accent-primary)15';
                      e.currentTarget.style.backgroundColor = 'var(--background-subtle)';
                    }}
                  >
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <div 
                        className="p-2 rounded-lg border group-hover:scale-110 transition-transform"
                        style={{
                          backgroundColor: 'var(--accent-primary)15',
                          borderColor: 'var(--accent-primary)30'
                        }}
                      >
                        <Clock 
                          className="w-4 h-4" 
                          style={{ 
                            color: 'var(--accent-primary)',
                            filter: 'brightness(1.2)'
                          }} 
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">
                          {session.sessionName || 'Focus Session'}
                        </p>
                        <p className="text-xs text-[var(--foreground-muted)]">
                          {new Date(session.startedAt).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            hour: 'numeric',
                            minute: '2-digit',
                          })}
                        </p>
                      </div>
                    </div>
                    <div className="text-sm font-semibold ml-4">
                      {formatDuration(session.durationSeconds)}
                    </div>
                  </motion.div>
                ))
              )}
            </div>
          </div>
        </motion.div>
      )}

      {/* Active Tasks */}
      {(tasks.length > 0 || loading) && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <div className="card p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl font-bold mb-1">Active Tasks</h3>
                <p className="text-sm text-[var(--foreground-muted)]">
                  Tasks you're working on
                </p>
              </div>
              <Link 
                href="/tasks" 
                className="text-sm text-[var(--accent-primary)] hover:underline flex items-center gap-1"
              >
                View all
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            
            <div className="space-y-3">
              {loading ? (
                [...Array(3)].map((_, i) => (
                  <div key={i} className="h-16 bg-[var(--background-subtle)] rounded-xl animate-pulse" />
                ))
              ) : (
                tasks.slice(0, 5).map((task, index) => (
                  <motion.div
                    key={task.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.3, delay: index * 0.1 }}
                    className="flex items-center gap-3 p-4 rounded-xl bg-[var(--background-subtle)] border transition-all group"
                    style={{
                      borderColor: 'var(--accent-secondary)15',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.borderColor = 'var(--accent-secondary)30';
                      e.currentTarget.style.backgroundColor = 'var(--background-muted)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.borderColor = 'var(--accent-secondary)15';
                      e.currentTarget.style.backgroundColor = 'var(--background-subtle)';
                    }}
                  >
                    <div 
                      className="p-2 rounded-lg border group-hover:scale-110 transition-transform"
                      style={{
                        backgroundColor: 'var(--accent-secondary)15',
                        borderColor: 'var(--accent-secondary)30'
                      }}
                    >
                      <CheckSquare 
                        className="w-4 h-4" 
                        style={{ 
                          color: 'var(--accent-secondary)',
                          filter: 'brightness(1.2)'
                        }} 
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{task.title}</p>
                      {task.notes && (
                        <p className="text-xs text-[var(--foreground-muted)] truncate mt-0.5">
                          {task.notes}
                        </p>
                      )}
                    </div>
                  </motion.div>
                ))
              )}
            </div>
          </div>
        </motion.div>
      )}
    </div>
  );
}

