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

    if targetInfo.Hitpoints == 0 then
        Logger:Info("Echo killed")
        table.remove(killableEchoes, 1)
        
        if #killableEchoes == 2 then
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[2].TileX)/512, math.floor(killableEchoes[2].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
        elseif #killableEchoes == 1 then
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
        end
    end

    if #killableEchoes == 2 and targetInfo.Hitpoints == 100000 then
        Logger:Debug("Amount of killable echoes: " .. #killableEchoes)
        API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[2].TileX)/512, math.floor(killableEchoes[2].TileY)/512, math.floor(killableEchoes[2].TileZ)/512))
        Utils:SleepTickRandom(0)
        API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[2].TileZ)/512))
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[2].Id }, 10)
    elseif #killableEchoes == 1 and targetInfo.Hitpoints == 100000 then
        Logger:Debug("Amount of killable echoes: " .. #killableEchoes)
        API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
        Utils:SleepTickRandom(0)
        API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
        API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 100)
    elseif #killableEchoes == 0 then
        Combat:AttackKerapac()
    end

    if #killableEchoes > 0 and targetInfo.Hitpoints ~= 100000 then
        Combat:ApplyVulnerability()
        if not API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10) then
            API.DoAction_Dive_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            Utils:SleepTickRandom(0)
            API.DoAction_Tile(WPOINT.new(math.floor(killableEchoes[1].TileX)/512, math.floor(killableEchoes[1].TileY)/512, math.floor(killableEchoes[1].TileZ)/512))
            API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, { killableEchoes[1].Id }, 10)
        end
    end

    State.phase4Ticks = API.Get_tick()
end

function KerapacHardMode:CalculateSafePosition(playerPosition)
    if #State.lightningDirections == 0 then
        return playerPosition
    end
    
    local safeDistance = 20
    local safestDirection = 0
    
    if #State.lightningDirections == 1 then
        safestDirection = State.lightningDirections[1]
        Logger:Debug("Single lightning at " .. State.lightningDirections[1] .. " moving to " .. safestDirection)
    else
        local vectorX, vectorY = 0, 0
        
        for _, direction in ipairs(State.lightningDirections) do
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
            avgDirection = State.lightningDirections[1]
            Logger:Debug("Lightning directions nearly cancel getting behind first lightning at " .. State.lightningDirections[1])
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
        
        Logger:Debug("Multiple lightning directions average: " .. avgDirection .. " moving to: " .. safestDirection)
    end
    
    local safeRadians = math.rad(safestDirection)
    local safeX = playerPosition.x - safeDistance * math.sin(safeRadians)
    local safeY = playerPosition.y - safeDistance * math.cos(safeRadians)
    local safePosition = WPOINT.new(safeX, safeY, playerPosition.z)

    Logger:Debug("Lightning directions: " .. table.concat(State.lightningDirections, ", "))
    Logger:Debug("Player position x: " .. playerPosition.x .. " player position y: " .. playerPosition.y)
    Logger:Debug("Adjusted game direction: " .. safestDirection)
    
    return safePosition
end

function KerapacHardMode:PerformDodge(safeWPOINT)
    local surgeAB = API.GetABs_name("Surge", true)
    local diveAB = API.GetABs_name("Dive", true)
    
    if (diveAB.cooldown_timer <= 0) then
        Logger:Info("Diving to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Dive_Tile(safeWPOINT)
    elseif (surgeAB.cooldown_timer <= 0) then
        Logger:Info("Surging to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Tile(safeWPOINT)
        Utils:SleepTickRandom(1)
        API.DoAction_Ability_Direct(surgeAB, 1, API.OFF_ACT_GeneralInterface_route)
    else
        Logger:Info("Running to x: " .. safeWPOINT.x .. " y: " .. safeWPOINT.y)
        API.DoAction_Tile(safeWPOINT)
    end
    
    if State.isAttackingKerapac then
        State.isAttackingKerapac = false
    end
    
    State.avoidLightningTicks = API.Get_tick()
end

function KerapacHardMode:AvoidLightningBolts()
    local inDanger = false
    local closestBolt = nil
    local allLightningBolts = API.GetAllObjArray1({ 28071, 9216 }, 100, {1})
    
    State.lightningDirections = {}
    for i = 1, #allLightningBolts do
        if allLightningBolts[i].Distance < Data.proximityThreshold then
            local direction = math.ceil(API.calculateOrientation(allLightningBolts[i].MemE))
            Utils:AddIfNotExists(State.lightningDirections, direction)
        end
    end
    
    if #State.lightningDirections <= 0 and State.islightningPhase then
        State.islightningPhase = false
    end

    for i = 1, #allLightningBolts do
        if allLightningBolts[i].Distance < Data.distanceThreshold then
            inDanger = true
        end
    end

    if not inDanger and not State.isAttackingKerapac then
        State.isAttackingKerapac = true
        Combat:AttackKerapac()
    end

    if inDanger and API.Get_tick() - State.avoidLightningTicks > Data.dodgeCooldown then
        self:PerformDodge(self:CalculateSafePosition(State.playerPosition))
    end
end

return KerapacHardMode