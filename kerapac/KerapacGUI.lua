local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")

local KerapacGUI = {}
KerapacGUI.open = true
KerapacGUI.started = false
KerapacGUI.startupMode = true
KerapacGUI.selectConfigTab = true
KerapacGUI.selectInfoTab = false
KerapacGUI.tabBarId = 0
KerapacGUI.hideInfoTabFrames = 0
KerapacGUI.dpmStats = nil

function KerapacGUI.reset()
    KerapacGUI.open = true
    KerapacGUI.started = false
    KerapacGUI.startupMode = true
    KerapacGUI.selectConfigTab = true
    KerapacGUI.selectInfoTab = false
    KerapacGUI.tabBarId = KerapacGUI.tabBarId + 1
    KerapacGUI.presetName = ""
    KerapacGUI.presetIndex = 0
    KerapacGUI.presetList = {}
    KerapacGUI.presetNames = {}
    KerapacGUI.dpmStats = nil
end

function KerapacGUI.setDPMStats(stats)
    KerapacGUI.dpmStats = stats
end

local passiveOptions = {"None", "Piety", "Rigour", "Augury", "Sanctity", "Turmoil", "Malevolence", "Anguish", "Desolation", "Torment", "Affliction", "Ruination", "Sorrow"}

local function findIndex(arr, value)
    for i, v in ipairs(arr) do
        if v == value then return i - 1 end
    end
    return 0
end

local SCRIPT_DIR = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\kerapac\\"
local configPath = SCRIPT_DIR .. "config.json"
local presetsIndexPath = SCRIPT_DIR .. "presets.json"

KerapacGUI.hasConfig = false
KerapacGUI.presetName = ""
KerapacGUI.presetIndex = 0
KerapacGUI.presetList = {}
KerapacGUI.presetNames = {}

KerapacGUI.config = {
    passiveIndex = 5,
    isHardMode = false,
    hasAdrenalineCrystal = false,
    isInParty = false,
    isPartyLeader = false,
    partyLeader = "",
    partyMembersText = "",
    hpThreshold = 70,
    prayerThreshold = 30,
    emergencyEatThreshold = 50,
    discordWebhookUrl = "",
    discordUserId = "",
    bankPin = "",
    prebuffEnabled = false,
    mainPreset = 1,
    prebuffPreset = 2,
    prebuffKwuarm = false,
    prebuffLantadyme = false,
    prebuffSpiritWeed = false,
    prebuffWarsBonfire = false,
    prebuffThermalFlask = false,
    prebuffDivineCharges = false,
}

local function buildConfigData(cfg)
    return {
        SelectedPassive = passiveOptions[cfg.passiveIndex + 1],
        IsHardMode = cfg.isHardMode,
        HasAdrenalineCrystal = cfg.hasAdrenalineCrystal,
        IsInParty = cfg.isInParty,
        IsPartyLeader = cfg.isPartyLeader,
        PartyLeader = cfg.partyLeader,
        PartyMembersText = cfg.partyMembersText,
        HpThreshold = cfg.hpThreshold,
        PrayerThreshold = cfg.prayerThreshold,
        EmergencyEatThreshold = cfg.emergencyEatThreshold,
        DiscordWebhookUrl = cfg.discordWebhookUrl,
        DiscordUserId = cfg.discordUserId,
        BankPin = cfg.bankPin,
        PrebuffEnabled = cfg.prebuffEnabled,
        MainPreset = cfg.mainPreset,
        PrebuffPreset = cfg.prebuffPreset,
        PrebuffKwuarm = cfg.prebuffKwuarm,
        PrebuffLantadyme = cfg.prebuffLantadyme,
        PrebuffSpiritWeed = cfg.prebuffSpiritWeed,
        PrebuffWarsBonfire = cfg.prebuffWarsBonfire,
        PrebuffThermalFlask = cfg.prebuffThermalFlask,
        PrebuffDivineCharges = cfg.prebuffDivineCharges,
    }
end

local applyConfigData

