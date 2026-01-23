-- EndeavorTracker.lua
-- Controller: Main addon coordination, event handling, slash commands
--
-- Housing endeavors use C_NeighborhoodInitiative API

local EndeavorTracker = {}

function EndeavorTracker:Initialize()
    -- Setup event listeners
    local eventFrame = CreateFrame("Frame")
    
    eventFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "NEIGHBORHOOD_INITIATIVE_UPDATED" then
            C_Timer.After(0.2, function()
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:UpdateXPDisplay()
                end
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function()
                if C_NeighborhoodInitiative then
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                end
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:HookEndeavorsFrame()
                end
                C_Timer.After(1, function()
                    if EndeavorTrackerDisplay then
                        EndeavorTrackerDisplay:UpdateXPDisplay()
                    end
                end)
            end)
        elseif event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "EndeavorTracker" then
                -- Initialize settings
                if EndeavorTrackerUI then
                    EndeavorTrackerUI:InitializeSettings()
                end
            end
        end
    end)
end

-- Slash commands
SLASH_ENDEAVORTRACKER1 = "/endeavortracker"
SLASH_ENDEAVORTRACKER2 = "/et"
SlashCmdList["ENDEAVORTRACKER"] = function(msg)
    -- Trim whitespace and convert to lowercase
    msg = msg:lower():trim()
    
    if msg == "refresh" or msg == "reload" or msg == "update" then
        -- Manual refresh
        print("Endeavor Tracker: Refreshing display...")
        if C_NeighborhoodInitiative then
            C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        end
        if EndeavorTrackerDisplay then
            EndeavorTrackerDisplay:HookEndeavorsFrame()
        end
        C_Timer.After(0.5, function()
            if EndeavorTrackerDisplay then
                EndeavorTrackerDisplay:UpdateXPDisplay()
            end
            print("Endeavor Tracker: Refresh complete")
        end)
    else
        -- Default: open settings
        if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
            EndeavorTrackerUI:OpenSettings()
        else
            print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
        end
    end
end

-- Slash command to open settings (kept for compatibility)
SLASH_ENDEAVORTRACKERCONFIG1 = "/etconfig"
SLASH_ENDEAVORTRACKERCONFIG2 = "/etset"
SlashCmdList["ENDEAVORTRACKERCONFIG"] = function(msg)
    if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
        EndeavorTrackerUI:OpenSettings()
    else
        print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
    end
end

-- Initialize on load
C_Timer.After(1, function()
    EndeavorTracker:Initialize()
end)
