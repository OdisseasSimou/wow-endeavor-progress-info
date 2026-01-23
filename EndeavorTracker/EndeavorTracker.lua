-- EndeavorTracker.lua
-- Shows XP needed for next housing endeavor milestone
--
-- Housing endeavors use C_NeighborhoodInitiative API

local EndeavorTracker = {}

-- Milestone XP thresholds (these are the total XP values)
local MILESTONE_THRESHOLDS = {
    500,    -- Milestone 1
    1500,   -- Milestone 2
    3000,   -- Milestone 3
    5000,   -- Milestone 4
    7500,   -- Milestone 5
    10500,  -- Milestone 6
    14000,  -- Milestone 7
    18000,  -- Milestone 8
    22500,  -- Milestone 9
    27500,  -- Milestone 10
}

function EndeavorTracker:GetCurrentProgress()
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    -- Check if initiatives are enabled
    if not C_NeighborhoodInitiative.IsInitiativeEnabled() then
        return nil, "Initiatives not enabled"
    end
    
    -- Get initiative info
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    if not info or not info.isLoaded then
        return nil, "Initiative data not loaded"
    end
    
    if info.initiativeID == 0 then
        return nil, "No active initiative"
    end
    
    return {
        currentXP = info.currentProgress or 0,
        maxProgress = info.progressRequired or 0,
        seasonName = info.title or "Unknown",
        milestones = info.milestones,
    }
end

function EndeavorTracker:CalculateXPNeeded(currentXP)
    if not currentXP then return nil end
    
    -- Find next milestone
    for i, threshold in ipairs(MILESTONE_THRESHOLDS) do
        if currentXP < threshold then
            local xpNeeded = threshold - currentXP
            return xpNeeded, i, threshold
        end
    end
    
    -- Max milestone reached
    return 0, #MILESTONE_THRESHOLDS, MILESTONE_THRESHOLDS[#MILESTONE_THRESHOLDS]
end

function EndeavorTracker:HookEndeavorsFrame()
    -- Search for Blizzard's neighborhood initiative UI
    local possibleFrames = {
        "NeighborhoodInitiativeFrame",
        "HousingDashboardFrame",
    }
    
    local frame = nil
    for _, frameName in ipairs(possibleFrames) do
        frame = _G[frameName]
        if frame then
            break
        end
    end
    
    -- Search all global frames for Initiative/Neighborhood
    if not frame then
        for k, v in pairs(_G) do
            if type(v) == "table" and type(k) == "string" then
                if (k:match("Initiative") or k:match("Neighborhood")) and k:match("Frame") then
                    if not frame and v.CreateFontString then
                        frame = v
                        break
                    end
                end
            end
        end
    end
    
    if not frame then
        self.hookedFrame = false
        return false
    end
    
    -- Collect all candidates for positioning
    local allCandidates = {}
    local function CollectAll(parent, depth)
        if depth > 10 then return end
        for k, v in pairs(parent) do
            if type(v) == "table" then
                if type(k) == "string" and (k:match("Progress") or k:match("Bar")) then
                    if v.GetObjectType and (v:GetObjectType() == "StatusBar" or v:GetObjectType() == "Frame" or v:GetObjectType() == "Slider") then
                        local objName = v.GetName and v:GetName() or "unnamed"
                        table.insert(allCandidates, {key = k, obj = v, type = v:GetObjectType(), name = objName, depth = depth})
                    end
                end
                CollectAll(v, depth + 1)
            end
        end
    end
    CollectAll(frame, 0)
    
    -- Filter candidates with depth > 4
    local deepCandidates = {}
    for _, c in ipairs(allCandidates) do
        if c.depth > 4 then
            table.insert(deepCandidates, c)
        end
    end
    
    -- Use the 4th deep candidate (index 4) if available
    local targetCandidate = nil
    if #deepCandidates >= 4 then
        targetCandidate = deepCandidates[4]
    elseif #allCandidates > 0 then
        targetCandidate = allCandidates[1]
    end
    
    -- Create XP info on the target using a tooltip-level overlay frame
    if targetCandidate then
        -- Check if overlay already exists, if so just reuse it
        if frame.ET_XPInfoFrame and frame.ET_XPInfo then
            -- Already exists, just update position if needed
            frame.ET_XPInfoFrame:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 0, -5)
        else
            -- Create an overlay frame with tooltip strata
            local overlay = CreateFrame("Frame", nil, UIParent)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(10000)
            overlay:SetSize(1000, 60)
            
            -- Position relative to the target
            overlay:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 0, -5)
            
            -- Create the text on the overlay
            local xpInfo = overlay:CreateFontString(nil, "OVERLAY")
            xpInfo:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            xpInfo:SetAllPoints(overlay)
            xpInfo:SetWordWrap(false)
            xpInfo:SetNonSpaceWrap(false)
            xpInfo:SetTextColor(1, 0.82, 0)
            xpInfo:SetText("Hover over the progress bar")
            
            -- Start hidden, show on hover
            overlay:Hide()
            
            -- Hook hover events on the progress bar
            if targetCandidate.obj:HasScript("OnEnter") then
                targetCandidate.obj:HookScript("OnEnter", function()
                    overlay:Show()
                end)
            end
            if targetCandidate.obj:HasScript("OnLeave") then
                targetCandidate.obj:HookScript("OnLeave", function()
                    overlay:Hide()
                end)
            end
            
            frame.ET_XPInfo = xpInfo
            frame.ET_XPInfoFrame = overlay
            frame.ET_ProgressBar = targetCandidate.obj
        end
    end
    
    -- Hook frame show
    if not frame._EndeavorTrackerHooked then
        frame:HookScript("OnShow", function()
            C_Timer.After(0.1, function()
                EndeavorTracker:UpdateXPDisplay()
            end)
        end)
        frame._EndeavorTrackerHooked = true
    end
    
    -- Store the frame reference
    self.hookedFrame = frame
    
    return true
