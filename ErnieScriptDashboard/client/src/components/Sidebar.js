import React from 'react';
import '../styles/Sidebar.css';

function Sidebar({ scripts, selectedScript, onSelectScript, onRemoveScript, connectionStatus }) {
  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'connected': return '#4caf50';
      case 'error': return '#f44336';
      default: return '#ff9800';
    }
  };

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h2>Script Dashboard</h2>
        <div className="connection-status">
          <span
            className="status-dot"
            style={{ background: getStatusColor() }}
          />
          <span>{connectionStatus}</span>
        </div>
      </div>

      <div className="script-list">
        <h3>Active Scripts</h3>
        {Object.keys(scripts).length === 0 ? (
          <div className="no-scripts">No active scripts</div>
        ) : (
          Object.entries(scripts).map(([name, data]) => (
            <div
              key={name}
              className={`script-item ${selectedScript === name ? 'active' : ''}`}
              onClick={() => onSelectScript(name)}
            >
              <div className="script-info">
                <div className="script-name">{name}</div>
                <div className="script-type">{data.script}</div>
                <div className="script-state">{data.state}</div>
              </div>
              {selectedScript === name && (
                <button
                  className="remove-script"
                  onClick={(e) => {
                    e.stopPropagation();
                    onRemoveScript(name);
                  }}
                >
                  ×
                </button>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default Sidebar;