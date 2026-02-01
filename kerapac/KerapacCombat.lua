local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")

local KerapacCombat = {}

function KerapacCombat:InitAbilities()
    Logger:Debug("Initializing abilities")
    
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
    
    Logger:Debug("Abilities initialized")
end

function KerapacCombat:GetKerapacInformation()
    return API.FindNPCbyName("Kerapac, the bound", 30)
end

function KerapacCombat:GetKerapacAnimation()
    local kerapacInfo = self:GetKerapacInformation()
    if kerapacInfo then
        return kerapacInfo.Anim
    end
    return nil
end

function KerapacCombat:GetKerapacPositionFFPOINT()
    local kerapacInfo = self:GetKerapacInformation()
    if kerapacInfo then
        return FFPOINT.new(kerapacInfo.Tile_XYZ.x, kerapacInfo.Tile_XYZ.y, kerapacInfo.Tile_XYZ.z)
    end
    return nil
end

function KerapacCombat:HasMarkOfDeath()
    return (API.VB_FindPSett(11303).state >> 7 & 0x1) == 1
end

function KerapacCombat:HasDeathInvocation()
    return API.Buffbar_GetIDstatus(30100).id > 0
end

local function isOnActionBar(ability)
    if not ability then return false end
    if not ability.AB then return false end
    return (ability.AB.slot or 0) ~= 0
end

function KerapacCombat:CheckAvailableBuffs()
    self:InitAbilities()
    State.hasOverload = Utils:WhichOverload() ~= ""
    State.hasWeaponPoison = Utils:WhichWeaponPoison() ~= ""
    State.hasAdrenalinePotion = Utils:WhichAdrenalinePotion() ~= ""
    State.hasDebilitate = isOnActionBar(Data.extraAbilities.debilitateAbility)
    State.hasDevotion = isOnActionBar(Data.extraAbilities.devotionAbility)
    State.hasReflect = isOnActionBar(Data.extraAbilities.reflectAbility)
    State.hasImmortality = isOnActionBar(Data.extraAbilities.immortalityAbility)

    if isOnActionBar(Data.extraAbilities.darknessAbility) then
        State.hasDarkness = Data.extraAbilities.darknessAbility.AB.enabled or false
    end

    if isOnActionBar(Data.extraAbilities.invokeDeathAbility) then
        State.hasInvokeDeath = Data.extraAbilities.invokeDeathAbility.AB.enabled or false
    end

    if isOnActionBar(Data.extraAbilities.splitSoulAbility) then
        State.hasSplitSoul = Data.extraAbilities.splitSoulAbility.AB.enabled or false
    end

    Utils:CheckForScripture()

    Logger:Debug("Buff check complete")
end

function KerapacCombat:CheckForDebilitateOnTarget()
    return API.TargetHasBuff("Debilitate")
end

function KerapacCombat:CheckForBloatOnTarget()
    return API.TargetHasBuff("Bloat")
end

function KerapacCombat:CheckForSmokeCloudOnTarget()
    return API.TargetHasBuff(Data.extraBuffs.smokeCloud.targetBuffId)
end

function KerapacCombat:UseSmokeCloud()
    if not Data.extraBuffSmokeCloud then return end
    if self:CheckForSmokeCloudOnTarget() then return end
    if not Data.extraBuffs.smokeCloud.AB or not Data.extraBuffs.smokeCloud.AB.enabled then return end
    API.DoAction_Ability_Direct(Data.extraBuffs.smokeCloud.AB, 1, API.OFF_ACT_GeneralInterface_route)
    Logger:Info("Casting Smoke Cloud")
end

function KerapacCombat:UsePowderOfPenance()
    if not Data.extraBuffPowderOfPenance then return end
    if API.Buffbar_GetIDstatus(Data.extraBuffs.powderOfPenance.buffId).found then return end
    if not Data.extraBuffs.powderOfPenance.AB or not Data.extraBuffs.powderOfPenance.AB.enabled then return end
    API.DoAction_Ability_Direct(Data.extraBuffs.powderOfPenance.AB, 1, API.OFF_ACT_GeneralInterface_route)
    Logger:Info("Using Powder of Penance")
end

