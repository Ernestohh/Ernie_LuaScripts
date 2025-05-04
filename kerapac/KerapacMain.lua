local API = require("api")
API.SetDrawLogs(true)

local Data = require("kerapac/KerapacData")
local Core = require("kerapac/KerapacCore")

Core.log("Started Ernie's Kerapac Bosser " .. Data.version)
API.SetMaxIdleTime(5)
API.Write_fake_mouse_do(false)
Core.handleCombatMode()
while (API.Read_LoopyLoop()) do
    if Core.guiVisible then
        Core.DrawGui() 
    end
    
    if Core.startScript then
        if not Core.isInBattle and not Core.isTimeToLoot then
            if not Core.isInWarsRetreat then
                Core.checkStartLocation()
            end
            
            if Core.isInWarsRetreat and not Core.isRestoringPrayer and not Core.isPrepared and API.Read_LoopyLoop() then
                Core.HandlePrayerRestore()
            end

            if Core.isInWarsRetreat and not Core.isBanking and not Core.isPrepared and API.Read_LoopyLoop() then
                Core.HandleBanking()
            end

            if Core.isInWarsRetreat and Core.isBanking and Core.isRestoringPrayer and not Core.isPrepared and API.Read_LoopyLoop() then
                Core.prepareForBattle()
            end
            
            if Core.isPrepared and not Core.isPortalUsed and API.Read_LoopyLoop() then
               Core.goThroughPortal() 
            end
            
            if Core.isPortalUsed and not Core.isInArena and API.Read_LoopyLoop() then
                Core.goThroughGate() 
            end
            
            if Core.isInArena and API.Read_LoopyLoop() then
                Core.startEncounter()
                Core.checkKerapacExists()
            end
        elseif Core.isInBattle and API.Read_LoopyLoop() and not Core.isPlayerDead and not Core.isHardMode then
            Core.avoidLightningBolts()
            Core.managePlayer()
            Core.manageBuffs()
            Core.handleBossPhase()
            Core.handleStateChange(Core.getKerapacAnimation())
        elseif Core.isInBattle and API.Read_LoopyLoop() and not Core.isPlayerDead and Core.isHardMode then
            if Core.kerapacPhase >= 4 then
                Core.hardModePhase4Setup()
                if Core.isPhase4SetupComplete then 
                    Core.HandlePhase4()
                    Core.managePlayer()
                    Core.manageBuffs()
                    Core.handleBossPhase()
                end
            else
                Core.avoidLightningBolts()
                Core.managePlayer()
                Core.manageBuffs()
                Core.handleBossPhase()
                Core.handleStateChange(Core.getKerapacAnimation())
            end
        elseif Core.isPlayerDead then
            Core.reclaimItemsAtGrave() 
            Core.handleBossReset()
        elseif Core.isTimeToLoot and not Core.isLooted and API.Read_LoopyLoop() then
            Core.handleBossLoot()
        elseif Core.isLooted and API.Read_LoopyLoop() then
            Core.handleBossReset()
        end
    end
end

Core.log("Stopped Ernie's Kerapac Bosser " .. Data.version)