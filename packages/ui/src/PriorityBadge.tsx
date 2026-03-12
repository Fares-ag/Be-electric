import React from 'react';
import { tokens } from './design-tokens';
import type { WorkOrderPriority } from '@beelectric/supabase';

interface PriorityBadgeProps {
  priority: WorkOrderPriority | string;
  children?: React.ReactNode;
}

const priorityColor: Record<string, string> = tokens.priority;

export function PriorityBadge({ priority, children }: PriorityBadgeProps) {
  const color = priorityColor[priority] ?? tokens.colors.secondaryText;
  const label = children ?? String(priority).charAt(0).toUpperCase() + String(priority).slice(1);

  return (
    <span
      style={{
        display: 'inline-block',
        padding: `${tokens.spacing.xs}px ${tokens.spacing.s}px`,
        borderRadius: tokens.radius.button,
        background: color,
        color: '#fff',
        fontFamily: tokens.font.sans,
        fontSize: tokens.font.sizes.small,
        fontWeight: tokens.font.weights.semibold,
      }}
    >
      {label}
    </span>
  );
}