end

function EndeavorTracker:UpdateXPDisplay()
    -- Try to hook if not already hooked
    if not self.hookedFrame or self.hookedFrame == false then
        if not self:HookEndeavorsFrame() then
            return
        end
    end
    
    -- Use stored frame reference
    local frame = self.hookedFrame
    if not frame or frame == false then
        return
    end
    
    -- XP info should already be created by HookEndeavorsFrame
    if not frame.ET_XPInfo then
        return
    end
    
    local data = self:GetCurrentProgress()
    if not data then
        frame.ET_XPInfo:SetText("")
        return
    end
    
    local currentXP = data.currentXP or 0
    local xpNeeded, milestone, threshold = self:CalculateXPNeeded(currentXP)
    
    if xpNeeded and xpNeeded > 0 then
        local text = string.format("Next Milestone: %d / %d (%d XP needed)", 
            currentXP, threshold, xpNeeded)
        frame.ET_XPInfo:SetText(text)
    elseif xpNeeded == 0 then
        frame.ET_XPInfo:SetText("All milestones completed!")
    else
        frame.ET_XPInfo:SetText("Calculating...")
    end
end

function EndeavorTracker:Initialize()
    -- Setup event listeners
    local eventFrame = CreateFrame("Frame")
    
    eventFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "NEIGHBORHOOD_INITIATIVE_UPDATED" then
            C_Timer.After(0.2, function()
                EndeavorTracker:UpdateXPDisplay()
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(2, function()
                if C_NeighborhoodInitiative then
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                end
                C_Timer.After(0.5, function()
                    EndeavorTracker:UpdateXPDisplay()
                end)
            end)
        elseif event == "ADDON_LOADED" then
            local addon = ...
            if addon and (addon:match("Housing") or addon:match("Neighborhood")) then
                C_Timer.After(1, function()
                    EndeavorTracker:HookEndeavorsFrame()
                    if C_NeighborhoodInitiative then
                        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                    end
                    C_Timer.After(0.5, function()
                        EndeavorTracker:UpdateXPDisplay()
                    end)
                end)
            end
        end
    end)
    
    -- Try initial hook after a delay
    C_Timer.After(3, function()
        if C_NeighborhoodInitiative then
            C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        end
        C_Timer.After(0.5, function()
            EndeavorTracker:UpdateXPDisplay()
        end)
    end)
end

-- Slash command for manual refresh
SLASH_ENDEAVORTRACKER1 = "/endeavortracker"
SLASH_ENDEAVORTRACKER2 = "/et"
SlashCmdList["ENDEAVORTRACKER"] = function(msg)
    if C_NeighborhoodInitiative then
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    end
    EndeavorTracker:HookEndeavorsFrame()
    C_Timer.After(0.5, function()
        EndeavorTracker:UpdateXPDisplay()
    end)
end

-- Initialize on load
C_Timer.After(1, function()
    EndeavorTracker:Initialize()
end)
