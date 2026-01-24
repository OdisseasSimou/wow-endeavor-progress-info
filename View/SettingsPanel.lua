-- UI.lua
-- Settings panel for EndeavorTracker

EndeavorTrackerUI = {}

-- Keep a reference to the real print and silence all other prints in this module
local _print = _G.print
local print = function(...) end

-- Store the settings category for opening
EndeavorTrackerUI.settingsCategory = nil

-- Text format presets
local textFormats = {
    {name = "Detailed (Default)", format = "detailed", 
     example = "Milestone 2: 125 / 250 (125 XP needed)"},
    {name = "Simple", format = "simple", 
     example = "125 XP to reach Milestone 2 (completed: M1)"},
    {name = "Progress Bar Style", format = "progress", 
     example = "M2 Progress: 125/250 (50%) - 125 XP to go"},
    {name = "Short", format = "short", 
     example = "To Milestone 2: 125 XP remaining"},
    {name = "Minimal", format = "minimal", 
     example = "125 XP to next milestone"},
    {name = "Percentage Focus", format = "percentage", 
     example = "50% to M2 - 125 XP needed"},
    {name = "Next & Final", format = "nextfinal", 
     example = "Next: 125 XP | Final: 875 XP"},
}

-- Color presets
local colorPresets = {
    {name = "Gold (Default)", r = 1, g = 0.82, b = 0},
    {name = "Bright Gold", r = 1, g = 0.96, b = 0.41},
    {name = "White", r = 1, g = 1, b = 1},
    {name = "Light Blue", r = 0.5, g = 0.8, b = 1},
    {name = "Cyan", r = 0, g = 1, b = 0.9},
    {name = "Green", r = 0.1, g = 1, b = 0.1},
    {name = "Light Green", r = 0.67, g = 1, b = 0.5},
    {name = "Orange", r = 1, g = 0.5, b = 0},
    {name = "Red", r = 1, g = 0.1, b = 0.1},
    {name = "Pink", r = 1, g = 0.4, b = 0.7},
    {name = "Purple", r = 0.8, g = 0.4, b = 1},
    {name = "Yellow", r = 1, g = 1, b = 0},
}

-- Default settings
local defaults = {
    color = {r = 1, g = 0.82, b = 0}, -- Default golden color
    textFormat = "detailed" -- Default text format
}

function EndeavorTrackerUI:InitializeSettings()
    -- Initialize saved variables
    if not EndeavorTrackerDB then
        EndeavorTrackerDB = {}
    end
    if not EndeavorTrackerDB.color then
        EndeavorTrackerDB.color = {r = defaults.color.r, g = defaults.color.g, b = defaults.color.b}
    end
    if not EndeavorTrackerDB.textFormat then
        EndeavorTrackerDB.textFormat = defaults.textFormat
    end
end

function EndeavorTrackerUI:GetColor()
    if EndeavorTrackerDB and EndeavorTrackerDB.color then
        return EndeavorTrackerDB.color.r, EndeavorTrackerDB.color.g, EndeavorTrackerDB.color.b
    end
    return defaults.color.r, defaults.color.g, defaults.color.b
end

function EndeavorTrackerUI:SetColor(r, g, b)
    if not EndeavorTrackerDB then
        EndeavorTrackerDB = {}
    end
    EndeavorTrackerDB.color = {r = r, g = g, b = b}
    
    -- Update the display with current color
    if EndeavorTrackerDisplay and EndeavorTrackerDisplay.UpdateXPDisplay then
        EndeavorTrackerDisplay:UpdateXPDisplay()
    end
end

function EndeavorTrackerUI:GetTextFormat()
    if EndeavorTrackerDB and EndeavorTrackerDB.textFormat then
        return EndeavorTrackerDB.textFormat
    end
    return defaults.textFormat
end

function EndeavorTrackerUI:SetTextFormat(format)
    if not EndeavorTrackerDB then
        EndeavorTrackerDB = {}
    end
    EndeavorTrackerDB.textFormat = format
    
    -- Update the display with new format
    if EndeavorTrackerDisplay and EndeavorTrackerDisplay.UpdateXPDisplay then
        EndeavorTrackerDisplay:UpdateXPDisplay()
    end
end

