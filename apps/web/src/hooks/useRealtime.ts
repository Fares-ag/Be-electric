'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '@/stores/auth-store';
import { subscribeWorkOrders, subscribeNotifications } from '@/lib/realtime';

export function useRealtimeSubscriptions() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const authUser = useAuthStore((s) => s.authUser);

  useEffect(() => {
    if (!user && !authUser) return;

    const userId = user?.id ?? authUser?.id;
    const invalidate = () => {
      queryClient.invalidateQueries({ queryKey: ['work-orders'] });
      queryClient.invalidateQueries({ queryKey: ['work-orders-summary'] });
      queryClient.invalidateQueries({ queryKey: ['my-work-orders'] });
    };

    const channelWo = subscribeWorkOrders(invalidate, invalidate, invalidate);

    let channelNotif: ReturnType<typeof subscribeNotifications> | null = null;
    if (userId) {
      channelNotif = subscribeNotifications(userId, () => {
        queryClient.invalidateQueries({ queryKey: ['notifications', userId] });
      });
    }

    return () => {
      channelWo.unsubscribe();
      channelNotif?.unsubscribe();
    };
  }, [user?.id, authUser?.id, queryClient]);
}
