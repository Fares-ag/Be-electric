'use client';

import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Reports</h1>
      <Card>
        <p className="text-[#757575] mb-4">
          Export reports (work orders, PM completion, inventory, etc.).
        </p>
        <Button>Export Work Orders</Button>
      </Card>
    </div>
  );
}
