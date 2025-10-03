-- Title: AutoRunecraft
-- Author: Ernie
-- Description: Wildy/Um RC
-- Version: 2.0
-- Category: Skilling
local API = require("api")

if not CONFIG then
    API.logError("No configuration found! Please configure the script through the Script Manager.")
    API.Write_LoopyLoop(false)
    return
end
if not API.IsCacheLoaded() then
    Logger:Error("Cache not found at right location. Redownload cache or adjust cache location in settings.json")
    API.Write_LoopyLoop(false)
end

local function toBool(value)
    return value == true or value == "true" or value == 1
end

local RUNE_TYPE = CONFIG.runeType or "air"
local TELEPORT_METHOD = CONFIG.teleportMethod or "War's Retreat Teleport"
local MAX_IDLE_TIME_MINUTES = 10

local WILDERNESS_RUNES = {
    air = true, water = true, earth = true, fire = true,
    mind = true, body = true, nature = true, astral = true,
    cosmic = true, blood = true, chaos = true, law = true,
    death = true, soul = true, time = true
}
local IS_WILDERNESS = WILDERNESS_RUNES[RUNE_TYPE] or false

local RUNE_ALTAR_IDS = {
    miasma = 127383,
    flesh = 127382,
    bone = 127381,
    spirit = 127380,
    air = 2478,
    water = 2480,
    earth = 2481,
    fire = 2482,
    mind = 2479,
    body = 2483,
    nature = 2486,
    astral = 17010,
    cosmic = 2484,
    blood = 30624,
    chaos = 2487,
    law = 2485,
    death = 2488,
    soul = 109429,
    time = 132584
}

local PURE_ESSENCE_ID = IS_WILDERNESS and 7936 or 55667
local PORTAL_ID = 127376
local BANK_CHEST_ID = 114750
local WARS_BANK_CHEST_ID = 114750
local DEEP_SEA_BANK_CHEST_ID = 110591
local ALTAR_OF_WAR_ID = 114748
local ABYSSAL_POUCH = {12037, 12035, 12796}
local RUNIC_ATTUNER = 57519
local RUNIC_BUFF_IDS = {554,555,556,557,558,559,560,561,562,563,564,565,566,9075,58450,13649}
local INFINITY_ETHEREAL_OUTFIT = {32357,32581, 32582, 32360, 32361}
local LAW_ETHEREAL_OUTFIT = {32342,32575,32576,32345,32346}
local DEATH_ETHEREAL_OUTFIT = {32352,32579,32580,32355,32356}
local BLOOD_ETHEREAL_OUTFIT = {32347,32577,32578,32350,32351}
local POUCHES = {5509, 5510, 5512, 5514, 24205, 58453}
local BINDING_ROD = {58896, 58899}
local POWERBURST_OF_SORCERY = {49063,49065,49067,49069}
local essenceCount = nil
local braceletAB = nil
local warsTeleportAB = nil
local deepSeaTeleportAB = nil
local surgeAB = nil
local wildernessSwordAB = nil
local bindingRodAB = nil
local powerburstOfSorceryAB = nil
local runicAttunerAB = nil

local States = {
    INIT = "INIT",
    USE_BRACELET = "USE_BRACELET",
    CHOOSE_PORTAL_OPTION = "CHOOSE_PORTAL_OPTION",
    ENTER_PORTAL = "ENTER_PORTAL",
    CHECK_RUNIC_ATTUNER = "CHECK_RUNIC_ATTUNER",
    USE_RUNIC_TELEPORT = "USE_RUNIC_TELEPORT",
    USE_WILDERNESS_SWORD = "USE_WILDERNESS_SWORD",
    INTERACT_WILDERNESS_WALL = "INTERACT_WILDERNESS_WALL",
    TELEPORT_WITH_MAGE = "TELEPORT_WITH_MAGE",
    ENTER_RIFT = "ENTER_RIFT",
    APPROACH_ALTAR = "APPROACH_ALTAR",
    CRAFT_RUNES = "CRAFT_RUNES",
    REFRESH_FAMILIAR = "REFRESH_FAMILIAR",
    TELEPORT_TO_BANK = "TELEPORT_TO_BANK",
    BANKING = "BANKING",
    COMPLETE = "COMPLETE"
}

local ernieRuneCrafter = {
    currentState = States.INIT,
    previousState = nil,
    runesCrafted = 0,
    tripCounter = 0,
    runeBreakdown = {},
    magicalThreadCrafted = 0,
    firstBankCompleted = false,
    stateHandlers = {},
    stateData = {},
    lastStateChange = os.time(),
    startTime = os.time(),
    afkTimer = os.time(),
    startExp = 0,
    currentExp = 0,
    soulChargerTotalCharges = 0,
    lastExpUpdate = os.time(),
    lastExpGained = 0,
    cachedExpPerHour = 0,
    cachedRunesPerHour = 0
}

local function sleepTickRandom(sleepticks)
    API.Sleep_tick(sleepticks)
    API.RandomSleep2(1, 240, 0)
end

local function hasBindingRod()
    for _, rodId in ipairs(BINDING_ROD) do
        if Inventory:Contains(rodId) then
            return true
        end
    end
    return false
end

local function isCompleteOutfitWorn(outfit)
    local slots = {0, 4, 6, 7, 8}
    local slotNames = {"Head", "Body", "Legs", "Hands", "Feet"}

    for i, slot in ipairs(slots) do
        local isEquipped = API.EquipSlotEq1(slot, outfit[i])

        if not isEquipped then
            return false
        end
    end
    return true
end

local function getPouchesInInventory()
    local foundPouches = {}

    if Inventory:Contains(58453) then
        table.insert(foundPouches, 58453)
        return foundPouches
    end

    for _, pouchId in ipairs(POUCHES) do
        if pouchId ~= 58453 and Inventory:Contains(pouchId) then
            table.insert(foundPouches, pouchId)
        end
    end

    return foundPouches
