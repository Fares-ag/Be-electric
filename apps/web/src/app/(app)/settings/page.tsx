'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuthStore } from '@/stores/auth-store';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PageHeader } from '@/components/ui/PageStates';
import { LEGAL_URLS } from '@/lib/legal-urls';
import { resetAllUiHints } from '@/lib/ui-hints';

export default function SettingsPage() {
  const user = useAuthStore((s) => s.user);
  const [hintsReset, setHintsReset] = useState(false);

  function handleResetHints() {
    resetAllUiHints();
    setHintsReset(true);
  }

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <PageHeader title="Settings" description="Account and application preferences." />

      <Card className="p-6 space-y-4">
        <h2 className="text-base font-semibold text-foreground">Your account</h2>
        <dl className="grid gap-3 text-sm sm:grid-cols-2">
          <div>
            <dt className="text-muted-foreground">Name</dt>
            <dd className="font-medium text-foreground">{user?.name ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Email</dt>
            <dd className="font-medium text-foreground">{user?.email ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Role</dt>
            <dd className="font-medium capitalize text-foreground">{user?.role ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Department</dt>
            <dd className="font-medium text-foreground">{user?.department ?? '—'}</dd>
          </div>
        </dl>
      </Card>

      <Card className="p-6">
        <h2 className="text-base font-semibold text-foreground">Notifications</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Configure how you receive updates about maintenance activity.
        </p>
        <Link
          href="/notification-settings"
          className="mt-4 inline-flex text-sm font-medium text-primary underline underline-offset-2 hover:text-primary-hover"
        >
          Open notification settings
        </Link>
      </Card>

      <Card className="p-6 space-y-3">
        <h2 className="text-base font-semibold text-foreground">Admin tips</h2>
        <p className="text-sm text-muted-foreground">
          Bring back dismissible onboarding hints across the admin portal (dashboard, PM, support, inventory,
          parts, notifications, and legacy PM tasks).
        </p>
        <Button type="button" variant="outline" size="sm" onClick={handleResetHints}>
          Show tips again
        </Button>
        {hintsReset ? (
          <p className="text-sm text-green-700" role="status">
            Tips will appear the next time you open those pages.
          </p>
        ) : null}
      </Card>

      <Card className="p-6">
        <h2 className="text-base font-semibold text-foreground">Legal & support</h2>
        <ul className="mt-3 space-y-2 text-sm">
          <li>
            <Link href={LEGAL_URLS.privacy} className="text-primary underline underline-offset-2">
              Privacy Policy
            </Link>
          </li>
          <li>
            <Link href={LEGAL_URLS.terms} className="text-primary underline underline-offset-2">
              Terms of Service
            </Link>
          </li>
          <li>
            <Link href={LEGAL_URLS.support} className="text-primary underline underline-offset-2">
              Help & Support
            </Link>
          </li>
          <li>
            <Link href={LEGAL_URLS.accountDeletion} className="text-primary underline underline-offset-2">
              Account Deletion
            </Link>
          </li>
        </ul>
      </Card>
    </div>
  );
}
