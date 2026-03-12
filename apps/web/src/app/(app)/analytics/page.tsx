'use client';

import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/Card';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

export default function AnalyticsPage() {
  const { data: workOrders } = useQuery({
    queryKey: ['analytics-work-orders'],
    queryFn: async () => {
      const { data } = await supabase.from('work_orders').select('status, priority');
      return data ?? [];
    },
  });

  const statusCounts =
    workOrders?.reduce((acc: Record<string, number>, wo: { status?: string }) => {
      const s = wo.status ?? 'unknown';
      acc[s] = (acc[s] ?? 0) + 1;
      return acc;
    }, {}) ?? {};
  const statusData = Object.entries(statusCounts).map(([name, value]) => ({
    name: name.replace(/([A-Z])/g, ' $1').trim(),
    value,
  }));
  const COLORS = ['#BDBDBD', '#9E9E9E', '#757575', '#002911', '#1976D2'];

  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">Analytics</h1>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 mb-8">
        <Card>
          <h2 className="text-sm font-medium text-[#757575] mb-2">
            Work Orders by Status
          </h2>
          {statusData.length > 0 ? (
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={statusData}
                    cx="50%"
                    cy="50%"
                    innerRadius={40}
                    outerRadius={60}
                    paddingAngle={2}
                    dataKey="value"
                  >
                    {statusData.map((_, i) => (
                      <Cell key={i} fill={COLORS[i % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <p className="text-sm text-[#757575]">No data</p>
          )}
        </Card>
        <Card className="md:col-span-2">
          <h2 className="text-sm font-medium text-[#757575] mb-4">
            Work Orders by Status (Bar)
          </h2>
          {statusData.length > 0 ? (
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={statusData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
                  <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Bar dataKey="value" fill="#002911" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <p className="text-sm text-[#757575]">No data</p>
          )}
        </Card>
      </div>
      <Card>
        <h2 className="text-lg font-semibold mb-4">Summary</h2>
        <p className="text-sm text-[#757575]">
          MTTR, completion rate, and other metrics coming soon.
        </p>
      </Card>
    </div>
  );
}
