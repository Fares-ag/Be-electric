'use client';

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
  Legend,
} from 'recharts';
import { Card } from '@/components/ui/Card';

const COLORS = ['#052e16', '#166534', '#15803d', '#16a34a', '#22c55e', '#ca8a04'];

const axisTickStyle = { fontSize: 13, fill: 'rgb(var(--muted-foreground))' };
const gridStroke = 'rgb(var(--border))';

type ChartData = { name: string; value: number }[];

function renderCustomPieLegend(props: { payload?: Array<{ value?: string; name?: string; color?: string }> }) {
  const { payload } = props;
  if (!payload?.length) return null;
  return (
    <ul className="flex flex-wrap justify-center gap-x-4 gap-y-1 mt-3 text-sm text-muted-foreground">
      {payload.map((entry, i) => (
        <li key={i} className="flex items-center gap-2">
          <span
            className="inline-block w-3 h-3 rounded-full shrink-0"
            style={{ backgroundColor: entry.color ?? 'transparent' }}
          />
          <span>{entry.name ?? entry.value}</span>
        </li>
      ))}
    </ul>
  );
}

export function AnalyticsChartsInner({
  statusData,
  priorityData,
  pmStatusData,
}: {
  statusData: ChartData;
  priorityData: ChartData;
  pmStatusData: ChartData;
}) {
  return (
    <div className="space-y-10">
      {/* Work Orders by Status */}
      <section>
        <h2 className="font-display text-lg font-semibold text-foreground mb-4">
          Work Orders by Status
        </h2>
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <Card className="overflow-hidden">
            <div className="px-4 pt-4 pb-1 border-b border-border">
              <h3 className="text-sm font-medium text-muted-foreground">Distribution</h3>
            </div>
            {statusData.length > 0 ? (
              <div className="p-4">
                <div className="h-52">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={statusData}
                        cx="50%"
                        cy="50%"
                        innerRadius={48}
                        outerRadius={72}
                        paddingAngle={2}
                        dataKey="value"
                        nameKey="name"
                      >
                        {statusData.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} stroke="transparent" />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(value: number) => [value, 'Count']}
                        contentStyle={{
                          borderRadius: 'var(--radius)',
                          border: '1px solid rgb(var(--border))',
                        }}
                      />
                      <Legend content={renderCustomPieLegend} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>
            ) : (
              <p className="p-6 text-sm text-muted-foreground">No data</p>
            )}
          </Card>
          <Card className="md:col-span-2 overflow-hidden">
            <div className="px-4 pt-4 pb-1 border-b border-border">
              <h3 className="text-sm font-medium text-muted-foreground">By count</h3>
            </div>
            {statusData.length > 0 ? (
              <div className="p-4 pt-2">
                <div className="h-52">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={statusData} margin={{ top: 8, right: 16, left: 8, bottom: 4 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke={gridStroke} vertical={false} />
                      <XAxis dataKey="name" tick={axisTickStyle} axisLine={{ stroke: gridStroke }} />
                      <YAxis
                        allowDecimals={false}
                        tick={axisTickStyle}
                        axisLine={{ stroke: gridStroke }}
                        tickLine={{ stroke: gridStroke }}
                      />
                      <Tooltip
                        formatter={(value: number) => [value, 'Count']}
                        contentStyle={{
                          borderRadius: 'var(--radius)',
                          border: '1px solid rgb(var(--border))',
                        }}
                      />
                      <Bar dataKey="value" fill="rgb(var(--primary))" radius={[6, 6, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            ) : (
              <p className="p-6 text-sm text-muted-foreground">No data</p>
            )}
          </Card>
        </div>
      </section>

      {/* Work Orders by Priority */}
      <section>
        <h2 className="font-display text-lg font-semibold text-foreground mb-4">
          Work Orders by Priority
        </h2>
        <div className="grid gap-6 md:grid-cols-2">
          <Card className="overflow-hidden">
            <div className="px-4 pt-4 pb-1 border-b border-border">
              <h3 className="text-sm font-medium text-muted-foreground">Distribution</h3>
            </div>
            {priorityData.length > 0 ? (
              <div className="p-4">
                <div className="h-52">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={priorityData}
                        cx="50%"
                        cy="50%"
                        innerRadius={48}
                        outerRadius={72}
                        paddingAngle={2}
                        dataKey="value"
                        nameKey="name"
                      >
                        {priorityData.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} stroke="transparent" />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(value: number) => [value, 'Count']}
                        contentStyle={{
                          borderRadius: 'var(--radius)',
                          border: '1px solid rgb(var(--border))',
                        }}
                      />
                      <Legend content={renderCustomPieLegend} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>
            ) : (
              <p className="p-6 text-sm text-muted-foreground">No data</p>
            )}
          </Card>
          <Card className="overflow-hidden">
            <div className="px-4 pt-4 pb-1 border-b border-border">
              <h3 className="text-sm font-medium text-muted-foreground">By count</h3>
            </div>
            {priorityData.length > 0 ? (
              <div className="p-4 pt-2">
                <div className="h-52">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={priorityData} margin={{ top: 8, right: 16, left: 8, bottom: 4 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke={gridStroke} vertical={false} />
                      <XAxis dataKey="name" tick={axisTickStyle} axisLine={{ stroke: gridStroke }} />
                      <YAxis
                        allowDecimals={false}
                        tick={axisTickStyle}
                        axisLine={{ stroke: gridStroke }}
                        tickLine={{ stroke: gridStroke }}
                      />
                      <Tooltip
                        formatter={(value: number) => [value, 'Count']}
                        contentStyle={{
                          borderRadius: 'var(--radius)',
                          border: '1px solid rgb(var(--border))',
                        }}
                      />
                      <Bar dataKey="value" fill="#166534" radius={[6, 6, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            ) : (
              <p className="p-6 text-sm text-muted-foreground">No data</p>
            )}
          </Card>
        </div>
      </section>

      {/* PM Tasks by Status */}
      <section>
        <h2 className="font-display text-lg font-semibold text-foreground mb-4">
          PM Tasks by Status
        </h2>
        <Card className="overflow-hidden">
          <div className="px-4 pt-4 pb-1 border-b border-border">
            <h3 className="text-sm font-medium text-muted-foreground">Count by status</h3>
          </div>
          {pmStatusData.length > 0 ? (
            <div className="p-4 pt-2">
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart
                    data={pmStatusData}
                    layout="vertical"
                    margin={{ top: 8, right: 24, left: 8, bottom: 4 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke={gridStroke} horizontal={false} />
                    <XAxis
                      type="number"
                      allowDecimals={false}
                      tick={axisTickStyle}
                      axisLine={{ stroke: gridStroke }}
                      tickLine={{ stroke: gridStroke }}
                    />
                    <YAxis
                      type="category"
                      dataKey="name"
                      tick={axisTickStyle}
                      width={90}
                      axisLine={{ stroke: gridStroke }}
                      tickLine={{ stroke: gridStroke }}
                    />
                    <Tooltip
                      formatter={(value: number) => [value, 'Count']}
                      contentStyle={{
                        borderRadius: 'var(--radius)',
                        border: '1px solid rgb(var(--border))',
                      }}
                    />
                    <Bar dataKey="value" fill="#15803d" radius={[0, 6, 6, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          ) : (
            <p className="p-6 text-sm text-muted-foreground">No PM task data</p>
          )}
        </Card>
      </section>
    </div>
  );
}
