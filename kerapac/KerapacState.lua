local API = require("api")
local Data = require("kerapac/KerapacData")
local Logger = require("kerapac/KerapacLogger")

local KerapacState = {
    startScript = false,
    isResetting = false,
    guiVisible = false,
    
    isInWarsRetreat = false,
    isInArena = false,
    isPortalUsed = false,
    
    isInBattle = false,
    isTimeToLoot = false,
    isLooted = false,
    isPhasing = false,
    isMovedToCenter = false,
    islightningPhase = false,
    isAttackingKerapac = false,
    isPlayerDead = false,
    hasReclaimedItems = true,
    isFightStarted = false,
    isEchoesDead = false,
    isNorthEchoDead = false,
    isWestEchoDead = false,
    isSouthEchoDead = false,
    
    isRiftDodged = false,
    isJumpDodged = true,
    
    isBanking = false,
    isRestoringPrayer = false,
    isPrepared = false,
    isMaxAdrenaline = false,
    
    isScriptureEquipped = false,
    hasWeaponPoison = false,
    hasAdrenalinePotion = false,
    hasDeathGuardEquipped = false,
    hasOmniGuardEquipped = false,
    hasDarkness = false,
    hasOverload = false,
    hasInvokeDeath = false,
    hasSplitSoul = false,
    hasDebilitate = false,
    hasDevotion = false,
    hasReflect = false,
    hasImmortality = false,
    hasBloatDebuff = false,
    hasFreedom = false,
    hasResonance = false,
    hasScriptureBuff = false,
    hasTimeWarpBuff = false,
    hasDodged = false,
    
    isFamiliarSummoned = false,
    isAutoFireSetup = false,
    
    isHardMode = false,
    isUsingSplitSoul = false,
    
    isInParty = false,
    isPartyLeader = false,
    isSetupFirstInstance = false,
    isTeamComplete = false,
    
    isPhase4SetupComplete = false,
    isClonesSetup = false,
    
    isResonanceEnabled = false,
    isMagePrayEnabled = false,
    isMeleePrayEnabled = false,
    isSoulSplitEnabled = false,
    isFullManualEnabled = false,
    isAutoRetaliateDisabled = false,
    isAbilityBarsValidated = false,
    
    canAttack = true,
    
    playerPosition = nil,
    startLocationOfArena = nil,
    centerOfArenaPosition = nil,
    
    scripture = nil,
    currentState = nil,
    overheadTable = nil,
    
    necrosisStacks = nil,
    residualSoulsStack = nil,
    lastAttackTick = nil,

    warpTimeTicks = API.Get_tick(),
    globalCooldownTicks = API.Get_tick(),
    eatFoodTicks = API.Get_tick(),
    drinkRestoreTicks = API.Get_tick(),
    buffCheckCooldown = API.Get_tick(),
    avoidLightningTicks = API.Get_tick(),
    phase4Ticks = API.Get_tick(),
    resonanceTicks = API.Get_tick(),
    vulnTicks = API.Get_tick(),
    summoningSpecialTicks = API.Get_tick(),
    removeFromTableTicks = API.Get_tick(),
    
    lightningDirections = {},
    kerapacPhase = 1,
    kerapacEcho1 = nil,
    kerapacEcho2 = nil,
    kerapacEcho3 = nil,

    selectedPrayerType = nil,
    selectedPassive = nil,
    sortedPassiveKeys = {}
}

local prayerTypeNumber = API.VB_FindPSett(12219).state
if prayerTypeNumber == 0 then
    KerapacState.selectedPrayerType = "Prayers"  
elseif prayerTypeNumber == 1 then
    KerapacState.selectedPrayerType = "Curses"  
else
    KerapacState.selectedPrayerType = "Curses"
end

for key in pairs(Data.passiveBuffs) do
    table.insert(KerapacState.sortedPassiveKeys, key)
end
table.sort(KerapacState.sortedPassiveKeys)