local function loadConfigFromFile()
    if not configPath then return nil end
    local file = io.open(configPath, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then return nil end
    local ok, data = pcall(API.JsonDecode, content)
    if not ok or not data then return nil end
    return data
end

local function saveConfigToFile(cfg)
    local data = buildConfigData(cfg)
    local ok, json = pcall(API.JsonEncode, data)
    if not ok or not json then
        Logger:Error("Failed to encode config JSON")
        return
    end
    local file = io.open(configPath, "w")
    if not file then
        Logger:Error("Failed to open config file for writing")
        return
    end
    file:write(json)
    file:close()
    Logger:Info("Config saved")
end

local function loadPresetIndex()
    local file = io.open(presetsIndexPath, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then return {} end
    local ok, data = pcall(API.JsonDecode, content)
    if not ok or type(data) ~= "table" then return {} end
    return data
end

local function savePresetIndex(presets)
    local ok, json = pcall(API.JsonEncode, presets)
    if not ok or not json then
        Logger:Error("Failed to encode preset index")
        return false
    end
    local file = io.open(presetsIndexPath, "w")
    if not file then
        Logger:Error("Failed to open preset index for writing")
        return false
    end
    file:write(json)
    file:close()
    return true
end

local function scanPresets()
    local presets = loadPresetIndex()
    local names = {"-- Select Preset --"}
    local validPresets = {}
    for _, name in ipairs(presets) do
        local path = SCRIPT_DIR .. "preset_" .. name .. ".json"
        local file = io.open(path, "r")
        if file then
            file:close()
            validPresets[#validPresets + 1] = name
            names[#names + 1] = name
        end
    end
    if #validPresets ~= #presets then
        savePresetIndex(validPresets)
    end
    return validPresets, names
end

local function loadPreset(name)
    local path = SCRIPT_DIR .. "preset_" .. name .. ".json"
    local file = io.open(path, "r")
    if not file then return false end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then return false end
    local ok, data = pcall(API.JsonDecode, content)
    if not ok or not data then return false end
    applyConfigData(data, KerapacGUI.config)
    Logger:Info("Loaded preset: " .. name)
    return true
end

local function savePreset(name, cfg)
    if not name or name == "" then
        Logger:Error("Preset name is empty")
        return false
    end
    local path = SCRIPT_DIR .. "preset_" .. name .. ".json"
    local data = buildConfigData(cfg)
    local ok, json = pcall(API.JsonEncode, data)
    if not ok or not json then
        Logger:Error("Failed to encode preset JSON")
        return false
    end
    local file = io.open(path, "w")
    if not file then
        Logger:Error("Failed to save preset file")
        return false
    end
    file:write(json)
    file:close()
    local presets = loadPresetIndex()
    local found = false
    for _, n in ipairs(presets) do
        if n == name then found = true break end
    end
    if not found then
        presets[#presets + 1] = name
        savePresetIndex(presets)
    end
    Logger:Info("Saved preset: " .. name)
    return true
end

function KerapacGUI.refreshPresets()
    KerapacGUI.presetList, KerapacGUI.presetNames = scanPresets()
    KerapacGUI.presetIndex = 0
end

applyConfigData = function(saved, c)
    if saved.SelectedPassive then
        c.passiveIndex = findIndex(passiveOptions, saved.SelectedPassive)
    end
    if type(saved.IsHardMode) == "boolean" then c.isHardMode = saved.IsHardMode end
    if type(saved.HasAdrenalineCrystal) == "boolean" then c.hasAdrenalineCrystal = saved.HasAdrenalineCrystal end
    if type(saved.IsInParty) == "boolean" then c.isInParty = saved.IsInParty end
    if type(saved.IsPartyLeader) == "boolean" then c.isPartyLeader = saved.IsPartyLeader end
    if type(saved.PartyLeader) == "string" then c.partyLeader = saved.PartyLeader end
    if type(saved.PartyMembersText) == "string" then c.partyMembersText = saved.PartyMembersText end
    if type(saved.HpThreshold) == "number" then c.hpThreshold = math.max(1, math.min(99, saved.HpThreshold)) end
    if type(saved.PrayerThreshold) == "number" then c.prayerThreshold = math.max(1, math.min(99, saved.PrayerThreshold)) end
    if type(saved.EmergencyEatThreshold) == "number" then c.emergencyEatThreshold = math.max(1, math.min(99, saved.EmergencyEatThreshold)) end
    if type(saved.DiscordWebhookUrl) == "string" then c.discordWebhookUrl = saved.DiscordWebhookUrl end
    if type(saved.DiscordUserId) == "string" then c.discordUserId = saved.DiscordUserId end
    if type(saved.BankPin) == "string" then c.bankPin = saved.BankPin end
    if type(saved.PrebuffEnabled) == "boolean" then c.prebuffEnabled = saved.PrebuffEnabled end
    if type(saved.MainPreset) == "number" then c.mainPreset = math.max(1, math.min(18, saved.MainPreset)) end
    if type(saved.PrebuffPreset) == "number" then c.prebuffPreset = math.max(1, math.min(18, saved.PrebuffPreset)) end
    if type(saved.PrebuffKwuarm) == "boolean" then c.prebuffKwuarm = saved.PrebuffKwuarm end
    if type(saved.PrebuffLantadyme) == "boolean" then c.prebuffLantadyme = saved.PrebuffLantadyme end
    if type(saved.PrebuffSpiritWeed) == "boolean" then c.prebuffSpiritWeed = saved.PrebuffSpiritWeed end
    if type(saved.PrebuffWarsBonfire) == "boolean" then c.prebuffWarsBonfire = saved.PrebuffWarsBonfire end
    if type(saved.PrebuffThermalFlask) == "boolean" then c.prebuffThermalFlask = saved.PrebuffThermalFlask end
    if type(saved.PrebuffDivineCharges) == "boolean" then c.prebuffDivineCharges = saved.PrebuffDivineCharges end
end

function KerapacGUI.loadConfig()
    KerapacGUI.refreshPresets()
    local saved = loadConfigFromFile()
    if not saved then
        KerapacGUI.hasConfig = false
        return
    end
    KerapacGUI.hasConfig = true
    applyConfigData(saved, KerapacGUI.config)
end

function KerapacGUI.getConfig()
    local c = KerapacGUI.config
    return {
        selectedPassive = passiveOptions[c.passiveIndex + 1],
        isHardMode = c.isHardMode,
        hasAdrenalineCrystal = c.hasAdrenalineCrystal,
        isInParty = c.isInParty,
        isPartyLeader = c.isPartyLeader,
        partyLeader = c.partyLeader,
        partyMembersText = c.partyMembersText,
        hpThreshold = c.hpThreshold,
        prayerThreshold = c.prayerThreshold,
        emergencyEatThreshold = c.emergencyEatThreshold,
        discordWebhookUrl = c.discordWebhookUrl,
        discordUserId = c.discordUserId,
        bankPin = c.bankPin,
        prebuffEnabled = c.prebuffEnabled,
        mainPreset = c.mainPreset,
        prebuffPreset = c.prebuffPreset,
        prebuffKwuarm = c.prebuffKwuarm,
        prebuffLantadyme = c.prebuffLantadyme,
        prebuffSpiritWeed = c.prebuffSpiritWeed,
        prebuffWarsBonfire = c.prebuffWarsBonfire,
        prebuffThermalFlask = c.prebuffThermalFlask,
        prebuffDivineCharges = c.prebuffDivineCharges,
    }
end

local function row(label, value, lr, lg, lb, vr, vg, vb)
    ImGui.TableNextRow()
    ImGui.TableNextColumn()
    ImGui.PushStyleColor(ImGuiCol.Text, lr or 0.5, lg or 0.5, lb or 0.55, 1.0)
    ImGui.TextWrapped(label)
    ImGui.PopStyleColor(1)
    ImGui.TableNextColumn()
    if vr then
        ImGui.PushStyleColor(ImGuiCol.Text, vr, vg, vb, 1.0)
        ImGui.TextWrapped(value)
        ImGui.PopStyleColor(1)
    else
        ImGui.TextWrapped(value)
    end
end

local function progressBar(progress, height, text, r, g, b)
    ImGui.PushStyleColor(ImGuiCol.PlotHistogram, r * 0.4, g * 0.4, b * 0.4, 0.9)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, r * 0.1, g * 0.1, b * 0.1, 0.8)
    ImGui.ProgressBar(progress, -1, height, text)
    ImGui.PopStyleColor(2)
end

local function drawConfigSummary(cfg)
    if ImGui.BeginTable("##cfgsummary", 2) then
        ImGui.TableSetupColumn("lbl", ImGuiTableColumnFlags.WidthStretch, 0.4)
        ImGui.TableSetupColumn("val", ImGuiTableColumnFlags.WidthStretch, 0.6)
        row("Passive", passiveOptions[cfg.passiveIndex + 1])
        row("Hard Mode", cfg.isHardMode and "Yes" or "No", 0.5, 0.5, 0.55, cfg.isHardMode and 1.0 or 0.5, cfg.isHardMode and 0.4 or 0.8, cfg.isHardMode and 0.4 or 0.5)
        if cfg.isInParty then
            row("Party", cfg.isPartyLeader and "Leader" or "Member")
        end
        ImGui.EndTable()
    end
end

local function drawConfigTab(cfg, gui)
    if gui.started then
        local runText = "Script is running."
        local tw = ImGui.CalcTextSize(runText)
        local rw = ImGui.GetContentRegionAvail()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (rw - tw) * 0.5)
        ImGui.PushStyleColor(ImGuiCol.Text, 0.4, 0.8, 0.4, 1.0)
        ImGui.TextWrapped(runText)
        ImGui.PopStyleColor(1)
        ImGui.Spacing()
        drawConfigSummary(cfg)
        return
    end

    ImGui.PushItemWidth(-1)

    if #KerapacGUI.presetNames > 1 then
        ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.8, 0.9, 1.0)
        ImGui.TextWrapped("Load Preset")
        ImGui.PopStyleColor(1)
        local presetChanged, newPresetIdx = ImGui.Combo("##preset", KerapacGUI.presetIndex, KerapacGUI.presetNames, 10)
        if presetChanged and newPresetIdx > 0 then
            KerapacGUI.presetIndex = newPresetIdx
            local presetName = KerapacGUI.presetList[newPresetIdx]
            if presetName then
                loadPreset(presetName)
            end
        elseif presetChanged then
            KerapacGUI.presetIndex = 0
        end
        ImGui.Spacing()
    end

    ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.8, 0.9, 1.0)
    ImGui.TextWrapped("Save as Preset")
    ImGui.PopStyleColor(1)
    local nameChanged, newName = ImGui.InputText("##presetname", KerapacGUI.presetName, 0)
    if nameChanged then KerapacGUI.presetName = newName end
    ImGui.PushStyleColor(ImGuiCol.Button, 0.2, 0.5, 0.6, 0.9)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.25, 0.6, 0.7, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.2, 0.7, 0.8, 1.0)
    if ImGui.Button("Save Preset##save", -1, 22) then
        if KerapacGUI.presetName ~= "" then
            if savePreset(KerapacGUI.presetName, cfg) then
                KerapacGUI.refreshPresets()
                KerapacGUI.presetName = ""
            end
        end
    end
    ImGui.PopStyleColor(3)

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
    ImGui.TextWrapped("General Settings")
    ImGui.PopStyleColor(1)

    ImGui.TextWrapped("Passive Prayer/Curse")
    local passiveChanged, newPassiveIdx = ImGui.Combo("##passive", cfg.passiveIndex, passiveOptions, 10)
    if passiveChanged then cfg.passiveIndex = newPassiveIdx end

    ImGui.Spacing()
    local hmChanged, hmVal = ImGui.Checkbox("Hard Mode##hardmode", cfg.isHardMode)
    if hmChanged then cfg.isHardMode = hmVal end

    local acChanged, acVal = ImGui.Checkbox("Adrenaline Crystal Unlocked##adrencrystal", cfg.hasAdrenalineCrystal)
    if acChanged then cfg.hasAdrenalineCrystal = acVal end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
    ImGui.TextWrapped("Party Settings")
    ImGui.PopStyleColor(1)

    local partyChanged, partyVal = ImGui.Checkbox("In Party##inparty", cfg.isInParty)
    if partyChanged then cfg.isInParty = partyVal end

    if cfg.isInParty then
        local leaderChanged, leaderVal = ImGui.Checkbox("Am I Party Leader##partyleader", cfg.isPartyLeader)
        if leaderChanged then cfg.isPartyLeader = leaderVal end

        if not cfg.isPartyLeader then
            ImGui.TextWrapped("Party Leader Name")
            local plChanged, plVal = ImGui.InputText("##partyleadername", cfg.partyLeader, 0)
            if plChanged then cfg.partyLeader = plVal end
        end

        ImGui.TextWrapped("Party Members (comma separated)")
        local pmChanged, pmVal = ImGui.InputText("##partymembers", cfg.partyMembersText, 0)
        if pmChanged then cfg.partyMembersText = pmVal end
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
    ImGui.TextWrapped("Combat Settings")
    ImGui.PopStyleColor(1)

    ImGui.TextWrapped("HP Threshold %")
    local hpChanged, hpVal = ImGui.SliderInt("##hpthreshold", cfg.hpThreshold, 1, 99, "%d%%")
    if hpChanged then cfg.hpThreshold = hpVal end

    ImGui.TextWrapped("Prayer Threshold %")
    local prayChanged, prayVal = ImGui.SliderInt("##praythreshold", cfg.prayerThreshold, 1, 99, "%d%%")
    if prayChanged then cfg.prayerThreshold = prayVal end

    ImGui.TextWrapped("Emergency Eat Threshold %")
    local emergChanged, emergVal = ImGui.SliderInt("##emergthreshold", cfg.emergencyEatThreshold, 1, 99, "%d%%")
    if emergChanged then cfg.emergencyEatThreshold = emergVal end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
    ImGui.TextWrapped("Prebuff Settings")
    ImGui.PopStyleColor(1)

    local prebuffChanged, prebuffVal = ImGui.Checkbox("Enable Prebuffing##prebuffenabled", cfg.prebuffEnabled)
    if prebuffChanged then cfg.prebuffEnabled = prebuffVal end

    if cfg.prebuffEnabled then
        ImGui.Spacing()

        ImGui.TextWrapped("Main Preset (1-18)")
        local mainChanged, mainVal = ImGui.InputInt("##mainpreset", cfg.mainPreset, 1, 1)
        if mainChanged then
            cfg.mainPreset = mainVal
        end

        ImGui.TextWrapped("Prebuff Preset (1-18)")
        local prebuffPresetChanged, prebuffPresetVal = ImGui.InputInt("##prebuffpreset", cfg.prebuffPreset, 1, 1)
        if prebuffPresetChanged then
            cfg.prebuffPreset = prebuffPresetVal
        end

        ImGui.Spacing()
        ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.8, 0.9, 1.0)
        ImGui.TextWrapped("Prebuff Options:")
        ImGui.PopStyleColor(1)

        local kwuarmChanged, kwuarmVal = ImGui.Checkbox("Kwuarm Incense Stick##prebuffkwuarm", cfg.prebuffKwuarm)
        if kwuarmChanged then cfg.prebuffKwuarm = kwuarmVal end

        local lantadymeChanged, lantadymeVal = ImGui.Checkbox("Lantadyme Incense Stick##prebufflantadyme", cfg.prebuffLantadyme)
        if lantadymeChanged then cfg.prebuffLantadyme = lantadymeVal end

        local spiritWeedChanged, spiritWeedVal = ImGui.Checkbox("Spirit Weed Incense Stick##prebuffspiritweed", cfg.prebuffSpiritWeed)
        if spiritWeedChanged then cfg.prebuffSpiritWeed = spiritWeedVal end

        local bonfireChanged, bonfireVal = ImGui.Checkbox("War's Bonfire##prebuffbonfire", cfg.prebuffWarsBonfire)
        if bonfireChanged then cfg.prebuffWarsBonfire = bonfireVal end

        local thermalChanged, thermalVal = ImGui.Checkbox("Thermal Flask##prebuffthermal", cfg.prebuffThermalFlask)
        if thermalChanged then cfg.prebuffThermalFlask = thermalVal end

        local divineChanged, divineVal = ImGui.Checkbox("Divine Charges##prebuffdivine", cfg.prebuffDivineCharges)
        if divineChanged then cfg.prebuffDivineCharges = divineVal end
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
    ImGui.TextWrapped("Advanced Settings")
    ImGui.PopStyleColor(1)

    ImGui.TextWrapped("Discord Webhook URL")
    local webhookChanged, webhookVal = ImGui.InputText("##discordwebhook", cfg.discordWebhookUrl, 0)
    if webhookChanged then cfg.discordWebhookUrl = webhookVal end

    ImGui.TextWrapped("Discord User ID")
    local useridChanged, useridVal = ImGui.InputText("##discorduserid", cfg.discordUserId, 0)
    if useridChanged then cfg.discordUserId = useridVal end

    ImGui.TextWrapped("Bank PIN")
    local pinChanged, pinVal = ImGui.InputText("##bankpin", cfg.bankPin, 0)
    if pinChanged then cfg.bankPin = pinVal end

    ImGui.PopItemWidth()

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    local canStart = true
    local errorMsg = nil

    if cfg.prebuffEnabled == true then
        local main = tonumber(cfg.mainPreset) or 0
        local prebuff = tonumber(cfg.prebuffPreset) or 0

        if main < 1 or main > 18 then
            canStart = false
            errorMsg = "Main preset must be 1-18"
        elseif prebuff < 1 or prebuff > 18 then
            canStart = false
            errorMsg = "Prebuff preset must be 1-18"
        elseif main == prebuff then
            canStart = false
            errorMsg = "Main and Prebuff presets cannot be the same"
        end
    end

    if errorMsg ~= nil then
        ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.4, 0.4, 1.0)
        ImGui.TextWrapped(errorMsg)
        ImGui.PopStyleColor(1)
        ImGui.Spacing()
    end

    if canStart == true then
        ImGui.PushStyleColor(ImGuiCol.Button, 0.15, 0.55, 0.15, 0.9)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.2, 0.7, 0.2, 1.0)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.1, 0.85, 0.1, 1.0)
    else
        ImGui.PushStyleColor(ImGuiCol.Button, 0.3, 0.3, 0.3, 0.9)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.3, 0.3, 0.3, 0.9)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.3, 0.3, 0.3, 0.9)
    end
    if ImGui.Button("Start Script##start", -1, 30) then
        if canStart == true then
            saveConfigToFile(gui.config)
            gui.started = true
            gui.selectInfoTab = true
            gui.tabBarId = gui.tabBarId + 1
        end
    end
    ImGui.PopStyleColor(3)
