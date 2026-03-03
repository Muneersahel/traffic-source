import {
  ComposedChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export default function CombinedChart({ trafficData, revenueData }) {
  // Merge traffic + revenue data by date
  const merged = mergeByDate(trafficData, revenueData);

  if (!merged || merged.length === 0) {
    return (
      <div className="empty-state">
        <p>No data for this period</p>
      </div>
    );
  }

  const hasRevenue = merged.some((d) => d.revenue > 0);
  const hasVisitors = merged.some((d) => d.visitors > 0);

  return (
    <div className="chart-container">
      <ResponsiveContainer width="100%" height="100%">
        <ComposedChart data={merged} margin={{ top: 10, right: hasRevenue ? 50 : 20, left: 10, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0ece8" vertical={false} />
          <XAxis
            dataKey="date"
            tick={{ fontSize: 11, fill: '#999' }}
            tickLine={false}
            axisLine={{ stroke: '#f0ece8' }}
            tickFormatter={(val) => {
              if (val.includes(' ')) return val.split(' ')[1];
              const d = new Date(val + 'T00:00:00');
              return d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
            }}
          />
          <YAxis
            yAxisId="left"
            tick={{ fontSize: 11, fill: '#999' }}
            tickLine={false}
            axisLine={false}
            width={40}
          />
          {hasRevenue && (
            <YAxis
              yAxisId="right"
              orientation="right"
              tick={{ fontSize: 11, fill: '#999' }}
              tickLine={false}
              axisLine={false}
              width={50}
              tickFormatter={(v) => `$${(v / 100).toFixed(0)}`}
            />
          )}
          <Tooltip
            contentStyle={{
              background: '#fff',
              border: '1px solid #f0ece8',
              borderRadius: 10,
              fontSize: 13,
              boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
            }}
            formatter={(value, name) => {
              if (name === 'revenue') return [`$${(value / 100).toFixed(2)}`, 'Revenue'];
              if (name === 'page_views') return [value.toLocaleString(), 'Pageviews'];
              if (name === 'visitors') return [value.toLocaleString(), 'Visitors'];
              return [value.toLocaleString(), name];
            }}
          />
          {hasRevenue && (
            <Bar
              yAxisId="right"
              dataKey="revenue"
              fill="#f4c3b8"
              radius={[4, 4, 0, 0]}
              barSize={20}
              opacity={0.7}
            />
          )}
          <Bar
            yAxisId="left"
            dataKey="page_views"
            fill="#e8604c"
            radius={[4, 4, 0, 0]}
            barSize={20}
          />
          {hasVisitors && (
            <Bar
              yAxisId="left"
              dataKey="visitors"
              fill="#f4c3b8"
              radius={[4, 4, 0, 0]}
              barSize={20}
            />
          )}
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  );
}

function mergeByDate(traffic = [], revenue = []) {
  const map = {};
  for (const t of traffic) {
    map[t.date] = { ...t, revenue: 0 };
  }
  for (const r of revenue) {
    if (map[r.date]) {
      map[r.date].revenue = r.revenue || 0;
    } else {
      map[r.date] = { date: r.date, page_views: 0, visitors: 0, sessions: 0, revenue: r.revenue || 0 };
    }
  }
  return Object.values(map).sort((a, b) => a.date.localeCompare(b.date));
}
