import { describe, expect, it } from 'vitest';
import { notificationRelatedHref } from '@/lib/notifications';

describe('notifications', () => {
  it('links work orders for any role', () => {
    expect(
      notificationRelatedHref(
        { relatedId: 'wo-1', relatedType: 'work_order' },
        'requestor'
      )
    ).toBe('/work-orders/wo-1');
  });

  it('restricts parts requests to admins', () => {
    expect(
      notificationRelatedHref(
        { relatedId: 'pr-1', relatedType: 'parts_request' },
        'requestor'
      )
    ).toBeNull();
    expect(
      notificationRelatedHref(
        { relatedId: 'pr-1', relatedType: 'parts_request' },
        'admin'
      )
    ).toBe('/parts-requests');
  });

  it('links support requests for admins only', () => {
    expect(
      notificationRelatedHref(
        { relatedId: 'sr-1', relatedType: 'support_request' },
        'manager'
      )
    ).toBe('/support-requests/sr-1');
  });
});
