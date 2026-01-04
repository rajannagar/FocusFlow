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
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-2 flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-[var(--accent-secondary)]" />
          Quick Actions
        </h2>
        <p className="text-[var(--foreground-muted)] text-sm">
          Jump to your favorite features
        </p>
      </div>
      
      <div className="grid grid-cols-1 gap-3">
        {actions.map((action, index) => {
          const Icon = action.icon;
          return (
            <motion.div
              key={action.href}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              whileHover={{ x: 4 }}
            >
              <Link href={action.href}>
                <motion.div 
                  className="card p-5 group cursor-pointer transition-all relative overflow-hidden"
                  whileHover={{ x: 6, scale: 1.03 }}
                  transition={{ duration: 0.3 }}
                >
                  {/* Animated gradient background */}
                  <div 
                    className="absolute inset-0 transition-opacity duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
                    style={{
                      background: `var(--accent-gradient)`,
                      opacity: 0.15,
                      animation: 'gradient-shift 3s ease infinite',
                      backgroundSize: '200% 200%',
                    }}
                  />
                  
                  {/* Enhanced glow effect on hover */}
                  <div 
                    className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
                    style={{
                      boxShadow: `0 0 40px var(--accent-glow), 0 0 80px var(--accent-glow-subtle)`,
                      animation: 'glow-pulse 2s ease-in-out infinite',
                    }}
                  />
                  
                  {/* Color shift effect */}
                  <div 
                    className="absolute inset-0 transition-all duration-700 pointer-events-none rounded-2xl opacity-0 group-hover:opacity-100"
                    style={{
                      background: `radial-gradient(circle at center, var(--accent-glow-subtle), transparent 70%)`,
                      animation: 'float-gradient 4s ease-in-out infinite',
                    }}
                  />
                  
                  <div className="relative z-10 flex items-center gap-4">
                    <motion.div 
                      className="p-3 rounded-xl flex-shrink-0 relative overflow-hidden"
                      style={{
                        background: `var(--accent-gradient)`,
                        backgroundSize: '200% 200%',
                      }}
                      whileHover={{ scale: 1.15, rotate: 5 }}
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
                      <Icon 
                        className="w-5 h-5 relative z-10" 
                        style={{ 
                          color: 'white',
                          filter: 'brightness(1.2) drop-shadow(0 0 8px rgba(255,255,255,0.5))'
                        }} 
                      />
                    </motion.div>
                    
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-base mb-0.5 group-hover:text-[var(--accent-primary)] transition-colors">
                        {action.title}
                      </h3>
                      <p className="text-xs text-[var(--foreground-muted)] truncate">
                        {action.href === '/tasks' && totalTasks > 0
                          ? `${totalTasks} ${totalTasks === 1 ? 'task' : 'tasks'}`
                          : action.description}
                      </p>
                    </div>
                    
                    <ArrowRight className="w-4 h-4 text-[var(--foreground-muted)] group-hover:text-[var(--accent-primary)] group-hover:translate-x-1 transition-all flex-shrink-0" />
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

