import type { QueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

/**
 * Prefetch React Query data for a route when the user hovers a nav link.
 * Makes the page feel instant when they click because data is already loading or cached.
 */
export async function prefetchRoute(
  queryClient: QueryClient,
  href: string
): Promise<void> {
  const path = href.split('?')[0];
  try {
    switch (path) {
      case '/work-orders': {
        await Promise.all([
          queryClient.prefetchQuery({
            queryKey: ['work-orders', undefined],
            queryFn: async () => {
              const { data, error } = await supabase
                .from('work_orders')
                .select('id, ticketNumber, problemDescription, status, priority, createdAt, requestorName, requestorId, assignedTechnicianIds')
                .order('createdAt', { ascending: false });
              if (error) throw error;
              return data ?? [];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['users-list'],
            queryFn: async () => {
              const { data, error } = await (supabase as any).rpc('get_users_list');
              if (error) throw error;
              return ((data ?? []) as Record<string, unknown>[]).map((u) => ({
                id: String(u.id),
                name: String(u.name ?? ''),
                role: u.role ? String(u.role) : undefined,
                email: u.email ? String(u.email) : undefined,
              }));
            },
            staleTime: 60 * 1000,
          }),
        ]);
        break;
      }
      case '/assets': {
        await queryClient.prefetchQuery({
          queryKey: ['assets'],
          queryFn: async () => {
            const { data } = await supabase
              .from('assets')
              .select('*, company:companies(name)')
              .order('name');
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/pm-tasks': {
        await queryClient.prefetchQuery({
          queryKey: ['pm-tasks'],
          queryFn: async () => {
            const { data } = await supabase
              .from('pm_tasks')
              .select('id, taskName, status, frequency, nextDueDate, assignedTechnicianIds, asset:assets(name)')
              .order('nextDueDate', { ascending: true });
            return data ?? [];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/companies': {
        await queryClient.prefetchQuery({
          queryKey: ['companies'],
          queryFn: async () => {
            const { data } = await supabase.from('companies').select('*').order('name');
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/users': {
        await queryClient.prefetchQuery({
          queryKey: ['users'],
          queryFn: async () => {
            const { data, error } = await (supabase as any).rpc('get_users_list');
            if (error) throw error;
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/dashboard': {
        await Promise.all([
          queryClient.prefetchQuery({
            queryKey: ['work-orders-summary'],
            queryFn: async () => {
              const { data } = await supabase
                .from('work_orders')
                .select('id, status')
                .in('status', ['open', 'assigned', 'inProgress']);
              return (data ?? []) as unknown[];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['pm-tasks-overdue'],
            queryFn: async () => {
              const { data } = await supabase
                .from('pm_tasks')
                .select('id, status, nextDueDate')
                .eq('status', 'overdue');
              return (data ?? []) as unknown[];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['inventory-low-stock'],
            queryFn: async () => {
              const { data } = await supabase
                .from('inventory_items')
                .select('id, name, currentStock, minStock');
              return (data ?? []) as unknown[];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['dashboard-recent-activity'],
            queryFn: async () => {
              const [woRes, pmRes] = await Promise.all([
                supabase
                  .from('work_orders')
                  .select('id, ticketNumber, status, createdAt, updatedAt, activityHistory')
                  .order('updatedAt', { ascending: false })
                  .limit(25),
                supabase
                  .from('pm_tasks')
                  .select('id, taskName, status, lastCompletedDate')
                  .eq('status', 'completed')
                  .not('lastCompletedDate', 'is', null)
                  .order('lastCompletedDate', { ascending: false })
                  .limit(15),
              ]);
              return {
                workOrders: (woRes.data ?? []) as unknown[],
                pmTasks: (pmRes.data ?? []) as unknown[],
              };
            },
            staleTime: 60 * 1000,
          }),
        ]);
        break;
      }
      case '/inventory': {
        await queryClient.prefetchQuery({
          queryKey: ['inventory'],
          queryFn: async () => {
            const { data } = await supabase.from('inventory_items').select('*').order('name');
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/parts-requests': {
        await queryClient.prefetchQuery({
          queryKey: ['parts-requests'],
          queryFn: async () => {
            const { data } = await supabase.from('parts_requests').select('*');
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/purchase-orders': {
        await queryClient.prefetchQuery({
          queryKey: ['purchase-orders'],
          queryFn: async () => {
            const { data } = await supabase.from('purchase_orders').select('*');
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/analytics': {
        await Promise.all([
          queryClient.prefetchQuery({
            queryKey: ['analytics-work-orders'],
            queryFn: async () => {
              const { data } = await supabase
                .from('work_orders')
                .select('id, status, priority, createdAt, completedAt, closedAt');
              return data ?? [];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['analytics-pm-tasks'],
            queryFn: async () => {
              const { data } = await supabase
                .from('pm_tasks')
                .select('id, status, nextDueDate');
              return data ?? [];
            },
            staleTime: 60 * 1000,
          }),
        ]);
        break;
      }
      default:
        break;
    }
  } catch {
    // Prefetch is best-effort; don't break nav on failure
  }
}
