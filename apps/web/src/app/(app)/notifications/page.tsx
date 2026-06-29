'use client';

import { useEffect, useState, useMemo } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { notificationRelatedHref } from '@/lib/notifications';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

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

export default function NotificationsPage() {
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();

  const { data: notifications, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['notifications', user?.id],
    staleTime: 60 * 1000,
    queryFn: async (): Promise<NotificationRow[]> => {
      if (!user) return [];
      const { data, error: err } = await supabase
        .from('notifications')
        .select('id, userId, title, message, type, isRead, readAt, relatedId, relatedType, createdAt')
        .eq('userId', user.id)
        .order('createdAt', { ascending: false })
        .limit(50);
      if (err) throw err;
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

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = notifications ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (n) =>
        n.title.toLowerCase().includes(q) ||
        (n.message ?? '').toLowerCase().includes(q)
    );
  }, [notifications, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const unreadCount = (notifications ?? []).filter((n) => !n.isRead).length;

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

  const markAllReadMutation = useMutation({
    mutationFn: async () => {
      if (!user?.id) return;
      const { error } = await supabase
        .from('notifications')
        .update({ isRead: true, readAt: new Date().toISOString() })
        .eq('userId', user.id)
        .eq('isRead', false);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications', user?.id] });
    },
  });

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Notifications"
        description={unreadCount > 0 ? `${unreadCount} unread` : undefined}
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search title, message..."
              className="max-w-md"
            />
            {unreadCount > 0 && (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => markAllReadMutation.mutate()}
                disabled={markAllReadMutation.isPending}
              >
                {markAllReadMutation.isPending ? 'Marking…' : 'Mark all read'}
              </Button>
            )}
          </>
        }
      />

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (notifications?.length ?? 0) === 0}
            emptyTitle="No notifications"
            emptyDescription="Updates about your requests and assignments will appear here."
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (notifications?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching notifications</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <>
                <ul className="divide-y divide-border">
                  {paginatedItems.map((n) => {
                    const href = notificationRelatedHref(n, user?.role);
                    const content = (
                      <>
                        <p className={n.isRead ? 'text-foreground' : 'font-medium text-foreground'}>
                          {n.title}
                        </p>
                        {n.message ? (
                          <p className="mt-1 text-sm text-muted-foreground">{n.message}</p>
                        ) : null}
                        <p className="mt-1 text-xs text-muted-foreground">
                          {new Date(n.createdAt).toLocaleString()}
                        </p>
                        {href && (
                          <span className="mt-1 inline-block text-sm text-primary">View details →</span>
                        )}
                      </>
                    );
                    return (
                      <li
                        key={n.id}
                        className={`flex items-start justify-between gap-2 px-4 py-3 ${n.isRead ? 'opacity-80' : 'bg-accent/30'}`}
                      >
                        <div className="min-w-0 flex-1">
                          {href ? (
                            <Link
                              href={href}
                              className="block hover:opacity-90"
                              onClick={() => {
                                if (!n.isRead) markReadMutation.mutate(n.id);
                              }}
                            >
                              {content}
                            </Link>
                          ) : (
                            content
                          )}
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
                {totalItems > 0 && (
                  <Pagination
                    page={page}
                    pageSize={pageSize}
                    totalItems={totalItems}
                    onPageChange={setPage}
                    onPageSizeChange={setPageSize}
                  />
                )}
              </>
            )}
          </DataTableShell>
        </CardContent>
      </Card>
    </div>
  );
}
