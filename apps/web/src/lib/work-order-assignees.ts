import { supabase } from '@/lib/supabase';

export type UpdateWorkOrderAssigneesOptions = {
  /** When set, updates primaryTechnicianId after RPC (e.g. orphan scrub). */
  primaryTechnicianId?: string | null;
};

/**
 * Handbook-aligned assignee update via update_work_order_assignees RPC.
 * Admin/manager JWT required (enforced in RPC).
 */
export async function updateWorkOrderAssignees(
  workOrderId: string,
  technicianIds: string[],
  options?: UpdateWorkOrderAssigneesOptions
): Promise<void> {
  const { error } = await supabase.rpc('update_work_order_assignees', {
    p_work_order_id: workOrderId,
    p_technician_ids: technicianIds,
  });
  if (error) throw error;

  if (options?.primaryTechnicianId !== undefined) {
    const { error: primaryError } = await supabase
      .from('work_orders')
      .update({
        primaryTechnicianId: options.primaryTechnicianId,
        updatedAt: new Date().toISOString(),
      })
      .eq('id', workOrderId);
    if (primaryError) throw primaryError;
  }
}
