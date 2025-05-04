local API = require("api")
local Data = require("kerapac/KerapacData")

local KerapacCore = {
    startScript = false,
    isResetting = false,
    guiVisible = true,
    sortedPassiveKeys = {},
    
    isRiftDodged = false,
    isFightStarted = false,
    isJumpDodged = true,
    isInWarsRetreat = false,
    isInBattle = false,
    isTimeToLoot = false,
    isBanking = false,
    isRestoringPrayer = false,
    isPrepared = false,
    isInArena = false,
    isLooted = false,
    isPortalUsed = false,
    isPhasing = false,
    isMovedToCenter = false,
    islightningPhase = false,
    isScriptureEquipped = false,
    isAttackingKerapac = false,
    isPlayerDead = false,
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
    
    hasOverload = false,
    hasWeaponPoison = false,
    hasDarkness = false,
    hasInvokeDeath = false,
    hasSplitSoul = false,
    hasScriptureBuff = false,
    hasFreedom = false,
    hasResonance = false,
    hasReflect = false,
    hasImmortality = false,
    hasDebilitate = false,
    hasBloatDebuff = false,
    hasDevotion = false,
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
    lightningDirections = {},
    
    kerapacPhase = 1,
    kerapacEcho1 = nil,
    kerapacEcho2 = nil,
    
    Background = nil,
    PassivesDropdown = nil,
    StartButton = nil,
    hardModeCheckBox = nil,
    partyCheckBox = nil,
    partyLeaderCheckBox = nil,

    selectedPrayerType = API.VB_FindPSettinOrder(3277, 0).state & 1,
    selectedPassive = nil,
}

for key in pairs(Data.passiveBuffs) do
    table.insert(KerapacCore.sortedPassiveKeys, key)
end
table.sort(KerapacCore.sortedPassiveKeys)

KerapacCore.Background = API.CreateIG_answer()
KerapacCore.Background.box_name = "GuiBackground"
KerapacCore.Background.box_start = FFPOINT.new(Data.MARGIN, Data.BOX_START_Y, 0)
KerapacCore.Background.box_size = FFPOINT.new(Data.BOX_END_X, Data.BOX_END_Y, 0)
KerapacCore.Background.colour = ImColor.new(50, 48, 47)

KerapacCore.PassivesDropdown = API.CreateIG_answer()
KerapacCore.PassivesDropdown.box_name = "Passives"
KerapacCore.PassivesDropdown.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X, Data.BOX_START_Y + Data.PADDING_Y, 0)
KerapacCore.PassivesDropdown.stringsArr = {}

KerapacCore.StartButton = API.CreateIG_answer()
KerapacCore.StartButton.box_name = "Start"
KerapacCore.StartButton.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 120, Data.BOX_START_Y + Data.PADDING_Y + 40, 0)
KerapacCore.StartButton.box_size = FFPOINT.new(Data.BUTTON_WIDTH, Data.BUTTON_HEIGHT, 0)
KerapacCore.StartButton.colour = ImColor.new(0, 255, 0)

KerapacCore.hardModeCheckBox = API.CreateIG_answer()
KerapacCore.hardModeCheckBox.box_name = "Hard Mode"
KerapacCore.hardModeCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 40, 0)

KerapacCore.partyCheckBox = API.CreateIG_answer()
KerapacCore.partyCheckBox.box_name = "Party"
KerapacCore.partyCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 60, 0)

KerapacCore.partyLeaderCheckBox = API.CreateIG_answer()
KerapacCore.partyLeaderCheckBox.box_name = "Am I party leader"
KerapacCore.partyLeaderCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 80, 0)


for _, key in ipairs(KerapacCore.sortedPassiveKeys) do
    table.insert(KerapacCore.PassivesDropdown.stringsArr, Data.passiveBuffs[key].name)
end

local function initAbilities()
    for _, ability in pairs(Data.extraAbilities) do
        ability.AB = API.GetABs_name(ability.name)
    end
    
    for _, prayer in pairs(Data.overheadPrayersBuffs) do
        prayer.AB = API.GetABs_name(prayer.name)
    end
    
    for _, curse in pairs(Data.overheadCursesBuffs) do
        curse.AB = API.GetABs_name(curse.name)
    end
    
    for key, passive in pairs(Data.passiveBuffs) do
        if passive.name ~= "None" then
            passive.AB = API.GetABs_name(passive.name)
        end
    end
    
    for _, buff in pairs(Data.extraBuffs) do
        buff.AB = API.GetABs_name(buff.name)
    end
end

initAbilities()

function KerapacCore.log(message, level)
    level = level or "INFO"
    print(string.format("[%s] %s", level, message))
end

function KerapacCore.sleepTickRandom(sleepticks)
    API.Sleep_tick(sleepticks)
    API.RandomSleep2(1, 120, 0)
end

function KerapacCore.stopScript()
    KerapacCore.log("Stopping script", "WARN")
    KerapacCore.startScript = false
    API.Write_LoopyLoop(false)
end

function KerapacCore.whichFood()
    local food = ""
    local foundFood = false
    for i = 1, #Data.foodItems do
        foundFood = Inventory:Contains(Data.foodItems[i])
        if foundFood then
            food = Data.foodItems[i]
            break
        end
    end
    return food
end

function KerapacCore.whichEmergencyDrink()
    local emergencyDrink = ""
    local foundEmergencyDrink = false
    for i = 1, #Data.emergencyDrinkItems do
        foundEmergencyDrink = Inventory:Contains(Data.emergencyDrinkItems[i])
        if foundEmergencyDrink then
            emergencyDrink = Data.emergencyDrinkItems[i]
            break
        end
    end
    return emergencyDrink
end

function KerapacCore.whichEmergencyFood()
    local emergencyFood = ""
    local foundEmergencyFood = false
    for i = 1, #Data.emergencyFoodItems do
        foundEmergencyFood = Inventory:Contains(Data.emergencyFoodItems[i])
        if foundEmergencyFood then
            emergencyFood = Data.emergencyFoodItems[i]
            break
        end
    end
    return emergencyFood
end

function KerapacCore.whichPrayerRestore()
    local prayerRestore = ""
    local foundPrayerRestore = false
    for i = 1, #Data.prayerRestoreItems do
        foundPrayerRestore = Inventory:Contains(Data.prayerRestoreItems[i])
        if foundPrayerRestore then
            prayerRestore = Data.prayerRestoreItems[i]
            break
        end
    end
    return prayerRestore
end

function KerapacCore.whichOverload()
    local overload = ""
    local foundOverload = false
    for i = 1, #Data.overloadItems do
        foundOverload = Inventory:Contains(Data.overloadItems[i])
        if foundOverload then
            overload = Data.overloadItems[i]
            break
        end
    end
    return overload
end

function KerapacCore.whichWeaponPoison()
    local weaponPoison = ""
    local foundWeaponPoison = false
    for i = 1, #Data.weaponPoisonItems do
        foundWeaponPoison = Inventory:Contains(Data.weaponPoisonItems[i])
        if foundWeaponPoison then
            weaponPoison = Data.weaponPoisonItems[i]
            break
        end
    end
    return weaponPoison
end

function KerapacCore.whichFamiliar()
    local familiar = ""
    local foundFamiliar = false
    for i = 1, #Data.summoningPouches do
        foundFamiliar = Inventory:Contains(Data.summoningPouches[i])
        if foundFamiliar then
            familiar = Data.summoningPouches[i]
            break
        end
    end
    return familiar
end

function KerapacCore.isFamiliarHpBelowPercentage(hpString, percentage)
    if not hpString or type(hpString) ~= "string" then
        return nil
    end
     if not percentage or type(percentage) ~= "number" or percentage < 0 then
        return nil
    end

    local currentHpStr, maxHpStr = string.match(hpString, "^([^/]+)/([^/]+)$")

    if not currentHpStr then
        hpString = hpString:match("^%s*(.-)%s*$")
        if hpString then
             currentHpStr, maxHpStr = string.match(hpString, "^([^/]+)/([^/]+)$")
        end
        if not currentHpStr then
             return nil
        end
    end

    currentHpStr = string.gsub(currentHpStr, ",", "")
    maxHpStr = string.gsub(maxHpStr, ",", "")

    local currentHp = tonumber(currentHpStr)
    local maxHp = tonumber(maxHpStr)

    if not currentHp or not maxHp then
        return nil
    end
    if maxHp <= 0 then
        return nil
    end

    local thresholdValue = maxHp * (percentage / 100.0)
    local isBelow = currentHp < thresholdValue

    return isBelow
end

function KerapacCore.handleSpecialSummoning()
    if not (API.Get_tick() - KerapacCore.summoningSpecialTicks > 4) then return end
    if not Familiars:HasFamiliar() then return end 
    if not (Familiars:GetSpellPoints() >= Data.summoningPointsForScroll) then return end
    if Familiars:GetName() ~= "Hellhound" then return end
    local isHealable = KerapacCore.isFamiliarHpBelowPercentage(API.ScanForInterfaceTest2Get(false, { { 662,0,-1,0 }, { 662,43,-1,0 }, { 662,44,-1,0 }, { 662,64,-1,0 }, { 662,65,-1,0 }, { 662,66,-1,0 }, { 662,66,8,0 } })[1].textids, 70)
    if not isHealable then return end
    Familiars:CastSpecialAttack()
    KerapacCore.summoningSpecialTicks = API.Get_tick()
