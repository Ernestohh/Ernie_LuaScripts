import React from 'react';
import '../styles/AlertPanel.css';

function AlertPanel({ alerts, onDismiss }) {
  const getAlertClass = (level) => {
    switch (level) {
      case 'error': return 'alert-error';
      case 'warning': return 'alert-warning';
      default: return 'alert-info';
    }
  };

  return (
    <div className="alert-panel">
      {alerts.map(alert => (
        <div key={alert.id} className={`alert ${getAlertClass(alert.level)}`}>
          <div className="alert-content">
            <strong>{alert.name}</strong>: {alert.message}
          </div>
          <button className="alert-dismiss" onClick={() => onDismiss(alert.id)}>
            ×
          </button>
        </div>
      ))}
    </div>
  );
}

export default AlertPanel;