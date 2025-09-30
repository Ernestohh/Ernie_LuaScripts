-- Universal Dashboard Module for RuneScape Scripts
-- Supports both HTTP and file-based communication
local Dashboard = {}
Dashboard.__index = Dashboard

-- Configuration
local DEFAULT_CONFIG = {
    endpoint = "http://localhost:3000",
    mode = "http",  -- "http" or "file"
    enabled = true,
    updateInterval = 5,
    fileDir = "C:\\Users\\ernes\\MemoryError\\Lua_Scripts\\collection\\Dashboard\\server\\data\\"
}

-- JSON encoding
local function encodeJSON(data)
    local function escape(str)
        return str:gsub("\\", "\\\\")
                  :gsub('"', '\\"')
                  :gsub("\n", "\\n")
                  :gsub("\r", "\\r")
                  :gsub("\t", "\\t")
    end

    local function encodeValue(value)
        local valueType = type(value)

        if valueType == "string" then
            return '"' .. escape(value) .. '"'
        elseif valueType == "number" then
            return tostring(value)
        elseif valueType == "boolean" then
            return tostring(value)
        elseif valueType == "nil" then
            return "null"
        elseif valueType == "table" then
            local isArray = true
            local maxIndex = 0

            for k, v in pairs(value) do
                if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                    isArray = false
                    break
                end
                maxIndex = math.max(maxIndex, k)
            end

            if isArray and maxIndex == #value then
                local result = "["
                for i = 1, #value do
                    if i > 1 then result = result .. "," end
                    result = result .. encodeValue(value[i])
                end
                return result .. "]"
            else
                local result = "{"
                local first = true
                for k, v in pairs(value) do
                    if not first then result = result .. "," end
                    result = result .. '"' .. tostring(k) .. '":' .. encodeValue(v)
                    first = false
                end
                return result .. "}"
            end
        end

        return "null"
    end

    return encodeValue(data)
end

-- HTTP sender using VBScript wrapper (no CMD popup)
local function sendHTTP(url, data)
    local jsonData = encodeJSON(data)
    local tempFile = os.getenv("TEMP") .. "\\dashboard_" .. os.time() .. ".json"
    local vbsFile = os.getenv("TEMP") .. "\\dashboard_send_" .. os.time() .. ".vbs"

    -- Write JSON to temp file
    local file = io.open(tempFile, "w")
    if file then
        file:write(jsonData)
        file:close()
    else
        return false
    end

    -- Create VBScript for silent execution
    local vbs = io.open(vbsFile, "w")
    if vbs then
        vbs:write('Set WshShell = CreateObject("WScript.Shell")\n')
        vbs:write('WshShell.Run "cmd /c curl -X POST ""' .. url .. '"" -H ""Content-Type: application/json"" -d @""' .. tempFile .. '"" >nul 2>&1 & del ""' .. tempFile .. '"" & del ""' .. vbsFile .. '""", 0, False\n')
        vbs:close()

        -- Execute VBScript silently
        os.execute('start /b "" "' .. vbsFile .. '"')
        return true
    end

    os.remove(tempFile)
    return false
end

-- File writer for file-based mode
local function writeToFile(filepath, data)
    local jsonData = encodeJSON(data)
    local file = io.open(filepath, "w")
    if file then
        file:write(jsonData)
        file:close()
        return true
    end
    return false
end

-- Constructor
function Dashboard:new()
    local instance = setmetatable({}, Dashboard)
    instance.config = DEFAULT_CONFIG
    instance.initialized = false
    instance.name = ""
    instance.script = ""
    instance.history = {}
    instance.metrics = {}
    instance.lastUpdate = 0
    return instance
end

-- Initialize dashboard
function Dashboard:init(config)
    if not config or not config.name or not config.script then
        error("Dashboard:init requires 'name' and 'script' in config")
    end

    self.name = config.name
    self.script = config.script

    -- Merge config with defaults
    for k, v in pairs(DEFAULT_CONFIG) do
        self.config[k] = config[k] or v
    end

    self.initialized = true
    self.lastUpdate = os.time()

    -- Register with server
    self:_send({
        action = "register",
        name = self.name,
        script = self.script,
        timestamp = os.time()
    })

    return true
end

-- Main update function
function Dashboard:update(state, data)
    if not self.initialized or not self.config.enabled then
        return false
    end

    local updateData = {
        action = "update",
        name = self.name,
        script = self.script,
        state = state or "Unknown",
        data = data or {},
        timestamp = os.time()
    }

    -- Add to history
    table.insert(self.history, {
        state = state,
        timestamp = os.time()
    })

    -- Keep only last 100 history items
    if #self.history > 100 then
        table.remove(self.history, 1)
    end

    -- Merge with stored metrics
    for k, v in pairs(self.metrics) do
        if not updateData.data[k] then
            updateData.data[k] = v
        end
    end

    self.lastUpdate = os.time()
    return self:_send(updateData)
end

-- Update just the state
function Dashboard:setState(state, context)
    local data = context or {}
    return self:update(state, data)
end

-- Update a single metric
function Dashboard:metric(key, value)
    if not self.initialized or not self.config.enabled then
        return false
    end

    self.metrics[key] = value

    -- Send immediate update if more than updateInterval since last
    if os.time() - self.lastUpdate >= self.config.updateInterval then
        return self:update(self.lastState, self.metrics)
    end

    return true
end

-- Send an alert
function Dashboard:alert(message, level)
    if not self.initialized or not self.config.enabled then
        return false
    end

    return self:_send({
        action = "alert",
        name = self.name,
        script = self.script,
        message = message,
        level = level or "info",
        timestamp = os.time()
    })
end

-- Log an event
function Dashboard:event(eventName, eventData)
    if not self.initialized or not self.config.enabled then
        return false
    end

    return self:_send({
        action = "event",
        name = self.name,
        script = self.script,
        event = eventName,
        data = eventData or {},
        timestamp = os.time()
    })
end

-- Track progress
function Dashboard:progress(label, current, total)
    return self:metric(label, {
        current = current,
        total = total,
        percentage = (current / total) * 100
    })
end

-- Timer functions
function Dashboard:startTimer(name)
    self.timers = self.timers or {}
    self.timers[name] = os.time()
end

function Dashboard:endTimer(name)
    if not self.timers or not self.timers[name] then
        return 0
    end

    local elapsed = os.time() - self.timers[name]
    self:metric(name .. "_time", elapsed)
    self.timers[name] = nil
    return elapsed
end

-- Chart data
function Dashboard:chart(name, data)
    return self:metric(name .. "_chart", data)
end

-- Switch communication mode
function Dashboard:setMode(mode)
    if mode == "http" or mode == "file" then
        self.config.mode = mode
        return true
    end
    return false
end

-- Enable/disable dashboard
function Dashboard:setEnabled(enabled)
    self.config.enabled = enabled
end

-- Internal send function
function Dashboard:_send(data)
    if not self.config.enabled then
        return false
    end

    if self.config.mode == "http" then
        local endpoint = self.config.endpoint .. "/api/" .. data.action
        return sendHTTP(endpoint, data)
    else
        local filename = self.config.fileDir .. self.name .. "_" .. self.script .. ".json"

        -- Add history to file data
        data.history = self.history

        return writeToFile(filename, data)
    end
end

-- Create singleton instance
local instance = Dashboard:new()

return instance