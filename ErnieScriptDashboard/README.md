# Universal Script Dashboard System

A modern React-based dashboard for monitoring RuneScape scripts with dual communication modes (HTTP and file-based).

## System Architecture

```
Dashboard/
├── server/                 # Node.js/Express backend
│   ├── server.js          # Main server file
│   ├── package.json       # Server dependencies
│   └── data/              # File-based data directory
├── client/                # React frontend
│   ├── src/
│   │   ├── App.js
│   │   ├── components/
│   │   ├── hooks/
│   │   └── styles/
│   └── package.json
├── lua/                   # Lua integration modules
│   ├── dashboard.lua      # Main dashboard module
│   └── examples/          # Example integrations
└── README.md             # This file
```

## Features

- **Real-time Monitoring**: Live updates every 2 seconds
- **Multi-Script Support**: Monitor unlimited scripts simultaneously
- **Dual Communication**: HTTP or file-based data transfer
- **Performance Metrics**: XP tracking, rates, runtime, custom metrics
- **Clean UI**: Modern dark theme with responsive design
- **State History**: Track state transitions over time
- **Alerts**: Configurable alerts for specific conditions

## Quick Start

### 1. Install Backend

```bash
cd Dashboard/server
npm install
npm start
```

Server runs on `http://localhost:3000`

### 2. Install Frontend

```bash
cd Dashboard/client
npm install
npm start
```

React app runs on `http://localhost:3001`

### 3. Integrate with Lua Script

```lua
-- At the top of your script
local Dashboard = require("dashboard")

-- Initialize with your script info
Dashboard:init({
    name = "YourCharacterName",
    script = "YourScriptName",
    mode = "http",  -- or "file" for file-based
    endpoint = "http://localhost:3000"  -- optional, this is default
})

-- Update throughout your script
Dashboard:update("Banking", {
    itemsCollected = 150,
    xpGained = 12500,
    runtime = os.time() - startTime
})

-- Custom metrics
Dashboard:metric("efficiency", 95.5)
Dashboard:metric("profit", 1250000)

-- State transitions
Dashboard:setState("Crafting runes")

-- Alerts
Dashboard:alert("Out of essence!", "warning")
```

## Lua Integration Guide

### Basic Setup

```lua
local Dashboard = require("dashboard")

-- Configuration options
local config = {
    name = "MainCharacter",      -- Required: Character name
    script = "AutoMining",       -- Required: Script name
    mode = "http",               -- Optional: "http" or "file" (default: "http")
    endpoint = "http://localhost:3000", -- Optional: Server URL
    updateInterval = 5,          -- Optional: Seconds between auto-updates
    enabled = true              -- Optional: Enable/disable dashboard
}

Dashboard:init(config)
```

### State Management

```lua
-- Simple state update
Dashboard:setState("Mining iron ore")

-- State with context
Dashboard:setState("Banking", {
    location = "Varrock West",
    preset = 1
})

-- State transitions are automatically tracked
Dashboard:setState("Walking to mine")  -- Transition recorded
```

### Metrics and Data

```lua
-- Update multiple metrics at once
Dashboard:update("Current State", {
    oresMinied = 1250,
    xpGained = 45000,
    xpPerHour = calculateXpPerHour(),
    profit = calculateProfit(),
    efficiency = getMiningEfficiency()
})

-- Update single metric
Dashboard:metric("playerHealth", API.GetHP_())

-- Track events
Dashboard:event("levelUp", {
    skill = "Mining",
    newLevel = 85
})
```

### Advanced Features

```lua
-- Track performance over time
Dashboard:startTimer("bankRun")
-- ... do bank run ...
Dashboard:endTimer("bankRun")  -- Automatically tracks average times

-- Conditional alerts
if inventoryFull and noEssence then
    Dashboard:alert("Out of supplies!", "error")
end

-- Progress tracking
Dashboard:progress("Daily Goal", current, target)

-- Custom data visualization
Dashboard:chart("xpTrend", {
    labels = {"1h", "2h", "3h"},
    data = {15000, 30000, 42000}
})
```

## Communication Modes

### HTTP Mode (Recommended)

**Pros:**
- Real-time updates
- No file I/O overhead
- Works across network
- Clean data flow

**Cons:**
- May show CMD windows on Windows (use VBS wrapper to avoid)
- Requires server running

### File Mode

**Pros:**
- No network dependencies
- No CMD popups
- Works offline
- Simple setup

**Cons:**
- Slight delay in updates
- File locking potential
- Local only

### Switching Modes

```lua
-- Start with HTTP
Dashboard:init({
    name = "Character",
    script = "Script",
    mode = "http"
})

-- Switch to file mode if needed
Dashboard:setMode("file")

-- Switch back
Dashboard:setMode("http")
```

## React Dashboard Features

### Components

1. **Sidebar Navigation**
   - Character/script list
   - Quick filters
   - Connection status

2. **Main Dashboard**
   - Current state display
   - Live metrics grid
   - Performance graphs
   - Alert notifications

3. **Detail Views**
   - State history timeline
   - Detailed metrics
   - Custom data displays
   - Log viewer

### Customization

The React dashboard can be customized via `client/src/config.js`:

```javascript
export const config = {
    updateInterval: 2000,        // ms between updates
    theme: 'dark',              // 'dark' or 'light'
    layout: 'grid',             // 'grid' or 'list'
    metrics: {
        showGraphs: true,
        graphHistory: 100,       // data points to keep
        alertThresholds: {
            xpPerHour: 10000,    // Alert if below
            efficiency: 80       // Alert if below
        }
    }
};
```

