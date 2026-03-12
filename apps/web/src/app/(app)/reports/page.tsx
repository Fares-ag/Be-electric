'use client';

import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function ReportsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">Reports</h1>
      <Card>
        <p className="text-[#757575] mb-4">
          Export reports (work orders, PM completion, inventory, etc.).
        </p>
        <Button>Export Work Orders</Button>
      </Card>
    </div>
  );
}