function KerapacState:InitializeFromConfig(config)
    Logger:Info("Initializing from CONFIG")
    
    local function toBool(value)
        if type(value) == "string" then
            return value == "true"
        else
            return value or false
        end
    end
    
    self.selectedPassive = config.selectedPassive or "Turmoil"
    self.isHardMode = toBool(config.isHardMode)
    self.isInParty = toBool(config.isInParty)
    self.isPartyLeader = toBool(config.isPartyLeader)
    
    -- Handle adrenaline crystal setting
    if config.hasAdrenalineCrystal then
        self.isMaxAdrenaline = false
    else
        self.isMaxAdrenaline = true
    end
    
    -- Update Data with config values
    if config.discordWebhookUrl and config.discordWebhookUrl ~= "" then
        Data.discordWebhookUrl = config.discordWebhookUrl
    end
    if config.discordUserId and config.discordUserId ~= "" then
        Data.discordUserId = config.discordUserId
    end
    if config.bankPin and tonumber(config.bankPin) and tonumber(config.bankPin) > 0 then
        Data.bankPin = tonumber(config.bankPin)
    end
    
    -- Handle party data only if party mode is enabled
    if self.isInParty then
        -- Handle party leader name
        if config.partyLeader and config.partyLeader ~= "" then
            Data.partyLeader = config.partyLeader
        end
        
        -- Handle party members (parse comma-separated string)
        if config.partyMembersText and config.partyMembersText ~= "" then
            Data.partyMembers = {}
            for member in string.gmatch(config.partyMembersText, "([^,]+)") do
                local trimmedMember = member:match("^%s*(.-)%s*$")  -- trim whitespace
                if trimmedMember ~= "" then
                    table.insert(Data.partyMembers, trimmedMember)
                end
            end
        end
    else
        -- Clear any party data when party mode is disabled
        Data.partyLeader = nil
        Data.partyMembers = {}
    end
    
    -- Update thresholds if provided
    if config.hpThreshold and tonumber(config.hpThreshold) then
        Data.hpThreshold = tonumber(config.hpThreshold)
    end
    if config.prayerThreshold and tonumber(config.prayerThreshold) then
        Data.prayerThreshold = tonumber(config.prayerThreshold)
    end
    if config.emergencyEatThreshold and tonumber(config.emergencyEatThreshold) then
        Data.emergencyEatThreshold = tonumber(config.emergencyEatThreshold)
    end
    
    -- Handle party settings
    if self.isInParty then
        if self.isPartyLeader then
            -- If user marked themselves as party leader but didn't specify a name, use their current name
            if not Data.partyLeader or Data.partyLeader == "" then
                Data.partyLeader = API.GetLocalPlayerName()
            end
        elseif not Data.partyLeader or Data.partyLeader == "" then
            Logger:Error("No party leader specified in configuration")
            self:StopScript()
            return
        end
    end
    
    -- Log configuration
    Logger:Info("Selected Passive: " .. (self.selectedPassive or "None"))
    Logger:Info("Hard mode: " .. tostring(self.isHardMode))
    Logger:Info("In a party: " .. tostring(self.isInParty))
    if self.isInParty then
        Logger:Info("Am I party leader: " .. tostring(self.isPartyLeader))
        Logger:Info("Party leader: " .. (Data.partyLeader or "None"))
        if Data.partyMembers and #Data.partyMembers > 0 then
            Logger:Info("Party members: " .. table.concat(Data.partyMembers, ", "))
        end
    end
    Logger:Info("Discord webhook configured: " .. tostring(Data.discordWebhookUrl ~= ""))
    Logger:Info("Discord user ID configured: " .. tostring(Data.discordUserId ~= ""))
    Logger:Info("Bank PIN configured: " .. tostring(Data.bankPin ~= nil))
    Logger:Info("Adrenaline crystal unlocked: " .. tostring(config.hasAdrenalineCrystal))
    Logger:Info("Configuration initialization complete")
end

function KerapacState:Reset()
    Logger:Info("Resetting script state")
    
    self.isFightStarted = false
    self.isRiftDodged = false
    self.isJumpDodged = true
    self.isInBattle = false
    self.isTimeToLoot = false
    self.isInWarsRetreat = false
    self.isPrepared = false
    self.isBanking = false
    self.isRestoringPrayer = false
    self.isInArena = false
    self.isLooted = false
    self.isPortalUsed = false
    self.isPhasing = false
    self.isMovedToCenter = false
    self.islightningPhase = false
    self.isPlayerDead = false
    self.hasReclaimedItems = true
    self.isTeamComplete = false
    self.isPhase4SetupComplete = false
    self.isClonesSetup = false
    self.isResonanceEnabled = false
    self.isMagePrayEnabled = false
    self.isSoulSplitEnabled = false
    self.isMaxAdrenaline = false
    self.isEchoesDead = false
    self.isNorthEchoDead = false
    self.isWestEchoDead = false
    self.isSouthEchoDead = false
    
    self.hasOverload = false
    self.hasAdrenalinePotion = false
    self.hasWeaponPoison = false
    self.hasDebilitate = false
    self.hasDevotion = false
    self.hasDarkness = false
    self.hasInvokeDeath = false
    self.hasTimeWarpBuff = false
    self.hasDodged = false
    self.kerapacPhase = 1
    self.isScriptureEquipped = false
    self.hasScriptureBuff = false
    
    Logger:Info("State reset complete")
end

function KerapacState:StartScript()
    self.startScript = true
    Logger:Info("Script started via CONFIG system")
end

function KerapacState:StopScript()
    Logger:Warn("Stopping script")
    self.startScript = false
    API.Write_LoopyLoop(false)
end

function KerapacState:CheckPlayerDeath()
    if API.GetHP_() <= 0 and not self.isPlayerDead then
        self.isPlayerDead = true
        Data.totalDeaths = Data.totalDeaths + 1
        Logger:Warn("Player died!")
    end
end

function KerapacState:HandlePhaseTransition(bossLife)
    if bossLife <= Data.phaseTransitionThreshold and self.kerapacPhase < 4 and not self.isPhasing then
        self.kerapacPhase = self.kerapacPhase + 1
        self.isPhasing = true
        Logger:Info("Entering Phase " .. self.kerapacPhase)
    elseif bossLife > Data.phaseTransitionThreshold and self.isPhasing then
        self.isPhasing = false
        Logger:Info("Resuming battle")
    end
end

function KerapacState:UpdateStateFromAnimation(animation)
    if not animation then return nil end
    
    local newState = nil
    for state, data in pairs(Data.bossStateEnum) do
        for _, animValue in ipairs(data.animations) do
            if animValue == animation then
                newState = state
                break
            end
        end
        if newState then break end
    end
    
    if newState and newState ~= self.currentState then
        Logger:Debug("State changed to: " .. Data.bossStateEnum[newState].name)
        self.currentState = newState
        return newState
    end
    
    return nil
end

function KerapacState:CanUseAbilities()
    if self.isPhasing or not self.canAttack then
        return false
    end
    
    if self.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name or
       self.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name then
        return false
    end
    
    return true
end

return KerapacState