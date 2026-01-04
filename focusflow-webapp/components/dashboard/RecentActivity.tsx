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
    <div>
      {/* Section Header - Matching main site style */}
      <div className="mb-8 md:mb-12">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
          <Clock className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
          <span>Recent Activity</span>
        </div>
        <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 leading-tight">
          Your latest <span className="text-gradient">focus moments</span>
        </h2>
        <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed font-light max-w-2xl">
          See what you've accomplished recently
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">
        {/* Recent Sessions */}
        {(sessions.length > 0 || loading) && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
          >
            <div className="relative p-6 md:p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-xl md:text-2xl font-bold mb-1 flex items-center gap-2">
                    <Clock className="w-5 h-5 text-[var(--accent-primary)]" strokeWidth={1.5} />
                    Recent Sessions
                  </h3>
                  <p className="text-sm md:text-base text-[var(--foreground-muted)] font-light">
                    Your latest focus sessions
                  </p>
                </div>
                <Link 
                  href="/progress" 
                  className="text-sm font-medium text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] flex items-center gap-1 transition-colors group"
                >
                  View all
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" strokeWidth={2} />
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
                    whileHover={{ x: 4, scale: 1.01 }}
                    className="flex items-center justify-between p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/20 transition-all group cursor-pointer relative overflow-hidden"
                  >
                    {/* Subtle gradient on hover */}
                    <div 
                      className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                      style={{
                        background: `linear-gradient(90deg, var(--accent-glow-subtle), transparent)`,
                      }}
                    />
                    
                    <div className="flex items-center gap-3 flex-1 min-w-0 relative z-10">
                      <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                        <Clock 
                          className="w-5 h-5 text-[var(--accent-primary)]" 
                          strokeWidth={1.5}
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-semibold text-[var(--foreground)] truncate">
                          {session.sessionName || 'Focus Session'}
                        </p>
                        <p className="text-xs text-[var(--foreground-muted)] mt-0.5">
                          {new Date(session.startedAt).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            hour: 'numeric',
                            minute: '2-digit',
                          })}
                        </p>
                      </div>
                    </div>
                    <div className="text-sm font-semibold text-[var(--foreground)] ml-4">
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
            <div className="relative p-6 md:p-8 rounded-3xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-xl md:text-2xl font-bold mb-1 flex items-center gap-2">
                    <CheckSquare className="w-5 h-5 text-[var(--accent-secondary)]" strokeWidth={1.5} />
                    Active Tasks
                  </h3>
                  <p className="text-sm md:text-base text-[var(--foreground-muted)] font-light">
                    Tasks you're working on
                  </p>
                </div>
                <Link 
                  href="/tasks" 
                  className="text-sm font-medium text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] flex items-center gap-1 transition-colors group"
                >
                  View all
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" strokeWidth={2} />
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
                    whileHover={{ x: 4, scale: 1.01 }}
                    className="flex items-center gap-3 p-4 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-secondary)]/20 transition-all group cursor-pointer relative overflow-hidden"
                  >
                    {/* Subtle gradient on hover */}
                    <div 
                      className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                      style={{
                        background: `linear-gradient(90deg, var(--accent-secondary-glow), transparent)`,
                      }}
                    />
                    
                    <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-[var(--accent-secondary)]/20 to-[var(--accent-secondary)]/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                      <CheckSquare 
                        className="w-5 h-5 text-[var(--accent-secondary)]" 
                        strokeWidth={1.5}
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-[var(--foreground)] truncate">{task.title}</p>
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
    </div>
  );
}

