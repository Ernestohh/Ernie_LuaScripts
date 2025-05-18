local API = require("api")
local potionDefinitions = require("potionmixer.potionInfo")
local bankInterface = require("bank")

PotionMixer = {}

PotionMixer.States = {
    INITIALIZING = "INITIALIZING",
    IDLE = "IDLE",
    MIXING = "MIXING",
    BANKING = "BANKING",
    UPGRADING = "UPGRADING",
    ERROR = "ERROR"
}

PotionMixer.currentState = PotionMixer.States.INITIALIZING
PotionMixer.selectedPotionIngredientIds = {}
PotionMixer.selectedPotionName = ""
PotionMixer.isPresetCreated = false
PotionMixer.cachedBankItems = {}
PotionMixer.amountOfPotionsToMake = 0
PotionMixer.isMixing = false

PotionMixer.Data = {
    version = "1.1",
    sessionXpGained = 0,
    totalPotionsMixed = 0,
    presetChanges = 0,
    potionsPerHour = 0,
    xpPerHour = 0,
    startingXp = 0,
    startTime = os.time()
}

function PotionMixer:sleepWithRandomVariation(baseTicks)
    local minimumSleep = baseTicks * 600 + 100
    local maximumSleep = baseTicks * 600 + 1200
    API.RandomSleep2(minimumSleep, maximumSleep, maximumSleep)
end

function PotionMixer:removeColorTagsFromItemName(itemName)
    if not itemName then return "" end
    local cleanedName = string.gsub(itemName, "^<col=[^>]*>", "")
    return cleanedName
end

function PotionMixer:findBankItemById(bankItemArray, targetItemId)
    for i = 1, #bankItemArray do
        local currentItem = bankItemArray[i]
        if currentItem.itemid1 == targetItemId then
            return currentItem
        end
    end
    return nil
end

function PotionMixer:findBankItemByName(bankItemArray, targetItemName)
    for i = 1, #bankItemArray do
        local cleanName = self:removeColorTagsFromItemName(bankItemArray[i].textitem)
        if cleanName == targetItemName then
            return bankItemArray[i]
        end
    end
    return nil
end

function PotionMixer:validatePotionCanBeCrafted(bankItemArray, potionDefinition)
    if #potionDefinition.craft_items == 0 then
        return false
    end
    
    for j = 1, #potionDefinition.craft_items do
        local requiredIngredient = potionDefinition.craft_items[j]
        local availableItem = self:findBankItemById(bankItemArray, requiredIngredient.id)
        
        if not availableItem then
            return false
        end
    end
    
    return true
end

function PotionMixer:getAllCraftablePotions(bankItemArray, currentHerbloreLevel)
    local craftablePotionsList = {}
    
    for i = 1, #potionDefinitions do
        local potionDefinition = potionDefinitions[i]
        
        local meetsLevelRequirement = true
        if potionDefinition.level_required and currentHerbloreLevel < potionDefinition.level_required then
            meetsLevelRequirement = false
        end
        
        local hasEnoughIngredients = #potionDefinition.craft_items >= 2
        
        if meetsLevelRequirement and hasEnoughIngredients and self:validatePotionCanBeCrafted(bankItemArray, potionDefinition) then
            table.insert(craftablePotionsList, potionDefinition)
        end
    end
    
    return craftablePotionsList
end

function PotionMixer:identifyMissingIngredients(bankItemArray, potionDefinition)
    local missingIngredientsList = {}
    
    for j = 1, #potionDefinition.craft_items do
        local requiredIngredient = potionDefinition.craft_items[j]
        local availableItem = self:findBankItemById(bankItemArray, requiredIngredient.id)
        
        if not availableItem then
            table.insert(missingIngredientsList, requiredIngredient)
        end
    end
    
    return missingIngredientsList
end

function PotionMixer:getAvailablePotionIngredients(bankItemArray)
    local availableIngredientsList = {}
    
    local allKnownIngredientIds = {}
    for i = 1, #potionDefinitions do
        for j = 1, #potionDefinitions[i].craft_items do
            local ingredientId = potionDefinitions[i].craft_items[j].id
            allKnownIngredientIds[ingredientId] = true
        end
    end
    
    for i = 1, #bankItemArray do
        local itemId = bankItemArray[i].itemid1
        if allKnownIngredientIds[itemId] then
            table.insert(availableIngredientsList, bankItemArray[i])
        end
    end
    
    return availableIngredientsList
