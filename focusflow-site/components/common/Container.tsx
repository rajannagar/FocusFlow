import { ReactNode } from 'react';

interface ContainerProps {
  children: ReactNode;
  className?: string;
}

/**
 * Responsive container component with consistent max-width and padding
 */
export default function Container({ children, className = '' }: ContainerProps) {
  return (
    <div className={`container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 ${className}`}>
      {children}
    </div>
  );
}

