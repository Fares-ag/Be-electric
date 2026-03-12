'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

type NotificationRow = {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: string;
  isRead: boolean;
  readAt: string | null;
  relatedId: string | null;
  relatedType: string | null;
  createdAt: string;
};

function relatedHref(n: NotificationRow): string | null {
  if (!n.relatedId || !n.relatedType) return null;
  if (n.relatedType === 'work_order') return `/work-orders/${n.relatedId}`;
  if (n.relatedType === 'parts_request') return '/parts-requests';
  return null;
}

export default function NotificationsPage() {
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();

  const { data: notifications, isLoading } = useQuery({
    queryKey: ['notifications', user?.id],
    queryFn: async (): Promise<NotificationRow[]> => {
      if (!user) return [];
      const { data } = await supabase
        .from('notifications')
        .select('id, userId, title, message, type, isRead, readAt, relatedId, relatedType, createdAt')
        .eq('userId', user.id)
        .order('createdAt', { ascending: false })
        .limit(50);
      return (data ?? []) as NotificationRow[];
    },
    enabled: !!user?.id,
  });

  useEffect(() => {
    if (!user?.id) return;
    const channel = supabase
      .channel('notifications')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `userId=eq.${user.id}`,
        },
        () => {
          queryClient.invalidateQueries({ queryKey: ['notifications', user.id] });
        }
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [user?.id, queryClient]);

  const markReadMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('notifications')
        .update({ isRead: true, readAt: new Date().toISOString() })
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications', user?.id] });
    },
  });

  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">Notifications</h1>
      <Card>
        {isLoading ? (
          <p className="text-[#757575]">Loading...</p>
        ) : !notifications?.length ? (
          <p className="text-[#757575]">No notifications.</p>
        ) : (
          <ul className="divide-y divide-[#E0E0E0]">
            {notifications.map((n) => {
              const href = relatedHref(n);
              const content = (
                <>
                  <p className="text-[#000]">{n.title}</p>
                  {n.message ? (
                    <p className="text-sm text-[#757575] mt-1">{n.message}</p>
                  ) : null}
                  <p className="text-xs text-[#757575] mt-1">
                    {new Date(n.createdAt).toLocaleString()}
                  </p>
                  {href && (
                    <Link href={href} className="text-sm text-primary hover:underline mt-1 inline-block">
                      View details →
                    </Link>
                  )}
                </>
              );
              return (
                <li
                  key={n.id}
                  className={`py-3 px-4 ${n.isRead ? 'opacity-70' : 'font-medium'} flex items-start justify-between gap-2`}
                >
                  <div className="min-w-0 flex-1">
                    {href ? <Link href={href} className="block hover:opacity-90">{content}</Link> : content}
                  </div>
                  {!n.isRead && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className="shrink-0"
                      onClick={() => markReadMutation.mutate(n.id)}
                      disabled={markReadMutation.isPending}
                    >
                      Mark read
                    </Button>
                  )}
                </li>
              );
            })}
          </ul>
        )}
      </Card>
    </div>
  );
}