end

local function calculateEssenceCapacity()
    local capacity = Inventory:InvItemcount(7936)
    local pouches = getPouchesInInventory()
    local pouchSlots = #pouches

    if isCompleteOutfitWorn(INFINITY_ETHEREAL_OUTFIT) then
        capacity = capacity + 12
    elseif isCompleteOutfitWorn(LAW_ETHEREAL_OUTFIT) or
           isCompleteOutfitWorn(DEATH_ETHEREAL_OUTFIT) or
           isCompleteOutfitWorn(BLOOD_ETHEREAL_OUTFIT) then
        capacity = capacity + 6
    end

    for _, pouchId in ipairs(pouches) do
        if pouchId == 5509 then
            capacity = capacity + 3
        elseif pouchId == 5510 then
            capacity = capacity + 6
        elseif pouchId == 5512 then
            capacity = capacity + 9
        elseif pouchId == 5514 then
            capacity = capacity + 12
        elseif pouchId == 24205 then
            capacity = capacity + 18
        elseif pouchId == 58453 then
            capacity = capacity + 70
        end
    end

    local buffStatus = API.Buffbar_GetIDstatus(26095)
    if buffStatus.found then
        if toBool(CONFIG.hasAbyssalTitan) then
            capacity = capacity + 20
        elseif toBool(CONFIG.hasAbyssalLurker) then
            capacity = capacity + 12
        elseif toBool(CONFIG.hasAbyssalParasite) then
            capacity = capacity + 7
        end
    end

    return capacity
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), ernieRuneCrafter.afkTimer)
    local minIdleMinutes = 5
    local randomTime = math.random((minIdleMinutes * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)
    if timeDiff > randomTime then
        API.PIdle2()
        ernieRuneCrafter.afkTimer = os.time()
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

local function updateExpTracking()
    local xpEvents = API.GatherEvents_xp_check()
    if #xpEvents > 0 then
        for _, event in ipairs(xpEvents) do
            if event.skillIndex == 20 then
                if ernieRuneCrafter.startExp == 0 then
                    ernieRuneCrafter.startExp = event.exp
                    ernieRuneCrafter.currentExp = event.exp
                    API.logInfo("Initial Runecrafting XP: " .. event.exp)
                else
                    ernieRuneCrafter.currentExp = event.exp
                end
                break
            end
        end
    end

    if ernieRuneCrafter.startExp == 0 then
        local currentRcXp = API.GetSkillXP("RUNECRAFTING")
        if currentRcXp and currentRcXp > 0 then
            ernieRuneCrafter.startExp = currentRcXp
            ernieRuneCrafter.currentExp = currentRcXp
            API.logInfo("Initial Runecrafting XP from skill query: " .. currentRcXp)
        end
    end
end

local function calculateExpPerHour()
    local currentTime = os.time()
    local timeSinceUpdate = os.difftime(currentTime, ernieRuneCrafter.lastExpUpdate)
    local expGained = ernieRuneCrafter.currentExp - ernieRuneCrafter.startExp

    if timeSinceUpdate >= 5 or expGained ~= ernieRuneCrafter.lastExpGained then
        local timeElapsed = os.difftime(currentTime, ernieRuneCrafter.startTime) / 3600

        if timeElapsed > 0 then
            ernieRuneCrafter.cachedExpPerHour = math.floor(expGained / timeElapsed)
        else
            ernieRuneCrafter.cachedExpPerHour = 0
        end

        ernieRuneCrafter.lastExpUpdate = currentTime
        ernieRuneCrafter.lastExpGained = expGained
    end

    return ernieRuneCrafter.cachedExpPerHour
end

local function calculateRunesPerHour()
    local timeElapsed = os.difftime(os.time(), ernieRuneCrafter.startTime) / 3600
    if timeElapsed > 0 then
        return math.floor(ernieRuneCrafter.runesCrafted / timeElapsed)
    end
    return 0
end

local function calculateMagicalThreadPerHour()
    local timeElapsed = os.difftime(os.time(), ernieRuneCrafter.startTime) / 3600
    if timeElapsed > 0 then
        return math.floor(ernieRuneCrafter.magicalThreadCrafted / timeElapsed)
    end
    return 0
end

local function calculateTripsPerHour()
    local timeElapsed = os.difftime(os.time(), ernieRuneCrafter.startTime) / 3600
    if timeElapsed > 0 then
        return math.floor(ernieRuneCrafter.tripCounter / timeElapsed)
    end
    return 0
end

local RUNE_NAMES = {
    "Air rune", "Water rune", "Earth rune", "Fire rune", "Mind rune", "Body rune",
    "Cosmic rune", "Chaos rune", "Nature rune", "Law rune", "Death rune",
    "Astral rune", "Blood rune", "Soul rune", "Time rune",
    "Miasma rune", "Flesh rune", "Bone rune", "Spirit rune"
}

local function updateRuneBreakdown()
    local totalRunes = 0
    local breakdown = {}

    for _, runeName in ipairs(RUNE_NAMES) do
        local count = Inventory:InvItemcountStack_Strings(runeName)
        if count > 0 then
            breakdown[runeName] = (ernieRuneCrafter.runeBreakdown[runeName] or 0) + count
            totalRunes = totalRunes + count
        end
    end

    if totalRunes > 0 then
        for runeName, count in pairs(breakdown) do
            ernieRuneCrafter.runeBreakdown[runeName] = count
        end
        ernieRuneCrafter.runesCrafted = 0
        for _, count in pairs(ernieRuneCrafter.runeBreakdown) do
            ernieRuneCrafter.runesCrafted = ernieRuneCrafter.runesCrafted + count
        end
    end

    local threadCount = Inventory:InvItemcountStack_Strings("Magical thread")
    if threadCount > 0 then
        ernieRuneCrafter.magicalThreadCrafted = ernieRuneCrafter.magicalThreadCrafted + threadCount
    end
end

local function trackingData()
    local data = {
        { "Ernie's Auto Runecraft", "Version: 2.0" },
        { "-------", "-------" },
        { "Runtime:", API.ScriptRuntimeString() },
        { "- Trips Completed", ernieRuneCrafter.tripCounter },
        { "- Trips/Hour", calculateTripsPerHour() },
        { "- Primary Rune Type", (RUNE_TYPE:gsub("^%l", string.upper)) },
        { "- Essence Capacity", essenceCount or "N/A" },
        { "- XP Gained", (ernieRuneCrafter.currentExp - ernieRuneCrafter.startExp) },
        { "- XP/Hour", calculateExpPerHour() },
        { "- Current State", ernieRuneCrafter.currentState },
        { "-------", "-------" },
        { "TOTAL RUNES CRAFTED", ernieRuneCrafter.runesCrafted },
        { "- Runes/Hour", calculateRunesPerHour() }
    }

    local sortedRunes = {}
    for runeName, count in pairs(ernieRuneCrafter.runeBreakdown) do
        table.insert(sortedRunes, {name = runeName, count = count})
    end

    table.sort(sortedRunes, function(a, b) return a.count > b.count end)

    for _, runeData in ipairs(sortedRunes) do
        table.insert(data, { "  - " .. runeData.name, runeData.count })
    end

    table.insert(data, { "-------", "-------" })
    table.insert(data, { "MAGICAL THREAD", ernieRuneCrafter.magicalThreadCrafted })
    table.insert(data, { "- Thread/Hour", calculateMagicalThreadPerHour() })
    table.insert(data, { "-------", "-------" })

    API.DrawTable(data)
end

function ernieRuneCrafter:transitionTo(newState)
    if self.currentState ~= newState then
        API.logInfo(string.format("[STATE] %s -> %s", self.currentState, newState))
        self.previousState = self.currentState
        self.currentState = newState
        self.stateData = {}
        self.lastStateChange = os.time()
    end
end

function ernieRuneCrafter:reset()
    API.logInfo("[RESET] Resetting state machine")
    self.stateData = {}
    self:transitionTo(States.INIT)
end

function ernieRuneCrafter:execute()
    local handler = self.stateHandlers[self.currentState]
    if handler then
        handler(self)
    else
        API.logError("[ERROR] No handler for state: " .. self.currentState)
    end
end

ernieRuneCrafter.stateHandlers[States.INIT] = function(erc)
    API.logInfo("Initializing runecrafting bot...")
    API.logInfo("Using rune type: " .. RUNE_TYPE)
    API.logInfo("Workflow: " .. (IS_WILDERNESS and "Wilderness" or "Necromancy"))
    API.logInfo("Teleport method: " .. TELEPORT_METHOD)

    if TELEPORT_METHOD == "War's Retreat Teleport" then
        warsTeleportAB = API.GetABs_name1("War's Retreat Teleport")
        if not warsTeleportAB or warsTeleportAB.id <= 0 then
            API.logError("War's Retreat Teleport ability not found!")
            erc:transitionTo(States.COMPLETE)
            return
        end
        BANK_CHEST_ID = WARS_BANK_CHEST_ID
    elseif TELEPORT_METHOD == "GotE Deep Sea Fishing Hub" then
        deepSeaTeleportAB = API.GetABs_name1("Grace of the Elves")
        if not deepSeaTeleportAB or deepSeaTeleportAB.id <= 0 then
            API.logError("Deep Sea Fishing hub teleport not found! (Grace of the Elves required)")
            erc:transitionTo(States.COMPLETE)
            return
        end
        BANK_CHEST_ID = DEEP_SEA_BANK_CHEST_ID
    end

    if IS_WILDERNESS then
        wildernessSwordAB = API.GetABs_name1("Wilderness sword")
        if not wildernessSwordAB or wildernessSwordAB.id <= 0 then
            API.logError("Wilderness sword not found in inventory or abilities!")
            erc:transitionTo(States.COMPLETE)
            return
        end
    else
        braceletAB = API.GetABs_name1("Passing bracelet")
        if not braceletAB or braceletAB.id <= 0 then
            API.logError("Passing bracelet ability not found!")
            erc:transitionTo(States.COMPLETE)
            return
        end
    end

    if Inventory:Contains(PURE_ESSENCE_ID) then
        erc:transitionTo(States.REFRESH_FAMILIAR)
    else
        erc:transitionTo(States.TELEPORT_TO_BANK)
    end
end

ernieRuneCrafter.stateHandlers[States.USE_BRACELET] = function(erc)
    if not erc.stateData.usedBracelet then
        API.logInfo("Using Passing bracelet...")
        API.DoAction_Ability_Direct(braceletAB, 1, API.OFF_ACT_GeneralInterface_route)
        erc.stateData.usedBracelet = true
        sleepTickRandom(2)
    end

    local interface = API.ScanForInterfaceTest2Get(false, {{720, 2, -1, 0}, {720, 16, -1, 0}, {720, 5, -1, 0}, {720, 21, -1, 0}})
    if #interface > 0 and interface[1].textids == "2. City of Um: Haunt on the Hill" then
        erc:transitionTo(States.CHOOSE_PORTAL_OPTION)
    end
end

ernieRuneCrafter.stateHandlers[States.CHOOSE_PORTAL_OPTION] = function(erc)
    if not erc.stateData.choseOption then
        API.logInfo("Selecting City of Um option...")
        API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 720, 20, -1, API.OFF_ACT_GeneralInterface_Choose_option)
        erc.stateData.choseOption = true
        erc.stateData.portalCheckTime = os.time()
        erc.stateData.portalRetries = 0
        sleepTickRandom(2)
    end

    local portal = API.GetAllObjArray1({PORTAL_ID}, 30, {12})

    if #portal > 0 and API.GetPlayerAnimation_(API.GetLocalPlayerName()) == -1 then
        erc:transitionTo(States.ENTER_PORTAL)
    else
        local waitTime = os.difftime(os.time(), erc.stateData.portalCheckTime)
        if waitTime >= 3 and not API.ReadPlayerMovin() then
            erc.stateData.portalRetries = erc.stateData.portalRetries + 1
            if erc.stateData.portalRetries >= 5 then
                API.logError("Portal not found after 5 attempts. Restarting from USE_BRACELET...")
                erc:transitionTo(States.USE_BRACELET)
            else
                API.logInfo("Portal not found, retrying (attempt " .. erc.stateData.portalRetries .. "/5)...")
                erc.stateData.portalCheckTime = os.time()
            end
        end
    end