## API Reference

### Dashboard Module

#### `Dashboard:init(config)`
Initialize the dashboard connection.

**Parameters:**
- `config` (table): Configuration object
  - `name` (string, required): Character name
  - `script` (string, required): Script name
  - `mode` (string): "http" or "file" (default: "http")
  - `endpoint` (string): Server URL (default: "http://localhost:3000")
  - `enabled` (boolean): Enable dashboard (default: true)

#### `Dashboard:update(state, data)`
Send a complete update.

**Parameters:**
- `state` (string): Current state description
- `data` (table): Metrics and data to send

#### `Dashboard:setState(state, context)`
Update only the current state.

**Parameters:**
- `state` (string): New state
- `context` (table, optional): Additional context

#### `Dashboard:metric(key, value)`
Update a single metric.

**Parameters:**
- `key` (string): Metric name
- `value` (any): Metric value

#### `Dashboard:alert(message, level)`
Send an alert to dashboard.

**Parameters:**
- `message` (string): Alert message
- `level` (string): "info", "warning", or "error"

#### `Dashboard:event(name, data)`
Log an event.

**Parameters:**
- `name` (string): Event name
- `data` (table): Event data

#### `Dashboard:setMode(mode)`
Switch communication mode.

**Parameters:**
- `mode` (string): "http" or "file"

## Server API Endpoints

### `POST /api/register`
Register a new script instance.

**Body:**
```json
{
    "name": "CharacterName",
    "script": "ScriptName",
    "timestamp": 1234567890
}
```

### `POST /api/update`
Update script data.

**Body:**
```json
{
    "name": "CharacterName",
    "script": "ScriptName",
    "state": "Current State",
    "data": {
        "metric1": 100,
        "metric2": "value"
    },
    "timestamp": 1234567890
}
```

### `GET /api/scripts`
Get all active scripts data.

**Response:**
```json
{
    "CharacterName": {
        "script": "ScriptName",
        "state": "Current State",
        "data": {...},
        "lastUpdate": 1234567890,
        "history": [...]
    }
}
```

### `POST /api/alert`
Send an alert.

**Body:**
```json
{
    "name": "CharacterName",
    "script": "ScriptName",
    "message": "Alert message",
    "level": "warning",
    "timestamp": 1234567890
}
```

### `DELETE /api/scripts/:name`
Remove a script from tracking.

## File-Based Communication

When using file mode, data is written to:
```
Dashboard/server/data/{CharacterName}_{ScriptName}.json
```

**File Format:**
```json
{
    "name": "CharacterName",
    "script": "ScriptName",
    "state": "Current State",
    "data": {
        "metric1": 100,
        "metric2": "value"
    },
    "timestamp": 1234567890,
    "history": [
        {
            "state": "Previous State",
            "timestamp": 1234567880
        }
    ]
}
```

The server watches this directory and automatically loads updates.

## Troubleshooting

### CMD Popups on Windows

If you see CMD windows when using HTTP mode:

1. The dashboard module includes a VBS wrapper that should prevent this
2. If still occurring, switch to file mode: `Dashboard:setMode("file")`
3. Check antivirus isn't blocking the VBS execution

### Server Connection Issues

1. Ensure server is running: `npm start` in server directory
2. Check firewall isn't blocking port 3000
3. Verify endpoint URL in Lua config

### File Mode Not Updating

1. Check file permissions in `Dashboard/server/data/`
2. Ensure no antivirus is blocking file writes
3. Verify the server's file watcher is running

### React App Not Showing Data

1. Check browser console for errors
2. Verify server is accessible at configured endpoint
3. Ensure CORS is properly configured in server

## Examples

### Mining Script Integration

```lua
local Dashboard = require("dashboard")
local API = require("api")

-- Initialize
Dashboard:init({
    name = API.GetPlayerName(),
    script = "AutoMining",
    mode = "http"
})

local startTime = os.time()
local oresMinied = 0

-- Main loop
while API.Read_LoopyLoop() do
    local currentState = determineState()

    Dashboard:update(currentState, {
        oresMinied = oresMinied,
        runtime = os.time() - startTime,
        xpGained = API.GetXP("Mining") - startXP,
        location = API.GetLocation()
    })

    -- State-specific updates
    if currentState == "Mining" then
        Dashboard:metric("rockHealth", getRockHealth())
    elseif currentState == "Banking" then
        Dashboard:metric("bankTrips", bankTrips)
    end

    API.Sleep_tick(1)
end
```

### Combat Script Integration

```lua
local Dashboard = require("dashboard")

Dashboard:init({
    name = "CombatBot",
    script = "AutoSlayer",
    mode = "file"  -- Use file mode for combat (less overhead)
})

-- Track combat stats
function onKill(npc)
    Dashboard:event("kill", {
        npc = npc.name,
        loot = getLoot(),
        xp = getXPDrop()
    })

    Dashboard:metric("killCount", kills)
    Dashboard:metric("killsPerHour", calculateKPH())
end

-- Track health
function onLoop()
    local hp = API.GetHP_()
    if hp < 50 then
        Dashboard:alert("Low health!", "warning")
    end

    Dashboard:update(getCurrentTask(), {
        health = hp,
        prayer = API.GetPrayer_(),
        kills = killCount,
        taskRemaining = getTaskRemaining()
    })
end
```

## Contributing

Contributions are welcome! Please ensure any new features:
1. Work with both HTTP and file modes
2. Include proper error handling
3. Are documented in this README
4. Include example usage

## License

MIT License - Use freely in your scripts!