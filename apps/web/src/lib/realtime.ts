import { supabase } from './supabase';
import type { RealtimeChannel } from '@supabase/supabase-js';

export function subscribeWorkOrders(
  onInsert?: (payload: unknown) => void,
  onUpdate?: (payload: unknown) => void,
  onDelete?: (payload: unknown) => void
): RealtimeChannel {
  const channel = supabase
    .channel('work-orders-changes')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'work_orders' },
      (payload) => onInsert?.(payload)
    )
    .on(
      'postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'work_orders' },
      (payload) => onUpdate?.(payload)
    )
    .on(
      'postgres_changes',
      { event: 'DELETE', schema: 'public', table: 'work_orders' },
      (payload) => onDelete?.(payload)
    )
    .subscribe();
  return channel;
}

export function subscribeNotifications(
  userId: string,
  onInsert: (payload: unknown) => void
): RealtimeChannel {
  const channel = supabase
    .channel('notifications-changes')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `userId=eq.${userId}`,
      },
      (payload) => onInsert(payload)
    )
    .subscribe();
  return channel;
}

export function subscribePMTasks(
  onInsert?: (payload: unknown) => void,
  onUpdate?: (payload: unknown) => void
): RealtimeChannel {
  const channel = supabase
    .channel('pm-tasks-changes')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'pm_tasks' },
      (payload) => onInsert?.(payload)
    )
    .on(
      'postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'pm_tasks' },
      (payload) => onUpdate?.(payload)
    )
    .subscribe();
  return channel;
}
