'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import { Sidebar } from '@/components/layout/Sidebar';
import FocusTimer from '@/components/focus/FocusTimer';
import { FullScreenFocus } from '@/components/focus/FullScreenFocus';
import { usePresets } from '@/hooks/supabase/usePresets';
import { Maximize2 } from 'lucide-react';
import { Button } from '@/components/common/Button';

export default function FocusPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [isFullScreen, setIsFullScreen] = useState(false);
  
  // Sync auth state with stores
  useSyncAuth();
  useOnlineStatus();
  
  // Fetch presets
  const userId = user?.id;
  const { presets } = usePresets(userId);
  
  useEffect(() => {
    if (!loading && !user) {
      router.push('/signin');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="text-[var(--foreground-muted)]">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null; // Will redirect
  }

  return (
    <>
      <div className="min-h-screen flex bg-[var(--background)]">
        <Sidebar />
        
        <main className="flex-1 flex flex-col lg:ml-0">
          {/* Top Bar */}
          <div className="sticky top-0 z-30 bg-[var(--background-elevated)]/80 backdrop-blur-xl border-b border-[var(--border)] px-6 py-4">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold">Focus Timer</h1>
                <p className="text-sm text-[var(--foreground-muted)] mt-1">
                  Start a focus session and track your deep work time
                </p>
              </div>
              <Button
                variant="secondary"
                onClick={() => setIsFullScreen(true)}
                className="flex items-center gap-2"
              >
                <Maximize2 className="w-4 h-4" />
                Full Screen
              </Button>
            </div>
          </div>

          {/* Main Content */}
          <div className="flex-1 overflow-y-auto">
            <div className="max-w-4xl mx-auto p-6">
              <FocusTimer />
            </div>
          </div>
        </main>
      </div>

      {/* Full Screen Focus Mode */}
      <FullScreenFocus 
        isOpen={isFullScreen} 
        onClose={() => setIsFullScreen(false)} 
      />
    </>
  );
}
