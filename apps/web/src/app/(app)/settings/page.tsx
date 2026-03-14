'use client';

import { Card, CardContent } from '@/components/ui/Card';

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Settings</h1>
      <Card>
        <h2 className="text-lg font-semibold mb-4">Application Settings</h2>
        <p className="text-sm text-[#757575]">Configure app preferences.</p>
      </Card>
    </div>
  );
}
