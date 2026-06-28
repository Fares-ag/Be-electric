'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '@/stores/auth-store';
import { subscribeWorkOrders, subscribeNotifications, subscribePMTasks, subscribePmOccurrences } from '@/lib/realtime';

export function useRealtimeSubscriptions() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const authUser = useAuthStore((s) => s.authUser);

  useEffect(() => {
    if (!user && !authUser) return;

    const userId = user?.id ?? authUser?.id;
    const invalidateWorkOrders = () => {
      queryClient.invalidateQueries({ queryKey: ['work-orders'] });
      queryClient.invalidateQueries({ queryKey: ['work-orders-summary'] });
      queryClient.invalidateQueries({ queryKey: ['my-work-orders'] });
    };
    const invalidatePmTasks = () => {
      queryClient.invalidateQueries({ queryKey: ['pm-tasks'] });
    };
    const invalidatePmSchedules = () => {
      queryClient.invalidateQueries({ queryKey: ['pm-schedules'] });
      queryClient.invalidateQueries({ queryKey: ['pm-schedule'] });
      queryClient.invalidateQueries({ queryKey: ['pm-schedule-occurrences'] });
      queryClient.invalidateQueries({ queryKey: ['pm-occurrence'] });
    };

    const channelWo = subscribeWorkOrders(invalidateWorkOrders, invalidateWorkOrders, invalidateWorkOrders);
    const channelPm = subscribePMTasks(invalidatePmTasks, invalidatePmTasks);
    const channelPmOcc = subscribePmOccurrences(invalidatePmSchedules, invalidatePmSchedules);

    let channelNotif: ReturnType<typeof subscribeNotifications> | null = null;
    if (userId) {
      channelNotif = subscribeNotifications(userId, () => {
        queryClient.invalidateQueries({ queryKey: ['notifications', userId] });
      });
    }

    return () => {
      channelWo.unsubscribe();
      channelPm.unsubscribe();
      channelPmOcc.unsubscribe();
      channelNotif?.unsubscribe();
    };
  }, [user, authUser, queryClient]);
}