end

local function formatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return string.format("%d", n)
end

local function drawInfoTab()
    local stateText = "Idle"
    if State.isInBattle then
        stateText = "In Battle - Phase " .. State.kerapacPhase
    elseif State.isTimeToLoot then
        stateText = "Looting"
    elseif State.isInArena then
        stateText = "In Arena"
    elseif State.isPrepared then
        stateText = "Prepared"
    elseif State.isInWarsRetreat then
        stateText = "At War's Retreat"
    end

    local textWidth = ImGui.CalcTextSize(stateText)
    local regionWidth = ImGui.GetContentRegionAvail()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (regionWidth - textWidth) * 0.5)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.3, 1.0, 0.4, 1.0)
    ImGui.TextWrapped(stateText)
    ImGui.PopStyleColor(1)

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    local hpPct = API.GetHPrecent() / 100
    local hr, hg, hb = 1.0, 0.3, 0.3
    if hpPct > 0.6 then hr, hg, hb = 0.3, 0.85, 0.45
    elseif hpPct > 0.3 then hr, hg, hb = 1.0, 0.75, 0.2 end
    progressBar(hpPct, 20, string.format("HP: %d%%", API.GetHPrecent()), hr, hg, hb)

    ImGui.Spacing()

    local prayPct = API.GetPrayPrecent() / 100
    local pr, pg, pb = 0.3, 0.6, 0.9
    progressBar(prayPct, 20, string.format("Prayer: %d%%", API.GetPrayPrecent()), pr, pg, pb)

    ImGui.Spacing()

    local adrenPct = API.GetAddreline_() / 100
    local ar, ag, ab = 0.9, 0.7, 0.2
    progressBar(adrenPct, 20, string.format("Adrenaline: %d%%", API.GetAddreline_()), ar, ag, ab)

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    if ImGui.BeginTable("##stats", 2) then
        ImGui.TableSetupColumn("lbl", ImGuiTableColumnFlags.WidthStretch, 0.4)
        ImGui.TableSetupColumn("val", ImGuiTableColumnFlags.WidthStretch, 0.6)
        row("Total Kills", tostring(Data.totalKills))
        row("Total Deaths", tostring(Data.totalDeaths))
        row("Total Rares", tostring(Data.totalRares))
        row("Phase", tostring(State.kerapacPhase))
        if State.isHardMode then
            row("Mode", "Hard Mode", 0.5, 0.5, 0.55, 1.0, 0.4, 0.4)
        else
            row("Mode", "Normal Mode", 0.5, 0.5, 0.55, 0.4, 0.8, 0.4)
        end
        ImGui.EndTable()
    end

    if KerapacGUI.dpmStats then
        ImGui.Spacing()
        ImGui.Separator()
        ImGui.Spacing()
        ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.7, 0.3, 1.0)
        ImGui.TextWrapped("DPM Stats")
        ImGui.PopStyleColor(1)
        if ImGui.BeginTable("##dpmstats", 2) then
            ImGui.TableSetupColumn("lbl", ImGuiTableColumnFlags.WidthStretch, 0.4)
            ImGui.TableSetupColumn("val", ImGuiTableColumnFlags.WidthStretch, 0.6)
            row("Current DPM", KerapacGUI.dpmStats.dpmFormatted or "0")
            row("Peak DPM", KerapacGUI.dpmStats.peakDPMFormatted or "0")
            row("Average DPM", KerapacGUI.dpmStats.averageDPMFormatted or "0")
            row("Total Damage", KerapacGUI.dpmStats.totalDamageFormatted or "0")
            row("Duration", KerapacGUI.dpmStats.durationFormatted or "0:00")
            ImGui.EndTable()
        end
    end
