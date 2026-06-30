import { supabase } from '@/lib/supabase';
import { deriveOccurrenceStatus } from '@/lib/pm-schedule';

export type AttentionItem =
  | {
      kind: 'pm_overdue';
      id: string;
      href: string;
      label: string;
      meta: string;
      sortAt: string;
    }
  | {
      kind: 'work_order_open';
      id: string;
      href: string;
      label: string;
      meta: string;
      sortAt: string;
    }
  | {
      kind: 'support_submitted';
      id: string;
      href: string;
      label: string;
      meta: string;
      sortAt: string;
    };

export async function fetchDashboardAttentionItems(limit = 8): Promise<AttentionItem[]> {
  const todayIso = new Date().toISOString().slice(0, 10);
  const perSource = Math.max(3, Math.ceil(limit / 2));

  const [pmRes, woRes, supportRes] = await Promise.all([
    supabase
      .from('pm_task_occurrences')
      .select('id, scheduleId, dueDate, status, asset:assets(name), schedule:pm_schedules(taskName)')
      .neq('status', 'completed')
      .neq('status', 'cancelled')
      .lt('dueDate', todayIso)
      .order('dueDate', { ascending: true })
      .limit(perSource),
    supabase
      .from('work_orders')
      .select('id, ticketNumber, problemDescription, status, createdAt')
      .eq('status', 'open')
      .order('createdAt', { ascending: false })
      .limit(perSource),
    supabase
      .from('support_requests')
      .select('id, summary, type, createdAt')
      .eq('status', 'submitted')
      .order('createdAt', { ascending: false })
      .limit(perSource),
  ]);

  if (pmRes.error) throw pmRes.error;
  if (woRes.error) throw woRes.error;
  if (supportRes.error) throw supportRes.error;

  const items: AttentionItem[] = [];

  for (const row of pmRes.data ?? []) {
    const status = String(row.status);
    const dueDate = String(row.dueDate);
    if (deriveOccurrenceStatus(status, dueDate, todayIso) !== 'overdue') continue;
    const schedule = row.schedule as { taskName?: string } | null;
    const asset = row.asset as { name?: string | null } | null;
    const taskName = schedule?.taskName ?? 'PM task';
    const chargerName = asset?.name ?? 'Charger';
    items.push({
      kind: 'pm_overdue',
      id: String(row.id),
      href: `/pm-schedules/${row.scheduleId}/occurrences/${row.id}`,
      label: `${taskName} — ${chargerName}`,
      meta: `Due ${new Date(dueDate).toLocaleDateString()} · overdue`,
      sortAt: dueDate,
    });
  }

  for (const row of woRes.data ?? []) {
    const desc = String(row.problemDescription ?? '').trim();
    items.push({
      kind: 'work_order_open',
      id: String(row.id),
      href: `/work-orders/${row.id}`,
      label: `Work order #${row.ticketNumber}`,
      meta: desc ? desc.slice(0, 80) : 'Open — needs assignment or action',
      sortAt: String(row.createdAt),
    });
  }

  for (const row of supportRes.data ?? []) {
    const summary = String(row.summary ?? '').trim() || 'Support request';
    items.push({
      kind: 'support_submitted',
      id: String(row.id),
      href: `/support-requests/${row.id}`,
      label: summary.slice(0, 80),
      meta: `${String(row.type ?? 'request')} · awaiting review`,
      sortAt: String(row.createdAt),
    });
  }

  items.sort((a, b) => {
    if (a.kind === 'pm_overdue' && b.kind !== 'pm_overdue') return -1;
    if (b.kind === 'pm_overdue' && a.kind !== 'pm_overdue') return 1;
    return new Date(a.sortAt).getTime() - new Date(b.sortAt).getTime();
  });

  return items.slice(0, limit);
}
