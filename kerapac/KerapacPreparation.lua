local API = require("api")

local Data = require("kerapac/KerapacData")

local State = require("kerapac/KerapacState")

local Logger = require("kerapac/KerapacLogger")

local Utils = require("kerapac/KerapacUtils")



local KerapacPreparation = {}

-- Replacement functions for removed UI module
function KerapacPreparation:HandleBankPin()
    if API.DoBankPin(Data.bankPin) then
        if Data.bankPin ~= nil then
            Logger:Error("No Bank Pin provided in configuration")
        else
            return true
        end
    end
    return false
end

function KerapacPreparation:HandleSetupInstance()
    Logger:Info("Setting max players")
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 72, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(2)
    API.KeyboardPress(3, 60, 110)
    API.KeyboardPress2(0x0D, 60, 110)
    
    Logger:Info("Setting min level to 1")
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 81, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(2)
    API.KeyboardPress(1, 60, 110)
    API.KeyboardPress2(0x0D, 60, 110)
    
    Logger:Info("Setting FFA")
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 36, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(2)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 36, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(2)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 36, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(2)
    
    State.isSetupFirstInstance = true
end

function KerapacPreparation:HandleHardMode()
    if State.isHardMode then
        if API.ScanForInterfaceTest2Get(false, { { 1591, 15, -1, 0 }, { 1591, 17, -1, 0 }, { 1591, 41, -1, 0 }, { 1591, 12, -1, 0 } })[1].textids == "Kerapac" then
            Logger:Info("Enabling Hard Mode")
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 4, -1, API.OFF_ACT_GeneralInterface_route)
        end
    else
        if API.ScanForInterfaceTest2Get(false, { { 1591, 15, -1, 0 }, { 1591, 17, -1, 0 }, { 1591, 41, -1, 0 }, { 1591, 12, -1, 0 } })[1].textids ~= "Kerapac" then
            Logger:Info("Disabling Hard Mode")
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 4, -1, API.OFF_ACT_GeneralInterface_route)
        end
    end
end

function KerapacPreparation:HandleStartFight() 
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(3)
end

function KerapacPreparation:HandleJoinPlayer(partyLeader)
    if State.isInArena then 
        Logger:Info("Already in arena") 
        return 
    end
    
    partyLeader = string.upper(partyLeader)
    for i = 1, #partyLeader do
        local char = partyLeader:sub(i, i)
        local byte = string.byte(char)
        local hex = string.format("%02X", byte)
        
        if State.isInArena then 
            Logger:Info("Already in arena") 
            return 
        end
        
        API.KeyboardPress2("0x"..hex, 60, 110)
    end
    
    if State.isInArena then 
        Logger:Info("Already in arena") 
        return 
    end
    
    API.KeyboardPress2(0x0D, 60, 110)
    API.Sleep_tick(2)
end



function KerapacPreparation:CheckStartLocation()

    if not (API.Dist_FLP(FFPOINT.new(3299, 10131, 0)) < 30) then

        Logger:Info("Teleporting to War's Retreat")

        Utils:WarsTeleport()

    else

        Logger:Info("Already in War's Retreat")

        State.isInWarsRetreat = true

        Utils:SleepTickRandom(2)

    end

end



function KerapacPreparation:HandlePrayerRestore()

    if API.GetPrayPrecent() < 100 or API.GetSummoningPoints_() < 60 then

        Logger:Info("Restoring prayer and summoning at Altar of War")

        API.DoAction_Object1(0x3d, API.OFF_ACT_GeneralObject_route0, { 114748 }, 50)

        API.WaitUntilMovingEnds(10, 4)

    end

    State.isRestoringPrayer = true

end



function KerapacPreparation:HandleBanking()

    if Inventory:Contains(24154) then

        API.DoAction_Inventory1(24154,0,8,API.OFF_ACT_GeneralInterface_route2)

        Utils:SleepTickRandom(2)

        API.DoAction_Interface(0xffffffff,0xffffffff,0,1183,5,-1,API.OFF_ACT_GeneralInterface_Choose_option)

    end

    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { 114750 }, 50)

    API.WaitUntilMovingEnds(10, 4)

    self:HandleBankPin()

    Logger:Info("Loading preset")

    State.isBanking = true

end



