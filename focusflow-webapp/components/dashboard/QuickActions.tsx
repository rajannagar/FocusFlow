'use client';

import Link from 'next/link';
import { Timer, CheckSquare, TrendingUp, BookOpen, Settings, User, ArrowRight } from 'lucide-react';
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
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-2">Quick Actions</h2>
        <p className="text-[var(--foreground-muted)]">
          Jump to your favorite features
        </p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {actions.map((action, index) => {
          const Icon = action.icon;
          return (
            <motion.div
              key={action.href}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
            >
              <Link href={action.href}>
                <div 
                  className="card p-6 group cursor-pointer h-full transition-all relative overflow-hidden"
                  style={{
                    borderColor: 'var(--accent-primary)20'
                  }}
                >
                  {/* Gradient overlay on hover - more prominent */}
                  <div 
                    className="absolute inset-0 transition-opacity duration-500 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
                    style={{
                      background: `linear-gradient(135deg, var(--accent-primary)15, var(--accent-secondary)15)`,
                    }}
                  />
                  
                  <div className="relative z-10">
                    <div className="flex items-start justify-between mb-4">
                      <div 
                        className="p-3 rounded-xl border group-hover:scale-110 transition-all"
                        style={{
                          background: `linear-gradient(135deg, var(--accent-primary)25, var(--accent-secondary)25)`,
                          borderColor: `var(--accent-primary)40`
                        }}
                      >
                        <Icon 
                          className="w-6 h-6" 
                          style={{ 
                            color: 'var(--accent-primary)',
                            filter: 'brightness(1.15) saturate(1.2)'
                          }} 
                        />
                      </div>
                      <ArrowRight className="w-5 h-5 text-[var(--foreground-muted)] group-hover:text-[var(--foreground)] group-hover:translate-x-1 transition-all" />
                    </div>
                    
                    <h3 className="font-semibold text-lg mb-1">{action.title}</h3>
                    <p className="text-sm text-[var(--foreground-muted)]">
                      {action.href === '/tasks' && totalTasks > 0
                        ? `${totalTasks} ${totalTasks === 1 ? 'task' : 'tasks'}`
                        : action.description}
                    </p>
                  </div>
                </div>
              </Link>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

