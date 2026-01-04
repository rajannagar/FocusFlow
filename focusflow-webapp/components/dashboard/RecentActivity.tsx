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
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">
      {/* Recent Sessions */}
      {(sessions.length > 0 || loading) && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
        >
          <div className="card p-6 lg:p-8">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl lg:text-2xl font-bold mb-1 flex items-center gap-2">
                  <Clock className="w-5 h-5 text-[var(--accent-primary)]" />
                  Recent Sessions
                </h3>
                <p className="text-sm text-[var(--foreground-muted)]">
                  Your latest focus sessions
                </p>
              </div>
              <Link 
                href="/progress" 
                className="text-sm text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] flex items-center gap-1 transition-colors group"
              >
                View all
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
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
                    whileHover={{ x: 6, scale: 1.02 }}
                    className="flex items-center justify-between p-4 rounded-xl bg-[var(--background-subtle)] transition-all group cursor-pointer relative overflow-hidden"
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = 'var(--background-muted)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = 'var(--background-subtle)';
                    }}
                  >
                    {/* Animated gradient on hover */}
                    <div 
                      className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                      style={{
                        background: `linear-gradient(90deg, var(--accent-glow-subtle), transparent)`,
                      }}
                    />
                    
                    <div className="flex items-center gap-3 flex-1 min-w-0 relative z-10">
                      <motion.div 
                        className="p-2 rounded-lg relative overflow-hidden"
                        style={{
                          background: `var(--accent-gradient)`,
                          backgroundSize: '200% 200%',
                        }}
                        whileHover={{ scale: 1.2, rotate: 5 }}
                        transition={{ duration: 0.3 }}
                      >
                        {/* Animated gradient overlay */}
                        <div 
                          className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                          style={{
                            background: `var(--accent-gradient-reverse)`,
                            animation: 'gradient-shift 2s ease infinite',
                            backgroundSize: '200% 200%',
                          }}
                        />
                        <Clock 
                          className="w-4 h-4 relative z-10" 
                          style={{ 
                            color: 'white',
                            filter: 'drop-shadow(0 0 4px rgba(255,255,255,0.5))'
                          }} 
                        />
                      </motion.div>
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
          <div className="card p-6 lg:p-8">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl lg:text-2xl font-bold mb-1 flex items-center gap-2">
                  <CheckSquare className="w-5 h-5 text-[var(--accent-secondary)]" />
                  Active Tasks
                </h3>
                <p className="text-sm text-[var(--foreground-muted)]">
                  Tasks you're working on
                </p>
              </div>
              <Link 
                href="/tasks" 
                className="text-sm text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] flex items-center gap-1 transition-colors group"
              >
                View all
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
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
                    whileHover={{ x: 6, scale: 1.02 }}
                    className="flex items-center gap-3 p-4 rounded-xl bg-[var(--background-subtle)] transition-all group cursor-pointer relative overflow-hidden"
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = 'var(--background-muted)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = 'var(--background-subtle)';
                    }}
                  >
                    {/* Animated gradient on hover */}
                    <div 
                      className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                      style={{
                        background: `linear-gradient(90deg, var(--accent-secondary-glow), transparent)`,
                      }}
                    />
                    
                    <motion.div 
                      className="p-2 rounded-lg relative overflow-hidden"
                      style={{
                        background: `var(--accent-gradient-reverse)`,
                        backgroundSize: '200% 200%',
                      }}
                      whileHover={{ scale: 1.2, rotate: 5 }}
                      transition={{ duration: 0.3 }}
                    >
                      {/* Animated gradient overlay */}
                      <div 
                        className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                        style={{
                          background: `var(--accent-gradient)`,
                          animation: 'gradient-shift 2s ease infinite',
                          backgroundSize: '200% 200%',
                        }}
                      />
                      <CheckSquare 
                        className="w-4 h-4 relative z-10" 
                        style={{ 
                          color: 'white',
                          filter: 'drop-shadow(0 0 4px rgba(255,255,255,0.5))'
                        }} 
                      />
                    </motion.div>
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

