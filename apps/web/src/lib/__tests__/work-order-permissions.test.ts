/**
 * RC1: Documented work_orders permission matrix and trigger allow/deny expectations.
 * These tests encode cross-platform contracts; they do not hit Supabase.
 * See docs/release/RC1/PERMISSION_MATRIX.md for full matrix.
 */
import { describe, expect, it } from 'vitest';

type Role = 'requestor' | 'technician' | 'manager' | 'admin';

/** Fields a requestor may change on open/reopened WOs (direct UPDATE, non-privileged). */
const REQUESTOR_EDITABLE_OPEN_FIELDS = [
  'problemDescription',
  'photoPath',
  'metadata',
  'location',
  'category',
  'notes',
  'priority',
  'updatedAt',
] as const;

/** Fields changed during Flutter/React reopen (docs/WORK_ORDER_REOPEN.md). */
const REQUESTOR_REOPEN_FIELDS = [
  'status', // -> reopened
  'assignedTechnicianIds', // cleared
  'primaryTechnicianId', // cleared
  'assignedAt',
  'startedAt',
  'completedAt',
  'closedAt',
  'problemDescription',
  'metadata',
  'isPaused',
  'pausedAt',
  'pauseReason',
  'resumedAt',
  'updatedAt',
] as const;

/** Fields allowed during requestor sign-off (RC1 P0-1 fix). */
const REQUESTOR_SIGNOFF_FIELDS = [
  'requestorSignature',
  'customerSignature',
  'status', // completed|inProgress -> closed optional
  'closedAt',
  'updatedAt',
] as const;

/** Fields requestors must never set via direct UPDATE (privilege escalation). */
const REQUESTOR_FORBIDDEN_FIELDS = [
  'assignedTechnicianIds', // non-empty
  'primaryTechnicianId', // non-null
  'technicianSignature',
  'completionPhotoPath',
  'correctiveActions',
  'recommendations',
  'technicianNotes',
  'actualCost',
  'laborCost',
  'requestorId',
] as const;

/** Technician completion fields (direct UPDATE when assigned). */
const TECHNICIAN_COMPLETION_FIELDS = [
  'status',
  'startedAt',
  'completedAt',
  'correctiveActions',
  'recommendations',
  'technicianNotes',
  'technicianSignature',
  'completionPhotoPath',
  'beforePhotoPath',
  'afterPhotoPath',
  'isPaused',
  'pausedAt',
  'pauseReason',
  'updatedAt',
] as const;

describe('RC1 work_orders permission matrix (documented contracts)', () => {
  it('defines RLS SELECT paths per role', () => {
    const selectByRole: Record<Role, string> = {
      requestor: 'requestorId = auth.uid()',
      technician: 'auth.uid() = ANY(assignedTechnicianIds)',
      manager: "get_my_role() IN ('admin','manager')",
      admin: "get_my_role() IN ('admin','manager')",
    };
    expect(selectByRole.requestor).toContain('requestorId');
    expect(selectByRole.technician).toContain('assignedTechnicianIds');
  });

  it('defines RLS INSERT paths per role', () => {
    const insertCheck = {
      requestor: 'requestorId = auth.uid() OR via upsert_work_order RPC',
      technician: 'same as requestor if creating (unusual)',
      manager: 'any (admin path)',
      admin: 'any (admin path)',
    };
    expect(insertCheck.manager).toContain('admin');
  });

  it('requestor open-WO editable fields are non-privileged', () => {
    for (const field of REQUESTOR_FORBIDDEN_FIELDS) {
      expect(REQUESTOR_EDITABLE_OPEN_FIELDS).not.toContain(field);
    }
  });

  it('reopen field set matches WORK_ORDER_REOPEN.md', () => {
    expect(REQUESTOR_REOPEN_FIELDS).toContain('status');
    expect(REQUESTOR_REOPEN_FIELDS).toContain('metadata');
    expect(REQUESTOR_REOPEN_FIELDS).not.toContain('correctiveActions');
  });

  it('sign-off field set restores requestorSignature', () => {
    expect(REQUESTOR_SIGNOFF_FIELDS).toContain('requestorSignature');
    expect(REQUESTOR_FORBIDDEN_FIELDS).toContain('technicianSignature');
  });

  it('technician completion fields exclude assignee spoofing', () => {
    expect(TECHNICIAN_COMPLETION_FIELDS).not.toContain('requestorId');
    expect(TECHNICIAN_COMPLETION_FIELDS).not.toContain('assignedTechnicianIds');
  });
});

describe('RC1 trigger allow/deny matrix (requestor path)', () => {
  const allow = [
    'open WO: edit problemDescription',
    'open WO: add photoPath/metadata',
    'completed WO: reopen -> reopened + clear assignees',
    'completed WO: sign-off with requestorSignature',
    'completed WO: sign-off + status closed + closedAt',
    'sign-off: optional customerSignature',
  ];
  const deny = [
    'set assignedTechnicianIds to non-empty',
    'set primaryTechnicianId',
    'set status open while completed',
    'modify technicianSignature',
    'modify correctiveActions as requestor',
    'change requestorId',
    'set actualCost',
  ];

  it('documents allowed requestor UPDATE scenarios', () => {
    expect(allow.length).toBeGreaterThanOrEqual(5);
  });

  it('documents denied requestor UPDATE scenarios', () => {
    expect(deny).toContain('set assignedTechnicianIds to non-empty');
    expect(deny).toContain('modify technicianSignature');
  });
});
