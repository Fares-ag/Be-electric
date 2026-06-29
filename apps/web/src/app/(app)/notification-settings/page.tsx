'use client';

import { useEffect, useState } from 'react';
import { useAuthStore } from '@/stores/auth-store';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PageHeader } from '@/components/ui/PageStates';
import {
  DEFAULT_NOTIFICATION_PREFERENCES,
  loadNotificationPreferences,
  saveNotificationPreferences,
  type NotificationPreferences,
} from '@/lib/notification-preferences';

const FIELDS: { key: keyof NotificationPreferences; label: string; description: string }[] = [
  {
    key: 'emailOnAssigned',
    label: 'Work order assigned',
    description: 'Notify when a maintenance request is assigned to a technician.',
  },
  {
    key: 'emailOnCompleted',
    label: 'Work order completed',
    description: 'Notify when a work order you submitted is marked completed or closed.',
  },
  {
    key: 'emailOnStatusChange',
    label: 'Other status updates',
    description: 'Notify on additional status changes (in progress, reopened, etc.).',
  },
];

export default function NotificationSettingsPage() {
  const user = useAuthStore((s) => s.user);
  const [prefs, setPrefs] = useState<NotificationPreferences>(DEFAULT_NOTIFICATION_PREFERENCES);
  const [saved, setSaved] = useState(false);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (!user?.id) return;
    setPrefs(loadNotificationPreferences(user.id));
    setDirty(false);
    setSaved(false);
  }, [user?.id]);

  function updatePref(key: keyof NotificationPreferences, value: boolean) {
    setPrefs((p) => ({ ...p, [key]: value }));
    setDirty(true);
    setSaved(false);
  }

  function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!user?.id) return;
    saveNotificationPreferences(prefs, user.id);
    setDirty(false);
    setSaved(true);
  }

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <PageHeader
        title="Notification Settings"
        description="Choose which updates you want to track. Preferences are saved on this device and browser."
      />

      <Card className="p-6">
        <form onSubmit={handleSave} className="space-y-6">
          <p className="text-sm text-muted-foreground">
            Signed in as <span className="font-medium text-foreground">{user?.email}</span>. Push
            notifications are not enabled in this release; in-app notifications appear under
            Notifications.
          </p>

          <fieldset className="space-y-4">
            <legend className="text-sm font-semibold text-foreground">Email preferences</legend>
            {FIELDS.map(({ key, label, description }) => (
              <label
                key={key}
                className="flex cursor-pointer gap-3 rounded-lg border border-border p-4 transition-colors hover:bg-muted/40"
              >
                <input
                  type="checkbox"
                  className="mt-0.5 h-4 w-4 rounded border-border text-primary focus:ring-primary"
                  checked={prefs[key]}
                  onChange={(e) => updatePref(key, e.target.checked)}
                />
                <span>
                  <span className="block text-sm font-medium text-foreground">{label}</span>
                  <span className="block text-sm text-muted-foreground">{description}</span>
                </span>
              </label>
            ))}
          </fieldset>

          <div className="flex flex-wrap items-center gap-3">
            <Button type="submit" disabled={!dirty}>
              Save preferences
            </Button>
            {saved && !dirty ? (
              <span className="text-sm text-primary" role="status">
                Saved
              </span>
            ) : null}
          </div>
        </form>
      </Card>
    </div>
  );
}
