'use client';

import { ReactNode, HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glass' | 'glow';
  hover?: boolean;
  children: ReactNode;
}

export function Card({
  variant = 'default',
  hover = true,
  className,
  children,
  ...props
}: CardProps) {
  const baseStyles = 'card';
  
  const variants = {
    default: '',
    glass: 'card-glass',
    glow: 'card-glow',
  };

  return (
    <div
      className={cn(
        baseStyles,
        variants[variant],
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

