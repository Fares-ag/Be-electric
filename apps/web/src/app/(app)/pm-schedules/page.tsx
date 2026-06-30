'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ChevronRight } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { usePagination } from '@/hooks/usePagination';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { useUsersMap } from '@/hooks/useUsersMap';
import { useAuthStore } from '@/stores/auth-store';
import { supabase } from '@/lib/supabase';
import {
  PM_FREQUENCIES,
  formatPmFrequency,
  matchesOccurrenceStatusFilter,
  previewOccurrences,
  scheduleEndDateFromDurationYears,
  type PmFrequency,
} from '@/lib/pm-schedule';
import { PmOccurrenceStatusLegend } from '@/components/pm/PmOccurrenceStatusLegend';
import { PmScheduleCallouts } from '@/components/pm/PmScheduleCallouts';
import { DismissibleHint } from '@/components/ui/DismissibleHint';
import {
  PM_SCHEDULES_LIST_QUERY_KEY,
  UPCOMING_PM_OCCURRENCES_QUERY_KEY,
  createScheduleWithOccurrences,
  fetchPmSchedulesList,
  fetchUpcomingPmOccurrences,
} from '@/lib/queries/pm-schedules';

const WIZARD_STEPS = [
  'Task details',
  'Schedule window',
  'Chargers',
  'Technicians',
  'Preview',
] as const;

type WindowMode = 'endDate' | 'duration';

const emptyWizard = {
  taskName: '',
  description: '',
  frequency: 'quarterly' as PmFrequency,
  scheduleStartDate: new Date().toISOString().slice(0, 10),
  windowMode: 'duration' as WindowMode,
  scheduleEndDate: '',
  durationYears: 2,
  companyId: '',
  selectedAssetIds: [] as string[],
  assignedTechnicianIds: [] as string[],
};

