import React from 'react';
import MetricCard from './MetricCard';
import StateHistory from './StateHistory';
import PerformanceChart from './PerformanceChart';
import { formatDistanceToNow } from 'date-fns';
import '../styles/Dashboard.css';

function Dashboard({ script, onRemove }) {
  const { name, script: scriptName, state, data, lastUpdate, history } = script;

  // Format runtime
  const formatRuntime = (seconds) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours}h ${minutes}m ${secs}s`;
  };

  // Extract chart data if available
  const getChartData = (key) => {
    const chartKey = `${key}_chart`;
    return data[chartKey] || null;
  };

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <div className="header-info">
          <h1>{name}</h1>
          <span className="script-name">{scriptName}</span>
        </div>
        <div className="header-actions">
          <span className="last-update">
            Last update: {formatDistanceToNow(lastUpdate)} ago
          </span>
          <button className="remove-btn" onClick={onRemove}>×</button>
        </div>
      </div>

      <div className="current-state">
        <h2>Current State</h2>
        <div className="state-display">{state}</div>
      </div>

      <div className="metrics-grid">
        {data.runtime && (
          <MetricCard
            label="Runtime"
            value={formatRuntime(data.runtime)}
            icon="⏱️"
          />
        )}

        {data.xpGained !== undefined && (
          <MetricCard
            label="XP Gained"
            value={data.xpGained.toLocaleString()}
            icon="✨"
          />
        )}

        {data.xpPerHour !== undefined && (
          <MetricCard
            label="XP/Hour"
            value={data.xpPerHour.toLocaleString()}
            icon="📈"
          />
        )}

        {data.efficiency !== undefined && (
          <MetricCard
            label="Efficiency"
            value={`${data.efficiency}%`}
            icon="⚡"
            status={data.efficiency > 80 ? 'good' : 'warning'}
          />
        )}

        {/* Render progress bars */}
        {Object.entries(data).map(([key, value]) => {
          if (value && typeof value === 'object' && value.percentage !== undefined) {
            return (
              <MetricCard
                key={key}
                label={key.replace(/_/g, ' ')}
                value={`${value.current}/${value.total}`}
                progress={value.percentage}
                icon="📊"
              />
            );
          }
          return null;
        })}

        {/* Render other metrics */}
        {Object.entries(data).map(([key, value]) => {
          // Skip special keys
          if (key.includes('_chart') || key.includes('_time') ||
              key === 'runtime' || key === 'xpGained' ||
              key === 'xpPerHour' || key === 'efficiency' ||
              (typeof value === 'object' && value.percentage !== undefined)) {
            return null;
          }

          return (
            <MetricCard
              key={key}
              label={key.replace(/_/g, ' ')}
              value={typeof value === 'number' ? value.toLocaleString() : value}
              icon="📊"
            />
          );
        })}
      </div>

      {/* Performance charts */}
      {getChartData('xpTrend') && (
        <PerformanceChart
          title="XP Trend"
          data={getChartData('xpTrend')}
        />
      )}

      {/* State history */}
      {history && history.length > 0 && (
        <StateHistory history={history} />
      )}
    </div>
  );
}

export default Dashboard;