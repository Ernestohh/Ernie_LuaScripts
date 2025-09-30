import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Dashboard from './components/Dashboard';
import Sidebar from './components/Sidebar';
import AlertPanel from './components/AlertPanel';
import './styles/App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

function App() {
  const [scripts, setScripts] = useState({});
  const [selectedScript, setSelectedScript] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const [connectionStatus, setConnectionStatus] = useState('connecting');

  // Fetch script data
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [scriptsRes, alertsRes] = await Promise.all([
          axios.get(`${API_URL}/api/scripts`),
          axios.get(`${API_URL}/api/alerts?unread=true`)
        ]);

        setScripts(scriptsRes.data);
        setAlerts(alertsRes.data);
        setConnectionStatus('connected');

        // Auto-select first script if none selected
        if (!selectedScript && Object.keys(scriptsRes.data).length > 0) {
          setSelectedScript(Object.keys(scriptsRes.data)[0]);
        }
      } catch (error) {
        console.error('Failed to fetch data:', error);
        setConnectionStatus('error');
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 2000); // Update every 2 seconds

    return () => clearInterval(interval);
  }, [selectedScript]);

  // Mark alert as read
  const markAlertRead = async (alertId) => {
    try {
      await axios.patch(`${API_URL}/api/alerts/${alertId}`);
      setAlerts(alerts.filter(a => a.id !== alertId));
    } catch (error) {
      console.error('Failed to mark alert as read:', error);
    }
  };

  // Remove script
  const removeScript = async (name) => {
    try {
      await axios.delete(`${API_URL}/api/scripts/${name}`);
      if (selectedScript === name) {
        setSelectedScript(null);
      }
    } catch (error) {
      console.error('Failed to remove script:', error);
    }
  };

  return (
    <div className="app">
      <Sidebar
        scripts={scripts}
        selectedScript={selectedScript}
        onSelectScript={setSelectedScript}
        onRemoveScript={removeScript}
        connectionStatus={connectionStatus}
      />

      <div className="main-content">
        {alerts.length > 0 && (
          <AlertPanel
            alerts={alerts}
            onDismiss={markAlertRead}
          />
        )}

        {selectedScript && scripts[selectedScript] ? (
          <Dashboard
            script={scripts[selectedScript]}
            onRemove={() => removeScript(selectedScript)}
          />
        ) : (
          <div className="no-script-selected">
            <h2>No Script Selected</h2>
            <p>Select a script from the sidebar or wait for scripts to connect.</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;