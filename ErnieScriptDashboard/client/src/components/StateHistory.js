import React from 'react';
import { formatDistanceToNow } from 'date-fns';
import '../styles/StateHistory.css';

function StateHistory({ history }) {
  if (!history || history.length === 0) return null;

  // Get last 10 states
  const recentHistory = history.slice(-10).reverse();

  return (
    <div className="state-history">
      <h3>State History</h3>
      <div className="history-list">
        {recentHistory.map((entry, index) => (
          <div key={index} className="history-item">
            <div className="history-state">{entry.state}</div>
            <div className="history-time">
              {formatDistanceToNow(entry.timestamp * 1000)} ago
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default StateHistory;