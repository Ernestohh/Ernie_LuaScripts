local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")
local Combat = require("kerapac/KerapacCombat")

local KerapacHardMode = {}

function KerapacHardMode:SetupEchoLocations()
    State.kerapacEcho1 = WPOINT.new(math.floor(State.centerOfArenaPosition.x), math.floor(State.centerOfArenaPosition.y + 9), 1)
    State.kerapacEcho2 = WPOINT.new(math.floor(State.centerOfArenaPosition.x), math.floor(State.centerOfArenaPosition.y - 9), 1)
    State.kerapacEcho3 = WPOINT.new(math.floor(State.centerOfArenaPosition.x-9), math.floor(State.centerOfArenaPosition.y), 1)
    Logger:Debug("Echo locations set up")
end

function KerapacHardMode:SetupPlayerTank(clones)
    if State.isPartyLeader or not State.isInParty then 
        API.DoAction_Dive_Tile(State.kerapacEcho1)
        API.DoAction_Tile(State.kerapacEcho1)
        Utils:SleepTickRandom(5)
        API.DoAction_NPC(0x2a, API.OFF_ACT_InteractNPC_route, { clones[1].Id }, 10)
        Utils:SleepTickRandom(3)
        Inventory:Eat("Powerburst of vitality")
        Utils:SleepTickRandom(1)
        API.DoAction_NPC(0x2a, API.OFF_ACT_InteractNPC_route, { clones[1].Id }, 50)
        Utils:SleepTickRandom(1)
        Logger:Info("Player tanking position set up")
        Utils:SleepTickRandom(1)
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { Data.kerapacClones }, 10)
    end
end

function KerapacHardMode:Phase4Setup()
    if State.isPhase4SetupComplete then return end
    
    Utils:SleepTickRandom(3)
    local clones = API.GetAllObjArray1({Data.playerClone}, 60, {1})
    local echoes = API.GetAllObjArray1({Data.kerapacClones}, 60, {1})
    
    if not (#clones > 0) and not (#echoes > 0) then 
        Logger:Debug("No clones or echoes found yet")
        return 
    end
    
    Combat:EnableMagePray()
    self:SetupEchoLocations()
    self:SetupPlayerTank(clones)
    
    State.isPhase4SetupComplete = true
    State.isPhasing = false
    State.islightningPhase = false
    State.canAttack = true
    
    Logger:Info("Phase 4 setup complete")
end

function KerapacHardMode:AttackEcho()
    API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { Data.kerapacClones }, 10)
end

function KerapacHardMode:AttackEchoInArea(botleft, topright)
    API.DoAction_NPC_In_Area(0x2a, API.OFF_ACT_AttackNPC_route, {Data.kerapacClones}, 10, botleft, topright)
end

local printed = false
function KerapacHardMode:HandlePhase4()
    if not (API.Get_tick() - State.phase4Ticks > 1) then return end
    
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
    
    local targetInfo = API.ReadLpInteracting()

    local northEcho = API.GetAllObjArray2({Data.kerapacClones}, 100, {1}, WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.northEcho.echoSpot.x, State.centerOfArenaPosition.y + Data.echoAreasMap.northEcho.echoSpot.y, 1))
    local westEcho = API.GetAllObjArray2({Data.kerapacClones}, 100, {1}, WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.westEcho.echoSpot.x, State.centerOfArenaPosition.y + Data.echoAreasMap.westEcho.echoSpot.y, 1))
    local southEcho = API.GetAllObjArray2({Data.kerapacClones}, 100, {1}, WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.southEcho.echoSpot.x, State.centerOfArenaPosition.y + Data.echoAreasMap.southEcho.echoSpot.y, 1))
    if not printed then
        Logger:Info(#northEcho .. " North")
        Logger:Info(#westEcho .. " West")
        Logger:Info(#southEcho .. " South")
        printed = true
    end
    if northEcho ~= nil and not State.isNorthEchoDead then
        if northEcho[1] ~= nil and northEcho[1].Anim == 33493 then
        State.isNorthEchoDead = true
        end
    end
    if westEcho ~= nil and not State.isWestEchoDead then
        if westEcho[1] ~= nil and westEcho[1].Anim == 33493 then
        State.isWestEchoDead = true
        end
    end
    
    if southEcho ~= nil and not State.isSouthEchoDead then
        if southEcho[1] ~= nil and southEcho[1].Anim == 33493 then
        State.isSouthEchoDead = true
        end
    end

    if targetInfo.Name ~= "Echo of Kerapac" then
        self:AttackEcho()
    end

    if not State.isWestEchoDead then
        if API.Math_DistanceW(API.PlayerCoord(), State.kerapacEcho3) > 2 then
            API.DoAction_Dive_Tile(State.kerapacEcho3)
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(State.kerapacEcho3)
            Utils:SleepTickRandom(3)
            self:AttackEchoInArea(WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.westEcho.bottomLeft.x, State.centerOfArenaPosition.y + Data.echoAreasMap.westEcho.bottomLeft.y, 1), 
                                    WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.westEcho.topRight.x, State.centerOfArenaPosition.y + Data.echoAreasMap.westEcho.topRight.y, 1))
        end
    elseif not State.isSouthEchoDead then
        if API.Math_DistanceW(API.PlayerCoord(), State.kerapacEcho2) > 2 then
            API.DoAction_Dive_Tile(State.kerapacEcho2)
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(State.kerapacEcho2)
            Utils:SleepTickRandom(3)
            self:AttackEchoInArea(WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.southEcho.bottomLeft.x, State.centerOfArenaPosition.y + Data.echoAreasMap.southEcho.bottomLeft.y, 1), 
                                    WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.southEcho.topRight.x, State.centerOfArenaPosition.y + Data.echoAreasMap.southEcho.topRight.y, 1))
        end
    elseif not State.isNorthEchoDead then
        if API.Math_DistanceW(API.PlayerCoord(), State.kerapacEcho1) > 2 then
            API.DoAction_Dive_Tile(State.kerapacEcho1)
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(State.kerapacEcho1)
            Utils:SleepTickRandom(3)
            self:AttackEchoInArea(WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.northEcho.bottomLeft.x, State.centerOfArenaPosition.y + Data.echoAreasMap.northEcho.bottomLeft.y, 1), 
                                    WPOINT.new(State.centerOfArenaPosition.x + Data.echoAreasMap.northEcho.topRight.x, State.centerOfArenaPosition.y + Data.echoAreasMap.northEcho.topRight.y, 1))
        end
    else
        if not State.isEchoesDead then
            State.isEchoesDead = true
        end
        if targetInfo.Name ~= "Kerapac, the bound" then
            Combat:AttackKerapac() 
        end
    end

    State.phase4Ticks = API.Get_tick()
end

return KerapacHardMode