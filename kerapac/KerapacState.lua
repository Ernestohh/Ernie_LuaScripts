local API = require("api")
local Data = require("kerapac/KerapacData")
local Logger = require("kerapac/KerapacLogger")

local KerapacState = {
    startScript = false,
    isResetting = false,
    guiVisible = true,
    
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
    isFightStarted = false,
    isEchoesDead = false,
    
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
    wave1Direction = nil,
    wave2Direction = nil,
    wave3Direction = nil,
    currentTargetLp = nil,
    
    Background = nil,
    PassivesDropdown = nil,
    StartButton = nil,
    hardModeCheckBox = nil,
    partyCheckBox = nil,
    partyLeaderCheckBox = nil,
    adrenCheckbox = nil,
    
    selectedPrayerType = nil,
    selectedPassive = nil,
    sortedPassiveKeys = {}
}

KerapacState.selectedPrayerType = API.VB_FindPSettinOrder(3277, 0).state & 1

for key in pairs(Data.passiveBuffs) do
    table.insert(KerapacState.sortedPassiveKeys, key)
end
table.sort(KerapacState.sortedPassiveKeys)

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
    self.isTeamComplete = false
    self.isPhase4SetupComplete = false
    self.isClonesSetup = false
    self.isResonanceEnabled = false
    self.isMagePrayEnabled = false
    self.isSoulSplitEnabled = false
    self.isMaxAdrenaline = false
    self.isEchoesDead = false
    
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
    
    Logger:Info("State reset complete")
end

function KerapacState:StartScript()
    self.startScript = true
    self.selectedPassive = self.PassivesDropdown.stringsArr[tonumber(self.PassivesDropdown.int_value) + 1]
    self.isHardMode = self.hardModeCheckBox.box_ticked
    
    if self.selectedPrayerType == 0 then
        self.selectedPrayerType = "Prayers"  
    elseif self.selectedPrayerType == 1 then
        self.selectedPrayerType = "Curses"  
    end
    
    if self.isInParty then
        if self.isPartyLeader then
            Data.partyLeader = API.GetLocalPlayerName()
        elseif Data.partyLeader == nil then
            Logger:Error("No party leader appointed in KerapacData.lua")
            self:StopScript()
        end
    end
    
    if self.adrenCheckbox.box_ticked then
        self.isMaxAdrenaline = false
    else
        self.isMaxAdrenaline = true
    end
    
    self.adrenCheckbox.remove = true
    self.Background.remove = true
    self.StartButton.remove = true
    self.PassivesDropdown.remove = true
    self.hardModeCheckBox.remove = true
    self.partyCheckBox.remove = true
    self.partyLeaderCheckBox.remove = true
    self.guiVisible = false
    
    Logger:Info("Script started")
    Logger:Info("Selected Prayer Type: " .. (self.selectedPrayerType or "None"))
    Logger:Info("Selected Passive: " .. (self.selectedPassive or "None"))
    Logger:Info("Hardmode on: " .. tostring(self.isHardMode))
    Logger:Info("In a party?: " .. tostring(self.isInParty))
    Logger:Info("Am I party leader?: " .. tostring(self.isPartyLeader))
end

function KerapacState:StopScript()
    Logger:Warn("Stopping script")
    self.startScript = false
    API.Write_LoopyLoop(false)
end

function KerapacState:CheckPlayerDeath()
    if API.GetHP_() <= 0 and not self.isPlayerDead then
        self.isPlayerDead = true
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