'use client';

import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Wrench, ClipboardList, AlertTriangle, Package } from 'lucide-react';

export default function DashboardPage() {
  const { data: workOrders } = useQuery({
    queryKey: ['work-orders-summary'],
    queryFn: async () => {
      const { data } = await supabase
        .from('work_orders')
        .select('id, status')
        .in('status', ['open', 'assigned', 'inProgress']);
      return (data ?? []) as { id: string; status: string }[];
    },
  });

  const { data: pmTasks } = useQuery({
    queryKey: ['pm-tasks-overdue'],
    queryFn: async () => {
      const { data } = await supabase
        .from('pm_tasks')
        .select('id, status, nextDueDate')
        .eq('status', 'overdue');
      return (data ?? []) as { id: string }[];
    },
  });

  const { data: inventory } = useQuery({
    queryKey: ['inventory-low-stock'],
    queryFn: async () => {
      const { data } = await supabase
        .from('inventory_items')
        .select('id, name, currentStock, minStock');
      return (data ?? []) as { currentStock: number; minStock: number | null }[];
    },
  });

  const openCount = workOrders?.filter((wo) => wo.status === 'open').length ?? 0;
  const inProgressCount =
    workOrders?.filter(
      (wo) => wo.status === 'assigned' || wo.status === 'inProgress'
    ).length ?? 0;
  const overdueCount = pmTasks?.length ?? 0;
  const lowStockCount =
    inventory?.filter(
      (i) => i.minStock != null && i.currentStock <= i.minStock
    ).length ?? 0;

  const cards = [
    { label: 'Open Work Orders', value: openCount, href: '/work-orders?status=open', icon: Wrench },
    { label: 'In Progress', value: inProgressCount, href: '/work-orders?status=inProgress', icon: Wrench },
    { label: 'Overdue PM Tasks', value: overdueCount, href: '/pm-tasks?status=overdue', icon: AlertTriangle },
    { label: 'Low Stock Items', value: lowStockCount, href: '/inventory', icon: Package },
  ];

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground mb-8">
        Dashboard
      </h1>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-8">
        {cards.map(({ href, label, value, icon: Icon }) => (
          <Link key={href} href={href}>
            <Card className="cursor-pointer transition-all duration-200 hover:border-primary/30">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {label}
                </CardTitle>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground">
                  <Icon className="h-4 w-4" />
                </span>
              </CardHeader>
              <CardContent>
                <p className="font-display text-2xl font-bold text-foreground">{value}</p>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">Activity feed coming soon.</p>
        </CardContent>
      </Card>
    </div>
  );
}