end

local function drawStartupScreen(gui)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.9, 0.95, 1.0)
    local title = "Kerapac Bosser"
    local tw = ImGui.CalcTextSize(title)
    local rw = ImGui.GetContentRegionAvail()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (rw - tw) * 0.5)
    ImGui.TextWrapped(title)
    ImGui.PopStyleColor(1)

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    if #KerapacGUI.presetList > 0 then
        ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.8, 0.9, 1.0)
        ImGui.TextWrapped("Saved Presets:")
        ImGui.PopStyleColor(1)
        ImGui.Spacing()

        ImGui.PushStyleColor(ImGuiCol.Button, 0.15, 0.4, 0.5, 0.9)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.2, 0.5, 0.6, 1.0)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.15, 0.6, 0.7, 1.0)
        for _, presetName in ipairs(KerapacGUI.presetList) do
            if ImGui.Button(presetName .. "##preset_" .. presetName, -1, 28) then
                if loadPreset(presetName) then
                    local presetValid = true
                    if gui.config.prebuffEnabled == true then
                        local main = tonumber(gui.config.mainPreset) or 0
                        local prebuff = tonumber(gui.config.prebuffPreset) or 0
                        if main < 1 or main > 18 or prebuff < 1 or prebuff > 18 or main == prebuff then
                            presetValid = false
                        end
                    end
                    if presetValid == true then
                        gui.startupMode = false
                        gui.started = true
                        gui.selectInfoTab = true
                    else
                        gui.startupMode = false
                        gui.selectConfigTab = true
                        gui.tabBarId = gui.tabBarId + 1
                    end
                end
            end
        end
        ImGui.PopStyleColor(3)

        ImGui.Spacing()
        ImGui.Separator()
        ImGui.Spacing()
    else
        ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.5, 0.55, 1.0)
        ImGui.TextWrapped("No saved presets found.")
        ImGui.PopStyleColor(1)
        ImGui.Spacing()
    end

    ImGui.PushStyleColor(ImGuiCol.Button, 0.15, 0.55, 0.15, 0.9)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.2, 0.7, 0.2, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.1, 0.85, 0.1, 1.0)
    if ImGui.Button("New Configuration##newconfig", -1, 32) then
        gui.startupMode = false
        gui.selectConfigTab = true
        gui.selectInfoTab = false
        gui.hideInfoTabFrames = 3
        gui.tabBarId = gui.tabBarId + 1
    end
    ImGui.PopStyleColor(3)
