'use client';

import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function NotificationSettingsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">
        Notification Settings
      </h1>
      <Card>
        <p className="text-[#757575] mb-4">
          Configure notification preferences for work order updates.
        </p>
        <div className="space-y-2">
          <label className="flex items-center gap-2">
            <input type="checkbox" defaultChecked className="rounded" />
            <span>Email when work order is assigned</span>
          </label>
          <label className="flex items-center gap-2">
            <input type="checkbox" defaultChecked className="rounded" />
            <span>Email when work order is completed</span>
          </label>
        </div>
        <Button className="mt-4">Save</Button>
      </Card>
    </div>
  );
}