function KerapacPreparation:PrepareForBattle()

    Utils:CheckWeaponType()

    Utils:CheckForZukCape()

    Utils:SummonFamiliar()

    Utils:RenewFamiliar()

    Utils:SetupAutoFire()

    Utils:StoreScrollsInFamiliar()

    

    local Combat = require("kerapac/KerapacCombat")

    Combat:CheckAvailableBuffs()

    Utils:SleepTickRandom(1)

    

    Logger:Info(string.format(

        "Preparation status:\nOverloads: %s\nWeapon Poison: %s\nDebilitate: %s\nDevotion: %s\nDarkness: %s\nInvoke Death: %s\nScripture: %s",

        tostring(State.hasOverload), 

        tostring(State.hasWeaponPoison), 

        tostring(State.hasDebilitate), 

        tostring(State.hasDevotion), 

        tostring(State.hasDarkness), 

        tostring(State.hasInvokeDeath), 

        tostring(State.isScriptureEquipped)

    ))



    Logger:Info(string.format(

        "Food:\nRegular: %s\nEmergency Food: %s\nEmergency Drink: %s",

        Utils:WhichFood(), Utils:WhichEmergencyFood(), Utils:WhichEmergencyDrink()

    ))



    Utils:ValidateAbilityBars()

    

    if not Inventory:ContainsAny(Data.foodItems) and 

       not Inventory:ContainsAny(Data.emergencyFoodItems) and 

       not Inventory:ContainsAny(Data.emergencyDrinkItems) then

        Logger:Error("No food items in inventory! Stopping script for safety.")

        State:StopScript()

        return

    end

    

    State.isPrepared = true

    Logger:Info("Ready for battle")

end



function KerapacPreparation:HandleAdrenalineCrystal()

    if State.isMaxAdrenaline then return end

    

    if API.GetAddreline_() ~= 100 then

        Interact:Object("Adrenaline crystal", "Channel", 60)

        API.WaitUntilMovingandAnimEnds(10, 4)

        Logger:Info("Charging adrenaline")

    else

        State.isMaxAdrenaline = true

        Logger:Info("Adrenaline fully charged")

    end

end



function KerapacPreparation:GoThroughPortal()

    Logger:Info("Going through boss portal")

    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 121019 }, 50)

    API.WaitUntilMovingEnds(20, 4)

    Utils:SleepTickRandom(5)

    

    local colosseum = API.GetAllObjArray1({120046}, 30, {12})

    if #colosseum > 0 then

        State.isPortalUsed = true

        Logger:Info("At Colosseum entrance")

    end

end



function KerapacPreparation:GoThroughGate()

    Logger:Info("Entering Colosseum")

    if State.isInParty then
        if State.isPartyLeader and not State.isSetupFirstInstance then

            API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)

            Utils:SleepTickRandom(2)

            self:HandleSetupInstance()

            self:HandleHardMode()

            self:HandleStartFight()

            Utils:SleepTickRandom(10)

        elseif State.isPartyLeader and State.isSetupFirstInstance then

            API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)

            Utils:SleepTickRandom(2)

            self:HandleHardMode()

            self:HandleStartFight()

        elseif not State.isPartyLeader then

            API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route1, { 120046 }, 50)

            Utils:SleepTickRandom(2)

            self:HandleJoinPlayer(Data.partyLeader)

        end

    else

        API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 120046 }, 50)

        Utils:SleepTickRandom(2)

        self:HandleHardMode()

        self:HandleStartFight() 

    end



    local gate = API.GetAllObjArray1({120047}, 30, {12})

    if #gate > 0 then

        State.isInArena = true

        Logger:Info("Inside Colosseum")

    end

end



function KerapacPreparation:WaitForPartyToBeComplete()

    Logger:Info("Waiting for team to be complete")

    local players = API.GetAllObjArray1({1}, 30, {2})

    local playersInVicinity = {}

    local partyMembers = {}

    

    for i = 1, #players do

        local player = players[i]

        Logger:Debug("Found player: " .. player.Name)

        table.insert(playersInVicinity, string.lower(player.Name))

    end

    

    for i = 1, #Data.partyMembers do

        Logger:Debug("Party member: " .. Data.partyMembers[i])

        table.insert(partyMembers, string.lower(Data.partyMembers[i]))

    end

    

    playersInVicinity = Utils:RemoveDuplicates(playersInVicinity)

    

    if #playersInVicinity == #Data.partyMembers then

        State.isTeamComplete = true

    end

    

    Logger:Info("Found all team members: " .. tostring(State.isTeamComplete))

    Utils:SleepTickRandom(1)