end

local function drawContent(gui)
    if gui.startupMode and not gui.started then
        drawStartupScreen(gui)
        return
    end

    if not gui.started then
        ImGui.Spacing()
        drawConfigTab(gui.config, gui)
        return
    end

    if ImGui.BeginTabBar("##maintabs_" .. gui.tabBarId, 0) then
        local infoFlags = gui.selectInfoTab and ImGuiTabItemFlags.SetSelected or 0
        local infoSelected = ImGui.BeginTabItem("Info###info_" .. gui.tabBarId, nil, infoFlags)
        if infoSelected then
            gui.selectInfoTab = false
            ImGui.Spacing()
            if gui.started then
                drawInfoTab()
            else
                ImGui.PushStyleColor(ImGuiCol.Text, 0.5, 0.5, 0.55, 1.0)
                ImGui.TextWrapped("Configure settings and press Start Script.")
                ImGui.PopStyleColor(1)
            end
            ImGui.EndTabItem()
        end

        if gui.started then
            if ImGui.BeginTabItem("Config###configrunning_" .. gui.tabBarId) then
                ImGui.Spacing()
                drawConfigTab(gui.config, gui)
                ImGui.EndTabItem()
            end
        end

        ImGui.EndTabBar()
    end
end

function KerapacGUI.draw()
    ImGui.SetNextWindowSize(340, 0, ImGuiCond.Always)
    ImGui.SetNextWindowPos(100, 100, ImGuiCond.FirstUseEver)

    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.07, 0.07, 0.09, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.10, 0.10, 0.13, 1.0)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.13, 0.13, 0.18, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Separator, 0.2, 0.2, 0.25, 0.5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 14, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 6, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 3)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)

    local title = "Kerapac - " .. API.ScriptRuntimeString() .. "###Kerapac"
    local visible = ImGui.Begin(title, 0)

    if visible then
        local ok, err = pcall(drawContent, KerapacGUI)
        if not ok then
            ImGui.TextColored(1.0, 0.3, 0.3, 1.0, "Error: " .. tostring(err))
        end
    end

    ImGui.PopStyleVar(4)
    ImGui.PopStyleColor(4)
    ImGui.End()

    return KerapacGUI.open
