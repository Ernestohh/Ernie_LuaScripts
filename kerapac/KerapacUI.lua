local API = require("api")
local Data = require("kerapac/KerapacData")
local State = require("kerapac/KerapacState")
local Logger = require("kerapac/KerapacLogger")

local KerapacUI = {}

function KerapacUI:InitializeUI()
    Logger:Debug("Initializing UI elements")
    
    State.Background = API.CreateIG_answer()
    State.Background.box_name = "GuiBackground"
    State.Background.box_start = FFPOINT.new(Data.MARGIN, Data.BOX_START_Y, 0)
    State.Background.box_size = FFPOINT.new(Data.BOX_END_X, Data.BOX_END_Y, 0)
    State.Background.colour = ImColor.new(50, 48, 47)

    State.PassivesDropdown = API.CreateIG_answer()
    State.PassivesDropdown.box_name = "Passives"
    State.PassivesDropdown.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X, Data.BOX_START_Y + Data.PADDING_Y, 0)
    State.PassivesDropdown.stringsArr = {}

    State.StartButton = API.CreateIG_answer()
    State.StartButton.box_name = "Start"
    State.StartButton.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 120, Data.BOX_START_Y + Data.PADDING_Y + 40, 0)
    State.StartButton.box_size = FFPOINT.new(Data.BUTTON_WIDTH, Data.BUTTON_HEIGHT, 0)
    State.StartButton.colour = ImColor.new(160, 255, 0)

    State.adrenCheckbox = API.CreateIG_answer()
    State.adrenCheckbox.box_name = "Adrenaline Crystal Unlocked"
    State.adrenCheckbox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 120, Data.BOX_START_Y + Data.PADDING_Y + 60, 0)

    State.hardModeCheckBox = API.CreateIG_answer()
    State.hardModeCheckBox.box_name = "Hard Mode"
    State.hardModeCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 40, 0)

    State.partyCheckBox = API.CreateIG_answer()
    State.partyCheckBox.box_name = "Party"
    State.partyCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 60, 0)

    State.partyLeaderCheckBox = API.CreateIG_answer()
    State.partyLeaderCheckBox.box_name = "Am I party leader"
    State.partyLeaderCheckBox.box_start = FFPOINT.new(Data.MARGIN + Data.PADDING_X + 20, Data.BOX_START_Y + Data.PADDING_Y + 80, 0)

    for _, key in ipairs(State.sortedPassiveKeys) do
        table.insert(State.PassivesDropdown.stringsArr, Data.passiveBuffs[key].name)
    end
    
    Logger:Debug("UI elements initialized")
end

function KerapacUI:HandleStartButton()
    if not State.startScript then
        if State.StartButton.return_click then
            State.StartButton.return_click = false
            State:StartScript()
        end
    end
end

function KerapacUI:HandlePartyButton()
    State.isInParty = State.partyCheckBox.box_ticked
    State.isPartyLeader = State.partyLeaderCheckBox.box_ticked
    
    if State.isInParty then
        API.DrawCheckbox(State.partyLeaderCheckBox)
    else
        State.partyLeaderCheckBox.remove = true
    end
end

function KerapacUI:HandleButtons()
    self:HandleStartButton()
    self:HandlePartyButton()
end

function KerapacUI:DrawButtons()
    API.DrawSquareFilled(State.Background)
    API.DrawComboBox(State.PassivesDropdown, false)
    API.DrawBox(State.StartButton)
    API.DrawCheckbox(State.hardModeCheckBox)
    API.DrawCheckbox(State.partyCheckBox)
    API.DrawCheckbox(State.adrenCheckbox)
end

function KerapacUI:DrawGui()
    self:DrawButtons()
    self:HandleButtons()
end

function KerapacUI:HandleBankPin()
    if API.DoBankPin(Data.bankPin) then
        if Data.bankPin ~= nil then
            Logger:Error("No Bank Pin provided in KerapacData.lua")
        else
            return true
        end
    end
    return false
end

function KerapacUI:HandleSetupInstance()
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

function KerapacUI:HandleJoinPlayer(partyLeader)
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

function KerapacUI:HandleHardMode()
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

function KerapacUI:HandleStartFight() 
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)
    API.Sleep_tick(3)
end


return KerapacUI
