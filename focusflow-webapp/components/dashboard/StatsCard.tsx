'use client';

import { LucideIcon } from 'lucide-react';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  description?: string;
}

export default function StatsCard({ title, value, icon: Icon, description }: StatsCardProps) {
  return (
    <div className="card p-6">
      <div className="flex items-start justify-between mb-4">
        <div>
          <p className="text-sm text-[var(--foreground-muted)] mb-1">{title}</p>
          <p className="text-2xl md:text-3xl font-bold text-[var(--foreground)]">{value}</p>
        </div>
        <div className="p-3 rounded-xl bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20">
          <Icon className="w-5 h-5 text-[var(--accent-primary)]" />
        </div>
      </div>
      {description && (
        <p className="text-xs text-[var(--foreground-subtle)]">{description}</p>
      )}
    </div>
  );
}

