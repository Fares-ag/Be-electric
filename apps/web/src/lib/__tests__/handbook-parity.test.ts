import { describe, expect, it } from 'vitest';
import { profileRowToUser, validateProfileForAuth } from '@/lib/auth/profile-validation';
import { requestPhotoStoragePath } from '@/lib/storage-config';
import { resolveStorageBucketForPath, toPhotoUrl } from '@/lib/storage-urls';
import { buildUpsertWorkOrderPayload } from '@/lib/work-order-create-payload';

describe('auth profile (handbook parity)', () => {
  it('maps profile rows to User shape', () => {
    const user = profileRowToUser({
      id: 'abc-123',
      email: 'tech@example.com',
      name: 'Tech User',
      role: 'technician',
      companyId: 'co-1',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    });
    expect(user?.id).toBe('abc-123');
    expect(user?.role).toBe('technician');
    expect(user?.companyId).toBe('co-1');
  });

  it('validates auth uid matches profile id', () => {
    expect(
      validateProfileForAuth({ id: 'abc-123', isActive: true }, 'abc-123')
    ).toEqual({ ok: true });
    expect(validateProfileForAuth({ id: 'other-id', isActive: true }, 'abc-123')).toEqual({
      ok: false,
      message: 'Profile mismatch. Contact your administrator.',
    });
    expect(validateProfileForAuth(null, 'abc-123')).toEqual({
      ok: false,
      message: 'No profile found. Contact your administrator.',
    });
  });

  it('rejects deactivated accounts', () => {
    expect(
      validateProfileForAuth({ id: 'abc-123', isActive: false }, 'abc-123')
    ).toEqual({
      ok: false,
      message: 'Your account has been deactivated. Contact your administrator.',
    });
  });
});

describe('storage (handbook parity)', () => {
  it('uses handbook request photo paths', () => {
    const path = requestPhotoStoragePath('wo-99', 0, 'jpg');
    expect(path).toMatch(/^work_orders\/request_photos\/request_wo-99_\d+_0\.jpg$/);
  });

  it('resolves files bucket for handbook paths', () => {
    expect(resolveStorageBucketForPath('work_orders/request_photos/a.jpg')).toBe('files');
    expect(resolveStorageBucketForPath('wo-1/request/photo.jpg')).toBe('work-order-photos');
  });

  it('builds public URLs for both buckets', () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://example.supabase.co';
    expect(toPhotoUrl('work_orders/request_photos/a.jpg')).toContain('/files/work_orders/');
    expect(toPhotoUrl('wo-1/request/photo.jpg')).toContain('/work-order-photos/wo-1/');
    expect(toPhotoUrl('https://cdn.example/x.jpg')).toBe('https://cdn.example/x.jpg');
  });
});

describe('upsert_work_order payload', () => {
  it('includes metadata.photoPaths and photoPath for Flutter parity', () => {
    const payload = buildUpsertWorkOrderPayload({
      id: '11111111-1111-1111-1111-111111111111',
      ticketNumber: 'WO-1',
      problemDescription: 'Broken charger',
      priority: 'high',
      requestorId: '22222222-2222-2222-2222-222222222222',
      requestorName: 'Requestor',
      companyId: 'co-1',
      assetId: 'asset-1',
      location: 'Bay 3',
      notes: 'Urgent',
      photoUrls: ['https://example.supabase.co/files/a.jpg', 'https://example.supabase.co/files/b.jpg'],
    });

    expect(payload.status).toBe('open');
    expect(payload.metadata).toEqual({
      photoPaths: [
        'https://example.supabase.co/files/a.jpg',
        'https://example.supabase.co/files/b.jpg',
      ],
    });
    expect(payload.photoPath).toContain('[');
    expect(payload.assignedTechnicianIds).toEqual([]);
  });

  it('uses single photoPath when only one photo', () => {
    const payload = buildUpsertWorkOrderPayload({
      id: '11111111-1111-1111-1111-111111111111',
      ticketNumber: 'WO-2',
      problemDescription: 'Issue',
      priority: 'medium',
      requestorId: '22222222-2222-2222-2222-222222222222',
      requestorName: 'Requestor',
      companyId: null,
      assetId: null,
      location: null,
      notes: null,
      photoUrls: ['https://example.supabase.co/files/a.jpg'],
    });
    expect(payload.photoPath).toBe('https://example.supabase.co/files/a.jpg');
  });
});
