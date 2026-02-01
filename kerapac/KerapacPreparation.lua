local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")

local KerapacPreparation = {}

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

function KerapacPreparation:OpenPresetInterface()
    if API.GetVarbitValue(45223) ~= 1 then
        Logger:Info("Opening preset interface")
        API.DoAction_Interface(0x2e, 0xffffffff, 1, 517, 153, -1, API.OFF_ACT_GeneralInterface_route)
        Utils:SleepTickRandom(2)
        return API.GetVarbitValue(45223) == 1
    end
    return true
end

function KerapacPreparation:EnsureCorrectPresetPage(presetNumber)
    local needsPage2 = presetNumber > 9
    local currentPage = API.GetVarbitValue(49662)

    if needsPage2 and currentPage == 0 then
        Logger:Info("Switching to preset page 2")
        API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, 100, API.OFF_ACT_GeneralInterface_route)
        Utils:SleepTickRandom(2)
        return true
    elseif not needsPage2 and currentPage == 1 then
        Logger:Info("Switching to preset page 1")
        API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, 100, API.OFF_ACT_GeneralInterface_route)
        Utils:SleepTickRandom(2)
        return true
    end
    return true
end

function KerapacPreparation:LoadPresetNumber(presetNumber)
    local interfacePresetNum = presetNumber
    if presetNumber > 9 then
        interfacePresetNum = presetNumber - 9
    end

    Logger:Info("Loading preset " .. presetNumber)
    API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, interfacePresetNum, API.OFF_ACT_GeneralInterface_route)
    Utils:SleepTickRandom(3)
end

function KerapacPreparation:HandlePrebuffPreset()
    if not Data.prebuffEnabled or State.isPrebuffComplete then
        return
    end

    if not State.needsPrebuff then
        return
    end

    --[[if self:CheckPrebuffsActive() then
        Logger:Info("All prebuffs already active, skipping prebuff process")
        State.isPrebuffComplete = true
        State.needsPrebuff = false
        State.hasPrebuffLoaded = true
        return
    end]]--

    Logger:Info("Starting prebuff process")
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route1, { 114750 }, 50)
    API.WaitUntilMovingEnds(10, 4)

    for attempt = 1, 10 do
        if API.BankOpen2() then break end
        Logger:Debug("Waiting for bank to open... attempt " .. attempt)
        Utils:SleepTickRandom(4)
    end

    if not API.BankOpen2() then
        Logger:Error("Bank not open for prebuff preset after retries")
        return
    end

    self:HandleBankPin()
    Utils:SleepTickRandom(2)

    if not self:OpenPresetInterface() then
        Logger:Error("Failed to open preset interface")
        return
    end

    self:EnsureCorrectPresetPage(Data.prebuffPreset)
    self:LoadPresetNumber(Data.prebuffPreset)
    State.hasPrebuffLoaded = true
    Utils:SleepTickRandom(2)
    self:ApplyPrebuffs()

    State.isPrebuffComplete = true
    State.needsPrebuff = false
    State.hasLoadedMainPreset = false
    Logger:Info("Prebuff process complete")
end