end



function KerapacPreparation:BeginFight()

    Logger:Info("Starting encounter")

    

    State.playerPosition = API.PlayerCoord()

    State.centerOfArenaPosition = FFPOINT.new(State.playerPosition.x - 7, State.playerPosition.y, 0)

    State.startLocationOfArena = FFPOINT.new(State.playerPosition.x - 25, State.playerPosition.y, 0)

    State.kerapacPhase = API.VB_FindPSett(10949).state + 1

        

    Logger:Info("Resetting compass")

    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1919, 2, -1, API.OFF_ACT_GeneralInterface_route)

    Utils:SleepTickRandom(1)

        

    Logger:Info("Moving to starting position")

    local Combat = require("kerapac/KerapacCombat")

    Combat:EnableMagePray()

    API.DoAction_TileF(State.startLocationOfArena)

    

    if Data.extraAbilities.conjureUndeadArmyAbility.AB.enabled 

       and API.VB_FindPSettinOrder(10994).state < 1 

       and API.VB_FindPSettinOrder(11018).state < 1 

       and API.VB_FindPSettinOrder(11006).state < 1 then

        Combat:UseConjureUndeadArmy()

    else

        if Data.extraAbilities.conjureSkeletonWarriorAbility.AB.enabled 

           and API.VB_FindPSettinOrder(10994).state < 1 then

            Combat:UseConjureSkeletonWarrior()

        end



        if Data.extraAbilities.conjureVengefulGhostAbility.AB.enabled 

           and API.VB_FindPSettinOrder(11018).state < 1 then

            Combat:UseConjureVengefulGhost()

        end



        if Data.extraAbilities.conjurePutridZombieAbility.AB.enabled 

           and API.VB_FindPSettinOrder(11006).state < 1 then

            Combat:UseConjurePutridZombie()

        end

    end

    

    API.WaitUntilMovingEnds(20, 4)

    Logger:Info("Ready to engage boss")

end



function KerapacPreparation:StartEncounter()

    if State.isInParty then

        if not State.isTeamComplete then

            self:WaitForPartyToBeComplete()

        else

            self:BeginFight()

        end

    else

        self:BeginFight()

    end

end



function KerapacPreparation:CheckKerapacExists()

    local Combat = require("kerapac/KerapacCombat")

    local kerapacInfo = Combat:GetKerapacInformation()

    

    if kerapacInfo and kerapacInfo.Action == "Attack" then

        State.isInBattle = true

        State.isFightStarted = true

        State.canAttack = true

        Combat:EnableMagePray()

        Combat:AttackKerapac()

        Logger:Info("Fight started")

    end

end



function KerapacPreparation:HandleBossReset()

    State:Reset()

    Logger:Info("Boss encounter reset, ready for next run")

end



function KerapacPreparation:ReclaimItemsAtGrave()
    Utils:SleepTickRandom(20)
    State.hasReclaimedItems = false
    local foundDeath = false
    local deathNPC =  API.GetAllObjArray1({27299}, 30, {1})
    if #deathNPC > 0 then
        Interact:NPC("Death", "Reclaim items", 15)
        Utils:SleepTickRandom(5)
        if API.ScanForInterfaceTest2Get(false, { {1626,57,-1,0}, {1626,59,-1,0}, {1626,12,-1,0}, {1626,13,-1,0}, {1626,23,-1,0}, {1626,24,-1,0}, {1626,30,-1,0}, {1626,31,-1,0}, {1626,33,-1,0}, {1626,8,-1,0}, {1626,10,-1,0}, {1626,10,0,0} })[1].itemid1 ~= 0 then
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1626, 47, -1, API.OFF_ACT_GeneralInterface_route)
            Utils:SleepTickRandom(5)
            API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1626, 72, -1, API.OFF_ACT_GeneralInterface_Choose_option)
            Utils:SleepTickRandom(5)
            Logger:Info("Items reclaimed from grave")
             KerapacPreparation:HandleBossReset()
        end 
    end
end



return KerapacPreparation