function KerapacCombat:UsePrismOfRestoration()
    if not Data.extraBuffPrismOfRestoration then return end
    if not Familiars:HasFamiliar() then return end
    if not Data.extraBuffs.prismOfRestoration.AB or not Data.extraBuffs.prismOfRestoration.AB.enabled then return end
    local familiarHp = API.GetVarbitValue(19034)
    local familiarTimeLeft = API.GetVarbitValue(6055)
    if familiarHp >= Data.extraBuffPrismHpThreshold then return end
    if familiarTimeLeft <= 1 then return end
    API.DoAction_Ability_Direct(Data.extraBuffs.prismOfRestoration.AB, 1, API.OFF_ACT_GeneralInterface_route)
    Logger:Info("Casting Prism of Restoration (familiar HP: " .. familiarHp .. ", time left: " .. familiarTimeLeft .. "m)")
end

function KerapacCombat:UseCastFamiliarSpecial()
    if not Data.prebuffSummoning then return end
    if not Data.prebuffSummoningPouch then return end
    if not Familiars:HasFamiliar() then return end

    local pouch = Data.prebuffSummoningPouch
    local specialPoints = API.GetVarbitValue(26474)

    if string.find(pouch, "kal'gerion") then
        if not Data.extraBuffs.castFamiliarSpecial.AB or not Data.extraBuffs.castFamiliarSpecial.AB.enabled then return end
        if API.Buffbar_GetIDstatus(49416).found then return end
        if specialPoints < 30 then return end
        API.DoAction_Ability_Direct(Data.extraBuffs.castFamiliarSpecial.AB, 1, API.OFF_ACT_GeneralInterface_route)
        Logger:Info("Casting Kal'gerion Special (points: " .. specialPoints .. ")")
        return
    end

    if string.find(pouch, "hellhound") then
        if not Data.extraBuffs.castFamiliarSpecial.AB or not Data.extraBuffs.castFamiliarSpecial.AB.enabled then return end
        local familiarHp = API.GetVarbitValue(19034)
        if familiarHp >= 5000 then return end
        if specialPoints < 20 then return end
        API.DoAction_Ability_Direct(Data.extraBuffs.castFamiliarSpecial.AB, 1, API.OFF_ACT_GeneralInterface_route)
        Logger:Info("Casting Hellhound Special (HP: " .. familiarHp .. ", points: " .. specialPoints .. ")")
        return
    end
end

function KerapacCombat:UseSpiritualPrayerPotion()
    if not Data.prebuffSummoning then return end
    if not Data.prebuffSummoningPouch then return end
    if not Familiars:HasFamiliar() then return end

    local pouch = Data.prebuffSummoningPouch
    local specialPoints = API.GetVarbitValue(26474)

    local threshold = nil
    if string.find(pouch, "ripper") then
        if State.kerapacPhase < 3 then return end
        threshold = 20
    elseif string.find(pouch, "blood reaver") then
        threshold = 15
    else
        return
    end

    if specialPoints >= threshold then return end

    if not Data.extraBuffs.spiritualPrayerPotion.AB or not Data.extraBuffs.spiritualPrayerPotion.AB.enabled then return end

    API.DoAction_Ability_Direct(Data.extraBuffs.spiritualPrayerPotion.AB, 1, API.OFF_ACT_GeneralInterface_route)
    Logger:Info("Drinking Spiritual Prayer Potion (points: " .. specialPoints .. ", threshold: " .. threshold .. ")")
end

function KerapacCombat:CheckForSplitSoul()
    if API.Buffbar_GetIDstatus(30126).found and not State.isSoulSplitEnabled then
        self:EnableSoulSplit()
    end
end

