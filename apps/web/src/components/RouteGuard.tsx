'use client';

import { useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores/auth-store';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import {
  isTechnicianRole,
  redirectForUnauthorizedRoute,
} from '@/lib/roles';

export function RouteGuard({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (!user) return;
    const redirect = redirectForUnauthorizedRoute(pathname, user.role);
    if (redirect && redirect !== pathname) {
      router.replace(redirect);
    }
  }, [user, pathname, router]);

  if (user && isTechnicianRole(user.role)) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center p-4">
        <Card className="max-w-md space-y-4 p-8 text-center">
          <h1 className="font-display text-xl font-semibold text-foreground">Use the Be Electric Tech app</h1>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Technician accounts are designed for the Be Electric Tech mobile app. Sign in there to view assigned
            work orders and complete maintenance tasks.
          </p>
          <Button type="button" onClick={() => signOut()} className="w-full">
            Sign out
          </Button>
        </Card>
      </div>
    );
  }

  if (user) {
    const redirect = redirectForUnauthorizedRoute(pathname, user.role);
    if (redirect && redirect !== pathname) {
      return (
        <div className="flex min-h-[40vh] items-center justify-center">
          <p className="text-sm text-muted-foreground">Redirecting…</p>
        </div>
      );
    }
  }

  return <>{children}</>;
}
