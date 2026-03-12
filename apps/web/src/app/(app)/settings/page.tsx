'use client';

import { Card, CardContent } from '@/components/ui/Card';

export default function SettingsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">Settings</h1>
      <Card>
        <h2 className="text-lg font-semibold mb-4">Application Settings</h2>
        <p className="text-sm text-[#757575]">Configure app preferences.</p>
      </Card>
    </div>
  );
}
