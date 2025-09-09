local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")
local Combat = require("kerapac/KerapacCombat")

local KerapacLightning = {}

function KerapacLightning:PerformDodge(safeWPOINT)
    local diveAB = API.GetABs_name("Dive", true)
    local surgeAB = API.GetABs_name("Surge", true)
    
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
    Utils:SleepTickRandom(1)
end

function KerapacLightning:FindLightningDirections(bolts)
    State.lightningDirections = {}
    for i = 1, #bolts do
        if bolts[i].Distance < Data.proximityThreshold then
            local direction = math.ceil(API.calculateOrientation(bolts[i].MemE))
            if direction > 40 and direction < 50 then
                direction = 45
            end
            if direction > 50 and direction < 95 then
                direction = 90
            end
            if direction > 95 and direction < 140 then
                direction = 135
            end
            if direction > 140 and direction < 190 then
                direction = 180
            end
            if direction > 190 and direction < 230 then
                direction = 225
            end
            if direction > 230 and direction < 275 then
                direction = 270
            end
            if direction > 275 and direction < 320 then
                direction = 315
            end
            if direction > 320 or direction < 40 then
                direction = 0
            end
            Utils:AddIfNotExists(State.lightningDirections, direction)
        end
    end
end

function KerapacLightning:AvoidLightningBolts()
    local inDanger = false
    local closestBolt = nil
    local allLightningBolts = API.GetAllObjArray1({ 28071, 9216 }, 120, {1})
    self:FindLightningDirections(allLightningBolts)
    
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

    if inDanger and not State.hasDodged then
        for i = 1, #State.lightningDirections do
            print("Directions found: ".. State.lightningDirections[i])
        end
        State.canAttack = false
        self:WhereToAvoid()
        State.hasDodged = true
        State.canAttack = true
        State.islightningPhase = false
        Utils:SleepTickRandom(1)
        Combat:AttackKerapac()
    end
end

function KerapacLightning:CreateSafeWPOINT(tile)
    return WPOINT.new(State.centerOfArenaPosition.x + Data.deltaTileMap[tile].x, State.centerOfArenaPosition.y + Data.deltaTileMap[tile].y, 1)
end

function KerapacLightning:MapValueToKey(directions)
    if #directions == 2 then
        return directions[1] * 1000 + directions[2]
    elseif #directions == 3 then
        return directions[1] * 1000000 + directions[2] * 1000 + directions[3]
    end
    return directions[1]
end

function KerapacLightning:WhereToAvoid()
    local directions = State.lightningDirections
    table.sort(directions)
    if #directions < 1 or #directions > 3 then return end

    if #directions == 1 then
        local tile = Data.singlesMap[directions[1]]
        if tile then
            Logger:Info("Dodging 1 row of bolts")
            self:PerformDodge(self:CreateSafeWPOINT(tile))
        end
    elseif #directions == 2 then
        local tile = Data.doublesMap[self:MapValueToKey(directions)]
        if tile then
            Logger:Info("Dodging 2 rows of bolts")
            self:PerformDodge(self:CreateSafeWPOINT(tile))
        else
            local tiles = {}
            for _, direction in ipairs(directions) do
                local tile = Data.singlesMap[direction]
                if tile then
                    table.insert(tiles, tile)
                end
            end
            if #tiles > 0 then
                self:PerformDodge(self:CreateSafeWPOINT(tiles[1]))
                Utils:SleepTickRandom(8)
                self:PerformDodge(self:CreateSafeWPOINT(tiles[2]))
            end
        end
    elseif #directions == 3 then
        local tile = Data.triplesMap[self:MapValueToKey(directions)]
        if tile then
            Logger:Info("Dodging 3 rows of bolts")
            self:PerformDodge(self:CreateSafeWPOINT(tile))
        else
            local tiles = {}
            local doubleKey = directions[1] * 1000 + directions[2]
            local doubleTile = Data.doublesMap[doubleKey]
            
            if doubleTile then
                table.insert(tiles, doubleTile)
                local singleTile = Data.singlesMap[directions[3]]
                if singleTile then
                    table.insert(tiles, singleTile)
                end
            else
                doubleKey = directions[1] * 1000 + directions[3]
                doubleTile = Data.doublesMap[doubleKey]
                
                if doubleTile then
                    table.insert(tiles, doubleTile)
                    local singleTile = Data.singlesMap[directions[2]]
                    if singleTile then
                        table.insert(tiles, singleTile)
                    end
                else
                    doubleKey = directions[2] * 1000 + directions[3]
                    doubleTile = Data.doublesMap[doubleKey]
                
                    if doubleTile then
                        table.insert(tiles, doubleTile)
                        local singleTile = Data.singlesMap[directions[1]]
                        if singleTile then
                            table.insert(tiles, singleTile)
                        end
                    end
                end
            end
            if #tiles > 0 then
                self:PerformDodge(self:CreateSafeWPOINT(tiles[1]))
                Utils:SleepTickRandom(8)
                self:PerformDodge(self:CreateSafeWPOINT(tiles[2]))
            end
        end
    end
end

return KerapacLightning