end

function KerapacCore.getKerapacInformation()
    return API.FindNPCbyName("Kerapac, the bound", 30)
end

function KerapacCore.getKerapacAnimation()
    local kerapacInfo = KerapacCore.getKerapacInformation()
    if kerapacInfo then
        return kerapacInfo.Anim
    end
    return nil
end

function KerapacCore.getKerapacPositionFFPOINT()
    local kerapacInfo = KerapacCore.getKerapacInformation()
    if kerapacInfo then
        return FFPOINT.new(kerapacInfo.Tile_XYZ.x, kerapacInfo.Tile_XYZ.y, kerapacInfo.Tile_XYZ.z)
    end
    return nil
end

function KerapacCore.hasMarkOfDeath()
    return (API.VB_FindPSett(11303).state >> 7 & 0x1) == 1
end

function KerapacCore.hasDeathInvocation()
    return API.Buffbar_GetIDstatus(30100).id > 0
end

function KerapacCore.checkAvailableBuffs()
    local darknessOnBar = false
    local invokeDeathOnBar = false
    local splitSoulOnBar = false
    KerapacCore.hasOverload = KerapacCore.whichOverload() ~= ""
    KerapacCore.hasWeaponPoison = KerapacCore.whichWeaponPoison() ~= ""
    KerapacCore.hasDebilitate = Data.extraAbilities.debilitateAbility.AB.slot ~= 0
    KerapacCore.hasDevotion = Data.extraAbilities.devotionAbility.AB.slot ~= 0
    KerapacCore.hasReflect = Data.extraAbilities.reflectAbility.AB.slot ~= 0
    KerapacCore.hasImmortality = Data.extraAbilities.immortalityAbility.AB.slot ~= 0
    darknessOnBar = Data.extraAbilities.darknessAbility.AB.slot ~= 0
    if darknessOnBar then
        KerapacCore.hasDarkness = Data.extraAbilities.darknessAbility.AB.enabled
    end
    invokeDeathOnBar = Data.extraAbilities.invokeDeathAbility.AB.slot ~= 0
    if invokeDeathOnBar then
        KerapacCore.hasInvokeDeath = Data.extraAbilities.invokeDeathAbility.AB.enabled
    end
    splitSoulOnBar = Data.extraAbilities.splitSoulAbility.AB.slot ~= 0
    if splitSoulOnBar then
        KerapacCore.hasSplitSoul = Data.extraAbilities.splitSoulAbility.AB.enabled
    end
    KerapacCore.hasScripture()
end

function KerapacCore.playerDied()
    if API.GetHP_() <= 0 and not KerapacCore.isPlayerDead then
        KerapacCore.isPlayerDead = true
    end
end

function KerapacCore.reclaimItemsAtGrave()
    KerapacCore.sleepTickRandom(10)
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{ 27299 },50)
    KerapacCore.sleepTickRandom(5)
    API.DoAction_Interface(0xffffffff,0xffffffff,1,1626,47,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(5)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1626,72,-1,API.OFF_ACT_GeneralInterface_Choose_option)
    KerapacCore.sleepTickRandom(5)
end

function KerapacCore.getBossStateFromAnimation(animation)
    if not animation then return nil end
    for state, data in pairs(Data.bossStateEnum) do
        for _, animValue in ipairs(data.animations) do
            if animValue == animation then
                return state
            end
        end
    end
    return nil