function KerapacPreparation:ApplyPrebuffs()
    Logger:Info("Applying prebuffs...")

    -- Inventory detection
    local hasKwuarm = Inventory:Contains(47709)
    local hasLantadyme = Inventory:Contains(47713)
    local hasSpiritWeed = Inventory:Contains(47705)
    local hasThermalFlask = Inventory:ContainsAny({38403, 47637, 47639, 47641, 47643, 47645})
    local hasDivineCharges = Inventory:Contains(36390)

    local runePouches = Utils:WhichRunePouches()
    local runes = Utils:WhichRunes()
    local summoningPouches = Utils:WhichFamiliar()
    local summoningScrolls = Utils:WhichSummoningScrolls()
    local scriptures = Utils:WhichScriptures()
    local scripturePages = Utils:WhichScripturePages()

    Logger:Info("Inventory detected:")
    Logger:Info("  Kwuarm: " .. tostring(hasKwuarm))
    Logger:Info("  Lantadyme: " .. tostring(hasLantadyme))
    Logger:Info("  Spirit Weed: " .. tostring(hasSpiritWeed))
    Logger:Info("  Thermal Flask: " .. tostring(hasThermalFlask))
    Logger:Info("  Divine Charges: " .. tostring(hasDivineCharges))
    Logger:Info("  Rune Pouches: " .. #runePouches)
    Logger:Info("  Runes: " .. #runes)
    Logger:Info("  Summoning Pouches: " .. #summoningPouches)
    Logger:Info("  Summoning Scrolls: " .. #summoningScrolls)
    Logger:Info("  Scriptures: " .. #scriptures)
    Logger:Info("  Scripture Pages: " .. #scripturePages)

    if Data.prebuffKwuarm and hasKwuarm then
        local buffStatus = API.Buffbar_GetIDstatus(47709)
        local potency = buffStatus.found and tonumber(buffStatus.text) or 0

        if not buffStatus.found or potency < 4 then
            Logger:Info("Overloading Kwuarm incense stick")
            API.DoAction_Inventory1(47709, 0, 2, API.OFF_ACT_GeneralInterface_route)
            Utils:SleepTickRandom(1)
        end

        local function getBuffMinutes()
            local status = API.Buffbar_GetIDstatus(47709)
            if not status.found then return 0 end
            local minutes = tonumber(tostring(status.text):match("(%d+)m"))
            return minutes or 0
        end

        local currentMinutes = getBuffMinutes()
        local usesNeeded = math.floor((51 - currentMinutes) / 10)
        if usesNeeded > 0 then
            Logger:Info("Kwuarm incense needs " .. usesNeeded .. " uses (currently " .. currentMinutes .. "m)")
            for i = 1, usesNeeded do
                Logger:Info("Adding time to Kwuarm incense (" .. i .. "/" .. usesNeeded .. ")")
                API.DoAction_Inventory1(47709, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Utils:SleepTickRandom(1)
            end
        end

        Logger:Info("Kwuarm incense ready: " .. getBuffMinutes() .. "m")
    end

    if Data.prebuffLantadyme and hasLantadyme then
        local buffStatus = API.Buffbar_GetIDstatus(47713)
        local potency = buffStatus.found and tonumber(buffStatus.text) or 0

        if not buffStatus.found or potency < 4 then
            Logger:Info("Overloading Lantadyme incense stick")
            API.DoAction_Inventory1(47713, 0, 2, API.OFF_ACT_GeneralInterface_route)
            Utils:SleepTickRandom(1)
        end

        local function getBuffMinutes()
            local status = API.Buffbar_GetIDstatus(47713)
            if not status.found then return 0 end
            local minutes = tonumber(tostring(status.text):match("(%d+)m"))
            return minutes or 0
        end

        local currentMinutes = getBuffMinutes()
        local usesNeeded = math.floor((51 - currentMinutes) / 10)
        if usesNeeded > 0 then
            Logger:Info("Lantadyme incense needs " .. usesNeeded .. " uses (currently " .. currentMinutes .. "m)")
            for i = 1, usesNeeded do
                Logger:Info("Adding time to Lantadyme incense (" .. i .. "/" .. usesNeeded .. ")")
                API.DoAction_Inventory1(47713, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Utils:SleepTickRandom(1)
            end
        end

        Logger:Info("Lantadyme incense ready: " .. getBuffMinutes() .. "m")
    end

    if Data.prebuffSpiritWeed and hasSpiritWeed then
        local buffStatus = API.Buffbar_GetIDstatus(47705)
        local potency = buffStatus.found and tonumber(buffStatus.text) or 0

        if not buffStatus.found or potency < 4 then
            Logger:Info("Overloading Spirit weed incense stick")
            API.DoAction_Inventory1(47705, 0, 2, API.OFF_ACT_GeneralInterface_route)
            Utils:SleepTickRandom(1)
        end

        local function getBuffMinutes()
            local status = API.Buffbar_GetIDstatus(47705)
            if not status.found then return 0 end
            local minutes = tonumber(tostring(status.text):match("(%d+)m"))
            return minutes or 0
        end

        local currentMinutes = getBuffMinutes()
        local usesNeeded = math.floor((51 - currentMinutes) / 10)
        if usesNeeded > 0 then
            Logger:Info("Spirit weed incense needs " .. usesNeeded .. " uses (currently " .. currentMinutes .. "m)")
            for i = 1, usesNeeded do
                Logger:Info("Adding time to Spirit weed incense (" .. i .. "/" .. usesNeeded .. ")")
                API.DoAction_Inventory1(47705, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Utils:SleepTickRandom(1)
            end
        end

        Logger:Info("Spirit weed incense ready: " .. getBuffMinutes() .. "m")
    end

    if Data.prebuffThermalFlask and hasThermalFlask then
        if not API.Buffbar_GetIDstatus(47637).found then
            Logger:Info("Using Thermal flask")
            local thermalFlaskIds = {38403,47637,47639,47641,47643,47645}
            local found = false
            for _, id in ipairs(thermalFlaskIds) do
                if Inventory:Contains(id) then
                        API.DoAction_Inventory1(id, 0, 1, API.OFF_ACT_GeneralInterface_route)
                        Utils:SleepTickRandom(2)
                    break
                end
            end
        else
            Logger:Info("Thermal flask buff already active")
        end
    end

    if Data.prebuffDivineCharges and hasDivineCharges and (API.VB_FindPSett(5984).state - 1488)/3000 < 495000 then
        Logger:Info("Using Divine charges")
        API.DoAction_Inventory1(36390,0,7,API.OFF_ACT_GeneralInterface_route2)
        Utils:SleepTickRandom(2)
    end

    if Data.prebuffWarsBonfire then
        if not API.Buffbar_GetIDstatus(10931).found then
            Logger:Info("Using War's Bonfire")
            API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, { 114758 }, 50)
            API.WaitUntilMovingandAnimEnds(10, 4)
            Utils:SleepTickRandom(2)
        else
            Logger:Info("War's Bonfire buff already active")
        end
    end

    if Data.prebuffRefillScriptures then
        local scripturesWithIds = Utils:GetScriptureInventoryIds()

        if #scripturesWithIds == 0 then
            Logger:Info("No scriptures in inventory, skipping refill")
        else
            for _, scriptureData in ipairs(scripturesWithIds) do
                local scriptureName = scriptureData.name
                local scriptureId = scriptureData.id
                local secondsRemaining = Utils:GetScriptureSecondsRemaining(scriptureId)
                Logger:Info(scriptureName .. " (ID: " .. scriptureId .. ") has " .. math.floor(secondsRemaining) .. " seconds remaining")

                local pageName = Utils:GetScripturePageName(scriptureName)

                if pageName then
                    local pageCount = Inventory:InvItemcountStack_Strings(pageName)

                    if pageCount == 0 then
                        Logger:Info("No " .. pageName .. " in inventory for " .. scriptureName)
                    else
                        if secondsRemaining < 3600 then
                            Logger:Info("Refilling " .. scriptureName .. " with " .. pageName .. " (" .. pageCount .. " available)")
                            API.DoAction_Inventory1(Item:Get(pageName).id, 0, 2, API.OFF_ACT_GeneralInterface_route)
                            Utils:SleepTickRandom(2)
                        else
                            Logger:Info(scriptureName .. " has sufficient time, no refill needed")
                        end
                    end
                else
                    Logger:Info("No matching page found for scripture: " .. scriptureName)
                end
            end
        end
    end

    if Data.prebuffRefillRunePouches then
        local runePouchesWithIds = Utils:GetRunePouchInventoryIds()
        local runes = Utils:WhichRunes()

        if #runePouchesWithIds == 0 then
            Logger:Info("No rune pouches in inventory, disabling rune pouch refill")
            Data.prebuffRefillRunePouches = false
        elseif #runes == 0 then
            Logger:Info("No runes in inventory, disabling rune pouch refill")
            Data.prebuffRefillRunePouches = false
        else
            local totalRefills = 0

            for _, pouchData in ipairs(runePouchesWithIds) do
                local pouchName = pouchData.name
                local pouchId = pouchData.id
                local runesNeedingRefill = Utils:GetRunesNeedingRefillInPouch(pouchId, 1000)

                if #runesNeedingRefill > 0 then
                    Logger:Info(pouchName .. " needs " .. #runesNeedingRefill .. " rune(s) refilled")

                    for _, runeData in ipairs(runesNeedingRefill) do
                        local runeName = runeData.name
                        local currentCount = runeData.count

                        if Inventory:Contains(runeName) then
                            local runeId = Item:Get(runeName).id
                            Logger:Info("Refilling " .. runeName .. " in " .. pouchName .. " (current: " .. currentCount .. ")")
                            API.DoAction_Inventory1(runeId, 0, 0, API.OFF_ACT_Bladed_interface_route)
                            Utils:SleepTickRandom(0)
                            API.DoAction_DontResetSelection()
                            API.DoAction_Inventory1(pouchId, 0, 0, API.OFF_ACT_GeneralInterface_route1)
                            Utils:SleepTickRandom(1)
                            totalRefills = totalRefills + 1
                        else
                            Logger:Debug(runeName .. " not in inventory, cannot refill " .. pouchName)
                        end
                    end
                else
                    Logger:Info(pouchName .. " has all runes above 1000, no refill needed")
                end
            end

            if totalRefills > 0 then
                Logger:Info("Rune pouch refill complete: " .. totalRefills .. " rune(s) topped up")
            else
                Logger:Info("All rune pouches have sufficient stock, no refill needed")
            end
        end
    end

    if Data.prebuffSummoning and Data.prebuffSummoningPouch then
        local hasFamiliar = API.GetVarbitValue(31223) == 1
        local familiarTimeLeft = API.GetVarbitValue(6055)

        if hasFamiliar and familiarTimeLeft < 10 then
            Logger:Info("Familiar time remaining: " .. familiarTimeLeft .. "m, summoning new one")
            if Inventory:Contains(Data.prebuffSummoningPouch) then
                local pouchId = Item:Get(Data.prebuffSummoningPouch).id
                API.DoAction_Inventory1(pouchId, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Utils:SleepTickRandom(2)
                Logger:Info("Summoned familiar: " .. Data.prebuffSummoningPouch)
            else
                Logger:Info("No " .. Data.prebuffSummoningPouch .. " in inventory")
            end
        elseif not hasFamiliar then
            Logger:Info("No familiar active, summoning one")
            if Inventory:Contains(Data.prebuffSummoningPouch) then
                local pouchId = Item:Get(Data.prebuffSummoningPouch).id
                API.DoAction_Inventory1(pouchId, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Utils:SleepTickRandom(2)
                Logger:Info("Summoned familiar: " .. Data.prebuffSummoningPouch)
            else
                Logger:Info("No " .. Data.prebuffSummoningPouch .. " in inventory")
            end
        else
            Logger:Info("Familiar has " .. familiarTimeLeft .. "m remaining, no need to resummon")
        end

        if Data.prebuffUseScroll then
            local scrollCount = API.GetVarbitValue(25412)
            if scrollCount < 500 then
                local scrollIndex = nil
                for i, pouchName in ipairs(Data.summoningPouches) do
                    if pouchName == Data.prebuffSummoningPouch then
                        scrollIndex = i
                        break
                    end
                end

                if scrollIndex and Data.summoningScrolls[scrollIndex] then
                    local scrollName = Data.summoningScrolls[scrollIndex]
                    if Inventory:Contains(scrollName) then
                        Logger:Info("Scroll count: " .. scrollCount .. ", refilling with " .. scrollName)
                        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,78,-1,API.OFF_ACT_GeneralInterface_route)
                        Utils:SleepTickRandom(2)
                    else
                        Logger:Info("No " .. scrollName .. " in inventory to refill")
                    end
                end
            else
                Logger:Info("Scroll count: " .. scrollCount .. ", no refill needed")
            end

            local pouch = Data.prebuffSummoningPouch
            if (string.find(pouch, "ripper") or string.find(pouch, "blood reaver")) and Data.prebuffAutofireRate >= 1 and Data.prebuffAutofireRate <= 15 then
                local expectedVb = math.floor(Data.prebuffAutofireRate * 5 / 3)
                local currentVb = API.GetVarbitValue(49035)

                if currentVb == expectedVb then
                    Logger:Info("Autofire rate already set to " .. Data.prebuffAutofireRate .. " (vb: " .. currentVb .. ")")
                else
                    local summoningInterfaceOpen = API.VB_FindPSett(3102).state == 1
                    if summoningInterfaceOpen then
                        Logger:Info("Setting autofire rate to " .. Data.prebuffAutofireRate .. " (current vb: " .. currentVb .. ", expected: " .. expectedVb .. ")")
                        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,74,-1,API.OFF_ACT_GeneralInterface_route)
                        Utils:SleepTickRandom(1)
                        API.TypeOnkeyboard2(tostring(Data.prebuffAutofireRate))
                        Utils:SleepTickRandom(1)
                        API.KeyboardPress2(0x0D, 60, 100)
                        Utils:SleepTickRandom(1)

                        local newVb = API.GetVarbitValue(49035)
                        if newVb == expectedVb then
                            Logger:Info("Autofire rate verified: " .. Data.prebuffAutofireRate .. " (vb: " .. newVb .. ")")
                        else
                            Logger:Warn("Autofire rate may not have been set correctly (vb: " .. newVb .. ", expected: " .. expectedVb .. ")")
                        end
                    else
                        Logger:Info("Summoning interface not open, cannot set autofire rate")
                    end
                end
            end
        end
    end

    Logger:Info("Prebuffs applied")
end

function KerapacPreparation:HandleMainPreset()
    if not Data.prebuffEnabled then
        return
    end

    if not State.isPrebuffComplete then
        return
    end

    Logger:Info("Loading main preset after prebuffing")
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route1, { 114750 }, 50)
    API.WaitUntilMovingEnds(10, 4)

    for attempt = 1, 10 do
        if API.BankOpen2() then break end
        Logger:Debug("Waiting for bank to open... attempt " .. attempt)
        Utils:SleepTickRandom(4)
    end

    if not API.BankOpen2() then
        Logger:Error("Bank not open for main preset after retries")
        return
    end

    self:HandleBankPin()
    Utils:SleepTickRandom(2)

    if not self:OpenPresetInterface() then
        Logger:Error("Failed to open preset interface")
        return
    end

    self:EnsureCorrectPresetPage(Data.mainPreset)
    self:LoadPresetNumber(Data.mainPreset)
    Logger:Info("Main preset loaded")
end

function KerapacPreparation:CheckPrebuffsActive()
    if Data.prebuffKwuarm then
        local status = API.Buffbar_GetIDstatus(47709)
        if not status.found then
            Logger:Debug("Kwuarm incense buff not found")
            return false
        end
    end

    if Data.prebuffLantadyme then
        local status = API.Buffbar_GetIDstatus(47713)
        if not status.found then
            Logger:Debug("Lantadyme incense buff not found")
            return false
        end
    end

    if Data.prebuffSpiritWeed then
        local status = API.Buffbar_GetIDstatus(47705)
        if not status.found then
            Logger:Debug("Spirit weed incense buff not found")
            return false
        end
    end

    if Data.prebuffThermalFlask then
        local thermalFlaskIds = {38403,47637,47639,47641,47643,47645}
        local found = false
        for _, id in ipairs(thermalFlaskIds) do
            if API.Buffbar_GetIDstatus(id).found then
                found = true
                break
            end
        end
        if not found then
            Logger:Debug("Thermal flask buff not found")
            return false
        end
    end

    if Data.prebuffDivineCharges then
        if (API.VB_FindPSett(5984).state - 1488) / 3000 < 15000 then
            Logger:Debug("Divine charges below threshold")
            return false
        end
    end

    if Data.prebuffWarsBonfire then
        local status = API.Buffbar_GetIDstatus(10931)
        if not status.found then
            Logger:Debug("War's Bonfire buff not found")
            return false
        end
    end

    return true
end

function KerapacPreparation:PrepareForBattle()
    Utils:CheckWeaponType()
    Utils:CheckForZukCape()
    Utils:SummonFamiliar()
    Utils:RenewFamiliar()

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
        API.DoAction_Object2(0x29,API.OFF_ACT_GeneralObject_route0,{114749},50,WPOINT.new(3299,10148,0))
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
    if State.isBeginFightComplete then return end
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
    Combat:ManageBuffs()
    Logger:Info("Ready to engage boss")
    State.isBeginFightComplete = true
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
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{27299},50)
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
