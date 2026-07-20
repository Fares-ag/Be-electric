import { describe, expect, it, vi } from 'vitest';
import { assertCanAssignRole, callerIsAdmin } from '@/lib/api/admin-privileges';

describe('admin privileges', () => {
  it('callerIsAdmin is true only when is_admin', async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [{ is_admin: true, is_manager: true }],
      error: null,
    });
    const ok = await callerIsAdmin({ rpc } as never, 'a@x.com');
    expect(ok).toBe(true);
    expect(rpc).toHaveBeenCalledWith('get_admin_by_email', { p_email: 'a@x.com' });
  });

  it('managers cannot assign role=admin', async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [{ is_admin: false, is_manager: true }],
      error: null,
    });
    const err = await assertCanAssignRole({ rpc } as never, 'm@x.com', 'admin');
    expect(err).toMatch(/only admins/i);
  });

  it('managers may assign technician', async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: [{ is_admin: false, is_manager: true }],
      error: null,
    });
    const err = await assertCanAssignRole({ rpc } as never, 'm@x.com', 'technician');
    expect(err).toBeNull();
  });
});
