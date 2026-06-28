'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { useUsersMap } from '@/hooks/useUsersMap';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner, QueryErrorState } from '@/components/ui/PageStates';
import { WorkOrderDetailHeader } from '@/components/work-orders/WorkOrderDetailHeader';
import {
  WorkOrderActivityCard,
  WorkOrderCostPartsCard,
  WorkOrderCustomerCard,
  WorkOrderNotesCard,
  WorkOrderPauseResumeCard,
  WorkOrderReopenHistoryCard,
  WorkOrderRootCauseCard,
  WorkOrderSignaturesCard,
  WorkOrderSyncOfflineCard,
  WorkOrderTextSectionCard,
} from '@/components/work-orders/WorkOrderExtendedCards';
import { WorkOrderPhotosCard } from '@/components/work-orders/WorkOrderPhotosCard';
import {
  WorkOrderAssignmentCard,
  WorkOrderIdentityCard,
  WorkOrderLocationCard,
  WorkOrderTimelineCard,
} from '@/components/work-orders/WorkOrderSummaryCards';
import { WorkOrderTechniciansPanel } from '@/components/work-orders/WorkOrderTechniciansPanel';
import {
  WorkOrderReopenModal,
  WorkOrderStatusModal,
} from '@/components/work-orders/WorkOrderStatusModals';
import {
  STATUSES_REQUIRING_REASON,
  canRequestorReopen,
  collectRequestPhotos,
  collectCompletionPhotos,
  getReopenCount,
  isAllowedAdminStatusTransition,
  metaPhotoPaths,
  parseActivityHistory,
  parsePhotoPaths,
  parseReopenHistory,
  readMetaString,
  type WorkOrderDetail,
} from '@/lib/work-order-detail';
import { WORK_ORDER_DETAIL_QUERY_KEY, fetchWorkOrderDetail } from '@/lib/queries/work-order-detail';

