-- EndeavorTracker.lua
-- Shows XP needed for next housing endeavor milestone
--
-- Housing endeavors use C_NeighborhoodInitiative API

local EndeavorTracker = {}

-- Milestone XP thresholds (fallback values if API data unavailable)
-- Note: Max endeavor XP is 1000 with 4 milestones
local MILESTONE_THRESHOLDS = {
    250,    -- Milestone 1
    500,    -- Milestone 2
    750,    -- Milestone 3
    1000,   -- Milestone 4 (max)
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
        rawInfo = info, -- Store full info for debugging
    }
end

function EndeavorTracker:GetMilestoneThresholds(data)
    -- Try to extract milestone thresholds from API data
    local thresholds = {}
    
    if data and data.milestones then
        for i, milestone in ipairs(data.milestones) do
            -- Check for the actual field name from API
            local threshold = milestone.requiredContributionAmount or milestone.threshold or milestone.progressRequired or milestone.requiredProgress
            if threshold and type(threshold) == "number" and threshold > 0 then
                table.insert(thresholds, threshold)
            end
        end
    end
    
    -- If we got valid thresholds from API, use them
    if #thresholds > 0 then
        return thresholds
    end
    
    -- Fallback to hardcoded values
    return MILESTONE_THRESHOLDS
end

function EndeavorTracker:CalculateXPNeeded(currentXP, thresholds)
    if not currentXP then return nil end
    
    -- Use provided thresholds or fallback to default
    local milestones = thresholds or MILESTONE_THRESHOLDS
    
    -- Find next milestone
    for i, threshold in ipairs(milestones) do
        if currentXP < threshold then
            local xpNeeded = threshold - currentXP
            return xpNeeded, i, threshold, milestones
        end
    end
    
    -- Max milestone reached
    return 0, #milestones, milestones[#milestones], milestones
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
            frame.ET_XPInfoFrame:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -15)
        else
            -- Create an overlay frame with tooltip strata
            local overlay = CreateFrame("Frame", nil, UIParent)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(10000)
            overlay:SetSize(1000, 60)
            
            -- Position relative to the target
            overlay:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -15)
            
            -- Create the text on the overlay
            local xpInfo = overlay:CreateFontString(nil, "OVERLAY")
            xpInfo:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            xpInfo:SetAllPoints(overlay)
            xpInfo:SetWordWrap(false)
            xpInfo:SetNonSpaceWrap(false)
            
            -- Use color from settings if available
            if EndeavorTrackerUI and EndeavorTrackerUI.GetColor then
                local r, g, b = EndeavorTrackerUI:GetColor()
                xpInfo:SetTextColor(r, g, b)
            else
                xpInfo:SetTextColor(1, 0.82, 0)
            end
            
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
    
    -- Update text color from settings
    if EndeavorTrackerUI and EndeavorTrackerUI.GetColor then
        local r, g, b = EndeavorTrackerUI:GetColor()
        frame.ET_XPInfo:SetTextColor(r, g, b)
    end
    
    local data = self:GetCurrentProgress()
    if not data then
        frame.ET_XPInfo:SetText("")
        return
    end
    
    local currentXP = data.currentXP or 0
    
    -- Get milestone thresholds from API or use fallback
    local thresholds = self:GetMilestoneThresholds(data)
    local xpNeeded, milestone, threshold, usedThresholds = self:CalculateXPNeeded(currentXP, thresholds)
    
    if xpNeeded and xpNeeded > 0 then
        -- Get the text format preference
        local textFormat = "detailed"
        if EndeavorTrackerUI and EndeavorTrackerUI.GetTextFormat then
            textFormat = EndeavorTrackerUI:GetTextFormat()
        end
        
        -- Calculate percentage from previous milestone to next
        local completedMilestone = milestone - 1
        local previousThreshold = completedMilestone > 0 and MILESTONE_THRESHOLDS[completedMilestone] or 0
        local xpFromPrevious = currentXP - previousThreshold
        local xpBetweenMilestones = threshold - previousThreshold
        local percentage = math.floor((xpFromPrevious / xpBetweenMilestones) * 1000) / 10
        
        -- Format text based on selected format
        local text
        if textFormat == "simple" then
            -- Show both completed and target milestone for clarity
            if completedMilestone > 0 then
                text = string.format("%.1f XP to reach Milestone %d (completed: M%d)", 
                    xpNeeded, milestone, completedMilestone)
            else
                text = string.format("%.1f XP to reach Milestone %d", xpNeeded, milestone)
            end
        elseif textFormat == "progress" then
            text = string.format("M%d Progress: %.1f/%.1f (%.1f%%) - %.1f XP to go", 
                milestone, xpFromPrevious, xpBetweenMilestones, percentage, xpNeeded)
        elseif textFormat == "short" then
            text = string.format("To Milestone %d: %.1f XP remaining", milestone, xpNeeded)
        elseif textFormat == "minimal" then
            text = string.format("%.1f XP to next milestone", xpNeeded)
        elseif textFormat == "percentage" then
            text = string.format("%.1f%% to M%d - %.1f XP needed", 
                percentage, milestone, xpNeeded)
        elseif textFormat == "nextfinal" then
            local xpToFinal = 1000 - currentXP
            text = string.format("Next: %.1f XP | Final: %.1f XP", xpNeeded, xpToFinal)
        else -- detailed (default)
            -- Show progress from previous milestone to next
            text = string.format("Milestone %d: %.1f / %.1f (%.1f XP needed)", 
                milestone, xpFromPrevious, xpBetweenMilestones, xpNeeded)
        end
        
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
        EndeavorTracker:HookEndeavorsFrame()
        C_Timer.After(0.5, function()
            EndeavorTracker:UpdateXPDisplay()
            print("Endeavor Tracker: Refresh complete")
        end)
    elseif msg == "debug" or msg == "info" then
        -- Show debug info
        local data = EndeavorTracker:GetCurrentProgress()
        if data then
            print("=== Endeavor Tracker Debug Info ===")
            print("Current XP: " .. (data.currentXP or 0))
            print("Max Progress: " .. (data.maxProgress or 0))
            print("Season: " .. (data.seasonName or "Unknown"))
            if data.milestones then
                print("Milestones from API (" .. #data.milestones .. " total):")
                for i, milestone in ipairs(data.milestones) do
                    print("  Milestone " .. i .. ":")
                    -- Dump all fields in the milestone table
                    for key, value in pairs(milestone) do
                        print("    " .. tostring(key) .. " = " .. tostring(value))
                    end
                end
            else
                print("No milestone data available from API")
            end
            print("=================================")
        else
            print("Endeavor Tracker: No data available")
        end
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
