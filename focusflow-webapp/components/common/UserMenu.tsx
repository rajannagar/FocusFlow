'use client';

import { useState, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { User, LogOut, ChevronDown } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export default function UserMenu() {
  const { user, signOut } = useAuth();
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const handleSignOut = async () => {
    await signOut();
    router.push('/signin');
  };

  const handleProfileClick = () => {
    setIsOpen(false);
    router.push('/profile');
  };

  if (!user?.email) {
    return null;
  }

  // Get display email (truncate if too long)
  const displayEmail = user.email.length > 25 
    ? `${user.email.substring(0, 22)}...` 
    : user.email;

  return (
    <div className="relative" ref={menuRef}>
      {/* User Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-[var(--background-subtle)] transition-colors text-sm font-medium text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--accent-primary)] focus:ring-offset-2 focus:ring-offset-[var(--background)]"
        aria-label="User menu"
        aria-expanded={isOpen}
      >
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 flex items-center justify-center border border-[var(--border)]">
          <User className="w-4 h-4 text-[var(--accent-primary)]" strokeWidth={2} />
        </div>
        <span className="hidden sm:inline text-[var(--foreground-muted)]">
          {displayEmail}
        </span>
        <ChevronDown 
          className={`w-4 h-4 text-[var(--foreground-muted)] transition-transform ${isOpen ? 'rotate-180' : ''}`}
          strokeWidth={2}
        />
      </button>

      {/* Dropdown Menu */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-40"
              onClick={() => setIsOpen(false)}
            />
            
            {/* Menu */}
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              transition={{ duration: 0.2 }}
              className="absolute right-0 top-full mt-2 w-56 rounded-xl bg-[var(--background-elevated)] border border-[var(--border)] shadow-lg z-50 overflow-hidden"
            >
              {/* User Info */}
              <div className="px-4 py-3 border-b border-[var(--border)]">
                <p className="text-xs font-medium text-[var(--foreground-muted)] uppercase tracking-wider mb-1">
                  Signed in as
                </p>
                <p className="text-sm font-medium text-[var(--foreground)] truncate">
                  {user.email}
                </p>
              </div>

              {/* Menu Items */}
              <div className="py-1">
                <button
                  onClick={handleProfileClick}
                  className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-colors text-left"
                >
                  <User className="w-4 h-4 text-[var(--foreground-muted)]" strokeWidth={2} />
                  <span>Profile</span>
                </button>
                
                <button
                  onClick={handleSignOut}
                  className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-colors text-left"
                >
                  <LogOut className="w-4 h-4 text-[var(--foreground-muted)]" strokeWidth={2} />
                  <span>Sign out</span>
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}

