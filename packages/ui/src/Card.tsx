import React from 'react';
import { tokens } from './design-tokens';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  elevation?: 0 | 1 | 2;
}

export function Card({ children, elevation = 2, style, ...props }: CardProps) {
  return (
    <div
      style={{
        background: tokens.colors.surface,
        borderRadius: tokens.radius.card,
        padding: tokens.spacing.l,
        boxShadow:
          elevation === 2
            ? '0 2px 8px rgba(0,0,0,0.08)'
            : elevation === 1
              ? '0 1px 4px rgba(0,0,0,0.06)'
              : 'none',
        ...style,
      }}
      {...props}
    >
      {children}
    </div>
  );
}