end

function PotionMixer:findPotionsUsingSpecificIngredient(targetIngredientId)
    local potionsUsingIngredient = {}
    
    for i = 1, #potionDefinitions do
        local potionDefinition = potionDefinitions[i]
        for j = 1, #potionDefinition.craft_items do
            if potionDefinition.craft_items[j].id == targetIngredientId then
                table.insert(potionsUsingIngredient, potionDefinition)
                break
            end
        end
    end
    
    return potionsUsingIngredient
end

function PotionMixer:getCurrentHerbloreLevel()
    local herbloreLevel = API.GetSkillByName("HERBLORE").level
    print("Current Herblore level: " .. herbloreLevel)
    return herbloreLevel
end

function PotionMixer:analyzeBankForAvailablePotions()
    local allBankItems = API.FetchBankArray()
    local herbloreLevel = API.GetSkillByName("HERBLORE").level
    
    local craftablePotions = self:getAllCraftablePotions(allBankItems, herbloreLevel)
    
    print("=== POTION CRAFTING ANALYSIS ===")
    print("You can craft " .. #craftablePotions .. " different potions:")
    
    for i = 1, #craftablePotions do
        local potionDefinition = craftablePotions[i]
        print("  V " .. potionDefinition.name .. " (Level " .. (potionDefinition.level_required or "?") .. ")")
    end
    
    print("\n=== MISSING INGREDIENTS CHECK ===")
    local priorityPotions = {"Attack potion (3)", "Strength potion (3)", "Defence potion (3)", "Prayer potion (3)"}
    
    for i = 1, #priorityPotions do
        local potionName = priorityPotions[i]
        
        local targetPotionDefinition = nil
        for j = 1, #potionDefinitions do
            if potionDefinitions[j].name == potionName then
                targetPotionDefinition = potionDefinitions[j]
                break
            end
        end
        
        if targetPotionDefinition then
            if self:validatePotionCanBeCrafted(allBankItems, targetPotionDefinition) then
                print("  V " .. potionName .. " - Ready to craft!")
            else
                local missingIngredients = self:identifyMissingIngredients(allBankItems, targetPotionDefinition)
                if #missingIngredients > 0 then
                    print("  X " .. potionName .. " - Missing:")
                    for k = 1, #missingIngredients do
                        print("    - " .. missingIngredients[k].name .. " (ID: " .. missingIngredients[k].id .. ")")
                    end
                else
                    print("  X " .. potionName .. " - Level too low (need " .. (targetPotionDefinition.level_required or "?") .. ")")
                end
            end
        end
    end
    
    return craftablePotions
end

function PotionMixer:determineOptimalPotionToCraft()
    local allBankItems = API.FetchBankArray()
    local herbloreLevel = API.GetSkillByName("HERBLORE").level
    local craftablePotions = self:getAllCraftablePotions(allBankItems, herbloreLevel)
    
    if #craftablePotions == 0 then
        print("No potions can be crafted with current ingredients and level")
        return nil
    end
    
    local optimalPotion = craftablePotions[1]
    for i = 2, #craftablePotions do
        local potionCandidate = craftablePotions[i]
        if potionCandidate.level_required and optimalPotion.level_required then
            if potionCandidate.level_required > optimalPotion.level_required then
                optimalPotion = potionCandidate
            end
        end
    end
    
    print("Best potion to make: " .. optimalPotion.name .. " (Level " .. (optimalPotion.level_required or "?") .. ")")
    return optimalPotion
end

function PotionMixer:identifyNextLevelPotions()
    local allBankItems = API.FetchBankArray()
    local herbloreLevel = API.GetSkillByName("HERBLORE").level
    
    print("\n=== CHECKING FUTURE OPPORTUNITIES ===")
    
    local nextBestPotionDefinition = nil
    local nextBestLevelRequirement = 999
    
    for i = 1, #potionDefinitions do
        local potionDefinition = potionDefinitions[i]
        if potionDefinition.level_required and potionDefinition.level_required > herbloreLevel and self:validatePotionCanBeCrafted(self.cachedBankItems, potionDefinition) then
            if potionDefinition.level_required < nextBestLevelRequirement then
                nextBestPotionDefinition = potionDefinition
                nextBestLevelRequirement = potionDefinition.level_required
            end
        end
    end
    
    if nextBestPotionDefinition then
        local levelsUntilUnlock = nextBestLevelRequirement - herbloreLevel
        print("Next craftable potion: " .. nextBestPotionDefinition.name .. " (Level " .. nextBestLevelRequirement .. " - " .. levelsUntilUnlock .. " levels away)")
        return nextBestPotionDefinition
    else
        print("No future potions available with current ingredients")
        return nil
    end
end

function PotionMixer:checkForLevelUpAndBetterPotions()
    print("[DEBUG shouldUpdatePotion] Starting level check...")
    local currentLevel = API.GetSkillByName("HERBLORE").level
    
    print("[DEBUG shouldUpdatePotion] Using stored bank items (" .. #self.cachedBankItems .. " items)")
    
    print("[DEBUG shouldUpdatePotion] Current level: " .. currentLevel)
    print("[DEBUG shouldUpdatePotion] Current potion ingredients: " .. #self.selectedPotionIngredientIds .. " items")
    
    local newCraftablePotions = self:getAllCraftablePotions(self.cachedBankItems, currentLevel)
    print("[DEBUG shouldUpdatePotion] Found " .. #newCraftablePotions .. " craftable potions")
    
    local bestAvailablePotion = nil
    for i = 1, #newCraftablePotions do
        local potionCandidate = newCraftablePotions[i]
        if not bestAvailablePotion or (potionCandidate.level_required and bestAvailablePotion.level_required and potionCandidate.level_required > bestAvailablePotion.level_required) then
            bestAvailablePotion = potionCandidate
        end
    end
    
    if bestAvailablePotion then
        print("[DEBUG shouldUpdatePotion] Best current potion: " .. bestAvailablePotion.name .. " (Level " .. (bestAvailablePotion.level_required or "?") .. ")")
    else
        print("[DEBUG shouldUpdatePotion] No best current potion found")
        return nil
    end
    
    if bestAvailablePotion and (#bestAvailablePotion.craft_items >= 2) then
        local newIngredientIds = {}
        for i = 1, #bestAvailablePotion.craft_items do
            table.insert(newIngredientIds, bestAvailablePotion.craft_items[i].id)
        end
        
        local ingredientsDifferent = false
        if #newIngredientIds ~= #self.selectedPotionIngredientIds then
            ingredientsDifferent = true
        else
            for i = 1, #newIngredientIds do
                if newIngredientIds[i] ~= self.selectedPotionIngredientIds[i] then
                    ingredientsDifferent = true
                    break
                end
            end
        end
        
        if ingredientsDifferent then
            print("[DEBUG shouldUpdatePotion] Ingredients are different, checking if better...")
            
            local currentBestLevelRequirement = 0
            if self.selectedPotionName ~= "" then
                for i = 1, #potionDefinitions do
                    if potionDefinitions[i].name == self.selectedPotionName and potionDefinitions[i].level_required then
                        currentBestLevelRequirement = potionDefinitions[i].level_required
                        break
                    end
                end
            end
            
            print("[DEBUG shouldUpdatePotion] Current best level: " .. currentBestLevelRequirement .. ", New level: " .. (bestAvailablePotion.level_required or 0))
            
            if bestAvailablePotion.level_required and bestAvailablePotion.level_required > currentBestLevelRequirement then
                print("\n=== LEVEL UP DETECTED ===")
                print("Current potion: " .. self.selectedPotionName .. " (Level " .. currentBestLevelRequirement .. ")")
                print("New better potion available: " .. bestAvailablePotion.name .. " (Level " .. bestAvailablePotion.level_required .. ")")
                return bestAvailablePotion
            else
                print("Checked for better potions - current setup is still optimal")
            end
        else
            print("Checked for new potions - no changes needed")
        end
    end
    
    print("[DEBUG shouldUpdatePotion] No update needed")
    return nil
end

function PotionMixer:ensureBankIsOpen()
    if not bankInterface:IsOpen() then
        bankInterface:Open()
        API.RandomSleep2(2000,2000,3000)
    end
end

function PotionMixer:hasAllIngredients()
    if #self.selectedPotionIngredientIds == 0 then
        return false
    end
    
    for i = 1, #self.selectedPotionIngredientIds do
        if not Inventory:Contains({self.selectedPotionIngredientIds[i]}) then
            return false
        end
    end
    return true
end

function PotionMixer:configureBankPresetWithIngredients(potionDefinition)
    self:ensureBankIsOpen()
    bankInterface:DepositInventory()
    bankInterface:SetQuantity("X")
    
    local quantityPerIngredient = math.floor(28 / #potionDefinition.craft_items)
    bankInterface:SetXQuantity(quantityPerIngredient)
    
    local ingredientIds = {}
    for i = 1, #potionDefinition.craft_items do
        table.insert(ingredientIds, potionDefinition.craft_items[i].id)
    end
    
    bankInterface:Withdraw(ingredientIds)
    self:sleepWithRandomVariation(1)
    bankInterface:SavePreset(1)
end

function PotionMixer:createBankPresetForPotion(potionDefinition, reasonForCreation)
    if #potionDefinition.craft_items < 2 then
        print("Cannot create preset: " .. potionDefinition.name .. " needs " .. #potionDefinition.craft_items .. " ingredients")
        return false
    end
    
    if self.selectedPotionName == potionDefinition.name and self.isPresetCreated then
        print("Preset already configured for " .. potionDefinition.name .. " - no changes needed")
        return true
    end
    
    print("\n=== CREATING PRESET ===")
    print("Reason: " .. reasonForCreation)
    print("Potion: " .. potionDefinition.name)
    print("Ingredients: " .. #potionDefinition.craft_items .. " items")
    for i = 1, #potionDefinition.craft_items do
        print("  - " .. potionDefinition.craft_items[i].name)
    end
    
    self:configureBankPresetWithIngredients(potionDefinition)
    
    self.selectedPotionIngredientIds = {}
    for i = 1, #potionDefinition.craft_items do
        table.insert(self.selectedPotionIngredientIds, potionDefinition.craft_items[i].id)
    end
    self.selectedPotionName = potionDefinition.name
    self.isPresetCreated = true
    
    print("V Preset created successfully!")
    local ingredientNames = {}
    for i = 1, #potionDefinition.craft_items do
        table.insert(ingredientNames, potionDefinition.craft_items[i].name)
    end
    print("V Auto-mixing configured for: " .. table.concat(ingredientNames, " + "))
    return true
end

function PotionMixer:debugMissingItemsForPotion(potionDefinition)
    local allBankItems = API.FetchBankArray()
    print("\n=== DEBUGGING MISSING ITEMS FOR: " .. potionDefinition.name .. " ===")
    
    for j = 1, #potionDefinition.craft_items do
        local requiredIngredient = potionDefinition.craft_items[j]
        local searchTargetId = requiredIngredient.id
        local searchTargetName = requiredIngredient.name
        
        print("Looking for: " .. searchTargetName .. " (ID: " .. searchTargetId .. ")")
        
        local foundExactMatch = false
        local similarNamedItems = {}
        
        for i = 1, #allBankItems do
            local bankItem = allBankItems[i]
            local bankItemId = bankItem.itemid1
            local bankItemName = self:removeColorTagsFromItemName(bankItem.textitem)
            
            if bankItemId == searchTargetId then
                print("  V FOUND BY ID: " .. bankItemName .. " (ID: " .. bankItemId .. ")")
                foundExactMatch = true
                break
            end
            
            if bankItemName and string.find(string.lower(bankItemName), string.lower(searchTargetName:sub(1, 4))) then
                table.insert(similarNamedItems, {name = bankItemName, id = bankItemId})
            end
        end
        
        if not foundExactMatch then
            print("  X NOT FOUND BY ID: " .. searchTargetId)
            if #similarNamedItems > 0 then
                print("  Similar items found:")
                for k = 1, math.min(5, #similarNamedItems) do
                    print("    - " .. similarNamedItems[k].name .. " (ID: " .. similarNamedItems[k].id .. ")")
                end
            else
                print("  No similar items found in bank")
            end
        end
    end
    
    print("=== END DEBUG ===\n")
end

function PotionMixer:setupOptimalPotionPreset()
    local optimalPotion = self:determineOptimalPotionToCraft()
    
    if optimalPotion then
        return self:createBankPresetForPotion(optimalPotion, "Best available potion at current level")
    else
        print("\n=== NO CRAFTABLE POTIONS FOUND ===")
        print("No potions can be made at your current level!")
        print("This could be because:")
        print("  - Missing required ingredients in bank")
        print("  - All available potions require higher Herblore level")
        print("  - Potions only have 1 ingredient (need 2+ for presets)")
        print("Check your bank and Herblore level, then restart the script.")
        API.Write_LoopyLoop(false)
    end
end

function PotionMixer:debugSpecificPotionByName(targetPotionName)
    for i = 1, #potionDefinitions do
        if potionDefinitions[i].name == targetPotionName then
            self:debugMissingItemsForPotion(potionDefinitions[i])
            return
        end
    end
    print("Potion not found: " .. targetPotionName)
end

function PotionMixer:updateSessionXp()
    local currentXp = API.GetSkillByName("HERBLORE").xp
    if self.Data.startingXp == 0 then
        self.Data.startingXp = currentXp
    end
    self.Data.sessionXpGained = currentXp - self.Data.startingXp

    local currentTime = os.time()
    local elapsedHours = (currentTime - self.Data.startTime) / 3600
    if elapsedHours > 0 then
        self.Data.xpPerHour = math.floor(self.Data.sessionXpGained / elapsedHours)
    end
end

function PotionMixer:updatePotionsPerHour()
    local currentTime = os.time()
    local elapsedHours = (currentTime - self.Data.startTime) / 3600
    if elapsedHours > 0 then
        self.Data.potionsPerHour = math.floor(self.Data.totalPotionsMixed / elapsedHours)
    end
end

function PotionMixer:trackingData()
    self:updateSessionXp()
    self:updatePotionsPerHour()
    
    local currentMixingStatus = "Idle"
    if self.currentState == self.States.MIXING then
        currentMixingStatus = "Mixing " .. (self.selectedPotionName or "Unknown")
    elseif self.selectedPotionName and self.selectedPotionName ~= "" then
        currentMixingStatus = "Ready: " .. self.selectedPotionName
    end
    
    local data = {
        { "Ernie's Potion Mixer ", "Version: " .. self.Data.version },
        { "-------", "-------" },
        { "Runtime:", API.ScriptRuntimeString() },
        { "- Current Level", API.GetSkillByName("HERBLORE").level},
        { "- Session XP Gained", self.Data.sessionXpGained},
        { "- XP/Hour", self.Data.xpPerHour},
        { "- Total Potions Mixed", self.Data.totalPotionsMixed},
        { "- Current Status", currentMixingStatus},
        { "- Current State", self.currentState},
        { "- Preset Changes", self.Data.presetChanges},
        { "- Potions/Hour", self.Data.potionsPerHour},
        { "-------", "-------" },
    }
    
    API.DrawTable(data)
end

function PotionMixer:handleInitializing()
    print("=== HERBLORE ASSISTANT ===")
    
    self:ensureBankIsOpen()
    
    self.cachedBankItems = API.FetchBankArray()
    print("V Stored " .. #self.cachedBankItems .. " bank items for level-up detection")
    
    local herbloreLevel = self:getCurrentHerbloreLevel()
    
    local craftablePotions = self:analyzeBankForAvailablePotions()
    
    local availableIngredients = self:getAvailablePotionIngredients(self.cachedBankItems)
    print("\n=== HERBLORE INGREDIENTS IN BANK ===")
    print("You have " .. #availableIngredients .. " herblore ingredients:")
    for i = 1, #availableIngredients do
        local cleanName = self:removeColorTagsFromItemName(availableIngredients[i].textitem)
        print("  - " .. cleanName .. " (ID: " .. availableIngredients[i].itemid1 .. ")")
    end
    
    local futurePotion = self:identifyNextLevelPotions()
    if futurePotion then
        print("Future opportunity: " .. futurePotion.name .. " at level " .. futurePotion.level_required)
    end
    
    local presetCreationSuccess = self:setupOptimalPotionPreset()
    
    if presetCreationSuccess == nil then
        print("\n=== SCRIPT STOPPED ===")
        print("No valid potions to craft. Exiting...")
    elseif presetCreationSuccess then
        print("\n=== READY TO CRAFT ===")
        print("Preset has been set up for current level potions. Loading preset...")
        
        if API.FindNPCbyName("Banker", 10).Id ~= 0 then
            Interact:NPC("Banker", "Load Last Preset from", 10)
        elseif #API.GetAllObjArray1({125115}, 10, {0}) > 0 then
            Interact:Object("Bank chest", "Load Last Preset from", 10)
        else
            print("WARNING: No banker or bank chest found!")
        end
        
        local attempts = 0
        local maxAttempts = 50
        local ingredientsLoaded = false
        repeat
            self:sleepWithRandomVariation(0)
            print("[DEBUG] Attempt " .. attempts .. "/" .. maxAttempts)
            print("[DEBUG] selectedPotionIngredientIds count: " .. #self.selectedPotionIngredientIds)
            if #self.selectedPotionIngredientIds > 0 then
                for i = 1, #self.selectedPotionIngredientIds do
                    print("[DEBUG] Looking for ingredient " .. i .. " (ID: " .. self.selectedPotionIngredientIds[i] .. "): " .. tostring(Inventory:Contains({self.selectedPotionIngredientIds[i]})))
                end
            end
            
            if self:hasAllIngredients() then
                ingredientsLoaded = true
            end
            attempts = attempts + 1
        until ingredientsLoaded or attempts >= maxAttempts
        
        if ingredientsLoaded then
            print("V Ingredients loaded successfully!")
            print("You can now start crafting!")
            self.currentState = self.States.IDLE
            print("[DEBUG] State changed to: " .. self.currentState)
            return
        else
            print("WARNING: Preset did not load ingredients within timeout!")
            return
        end
    else
        print("\n=== NO ACTION TAKEN ===")
        print("Unable to create a preset at this time.")
        self.currentState = self.States.ERROR
        return
    end
end

function PotionMixer:handleIdle()
    if #self.selectedPotionIngredientIds > 0  and not self.isMixing then
        print("[DEBUG IDLE] Checking for " .. #self.selectedPotionIngredientIds .. " ingredients:")
        for i = 1, #self.selectedPotionIngredientIds do
            print("[DEBUG IDLE] Has ingredient " .. i .. " (ID: " .. self.selectedPotionIngredientIds[i] .. "): " .. tostring(Inventory:Contains({self.selectedPotionIngredientIds[i]})))
        end
        
        if self:hasAllIngredients() then
            if not self.isMixing then
                print("Mixing")
                if #API.GetAllObjArray1({89770}, 10, {0}) > 0 then
                    Interact:Object("Portable well", "Mix Potions", 10)
                    self.currentState = self.States.MIXING
                    local attempts = 0
                    local maxAttempts = 10
                    local interfaceReady = false
                    repeat
                        self:sleepWithRandomVariation(0)
                        local interfaceElements = API.ScanForInterfaceTest2Get(false, { { 1370,0,-1,0 }, { 1370,2,-1,0 }, { 1370,4,-1,0 }, { 1370,5,-1,0 }, { 1370,13,-1,0 } })
                        for i = 1, #interfaceElements do
                            local cleanTextids = interfaceElements[i].textids
                            if cleanTextids then
                                cleanTextids = string.gsub(cleanTextids, "<br>", "")
                                if cleanTextids == self.selectedPotionName then
                                    print("[DEBUG] Found match! Setting interfaceReady = true")
                                    interfaceReady = true
                                    break
                                end
                            end
                        end
                        print("[DEBUG] End of attempt " .. attempts .. ", interfaceReady = " .. tostring(interfaceReady))
                        attempts = attempts + 1
                    until interfaceReady or attempts >= maxAttempts

                    if attempts >= maxAttempts then
                        print("WARNING: Mixing interface did not show " .. self.selectedPotionName .. " within timeout, stopping script")
                        API.Write_LoopyLoop(false)
                    end

                    self.amountOfPotionsToMake = API.VB_FindPSett(8847).state
                    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)
                    self:sleepWithRandomVariation(1)
                else
                    print("No Portable well found. Stopping script")
                    self.currentState = self.States.ERROR
                end
            end
        else
            print("[DEBUG IDLE] Missing ingredients - staying in IDLE")
        end
    else
        print("[DEBUG IDLE] No potion ingredients configured")
    end
end

function PotionMixer:handleMixing()
    if API.ScanForInterfaceTest2Get(false, { { 1251,8,-1,0 }, { 1251,36,-1,0 }, { 1251,0,-1,0 } })[1].itemid1 == 0 then
        print("Banking")
        if self.amountOfPotionsToMake > 0 then
            self.Data.totalPotionsMixed = self.Data.totalPotionsMixed + self.amountOfPotionsToMake
            print("Completed " .. self.amountOfPotionsToMake .. " potions (Total: " .. self.Data.totalPotionsMixed .. ")")
        end
        self.currentState = self.States.BANKING
    end
end

function PotionMixer:handleBanking()
    local improvedPotion = self:checkForLevelUpAndBetterPotions()
    if improvedPotion then
        self.currentState = self.States.UPGRADING
        self.upgradePotion = improvedPotion
    else
        self.isMixing = false
        if Inventory:Contains({24154}) then
            API.DoAction_Inventory1(24154, 0, 8, API.OFF_ACT_GeneralInterface_route2)
        end
        if API.FindNPCbyName("Banker", 10).Id ~= 0 then
            Interact:NPC("Banker", "Load Last Preset from", 10)
        elseif #API.GetAllObjArray1({125115}, 10, {0}) > 0 then
            Interact:Object("Bank chest", "Load Last Preset from", 10)
        end
        
        local attempts = 0
        local maxAttempts = 50
        local ingredientsLoaded = false
        repeat
            self:sleepWithRandomVariation(0)
            print("[DEBUG] Attempt " .. attempts .. "/" .. maxAttempts)
            print("[DEBUG] selectedPotionIngredientIds count: " .. #self.selectedPotionIngredientIds)
            if #self.selectedPotionIngredientIds > 0 then
                for i = 1, #self.selectedPotionIngredientIds do
                    print("[DEBUG] Looking for ingredient " .. i .. " (ID: " .. self.selectedPotionIngredientIds[i] .. "): " .. tostring(Inventory:Contains({self.selectedPotionIngredientIds[i]})))
                end
            end
            
            if self:hasAllIngredients() then
                ingredientsLoaded = true
            end
            attempts = attempts + 1
        until ingredientsLoaded or attempts >= maxAttempts
        
        if ingredientsLoaded then
            self.currentState = self.States.IDLE
            return
        else
            print("\n=== OUT OF INGREDIENTS ===")
            print("Failed to load preset - likely ran out of ingredients!")
            print("Restarting one more time!")
            self.currentState = self.States.ERROR 
            return
        end
    end
end

function PotionMixer:handleUpgrading()
    print("=== CREATING NEW PRESET FOR BETTER POTION ===")
    self:ensureBankIsOpen()
    
    local presetCreationSuccess = self:createBankPresetForPotion(self.upgradePotion, "Level up - better potion available")
    if presetCreationSuccess then
        print("V Successfully updated to better potion: " .. self.upgradePotion.name)
        local ingredientNames = {}
        for i = 1, #self.upgradePotion.craft_items do
            table.insert(ingredientNames, self.upgradePotion.craft_items[i].name)
        end
        print("V New preset created with ingredients: " .. table.concat(ingredientNames, " + "))
        self.Data.presetChanges = self.Data.presetChanges + 1
        self.currentState = self.States.IDLE
        return
    else
        print("X Failed to create new preset")
        self.currentState = self.States.ERROR
        return
    end
    self.upgradePotion = nil
end

function PotionMixer:handleError()
    print("Error state - attempting to reinitialize...")
    self:sleepWithRandomVariation(5)
    self.currentState = self.States.INITIALIZING
    return
end

function PotionMixer:executeStateMachine()
    if self.currentState == self.States.INITIALIZING then
        self:handleInitializing()
    elseif self.currentState == self.States.IDLE then
        self:handleIdle()
    elseif self.currentState == self.States.MIXING then
        self:handleMixing()
    elseif self.currentState == self.States.BANKING then
        self:handleBanking()
    elseif self.currentState == self.States.UPGRADING then
        self:handleUpgrading()
    elseif self.currentState == self.States.ERROR then
        self:handleError()
    end
end

while API.Read_LoopyLoop() do
    PotionMixer:trackingData()
    PotionMixer:executeStateMachine()
    PotionMixer:sleepWithRandomVariation(0)
end