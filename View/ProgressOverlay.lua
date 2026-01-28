-- ProgressOverlay.lua
-- View: XP progress display overlay on neighborhood initiative frame

local EndeavorTrackerDisplay = {}

-- Reference to hooked frame
EndeavorTrackerDisplay.hookedFrame = nil

function EndeavorTrackerDisplay:HookEndeavorsFrame()
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
local function SafeCall(obj, methodName)
    if not obj then return nil end
    local fn = obj[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, obj)
    if ok then return res end
end

local function SafeGetName(obj)
    local name = SafeCall(obj, "GetName")
    if type(name) == "string" and name ~= "" then
        return name
    end
end

local function SafeGetObjectType(obj)
    local t = SafeCall(obj, "GetObjectType")
    if type(t) == "string" and t ~= "" then
        return t
    end
end

local allCandidates = {}
local visited = {}

local function AddCandidate(label, obj, depth)
    if not obj or type(obj) ~= "table" then return end

    local objType = SafeGetObjectType(obj)
    if not objType then return end

    local objName = SafeGetName(obj) or "unnamed"

    local labelMatch = type(label) == "string" and (label:match("Progress") or label:match("Bar"))
    local nameMatch = (objName:match("Progress") or objName:match("Bar"))

    if objType == "StatusBar" or objType == "Frame" or objType == "Slider" then
        if labelMatch or nameMatch or objType == "StatusBar" then
            table.insert(allCandidates, {
                key = label or "",
                obj = obj,
                type = objType,
                name = objName,
                depth = depth
            })
        end
    end
end
    
    -- Filter candidates with depth > 4
    local deepCandidates = {}
    for _, c in ipairs(allCandidates) do
        if c.depth > 4 then
            table.insert(deepCandidates, c)
        end
    end
    
    local function PickDeepest(candidates)
        local best = nil
        for _, c in ipairs(candidates) do
            if not best or c.depth > best.depth then
                best = c
            end
        end
        return best
    end
    local statusBarCandidates = {}
    for _, c in ipairs(allCandidates) do
        if c.type == "StatusBar" then
            table.insert(statusBarCandidates, c)
        end
    end

    local targetCandidate = PickDeepest(statusBarCandidates)
    if not targetCandidate then
        targetCandidate = PickDeepest(deepCandidates)
    end
    if not targetCandidate then
        targetCandidate = PickDeepest(allCandidates)
    end
    
    -- Create XP info on the target using a tooltip-level overlay frame
    if targetCandidate then
        -- Check if overlay already exists, if so just reuse it
        if frame.ET_XPInfoFrame and frame.ET_XPInfo then
            -- Already exists, just update position if needed
            frame.ET_XPInfoFrame:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -15)
        else
            -- Create an overlay on the main frame (not the bar) so it is not clipped by the status bar
            local overlay = CreateFrame("Frame", nil, frame)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(targetCandidate.obj:GetFrameLevel() + 5)
            overlay:SetSize(500, 40)
            overlay:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -10)
            
            -- Create the text on the overlay
            local xpInfo = overlay:CreateFontString(nil, "OVERLAY")
            xpInfo:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            xpInfo:SetPoint("CENTER", overlay, "CENTER")
            xpInfo:SetWordWrap(true)
            xpInfo:SetMaxLines(2)
            
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
            
            -- Hover handlers
            local function ShowOverlay()
                overlay:Show()
            end
            local function HideOverlay()
                overlay:Hide()
            end
            targetCandidate.obj:EnableMouse(true)
            targetCandidate.obj:HookScript("OnEnter", ShowOverlay)
            targetCandidate.obj:HookScript("OnLeave", HideOverlay)
            
            frame.ET_XPInfo = xpInfo
            frame.ET_XPInfoFrame = overlay
            frame.ET_ProgressBar = targetCandidate.obj
        end
    end
    
    -- Hook frame show
    if not frame._EndeavorTrackerHooked then
        frame:HookScript("OnShow", function()
            C_Timer.After(0.1, function()
                EndeavorTrackerDisplay:UpdateXPDisplay()
                -- Request activity log and hook task tooltips
                C_NeighborhoodInitiative.RequestInitiativeActivityLog()
                C_Timer.After(0.5, function()
                    if EndeavorTrackerTooltips then
                        EndeavorTrackerTooltips:HookTaskTooltips(frame)
                    end
                end)
            end)
        end)
        frame._EndeavorTrackerHooked = true
        
        -- Also call it immediately if frame is already shown
        if frame:IsShown() then
            C_NeighborhoodInitiative.RequestInitiativeActivityLog()
            C_Timer.After(0.6, function()
                if EndeavorTrackerTooltips then
                    EndeavorTrackerTooltips:HookTaskTooltips(frame)
                end
            end)
        end
    end
    
    -- Store the frame reference
    self.hookedFrame = frame
    
    return true
