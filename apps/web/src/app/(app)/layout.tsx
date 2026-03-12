'use client';

import { RoleBasedLayout } from '@/components/RoleBasedLayout';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <RoleBasedLayout>{children}</RoleBasedLayout>;
}
