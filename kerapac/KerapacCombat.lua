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

function KerapacCombat:CheckAvailableBuffs()
    self:InitAbilities()
    State.hasOverload = Utils:WhichOverload() ~= ""
    State.hasWeaponPoison = Utils:WhichWeaponPoison() ~= ""
    State.hasAdrenalinePotion = Utils:WhichAdrenalinePotion() ~= ""
    State.hasDebilitate = Data.extraAbilities.debilitateAbility.AB.slot ~= 0
    State.hasDevotion = Data.extraAbilities.devotionAbility.AB.slot ~= 0
    State.hasReflect = Data.extraAbilities.reflectAbility.AB.slot ~= 0
    State.hasImmortality = Data.extraAbilities.immortalityAbility.AB.slot ~= 0
    
    local darknessOnBar = Data.extraAbilities.darknessAbility.AB.slot ~= 0
    if darknessOnBar then
        State.hasDarkness = Data.extraAbilities.darknessAbility.AB.enabled
    end
    
    local invokeDeathOnBar = Data.extraAbilities.invokeDeathAbility.AB.slot ~= 0
    if invokeDeathOnBar then
        State.hasInvokeDeath = Data.extraAbilities.invokeDeathAbility.AB.enabled
    end
    
    local splitSoulOnBar = Data.extraAbilities.splitSoulAbility.AB.slot ~= 0
    if splitSoulOnBar then
        State.hasSplitSoul = Data.extraAbilities.splitSoulAbility.AB.enabled
    end
    
    Utils:CheckForScripture()
    
    Logger:Debug("Buff check complete")
end

function KerapacCombat:CheckForDebilitateOnTarget()
    for _, value in ipairs(API.ReadTargetInfo().Buff_stack) do
        if value == Data.extraAbilities.debilitateAbility.debuffId then
            return true
        end
    end
    return false
end

function KerapacCombat:CheckForBloatOnTarget()
    for _, value in ipairs(API.ReadTargetInfo().Buff_stack) do
        if value == Data.extraAbilities.bloatAbility.buffId then
            return true
        end
    end
    return false
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
    if API.Get_tick() - State.buffCheckCooldown <= 4 then return end

    if State.hasOverload then
        Utils:DrinkOverload()
    end
    
    if State.hasWeaponPoison then
        Utils:DrinkWeaponPoison()
    end

    if State.isScriptureEquipped and not State.hasScriptureBuff then
        self:EnableScripture(State.scripture)
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

    if kerapacInfo.Life <= 0 and State.kerapacPhase >= 4 then
        Logger:Info("Preparing to loot")
        self:HandleBossDeath()
    end
    
    State:HandlePhaseTransition(kerapacInfo.Life)
end

function KerapacCombat:ApplyVulnerability()
    if not Inventory:Contains("Vulnerability bomb") and not API.GetABs_name1("Vulnerability bomb").enabled then return end
    
    if API.ReadTargetInfo().Target_Name ~= "Kerapac, the bound" and API.ReadTargetInfo().Target_Name ~= "Echo of Kerapac" then return end
    
    if not (API.Get_tick() - State.vulnTicks > 12) then return end
    
    if State.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name or 
       State.currentState == Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name or
       State.currentState == Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name or 
       State.currentState == Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name then 
        return 
    end
    
    local hasVuln = false
    for _, value in ipairs(API.ReadTargetInfo().Buff_stack) do
        if value == 14395 then
            hasVuln = true
        end
    end
    
    local vulnAB = API.GetABs_name1("Vulnerability bomb")
    if not hasVuln then
        API.DoAction_Ability_Direct(vulnAB, 1, API.OFF_ACT_GeneralInterface_route)
        if API.ReadTargetInfo().Target_Name == "Kerapac, the bound" then
            self:AttackKerapac()
        elseif API.ReadTargetInfo().Target_Name == "Echo of Kerapac" then
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
        Utils:SleepTickRandom(2)
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
    if Data.extraAbilities.freedomAbility.AB.id > 0 and
        Data.extraAbilities.freedomAbility.AB.enabled and 
        not API.Buffbar_GetIDstatus(Data.extraAbilities.freedomAbility.buffId).found then
        API.DoAction_Ability_check(Data.extraAbilities.freedomAbility.name, 1, API.OFF_ACT_GeneralInterface_route, true, true, true)
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