end
function KerapacCore.enableMagePray()
    if API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then return end
    if API.GetPrayPrecent() <= 0 or KerapacCore.magePrayEnabled then return end
    
    local overheadTable = nil
    if KerapacCore.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif KerapacCore.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        KerapacCore.log("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMage
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.isMagePrayEnabled = true
            KerapacCore.isMeleePrayEnabled = false
            KerapacCore.isSoulSplitEnabled = false
        end
    else
        KerapacCore.log("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCore.enableMeleePray()
    if API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then return end
    if API.GetPrayPrecent() <= 0 then return end
    
    local overheadTable = nil
    if KerapacCore.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif KerapacCore.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        KerapacCore.log("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMelee
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.isMagePrayEnabled = false
            KerapacCore.isMeleePrayEnabled = true
            KerapacCore.isSoulSplitEnabled = false
        end
    else
        KerapacCore.log("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCore.enableSoulSplit()
    if API.GetPrayPrecent() <= 0 then return end
    if KerapacCore.isSoulSplitEnabled then return end
    local overheadTable = nil
    if KerapacCore.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        KerapacCore.log("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.SoulSplit
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.isMagePrayEnabled = false
            KerapacCore.isMeleePrayEnabled = false
            KerapacCore.isSoulSplitEnabled = true
        end
    else
        KerapacCore.log("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCore.disableSoulSplit()
    local overheadTable = nil
    if KerapacCore.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        KerapacCore.log("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.SoulSplit
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Deactivate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
        end
    else
        KerapacCore.log("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCore.disableMagePray()
    local overheadTable = nil
    if KerapacCore.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif KerapacCore.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        KerapacCore.log("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMage
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Deactivate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.isMagePrayEnabled = false
        end
    else
        KerapacCore.log("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCore.enablePassivePrayer()
    if KerapacCore.selectedPassive == Data.passiveBuffs.None.name then
        return
    end
    
    local selectedPassiveKey = nil
    for key, data in pairs(Data.passiveBuffs) do
        if data.name == KerapacCore.selectedPassive then
            selectedPassiveKey = key
            break
        end
    end
    
    local selectedPassiveData = Data.passiveBuffs[selectedPassiveKey]
    if selectedPassiveData then
        local buffId = selectedPassiveData.buffId
        local ability = selectedPassiveData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 and API.GetPrayPrecent() > 0 then
            KerapacCore.log("Activate " .. KerapacCore.selectedPassive)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.sleepTickRandom(2)
        end
    else
        KerapacCore.log("No valid passive prayer selected or data not found.")
    end
end

function KerapacCore.disablePassivePrayer()
    local selectedPassiveKey = nil
    for key, data in pairs(Data.passiveBuffs) do
        if data.name == KerapacCore.selectedPassive then
            selectedPassiveKey = key
            break
        end
    end
    
    local selectedPassiveData = Data.passiveBuffs[selectedPassiveKey]
    if selectedPassiveData then
        local buffId = selectedPassiveData.buffId
        local ability = selectedPassiveData.AB
        
        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            KerapacCore.log("Deactivate " .. KerapacCore.selectedPassive)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
        end
    else
        KerapacCore.log("No valid passive prayer selected or data not found.")
    end
end

function KerapacCore.useDarkness()
    API.DoAction_Ability_check(Data.extraAbilities.darknessAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Concealing myself in the shadows")
end

function KerapacCore.useInvokeDeath()
    API.DoAction_Ability_check(Data.extraAbilities.invokeDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Die die die")
end

function KerapacCore.useSplitSoul()
    API.DoAction_Ability_check(Data.extraAbilities.splitSoulAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
        KerapacCore.log("Split my soul into pieces, this is my last resort")
        KerapacCore.enableSoulSplit()
end

function KerapacCore.useDevotionAbility()
    API.DoAction_Ability_check(Data.extraAbilities.devotionAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Please protect me")
end

function KerapacCore.useReflectAbility()
    API.DoAction_Ability_check(Data.extraAbilities.reflectAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Reflecting on life right now")
end

function KerapacCore.useImmortalityAbility()
    API.DoAction_Ability_check(Data.extraAbilities.immortalityAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Kill me, I dare you")
end

function KerapacCore.useResonanceAbility()
    API.DoAction_Ability_check(Data.extraAbilities.resonanceAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Resonate with me")
end

function KerapacCore.usePreparationAbility()
    API.DoAction_Ability_check(Data.extraAbilities.preparationAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Preparing to kill you")
end

function KerapacCore.useDebilitateAbility()
    if  KerapacCore.hasDebilitate then
        local hasDebilitateDebuff = false
        for _,value in ipairs(API.ReadTargetInfo(true).Buff_stack) do
            if value == Data.extraAbilities.debilitateAbility.debuffId then
                hasDebilitateDebuff = true
            end
        end
        if not hasDebilitateDebuff and KerapacCore.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name and KerapacCore.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name then
            if API.DoAction_Ability_check(Data.extraAbilities.debilitateAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
                KerapacCore.log("Kick in the nuts for more defense")
            end
        end
    end
end

function KerapacCore.useFreedomAbility()
    if Data.extraAbilities.freedomAbility.AB.id > 0 and
        Data.extraAbilities.freedomAbility.AB.enabled and 
        not API.Buffbar_GetIDstatus(Data.extraAbilities.freedomAbility.buffId).found then
        API.DoAction_Ability_check(Data.extraAbilities.freedomAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
        KerapacCore.log("Freeing myself from this blasphemy")
    end
end

function KerapacCore.useLivingDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.livingDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Living the Death")
end

function KerapacCore.useDeathSkullsAbility()
    API.DoAction_Ability_check(Data.extraAbilities.deathSkullsAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Catch these skulls sucker")
end

function KerapacCore.useFingerOfDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.fingerOfDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Fingering Death right now")
end

function KerapacCore.useBloatAbility()
    API.DoAction_Ability_check(Data.extraAbilities.bloatAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("I'm not fat, just bloated")
end

function KerapacCore.useVolleyOfSoulsAbility()
    API.DoAction_Ability_check(Data.extraAbilities.volleyOfSoulsAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Exorcising these souls out of me")
end

function KerapacCore.useTouchOfDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.touchOfDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Touching Death inappropriately")
end

function KerapacCore.useSoulSapAbility()
    API.DoAction_Ability_check(Data.extraAbilities.soulSapAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Sapping your soul")
end

function KerapacCore.useSacrificeAbility()
    API.DoAction_Ability_check(Data.extraAbilities.sacrificeAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Sacrifice your life to me")
end

function KerapacCore.useConjureUndeadArmy()
    API.DoAction_Ability_check(Data.extraAbilities.conjureUndeadArmyAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Conjuring up my harem")
end

function KerapacCore.useConjureSkeletonWarrior()
    API.DoAction_Ability_check(Data.extraAbilities.conjureSkeletonWarriorAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Conjuring up my Skelebro")
end

function KerapacCore.useConjureVengefulGhost()
    API.DoAction_Ability_check(Data.extraAbilities.conjureVengefulGhostAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Conjuring up Casper the Ghost")
end

function KerapacCore.useConjurePutridZombie()
    API.DoAction_Ability_check(Data.extraAbilities.conjurePutridZombieAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Conjuring up your Mom")
end

function KerapacCore.useCommandSkeletonWarrior()
    API.DoAction_Ability_check(Data.extraAbilities.commandSkeletonWarriorAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Commanding my Skelebro to slay")
end

function KerapacCore.useCommandVengefulGhost()
    API.DoAction_Ability_check(Data.extraAbilities.commandVengefulGhostAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    KerapacCore.log("Commanding Casper to haunt the target")
    KerapacCore.sleepTickRandom(1)
end

function KerapacCore.applyVulnerability()
    if not Inventory:Contains("Vulnerability bomb") and not API.GetABs_name1("Vulnerability bomb").enabled then return end
    if API.ReadTargetInfo().Target_Name ~= "Kerapac, the bound" and API.ReadTargetInfo().Target_Name ~= "Echo of Kerapac" then return end
    if not (API.Get_tick() - KerapacCore.vulnTicks > 12) then return end
    local hasVuln = false
    for _,value in ipairs(API.ReadTargetInfo(true).Buff_stack) do
        if value == 14395 then
            hasVuln = true
        end
    end
    local vulnAB = API.GetABs_name1("Vulnerability bomb")
    if not hasVuln then
        API.DoAction_Ability_Direct(vulnAB, 1, API.OFF_ACT_GeneralInterface_route)
        if(API.ReadTargetInfo().Target_Name == "Kerapac, the bound") then
            KerapacCore.attackKerapac()
        end
        KerapacCore.log("Found your tickle spot")
    end
    
    KerapacCore.vulnTicks = API.Get_tick()
end

function KerapacCore.checkForStun()
    if API.DeBuffbar_GetIDstatus(Data.stun).found then
        KerapacCore.log("I am stunned")
        KerapacCore.useFreedomAbility()
        API.DoAction_TileF(KerapacCore.centerOfArenaPosition)
        KerapacCore.sleepTickRandom(2)
    end
end

function KerapacCore.eatFood()
    if not Inventory:ContainsAny(Data.foodItems) and 
       not Inventory:ContainsAny(Data.emergencyDrinkItems) and 
       not Inventory:ContainsAny(Data.emergencyFoodItems) and 
       not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found or
       API.GetHPrecent() >= Data.hpThreshold or 
       API.Get_tick() - KerapacCore.eatFoodTicks <= Data.foodCooldown then 
        return 
    end
    
    local hasFood = Inventory:ContainsAny(Data.foodItems)
    local hasEmergencyFood = Inventory:ContainsAny(Data.emergencyFoodItems)
    local hasEmergencyDrink = Inventory:ContainsAny(Data.emergencyDrinkItems)
    local emergencyFoodAB = nil
    local emergencyDrinkAB = nil
    local eatFoodAB = API.GetABs_name1("Eat Food")
    if(string.find(string.lower(KerapacCore.whichEmergencyFood()), "blue blubber")) then
        emergencyFoodAB = API.GetABs_name1("Blue blubber jellyfish")
    elseif(string.find(string.lower(KerapacCore.whichEmergencyFood()), "green blubber")) then
        emergencyFoodAB = API.GetABs_name1("Green blubber jellyfish")
    end
    if string.find(string.lower(KerapacCore.whichEmergencyDrink()), "super guthix") then
        emergencyDrinkAB = API.GetABs_name1("Super Guthix rest")
    elseif string.find(string.lower(KerapacCore.whichEmergencyDrink()), "guthix")  then
        emergencyDrinkAB = API.GetABs_name1("Guthix rest")
    elseif string.find(string.lower(KerapacCore.whichEmergencyDrink()), "super saradomin")  then
        emergencyDrinkAB = API.GetABs_name1("Super Saradomin brew")
    elseif string.find(string.lower(KerapacCore.whichEmergencyDrink()), "saradomin")  then
        emergencyDrinkAB = API.GetABs_name1("Saradomin brew")
    end
    if API.GetHPrecent() <= Data.emergencyEatThreshold then
        if hasFood then
            API.DoAction_Ability_Direct(eatFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
        if hasEmergencyFood and emergencyFoodAB ~= nil then
            API.DoAction_Ability_Direct(emergencyFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
        if hasEmergencyDrink and emergencyDrinkAB ~= nil then
            API.DoAction_Ability_Direct(emergencyDrinkAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
        if Inventory:Contains("Enhanced Excalibur") and
           not API.DeBuffbar_GetIDstatus(Data.extraItems.excalibur, false).found then
            Inventory:DoAction("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
        elseif Inventory:Contains("Augmented enhanced Excalibur") and
               not API.DeBuffbar_GetIDstatus(Data.extraItems.excalibur, false).found then
                Inventory:DoAction("Augmented enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
        end
        KerapacCore.log("Eating a lot of food")
        KerapacCore.eatFoodTicks = API.Get_tick()
    else
        if hasFood then
            API.DoAction_Ability_Direct(eatFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.log("Eating some food")
            KerapacCore.eatFoodTicks = API.Get_tick()
        elseif hasEmergencyFood and emergencyFoodAB ~= nil then
            API.DoAction_Ability_Direct(emergencyFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.log("Eating some food")
            KerapacCore.eatFoodTicks = API.Get_tick()
        elseif hasEmergencyDrink and emergencyDrinkAB ~= nil then
            API.DoAction_Ability_Direct(emergencyDrinkAB, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.log("Eating some food")
            KerapacCore.eatFoodTicks = API.Get_tick()
        end
    end
end

function KerapacCore.drinkPrayer()
    if not Inventory:ContainsAny(Data.prayerRestoreItems) or 
    API.GetPrayPrecent() >= Data.prayerThreshold or 
    API.Get_tick() - KerapacCore.drinkRestoreTicks <= Data.drinkCooldown then return end

    local prayerAB = nil
    if string.find(KerapacCore.whichPrayerRestore(), "Prayer") then
        prayerAB = API.GetABs_name1("Prayer potion")
    elseif string.find(KerapacCore.whichPrayerRestore(), "Super prayer")  then
        prayerAB = API.GetABs_name1("Super prayer potion")
    elseif string.find(KerapacCore.whichPrayerRestore(), "Extreme prayer")  then
        prayerAB = API.GetABs_name1("Extreme prayer potion")
    elseif string.find(KerapacCore.whichPrayerRestore(), "Super restore")  then
        prayerAB = API.GetABs_name1("Super restore potion")
    end

    API.DoAction_Ability_Direct(prayerAB, 1, API.OFF_ACT_GeneralInterface_route)
    KerapacCore.log("Slurping on a prayer potion")
    KerapacCore.drinkRestoreTicks = API.Get_tick()
end

function KerapacCore.drinkOverload()
    if not Inventory:ContainsAny(Data.overloadItems) or 
    API.Buffbar_GetIDstatus(Data.overloadBuff.ElderOverload.buffId).found or 
    API.Buffbar_GetIDstatus(Data.overloadBuff.Overload.buffId).found or
    API.Buffbar_GetIDstatus(Data.overloadBuff.SupremeOverload.buffId).found or
    API.Get_tick() - KerapacCore.drinkRestoreTicks <= Data.drinkCooldown then return end

    local overloadAB = nil
    if string.find(KerapacCore.whichOverload(), "Overload") then
        overloadAB = API.GetABs_name1("Overload potion")
    elseif string.find(KerapacCore.whichOverload(), "Holy overload")  then
        overloadAB = API.GetABs_name1("Holy overload potion")
    elseif string.find(KerapacCore.whichOverload(), "Searing overload")  then
        overloadAB = API.GetABs_name1("Searing overload potion")
    elseif string.find(KerapacCore.whichOverload(), "Overload salve")  then
        overloadAB = API.GetABs_name1("Overload salve")
    elseif string.find(KerapacCore.whichOverload(), "Aggroverload")  then
        overloadAB = API.GetABs_name1("Aggroverload")
    elseif string.find(KerapacCore.whichOverload(), "Holy aggroverload")  then
        overloadAB = API.GetABs_name1("Holy aggroverload")
    elseif string.find(KerapacCore.whichOverload(), "Supreme overload salve")  then
        overloadAB = API.GetABs_name1("Supreme overload salve")
    elseif string.find(KerapacCore.whichOverload(), "Elder overload salve")  then
        overloadAB = API.GetABs_name1("Elder overload salve")
    elseif string.find(KerapacCore.whichOverload(), "Supreme overload potion")  then
        overloadAB = API.GetABs_name1("Supreme overload potion")
    elseif string.find(KerapacCore.whichOverload(), "Elder overload potion")  then
        overloadAB = API.GetABs_name1("Elder overload potion")
    end

    API.DoAction_Ability_Direct(overloadAB, 1, API.OFF_ACT_GeneralInterface_route)
    KerapacCore.log("Slurping an overload")
    KerapacCore.drinkRestoreTicks = API.Get_tick()
end

function KerapacCore.drinkWeaponPoison()
    if not Inventory:ContainsAny(Data.weaponPoisonItems) or 
    API.Buffbar_GetIDstatus(Data.weaponPoisonBuff).found or
    API.Get_tick() - KerapacCore.drinkRestoreTicks <= Data.drinkCooldown then return end

    local weaponPoisonAB = nil
    local items = {
        "Weapon Poison",
        "Weapon Poison++",
        "Weapon Poison+++"
    }
    
    for i = 1, #items, 1 do
        local ab = items[i]
        local ability = API.GetABs_name1(ab)
        if(ability.enabled)then
            weaponPoisonAB = ability
        end
    end
    API.DoAction_Ability_Direct(weaponPoisonAB, 1, API.OFF_ACT_GeneralInterface_route)
    KerapacCore.log("Slurping a weapon poison")
    KerapacCore.drinkRestoreTicks = API.Get_tick()
end

function KerapacCore.hasScripture()
    if API.Container_Get_s(94,Data.extraBuffs.scriptureOfJas.itemId).item_id > 0 then
        KerapacCore.scripture = (Data.extraBuffs.scriptureOfJas)
        KerapacCore.isScriptureEquipped = true
    end
    if API.Container_Get_s(94,Data.extraBuffs.scriptureOfWen.itemId).item_id > 0 then
        KerapacCore.scripture = (Data.extraBuffs.scriptureOfWen)
        KerapacCore.isScriptureEquipped = true
    end
    if API.Container_Get_s(94,Data.extraBuffs.scriptureOfFul.itemId).item_id > 0 then
        KerapacCore.scripture = (Data.extraBuffs.scriptureOfFul)
        KerapacCore.isScriptureEquipped = true
    end
    if API.Container_Get_s(94,Data.extraBuffs.scriptureOfAmascut.itemId).item_id > 0 then
        KerapacCore.scripture = (Data.extraBuffs.scriptureOfAmascut)
        KerapacCore.isScriptureEquipped = true
    end
end

function KerapacCore.enableScripture(book)
    if book.AB.enabled and 
    not API.Buffbar_GetIDstatus(book.itemId).found then
        API.DoAction_Ability_check(book.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
        KerapacCore.log("Enabling Scripture")
        KerapacCore.hasScriptureBuff = true
        KerapacCore.sleepTickRandom(2)
    end
end

function KerapacCore.useWarpTime()
    initAbilities()
    if not (API.Get_tick() - KerapacCore.warpTimeTicks > 64) then return end 
    if not (Data.extraAbilities.livingDeathAbility.AB.cooldown_timer <= 0)
    and not (API.GetAddreline_() > 99) then return end
    API.DoAction_Interface(0x2e,0xffffffff,1,743,1,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.log("Ultra Instinct mode Tu du tu du du du tu du..")
    KerapacCore.warpTimeTicks = API.Get_tick()
end

function KerapacCore.setupPlayerTank(clones)
    if KerapacCore.isPartyLeader or not KerapacCore.isInParty then 
        API.DoAction_Dive_Tile(KerapacCore.kerapacEcho2)
        KerapacCore.sleepTickRandom(5)
        API.DoAction_NPC(0x2a, API.OFF_ACT_InteractNPC_route, { clones[1].Id }, 10)
        KerapacCore.sleepTickRandom(3)
        Inventory:Eat("Powerburst of vitality")
        KerapacCore.sleepTickRandom(1)
        API.DoAction_NPC(0x2a, API.OFF_ACT_InteractNPC_route, { clones[1].Id }, 50)
    end
end

function KerapacCore.setupEchoLocations()
    KerapacCore.kerapacEcho1 = WPOINT.new(math.floor(KerapacCore.centerOfArenaPosition.x), math.floor(KerapacCore.centerOfArenaPosition.y + 9), math.floor(KerapacCore.centerOfArenaPosition.z))
    KerapacCore.kerapacEcho2 = WPOINT.new(math.floor(KerapacCore.centerOfArenaPosition.x), math.floor(KerapacCore.centerOfArenaPosition.y - 9), math.floor(KerapacCore.centerOfArenaPosition.z))
end

function KerapacCore.hardModePhase4Setup()
    if(KerapacCore.isPhase4SetupComplete)then return end
    KerapacCore.sleepTickRandom(3)
    local clones = API.GetAllObjArray1({Data.playerClone}, 60, {1})
    local echoes = API.GetAllObjArray1({Data.kerapacClones}, 60, {1})
    if not (#clones > 0) and not (#echoes > 0) then return end
    KerapacCore.isPhasing = false
    KerapacCore.canAttack = true
    KerapacCore.enableMagePray()
    KerapacCore.setupEchoLocations()
    KerapacCore.setupPlayerTank(clones)
    KerapacCore.isPhase4SetupComplete = true
end

function KerapacCore.HandlePhase4()
    if not (API.Get_tick() - KerapacCore.phase4Ticks > 1) then return end
    local surgeAB = API.GetABs_name("Surge")
    local echoes = API.GetAllObjArray1({Data.kerapacClones}, 100, {1})
    local killableEchoes = {}
    for i = 1, #echoes do
        if echoes[i].Anim ~= 33493 
        and echoes[i].Anim ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
        and echoes[i].Anim ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
        and echoes[i].Anim ~= Data.bossStateEnum.JUMP_ATTACK_LANDED then
            table.insert(killableEchoes, echoes[i])
        end
    end
    local targetInfo = API.ReadTargetInfo()

    if #killableEchoes == 3 and targetInfo.Target_Name ~= "Echo of Kerapac" then
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10)
    elseif #killableEchoes == 2 and targetInfo.Hitpoints == 100000 then
        KerapacCore.log("amount of killable echoes "..#killableEchoes)
        API.DoAction_Tile(KerapacCore.kerapacEcho1)
        KerapacCore.sleepTickRandom(2)
        API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
        API.DoAction_Tile(KerapacCore.kerapacEcho1)
        KerapacCore.sleepTickRandom(1)
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10)
    elseif #killableEchoes == 1 and targetInfo.Hitpoints == 100000 then
        KerapacCore.log("amount of killable echoes "..#killableEchoes)
        API.DoAction_Tile(KerapacCore.kerapacEcho2)
        KerapacCore.sleepTickRandom(2)
        API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
        API.DoAction_Tile(KerapacCore.kerapacEcho2)
        KerapacCore.sleepTickRandom(1)
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10)
    elseif #killableEchoes == 0 then
        KerapacCore.attackKerapac()
    end

    if(#killableEchoes > 0) then
        KerapacCore.applyVulnerability()
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10)
    end

    KerapacCore.phase4Ticks = API.Get_tick()
end

function KerapacCore.castNextAbility()
    initAbilities()
    local attackTick = API.VB_FindPSettinOrder(4501).state
    if attackTick == KerapacCore.lastAttackTick then return end
    if not (API.Get_tick() - KerapacCore.globalCooldownTicks > 2) then return end
    if not KerapacCore.canAttack then return end
    KerapacCore.hasBloatDebuff = false
    KerapacCore.necrosisStacks = API.VB_FindPSettinOrder(10986).state
    KerapacCore.residualSoulsStack = API.VB_FindPSettinOrder(11035).state
    KerapacCore.lastAttackTick = attackTick
    KerapacCore.globalCooldownTicks = API.Get_tick()

    if Data.extraAbilities.conjureUndeadArmyAbility.AB.enabled and API.VB_FindPSettinOrder(10994).state < 1 and API.VB_FindPSettinOrder(11018).state < 1 and API.VB_FindPSettinOrder(11006).state < 1 then
        KerapacCore.useConjureUndeadArmy()
        return
    end

    if Data.extraAbilities.conjureSkeletonWarriorAbility.AB.enabled and API.VB_FindPSettinOrder(10994).state < 1 then
        KerapacCore.useConjureSkeletonWarrior()
        return
    end

    if Data.extraAbilities.conjureVengefulGhostAbility.AB.enabled and API.VB_FindPSettinOrder(11018).state < 1 then
        KerapacCore.useConjureVengefulGhost()
        return
    end

    if Data.extraAbilities.conjurePutridZombieAbility.AB.enabled and API.VB_FindPSettinOrder(11006).state < 1 then
        KerapacCore.useConjurePutridZombie()
        return
    end

    if Data.extraAbilities.darknessAbility.AB.cooldown_timer <= 0 and not API.Buffbar_GetIDstatus(Data.extraAbilities.darknessAbility.buffId).found and KerapacCore.hasDarkness then
        KerapacCore.useDarkness()
    end

    if Data.extraAbilities.invokeDeathAbility.AB.cooldown_timer <= 0 and not KerapacCore.hasDeathInvocation() and not KerapacCore.hasMarkOfDeath() and KerapacCore.hasDeathInvocation then
        KerapacCore.useInvokeDeath()
    end

    if (KerapacCore.kerapacPhase < 3) and Data.extraAbilities.splitSoulAbility.AB.cooldown_timer <= 0 and Data.extraAbilities.splitSoulAbility.AB.id > 0 and Data.extraAbilities.splitSoulAbility.AB.enabled and not API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then
        KerapacCore.useSplitSoul()
    end
    if Data.extraAbilities.commandSkeletonWarriorAbility.AB.cooldown_timer <= 0 and Data.extraAbilities.commandSkeletonWarriorAbility.AB.enabled then
        KerapacCore.useCommandSkeletonWarrior()
        return
    end

    if Data.extraAbilities.commandVengefulGhostAbility.AB.cooldown_timer <= 0 and Data.extraAbilities.commandVengefulGhostAbility.AB.enabled then
        KerapacCore.useCommandVengefulGhost()
        return
    end

    if Data.extraAbilities.livingDeathAbility.AB.cooldown_timer <= 0 
    and API.GetAddreline_() >= Data.extraAbilities.livingDeathAbility.threshold 
    and not KerapacCore.isPhasing 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.livingDeathAbility.AB.id).found then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        end
        KerapacCore.useLivingDeathAbility()
        return
    end

    if Data.extraAbilities.immortalityAbility.AB.cooldown_timer <= 0 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED
    and not KerapacCore.islightningPhase
    and not KerapacCore.isPhasing
    and KerapacCore.kerapacPhase >= 4
    and API.GetAddreline_() >= Data.extraAbilities.immortalityAbility.threshold then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        end
        KerapacCore.useImmortalityAbility()
        return
    end

    if Data.extraAbilities.deathSkullsAbility.AB.cooldown_timer <= 0 and API.GetAddreline_() >= Data.extraAbilities.deathSkullsAbility.threshold and not KerapacCore.isPhasing then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        end
        KerapacCore.useDeathSkullsAbility()
        return
    end

    if Data.extraAbilities.devotionAbility.AB.cooldown_timer <= 0 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED
    and not KerapacCore.islightningPhase
    and not KerapacCore.isPhasing
    and API.GetAddreline_() >= Data.extraAbilities.devotionAbility.threshold then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        end
        KerapacCore.useDevotionAbility()
        return
    end
    if Data.extraAbilities.debilitateAbility.AB.cooldown_timer <= 0 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED
    and not KerapacCore.isPhasing
    and API.GetAddreline_() >= Data.extraAbilities.debilitateAbility.threshold then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        elseif KerapacCore.islightningPhase then
            KerapacCore.useDebilitateAbility()
            return 
        end
    end

    if Data.extraAbilities.reflectAbility.AB.cooldown_timer <= 0 
    and API.GetAddreline_() >= Data.extraAbilities.reflectAbility.threshold
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found 
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED 
    and not KerapacCore.isPhasing then
        if KerapacCore.kerapacPhase >= 4 and API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time" then
            if API.GetHPrecent() > 70 then
                KerapacCore.useWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                KerapacCore.eatFood()
                Data.emergencyEatThreshold = oldThreshold
                KerapacCore.useWarpTime()
            end
        elseif KerapacCore.islightningPhase then
            KerapacCore.useReflectAbility()
            return
        end
    end

    if Data.extraAbilities.resonanceAbility.AB.cooldown_timer <= 0 and not KerapacCore.isPhasing
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR
    and KerapacCore.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED 
    and KerapacCore.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE
    and KerapacCore.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE
    and API.GetHPrecent() <= 80 then
        KerapacCore.useResonanceAbility()
        KerapacCore.isResonanceEnabled = true
        return
    end

    if Data.extraAbilities.fingerOfDeathAbility.AB.cooldown_timer <= 0 and KerapacCore.necrosisStacks > 5 and not KerapacCore.isPhasing then
        KerapacCore.useFingerOfDeathAbility()
        return
    end

    if Data.extraAbilities.volleyOfSoulsAbility.AB.cooldown_timer <= 0 and KerapacCore.residualSoulsStack > 2 and not KerapacCore.isPhasing then
        KerapacCore.useVolleyOfSoulsAbility()
        return
    end

    if Data.extraAbilities.touchOfDeathAbility.AB.cooldown_timer <= 0 then
        KerapacCore.useTouchOfDeathAbility()
        return
    end

    if Data.extraAbilities.soulSapAbility.AB.cooldown_timer <= 0 then
        KerapacCore.useSoulSapAbility()
        return
    end

    if Data.extraAbilities.sacrificeAbility.AB.cooldown_timer <= 0 and not KerapacCore.isPhasing then
        KerapacCore.useSacrificeAbility()
        return
    end

    if Data.extraAbilities.resonanceAbility.AB.cooldown_timer > 0
    and Data.extraAbilities.preparationAbility.AB.cooldown_timer <= 0 then
        KerapacCore.usePreparationAbility()
        return
    end

    KerapacCore.log("Literally nothing to do so guess I'll do an auto attack")
end

function KerapacCore.handleResonance()
    if not KerapacCore.isResonanceEnabled and not (API.Get_tick() - KerapacCore.resonanceTicks > 2) then 
        if not KerapacCore.isMagePrayEnabled and not KerapacCore.isMeleePrayEnabled and not KerapacCore.isSoulSplitEnabled then
            KerapacCore.enableMagePray()
        end
        return 
    end
    if API.Buffbar_GetIDstatus(Data.extraAbilities.resonanceAbility.buffId).found then
        if Data.overheadCursesBuffs.SoulSplit.AB.enabled and not KerapacCore.isSoulSplitEnabled then
            KerapacCore.enableSoulSplit()
        elseif KerapacCore.isMagePrayEnabled then
            KerapacCore.disableMagePray()
        end
    else
        KerapacCore.isResonanceEnabled = false
    end
    KerapacCore.resonanceTicks = API.Get_tick()
end

function KerapacCore.managePlayer()
    KerapacCore.castNextAbility()
    KerapacCore.handleResonance()
    KerapacCore.applyVulnerability()
    KerapacCore.handleSpecialSummoning()
    KerapacCore.eatFood()
    KerapacCore.drinkPrayer()
    KerapacCore.enablePassivePrayer()
    KerapacCore.renewFamiliar()
    KerapacCore.checkForStun()
    KerapacCore.playerDied()
end

function KerapacCore.manageBuffs()
    if API.Get_tick() - KerapacCore.buffCheckCooldown <= 10  then return end

    if KerapacCore.hasOverload then
        KerapacCore.drinkOverload()
    end
    
    if KerapacCore.hasWeaponPoison then
        KerapacCore.drinkWeaponPoison()
    end

    if KerapacCore.isScriptureEquipped and not KerapacCore.hasScriptureBuff then
        KerapacCore.enableScripture(KerapacCore.scripture)
    end

    KerapacCore.buffCheckCooldown = API.Get_tick()
end

function KerapacCore.warsTeleport()
    API.DoAction_Ability("War's Retreat", 1, API.OFF_ACT_GeneralInterface_route, false)
    KerapacCore.sleepTickRandom(10)
end

function KerapacCore.checkStartLocation()
    if not (API.Dist_FLP(FFPOINT.new(3299, 10131, 0)) < 30) then
        KerapacCore.log("Teleport to War's")
        KerapacCore.warsTeleport()
    else
        KerapacCore.log("Already in War's")
        KerapacCore.isInWarsRetreat = true
        KerapacCore.sleepTickRandom(2)
    end
end

function KerapacCore.summonFamiliar()
    if not Familiars:HasFamiliar() and Inventory:ContainsAny(Data.summoningPouches) then
        KerapacCore.log("Summoning familiar " .. KerapacCore.whichFamiliar())
        Inventory:DoAction(KerapacCore.whichFamiliar(), 1, API.OFF_ACT_GeneralInterface_route)
        KerapacCore.isFamiliarSummoned = true
        KerapacCore.sleepTickRandom(1)
    else
        KerapacCore.log("familiar is summoned or pouch in inventory")
    end
end

function KerapacCore.setupAutoFire()
    if Familiars:HasFamiliar() and not KerapacCore.isAutoFireSetup then
        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,74,-1,API.OFF_ACT_GeneralInterface_route)
        KerapacCore.sleepTickRandom(2)
        API.KeyPress_(0x01)
        API.KeyPress_2(0x0D)
        KerapacCore.log("Setting up auto fire of scrolls")
        KerapacCore.isAutoFireSetup = true
    else
        KerapacCore.log("auto fire not setup")
    end
end

function KerapacCore.storeScrollsInFamiliar()
    if Familiars:HasFamiliar() and KerapacCore.isAutoFireSetup then
        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,78,-1,API.OFF_ACT_GeneralInterface_route)
        KerapacCore.log("Storing scrolls in familiar")
        KerapacCore.sleepTickRandom(1)
    end
end

function KerapacCore.renewFamiliar()
    if API.Buffbar_GetIDstatus(26095).found then
        local timeRemaining = tonumber(string.match(API.Buffbar_GetIDstatus(26095).text, "(-?%d+%.?%d*)"))
        if timeRemaining <= 1 then
            if Familiars:HasFamiliar() then
                if(Inventory:ContainsAny(Data.summoningPouches)) then
                    API.DoAction_Interface(0xffffffff,0xffffffff,1,662,53,-1,API.OFF_ACT_GeneralInterface_route)
                    KerapacCore.sleepTickRandom(1)
                    KerapacCore.log("Renewing familiar")
                end
            end
        end
    end
end

function KerapacCore.attackKerapac()
    API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { KerapacCore.getKerapacInformation().Id }, 50)
end

function KerapacCore.handleCombatMode()
    if KerapacCore.isFullManualEnabled then return end
    if API.VB_FindPSettinOrder(627, 0).state == 1073750353 then
        KerapacCore.isFullManualEnabled = true
        KerapacCore.sleepTickRandom(1)
    else
        API.DoAction_Interface(0xffffffff,0xffffffff,4,1430,265,-1,API.OFF_ACT_GeneralInterface_route)
        KerapacCore.sleepTickRandom(1)
    end
end

function KerapacCore.HandlePrayerRestore()
    if API.GetPrayPrecent() < 100 or API.GetSummoningPoints_() < 60 then
        KerapacCore.log("Restoring prayer at Altar of War")
        API.DoAction_Object1(0x3d, API.OFF_ACT_GeneralObject_route0, { 114748 }, 50)
        API.WaitUntilMovingEnds(10, 4)
    end
    KerapacCore.isRestoringPrayer = true
end

function KerapacCore.HandleBanking()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { 114750 }, 50)
    API.WaitUntilMovingEnds(10, 4)
    KerapacCore.handleBankPin()
    KerapacCore.log("Withdraw last quick preset")
    KerapacCore.isBanking = true
end

function KerapacCore.prepareForBattle()
    KerapacCore.summonFamiliar()
    KerapacCore.renewFamiliar()
    KerapacCore.setupAutoFire()
    KerapacCore.storeScrollsInFamiliar()
    KerapacCore.checkAvailableBuffs()
    KerapacCore.sleepTickRandom(1)
    
    KerapacCore.log(string.format("Do we have the following buffs: \nOverloads: %s\nWeaponPoison %s\nDebilitate %s\nDevotion %s\nDarkness %s\nInvoke Death %s\nScripture Buff %s",
        KerapacCore.hasOverload, KerapacCore.hasWeaponPoison, KerapacCore.hasDebilitate, KerapacCore.hasDevotion, KerapacCore.hasDarkness, KerapacCore.hasInvokeDeath, KerapacCore.isScriptureEquipped))

    KerapacCore.log(string.format("\nFood: %s\nEmergency Food: %s\nEmergency Drink %s",
    KerapacCore.whichFood(), KerapacCore.whichEmergencyFood(), KerapacCore.whichEmergencyDrink()))
    if not Inventory:ContainsAny(Data.foodItems) and not Inventory:ContainsAny(Data.emergencyFoodItems) and not Inventory:ContainsAny(Data.emergencyDrinkItems) then
        KerapacCore.log("No food items in inventory", "WARN")
        KerapacCore.stopScript()
    end
    
    KerapacCore.isPrepared = true
end

function KerapacCore.goThroughPortal()
    KerapacCore.log("Go through portal")
    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 121019 }, 50)
    API.WaitUntilMovingEnds(20, 4)
    KerapacCore.sleepTickRandom(5)
    
    local colosseum = API.GetAllObjArray1({120046}, 30, {12})
    if #colosseum > 0 then
        KerapacCore.isPortalUsed = true
        KerapacCore.log("At Colosseum")
    end
end

function KerapacCore.HandleSetupInstance()
    KerapacCore.log("Setting max players")
    API.DoAction_Interface(0x24,0xffffffff,1,1591,72,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(2)
    API.KeyPress_(0x3)
    API.KeyPress_2(0x0D)
    KerapacCore.log("Setting min level to 1")
    API.DoAction_Interface(0x24,0xffffffff,1,1591,81,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(2)
    API.KeyPress_(0x1)
    API.KeyPress_2(0x0D)
    KerapacCore.log("Setting FFA")
    API.DoAction_Interface(0xffffffff,0xffffffff,1,1591,36,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(2)
    API.DoAction_Interface(0xffffffff,0xffffffff,1,1591,36,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(2)
    API.DoAction_Interface(0xffffffff,0xffffffff,1,1591,36,-1,API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(2)
    KerapacCore.isSetupFirstInstance = true
end

function KerapacCore.HandleJoinPlayer(partyLeader)
    if KerapacCore.isInArena then KerapacCore.log("Already in arena") return end
    for i = 1, #partyLeader do
        partyLeader = string.upper(partyLeader)
        local char = partyLeader:sub(i, i)
        local byte = string.byte(char)
        local hex = string.format("%02X", byte)
        if KerapacCore.isInArena then KerapacCore.log("Already in arena") return end
        API.KeyPress_2("0x"..hex)
    end
    if KerapacCore.isInArena then KerapacCore.log("Already in arena") return end
    API.KeyPress_2(0x0D)
    KerapacCore.sleepTickRandom(2)
end

function KerapacCore.HandleHardMode()
    if KerapacCore.isHardMode then
        if API.ScanForInterfaceTest2Get(false, { { 1591,15,-1,0 }, { 1591,17,-1,0 }, { 1591,41,-1,0 }, { 1591,12,-1,0 } })[1].textids == "Kerapac" then
            KerapacCore.log("Time to lock in")
            API.DoAction_Interface(0x24,0xffffffff,1,1591,4,-1,API.OFF_ACT_GeneralInterface_route)
        end
    end
end

function KerapacCore.HandleStartFight() 
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(3)
end

function KerapacCore.goThroughGate()
    KerapacCore.log("Click on Colosseum")
    if KerapacCore.isInParty then
        if KerapacCore.isPartyLeader and not KerapacCore.isSetupFirstInstance then
            API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)
            KerapacCore.sleepTickRandom(2)
            KerapacCore.HandleSetupInstance()
            KerapacCore.HandleHardMode()
            KerapacCore.HandleStartFight()
            KerapacCore.sleepTickRandom(10)
        elseif KerapacCore.isPartyLeader and KerapacCore.isSetupFirstInstance then
            API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)
            KerapacCore.sleepTickRandom(2)
            KerapacCore.HandleHardMode()
            KerapacCore.HandleStartFight()
        elseif not KerapacCore.isPartyLeader then
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route1,{ 120046 },50);
            KerapacCore.sleepTickRandom(2)
            KerapacCore.HandleJoinPlayer(Data.partyLeader)
        end
    else
        API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)
        KerapacCore.sleepTickRandom(2)
        KerapacCore.HandleHardMode()
        KerapacCore.HandleStartFight() 
    end

    local gate = API.GetAllObjArray1({120047}, 30, {12})
    if #gate > 0 then
        KerapacCore.isInArena = true
        KerapacCore.log("In Colosseum")
    end
end

function KerapacCore.RemoveDuplicates(tbl)
    local hash, result = {}, {}
    for _, v in ipairs(tbl) do
        if not hash[v] then
            hash[v] = true
            table.insert(result, v)
        end
    end
    return result
end

function KerapacCore.CheckTables(tbl1, tbl2)
    local freq1, freq2 = {}, {}

    for _, v in ipairs(tbl1) do
        freq1[v] = (freq1[v] or 0) + 1
    end

    for _, v in ipairs(tbl2) do
        freq2[v] = (freq2[v] or 0) + 1
    end
    
    for k, v in pairs(freq1) do
        if freq2[k] ~= v then
            return false
        end
    end
    
    for k, v in pairs(freq2) do
        if freq1[k] ~= v then
            return false
        end
    end
    
    return true
end

function KerapacCore.WaitForPartyToBeComplete()
    KerapacCore.log("Waiting for team to be complete")
    local players = API.GetAllObjArray1({1}, 30, {2})
    local playersInVicinity = {}
    local partyMembers = {}
    for i = 1, #players do
        local player = players[i]
        table.insert(playersInVicinity, string.lower(player.Name))
    end
    for i = 1, #Data.partyMembers do
        table.insert(partyMembers, string.lower(Data.partyMembers[i]))
    end
    playersInVicinity = KerapacCore.RemoveDuplicates(playersInVicinity)
    KerapacCore.isTeamComplete = KerapacCore.CheckTables(playersInVicinity, Data.partyMembers)
    KerapacCore.log("Found all team members: "..tostring(KerapacCore.isTeamComplete))
    KerapacCore.sleepTickRandom(1)
end

function KerapacCore.BeginFight()
    KerapacCore.log("Start encounter")
    KerapacCore.playerPosition = API.PlayerCoord()
    KerapacCore.centerOfArenaPosition = FFPOINT.new(KerapacCore.playerPosition.x - 7, KerapacCore.playerPosition.y, 0)
    KerapacCore.startLocationOfArena = FFPOINT.new(KerapacCore.playerPosition.x - 25, KerapacCore.playerPosition.y, 0)

    if API.Container_Get_s(94, 55189) or API.Container_Get_s(94, 52504) then
        Data.extraAbilities.deathSkullsAbility.threshold = 60
        KerapacCore.log("Ooo look at you, fancy boy")
    end
        
    KerapacCore.log("Reset compass")
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1919, 2, -1, API.OFF_ACT_GeneralInterface_route)
    KerapacCore.sleepTickRandom(1)
        
    KerapacCore.log("Move to spot")
    KerapacCore.enableMagePray()
    API.DoAction_TileF(KerapacCore.startLocationOfArena)
    API.WaitUntilMovingEnds(20, 4)
end

function KerapacCore.startEncounter()
    if KerapacCore.isInParty then
        if not KerapacCore.isTeamComplete then
            KerapacCore.WaitForPartyToBeComplete()
        else
            KerapacCore.BeginFight()
        end
    else
        KerapacCore.BeginFight()
    end
end

function KerapacCore.checkKerapacExists()
    if KerapacCore.getKerapacInformation().Action == "Attack" then
        KerapacCore.isInBattle = true
        KerapacCore.isFightStarted = true
        KerapacCore.enableMagePray()
        KerapacCore.attackKerapac()
        KerapacCore.log("Fight started")
    end
end

function KerapacCore.startPhaseTransition()
    KerapacCore.kerapacPhase = KerapacCore.kerapacPhase + 1
    KerapacCore.isPhasing = true
    KerapacCore.log("Entering Phase " .. KerapacCore.kerapacPhase)
end

function KerapacCore.endPhaseTransition()
    KerapacCore.attackKerapac()
    KerapacCore.isPhasing = false
    KerapacCore.log("Resuming battle")
end

function KerapacCore.handlePhaseTransitions(bossLife)
    if bossLife <= Data.phaseTransitionThreshold and KerapacCore.kerapacPhase < 4 and not KerapacCore.isPhasing then
        KerapacCore.startPhaseTransition()
    elseif bossLife > Data.phaseTransitionThreshold and KerapacCore.isPhasing then
        KerapacCore.endPhaseTransition()
    end
end

function KerapacCore.handleBossLoot()
    local guaranteedDrop = {51804, 51805}
    local lootPiles = API.GetAllObjArray1(guaranteedDrop, 20, {3})
    
    if #lootPiles > 0 then
        if not API.LootWindowOpen_2() then 
            KerapacCore.log("Opening loot window")
            API.DoAction_G_Items1(0x2d, guaranteedDrop, 30)
            API.WaitUntilMovingEnds(6,10)
        end
        
        if API.LootWindowOpen_2() and (API.LootWindow_GetData()[1].itemid1 > 0) and not KerapacCore.isLooted then 
            local lootInterface = API.ScanForInterfaceTest2Get(true, { 
                { 1622,4,-1,0 }, 
                { 1622,6,-1,0 }, 
                { 1622,1,-1,0 }, 
                { 1622,11,-1,0 } 
            })
            
            local lootInWindow = {}
            for _,value in ipairs(lootInterface) do
                if value.itemid1 ~= -1 then
                    table.insert(lootInWindow, value.itemid1)
                end
            end
            
            local inventorySlotsRemaining = Inventory:FreeSpaces() - #lootInWindow
            
            if inventorySlotsRemaining < 0 then
                local slotsNeeded = -inventorySlotsRemaining
                KerapacCore.log("Need to free " .. slotsNeeded .. " slots to collect all loot")
                
                for i = 1, slotsNeeded do
                    local foodItem = KerapacCore.whichFood()
                    local emergencyFoodItem = KerapacCore.whichEmergencyFood()
                    local emergencyDrinkItem = KerapacCore.whichEmergencyDrink()
                    
                    if foodItem ~= "" then
                        KerapacCore.log("Eating " .. foodItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(foodItem)
                        KerapacCore.sleepTickRandom(3)
                    elseif emergencyFoodItem ~= "" then
                        KerapacCore.log("Eating emergency food " .. emergencyFoodItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(emergencyFoodItem)
                        KerapacCore.sleepTickRandom(3)
                    elseif emergencyDrinkItem ~= "" then
                        KerapacCore.log("Drinking emergency " .. emergencyDrinkItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(emergencyDrinkItem)
                        KerapacCore.sleepTickRandom(3)
                    else
                        KerapacCore.log("No more consumable items to use, can't collect all loot")
                        API.DoAction_LootAll_Button()
                        KerapacCore.isLooted = true
                        break
                    end
                end
            else
                KerapacCore.log("Get loot")
                API.DoAction_LootAll_Button()
                KerapacCore.isLooted = true
            end
        end
        KerapacCore.sleepTickRandom(1)
    end
end

function KerapacCore.handleBossDeath()
    KerapacCore.disableMagePray()
    KerapacCore.disableSoulSplit()
    KerapacCore.disablePassivePrayer()
    KerapacCore.isInBattle = false
    KerapacCore.isTimeToLoot = true
    
    if KerapacCore.playerPosition then
        local lootPosition = FFPOINT.new(KerapacCore.playerPosition.x + Data.lootPosition, KerapacCore.playerPosition.y, 0)
        API.DoAction_TileF(lootPosition)
        KerapacCore.log("Moving to loot")
        API.WaitUntilMovingEnds(20, 4)
    end
end

function KerapacCore.handleBossPhase()
    local kerapacInfo = KerapacCore.getKerapacInformation()
    
    if not kerapacInfo then
        KerapacCore.log("Kerapac information not available")
        return
    end
    
    if kerapacInfo.Life <= 0 then
        KerapacCore.log("Preparing to loot")
        KerapacCore.handleBossDeath()
        return
    end
    
    KerapacCore.handlePhaseTransitions(kerapacInfo.Life)
end

function KerapacCore.handleStateChange(currentAnimation)
    local newState = KerapacCore.getBossStateFromAnimation(currentAnimation)
    
    if newState == nil then
        return
    end
    
    if newState ~= KerapacCore.currentState then
        KerapacCore.log("State changed to: " .. Data.bossStateEnum[newState].name)
        KerapacCore.currentState = newState
        KerapacCore.handleCombat(newState)
    end
end

function KerapacCore.handleCombat(state)
    if (KerapacCore.isFightStarted) then
        if state == Data.bossStateEnum.BASIC_ATTACK.name then
            KerapacCore.enableMagePray()
        end
        
        if state == Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name and not KerapacCore.isRiftDodged and not KerapacCore.isPhasing then
            if KerapacCore.islightningPhase then
                KerapacCore.islightningPhase = false
            end
            KerapacCore.canAttack = false
            KerapacCore.sleepTickRandom(2)
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(KerapacCore.getKerapacPositionFFPOINT().x), math.floor(KerapacCore.getKerapacPositionFFPOINT().y), math.floor(KerapacCore.getKerapacPositionFFPOINT().z)))
            KerapacCore.enableMagePray()
            KerapacCore.isRiftDodged = true
            KerapacCore.log("Moved player under Kerapac")
        end
        
        if state == Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name and KerapacCore.isRiftDodged then
            KerapacCore.sleepTickRandom(2)
            KerapacCore.attackKerapac()
            KerapacCore.isRiftDodged = false
            KerapacCore.canAttack = true
            KerapacCore.enableMagePray()
            KerapacCore.log("Attacking Kerapac")
        end
        
        if state == Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name and KerapacCore.isJumpDodged then
            KerapacCore.isJumpDodged = false
            KerapacCore.attackKerapac()
            KerapacCore.log("Preparing for jump attack")
            KerapacCore.enableMeleePray()
            KerapacCore.buffCheckCooldown = API.Get_tick()
        end
        
        if state == Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name and not KerapacCore.isJumpDodged then
            KerapacCore.enableMeleePray()
            KerapacCore.isJumpDodged = true
            KerapacCore.attackKerapac()
            KerapacCore.sleepTickRandom(1)
            
            local surgeAB = API.GetABs_name("Surge")
            API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
            KerapacCore.sleepTickRandom(1)
            
            KerapacCore.attackKerapac()
            KerapacCore.buffCheckCooldown = API.Get_tick()
            KerapacCore.log("Dodge jump attack")
        end
        
        if state == Data.bossStateEnum.JUMP_ATTACK_LANDED.name and KerapacCore.getKerapacInformation().Distance < 4 then
            KerapacCore.enableMeleePray()
            API.DoAction_TileF(KerapacCore.centerOfArenaPosition)
            KerapacCore.sleepTickRandom(1)
            KerapacCore.attackKerapac()
        end

        if state == Data.bossStateEnum.LIGHTNING_ATTACK.name and not KerapacCore.islightningPhase then
            KerapacCore.log("Lightning Phase active ------------")
            local surgeAB = API.GetABs_name("Surge")
            API.DoAction_Tile(WPOINT.new(KerapacCore.playerPosition.x - 12, KerapacCore.playerPosition.y, 0))
            KerapacCore.sleepTickRandom(3)
            KerapacCore.attackKerapac()
            KerapacCore.islightningPhase = true
        end
    end
end

function KerapacCore.handleBossReset()
    KerapacCore.isFightStarted = false
    KerapacCore.isRiftDodged = false
    KerapacCore.isJumpDodged = true
    KerapacCore.isInBattle = false
    KerapacCore.isTimeToLoot = false
    KerapacCore.isInWarsRetreat = false
    KerapacCore.isPrepared = false
    KerapacCore.isBanking = false
    KerapacCore.isRestoringPrayer = false
    KerapacCore.isInArena = false
    KerapacCore.isLooted = false
    KerapacCore.isPortalUsed = false
    KerapacCore.isPhasing = false
    KerapacCore.isMovedToCenter = false
    KerapacCore.islightningPhase = false
    KerapacCore.isPlayerDead = false
    KerapacCore.isTeamComplete = false
    KerapacCore.isPhase4SetupComplete = false
    KerapacCore.isClonesSetup = false
    KerapacCore.isResonanceEnabled = false
    KerapacCore.isMagePrayEnabled = false
    KerapacCore.isSoulSplitEnabled = false
    
    KerapacCore.hasOverload = false
    KerapacCore.hasWeaponPoison = false
    KerapacCore.hasDebilitate = false
    KerapacCore.hasDevotion = false
    KerapacCore.hasDarkness = false
    KerapacCore.hasInvokeDeath = false
    
    KerapacCore.kerapacPhase = 1
    KerapacCore.log("Let's go again")
end

function KerapacCore.handleBankPin()
    if API.DoBankPin(Data.bankPin) then
        if Data.bankPin ~= nil then
            KerapacCore.log("No Bank Pin provided in KerapacData.lua", "ERROR")
        else
            return true
        end
    end
end

function KerapacCore.HandleStartButton()
    if not KerapacCore.startScript then
        if KerapacCore.StartButton.return_click then
            KerapacCore.StartButton.return_click = false
            KerapacCore.startScript = true
            KerapacCore.selectedPassive = KerapacCore.PassivesDropdown.stringsArr[tonumber(KerapacCore.PassivesDropdown.int_value) + 1]
            KerapacCore.isHardMode = KerapacCore.hardModeCheckBox.box_ticked
            if KerapacCore.selectedPrayerType == 0 then
                KerapacCore.selectedPrayerType = "Prayers"  
            elseif KerapacCore.selectedPrayerType == 1 then
                KerapacCore.selectedPrayerType = "Curses"  
            end
            if KerapacCore.isInParty then
                if KerapacCore.isPartyLeader then
                    Data.partyLeader = API.GetLocalPlayerName()
                elseif Data.partyLeader == nil then
                    KerapacCore.log("No party leader appointed in KerapacData.lua", "ERROR")
                    KerapacCore.stopScript()
                end
            end
            KerapacCore.Background.remove = true
            KerapacCore.StartButton.remove = true
            KerapacCore.PassivesDropdown.remove = true
            KerapacCore.hardModeCheckBox.remove = true
            KerapacCore.partyCheckBox.remove = true
            KerapacCore.partyLeaderCheckBox.remove = true
            KerapacCore.guiVisible = false
            KerapacCore.log("Script started")
            KerapacCore.log("Selected Prayer Type: " .. (KerapacCore.selectedPrayerType or "None"))
            KerapacCore.log("Selected Passive: " .. (KerapacCore.selectedPassive or "None"))
            KerapacCore.log("Hardmode on: " .. tostring(KerapacCore.isHardMode))
            KerapacCore.log("In a party?: " .. tostring(KerapacCore.isInParty))
            KerapacCore.log("Am I party leader?: " .. tostring(KerapacCore.isPartyLeader))
        end
    end
end

function KerapacCore.HandlePartyButton()
    KerapacCore.isInParty = KerapacCore.partyCheckBox.box_ticked
    KerapacCore.isPartyLeader = KerapacCore.partyLeaderCheckBox.box_ticked
    if KerapacCore.isInParty then
        API.DrawCheckbox(KerapacCore.partyLeaderCheckBox)
    else
        KerapacCore.partyLeaderCheckBox.remove = true
    end
end

function KerapacCore.HandleButtons()
    KerapacCore.HandleStartButton()
    KerapacCore.HandlePartyButton()
end

function KerapacCore.DrawButtons()
    API.DrawSquareFilled(KerapacCore.Background)
    API.DrawComboBox(KerapacCore.PassivesDropdown, false)
    API.DrawBox(KerapacCore.StartButton)
    API.DrawCheckbox(KerapacCore.hardModeCheckBox)
    API.DrawCheckbox(KerapacCore.partyCheckBox)
end

function KerapacCore.DrawGui()
    KerapacCore.DrawButtons()
    KerapacCore.HandleButtons()
end

function KerapacCore.avoidLightningBolts()
    local inDanger = false
    local closestBolt = nil
    local allLightningBolts = API.GetAllObjArray1({ 28071, 9216 }, 60, {1})
    
    KerapacCore.lightningDirections = {}
    for i = 1, #allLightningBolts do
        if allLightningBolts[i].Distance < Data.proximityThreshold then
            local direction = math.ceil(API.calculateOrientation(allLightningBolts[i].MemE))
            KerapacCore.addIfNotExists(KerapacCore.lightningDirections, direction)
        end
    end
    
    for i = 1, #allLightningBolts do
        if allLightningBolts[i].Distance < Data.distanceThreshold then
            inDanger = true
        end
    end

    if not inDanger and not KerapacCore.isAttackingKerapac then
        KerapacCore.isAttackingKerapac = true
        KerapacCore.attackKerapac()
    end

    if inDanger and API.Get_tick() - KerapacCore.avoidLightningTicks > Data.dodgeCooldown then
        KerapacCore.performDodge(KerapacCore.calculateSafePosition(KerapacCore.playerPosition))
    end
end

function KerapacCore.calculateSafePosition(playerPosition)
    if #KerapacCore.lightningDirections == 0 then
        return playerPosition
    end
    
    local safeDistance = 20
    local safestDirection = 0
    
    if #KerapacCore.lightningDirections == 1 then
        safestDirection = KerapacCore.lightningDirections[1]
        
        KerapacCore.log("Single lightning at " .. KerapacCore.lightningDirections[1] .. " moving to " .. safestDirection)
    else
        local vectorX, vectorY = 0, 0
        
        for _, direction in ipairs(KerapacCore.lightningDirections) do
            local adjustedDirection = direction
            if direction == 0 or direction == 1 then
                adjustedDirection = 360
            end

            local dirRadians = math.rad(adjustedDirection)
            vectorX = vectorX + math.sin(dirRadians)
            vectorY = vectorY + math.cos(dirRadians)
        end
        
        local avgDirection = 0
        if math.abs(vectorX) < 0.1 and math.abs(vectorY) < 0.1 then
            avgDirection = KerapacCore.lightningDirections[1]
            KerapacCore.log("Lightning directions nearly cancel getting behind first lightning at " .. KerapacCore.lightningDirections[1])
        else
            if vectorY > 0 then
                avgDirection = math.deg(math.atan(vectorX / vectorY))
            elseif vectorY < 0 then
                avgDirection = math.deg(math.atan(vectorX / vectorY)) + 180
            elseif vectorX > 0 then
                avgDirection = 90
            else
                avgDirection = 270 
            end
            avgDirection = (avgDirection) % 360
        end
        safestDirection = avgDirection
        
        KerapacCore.log("Multiple lightning directions average: " .. avgDirection .. " moving to: " .. safestDirection)
    end
    
    local safeRadians = math.rad(safestDirection)
    local safeX = playerPosition.x - safeDistance * math.sin(safeRadians)
    local safeY = playerPosition.y - safeDistance * math.cos(safeRadians)
    local safePosition = WPOINT.new(safeX, safeY, playerPosition.z)

    KerapacCore.log("Lightning directions: " .. table.concat(KerapacCore.lightningDirections, ", "))
    KerapacCore.log("player position x: " .. playerPosition.x .. " player position y: " .. playerPosition.y)
    KerapacCore.log("Adjusted game direction: " .. safestDirection)
    return safePosition
end

function KerapacCore.performDodge(safeWPOINT)
    local surgeAB = API.GetABs_name("Surge", true)
    local diveAB = API.GetABs_name("Dive", true)
    if (diveAB.cooldown_timer <= 0) then
        KerapacCore.log("Diving to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Dive_Tile(safeWPOINT)
    elseif (surgeAB.cooldown_timer <= 0) then
        KerapacCore.log("Surging to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Tile(safeWPOINT)
        KerapacCore.sleepTickRandom(1)
        API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
    else
        KerapacCore.log("Running to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Tile(safeWPOINT)
    end
    if KerapacCore.isAttackingKerapac then
        KerapacCore.isAttackingKerapac = false
    end
    KerapacCore.avoidLightningTicks = API.Get_tick()
end

function KerapacCore.addIfNotExists(array, value)
    value = value % 360
    for _, v in ipairs(array) do
        if v == value then
            return false
        end
    end
    table.insert(array, value)
    return true
end

return KerapacCore