'use client';

import { LucideIcon } from 'lucide-react';

interface ComingSoonCardProps {
  title: string;
  description: string;
  icon: LucideIcon;
}

export default function ComingSoonCard({ title, description, icon: Icon }: ComingSoonCardProps) {
  return (
    <div className="card p-6 opacity-60">
      <div className="flex items-start gap-4">
        <div className="p-3 rounded-xl bg-[var(--background-subtle)] border border-[var(--border)]">
          <Icon className="w-6 h-6 text-[var(--foreground-muted)]" />
        </div>
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-[var(--foreground)] mb-1">{title}</h3>
          <p className="text-sm text-[var(--foreground-muted)]">{description}</p>
          <div className="mt-3">
            <span className="badge badge-secondary">Coming Soon</span>
          </div>
        </div>
      </div>
    </div>
  );
}