end

ernieRuneCrafter.stateHandlers[States.ENTER_PORTAL] = function(erc)
    if not erc.stateData.enteredPortal then
        API.logInfo("Entering dark portal...")
        if not API.DoAction_BDive_Tile(WPOINT.new(1164, 1828, 15)) then
            if not API.DoAction_Dive_Tile(WPOINT.new(1164, 1828, 15)) then
                API.DoAction_Tile(WPOINT.new(1164, 1828, 15))
            end 
        end
        sleepTickRandom(1)
        API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ PORTAL_ID },50);
        erc.stateData.enteredPortal = true
        sleepTickRandom(4)
    end

    local altarId = RUNE_ALTAR_IDS[RUNE_TYPE]
    local altar = API.GetAllObjArray1({altarId}, 30, {0})
    if #altar > 0 then
        erc:transitionTo(States.APPROACH_ALTAR)
    end
end

ernieRuneCrafter.stateHandlers[States.CHECK_RUNIC_ATTUNER] = function(erc)
    local pocketItems = API.Container_Get_all(94)
    local useRunicTeleport = false

    if pocketItems and #pocketItems >= 6 and pocketItems[6].item_id == RUNIC_ATTUNER then
        API.logInfo("Runic Attuner detected, checking active buff...")

        local vbResult = API.VB_FindPSett(11854)
        if vbResult and vbResult.state then
            local altarId = vbResult.state
            API.logInfo("Found Runic Attuner altar ID: " .. altarId)

            local altarIdToRune = {
                [554] = "fire",
                [555] = "water",
                [556] = "air",
                [557] = "earth",
                [558] = "mind",
                [559] = "body",
                [560] = "death",
                [561] = "nature",
                [562] = "chaos",
                [563] = "law",
                [564] = "cosmic",
                [565] = "blood",
                [566] = "soul",
                [9075] = "astral",
                [58450] = "time"
            }

            if altarId == 13649 then
                local rcLevel = API.GetSkillsTableSkill(40)
                API.logInfo("Runecrafting level: " .. rcLevel)

                if rcLevel >= 100 and toBool(CONFIG.hasAccessToTimeAltar) then
                    RUNE_TYPE = "time"
                elseif rcLevel >= 90 and toBool(CONFIG.hasAccessToSoulAltar) then
                    RUNE_TYPE = "soul"
                elseif rcLevel >= 77 and toBool(CONFIG.hasAccessToBloodAltar) then
                    RUNE_TYPE = "blood"
                elseif rcLevel >= 65 and toBool(CONFIG.hasAccessToDeathAltar) then
                    RUNE_TYPE = "death"
                elseif rcLevel >= 54 then
                    RUNE_TYPE = "law"
                elseif rcLevel >= 44 then
                    RUNE_TYPE = "nature"
                elseif rcLevel >= 40 and toBool(CONFIG.hasAccessToAstralAltar) then
                    RUNE_TYPE = "astral"
                elseif rcLevel >= 35 then
                    RUNE_TYPE = "chaos"
                elseif rcLevel >= 27 then
                    RUNE_TYPE = "cosmic"
                elseif rcLevel >= 20 then
                    RUNE_TYPE = "body"
                elseif rcLevel >= 14 then
                    RUNE_TYPE = "fire"
                elseif rcLevel >= 9 then
                    RUNE_TYPE = "earth"
                elseif rcLevel >= 5 then
                    RUNE_TYPE = "water"
                else
                    RUNE_TYPE = "air"
                end

                API.logInfo("Best altar for level " .. rcLevel .. ": " .. RUNE_TYPE)
            elseif altarIdToRune[altarId] then
                RUNE_TYPE = altarIdToRune[altarId]
                API.logInfo("Using altar based on VB result: " .. RUNE_TYPE)
            end

            local matchingBuffId = nil
            for _, buffId in ipairs(RUNIC_BUFF_IDS) do
                if buffId == altarId then
                    matchingBuffId = buffId
                    break
                end
            end

            if matchingBuffId then
                local buffStatus = API.Buffbar_GetIDstatus(matchingBuffId)
                if buffStatus.found then
                    local buffText = buffStatus.text
                    local buffNumber = tonumber(buffText)
                    local hasHadChargesAboveZero = erc.runicAttunerHadCharges or false

                    if buffNumber and buffNumber > 0 then
                        erc.runicAttunerHadCharges = true
                        hasHadChargesAboveZero = true
                    end

                    local canTeleport = buffText == "10" or buffText == "20" or buffText == "30" or buffText == "40" or (buffText == "0" and hasHadChargesAboveZero)

                    if canTeleport then
                        if RUNE_TYPE == "soul" then
                            if not erc.stateData.usedRunicTeleportForSoul then
                                API.logInfo("Runic Attuner has " .. buffText .. " charges, using teleport for soul altar...")
                                useRunicTeleport = true
                                erc.stateData.usedRunicTeleportForSoul = true
                            else
                                API.logInfo("Already used Runic Attuner teleport this soul altar trip, using wilderness sword...")
                            end
                        else
                            API.logInfo("Runic Attuner has " .. buffText .. " charges, using teleport...")
                            useRunicTeleport = true
                        end
                    end
                end
            end
        end
    end

    if useRunicTeleport then
        erc:transitionTo(States.USE_RUNIC_TELEPORT)
    else
        erc:transitionTo(States.USE_WILDERNESS_SWORD)
    end
