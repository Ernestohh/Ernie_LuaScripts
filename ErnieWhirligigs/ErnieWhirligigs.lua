-- Title: ErnieWhirligigs
-- Author: Ernie
-- Description: Catching Whirligigs
-- Version: 1.0
-- Category: Skilling
local API = require("api")

if not CONFIG then
    API.logError("No configuration found! Please configure the script through the Script Manager.")
    API.Write_LoopyLoop(false)
    return
end

local function toBool(value)
    return value == true or value == "true" or value == 1
end

local INITIAL_WHIRLIGIG = CONFIG.initialWhirligig or "Plain whirligig"
local STACKING_WHIRLIGIG = CONFIG.stackingWhirligig or "Plain whirligig"
local INCREASED_STACKING = CONFIG.increasedStackingAmount or false

local WHIRLIGIG_IDS = {28711, 28712, 28713, 28714, 28715, 28716, 28717, 28718, 28719, 28720, 28721, 28722, 28723, 28724, 28725, 28726}
local BUFF_ID = 52770
local MAX_BUFF_STACKS = toBool(INCREASED_STACKING) and 5 or 4

local States = {
    INIT = "INIT",
    HANDLE_CROC = "HANDLE_CROC",
    CHECK_BUFF_STATUS = "CHECK_BUFF_STATUS",
    CATCH_INITIAL = "CATCH_INITIAL",
    CATCH_STACKING_PRE_BUFF = "CATCH_STACKING_PRE_BUFF",
    CATCH_STACKING = "CATCH_STACKING",
    WAIT_BUFF_EXPIRE = "WAIT_BUFF_EXPIRE"
}

local stateMachine = {
    currentState = States.INIT,
    previousState = nil,
    stateHandlers = {},
    stateData = {},
    lastStateChange = os.time(),
    startTime = os.time(),
    afkTimer = os.time(),
    whirligigsCaught = 0,
    plainCaught = false
}

local function sleepTickRandom(sleepticks)
    API.Sleep_tick(sleepticks)
    API.RandomSleep2(100, 300, 0)
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), stateMachine.afkTimer)
    local minIdleMinutes = 5
    local randomTime = math.random((minIdleMinutes * 60) * 0.6, (15 * 60) * 0.9)
    if timeDiff > randomTime then
        API.PIdle2()
        stateMachine.afkTimer = os.time()
    end
end

local function formatElapsedTime(start)
    local currentTime = os.time()
    local elapsedTime = currentTime - start
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("Runtime: %02d:%02d:%02d", hours, minutes, seconds)
end

function stateMachine:transitionTo(newState)
    if self.currentState ~= newState then
        API.logInfo(string.format("[STATE] %s -> %s", self.currentState, newState))
        self.previousState = self.currentState
        self.currentState = newState
        self.stateData = {}
        self.lastStateChange = os.time()
    end
end

function stateMachine:reset()
    API.logInfo("[RESET] Resetting state machine")
    self.stateData = {}
    self.plainCaught = false
    self:transitionTo(States.CHECK_BUFF_STATUS)
end

function stateMachine:execute()
    local handler = self.stateHandlers[self.currentState]
    if handler then
        handler(self)
    else
        API.logError("[ERROR] No handler for state: " .. self.currentState)
    end
end

local function getBuffStatus()
    return API.Buffbar_GetIDstatus(BUFF_ID)
end

local function getBuffCount()
    local buffStatus = getBuffStatus()
    if buffStatus.found then
        return tonumber(buffStatus.text) or 0
    end
    return 0
end

local function findWhirligigs()
    local result = API.GetAllObjArray1(WHIRLIGIG_IDS, 30, {1})
    return result or {}
end

local function findWhirligigByName(name)
    local foundWhirlies = findWhirligigs()
    if not foundWhirlies or #foundWhirlies == 0 then
        return nil
    end

    for i, whirlie in ipairs(foundWhirlies) do
        if whirlie and whirlie.Name == name then
            return whirlie
        end
    end
    return nil
end

local function catchWhirligig(name)
    local whirlie = findWhirligigByName(name)
    if whirlie and whirlie.Id then
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {whirlie.Id}, 30)
        API.logInfo("Catching: " .. name)
        sleepTickRandom(0)
        return true
    end
    API.logWarn("Could not find whirligig: " .. name)
    return false
end