function EndeavorTrackerUI:CreateSettingsPanel()
    -- Create the settings panel
    local panel = CreateFrame("Frame", "EndeavorTrackerSettingsPanel", UIParent, "BackdropTemplate")
    panel.name = "Endeavor Tracker"
    
    -- Set backdrop for the panel (like DecorVendor does)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    panel:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
    panel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Endeavor Tracker Settings")
    title:SetTextColor(1, 0.82, 0)
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Customize the appearance of the XP tooltip.")
    
    -- === TEXT FORMAT SECTION ===
    local formatLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    formatLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    formatLabel:SetText("Text Format:")
    formatLabel:SetTextColor(1, 0.82, 0)
    
    -- Create text format preset buttons
    local currentFormat = self:GetTextFormat()
    local formatButtons = {}
    
    for i, preset in ipairs(textFormats) do
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(140, 24)
        btn:SetText(preset.name)
        
        -- Position buttons vertically
        if i == 1 then
            btn:SetPoint("TOPLEFT", formatLabel, "BOTTOMLEFT", 0, -10)
        else
            btn:SetPoint("TOPLEFT", formatButtons[i - 1], "BOTTOMLEFT", 0, -4)
        end
        
        -- Highlight the current format
        if preset.format == currentFormat then
            btn:LockHighlight()
        end
        
        -- Show example on hover
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Example:", 1, 1, 1)
            GameTooltip:AddLine(preset.example, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Apply format on click
        btn:SetScript("OnClick", function(self)
            -- Unlock all buttons
            for _, b in ipairs(formatButtons) do
                b:UnlockHighlight()
            end
            -- Lock this button
            self:LockHighlight()
            -- Apply the format
            EndeavorTrackerUI:SetTextFormat(preset.format)
            print("Endeavor Tracker: Text format changed to " .. preset.name)
        end)
        
        table.insert(formatButtons, btn)
    end
    
    -- === COLOR SECTION ===
    local colorSectionLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    colorSectionLabel:SetPoint("TOPLEFT", formatButtons[#formatButtons], "BOTTOMLEFT", 0, -30)
    colorSectionLabel:SetText("Text Color:")
    colorSectionLabel:SetTextColor(1, 0.82, 0)
    
    -- Color picker label
    local colorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", colorSectionLabel, "BOTTOMLEFT", 0, -10)
    colorLabel:SetText("Custom Color:")
    
    -- Color preview box
    local colorBox = CreateFrame("Button", nil, panel, "BackdropTemplate")
    colorBox:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    colorBox:SetSize(40, 20)
    
    -- Color box texture
    local colorTexture = colorBox:CreateTexture(nil, "BACKGROUND")
    colorTexture:SetAllPoints()
    colorTexture:SetColorTexture(self:GetColor())
    
    -- Color box border
    colorBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    colorBox:SetBackdropColor(0, 0, 0, 0)
    colorBox:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Color picker functionality (use ColorPickerFrame API)
    colorBox:SetScript("OnClick", function()
        local r, g, b = self:GetColor()
        
        -- Store the previous values for cancel
        local info = {
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                colorTexture:SetColorTexture(newR, newG, newB)
                self:SetColor(newR, newG, newB)
            end,
            cancelFunc = function(previousValues)
                if previousValues then
                    colorTexture:SetColorTexture(previousValues.r, previousValues.g, previousValues.b)
                    self:SetColor(previousValues.r, previousValues.g, previousValues.b)
                end
            end,
            hasOpacity = false,
            r = r,
            g = g,
            b = b,
        }
        
        -- Use the appropriate API depending on version
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            -- Fallback for older versions
            ColorPickerFrame.func = info.swatchFunc
            ColorPickerFrame.cancelFunc = info.cancelFunc
            ColorPickerFrame.hasOpacity = info.hasOpacity
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame.previousValues = {r = r, g = g, b = b}
            ColorPickerFrame:Show()
        end
    end)
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -20)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        self:SetColor(defaults.color.r, defaults.color.g, defaults.color.b)
        colorTexture:SetColorTexture(defaults.color.r, defaults.color.g, defaults.color.b)
        print("Endeavor Tracker: Color reset to default")
    end)
    
    -- Color Presets section
    local presetsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetsLabel:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -30)
    presetsLabel:SetText("Color Presets:")
    
    -- Create preset buttons
    local presetButtons = {}
    local buttonsPerRow = 4
    local buttonWidth = 90
    local buttonHeight = 24
    local buttonSpacing = 8
    
    for i, preset in ipairs(colorPresets) do
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(buttonWidth, buttonHeight)
        btn:SetText(preset.name)
        
        -- Position buttons in a grid
        local row = math.floor((i - 1) / buttonsPerRow)
        local col = (i - 1) % buttonsPerRow
        local xOffset = col * (buttonWidth + buttonSpacing)
        local yOffset = -row * (buttonHeight + buttonSpacing)
        
        if col == 0 then
            btn:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, yOffset - 10)
        else
            btn:SetPoint("LEFT", presetButtons[i - 1], "RIGHT", buttonSpacing, 0)
        end
        
        -- Color the button text to match the preset
        btn:GetFontString():SetTextColor(preset.r, preset.g, preset.b)
        
        -- Apply preset on click
        btn:SetScript("OnClick", function()
            self:SetColor(preset.r, preset.g, preset.b)
            colorTexture:SetColorTexture(preset.r, preset.g, preset.b)
            print("Endeavor Tracker: Applied " .. preset.name .. " preset")
        end)
        
        table.insert(presetButtons, btn)
    end
    
    -- Calculate bottom position for info text
    local lastRow = math.floor((#colorPresets - 1) / buttonsPerRow)
    local infoYOffset = -(lastRow * (buttonHeight + buttonSpacing)) - 50
    
    -- Info text
    local info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, infoYOffset)
    info:SetWidth(500)
    info:SetJustifyH("LEFT")
    info:SetText("The tooltip will update automatically when you change the color.\nHover over the endeavor progress bar to see the changes.")
    
    -- Register the panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        -- Store the category reference for opening later
        self.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        -- Fallback for older interface versions
        InterfaceOptions_AddCategory(panel)
        self.settingsCategory = panel
    end
    
    return panel
end

function EndeavorTrackerUI:OpenSettings()
    if Settings and Settings.OpenToCategory and self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and self.settingsCategory then
        InterfaceOptionsFrame_OpenToCategory(self.settingsCategory)
    else
        print("Endeavor Tracker: Please open settings via Game Menu → Options → AddOns → Endeavor Tracker")
    end
end

-- Initialize on load
local uiFrame = CreateFrame("Frame")
uiFrame:RegisterEvent("ADDON_LOADED")
uiFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "EndeavorTracker" then
        EndeavorTrackerUI:InitializeSettings()
        EndeavorTrackerUI:CreateSettingsPanel()
        _print("Endeavor Tracker: Loaded! Commands: /et (settings) | /et refresh")
    end
end)
