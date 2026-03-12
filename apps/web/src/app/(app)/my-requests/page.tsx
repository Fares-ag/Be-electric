'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { ChevronRight } from 'lucide-react';

const statusVariants: Record<string, 'default' | 'success' | 'warning' | 'secondary'> = {
  open: 'secondary',
  assigned: 'default',
  inProgress: 'default',
  completed: 'success',
  closed: 'secondary',
};

export default function MyRequestsPage() {
  const user = useAuthStore((s) => s.user);
  const { data: workOrders, isLoading } = useQuery({
    queryKey: ['my-work-orders', user?.id],
    queryFn: async () => {
      if (!user) return [];
      const { data } = await supabase
        .from('work_orders')
        .select('id, ticketNumber, problemDescription, status, priority, createdAt')
        .eq('requestorId', user.id)
        .order('createdAt', { ascending: false });
      return data ?? [];
    },
    enabled: !!user?.id,
  });

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight text-foreground mb-6 md:mb-8">
        My Requests
      </h1>
      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : workOrders?.length === 0 ? (
            <div className="py-12 text-center px-4">
              <p className="text-muted-foreground">No requests yet.</p>
            </div>
          ) : (
            <>
              {/* Mobile: card list */}
              <div className="md:hidden divide-y divide-border">
                {workOrders?.map((wo: Record<string, unknown>) => (
                  <Link
                    key={wo.id as string}
                    href={`/work-orders/${wo.id}`}
                    className="block p-4 active:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-foreground">{wo.ticketNumber as string}</p>
                        <p className="text-sm text-muted-foreground line-clamp-2 mt-0.5">
                          {wo.problemDescription as string}
                        </p>
                        <div className="flex flex-wrap items-center gap-2 mt-2">
                          <Badge variant={statusVariants[wo.status as string] ?? 'default'}>
                            {String(wo.status).replace(/([A-Z])/g, ' $1').trim()}
                          </Badge>
                          <span className="text-xs text-muted-foreground capitalize">{wo.priority as string}</span>
                          <span className="text-xs text-muted-foreground">
                            {new Date(wo.createdAt as string).toLocaleDateString()}
                          </span>
                        </div>
                      </div>
                      <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0 mt-0.5" />
                    </div>
                  </Link>
                ))}
              </div>
              {/* Desktop: table */}
              <div className="hidden md:block overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-border">
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Ticket</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Description</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Status</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Priority</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Created</th>
                      <th className="w-12" />
                    </tr>
                  </thead>
                  <tbody>
                    {workOrders?.map((wo: Record<string, unknown>) => (
                      <tr
                        key={wo.id as string}
                        className="border-b border-border last:border-0 hover:bg-muted/50 transition-colors"
                      >
                        <td className="py-4 px-6 font-medium">{wo.ticketNumber as string}</td>
                        <td className="py-4 px-6 max-w-xs truncate text-sm text-muted-foreground">
                          {wo.problemDescription as string}
                        </td>
                        <td className="py-4 px-6">
                          <Badge variant={statusVariants[wo.status as string] ?? 'default'}>
                            {String(wo.status).replace(/([A-Z])/g, ' $1').trim()}
                          </Badge>
                        </td>
                        <td className="py-4 px-6 text-sm capitalize">{wo.priority as string}</td>
                        <td className="py-4 px-6 text-sm text-muted-foreground">
                          {new Date(wo.createdAt as string).toLocaleDateString()}
                        </td>
                        <td className="py-4 px-6">
                          <Link href={`/work-orders/${wo.id}`}>
                            <Button variant="ghost" size="sm" className="gap-1">
                              View
                              <ChevronRight className="h-4 w-4" />
                            </Button>
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