export default function PmSchedulesPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const statusFilter = searchParams.get('status') ?? undefined;
  const viewFilter = searchParams.get('view') ?? undefined;
  const showUpcomingTasks = viewFilter === 'upcoming';
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const [search, setSearch] = useState('');
  const [wizardOpen, setWizardOpen] = useState(false);
  const [wizardStep, setWizardStep] = useState(0);
  const [form, setForm] = useState(emptyWizard);
  const [formError, setFormError] = useState<string | null>(null);
  const { submitting: wizardSubmitting, runSubmit: runWizardSubmit } = useFormSubmitLock();

  const { data: schedules, isLoading, error, refetch } = useQuery({
    queryKey: PM_SCHEDULES_LIST_QUERY_KEY,
    staleTime: 60 * 1000,
    queryFn: fetchPmSchedulesList,
    enabled: !showUpcomingTasks,
  });

  const {
    data: upcomingOccurrences,
    isLoading: upcomingLoading,
    error: upcomingError,
    refetch: refetchUpcoming,
  } = useQuery({
    queryKey: UPCOMING_PM_OCCURRENCES_QUERY_KEY,
    staleTime: 60 * 1000,
    queryFn: () => fetchUpcomingPmOccurrences(),
    enabled: showUpcomingTasks,
  });

  const { users: allUsers } = useUsersMap(showUpcomingTasks || wizardOpen);
  const userNameById = useMemo(() => {
    const map = new Map<string, string>();
    for (const user of allUsers) map.set(user.id, user.name);
    return map;
  }, [allUsers]);

  const { data: companies } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase.from('companies').select('id, name').order('name');
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const { data: companyAssets } = useQuery({
    queryKey: ['assets', form.companyId],
    enabled: !!form.companyId,
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('assets')
        .select('id, name')
        .eq('companyId', form.companyId)
        .order('name');
      if (err) throw err;
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const technicians = allUsers.filter(
    (u) => u.role === 'technician' || u.role === 'manager' || u.role === 'admin'
  );

  const effectiveEndDate = useMemo(() => {
    if (form.windowMode === 'endDate') return form.scheduleEndDate;
    if (!form.scheduleStartDate || form.durationYears < 1) return '';
    return scheduleEndDateFromDurationYears(form.scheduleStartDate, form.durationYears);
  }, [form.windowMode, form.scheduleEndDate, form.scheduleStartDate, form.durationYears]);

  const previewRows = useMemo(() => {
    if (!effectiveEndDate || form.selectedAssetIds.length === 0) return [];
    return previewOccurrences(form.selectedAssetIds, {
      frequency: form.frequency,
      startDate: form.scheduleStartDate,
      endDate: effectiveEndDate,
    });
  }, [form.selectedAssetIds, form.frequency, form.scheduleStartDate, effectiveEndDate]);

  const assetNameById = useMemo(() => {
    const map = new Map<string, string>();
    for (const asset of companyAssets ?? []) map.set(asset.id, asset.name);
    return map;
  }, [companyAssets]);

  const createMutation = useMutation({
    mutationFn: async () => {
      if (!effectiveEndDate) throw new Error('Schedule end date is required');
      if (form.selectedAssetIds.length === 0) throw new Error('Select at least one charger');
      if (previewRows.length === 0) throw new Error('No occurrences to create');
      return createScheduleWithOccurrences({
        taskName: form.taskName,
        description: form.description,
        frequency: form.frequency,
        scheduleStartDate: form.scheduleStartDate,
        scheduleEndDate: effectiveEndDate,
        companyId: form.companyId || null,
        assignedTechnicianIds: form.assignedTechnicianIds,
        createdById: user?.id ?? null,
        occurrences: previewRows.map((r) => ({ assetId: r.assetId, dueDate: r.dueDate })),
      });
    },
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: PM_SCHEDULES_LIST_QUERY_KEY });
      setWizardOpen(false);
      setWizardStep(0);
      setForm(emptyWizard);
      setFormError(null);
      router.push(`/pm-schedules/${result.scheduleId}`);
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const filtered = useMemo(() => {
    let list = schedules ?? [];
    if (statusFilter === 'overdue') {
      list = list.filter((s) => (s.overdueCount ?? 0) > 0);
    }
    if (statusFilter === 'upcoming') {
      list = list.filter((s) => (s.upcomingCount ?? 0) > 0);
    }
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (s) =>
        s.taskName.toLowerCase().includes(q) ||
        (s.company?.name ?? '').toLowerCase().includes(q) ||
        s.frequency.toLowerCase().includes(q)
    );
  }, [schedules, search, statusFilter]);

  const filteredUpcoming = useMemo(() => {
    let list = upcomingOccurrences ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter((row) => {
      const taskName = row.schedule?.taskName ?? '';
      const company = row.schedule?.company?.name ?? row.asset?.company?.name ?? '';
      const charger = row.asset?.name ?? '';
      return (
        taskName.toLowerCase().includes(q) ||
        company.toLowerCase().includes(q) ||
        charger.toLowerCase().includes(q)
      );
    });
  }, [upcomingOccurrences, search]);

  const pmListTotals = useMemo(() => {
    const list = schedules ?? [];
    return {
      overdue: list.reduce((sum, s) => sum + (s.overdueCount ?? 0), 0),
      upcoming: list.reduce((sum, s) => sum + (s.upcomingCount ?? 0), 0),
    };
  }, [schedules]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  const {
    page: upcomingPage,
    setPage: setUpcomingPage,
    pageSize: upcomingPageSize,
    setPageSize: setUpcomingPageSize,
    paginatedItems: paginatedUpcoming,
    totalItems: totalUpcomingItems,
  } = usePagination(filteredUpcoming);

  useEffect(() => setPage(1), [search, statusFilter, setPage]);
  useEffect(() => setUpcomingPage(1), [search, setUpcomingPage]);

  const toggleAsset = (assetId: string) => {
    setForm((f) => ({
      ...f,
      selectedAssetIds: f.selectedAssetIds.includes(assetId)
        ? f.selectedAssetIds.filter((id) => id !== assetId)
        : [...f.selectedAssetIds, assetId],
    }));
  };

  const selectAllAssets = () => {
    setForm((f) => ({
      ...f,
      selectedAssetIds: (companyAssets ?? []).map((a) => a.id),
    }));
  };

  const toggleTechnician = (userId: string) => {
    setForm((f) => ({
      ...f,
      assignedTechnicianIds: f.assignedTechnicianIds.includes(userId)
        ? f.assignedTechnicianIds.filter((id) => id !== userId)
        : [...f.assignedTechnicianIds, userId],
    }));
  };

  const validateStep = (step: number): string | null => {
    if (step === 0 && !form.taskName.trim()) return 'Task name is required';
    if (step === 1) {
      if (!form.scheduleStartDate) return 'Start date is required';
      if (form.windowMode === 'endDate' && !form.scheduleEndDate) return 'End date is required';
      if (form.windowMode === 'duration' && form.durationYears < 1) return 'Duration must be at least 1 year';
      if (effectiveEndDate && effectiveEndDate < form.scheduleStartDate) {
        return 'End date must be on or after start date';
      }
    }
    if (step === 2) {
      if (!form.companyId) return 'Select a company';
      if (form.selectedAssetIds.length === 0) return 'Select at least one charger';
    }
    if (step === 4 && previewRows.length === 0) return 'No occurrences to create';
    return null;
  };

  const goNext = () => {
    const err = validateStep(wizardStep);
    if (err) {
      setFormError(err);
      return;
    }
    setFormError(null);
    setWizardStep((s) => Math.min(s + 1, WIZARD_STEPS.length - 1));
  };

  const goBack = () => {
    setFormError(null);
    setWizardStep((s) => Math.max(s - 1, 0));
  };

  const openWizard = () => {
    setForm({
      ...emptyWizard,
      scheduleStartDate: new Date().toISOString().slice(0, 10),
    });
    setWizardStep(0);
    setFormError(null);
    setWizardOpen(true);
  };

  const uniqueChargers = new Set(previewRows.map((r) => r.assetId)).size;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="PM Schedules"
        description="A schedule is the recurring template; each due date per charger is an occurrence technicians complete in the field."
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search task, company, frequency..."
              className="sm:min-w-[220px]"
            />
            <Button onClick={openWizard}>Create PM Schedule</Button>
          </>
        }
      />

      <DismissibleHint hintKey="pm-schedules-overview" title="How PM works in Beelectric">
        <ul className="list-inside list-disc space-y-1">
          <li>
            <strong className="font-medium text-foreground">Schedule</strong> — the template (task,
            frequency, chargers, technicians).
          </li>
          <li>
            <strong className="font-medium text-foreground">Occurrence</strong> — one due date for one
            charger; open a schedule to manage or complete individual dates.
          </li>
          <li>
            <strong className="font-medium text-foreground">PM Tasks (legacy)</strong> — older one-off
            rows; use schedules for new preventive maintenance.{' '}
            <Link href="/pm-tasks" className="text-primary underline-offset-2 hover:underline">
              View legacy PM Tasks
            </Link>
          </li>
        </ul>
      </DismissibleHint>

      {!showUpcomingTasks && !isLoading && !error && (
        <PmScheduleCallouts
          overdueCount={pmListTotals.overdue}
          upcomingCount={pmListTotals.upcoming}
          onCreateClick={openWizard}
        />
      )}

      {showUpcomingTasks && (
        <PmOccurrenceStatusLegend className="rounded-lg border border-border bg-muted/20 px-4 py-3" />
      )}

      <div className="flex flex-wrap gap-2">
        <Link href="/pm-schedules">
          <Button variant={!statusFilter && !showUpcomingTasks ? 'primary' : 'outline'} size="sm">
            All schedules
          </Button>
        </Link>
        <Link href="/pm-schedules?status=overdue">
          <Button variant={statusFilter === 'overdue' ? 'primary' : 'outline'} size="sm">
            Has overdue
          </Button>
        </Link>
        <Link href="/pm-schedules?status=upcoming">
          <Button variant={statusFilter === 'upcoming' ? 'primary' : 'outline'} size="sm">
            Has upcoming
          </Button>
        </Link>
        <Link href="/pm-schedules?view=upcoming">
          <Button variant={showUpcomingTasks ? 'primary' : 'outline'} size="sm">
            Upcoming tasks
          </Button>
        </Link>
      </div>
      {statusFilter === 'overdue' && (
        <p className="text-sm text-muted-foreground">
          Showing schedules with at least one overdue occurrence. Open a schedule to complete individual due dates.
        </p>
      )}
      {statusFilter === 'upcoming' && !showUpcomingTasks && (
        <p className="text-sm text-muted-foreground">
          Showing schedules with at least one upcoming occurrence (due today or later).
        </p>
      )}
      {showUpcomingTasks && (
        <p className="text-sm text-muted-foreground">
          All future PM task occurrences across schedules, sorted by due date.
        </p>
      )}

      {showUpcomingTasks ? (
        <Card>
          <CardContent className="p-0">
            <DataTableShell
              isLoading={upcomingLoading}
              error={upcomingError}
              isEmpty={!upcomingLoading && !upcomingError && (upcomingOccurrences?.length ?? 0) === 0}
              emptyTitle="No upcoming PM tasks"
              emptyDescription="Create a schedule or check overdue items that need attention."
              onRetry={() => refetchUpcoming()}
            >
              {filteredUpcoming.length === 0 && (upcomingOccurrences?.length ?? 0) > 0 ? (
                <div className="px-6 py-12 text-center">
                  <p className="font-medium text-foreground">No matching tasks</p>
                  <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
                </div>
              ) : (
                <div className="table-scroll overflow-x-auto">
                  <table className="table-modern">
                    <thead>
                      <tr>
                        <th>Task</th>
                        <th>Due date</th>
                        <th>Charger</th>
                        <th>Company</th>
                        <th>Assigned</th>
                        <th>Status</th>
                        <th className="w-12" />
                      </tr>
                    </thead>
                    <tbody>
                      {paginatedUpcoming.map((row) => {
                        const assigneeNames = (row.assignedTechnicianIds ?? [])
                          .map((id) => userNameById.get(id))
                          .filter(Boolean);
                        return (
                          <tr key={row.id}>
                            <td className="font-medium text-foreground">
                              {row.schedule?.taskName ?? '—'}
                            </td>
                            <td className="text-sm">
                              {new Date(row.dueDate).toLocaleDateString()}
                            </td>
                            <td className="text-sm">{row.asset?.name ?? row.assetId}</td>
                            <td className="text-sm">
                              {row.schedule?.company?.name ?? row.asset?.company?.name ?? '—'}
                            </td>
                            <td className="text-sm text-muted-foreground">
                              {assigneeNames.length > 0 ? assigneeNames.join(', ') : '—'}
                            </td>
                            <td>
                              <StatusBadge status={row.derivedStatus ?? row.status} />
                            </td>
                            <td>
                              <Link
                                href={`/pm-schedules/${row.scheduleId}/occurrences/${row.id}`}
                              >
                                <Button variant="ghost" size="sm" aria-label="View occurrence">
                                  <ChevronRight className="h-4 w-4" />
                                </Button>
                              </Link>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
              {totalUpcomingItems > 0 && (
                <Pagination
                  page={upcomingPage}
                  pageSize={upcomingPageSize}
                  totalItems={totalUpcomingItems}
                  onPageChange={setUpcomingPage}
                  onPageSizeChange={setUpcomingPageSize}
                />
              )}
            </DataTableShell>
          </CardContent>
        </Card>
      ) : (
      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={error}
            isEmpty={!isLoading && !error && (schedules?.length ?? 0) === 0}
            emptyTitle="No PM schedules yet"
            emptyDescription="Create a schedule to generate occurrences across selected chargers."
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (schedules?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching schedules</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Task</th>
                      <th>Frequency</th>
                      <th>Window</th>
                      <th>Company</th>
                      <th>Occurrences</th>
                      <th>Overdue</th>
                      <th>Upcoming</th>
                      <th>Next due</th>
                      <th className="w-12" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((schedule) => (
                      <tr key={schedule.id}>
                        <td className="font-medium text-foreground">{schedule.taskName}</td>
                        <td className="text-sm">{formatPmFrequency(schedule.frequency)}</td>
                        <td className="text-sm text-muted-foreground">
                          {new Date(schedule.scheduleStartDate).toLocaleDateString()} –{' '}
                          {new Date(schedule.scheduleEndDate).toLocaleDateString()}
                        </td>
                        <td className="text-sm">{schedule.company?.name ?? '—'}</td>
                        <td className="text-sm">{schedule.occurrenceCount ?? 0}</td>
                        <td className="text-sm">
                          {(schedule.overdueCount ?? 0) > 0 ? (
                            <span className="font-medium text-amber-700">{schedule.overdueCount}</span>
                          ) : (
                            '—'
                          )}
                        </td>
                        <td className="text-sm">
                          {(schedule.upcomingCount ?? 0) > 0 ? (
                            <span className="font-medium text-blue-700">{schedule.upcomingCount}</span>
                          ) : (
                            '—'
                          )}
                        </td>
                        <td className="text-sm">
                          {schedule.nextDueDate
                            ? new Date(schedule.nextDueDate).toLocaleDateString()
                            : '—'}
                        </td>
                        <td>
                          <Link
                            href={`/pm-schedules/${schedule.id}${
                              (schedule.overdueCount ?? 0) > 0 ? '?status=overdue' : ''
                            }`}
                          >
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
            )}
          </DataTableShell>
        </CardContent>
        {!isLoading && !error && totalItems > 0 && filtered.length > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            totalItems={totalItems}
            onPageChange={setPage}
            onPageSizeChange={setPageSize}
          />
        )}
      </Card>
      )}

      <Modal
        open={wizardOpen}
        onClose={() => {
          setWizardOpen(false);
          setFormError(null);
        }}
        title="Create PM Schedule"
      >
        <div className="mb-4 flex flex-wrap gap-2">
          {WIZARD_STEPS.map((label, index) => (
            <span
              key={label}
              className={
                index === wizardStep
                  ? 'rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary'
                  : index < wizardStep
                    ? 'rounded-full bg-muted px-2.5 py-1 text-xs text-muted-foreground'
                    : 'rounded-full border border-border px-2.5 py-1 text-xs text-muted-foreground'
              }
            >
              {index + 1}. {label}
            </span>
          ))}
        </div>

        {formError && (
          <p className="mb-4 text-sm text-destructive bg-destructive/10 p-2 rounded">{formError}</p>
        )}

        {wizardStep === 0 && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Task name *</label>
              <input
                type="text"
                required
                maxLength={80}
                value={form.taskName}
                onChange={(e) => setForm((f) => ({ ...f, taskName: e.target.value }))}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Description</label>
              <textarea
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                rows={3}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm resize-none"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Frequency *</label>
              <select
                value={form.frequency}
                onChange={(e) =>
                  setForm((f) => ({ ...f, frequency: e.target.value as PmFrequency }))
                }
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              >
                {PM_FREQUENCIES.map((f) => (
                  <option key={f.value} value={f.value}>
                    {f.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}

        {wizardStep === 1 && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Start date *</label>
              <input
                type="date"
                value={form.scheduleStartDate}
                onChange={(e) => setForm((f) => ({ ...f, scheduleStartDate: e.target.value }))}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="radio"
                  checked={form.windowMode === 'duration'}
                  onChange={() => setForm((f) => ({ ...f, windowMode: 'duration' }))}
                />
                Duration in years
              </label>
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="radio"
                  checked={form.windowMode === 'endDate'}
                  onChange={() => setForm((f) => ({ ...f, windowMode: 'endDate' }))}
                />
                End date
              </label>
            </div>
            {form.windowMode === 'duration' ? (
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">Duration (years) *</label>
                <input
                  type="number"
                  min={1}
                  max={10}
                  value={form.durationYears}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, durationYears: Number(e.target.value) || 1 }))
                  }
                  className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
                />
                {effectiveEndDate && (
                  <p className="mt-1 text-xs text-muted-foreground">
                    Effective end date: {effectiveEndDate}
                  </p>
                )}
              </div>
            ) : (
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">End date *</label>
                <input
                  type="date"
                  value={form.scheduleEndDate}
                  onChange={(e) => setForm((f) => ({ ...f, scheduleEndDate: e.target.value }))}
                  className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
                />
              </div>
            )}
          </div>
        )}

        {wizardStep === 2 && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Company *</label>
              <select
                value={form.companyId}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    companyId: e.target.value,
                    selectedAssetIds: [],
                  }))
                }
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="">— Select company —</option>
                {companies?.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
            {form.companyId && (
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <label className="text-sm font-medium text-foreground">Chargers *</label>
                  <Button type="button" variant="outline" size="sm" onClick={selectAllAssets}>
                    Select all
                  </Button>
                </div>
                <div className="max-h-48 overflow-y-auto rounded-lg border border-border p-2 space-y-1">
                  {(companyAssets ?? []).length === 0 ? (
                    <p className="text-sm text-muted-foreground p-2">No chargers for this company.</p>
                  ) : (
                    (companyAssets ?? []).map((asset) => (
                      <label
                        key={asset.id}
                        className="flex items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-muted/50"
                      >
                        <input
                          type="checkbox"
                          checked={form.selectedAssetIds.includes(asset.id)}
                          onChange={() => toggleAsset(asset.id)}
                        />
                        {asset.name}
                      </label>
                    ))
                  )}
                </div>
                <p className="mt-1 text-xs text-muted-foreground">
                  {form.selectedAssetIds.length} charger(s) selected
                </p>
              </div>
            )}
          </div>
        )}

        {wizardStep === 3 && (
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground">
              Assign technicians to all occurrences in this schedule (optional).
            </p>
            <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto">
              {technicians.slice(0, 30).map((u) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => toggleTechnician(u.id)}
                  className={
                    form.assignedTechnicianIds.includes(u.id)
                      ? 'rounded-md border border-primary bg-primary/10 px-2 py-1 text-xs font-medium text-primary'
                      : 'rounded-md border border-border bg-muted/50 px-2 py-1 text-xs text-muted-foreground hover:bg-muted'
                  }
                >
                  {u.name}
                </button>
              ))}
            </div>
          </div>
        )}

        {wizardStep === 4 && (
          <div className="space-y-3">
            <p className="text-sm font-medium text-foreground">
              {previewRows.length} occurrence(s) across {uniqueChargers} charger(s)
            </p>
            <div className="max-h-64 overflow-auto rounded-lg border border-border">
              <table className="table-modern text-sm">
                <thead>
                  <tr>
                    <th>Charger</th>
                    <th>Due date</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {previewRows.slice(0, 100).map((row, idx) => (
                    <tr key={`${row.assetId}-${row.dueDate}-${idx}`}>
                      <td>{assetNameById.get(row.assetId) ?? row.assetId}</td>
                      <td>{new Date(row.dueDate).toLocaleDateString()}</td>
                      <td>
                        <StatusBadge status="pending" />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {previewRows.length > 100 && (
              <p className="text-xs text-muted-foreground">
                Showing first 100 of {previewRows.length} rows.
              </p>
            )}
          </div>
        )}

        <ModalActions>
          <Button
            type="button"
            variant="outline"
            onClick={() => {
              if (wizardStep === 0) setWizardOpen(false);
              else goBack();
            }}
          >
            {wizardStep === 0 ? 'Cancel' : 'Back'}
          </Button>
          {wizardStep < WIZARD_STEPS.length - 1 ? (
            <Button type="button" onClick={goNext}>
              Next
            </Button>
          ) : (
            <Button
              type="button"
              disabled={wizardSubmitting || createMutation.isPending}
              onClick={() => {
                void runWizardSubmit(async () => {
                  const err = validateStep(4);
                  if (err) {
                    setFormError(err);
                    return;
                  }
                  await createMutation.mutateAsync();
                });
              }}
            >
              {wizardSubmitting || createMutation.isPending ? 'Creating…' : 'Confirm & create'}
            </Button>
          )}
        </ModalActions>
      </Modal>
    </div>
  );
}
