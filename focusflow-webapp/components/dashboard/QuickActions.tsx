'use client';

import Link from 'next/link';
import { Timer, CheckSquare, TrendingUp, BookOpen, Settings, User, ArrowRight, Sparkles } from 'lucide-react';
import { motion } from 'framer-motion';

interface QuickActionsProps {
  totalTasks: number;
}

const actions = [
  {
    href: '/focus',
    icon: Timer,
    title: 'Focus Timer',
    description: 'Start a focus session',
    gradient: 'from-[var(--accent-primary)] to-[var(--accent-primary-dark)]',
  },
  {
    href: '/tasks',
    icon: CheckSquare,
    title: 'Tasks',
    description: 'Manage your to-dos',
    gradient: 'from-[var(--accent-secondary)] to-[var(--accent-secondary-light)]',
  },
  {
    href: '/progress',
    icon: TrendingUp,
    title: 'Progress',
    description: 'View analytics',
    gradient: 'from-[var(--accent-primary)] to-[var(--accent-secondary)]',
  },
  {
    href: '/journey',
    icon: BookOpen,
    title: 'Journey',
    description: 'Your focus story',
    gradient: 'from-[var(--accent-secondary)] to-[var(--accent-primary)]',
  },
];

export function QuickActions({ totalTasks }: QuickActionsProps) {
  return (
    <div>
      {/* Header - Matching main site style */}
      <div className="mb-8">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] text-sm text-[var(--foreground-muted)] mb-4">
          <Sparkles className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
          <span>Quick Access</span>
        </div>
        <h2 className="text-2xl md:text-3xl font-bold mb-2 leading-tight">
          Jump to <span className="text-gradient">features</span>
        </h2>
        <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed font-light">
          Navigate to your favorite tools
        </p>
      </div>
      
      {/* Actions Grid - Premium Cards */}
      <div className="grid grid-cols-1 gap-4">
        {actions.map((action, index) => {
          const Icon = action.icon;
          return (
            <motion.div
              key={action.href}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
            >
              <Link href={action.href}>
                <motion.div 
                  className="group relative p-6 rounded-2xl bg-[var(--background-elevated)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-all duration-500 hover:shadow-xl hover:shadow-[var(--accent-primary)]/10"
                  whileHover={{ x: 4, scale: 1.02 }}
                  transition={{ duration: 0.3 }}
                >
                  {/* Subtle gradient background on hover - matching main site */}
                  <div 
                    className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                    style={{
                      background: `var(--accent-gradient)`,
                      opacity: 0.08,
                    }}
                  />
                  
                  <div className="relative z-10 flex items-center gap-4">
                    {/* Icon Container - Premium style */}
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform shadow-md">
                      <Icon 
                        className="w-6 h-6 text-[var(--accent-primary)]" 
                        strokeWidth={1.5}
                      />
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <h3 className="text-lg font-semibold text-[var(--foreground)] mb-1 group-hover:text-[var(--accent-primary)] transition-colors">
                        {action.title}
                      </h3>
                      <p className="text-sm text-[var(--foreground-muted)]">
                        {action.href === '/tasks' && totalTasks > 0
                          ? `${totalTasks} ${totalTasks === 1 ? 'task' : 'tasks'}`
                          : action.description}
                      </p>
                    </div>
                    
                    <ArrowRight className="w-5 h-5 text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)] group-hover:translate-x-1 transition-all flex-shrink-0" strokeWidth={2} />
                  </div>
                </motion.div>
              </Link>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

