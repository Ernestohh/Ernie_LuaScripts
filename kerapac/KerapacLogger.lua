local API = require("api")

local KerapacLogger = {
    levels = {
        DEBUG = "DEBUG",
        INFO = "INFO",
        WARN = "WARN",
        ERROR = "ERROR"
    },
    currentLevel = "INFO",
    includeTimestamp = true,
    debugMode = false
}

function KerapacLogger:SetLevel(level)
    if self.levels[level] then
        self.currentLevel = level
        self:Info("Log level set to " .. level)
    else
        self:Error("Invalid log level: " .. tostring(level))
    end
end

function KerapacLogger:SetDebugMode(enabled)
    self.debugMode = enabled
    if enabled then
        self:SetLevel("DEBUG")
    else
        self:SetLevel("INFO")
    end
    self:Info("Debug mode " .. (enabled and "enabled" or "disabled"))
end

function KerapacLogger:FormatMessage(level, message)
    local timestamp = ""
    if self.includeTimestamp then
        timestamp = "[" .. os.date("%H:%M:%S") .. "] "
    end
    return timestamp .. "[" .. level .. "] " .. message
end

function KerapacLogger:Debug(message)
    if self.currentLevel == self.levels.DEBUG then
        local formattedMessage = self:FormatMessage(self.levels.DEBUG, message)
        print(formattedMessage)
        API.Log(formattedMessage, "debug")
    end
end

function KerapacLogger:Info(message)
    if self.currentLevel == self.levels.DEBUG or 
       self.currentLevel == self.levels.INFO then
        local formattedMessage = self:FormatMessage(self.levels.INFO, message)
        print(formattedMessage)
        API.Log(formattedMessage, "info")
    end
end

function KerapacLogger:Warn(message)
    if self.currentLevel ~= self.levels.ERROR then
        local formattedMessage = self:FormatMessage(self.levels.WARN, message)
        print(formattedMessage)
        API.Log(formattedMessage, "warn")
    end
end

function KerapacLogger:Error(message)
    local formattedMessage = self:FormatMessage(self.levels.ERROR, message)
    print(formattedMessage)
    API.Log(formattedMessage, "error")
end

function KerapacLogger:Clear()
    API.ClearLog()
    self:Info("Log cleared")
end

return KerapacLogger