function KerapacCombat:CastNextAbility()
    self:InitAbilities()
    
    --local attackTick = API.VB_FindPSettinOrder(4501).state
    local timeWarpActionButton = API.ScanForInterfaceTest2Get(false, { { 743,0,-1,0 }, { 743,1,-1,0 } })[1].textitem == "<col=FFFFFF>Warp time"
    --if attackTick == State.lastAttackTick then return end
    if not (API.Get_tick() - State.globalCooldownTicks > 2) then return end
    if not State.canAttack then return end
    
    State.hasBloatDebuff = self:CheckForBloatOnTarget()
    State.necrosisStacks = API.VB_FindPSettinOrder(10986).state
    State.residualSoulsStack = API.VB_FindPSettinOrder(11035).state
    --State.lastAttackTick = attackTick
    State.globalCooldownTicks = API.Get_tick()
    
    self:CheckForSplitSoul()
    Utils:handleTimeWarpBuff()
    
    if Data.extraAbilities.conjureUndeadArmyAbility.AB.enabled 
    and API.VB_FindPSettinOrder(10994).state < 1 
    and API.VB_FindPSettinOrder(11018).state < 1 
    and API.VB_FindPSettinOrder(11006).state < 1 then
        self:UseConjureUndeadArmy()
        return
    end

    if Data.extraAbilities.conjureSkeletonWarriorAbility.AB.enabled 
    and API.VB_FindPSettinOrder(10994).state < 1 then
        self:UseConjureSkeletonWarrior()
        return
    end

    if Data.extraAbilities.conjureVengefulGhostAbility.AB.enabled 
    and API.VB_FindPSettinOrder(11018).state < 1 then
        self:UseConjureVengefulGhost()
        return
    end

    if Data.extraAbilities.conjurePutridZombieAbility.AB.enabled 
    and API.VB_FindPSettinOrder(11006).state < 1 then
        self:UseConjurePutridZombie()
        return
    end

    if Data.extraAbilities.darknessAbility.AB.cooldown_timer <= 0 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.darknessAbility.buffId).found 
    and Data.extraAbilities.darknessAbility.AB.enabled
    and State.hasDarkness then
        self:UseDarknessAbility()
        return
    end

    if Data.extraAbilities.invokeDeathAbility.AB.cooldown_timer <= 0 
    and not self:HasDeathInvocation() 
    and not self:HasMarkOfDeath()
    and Data.extraAbilities.invokeDeathAbility.AB.enabled 
    and State.hasInvokeDeath then
        self:UseInvokeDeathAbility()
        return
    end

    if (State.kerapacPhase < 3)
    and Data.extraAbilities.splitSoulAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.splitSoulAbility.AB.id > 0 
    and Data.extraAbilities.splitSoulAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found then
        self:UseSplitSoulAbility()
        return
    end
    
    if Data.extraAbilities.commandSkeletonWarriorAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.commandSkeletonWarriorAbility.AB.enabled then
        self:UseCommandSkeletonWarrior()
        return
    end

    if Data.extraAbilities.commandVengefulGhostAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.commandVengefulGhostAbility.AB.enabled then
        self:UseCommandVengefulGhost()
        return
    end

    if Data.extraAbilities.immortalityAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.immortalityAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name
    and not State.islightningPhase
    and not State.isPhasing
    and State.kerapacPhase >= 4
    and State.isEchoesDead
    and API.GetAddreline_() >= Data.extraAbilities.immortalityAbility.threshold then
        if timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        self:UseImmortalityAbility()
        return
    end

    if not API.DeBuffbar_GetIDstatus(55524).found
    and not State.isPhasing
    and State.necrosisStacks > 11
    and API.GetAddreline_() >= 25 then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
                self:UseSpecialAttackAbility()
                return
            elseif API.GetABs_name1("Essence of Finality").enabled then
                self:UseEssenceOfFinalityAbility()
                return
            end
        end
    end

    if State.necrosisStacks > 11 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseFingerOfDeathAbility()
            return
        end
    end

    if not API.DeBuffbar_GetIDstatus(55524).found
    and not State.isPhasing
    and State.necrosisStacks > 5
    and API.GetAddreline_() >= 25 then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
                self:UseSpecialAttackAbility()
                return
            elseif API.GetABs_name1("Essence of Finality").enabled then
                self:UseEssenceOfFinalityAbility()
                return
            end
        end
    end

    if State.residualSoulsStack > 4 
    and Data.extraAbilities.volleyOfSoulsAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseVolleyOfSoulsAbility()
            return
        end
    end

    if not API.DeBuffbar_GetIDstatus(55524).found
    and not State.isPhasing
    and State.necrosisStacks > 11
    and API.GetAddreline_() >= 25 then
        if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
            self:UseSpecialAttackAbility()
            return
        elseif API.GetABs_name1("Essence of Finality").enabled then
            self:UseEssenceOfFinalityAbility()
            return
        end
    end

    if State.necrosisStacks > 11 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        self:UseFingerOfDeathAbility()
        return
    end

    if not API.DeBuffbar_GetIDstatus(55524).found
    and not State.isPhasing
    and State.necrosisStacks > 5
    and API.GetAddreline_() >= 25 then
        if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
            self:UseSpecialAttackAbility()
            return
        elseif API.GetABs_name1("Essence of Finality").enabled then
            self:UseEssenceOfFinalityAbility()
            return
        end
    end

    if State.residualSoulsStack > 2
    and Data.extraAbilities.volleyOfSoulsAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        self:UseVolleyOfSoulsAbility()
        return
    end

    if Data.extraAbilities.barricadeAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.barricadeAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name
    and not State.isPhasing
    and API.GetAddreline_() >= Data.extraAbilities.barricadeAbility.threshold then
        if timeWarpActionButton and State.kerapacPhase >= 4 then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        if State.islightningPhase or State.kerapacPhase >= 4 then
            self:UseBarricadeAbility()
            return
        end
    end

    if Data.extraAbilities.rejuvenateAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.rejuvenateAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name
    and not State.islightningPhase
    and not State.isPhasing
    and State.kerapacPhase >= 4
    and API.GetAddreline_() >= Data.extraAbilities.rejuvenateAbility.threshold then
        if timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        self:UseRejuvenateAbility()
        return
    end

    if Data.extraAbilities.reflectAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.reflectAbility.AB.enabled 
    and API.GetAddreline_() >= Data.extraAbilities.reflectAbility.threshold
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name 
    and not State.isPhasing then
        if State.kerapacPhase >= 4 
        and timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        if State.islightningPhase or State.kerapacPhase >= 4 then
            self:UseReflectAbility()
            return
        end
    end

    if Data.extraAbilities.devotionAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.devotionAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name
    and not State.isPhasing
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.splitSoulAbility.buffId).found
    and API.GetAddreline_() >= Data.extraAbilities.devotionAbility.threshold then
        if State.kerapacPhase >= 4 
        and timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        self:UseDevotionAbility()
        return
    end
    
    if Data.extraAbilities.debilitateAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.debilitateAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.debilitateAbility.debuffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.reflectAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.devotionAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.immortalityAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.barricadeAbility.buffId).found
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.rejuvenateAbility.buffId).found
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name
    and not State.isPhasing
    and API.GetAddreline_() >= Data.extraAbilities.debilitateAbility.threshold then
        if State.kerapacPhase >= 4 
        and timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        if State.islightningPhase or State.kerapacPhase >= 4 then
            self:UseDebilitateAbility()
            return 
        end
    end

    if Data.extraAbilities.deathSkullsAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.deathSkullsAbility.AB.enabled 
    and API.GetAddreline_() >= Data.extraAbilities.deathSkullsAbility.threshold 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        if State.kerapacPhase >= 4 
        and timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseDeathSkullsAbility()
            Utils:SleepTickRandom(1)
            Utils:DrinkAdrenalinePotion()
            return
        end
    end

    if Data.extraAbilities.livingDeathAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.livingDeathAbility.AB.enabled 
    and API.GetAddreline_() >= Data.extraAbilities.livingDeathAbility.threshold 
    and not State.isPhasing 
    and not API.Buffbar_GetIDstatus(Data.extraAbilities.livingDeathAbility.buffId).found then
        if State.kerapacPhase >= 4 
        and timeWarpActionButton then
            if API.GetHPrecent() > 70 then
                self:UseWarpTime()
            else
                local oldThreshold = Data.emergencyEatThreshold
                Data.emergencyEatThreshold = API.GetHPrecent()+10
                Utils:EatFood()
                Data.emergencyEatThreshold = oldThreshold
                self:UseWarpTime()
            end
        end
        self:UseLivingDeathAbility()
        Utils:SleepTickRandom(1)
        Utils:DrinkAdrenalinePotion()
        return
    end

    if not API.Buffbar_GetIDstatus(55480).found 
    and not API.DeBuffbar_GetIDstatus(55480).found
    and not State.isPhasing
    and API.GetAddreline_() >= 30 then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            if State.hasOmniGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
                self:UseSpecialAttackAbility()
            elseif API.GetABs_name1("Essence of Finality").enabled then
                self:UseEssenceOfFinalityAbility()
            end
        end
    end

    if not API.DeBuffbar_GetIDstatus(55524).found
    and not State.isPhasing
    and State.necrosisStacks > 5
    and API.GetAddreline_() >= 25 then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            if State.hasDeathGuardEquipped and API.GetABs_name1("Weapon Special Attack").enabled then
                self:UseSpecialAttackAbility()
            elseif API.GetABs_name1("Essence of Finality").enabled then
                self:UseEssenceOfFinalityAbility()
            end
        end
    end

    if Data.extraAbilities.resonanceAbility.AB.cooldown_timer <= 0
    and Data.extraAbilities.resonanceAbility.AB.enabled  
    and not State.isPhasing
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_IN_AIR.name
    and State.currentState ~= Data.bossStateEnum.JUMP_ATTACK_LANDED.name 
    and State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_COMMENCE.name
    and State.currentState ~= Data.bossStateEnum.TEAR_RIFT_ATTACK_MOVE.name
    and API.GetHPrecent() <= 80 then
        self:UseResonanceAbility()
        State.isResonanceEnabled = true
        return
    end

    if State.necrosisStacks > 5 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseFingerOfDeathAbility()
            return
        end
    end

    if State.residualSoulsStack > 2 
    and Data.extraAbilities.volleyOfSoulsAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseVolleyOfSoulsAbility()
            return
        end
    end

    if Data.extraAbilities.bloatAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.bloatAbility.AB.enabled 
    and API.GetAddreline_() >= Data.extraAbilities.bloatAbility.threshold 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.hasBloatDebuff then
        if (State.kerapacPhase == 3 and not State.islightningPhase) or (State.kerapacPhase ~= 3) then
            self:UseBloatAbility()
            return
        end
    end

    if Data.extraAbilities.touchOfDeathAbility.AB.cooldown_timer <= 0
    and Data.extraAbilities.touchOfDeathAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseTouchOfDeathAbility()
        return
    end

    if Data.extraAbilities.soulSapAbility.AB.cooldown_timer <= 0
    and Data.extraAbilities.soulSapAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found then
        self:UseSoulSapAbility()
        return
    end

    if Data.extraAbilities.sacrificeAbility.AB.cooldown_timer <= 0 
    and Data.extraAbilities.sacrificeAbility.AB.enabled 
    and not API.Buffbar_GetIDstatus(Data.deathSparkReady).found
    and not State.isPhasing then
        self:UseSacrificeAbility()
        return
    end

    if Data.extraAbilities.resonanceAbility.AB.cooldown_timer > 0
    and Data.extraAbilities.preparationAbility.AB.enabled 
    and Data.extraAbilities.preparationAbility.AB.cooldown_timer <= 0 then
        self:UsePreparationAbility()
        return
    end

    Logger:Debug("Literally nothing to do so guess I'll do an auto attack")
end

function KerapacCombat:ManagePlayer()
    self:CastNextAbility()
    self:HandleResonance()
    self:EnablePassivePrayer()
    self:ApplyVulnerability()
    --Utils:HandleSpecialSummoning()
    Utils:EatFood()
    Utils:DrinkPrayer()
    self:EnablePassivePrayer()
    Utils:RenewFamiliar()
    self:CheckForStun()
    State:CheckPlayerDeath()
end

return KerapacCombat