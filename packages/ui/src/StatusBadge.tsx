import React from 'react';
import { tokens } from './design-tokens';
import type { WorkOrderStatus } from '@beelectric/supabase';

interface StatusBadgeProps {
  status: WorkOrderStatus | string;
  children?: React.ReactNode;
}

const statusColor: Record<string, string> = tokens.status;

export function StatusBadge({ status, children }: StatusBadgeProps) {
  const color = statusColor[status] ?? tokens.colors.secondaryText;
  const label = children ?? String(status).replace(/([A-Z])/g, ' $1').trim();

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