end

ernieRuneCrafter.stateHandlers[States.USE_RUNIC_TELEPORT] = function(erc)
    if not erc.stateData.calculatedCapacity then
        essenceCount = calculateEssenceCapacity()
        API.logInfo("Essence capacity: " .. essenceCount)
        erc.stateData.calculatedCapacity = true
    end

    if not erc.stateData.usedRunicTeleport then
        API.logInfo("Using Runic Attuner teleport...")
        runicAttunerAB = API.GetABs_name1("Runic Attuner")
        if not runicAttunerAB or runicAttunerAB.id <= 0 then
            API.logError("Runic Attuner ability not found!")
            erc:transitionTo(States.USE_WILDERNESS_SWORD)
            return
        end
        API.DoAction_Ability_Direct(runicAttunerAB, 1, API.OFF_ACT_GeneralInterface_route)
        erc.stateData.usedRunicTeleport = true
        sleepTickRandom(4)
    end

    local altarId = RUNE_ALTAR_IDS[RUNE_TYPE]
    local altar = API.GetAllObjArray1({altarId}, 30, {0})
    if #altar > 0 then
        erc:transitionTo(States.APPROACH_ALTAR)
    end
end

ernieRuneCrafter.stateHandlers[States.USE_WILDERNESS_SWORD] = function(erc)
    if not erc.stateData.calculatedCapacity then
        essenceCount = calculateEssenceCapacity()
        API.logInfo("Essence capacity: " .. essenceCount)
        erc.stateData.calculatedCapacity = true
    end

    if not erc.stateData.usedSword then
        API.logInfo("Using Wilderness sword...")
        API.DoAction_Ability_Direct(wildernessSwordAB, 1, API.OFF_ACT_GeneralInterface_route)
        erc.stateData.usedSword = true
    end

    local wildernessWall = API.GetAllObjArray1({65079}, 50, {12})
    if #wildernessWall > 0 then
        sleepTickRandom(4)
        erc:transitionTo(States.INTERACT_WILDERNESS_WALL)
    end
