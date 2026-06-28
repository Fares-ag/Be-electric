'use client';

import { RoleBasedLayout } from '@/components/RoleBasedLayout';
import { RouteGuard } from '@/components/RouteGuard';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <RoleBasedLayout>
      <RouteGuard>{children}</RouteGuard>
    </RoleBasedLayout>
  );
}
