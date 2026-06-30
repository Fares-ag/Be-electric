import type { QueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { USERS_LIST_QUERY_KEY, fetchUsersList, fetchUsersMapEntries } from '@/lib/queries/users';
import {
  fetchWorkOrdersForAnalytics,
  fetchWorkOrdersList,
  workOrdersListQueryKey,
} from '@/lib/queries/work-orders';
import {
  countOverduePmOccurrences,
  countUpcomingPmOccurrences,
  fetchPmOccurrencesForAnalytics,
  fetchRecentCompletedPmOccurrences,
} from '@/lib/queries/pm-schedules';
import { ACTIVE_WORK_ORDER_STATUSES } from '@/lib/work-order-detail';

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
            queryKey: workOrdersListQueryKey(undefined),
            queryFn: () => fetchWorkOrdersList(),
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: USERS_LIST_QUERY_KEY,
            queryFn: fetchUsersMapEntries,
            staleTime: 60 * 1000,
          }),
        ]);
        break;
      }
      case '/assets': {
        await queryClient.prefetchQuery({
          queryKey: ['assets'],
          queryFn: async () => {
            const { data, error } = await supabase
              .from('assets')
              .select('*, company:companies(name)')
              .order('name');
            if (error) throw error;
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/pm-schedules': {
        const { fetchPmSchedulesList, PM_SCHEDULES_LIST_QUERY_KEY } = await import(
          '@/lib/queries/pm-schedules'
        );
        await queryClient.prefetchQuery({
          queryKey: PM_SCHEDULES_LIST_QUERY_KEY,
          queryFn: fetchPmSchedulesList,
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/pm-tasks': {
        await queryClient.prefetchQuery({
          queryKey: ['pm-tasks'],
          queryFn: async () => {
            const { data, error } = await supabase
              .from('pm_tasks')
              .select('id, taskName, status, frequency, nextDueDate, assignedTechnicianIds, asset:assets(name)')
              .order('nextDueDate', { ascending: true });
            if (error) throw error;
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
            const { data, error } = await supabase.from('companies').select('*').order('name');
            if (error) throw error;
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/users': {
        await queryClient.prefetchQuery({
          queryKey: USERS_LIST_QUERY_KEY,
          queryFn: fetchUsersList,
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/dashboard': {
        await Promise.all([
          queryClient.prefetchQuery({
            queryKey: ['work-orders-summary'],
            queryFn: async () => {
              const { data, error } = await supabase
                .from('work_orders')
                .select('id, status')
                .in('status', ['open', ...ACTIVE_WORK_ORDER_STATUSES]);
              if (error) throw error;
              return (data ?? []) as unknown[];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['pm-occurrences-overdue'],
            queryFn: () => countOverduePmOccurrences(),
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['pm-occurrences-upcoming-count'],
            queryFn: () => countUpcomingPmOccurrences(),
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['inventory-low-stock'],
            queryFn: async () => {
              const { data, error } = await supabase
                .from('inventory_items')
                .select('id, name, currentStock, minStock');
              if (error) throw error;
              return (data ?? []) as unknown[];
            },
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['dashboard-recent-activity'],
            queryFn: async () => {
              const [woRes, pmOccurrences] = await Promise.all([
                supabase
                  .from('work_orders')
                  .select('id, ticketNumber, status, createdAt, updatedAt, activityHistory')
                  .order('updatedAt', { ascending: false })
                  .limit(25),
                fetchRecentCompletedPmOccurrences(15),
              ]);
              if (woRes.error) throw woRes.error;
              return {
                workOrders: (woRes.data ?? []) as unknown[],
                pmOccurrences,
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
            const { data, error } = await supabase.from('inventory_items').select('*').order('name');
            if (error) throw error;
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
            const { data, error } = await supabase.from('parts_requests').select('*');
            if (error) throw error;
            return (data ?? []) as unknown[];
          },
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/support-requests': {
        const { fetchSupportRequestsList, SUPPORT_REQUESTS_LIST_QUERY_KEY } = await import(
          '@/lib/queries/support-requests'
        );
        await queryClient.prefetchQuery({
          queryKey: SUPPORT_REQUESTS_LIST_QUERY_KEY,
          queryFn: fetchSupportRequestsList,
          staleTime: 60 * 1000,
        });
        break;
      }
      case '/purchase-orders': {
        await queryClient.prefetchQuery({
          queryKey: ['purchase-orders'],
          queryFn: async () => {
            const { data, error } = await supabase.from('purchase_orders').select('*');
            if (error) throw error;
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
            queryFn: fetchWorkOrdersForAnalytics,
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['analytics-pm-occurrences'],
            queryFn: fetchPmOccurrencesForAnalytics,
            staleTime: 60 * 1000,
          }),
          queryClient.prefetchQuery({
            queryKey: ['pm-occurrences-overdue'],
            queryFn: () => countOverduePmOccurrences(),
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