stateMachine.stateHandlers[States.INIT] = function(sm)
    API.logInfo("Initializing Whirligig Catcher...")
    sm.plainCaught = false
    sm.whirligigsCaught = 0

    local foundWhirlies = findWhirligigs()
    local stackingCount = 0

    for i, whirlie in ipairs(foundWhirlies) do
        if whirlie and whirlie.Name == STACKING_WHIRLIGIG then
            stackingCount = stackingCount + 1
        end
    end

    if stackingCount == 0 then
        API.logError("WARNING: No " .. STACKING_WHIRLIGIG .. " found nearby!")
        API.Write_LoopyLoop(false)
    elseif stackingCount < MAX_BUFF_STACKS then
        API.logWarn("WARNING: Only " .. stackingCount .. " " .. STACKING_WHIRLIGIG .. " found, need " .. MAX_BUFF_STACKS .. " for optimal stacking")
    else
        API.logInfo("Found " .. stackingCount .. " " .. STACKING_WHIRLIGIG .. " - sufficient for stacking")
    end

    sm:transitionTo(States.HANDLE_CROC)
end

stateMachine.stateHandlers[States.HANDLE_CROC] = function(sm)
    local chito = API.FindNPCbyName("Chito", 30)
    local frito = API.FindNPCbyName("Frito", 30)

    if not chito and not frito then
        API.logError("No crocs are found")
        API.Write_LoopyLoop(false)
        return
    end

    if chito and chito.Action == "Handle" then
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {chito.Id}, 30)
        API.logInfo("Handling Chito")
        sleepTickRandom(5)
        return
    end

    if frito and frito.Action == "Handle" then
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {frito.Id}, 30)
        API.logInfo("Handling Frito")
        sleepTickRandom(5)
        return
    end

    sm:transitionTo(States.CHECK_BUFF_STATUS)
end

stateMachine.stateHandlers[States.CHECK_BUFF_STATUS] = function(sm)
    local buffStatus = getBuffStatus()
    if not buffStatus.found then
        sm:transitionTo(States.CATCH_INITIAL)
    else
        local buffCount = getBuffCount()
        if buffCount < MAX_BUFF_STACKS then
            sm:transitionTo(States.CATCH_STACKING)
        else
            sm:transitionTo(States.WAIT_BUFF_EXPIRE)
        end
    end
end

stateMachine.stateHandlers[States.CATCH_INITIAL] = function(sm)
    if not sm.plainCaught then
        if catchWhirligig(INITIAL_WHIRLIGIG) then
            sm.plainCaught = true
        end
    end
    sm:transitionTo(States.CATCH_STACKING_PRE_BUFF)
end

stateMachine.stateHandlers[States.CATCH_STACKING_PRE_BUFF] = function(sm)
    local buffStatus = getBuffStatus()
    if buffStatus.found then
        sm:transitionTo(States.CATCH_STACKING)
        return
    end

    catchWhirligig(STACKING_WHIRLIGIG)
    sleepTickRandom(0)
end

stateMachine.stateHandlers[States.CATCH_STACKING] = function(sm)
    local buffStatus = getBuffStatus()

    if not buffStatus.found then
        sm:reset()
        return
    end

    local buffCount = getBuffCount()

    if buffCount < MAX_BUFF_STACKS then
        if catchWhirligig(STACKING_WHIRLIGIG) then
            sleepTickRandom(0)
        end
    else
        sm:transitionTo(States.WAIT_BUFF_EXPIRE)
    end
end

stateMachine.stateHandlers[States.WAIT_BUFF_EXPIRE] = function(sm)
    local buffStatus = getBuffStatus()

    if not buffStatus.found then
        API.logInfo("Buff expired, resetting cycle")
        sm:reset()
    else
        API.logInfo("Waiting for buff to expire... (Stack: " .. getBuffCount() .. ")")
        sleepTickRandom(2)
    end
end

API.logWarn("=== Ernie Whirligigs Started ===")
API.logInfo("Initial Whirligig: " .. INITIAL_WHIRLIGIG)
API.logInfo("Stacking Whirligig: " .. STACKING_WHIRLIGIG)
API.logInfo("Max Buff Stacks: " .. MAX_BUFF_STACKS)
API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)
API.GetTrackedSkills()
while API.Read_LoopyLoop() do
    idleCheck()
    stateMachine:execute()
end

API.logWarn("=== Ernie Whirligigs Stopped ===")
API.logInfo("Total whirligigs caught: " .. stateMachine.whirligigsCaught)
API.logInfo(formatElapsedTime(stateMachine.startTime))
