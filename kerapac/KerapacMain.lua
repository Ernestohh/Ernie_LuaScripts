-- Title: Kerapac Bosser
-- Author: Ernie
-- Description: Kills Kerapac
-- Version: 13.0
-- Category: PvM

local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Combat = require("kerapac/KerapacCombat")
local HardMode = require("kerapac/KerapacHardMode")
local Logger = require("kerapac/KerapacLogger")
local Utils = require("kerapac/KerapacUtils")
local Preparation = require("kerapac/KerapacPreparation")
local Loot = require("kerapac/KerapacLoot")
local Lightning = require("kerapac/KerapacLightning")
local GUI = require("kerapac/KerapacGUI")

Logger:Info("Started Ernie's Kerapac Bosser " .. Data.version)
API.SetMaxIdleTime(5)
API.Write_fake_mouse_do(false)
API.TurnOffMrHasselhoff(false)

GUI.loadConfig()
DrawImGui(function()
    if GUI.open then
        GUI.draw()
    end
end)
API.SetDrawLogs(false)
while (API.Read_LoopyLoop()) do
    if GUI.started then
        if not State.startScript then
            GUI.applyToState()
            Combat:InitAbilities()
            Utils:handleCombatMode()
            State.startScript = true
            Logger:Info("Configuration applied, starting script")
        end

        if not State.isInBattle and not State.isTimeToLoot then
            if not State.isInWarsRetreat then
                Preparation:CheckStartLocation()
            end

            if State.isInWarsRetreat and not State.isRestoringPrayer and not State.isPrepared and API.Read_LoopyLoop() then
                Preparation:HandlePrayerRestore()
            end

            if State.isInWarsRetreat and State.isRestoringPrayer and Data.prebuffEnabled and State.needsPrebuff and not State.hasPrebuffLoaded and API.Read_LoopyLoop() then
                Preparation:HandlePrebuffPreset()
            end

            if State.isInWarsRetreat and State.isRestoringPrayer and Data.prebuffEnabled and State.isPrebuffComplete and not State.hasLoadedMainPreset and not State.isPrepared and API.Read_LoopyLoop() then
                Preparation:HandleMainPreset()
                State.hasLoadedMainPreset = true
                State.isBanking = true
            end

            if State.isInWarsRetreat and not State.isBanking and not State.isPrepared and (not Data.prebuffEnabled or State.hasLoadedMainPreset) and API.Read_LoopyLoop() then
                Preparation:HandleBanking()
            end

            if State.isInWarsRetreat and State.isBanking and State.isRestoringPrayer and not State.isPrepared and API.Read_LoopyLoop() then
                Preparation:PrepareForBattle()
            end

            if State.isPrepared and not State.isMaxAdrenaline and API.Read_LoopyLoop() then
                Preparation:HandleAdrenalineCrystal()
            end

            if State.isPrepared and State.isMaxAdrenaline and not State.isPortalUsed and API.Read_LoopyLoop() then
                Preparation:GoThroughPortal()
            end

            if State.isPortalUsed and not State.isInArena and API.Read_LoopyLoop() then
                Preparation:GoThroughGate()
            end

            if State.isInArena and API.Read_LoopyLoop() then
                Preparation:StartEncounter()
                Preparation:CheckKerapacExists()
            end
        elseif State.isInBattle and API.Read_LoopyLoop() and not State.isPlayerDead and not State.isHardMode then
            Lightning:AvoidLightningBolts()
            Combat:ManagePlayer()
            Combat:ManageBuffs()
            Combat:HandleBossPhase()
            Combat:HandleCombatState(State:UpdateStateFromAnimation(Combat:GetKerapacAnimation()))
        elseif State.isInBattle and API.Read_LoopyLoop() and not State.isPlayerDead and State.isHardMode then
            if State.kerapacPhase >= 4 then
                Lightning:AvoidLightningBolts()
                HardMode:Phase4Setup()
                if State.isPhase4SetupComplete then
                    Lightning:AvoidLightningBolts()
                    HardMode:HandlePhase4()
                    Combat:ManagePlayer()
                    Combat:ManageBuffs()
                    Combat:HandleBossPhase()
                end
            else
                Lightning:AvoidLightningBolts()
                Combat:ManagePlayer()
                Combat:ManageBuffs()
                Combat:HandleBossPhase()
                Combat:HandleCombatState(State:UpdateStateFromAnimation(Combat:GetKerapacAnimation()))
            end
        elseif State.isPlayerDead then
            Preparation:ReclaimItemsAtGrave()
        elseif State.isTimeToLoot and not State.isLooted and API.Read_LoopyLoop() then
            Loot:HandleLoot()
        elseif State.isLooted and API.Read_LoopyLoop() then
            Preparation:HandleBossReset()
        end
    end
end

ClearRender()
Logger:Info("Stopped Ernie's Kerapac Bosser " .. Data.version)