end

ernieRuneCrafter.stateHandlers[States.INTERACT_WILDERNESS_WALL] = function(erc)
    if not erc.stateData.interactedWall then
        API.logInfo("Interacting with wilderness wall...")
        API.DoAction_Object1(0xb5,API.OFF_ACT_GeneralObject_route0,{ 65079 },50);
        erc.stateData.interactedWall = true
        erc.stateData.wallInteractTime = os.time()
        erc.stateData.wallRetries = erc.stateData.wallRetries or 0
        sleepTickRandom(3)
    end

    if erc.stateData.interactedWall and not erc.stateData.surgedFromWall then
        if API.PlayerCoord().y >= 3523 then
            sleepTickRandom(2)
            surgeAB = API.GetABs_name1("Surge")
            if surgeAB and surgeAB.id > 0 then
                API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
                sleepTickRandom(0)
            end
            if not API.DoAction_BDive_Tile(WPOINT.new(3102,3543,1)) then
                if not API.DoAction_Dive_Tile(WPOINT.new(3102,3543,1)) then
                    API.DoAction_Tile(WPOINT.new(3102,3543,1))
                end
            end
            sleepTickRandom(0)
            erc.stateData.surgedFromWall = true
        else
            local waitTime = os.difftime(os.time(), erc.stateData.wallInteractTime)
            if waitTime > 2 and not API.ReadPlayerMovin() then
                erc.stateData.wallRetries = erc.stateData.wallRetries + 1
                if erc.stateData.wallRetries >= 8 then
                    API.logError("Failed to cross wilderness wall after 8 retries. Restarting from USE_WILDERNESS_SWORD...")
                    erc:transitionTo(States.USE_WILDERNESS_SWORD)
                    return
                else
                    API.logInfo("Not past wall after 2 seconds, retrying (attempt " .. erc.stateData.wallRetries + 1 .. "/8)...")
                    erc.stateData.interactedWall = false
                    erc.stateData.wallInteractTime = nil
                end
            end
        end
    end

    local mageOfZamorak = API.FindNPCbyName("Mage of Zamorak", 50)
    if mageOfZamorak.Id ~= 0 and erc.stateData.surgedFromWall then
        erc:transitionTo(States.TELEPORT_WITH_MAGE)
    end
end

ernieRuneCrafter.stateHandlers[States.TELEPORT_WITH_MAGE] = function(erc)
    if not erc.stateData.teleportedWithMage then
        API.logInfo("Teleporting with Mage of Zamorak...")
        if API.FindNPCbyName("Mage of Zamorak", 50).Action == "Teleport" then
            Interact:NPC("Mage of Zamorak", "Talk-to", 50)
        elseif API.FindNPCbyName("Mage of Zamorak", 50).Action == "Talk-to" then
            Interact:NPC("Mage of Zamorak", "Teleport", 50)
        end
        erc.stateData.teleportedWithMage = true
    end

    local rift = API.GetAllObjArray1({7134}, 50, {0})
    if #rift > 0 then
        erc:transitionTo(States.ENTER_RIFT)
        sleepTickRandom(1)
    end
end

