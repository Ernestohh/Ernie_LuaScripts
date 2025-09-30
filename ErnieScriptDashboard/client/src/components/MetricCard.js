import React from 'react';
import '../styles/MetricCard.css';

function MetricCard({ label, value, icon, status, progress }) {
  return (
    <div className={`metric-card ${status || ''}`}>
      {icon && <div className="metric-icon">{icon}</div>}
      <div className="metric-content">
        <div className="metric-label">{label}</div>
        <div className="metric-value">{value}</div>
        {progress !== undefined && (
          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{ width: `${Math.min(100, progress)}%` }}
            />
          </div>
        )}
      </div>
    </div>
  );
}

export default MetricCard;