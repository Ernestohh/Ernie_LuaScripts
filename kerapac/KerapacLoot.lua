local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")

local KerapacLoot = {}

function KerapacLoot:HandleLoot()
    local lootPiles = API.ReadAllObjectsArray({3},{-1},{})
    local lootPosition = FFPOINT.new(State.playerPosition.x + Data.lootPosition, State.playerPosition.y, 0)
    API.DoAction_TileF(lootPosition)
    Logger:Info("Moving to loot")
    API.WaitUntilMovingEnds(10, 6)

    if State.hasTimeWarpBuff then
        Utils:forceUseTimeWarpBuff()
    end
    
    if #lootPiles > 0 then
        if not API.LootWindowOpen_2() then 
            Logger:Info("Opening loot window")
            API.DoAction_G_Items1(0x2d, {API.ReadAllObjectsArray({3},{-1},{})[1].Id}, 30)
            API.WaitUntilMovingEnds(6, 10)
        end
        
        if API.LootWindowOpen_2() and (API.LootWindow_GetData()[1].itemid1 > 0) and not State.isLooted then 
            local lootInterface = API.ScanForInterfaceTest2Get(true, { 
                { 1622, 4, -1, 0 }, 
                { 1622, 6, -1, 0 }, 
                { 1622, 1, -1, 0 }, 
                { 1622, 11, -1, 0 } 
            })
            
            local lootInWindow = {}
            for _, value in ipairs(lootInterface) do
                if value.itemid1 ~= -1 then
                    table.insert(lootInWindow, value.itemid1)
                end
            end
            local rares = Utils:findMatchingValues(lootInWindow, Data.rareDrops)
            Data.totalRares = Data.totalRares + #rares
            if #rares > 0 then
                for _, rareDrop in ipairs(rares) do
                    Utils:SendDropNotification(rareDrop)
                end
            end

            local inventorySlotsRemaining = Inventory:FreeSpaces() - #lootInWindow
            
            if inventorySlotsRemaining < 0 then
                local slotsNeeded = -inventorySlotsRemaining
                Logger:Info("Need to free " .. slotsNeeded .. " slots to collect all loot")
                
                for i = 1, slotsNeeded do
                    local foodItem = Utils:WhichFood()
                    local emergencyFoodItem = Utils:WhichEmergencyFood()
                    local emergencyDrinkItem = Utils:WhichEmergencyDrink()
                    
                    if foodItem ~= "" then
                        Logger:Info("Eating " .. foodItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(foodItem)
                        Utils:SleepTickRandom(3)
                    elseif emergencyFoodItem ~= "" then
                        Logger:Info("Eating emergency food " .. emergencyFoodItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(emergencyFoodItem)
                        Utils:SleepTickRandom(3)
                    elseif emergencyDrinkItem ~= "" then
                        Logger:Info("Drinking emergency " .. emergencyDrinkItem .. " to make room for loot (" .. (slotsNeeded - i + 1) .. " remaining)")
                        Inventory:Eat(emergencyDrinkItem)
                        Utils:SleepTickRandom(3)
                    else
                        Logger:Warn("No more consumable items to use, can't collect all loot")
                        API.DoAction_LootAll_Button()
                        State.isLooted = true
                        break
                    end
                end
            else
                Logger:Info("Collecting all loot")
                API.DoAction_LootAll_Button()
            end
        end
        Utils:SleepTickRandom(1)
    end
    local allMatchAllowedIDs = true
    lootPiles = API.ReadAllObjectsArray({3},{-1},{})
    if #lootPiles > 0 then
        for i = 1, #lootPiles do
            local isAllowedID = (lootPiles[i].Id == 15264 or lootPiles[i].Id == 15270 or lootPiles[i].Id == 1513 or lootPiles[i].Id == 44811 or lootPiles[i].Id == 44813)
            if not isAllowedID then
                allMatchAllowedIDs = false
                break
            end
        end
    end
    if allMatchAllowedIDs then
        Logger:Info("No more loot found")
        State.isLooted = true
    end
end

return KerapacLoot