ernieRuneCrafter.stateHandlers[States.ENTER_RIFT] = function(erc)
    if not erc.stateData.enteredRift then
        local riftName = RUNE_TYPE:gsub("^%l", string.upper) .. " rift"
        API.logInfo("Entering " .. riftName .. "...")
        Interact:Object(riftName, "Exit-through", 50)
        erc.stateData.enteredRift = true
        erc.stateData.riftCheckTime = os.time()
        erc.stateData.riftRetries = 0
        sleepTickRandom(3)
    end

    local altarId = RUNE_ALTAR_IDS[RUNE_TYPE]
    local altar = API.GetAllObjArray1({altarId}, 30, {0})
    if #altar > 0 then
        erc:transitionTo(States.APPROACH_ALTAR)
    else
        local waitTime = os.difftime(os.time(), erc.stateData.riftCheckTime)
        if waitTime >= 1 and not API.ReadPlayerMovin() then
            erc.stateData.riftRetries = erc.stateData.riftRetries + 1
            if erc.stateData.riftRetries >= 8 then
                API.logError("Altar not found after 8 attempts. Restarting from TELEPORT_WITH_MAGE...")
                erc:transitionTo(States.USE_WILDERNESS_SWORD)
            else
                API.logInfo("Altar not found, retrying (attempt " .. erc.stateData.riftRetries .. "/8)...")
                erc.stateData.enteredRift = false
                erc.stateData.riftCheckTime = os.time()
            end
        end
    end
end

ernieRuneCrafter.stateHandlers[States.APPROACH_ALTAR] = function(erc)
    if RUNE_TYPE == "soul" and IS_WILDERNESS then
        if not erc.stateData.chargerFilled then
            API.logInfo("Soul altar detected - filling charger...")
            Interact:Object("Charger", "Deposit", 10)
            sleepTickRandom(5)
            erc.stateData.chargerFilled = true
        end

        if not erc.stateData.chargerCharged then
            if not erc.stateData.startedCharging then
                API.logInfo("Charging the soul charger...")
                Interact:Object("Charger", "Charge altar", 10)
                erc.stateData.startedCharging = true
                sleepTickRandom(5)
            end

            if CONFIG.soulAltarCharges == "1 charge" then
                sleepTickRandom(2)
                local chargeText = API.ScanForInterfaceTest2Get(false, {{1251, 8, -1, 0}, {1251, 36, -1, 0}, {1251, 2, -1, 0}, {1251, 7, -1, 0}, {1251, 22, -1, 0}, {1251, 27, -1, 0}})[1].textids
                if chargeText then
                    local currentCharges = tonumber(chargeText:match("(%d+)/"))
                    if currentCharges and currentCharges >= 1 then
                        API.logInfo("1 charge obtained, cancelling charging process...")
                        sleepTickRandom(1)
                        erc.stateData.chargerCharged = true
                        erc.soulChargerTotalCharges = 100  
                        erc.stateData.checkedCharges = true
                        sleepTickRandom(2)
                        return
                    end
                end
            end

            if API.isProcessing() then
                return
            end

            API.logInfo("Charging complete!")
            erc.stateData.chargerCharged = true
            sleepTickRandom(2)
        end

        if not erc.stateData.checkedCharges then
            local chargesGained = math.floor(essenceCount / 4)
            erc.soulChargerTotalCharges = erc.soulChargerTotalCharges + chargesGained

            API.logInfo("Added " .. chargesGained .. " charges. Total charges: " .. erc.soulChargerTotalCharges)

            local chargeThreshold = 100
            if CONFIG.soulAltarCharges == "1 inventory worth of charges" then
                chargeThreshold = chargesGained
                API.logInfo("Using 1 inventory threshold: " .. chargeThreshold .. " charges")
            elseif CONFIG.soulAltarCharges == "1 charge" then
                chargeThreshold = 1
            end

            if erc.soulChargerTotalCharges < chargeThreshold then
                API.logInfo("Soul charger has " .. erc.soulChargerTotalCharges .. " charges, need " .. chargeThreshold .. ". Returning to bank...")
                erc:transitionTo(States.REFRESH_FAMILIAR)
                return
            else
                API.logInfo("Soul charger has " .. erc.soulChargerTotalCharges .. " charges, ready to craft!")
            end
            erc.stateData.checkedCharges = true
        end
    end

    if not erc.stateData.approachedAltar then
        API.logInfo("Approaching " .. RUNE_TYPE .. " altar...")

        local altarName = RUNE_TYPE:gsub("^%l", string.upper) .. " altar"
        surgeAB = API.GetABs_name1("Surge")
        bindingRodAB = API.GetABs_name1("binding rod")
        if not bindingRodAB then
            bindingRodAB = API.GetABs_name1("Binding rod")
        end

        local hasPowerburst = false
        for _, powerburstId in ipairs(POWERBURST_OF_SORCERY) do
            if Inventory:Contains(powerburstId) then
                hasPowerburst = true
                break
            end
        end

        if hasPowerburst then
            powerburstOfSorceryAB = API.GetABs_name1("Powerburst of sorcery")
        end

        if hasBindingRod() and bindingRodAB ~= nil then
            API.DoAction_Ability_Direct(bindingRodAB, 2, API.OFF_ACT_GeneralInterface_route)
        end

        if hasPowerburst and powerburstOfSorceryAB ~= nil then
            local debuffStatus = API.DeBuffbar_GetIDstatus(48960)
            if not debuffStatus.found then
                API.logInfo("Using Powerburst of Sorcery...")
                API.DoAction_Ability_Direct(powerburstOfSorceryAB, 1, API.OFF_ACT_GeneralInterface_route)
                sleepTickRandom(1)
            else
                API.logInfo("Powerburst of Sorcery debuff active, skipping...")
            end
        end

        if IS_WILDERNESS then
            Interact:Object(altarName, "Use", 50)
        else
            local altarId = RUNE_ALTAR_IDS[RUNE_TYPE]
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ altarId },50);
        end

        if not IS_WILDERNESS then
            local sleepTicks = 3
            if RUNE_TYPE == "bone" or RUNE_TYPE == "spirit" then
                sleepTicks = 5
            end
            sleepTickRandom(sleepTicks)

            if surgeAB and surgeAB.id > 0 then
                API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
                sleepTickRandom(0)
            end

            local altarId = RUNE_ALTAR_IDS[RUNE_TYPE]
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ altarId },50);
            sleepTickRandom(2)
        end
        updateExpTracking()
        erc.stateData.approachedAltar = true
        sleepTickRandom(2)
    end

    if not erc.stateData.startedCrafting then
        erc.stateData.startedCrafting = true
        erc:transitionTo(States.CRAFT_RUNES)
    end