end

function KerapacGUI.applyToState()
    local cfg = KerapacGUI.getConfig()

    State.selectedPassive = cfg.selectedPassive
    State.isHardMode = cfg.isHardMode
    State.isInParty = cfg.isInParty
    State.isPartyLeader = cfg.isPartyLeader

    if cfg.hasAdrenalineCrystal then
        State.isMaxAdrenaline = false
    else
        State.isMaxAdrenaline = true
    end

    Data.hpThreshold = cfg.hpThreshold
    Data.prayerThreshold = cfg.prayerThreshold
    Data.emergencyEatThreshold = cfg.emergencyEatThreshold

    if cfg.discordWebhookUrl and cfg.discordWebhookUrl ~= "" then
        Data.discordWebhookUrl = cfg.discordWebhookUrl
    end
    if cfg.discordUserId and cfg.discordUserId ~= "" then
        Data.discordUserId = cfg.discordUserId
    end
    if cfg.bankPin and cfg.bankPin ~= "" then
        Data.bankPin = tonumber(cfg.bankPin) or nil
    end

    if cfg.isInParty then
        if cfg.partyLeader and cfg.partyLeader ~= "" then
            Data.partyLeader = cfg.partyLeader
        elseif cfg.isPartyLeader then
            Data.partyLeader = API.GetLocalPlayerName()
        end

        if cfg.partyMembersText and cfg.partyMembersText ~= "" then
            Data.partyMembers = {}
            for member in string.gmatch(cfg.partyMembersText, "([^,]+)") do
                local trimmed = member:match("^%s*(.-)%s*$")
                if trimmed ~= "" then
                    table.insert(Data.partyMembers, trimmed)
                end
            end
        end
    else
        Data.partyLeader = nil
        Data.partyMembers = {}
    end

    Data.prebuffEnabled = cfg.prebuffEnabled
    Data.mainPreset = cfg.mainPreset
    Data.prebuffPreset = cfg.prebuffPreset
    Data.prebuffKwuarm = cfg.prebuffKwuarm
    Data.prebuffLantadyme = cfg.prebuffLantadyme
    Data.prebuffSpiritWeed = cfg.prebuffSpiritWeed
    Data.prebuffWarsBonfire = cfg.prebuffWarsBonfire
    Data.prebuffThermalFlask = cfg.prebuffThermalFlask
    Data.prebuffDivineCharges = cfg.prebuffDivineCharges

    if cfg.prebuffEnabled then
        State.needsPrebuff = true
    end

    Logger:Info("Configuration applied")
end

return KerapacGUI
