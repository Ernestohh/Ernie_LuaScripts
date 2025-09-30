import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import '../styles/PerformanceChart.css';

function PerformanceChart({ title, data }) {
  if (!data || !data.labels || !data.data) return null;

  // Transform data for Recharts
  const chartData = data.labels.map((label, index) => ({
    name: label,
    value: data.data[index]
  }));

  return (
    <div className="performance-chart">
      <h3>{title}</h3>
      <ResponsiveContainer width="100%" height={200}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="#333" />
          <XAxis dataKey="name" stroke="#666" />
          <YAxis stroke="#666" />
          <Tooltip
            contentStyle={{ background: '#2a2a2a', border: '1px solid #444' }}
            labelStyle={{ color: '#888' }}
          />
          <Line
            type="monotone"
            dataKey="value"
            stroke="#4caf50"
            strokeWidth={2}
            dot={{ fill: '#4caf50' }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export default PerformanceChart;