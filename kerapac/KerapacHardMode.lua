local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")
local Combat = require("kerapac/KerapacCombat")

local KerapacHardMode = {}

function KerapacHardMode:SetupEchoLocations()
    State.kerapacEcho1 = WPOINT.new(math.floor(State.centerOfArenaPosition.x), math.floor(State.centerOfArenaPosition.y + 9), math.floor(State.centerOfArenaPosition.z))
    State.kerapacEcho2 = WPOINT.new(math.floor(State.centerOfArenaPosition.x), math.floor(State.centerOfArenaPosition.y - 9), math.floor(State.centerOfArenaPosition.z))
    State.kerapacEcho3 = WPOINT.new(math.floor(State.centerOfArenaPosition.x-9), math.floor(State.centerOfArenaPosition.y), math.floor(State.centerOfArenaPosition.z))
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
    State.canAttack = true
    
    Logger:Info("Phase 4 setup complete")
end

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
    
    local targetInfo = API.ReadTargetInfo() 

    if targetInfo.Target_Name ~= "Echo of Kerapac" then
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { echoes[1].Id }, 10)
    end

    if #killableEchoes == 2 and targetInfo.Hitpoints >= 90000 then
        Logger:Debug("Amount of killable echoes: " .. #killableEchoes)
        if API.Math_DistanceW(WPOINT.new(math.floor(killableEchoes[2].TileX)/512, math.floor(killableEchoes[2].TileY)/512, math.floor(killableEchoes[2].TileZ)/512), API.PlayerCoord()) > 10 then
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[2].TileX)/512, math.floor(killableEchoes[2].TileY)/512, math.floor(killableEchoes[2].TileZ)/512))
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[2].TileX)/512, math.floor(killableEchoes[2].TileY)/512, math.floor(killableEchoes[2].TileZ)/512))
            API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[2].Id }, 10)
        end
    elseif #killableEchoes == 1 and targetInfo.Hitpoints >= 90000 then
        Logger:Debug("Amount of killable echoes: " .. #killableEchoes)
        if API.Math_DistanceW(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512), API.PlayerCoord()) > 10 then
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[2].Id }, 10)
        end
    elseif #killableEchoes == 0 then
        if not State.isEchoesDead then
            State.isEchoesDead = true
        end
        Combat:AttackKerapac()
    end

    if #killableEchoes > 0 and targetInfo.Hitpoints ~= 100000 then
        Combat:ApplyVulnerability()
    end
    State.phase4Ticks = API.Get_tick()
end

return KerapacHardMode