end

ernieRuneCrafter.stateHandlers[States.CRAFT_RUNES] = function(erc)
    local isSoulAltar = RUNE_TYPE == "soul" and IS_WILDERNESS
    local craftingComplete = false

    if isSoulAltar then
        if not erc.stateData.waitedForCrafting then
            sleepTickRandom(5)
            erc.stateData.waitedForCrafting = true
        end

        if not API.isProcessing() then
            craftingComplete = true
        end
    else
        craftingComplete = not Inventory:Contains(PURE_ESSENCE_ID)
    end

    if craftingComplete then
        updateRuneBreakdown()
        updateExpTracking()
        erc.tripCounter = erc.tripCounter + 1

        if isSoulAltar and erc.soulChargerTotalCharges > 0 then
            API.logInfo("Soul runes crafted! Resetting charger charges and runic teleport flag.")
            erc.soulChargerTotalCharges = 0
            erc.stateData.usedRunicTeleportForSoul = false
        end

        erc:transitionTo(States.REFRESH_FAMILIAR)
    else
        erc:transitionTo(States.APPROACH_ALTAR)
    end
end

ernieRuneCrafter.stateHandlers[States.REFRESH_FAMILIAR] = function(erc)
    local hasFamiliarConfigured = toBool(CONFIG.hasAbyssalParasite) or toBool(CONFIG.hasAbyssalLurker) or toBool(CONFIG.hasAbyssalTitan)

    if not hasFamiliarConfigured then
        erc:transitionTo(States.TELEPORT_TO_BANK)
        return
    end

    local shouldUsePouch = false
    local buffStatus = API.Buffbar_GetIDstatus(26095)

    if buffStatus.found then
        local timeRemaining = tonumber(buffStatus.conv_text)
        if timeRemaining and timeRemaining <= 2 then
            API.logInfo("Summoning familiar buff low (" .. timeRemaining .. " mins), will use pouch...")
            shouldUsePouch = true
        end
    else
        for _, pouchId in ipairs(ABYSSAL_POUCH) do
            if Inventory:Contains(pouchId) then
                API.logInfo("No Summoning familiar buff found but pouch detected, will refresh familiar...")
                shouldUsePouch = true
                break
            end
        end
    end

    if not shouldUsePouch then
        erc:transitionTo(States.TELEPORT_TO_BANK)
        return
    end

    if not toBool(CONFIG.hasAccessToAltarOfWar) then
        API.logInfo("Summoning familiar needs refresh but no access to Altar of War. Skipping summoning restoration...")
        erc:transitionTo(States.TELEPORT_TO_BANK)
        return
    end

    local altar = API.GetAllObjArray1({ALTAR_OF_WAR_ID}, 30, {0})
    if #altar > 0 then
        API.logInfo("Already at War's Retreat, skipping teleport...")
        erc.stateData.teleportedToWars = true
        erc.stateData.teleportTime = os.time()
        erc.stateData.altarRetries = 0
    end

    if not erc.stateData.teleportedToWars then
        warsTeleportAB = API.GetABs_name1("War's Retreat Teleport")

        if warsTeleportAB and warsTeleportAB.id > 0 then
            API.logInfo("Teleporting to War's Retreat for Altar of War...")
            API.DoAction_Ability_Direct(warsTeleportAB, 1, API.OFF_ACT_GeneralInterface_route)
            erc.stateData.teleportedToWars = true
            erc.stateData.teleportTime = os.time()
            erc.stateData.altarRetries = 0
            sleepTickRandom(2)
            return
        else
            API.logError("War's Retreat Teleport not found! Cannot restore summoning points.")
            erc:transitionTo(States.TELEPORT_TO_BANK)
            return
        end
    end

    if not erc.stateData.restoredSummoningPoints then
        local altar = API.GetAllObjArray1({ALTAR_OF_WAR_ID}, 30, {0})
        if #altar > 0 then
            sleepTickRandom(3)
            API.logInfo("Altar of War found, restoring summoning points...")
            Interact:Object("Altar of War", "Pray", 30)
            sleepTickRandom(8)
            erc.stateData.restoredSummoningPoints = true
            return
        else
            local waitTime = os.difftime(os.time(), erc.stateData.teleportTime)
            if waitTime > 3 and not API.ReadPlayerMovin() then
                erc.stateData.altarRetries = (erc.stateData.altarRetries or 0) + 1
                if erc.stateData.altarRetries >= 3 then
                    API.logError("Altar of War not found after 3 retries. Skipping summoning restoration...")
                    erc:transitionTo(States.TELEPORT_TO_BANK)
                    return
                else
                    API.logInfo("Altar not visible, retrying teleport (attempt " .. erc.stateData.altarRetries + 1 .. "/3)...")
                    API.DoAction_Ability_Direct(warsTeleportAB, 1, API.OFF_ACT_GeneralInterface_route)
                    erc.stateData.teleportTime = os.time()
                    sleepTickRandom(2)
                end
            end
            return
        end
    end

    if not erc.stateData.usedPouch then
        for _, pouchId in ipairs(ABYSSAL_POUCH) do
            if Inventory:Contains(pouchId) then
                API.logInfo("Using Abyssal Pouch: " .. pouchId)
                Inventory:DoAction(pouchId, 1, API.OFF_ACT_GeneralInterface_route)
                sleepTickRandom(2)
                erc.stateData.usedPouch = true
                break
            end
        end

        if not erc.stateData.usedPouch then
            return
        end
    end

    if TELEPORT_METHOD == "War's Retreat Teleport" then
        BANK_CHEST_ID = WARS_BANK_CHEST_ID
    end
    erc:transitionTo(States.BANKING)
end