end

function EndeavorTrackerDisplay:UpdateXPDisplay()
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
    
    local data = EndeavorTrackerCore:GetCurrentProgress()
    if not data then
        frame.ET_XPInfo:SetText("")
        return
    end
    
    local currentXP = data.currentXP or 0
    
    -- Get milestone thresholds from API or use fallback
    local thresholds = EndeavorTrackerCore:GetMilestoneThresholds(data)
    local xpNeeded, milestone, threshold, usedThresholds = EndeavorTrackerCore:CalculateXPNeeded(currentXP, thresholds)
    
    if xpNeeded and xpNeeded > 0 then
        -- Get the text format preference
        local textFormat = "detailed"
        if EndeavorTrackerUI and EndeavorTrackerUI.GetTextFormat then
            textFormat = EndeavorTrackerUI:GetTextFormat()
        end
        
        -- Calculate percentage from previous milestone to next
        local completedMilestone = milestone - 1
        local previousThreshold = completedMilestone > 0 and thresholds[completedMilestone] or 0
        local xpFromPrevious = currentXP - previousThreshold
        local xpBetweenMilestones = threshold - previousThreshold
        local percentage = math.floor((xpFromPrevious / xpBetweenMilestones) * 1000) / 10
        
        -- Format text based on selected format
        local text = self:FormatText(textFormat, milestone, xpNeeded, xpFromPrevious, xpBetweenMilestones, percentage, completedMilestone, currentXP)
        
        frame.ET_XPInfo:SetText(text)
    elseif xpNeeded == 0 then
        frame.ET_XPInfo:SetText("All milestones completed!")
    else
        frame.ET_XPInfo:SetText("Calculating...")
    end
end

function EndeavorTrackerDisplay:FormatText(textFormat, milestone, xpNeeded, xpFromPrevious, xpBetweenMilestones, percentage, completedMilestone, currentXP)
    if textFormat == "simple" then
        if completedMilestone > 0 then
            return string.format("%.1f XP to reach Milestone %d (completed: M%d)", xpNeeded, milestone, completedMilestone)
        else
            return string.format("%.1f XP to reach Milestone %d", xpNeeded, milestone)
        end
    elseif textFormat == "progress" then
        return string.format("M%d Progress: %.1f/%.1f (%.1f%%) - %.1f XP to go", milestone, xpFromPrevious, xpBetweenMilestones, percentage, xpNeeded)
    elseif textFormat == "short" then
        return string.format("To Milestone %d: %.1f XP remaining", milestone, xpNeeded)
    elseif textFormat == "minimal" then
        return string.format("%.1f XP to next milestone", xpNeeded)
    elseif textFormat == "percentage" then
        return string.format("%.1f%% to M%d - %.1f XP needed", percentage, milestone, xpNeeded)
    elseif textFormat == "nextfinal" then
        local xpToFinal = 1000 - currentXP
        return string.format("Next: %.1f XP | Final: %.1f XP", xpNeeded, xpToFinal)
    else -- detailed (default)
        return string.format("Milestone %d: %.1f / %.1f (%.1f XP needed)", milestone, xpFromPrevious, xpBetweenMilestones, xpNeeded)
    end
end

-- Export
_G.EndeavorTrackerDisplay = EndeavorTrackerDisplay