export default function WorkOrderDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const isRequestor = user?.role === 'requestor';
  const isAdminOrManager = user?.role === 'admin' || user?.role === 'manager';

  const { data: wo, isLoading, error: queryError, refetch } = useQuery({
    queryKey: WORK_ORDER_DETAIL_QUERY_KEY(id),
    staleTime: 60 * 1000,
    queryFn: () => fetchWorkOrderDetail(id),
  });

  // Secondary lookups: when Flutter stores string IDs in metadata instead of FK columns
  const metaAssetId = (wo?.metadata as Record<string, unknown> | undefined)
    ? String((wo?.metadata as Record<string, unknown>)?.appAssetId ?? (wo?.metadata as Record<string, unknown>)?.app_asset_id ?? '')
    : '';
  const metaCompanyId = (wo?.metadata as Record<string, unknown> | undefined)
    ? String((wo?.metadata as Record<string, unknown>)?.appCompanyId ?? (wo?.metadata as Record<string, unknown>)?.app_company_id ?? '')
    : '';

  const { data: metaAsset } = useQuery({
    queryKey: ['asset-by-meta-id', metaAssetId],
    enabled: !!metaAssetId && !wo?.assetId,
    staleTime: 5 * 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('assets')
        .select('id,name,location,manufacturer,qrCode')
        .or(`id.eq.${metaAssetId},qrCode.eq.${metaAssetId}`)
        .maybeSingle();
      return data;
    },
  });

  const { data: metaCompany } = useQuery({
    queryKey: ['company-by-meta-id', metaCompanyId],
    enabled: !!metaCompanyId && !wo?.companyId,
    staleTime: 5 * 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('companies')
        .select('id,name')
        .eq('id', metaCompanyId)
        .maybeSingle();
      return data;
    },
  });

  const [assignError, setAssignError] = useState<string | null>(null);
  const [pushWarning, setPushWarning] = useState<string | null>(null);
  const assignedIds = wo?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!wo && isAdminOrManager);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const updateAssignees = useMutation({
    mutationFn: async (technicianIds: string[]) => {
      setAssignError(null);
      setPushWarning(null);
      const { error } = await supabase
        .from('work_orders')
        .update({
          assignedTechnicianIds: technicianIds,
          assignedAt: technicianIds.length > 0 ? new Date().toISOString() : null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (error) throw error;
      if (technicianIds.length > 0) {
        const ticketNumber = wo?.ticketNumber ?? id;
        const { data: { session } } = await supabase.auth.getSession();
        const token = session?.access_token;
        if (!token) {
          setPushWarning(
            'Assignment saved. Push notification was not sent (session unavailable). Sign in again and retry if needed.'
          );
          return;
        }
        try {
          const pushRes = await fetch('/api/notifications/push', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
              type: 'work_order_assigned',
              external_user_ids: technicianIds,
              title: 'New Work Order Assigned',
              message: `Work order #${ticketNumber} has been assigned to you.`,
              data: { work_order_id: id, ticket_number: String(ticketNumber) },
            }),
          });
          if (!pushRes.ok) {
            const data = await pushRes.json().catch(() => ({})) as { error?: string; code?: string; hint?: string };
            const msg = data.code === 'MISSING_SERVICE_ROLE_KEY'
              ? 'Assignment saved. Push not sent: add SUPABASE_SERVICE_ROLE_KEY in Vercel → Project → Settings → Environment Variables, then redeploy.'
              : data.hint
                ? `Assignment saved. Push failed: ${data.hint}`
                : data.error ?? `Push failed (${pushRes.status}).`;
            setPushWarning(msg);
          }
        } catch (e) {
          setPushWarning('Assignment saved. Push notification request failed. Check network and try again.');
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      setAssignError(null);
    },
    onError: (err: Error) => {
      setAssignError(err.message);
    },
  });

  const addTechnician = (userId: string) => {
    const current = wo?.assignedTechnicianIds ?? [];
    if (current.includes(userId)) return;
    updateAssignees.mutate([...current, userId]);
  };

  const removeTechnician = (userId: string) => {
    const current = wo?.assignedTechnicianIds ?? [];
    updateAssignees.mutate(current.filter((id) => id !== userId));
  };

  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [statusModalTarget, setStatusModalTarget] = useState<string | null>(null);
  const [statusReason, setStatusReason] = useState('');
  const [statusReasonError, setStatusReasonError] = useState<string | null>(null);
  const [statusTransitionError, setStatusTransitionError] = useState<string | null>(null);

  const updateStatusMutation = useMutation({
    mutationFn: async ({
      newStatus,
      reason,
    }: {
      newStatus: string;
      reason?: string;
    }) => {
      const now = new Date().toISOString();
      const updates: Record<string, unknown> = {
        status: newStatus,
        updatedAt: now,
      };
      if (['completed', 'closed'].includes(newStatus)) {
        updates.completedAt = now;
        if (newStatus === 'closed') updates.closedAt = now;
      }
      if (newStatus === 'reopened') {
        updates.assignedTechnicianIds = [];
        updates.primaryTechnicianId = null;
        updates.assignedAt = null;
        updates.startedAt = null;
        updates.completedAt = null;
        updates.closedAt = null;
        if (reason) {
          const raw = wo?.metadata as Record<string, unknown> | undefined;
          const prevMeta = typeof raw === 'object' && raw !== null ? raw : {};
          const count = Number(prevMeta.reopenCount ?? prevMeta.reopen_count ?? 0);
          updates.metadata = {
            ...prevMeta,
            reopenedAt: now,
            reopenedBy: user?.id ?? null,
            reopenReason: reason,
            reopenCount: count + 1,
            previousCompletionDate: wo?.completedAt ?? wo?.closedAt ?? null,
            previousStatus: wo?.status,
          };
        }
      }
      if (reason) {
        const existing = parseActivityHistory(wo?.activityHistory);
        updates.activityHistory = [
          ...existing,
          { at: now, type: newStatus, note: reason },
        ];
      }
      const { error } = await supabase.from('work_orders').update(updates).eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      setStatusModalOpen(false);
      setStatusModalTarget(null);
      setStatusReason('');
      setStatusReasonError(null);
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      queryClient.invalidateQueries({ queryKey: ['work-orders'] });
      queryClient.invalidateQueries({ queryKey: ['my-work-orders'] });
    },
    onError: (err: Error) => {
      setStatusReasonError(err.message);
    },
  });

  const isCompletionLocked = ['completed', 'closed', 'cancelled'].includes(wo?.status ?? '');
  const rawMeta = wo?.metadata as Record<string, unknown> | undefined;
  const reopenCount = getReopenCount(rawMeta);
  const reopenHistoryMeta = parseReopenHistory(rawMeta);
  const reopenedByName = reopenHistoryMeta?.reopenedBy
    ? allUsers.find((u) => u.id === reopenHistoryMeta.reopenedBy)?.name
    : null;
  const canReopen = canRequestorReopen(wo, user?.id, isRequestor);

  const [reopenOpen, setReopenOpen] = useState(false);
  const [reopenReason, setReopenReason] = useState('');
  const [reopenDescription, setReopenDescription] = useState('');
  const [reopenError, setReopenError] = useState<string | null>(null);

  const reopenMutation = useMutation({
    mutationFn: async () => {
      if (!user?.id || !wo) throw new Error('Not allowed');
      if (reopenReason.trim().length < 10) throw new Error('Reason must be at least 10 characters');
      const now = new Date().toISOString();
      const previousCompletion = wo.completedAt ?? wo.closedAt ?? null;
      const newMeta = {
        ...(typeof wo.metadata === 'object' && wo.metadata !== null ? (wo.metadata as Record<string, unknown>) : {}),
        reopenedAt: now,
        reopenedBy: user.id,
        reopenReason: reopenReason.trim(),
        reopenCount: reopenCount + 1,
        previousCompletionDate: previousCompletion,
        previousStatus: wo.status,
      };
      const { error } = await supabase
        .from('work_orders')
        .update({
          status: 'reopened',
          problemDescription: reopenDescription.trim().length >= 10 ? reopenDescription.trim() : wo.problemDescription,
          assignedTechnicianIds: [],
          primaryTechnicianId: null,
          assignedAt: null,
          startedAt: null,
          completedAt: null,
          closedAt: null,
          metadata: newMeta,
          updatedAt: now,
        })
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      setReopenOpen(false);
      setReopenReason('');
      setReopenDescription('');
      setReopenError(null);
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      router.refresh();
    },
    onError: (err: Error) => {
      setReopenError(err.message);
    },
  });

  const handleReopenSubmit = () => {
    setReopenError(null);
    reopenMutation.mutate();
  };
  const requestPhotos = collectRequestPhotos(wo?.photoPath, rawMeta);
  const completionPhotos = collectCompletionPhotos(wo?.completionPhotoPath, rawMeta);
  const beforePhotos = [
    ...new Set([
      ...parsePhotoPaths(wo?.beforePhotoPath),
      ...metaPhotoPaths(rawMeta, ['beforePhotoPaths', 'before_photo_paths']),
    ]),
  ];
  const afterPhotos = [
    ...new Set([
      ...parsePhotoPaths(wo?.afterPhotoPath),
      ...metaPhotoPaths(rawMeta, ['afterPhotoPaths', 'after_photo_paths']),
    ]),
  ];
  const isCompleted = ['completed', 'closed'].includes(wo?.status ?? '');

  const primaryUser = wo?.primaryTechnicianId
    ? (allUsers.find((u) => u.id === wo.primaryTechnicianId) as { name?: string } | undefined)
    : null;
  const appCompanyIdFromMeta = readMetaString(rawMeta, 'appCompanyId', 'app_company_id');

  if (isLoading) return <LoadingSpinner label="Loading work order" />;

  if (queryError) {
    return (
      <QueryErrorState
        title="Failed to load work order"
        message={queryError instanceof Error ? queryError.message : String(queryError)}
        onRetry={() => refetch()}
      />
    );
  }

  if (!wo) {
    return (
      <QueryErrorState
        title="Work order not found"
        message="This work order may have been removed or you may not have permission to view it."
      />
    );
  }

  return (
    <div>
      <WorkOrderDetailHeader
        wo={wo}
        isAdminOrManager={isAdminOrManager}
        canReopen={canReopen}
        statusPending={updateStatusMutation.isPending}
        onStatusChange={(val) => {
          setStatusTransitionError(null);
          if (!isAllowedAdminStatusTransition(wo.status, val)) {
            setStatusTransitionError(`Cannot change status from ${wo.status} to ${val}.`);
            return;
          }
          if (STATUSES_REQUIRING_REASON.includes(val as typeof STATUSES_REQUIRING_REASON[number])) {
            setStatusModalTarget(val);
            setStatusReason('');
            setStatusReasonError(null);
            setStatusModalOpen(true);
          } else {
            updateStatusMutation.mutate({ newStatus: val });
          }
        }}
        onReopenClick={() => setReopenOpen(true)}
      />
      {statusTransitionError && (
        <p className="mb-4 text-sm text-destructive" role="alert">
          {statusTransitionError}
        </p>
      )}

      <WorkOrderStatusModal
        open={statusModalOpen}
        target={statusModalTarget}
        reason={statusReason}
        reasonError={statusReasonError}
        pending={updateStatusMutation.isPending}
        onReasonChange={setStatusReason}
        onClose={() => {
          setStatusModalOpen(false);
          setStatusModalTarget(null);
          setStatusReason('');
          setStatusReasonError(null);
        }}
        onConfirm={() => {
          setStatusReasonError(null);
          if (statusReason.trim().length < 10) {
            setStatusReasonError('Reason must be at least 10 characters');
            return;
          }
          if (!statusModalTarget) return;
          updateStatusMutation.mutate({
            newStatus: statusModalTarget,
            reason: statusReason.trim(),
          });
        }}
      />

      <WorkOrderReopenModal
        open={reopenOpen}
        reopenCount={reopenCount}
        reason={reopenReason}
        description={reopenDescription}
        error={reopenError}
        pending={reopenMutation.isPending}
        onReasonChange={setReopenReason}
        onDescriptionChange={setReopenDescription}
        onClose={() => {
          setReopenOpen(false);
          setReopenError(null);
        }}
        onConfirm={handleReopenSubmit}
      />

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="min-w-0 space-y-4">
          <WorkOrderIdentityCard wo={wo} />
          <WorkOrderLocationCard wo={wo} metaAsset={metaAsset} metaCompany={metaCompany} />
          <WorkOrderAssignmentCard
            wo={wo}
            primaryTechnicianName={primaryUser?.name}
            visible={Boolean(
              isAdminOrManager ||
                wo.assignedAt ||
                (wo.assignedTechnicianIds && wo.assignedTechnicianIds.length > 0) ||
                wo.primaryTechnicianId ||
                wo.technicianEffortMinutes
            )}
          />
          <WorkOrderTimelineCard wo={wo} rawMeta={rawMeta} />

          <WorkOrderNotesCard wo={wo} />
          <WorkOrderRootCauseCard rawMeta={rawMeta} />
          <WorkOrderCostPartsCard wo={wo} visible={!isRequestor} />
          <WorkOrderCustomerCard wo={wo} />
          <WorkOrderPauseResumeCard wo={wo} />
          <WorkOrderSyncOfflineCard wo={wo} />
        </div>
        {isAdminOrManager && (
          <WorkOrderTechniciansPanel
            assignedUsers={assignedUsers}
            assignableUsers={allUsers.filter(
              (u) => u.role === 'technician' || u.role === 'manager' || u.role === 'admin'
            )}
            assignedIds={assignedIds}
            assignError={assignError}
            pushWarning={pushWarning}
            isCompletionLocked={isCompletionLocked}
            pending={updateAssignees.isPending}
            onAdd={addTechnician}
            onRemove={removeTechnician}
          />
        )}
      </div>

      <WorkOrderReopenHistoryCard rawMeta={rawMeta} reopenedByName={reopenedByName} />

      <WorkOrderPhotosCard
        requestPhotos={requestPhotos}
        beforePhotos={beforePhotos}
        afterPhotos={afterPhotos}
        completionPhotos={completionPhotos}
        isCompleted={isCompleted}
      />

      <WorkOrderActivityCard activityHistory={wo.activityHistory} />

      {wo.correctiveActions && (
        <WorkOrderTextSectionCard
          title="Corrective actions"
          content={wo.correctiveActions}
          className="mt-4"
        />
      )}

      {wo.recommendations && (
        <WorkOrderTextSectionCard
          title="Recommendations"
          content={wo.recommendations}
          className="mt-4"
        />
      )}

      <WorkOrderSignaturesCard wo={wo} />
    </div>
  );
}