ernieRuneCrafter.stateHandlers[States.TELEPORT_TO_BANK] = function(erc)
    local hasFamiliarConfigured = toBool(CONFIG.hasAbyssalParasite) or toBool(CONFIG.hasAbyssalLurker) or toBool(CONFIG.hasAbyssalTitan)
    local useWarsForFirstBank = not erc.firstBankCompleted and hasFamiliarConfigured and TELEPORT_METHOD == "GotE Deep Sea Fishing Hub"
    local targetBankId = BANK_CHEST_ID

    if useWarsForFirstBank then
        targetBankId = WARS_BANK_CHEST_ID
    end

    local bankChest = API.GetAllObjArray1({targetBankId}, 20, {0,12})
    if #bankChest > 0 then
        API.logInfo("Already at bank location, skipping teleport...")
        if useWarsForFirstBank then
            local originalBankId = BANK_CHEST_ID
            BANK_CHEST_ID = WARS_BANK_CHEST_ID
            erc.stateData.restoreBankId = originalBankId
        end
        erc:transitionTo(States.BANKING)
        return
    end

    if not erc.stateData.teleported then
        if TELEPORT_METHOD == "War's Retreat Teleport" or useWarsForFirstBank then
            if useWarsForFirstBank then
                API.logInfo("First banking with familiar - using War's Retreat...")
                if not warsTeleportAB then
                    warsTeleportAB = API.GetABs_name1("War's Retreat Teleport")
                end
                API.DoAction_Ability_Direct(warsTeleportAB, 1, API.OFF_ACT_GeneralInterface_route)
                local originalBankId = BANK_CHEST_ID
                BANK_CHEST_ID = WARS_BANK_CHEST_ID
                erc.stateData.restoreBankId = originalBankId
            else
                API.logInfo("Teleporting to War's Retreat...")
                API.DoAction_Ability_Direct(warsTeleportAB, 1, API.OFF_ACT_GeneralInterface_route)
            end
        elseif TELEPORT_METHOD == "GotE Deep Sea Fishing Hub" then
            API.logInfo("Teleporting to Deep Sea Fishing Hub...")
            if deepSeaTeleportAB.action == "Deep sea fishing hub" then
                API.DoAction_Ability_Direct(deepSeaTeleportAB, 1, API.OFF_ACT_GeneralInterface_route)
            else
                API.DoAction_Ability_Direct(deepSeaTeleportAB, 2, API.OFF_ACT_GeneralInterface_route)
            end
        end
        erc.stateData.teleported = true
        sleepTickRandom(4)
    end

    if TELEPORT_METHOD == "War's Retreat Teleport" then
        BANK_CHEST_ID = WARS_BANK_CHEST_ID
    elseif TELEPORT_METHOD == "GotE Deep Sea Fishing Hub" and erc.firstBankCompleted then
        BANK_CHEST_ID = DEEP_SEA_BANK_CHEST_ID
    end
    bankChest = API.GetAllObjArray1({BANK_CHEST_ID}, 20, {0,12})
    if #bankChest > 0 then
        erc:transitionTo(States.BANKING)
    end
end

ernieRuneCrafter.stateHandlers[States.BANKING] = function(erc)
    if not erc.stateData.banked then
        API.logInfo("Banking...")
        if BANK_CHEST_ID == WARS_BANK_CHEST_ID then
            Interact:Object("Bank chest", "Load Last Preset from", 20)
        elseif BANK_CHEST_ID == DEEP_SEA_BANK_CHEST_ID then
            Interact:Object("Rowboat", "Load Last Preset from", 20)
        end
        if API.DoBankPin(CONFIG.bankPin) then
            if CONFIG.bankPin == nil then
                Logger:Error("No Bank Pin provided in configuration")
            end
        end
        erc.stateData.banked = true
        sleepTickRandom(4)
    end

    if Inventory:Contains(PURE_ESSENCE_ID) then
        if not erc.firstBankCompleted then
            erc.firstBankCompleted = true
            if erc.stateData.restoreBankId then
                BANK_CHEST_ID = erc.stateData.restoreBankId
                erc.stateData.restoreBankId = nil
            end
            local hasFamiliarConfigured = toBool(CONFIG.hasAbyssalParasite) or toBool(CONFIG.hasAbyssalLurker) or toBool(CONFIG.hasAbyssalTitan)
            if hasFamiliarConfigured then
                erc:transitionTo(States.REFRESH_FAMILIAR)
                return
            end
        end

        if IS_WILDERNESS then
            erc:transitionTo(States.CHECK_RUNIC_ATTUNER)
        else
            erc:transitionTo(States.USE_BRACELET)
        end
    elseif erc.stateData.bankAttempts and erc.stateData.bankAttempts > 3 then
        API.logError("Failed to get essence from bank after multiple attempts")
        erc:transitionTo(States.COMPLETE)
    else
        erc.stateData.bankAttempts = (erc.stateData.bankAttempts or 0) + 1
        erc.stateData.banked = false
        sleepTickRandom(1)
    end
end

ernieRuneCrafter.stateHandlers[States.COMPLETE] = function(erc)
    API.logInfo("Runecrafting session complete!")
    API.logInfo("Total runes crafted: " .. erc.runesCrafted)
    API.logInfo(formatElapsedTime(erc.startTime))
    API.Write_LoopyLoop(false)
end

API.logWarn("=== Ernie's Auto Runecraft Started ===")
API.logInfo("Rune Type: " .. RUNE_TYPE)
API.Write_fake_mouse_do(false)
API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    idleCheck()
    updateExpTracking()
    trackingData()
    ernieRuneCrafter:execute()
    API.RandomSleep2(50, 100, 150)
end

API.logWarn("=== Ernie's Auto Runecraft Stopped ===")
API.logInfo("Total runes crafted: " .. ernieRuneCrafter.runesCrafted)
API.logInfo(formatElapsedTime(ernieRuneCrafter.startTime))