function KerapacCombat:EnableMagePray()
    if API.Buffbar_GetIDstatus(30126).found then return end
    if API.GetPrayPrecent() <= 0 or State.isMagePrayEnabled then return end
    
    local overheadTable = nil
    if State.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif State.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        Logger:Error("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMage
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isMagePrayEnabled = true
            State.isMeleePrayEnabled = false
            State.isSoulSplitEnabled = false
        end
    else
        Logger:Error("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCombat:EnableMeleePray()
    if API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then return end
    if API.GetPrayPrecent() <= 0 then return end
    
    local overheadTable = nil
    if State.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif State.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        Logger:Error("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMelee
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isMagePrayEnabled = false
            State.isMeleePrayEnabled = true
            State.isSoulSplitEnabled = false
        end
    else
        Logger:Error("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCombat:EnableSoulSplit()
    if API.GetPrayPrecent() <= 0 then return end
    if State.isSoulSplitEnabled then return end
    
    local overheadTable = nil
    if State.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        Logger:Error("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.SoulSplit
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Activate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isMagePrayEnabled = false
            State.isMeleePrayEnabled = false
            State.isSoulSplitEnabled = true
        end
    else
        Logger:Error("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCombat:DisableSoulSplit()
    local overheadTable = nil
    if State.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        Logger:Error("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.SoulSplit
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Deactivate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isSoulSplitEnabled = false
        end
    else
        Logger:Error("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCombat:DisableMagePray()
    local overheadTable = nil
    if State.selectedPrayerType == "Prayers" then
        overheadTable = Data.overheadPrayersBuffs
    elseif State.selectedPrayerType == "Curses" then
        overheadTable = Data.overheadCursesBuffs
    else
        Logger:Error("Invalid prayer type selected.")
        return
    end
    
    local selectedOverheadData = overheadTable.PrayMage
    if selectedOverheadData then
        local buffId = selectedOverheadData.buffId
        local ability = selectedOverheadData.AB
        
        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Deactivate " .. selectedOverheadData.name)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isMagePrayEnabled = false
        end
    else
        Logger:Error("No valid overhead prayer selected or data not found.")
    end
end

function KerapacCombat:EnablePassivePrayer()
    if State.selectedPassive == Data.passiveBuffs.None.name then
        return
    end

    if State.isPassivePrayerEnabled then
        return
    end

    local selectedPassiveKey = nil
    for key, data in pairs(Data.passiveBuffs) do
        if data.name == State.selectedPassive then
            selectedPassiveKey = key
            break
        end
    end

    local selectedPassiveData = Data.passiveBuffs[selectedPassiveKey]
    if selectedPassiveData then
        local buffId = selectedPassiveData.buffId
        local ability = selectedPassiveData.AB

        if not API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 and API.GetPrayPrecent() > 0 then
            Logger:Info("Activate " .. State.selectedPassive)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isPassivePrayerEnabled = true
            Utils:SleepTickRandom(2)
        end
    else
        Logger:Error("No valid passive prayer selected or data not found.")
    end
end

function KerapacCombat:DisablePassivePrayer()
    local selectedPassiveKey = nil
    for key, data in pairs(Data.passiveBuffs) do
        if data.name == State.selectedPassive then
            selectedPassiveKey = key
            break
        end
    end

    local selectedPassiveData = Data.passiveBuffs[selectedPassiveKey]
    if selectedPassiveData then
        local buffId = selectedPassiveData.buffId
        local ability = selectedPassiveData.AB

        if API.Buffbar_GetIDstatus(buffId).found and ability.id ~= 0 then
            Logger:Info("Deactivate " .. State.selectedPassive)
            API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
            State.isPassivePrayerEnabled = false
        end
    else
        Logger:Error("No valid passive prayer selected or data not found.")
    end
end

function KerapacCombat:EnableScripture(book)
    if book.AB.enabled and not API.Buffbar_GetIDstatus(book.itemId).found then
        API.DoAction_Ability_check(book.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
        Logger:Info("Enabling Scripture")
        State.hasScriptureBuff = true
        Utils:SleepTickRandom(2)
    end
end

function KerapacCombat:CheckForStun()
    if API.DeBuffbar_GetIDstatus(Data.stun).found then
        Logger:Info("I am stunned")
        self:UseFreedomAbility()
        API.DoAction_TileF(State.centerOfArenaPosition)
        Utils:SleepTickRandom(2)
    end
end

function KerapacCombat:AttackKerapac()
    return API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { self:GetKerapacInformation().Id }, 100)
end

function KerapacCombat:ManageBuffs()
    if API.Get_tick() - State.buffCheckCooldown <= 3 then return end

    if State.hasOverload then
        Utils:DrinkOverload()
    end

    if State.hasWeaponPoison then
        Utils:DrinkWeaponPoison()
    end

    if State.isScriptureEquipped and not State.hasScriptureBuff then
        self:EnableScripture(State.scripture)
    end

    if Data.extraBuffPrismOfRestoration then
        self:UsePrismOfRestoration()
    end

    if Data.extraBuffPowderOfPenance then
        self:UsePowderOfPenance()
    end

    if Data.prebuffSummoning then
        self:UseCastFamiliarSpecial()
        self:UseSpiritualPrayerPotion()
    end

    State.buffCheckCooldown = API.Get_tick()
end

function KerapacCombat:HandleBossDeath()
    self:DisableMagePray()
    self:DisableSoulSplit()
    self:DisablePassivePrayer()
    State.isInBattle = false
    State.isTimeToLoot = true
    State.canAttack = false
    Data.totalKills = Data.totalKills + 1
end

function KerapacCombat:HandleBossPhase()
    local kerapacInfo = self:GetKerapacInformation()
    
    if not kerapacInfo then
        Logger:Warn("Kerapac information not available")
        return
    end

    if kerapacInfo.Life <= 50000 and State.kerapacPhase >= 4 then
        if Inventory:Contains("Luck of the Dwarves") then
            Inventory:Equip("Luck of the Dwarves")
        end
    end

    if kerapacInfo.Life <= 0 and State.kerapacPhase >= 4 then
        Logger:Info("Preparing to loot")
        self:HandleBossDeath()
    end
    
    State:HandlePhaseTransition(kerapacInfo.Life)
end

function KerapacCombat:ApplyVulnerability()
    if not Inventory:Contains("Vulnerability bomb") and not API.GetABs_name1("Vulnerability bomb").enabled then return end
    
    if API.ReadLpInteracting().Name ~= "Kerapac, the bound" and API.ReadLpInteracting().Name ~= "Echo of Kerapac" then return end
    
    if not (API.Get_tick() - State.vulnTicks > 12) then return end
    
    if State.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name or 
       State.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name or
       State.currentState == Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name or 
       State.currentState == Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name then 
        return 
    end
    
    local vulnAB = API.GetABs_name1("Vulnerability bomb")
    if not API.TargetHasBuff("Vulnerability") then
        API.DoAction_Ability_Direct(vulnAB, 1, API.OFF_ACT_GeneralInterface_route)
        if API.ReadLpInteracting().Name == "Kerapac, the bound" then
            self:AttackKerapac()
        elseif API.ReadLpInteracting().Name == "Echo of Kerapac" then
            local HardMode = require("kerapac/KerapacHardMode")
            HardMode:AttackEcho()
        end
        Logger:Info("Found your tickle spot")
    end
    
    State.vulnTicks = API.Get_tick()
end

function KerapacCombat:HandleCombatState(state)
    if not State.isFightStarted then
        return
    end
    
    if state == Data.bossStateEnum.BASIC_ATTACK.name then
        self:EnableMagePray()
    end
    
    if state == Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name and not State.isRiftDodged and not State.isPhasing then
        if State.islightningPhase then
            State.islightningPhase = false
        end
        State.canAttack = false
        Utils:SleepTickRandom(1)
        if not API.DoAction_Dive_Tile(WPOINT.new(math.floor(self:GetKerapacInformation().TileX / 512), math.floor(self:GetKerapacInformation().TileY / 512), math.floor(self:GetKerapacInformation().TileZ / 512))) then
            API.DoAction_Tile(WPOINT.new(math.floor(self:GetKerapacInformation().TileX / 512), math.floor(self:GetKerapacInformation().TileY / 512), math.floor(self:GetKerapacInformation().TileZ / 512)))
        end
        self:EnableMagePray()
        State.isRiftDodged = true
        Logger:Info("Moved player under Kerapac")
    end
    
    if state == Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name and State.isRiftDodged then
        Utils:SleepTickRandom(3)
        self:AttackKerapac()
        State.isRiftDodged = false
        State.canAttack = true
        self:EnableMagePray()
        Logger:Info("Attacking Kerapac")
    end
    
    if state == Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name and State.isJumpDodged then
        State.isJumpDodged = false
        self:AttackKerapac()
        Logger:Info("Preparing for jump attack")
        self:EnableMeleePray()
        State.buffCheckCooldown = API.Get_tick()
    end
    
    if state == Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name and not State.isJumpDodged then
        self:EnableMeleePray()
        State.isJumpDodged = true
        self:AttackKerapac()
        Utils:SleepTickRandom(1)
        
        local surgeAB = API.GetABs_name("Surge")
        API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
        Utils:SleepTickRandom(1)
        
        self:AttackKerapac()
        State.buffCheckCooldown = API.Get_tick()
        Logger:Info("Dodge jump attack")
    end
    
    if state == Data.bossStateEnum.JUMP_ATTACK_LANDED.name and self:GetKerapacInformation().Distance < 4 then
        self:EnableMeleePray()
        API.DoAction_TileF(State.centerOfArenaPosition)
        Utils:SleepTickRandom(1)
        self:AttackKerapac()
    end

    if state == Data.bossStateEnum.LIGHTNING_ATTACK.name and not State.islightningPhase then
        Logger:Info("Lightning Phase active ------------")
        local surgeAB = API.GetABs_name("Surge")
        API.DoAction_Tile(WPOINT.new(State.centerOfArenaPosition.x, State.centerOfArenaPosition.y, 1))
        Utils:SleepTickRandom(6)
        self:AttackKerapac()
        State.islightningPhase = true
        State.hasDodged = false
    end
end

function KerapacCombat:UseWarpTime()
    self:InitAbilities()
    if not (API.Get_tick() - State.warpTimeTicks > 64) then return end 
    if not (Data.extraAbilities.livingDeathAbility.AB.cooldown_timer <= 0)
    and not (API.GetAddreline_() > 99) then return end
    
    API.DoAction_Interface(0x2e, 0xffffffff, 1, 743, 1, -1, API.OFF_ACT_GeneralInterface_route)
    Logger:Info("Ultra Instinct mode Tu du tu du du du tu du..")
    State.warpTimeTicks = API.Get_tick()
end

function KerapacCombat:UseDarknessAbility()
    API.DoAction_Ability_check(Data.extraAbilities.darknessAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Concealing myself in the shadows")
end

function KerapacCombat:UseInvokeDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.invokeDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Die die die")
end

function KerapacCombat:UseSplitSoulAbility()
    API.DoAction_Ability_check(Data.extraAbilities.splitSoulAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Split my soul into pieces, this is my last resort")
    self:EnableSoulSplit()
end

function KerapacCombat:UseDevotionAbility()
    API.DoAction_Ability_check(Data.extraAbilities.devotionAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Please protect me")
end

function KerapacCombat:UseReflectAbility()
    API.DoAction_Ability_check(Data.extraAbilities.reflectAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Reflecting on life right now")
end

function KerapacCombat:UseImmortalityAbility()
    API.DoAction_Ability_check(Data.extraAbilities.immortalityAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Kill me, I dare you")
end

function KerapacCombat:UseBarricadeAbility()
    API.DoAction_Ability_check(Data.extraAbilities.barricadeAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Shield wall!")
end

function KerapacCombat:UseRejuvenateAbility()
    API.DoAction_Ability_check(Data.extraAbilities.rejuvenateAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Aaah.. Refreshing")
end

function KerapacCombat:UseResonanceAbility()
    API.DoAction_Ability_check(Data.extraAbilities.resonanceAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Resonate with me")
end

function KerapacCombat:UsePreparationAbility()
    API.DoAction_Ability_check(Data.extraAbilities.preparationAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Preparing to kill you")
end

function KerapacCombat:UseDebilitateAbility()
    if State.hasDebilitate then
        local hasDebilitateDebuff = self:CheckForDebilitateOnTarget()
        if not hasDebilitateDebuff and 
           State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name and 
           State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name then
            if API.DoAction_Ability_check(Data.extraAbilities.debilitateAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true) then
                Logger:Info("Kick in the nuts for more defense")
            end
        end
    end
end

function KerapacCombat:UseFreedomAbility()
    local freedom = Data.extraAbilities.freedomAbility
    if freedom and freedom.AB and (freedom.AB.id or 0) > 0 and freedom.AB.enabled
        and not API.Buffbar_GetIDstatus(freedom.buffId).found then
        API.DoAction_Ability_check(freedom.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
        Logger:Info("Freeing myself from this blasphemy")
    end
end

function KerapacCombat:UseLivingDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.livingDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Living the Death")
end

function KerapacCombat:UseDeathSkullsAbility()
    API.DoAction_Ability_check(Data.extraAbilities.deathSkullsAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Catch these skulls sucker")
end

function KerapacCombat:UseFingerOfDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.fingerOfDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Fingering Death right now")
end

function KerapacCombat:UseBloatAbility()
    API.DoAction_Ability_check(Data.extraAbilities.bloatAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("I'm not fat, just bloated")
end

function KerapacCombat:UseVolleyOfSoulsAbility()
    API.DoAction_Ability_check(Data.extraAbilities.volleyOfSoulsAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Exorcising these souls out of me")
end

function KerapacCombat:UseTouchOfDeathAbility()
    API.DoAction_Ability_check(Data.extraAbilities.touchOfDeathAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Touching Death inappropriately")
end

function KerapacCombat:UseSoulSapAbility()
    API.DoAction_Ability_check(Data.extraAbilities.soulSapAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Sapping your soul")
end

function KerapacCombat:UseSacrificeAbility()
    API.DoAction_Ability_check(Data.extraAbilities.sacrificeAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Sacrifice your life to me")
end

function KerapacCombat:UseConjureUndeadArmy()
    API.DoAction_Ability_check(Data.extraAbilities.conjureUndeadArmyAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Conjuring up my harem")
end

function KerapacCombat:UseConjureSkeletonWarrior()
    API.DoAction_Ability_check(Data.extraAbilities.conjureSkeletonWarriorAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Conjuring up my Skelebro")
end

function KerapacCombat:UseConjureVengefulGhost()
    API.DoAction_Ability_check(Data.extraAbilities.conjureVengefulGhostAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Conjuring up Casper the Ghost")
end

function KerapacCombat:UseConjurePutridZombie()
    API.DoAction_Ability_check(Data.extraAbilities.conjurePutridZombieAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Conjuring up your Mom")
end

function KerapacCombat:UseCommandSkeletonWarrior()
    API.DoAction_Ability_check(Data.extraAbilities.commandSkeletonWarriorAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Commanding my Skelebro to slay")
end

function KerapacCombat:UseCommandVengefulGhost()
    API.DoAction_Ability_check(Data.extraAbilities.commandVengefulGhostAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Commanding Casper to haunt the target")
end

function KerapacCombat:UseSpecialAttackAbility()
    API.DoAction_Ability_check(Data.extraAbilities.specialAttackAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("You are special")
end

function KerapacCombat:UseEssenceOfFinalityAbility()
    API.DoAction_Ability_check(Data.extraAbilities.essenceOfFinalityAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
    Logger:Info("Nice bling")
end

function KerapacCombat:HandleResonance()
    if not State.isResonanceEnabled and not (API.Get_tick() - State.resonanceTicks > 2) then 
        if not State.isMagePrayEnabled and not State.isMeleePrayEnabled and State.isSoulSplitEnabled then
            self:EnableMagePray()
        end
        return 
    end
    
    if API.Buffbar_GetIDstatus(Data.extraAbilities.resonanceAbility.buffId).found then
        if Data.overheadCursesBuffs.SoulSplit.AB.enabled and not State.isSoulSplitEnabled then
            self:EnableSoulSplit()
        elseif State.isMagePrayEnabled then
            self:DisableMagePray()
        end
    else
        State.isResonanceEnabled = false
    end
    
    State.resonanceTicks = API.Get_tick()
end

function KerapacCombat:HasDefensiveBuffActive()
    return API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
        or API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
        or API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
        or API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
        or API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
        or API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
end

local function isDefensiveReady(ability, minAdrenaline)
    if not ability then return false end
    if not ability.AB then return false end
    if not ability.AB.enabled then return false end
    if (ability.AB.cooldown_timer or 999) > 0 then return false end
    if minAdrenaline and API.GetAddreline_() < minAdrenaline then return false end
    return true
end

local function isAbilityReady(ability)
    if not ability then return false end
    if not ability.AB then return false end
    return ability.AB.enabled == true
end

local function isAbilityOffCooldown(ability)
    if not ability then return false end
    if not ability.AB then return false end
    if not ability.AB.enabled then return false end
    return (ability.AB.cooldown_timer or 999) <= 0
end

local function isInJumpAttackState()
    return State.currentState == Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
        or State.currentState == Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
        or State.currentState == Data.bossStateEnum.JUMP_ATTACK_LANDED.name
end

function KerapacCombat:UseWarpTimeIfAvailable(timeWarpActionButton)
    if not timeWarpActionButton then return end
    if State.kerapacPhase < 4 then return end

    if API.GetHPrecent() > 70 then
        self:UseWarpTime()
    else
        local oldThreshold = Data.emergencyEatThreshold
        Data.emergencyEatThreshold = API.GetHPrecent() + 10
        Utils:EatFood()
        Data.emergencyEatThreshold = oldThreshold
        self:UseWarpTime()
    end
end

function KerapacCombat:CastDefensiveAbility(timeWarpActionButton)
    if self:HasDefensiveBuffActive() then return false end
    if isInJumpAttackState() then return false end
    if State.isPhasing then return false end

    -- Immortality (Phase 4 only, after echoes dead)
    if isDefensiveReady(Data.extraAbilities.immortalityAbility, Data.extraAbilities.immortalityAbility.threshold)
    and not State.islightningPhase
    and State.kerapacPhase >= 4
    and State.isEchoesDead then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseImmortalityAbility()
        return true
    end

    -- Barricade (Lightning phase or Phase 4)
    if isDefensiveReady(Data.extraAbilities.barricadeAbility, Data.extraAbilities.barricadeAbility.threshold)
    and (State.islightningPhase or State.kerapacPhase >= 4) then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseBarricadeAbility()
        return true
    end

    -- Rejuvenate (Phase 4 only, not lightning)
    if isDefensiveReady(Data.extraAbilities.rejuvenateAbility, Data.extraAbilities.rejuvenateAbility.threshold)
    and not State.islightningPhase
    and State.kerapacPhase >= 4 then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseRejuvenateAbility()
        return true
    end

    -- Reflect (Lightning phase or Phase 4)
    if isDefensiveReady(Data.extraAbilities.reflectAbility, Data.extraAbilities.reflectAbility.threshold)
    and (State.islightningPhase or State.kerapacPhase >= 4) then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseReflectAbility()
        return true
    end

    -- Devotion (not during split soul)
    if isDefensiveReady(Data.extraAbilities.devotionAbility, Data.extraAbilities.devotionAbility.threshold)
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseDevotionAbility()
        return true
    end

    -- Debilitate (Lightning phase or Phase 4)
    if isDefensiveReady(Data.extraAbilities.debilitateAbility, Data.extraAbilities.debilitateAbility.threshold)
    and (State.islightningPhase or State.kerapacPhase >= 4) then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseDebilitateAbility()
        return true
    end

    -- Resonance (HP <= 80%, not during rift attacks)
    if isAbilityOffCooldown(Data.extraAbilities.resonanceAbility)
    and State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name
    and API.GetHPrecent() <= 80 then
        self:UseResonanceAbility()
        State.isResonanceEnabled = true
        return true
    end

    -- Preparation (when resonance is on cooldown)
    local resAB = Data.extraAbilities.resonanceAbility.AB
    local prepAB = Data.extraAbilities.preparationAbility.AB
    if resAB and (resAB.cooldown_timer or 0) > 0
    and prepAB and prepAB.enabled and (prepAB.cooldown_timer or 999) <= 0 then
        self:UsePreparationAbility()
        return true
    end

    return false
end

local function canUseOffensiveAbility()
    if State.isPhasing then return false end
    if State.kerapacPhase == 3 and State.islightningPhase then return false end
    return true
end

function KerapacCombat:CastOffensiveAbility(timeWarpActionButton)
    -- Conjures (always priority)
    if isAbilityReady(Data.extraAbilities.conjureUndeadArmyAbility)
    and API.VB_FindPSettinOrder(10994).state < 1
    and API.VB_FindPSettinOrder(11018).state < 1
    and API.VB_FindPSettinOrder(11006).state < 1 then
        self:UseConjureUndeadArmy()
        return true
    end

    if isAbilityReady(Data.extraAbilities.conjureSkeletonWarriorAbility)
    and API.VB_FindPSettinOrder(10994).state < 1 then
        self:UseConjureSkeletonWarrior()
        return true
    end

    if isAbilityReady(Data.extraAbilities.conjureVengefulGhostAbility)
    and API.VB_FindPSettinOrder(11018).state < 1 then
        self:UseConjureVengefulGhost()
        return true
    end

    if isAbilityReady(Data.extraAbilities.conjurePutridZombieAbility)
    and API.VB_FindPSettinOrder(11006).state < 1 then
        self:UseConjurePutridZombie()
        return true
    end

    -- Smoke Cloud
    if Data.extraBuffSmokeCloud and not self:CheckForSmokeCloudOnTarget() then
        self:UseSmokeCloud()
        return true
    end

    -- Darkness
    if isAbilityOffCooldown(Data.extraAbilities.darknessAbility)
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.darknessAbility.buffId).found
    and State.hasDarkness then
        self:UseDarknessAbility()
        return true
    end

    -- Invoke Death
    if isAbilityOffCooldown(Data.extraAbilities.invokeDeathAbility)
    and not self:HasDeathInvocation()
    and not self:HasMarkOfDeath()
    and State.hasInvokeDeath then
        self:UseInvokeDeathAbility()
        return true
    end

    -- Split Soul
    if State.kerapacPhase < 4
    and isAbilityOffCooldown(Data.extraAbilities.splitSoulAbility)
    and Data.extraAbilities.splitSoulAbility.AB and Data.extraAbilities.splitSoulAbility.AB.id and Data.extraAbilities.splitSoulAbility.AB.id > 0
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then
        self:UseSplitSoulAbility()
        return true
    end

    -- Commands
    if isAbilityOffCooldown(Data.extraAbilities.commandSkeletonWarriorAbility) then
        self:UseCommandSkeletonWarrior()
        return true
    end

    if isAbilityOffCooldown(Data.extraAbilities.commandVengefulGhostAbility) then
        self:UseCommandVengefulGhost()
        return true
    end

    if not canUseOffensiveAbility() then
        return false
    end

    -- Death Guard / EOF spec with high necrosis
    if not API.DeBuffbar_GetIDstatus(55524).found
    and State.necrosisStacks > 11
    and API.GetAddreline_() >= 25 then
        if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
            self:UseSpecialAttackAbility()
            return true
        elseif API.GetABs_name1("Essence of Finality").enabled then
            self:UseEssenceOfFinalityAbility()
            return true
        end
    end

    -- Finger of Death (high necrosis)
    if State.necrosisStacks > 11
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseFingerOfDeathAbility()
        return true
    end

    -- Volley of Souls (high stacks)
    if State.residualSoulsStack > State.residualSoulsMax
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseVolleyOfSoulsAbility()
        return true
    end

    -- Death Skulls
    if isAbilityOffCooldown(Data.extraAbilities.deathSkullsAbility)
    and API.GetAddreline_() >= Data.extraAbilities.deathSkullsAbility.threshold
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseDeathSkullsAbility()
        Utils:SleepTickRandom(1)
        Utils:DrinkAdrenalinePotion()
        return true
    end

    -- Living Death
    if isAbilityOffCooldown(Data.extraAbilities.livingDeathAbility)
    and API.GetAddreline_() >= Data.extraAbilities.livingDeathAbility.threshold
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.livingDeathAbility.buffId).found then
        self:UseWarpTimeIfAvailable(timeWarpActionButton)
        self:UseLivingDeathAbility()
        Utils:SleepTickRandom(1)
        Utils:DrinkAdrenalinePotion()
        return true
    end

    -- Omni Guard / EOF spec
    if not API.Buffbar_GetIDstatus(55480).found
    and not API.DeBuffbar_GetIDstatus(55480).found
    and API.GetAddreline_() >= 30 then
        if State.hasOmniGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
            self:UseSpecialAttackAbility()
            return true
        elseif API.GetABs_name1("Essence of Finality").enabled then
            self:UseEssenceOfFinalityAbility()
            return true
        end
    end

    -- Finger of Death (medium necrosis)
    if State.necrosisStacks > 5
    and API.DeBuffbar_GetIDstatus(55524).found
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseFingerOfDeathAbility()
        return true
    end

    -- Bloat
    if isAbilityOffCooldown(Data.extraAbilities.bloatAbility)
    and API.GetAddreline_() >= Data.extraAbilities.bloatAbility.threshold
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not API.TargetHasBuff("Bloat") then
        self:UseBloatAbility()
        return true
    end

    -- Touch of Death
    if isAbilityOffCooldown(Data.extraAbilities.touchOfDeathAbility)
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseTouchOfDeathAbility()
        return true
    end

    -- Soul Sap
    if isAbilityOffCooldown(Data.extraAbilities.soulSapAbility)
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseSoulSapAbility()
        return true
    end

    -- Sacrifice
    if isAbilityOffCooldown(Data.extraAbilities.sacrificeAbility)
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseSacrificeAbility()
        return true
    end

    return false
end

function KerapacCombat:CastNextAbility()
    self:InitAbilities()

    local currentTick = API.Get_tick()
    local tickDiff = currentTick - State.globalCooldownTicks

    local timeWarpActionButton = API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time"

    if tickDiff <= 2 then
        Logger:Debug("CastNextAbility: GCD active (tickDiff=" .. tickDiff .. ", current=" .. currentTick .. ", last=" .. State.globalCooldownTicks .. ")")
        return
    end

    if not State.canAttack then
        Logger:Debug("CastNextAbility: canAttack is false")
        return
    end

    Logger:Debug("CastNextAbility: Executing rotation (tick: " .. currentTick .. ", canAttack: " .. tostring(State.canAttack) .. ")")

    State.hasBloatDebuff = self:CheckForBloatOnTarget()
    State.necrosisStacks = API.VB_FindPSettinOrder(10986).state
    State.residualSoulsStack = API.VB_FindPSettinOrder(11035).state
    State.globalCooldownTicks = currentTick

    self:CheckForSplitSoul()
    Utils:handleTimeWarpBuff()

    if (State.kerapacPhase >= 4 or State.islightningPhase) then
        if self:CastDefensiveAbility(timeWarpActionButton) then
            return
        end
    end

    if self:CastOffensiveAbility(timeWarpActionButton) then
        return
    end

    Logger:Debug("Literally nothing to do so guess I'll do an auto attack")
end

function KerapacCombat:ManagePlayer()
    if State.kerapacPhase == 4 then
        
    end
    self:CastNextAbility()
    self:HandleResonance()
    self:EnablePassivePrayer()
    self:ApplyVulnerability()
    Utils:EatFood()
    Utils:DrinkPrayer()
    Utils:RenewFamiliar()
    self:CheckForStun()
    State:CheckPlayerDeath()
end

return KerapacCombat