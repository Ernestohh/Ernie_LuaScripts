const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const chokidar = require('chokidar');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Data storage
const scriptData = {};
const alerts = [];
const events = [];

// File watching directory
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

// Watch for file changes
const watcher = chokidar.watch(dataDir, {
    persistent: true,
    ignoreInitial: false
});

watcher.on('change', (filepath) => {
    const filename = path.basename(filepath);
    if (filename.endsWith('.json')) {
        try {
            const data = fs.readFileSync(filepath, 'utf8');
            const parsed = JSON.parse(data);
            const key = parsed.name;

            scriptData[key] = {
                ...parsed,
                lastUpdate: Date.now(),
                source: 'file'
            };
        } catch (err) {
            console.error(`Error reading file ${filename}:`, err);
        }
    }
});

// API Routes

// Register a new script
app.post('/api/register', (req, res) => {
    const { name, script, timestamp } = req.body;

    if (!name || !script) {
        return res.status(400).json({ error: 'Name and script required' });
    }

    scriptData[name] = {
        name,
        script,
        state: 'Initializing',
        data: {},
        registeredAt: timestamp || Date.now(),
        lastUpdate: Date.now(),
        history: [],
        source: 'http'
    };

    res.json({ success: true, message: 'Registered successfully' });
});

// Update script data
app.post('/api/update', (req, res) => {
    const { name, script, state, data, timestamp } = req.body;

    if (!name) {
        return res.status(400).json({ error: 'Name required' });
    }

    if (!scriptData[name]) {
        scriptData[name] = {
            name,
            script,
            registeredAt: Date.now(),
            history: []
        };
    }

    // Update data
    scriptData[name] = {
        ...scriptData[name],
        state: state || scriptData[name].state,
        data: { ...scriptData[name].data, ...data },
        lastUpdate: timestamp || Date.now(),
        source: 'http'
    };

    // Add to history
    if (state) {
        scriptData[name].history.push({
            state,
            timestamp: timestamp || Date.now()
        });

        // Keep only last 100 history items
        if (scriptData[name].history.length > 100) {
            scriptData[name].history.shift();
        }
    }

    res.json({ success: true });
});

// Send an alert
app.post('/api/alert', (req, res) => {
    const { name, script, message, level, timestamp } = req.body;

    const alert = {
        id: Date.now(),
        name,
        script,
        message,
        level: level || 'info',
        timestamp: timestamp || Date.now(),
        read: false
    };

    alerts.push(alert);

    // Keep only last 50 alerts
    if (alerts.length > 50) {
        alerts.shift();
    }

    res.json({ success: true, id: alert.id });
});

// Log an event
app.post('/api/event', (req, res) => {
    const { name, script, event, data, timestamp } = req.body;

    const eventEntry = {
        id: Date.now(),
        name,
        script,
        event,
        data,
        timestamp: timestamp || Date.now()
    };

    events.push(eventEntry);

    // Keep only last 200 events
    if (events.length > 200) {
        events.shift();
    }

    res.json({ success: true, id: eventEntry.id });
});

// Get all script data
app.get('/api/scripts', (req, res) => {
    res.json(scriptData);
});

// Get specific script data
app.get('/api/scripts/:name', (req, res) => {
    const { name } = req.params;

    if (!scriptData[name]) {
        return res.status(404).json({ error: 'Script not found' });
    }

    res.json(scriptData[name]);
});

// Get alerts
app.get('/api/alerts', (req, res) => {
    const { unread } = req.query;

    if (unread === 'true') {
        res.json(alerts.filter(a => !a.read));
    } else {
        res.json(alerts);
    }
});

// Mark alert as read
app.patch('/api/alerts/:id', (req, res) => {
    const { id } = req.params;
    const alert = alerts.find(a => a.id === parseInt(id));

    if (!alert) {
        return res.status(404).json({ error: 'Alert not found' });
    }

    alert.read = true;
    res.json({ success: true });
});

// Get events
app.get('/api/events', (req, res) => {
    const { name, limit } = req.query;

    let filtered = events;

    if (name) {
        filtered = filtered.filter(e => e.name === name);
    }

    if (limit) {
        filtered = filtered.slice(-parseInt(limit));
    }

    res.json(filtered);
});

// Delete script data
app.delete('/api/scripts/:name', (req, res) => {
    const { name } = req.params;

    if (scriptData[name]) {
        delete scriptData[name];

        // Also delete file if exists
        const filepath = path.join(dataDir, `${name}_*.json`);
        const files = fs.readdirSync(dataDir).filter(f => f.startsWith(`${name}_`));
        files.forEach(f => {
            fs.unlinkSync(path.join(dataDir, f));
        });

        res.json({ success: true });
    } else {
        res.status(404).json({ error: 'Script not found' });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        activeScripts: Object.keys(scriptData).length,
        alerts: alerts.length,
        events: events.length,
        uptime: process.uptime()
    });
});

// Clean up stale data (no update in 30 minutes)
setInterval(() => {
    const now = Date.now();
    const staleTime = 30 * 60 * 1000; // 30 minutes

    Object.keys(scriptData).forEach(key => {
        if (now - scriptData[key].lastUpdate > staleTime) {
            console.log(`Removing stale script: ${key}`);
            delete scriptData[key];
        }
    });
}, 60000); // Check every minute

app.listen(PORT, () => {
    console.log(`Dashboard server running on http://localhost:${PORT}`);
    console.log(`Watching for file updates in: ${dataDir}`);
});