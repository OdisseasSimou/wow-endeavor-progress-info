-- ProgressOverlay.lua
-- View: XP progress display overlay on neighborhood initiative frame
local EndeavorTrackerDisplay = {}

-- Reference to hooked frame
EndeavorTrackerDisplay.hookedFrame = nil
-- Temporary debug switch for diagnosing missing hover events
EndeavorTrackerDisplay.debugHover = false
-- Bounded fallback scan state to avoid repeated full _G scans forever
EndeavorTrackerDisplay.scanState = EndeavorTrackerDisplay.scanState or {
    attempts = 0,
    windowStart = 0,
    lastScan = 0,
}

local MAX_GLOBAL_SCAN_ATTEMPTS = 6
local SCAN_WINDOW_SECONDS = 8
local SCAN_MIN_INTERVAL = 0.75

function EndeavorTrackerDisplay:DebugHover(msg)
    if not self.debugHover then
        return
    end
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[ET Hover]|r " .. tostring(msg))
    end
end

function EndeavorTrackerDisplay:HookEndeavorsFrame()
    -- Search for Blizzard's neighborhood initiative UI
    local possibleFrames = {"NeighborhoodInitiativeFrame", "HousingDashboardFrame"}

    local frame = nil
    for _, frameName in ipairs(possibleFrames) do
        frame = _G[frameName]
        if frame then
            break
        end
    end

    local now = (GetTime and GetTime()) or 0

    local function CanRunGlobalScan()
        if now <= 0 then
            -- If timing API is unavailable for any reason, allow a conservative scan.
            return true
        end

        if self.scanState.windowStart == 0 or (now - self.scanState.windowStart) > SCAN_WINDOW_SECONDS then
            self.scanState.windowStart = now
            self.scanState.attempts = 0
        end

        if self.scanState.attempts >= MAX_GLOBAL_SCAN_ATTEMPTS then
            return false
        end

        if self.scanState.lastScan > 0 and (now - self.scanState.lastScan) < SCAN_MIN_INTERVAL then
            return false
        end

        self.scanState.attempts = self.scanState.attempts + 1
        self.scanState.lastScan = now
        return true
    end

    -- Fallback: scan globals with bounded retries to handle late Blizzard UI loading.
    if not frame then
        if CanRunGlobalScan() then
            for k, v in pairs(_G) do
                if (type(v) == "table" or type(v) == "userdata") and type(k) == "string" then
                    if (k:match("Initiative") or k:match("Neighborhood")) and k:match("Frame") then
                        local ok, canCreateFont = pcall(function()
                            return v.CreateFontString ~= nil
                        end)
                        if ok and canCreateFont then
                            frame = v
                            self:DebugHover("Found frame via global scan: " .. k)
                            break
                        end
                    end
                end
            end
        else
            self:DebugHover("Skipping global scan (bounded retry/cooldown)")
        end
    end

    if not frame then
        self:DebugHover("No frame found to hook")
        return false
    end

    -- Reset bounded-scan state once we successfully found a frame.
    self.scanState.attempts = 0
    self.scanState.windowStart = now

    local function SafeCall(obj, methodName, ...)
        if not obj or type(methodName) ~= "string" then
            return nil
        end

        -- Avoid metatable/__index access on userdata (can trigger forbidden table errors)
        local okFn, fn = pcall(function()
            return obj[methodName]
        end)
        if not okFn or type(fn) ~= "function" then
            return nil
        end

        local ok, res = pcall(fn, obj, ...)
        if ok then
            return res
        end
        return nil
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

    -- Collect all candidates for positioning
    local allCandidates = {}
    local visited = {}

    local function AddCandidate(label, obj, depth)
        if not obj or (type(obj) ~= "table" and type(obj) ~= "userdata") then
            return
        end

        local objType = SafeGetObjectType(obj)
        if not objType then
            return
        end

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

    -- Collect recursively all child frames
    local function CollectAll(parent, depth)
        if depth > 10 or not parent or visited[parent] then
            return
        end
        visited[parent] = true

        -- Only traverse children; do not recurse with pairs(parent)
        local ok, children = pcall(function()
            return {parent:GetChildren()}
        end)
        if ok and children then
            for _, child in ipairs(children) do
                AddCandidate(SafeGetName(child) or "child", child, depth)
                CollectAll(child, depth + 1)
            end
        end
    end

    -- >>> This call is what populates allCandidates <<<
    CollectAll(frame, 0)

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
    if targetCandidate and targetCandidate.obj then
        self:DebugHover(string.format("Target candidate: type=%s name=%s depth=%d", targetCandidate.type or "?",
            targetCandidate.name or "unnamed", targetCandidate.depth or -1))
        -- Check if overlay already exists, if so just reuse it
        if frame.ET_XPInfoFrame and frame.ET_XPInfo then
            frame.ET_XPInfoFrame:ClearAllPoints()
            frame.ET_XPInfoFrame:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -15)
            self:DebugHover("Reused existing overlay frame")
        else
            -- Use UIParent to avoid clipping by Blizzard frames/statusbars/scrollframes
            local overlay = CreateFrame("Frame", nil, UIParent)
            overlay:SetFrameStrata("TOOLTIP")
            overlay:SetFrameLevel(9999)
            overlay:SetClampedToScreen(true)
            overlay:SetPoint("BOTTOM", targetCandidate.obj, "TOP", 50, -10)

            -- Dark background (Added background on text)
            local bg = overlay:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(overlay)
            bg:SetColorTexture(0, 0, 0, 0.75)

            -- Text
            local xpInfo = overlay:CreateFontString(nil, "OVERLAY")
            xpInfo:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            xpInfo:SetPoint("CENTER", overlay, "CENTER")
            xpInfo:SetWordWrap(true)
            xpInfo:SetMaxLines(2)
                        -- Auto-size overlay to text (with max width + padding)
            local PAD_X, PAD_Y = 14, 10
            local MAX_W = 500 -- max width before wrap; adjustable

            local function UpdateOverlaySize()
                -- Measure natural (unwrapped) width first
                xpInfo:SetWidth(0)
                local naturalW = xpInfo:GetStringWidth() or 0

                -- Apply wrapping only when needed
                local textW = naturalW
                if textW > MAX_W then
                    textW = MAX_W
                end
                if textW < 1 then
                    textW = 1
                end

                xpInfo:SetWidth(textW)

                local h = xpInfo:GetStringHeight() or 0
                if h < 1 then
                    h = 1
                end

                overlay:SetSize(textW + PAD_X * 2, h + PAD_Y * 2)
            end


            overlay.ET_UpdateOverlaySize = UpdateOverlaySize
            if EndeavorTrackerUI and EndeavorTrackerUI.GetColor then
                local r, g, b = EndeavorTrackerUI:GetColor()
                xpInfo:SetTextColor(r, g, b)
            else
                xpInfo:SetTextColor(1, 0.82, 0)
            end

            xpInfo:SetText("Hover over the progress bar")
            overlay.ET_UpdateOverlaySize()

            C_Timer.After(1.0, function()
                if overlay then
                    overlay:Hide()
                end
            end)

            local function ShowOverlay(source)
                overlay:Show()
                EndeavorTrackerDisplay:DebugHover("OnEnter from " .. tostring(source))
            end
            local function HideOverlay(source)
                overlay:Hide()
                EndeavorTrackerDisplay:DebugHover("OnLeave from " .. tostring(source))
            end

            local function IsMouseOverProgressTarget()
                local target = frame.ET_ProgressBar or targetCandidate.obj
                if not target then
                    return false
                end

                if target.IsMouseOver then
                    local ok, over = pcall(target.IsMouseOver, target)
                    if ok and over then
                        return true
                    end
                end

                if MouseIsOver then
                    local ok, over = pcall(MouseIsOver, target)
                    if ok and over then
                        return true
                    end
                end

                return false
            end

            local function MakeEnterHandler(source)
                return function()
                    if source == "root-frame" and not IsMouseOverProgressTarget() then
                        EndeavorTrackerDisplay:DebugHover("Ignored root-frame enter outside progress target")
                        return
                    end
                    ShowOverlay(source)
                end
            end

            local function MakeLeaveHandler(source)
                return function()
                    HideOverlay(source)
                end
            end

            -- Hook hover on both the bar and the main frame (bar often doesn't receive mouse)
            if targetCandidate.obj.EnableMouse then
                targetCandidate.obj:EnableMouse(true)
                self:DebugHover("Enabled mouse on progress target")
            end
            if targetCandidate.obj.HookScript then
                targetCandidate.obj:HookScript("OnEnter", MakeEnterHandler("progress-target"))
                targetCandidate.obj:HookScript("OnLeave", MakeLeaveHandler("progress-target"))
                self:DebugHover("Hooked OnEnter/OnLeave on progress target")
            end

            -- Fallback hover target: some Blizzard status bars do not reliably get mouse events.
            if frame.EnableMouse then
                frame:EnableMouse(true)
                self:DebugHover("Enabled mouse on root frame")
            end
            if frame.HookScript then
                frame:HookScript("OnEnter", MakeEnterHandler("root-frame"))
                frame:HookScript("OnLeave", MakeLeaveHandler("root-frame"))
                self:DebugHover("Hooked OnEnter/OnLeave on root frame")
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
                EndeavorTrackerDisplay:UpdateXPDisplay()
                -- Request activity log and hook task tooltips
                if EndeavorTrackerCore and EndeavorTrackerCore.RequestInitiativeActivityLog then
                    EndeavorTrackerCore:RequestInitiativeActivityLog(2.5)
                else
                    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
                end
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
            if EndeavorTrackerCore and EndeavorTrackerCore.RequestInitiativeActivityLog then
                EndeavorTrackerCore:RequestInitiativeActivityLog(2.5)
            else
                C_NeighborhoodInitiative.RequestInitiativeActivityLog()
            end
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
    -- Try to hook if not already hooked.
    if not self.hookedFrame then
        if not self:HookEndeavorsFrame() then
            return
        end
    end

    -- Use stored frame reference
    local frame = self.hookedFrame
    if not frame then
        return
    end

    -- XP info should already be created by HookEndeavorsFrame
    if not frame.ET_XPInfo then
        return
    end

    local function ResizeOverlay()
        if frame.ET_XPInfoFrame and frame.ET_XPInfoFrame.ET_UpdateOverlaySize then
            frame.ET_XPInfoFrame.ET_UpdateOverlaySize()
        end
    end

    -- Update text color from settings
    if EndeavorTrackerUI and EndeavorTrackerUI.GetColor then
        local r, g, b = EndeavorTrackerUI:GetColor()
        frame.ET_XPInfo:SetTextColor(r, g, b)
    end

    local data = EndeavorTrackerCore:GetCurrentProgress()
    if not data then
        frame.ET_XPInfo:SetText("")
        ResizeOverlay()
        return
    end

    local currentXP = data.currentXP or 0

    -- Get milestone thresholds from API or use fallback
    local thresholds = EndeavorTrackerCore:GetMilestoneThresholds(data)
    local xpNeeded, milestone, threshold, usedThresholds = EndeavorTrackerCore:CalculateXPNeeded(currentXP, thresholds)

    local text

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
        text = self:FormatText(textFormat, milestone, xpNeeded, xpFromPrevious, xpBetweenMilestones, percentage,
            completedMilestone, currentXP)
    elseif xpNeeded == 0 then
        text = "All milestones completed!"
    else
        text = "Calculating..."
    end

    frame.ET_XPInfo:SetText(text)
    ResizeOverlay()
end

function EndeavorTrackerDisplay:FormatText(textFormat, milestone, xpNeeded, xpFromPrevious, xpBetweenMilestones,
    percentage, completedMilestone, currentXP)
    if textFormat == "simple" then
        if completedMilestone > 0 then
            return string.format("%.1f XP to reach Milestone %d (completed: M%d)", xpNeeded, milestone,
                completedMilestone)
        else
            return string.format("%.1f XP to reach Milestone %d", xpNeeded, milestone)
        end
    elseif textFormat == "progress" then
        return string.format("M%d Progress: %.1f/%.1f (%.1f%%) - %.1f XP to go", milestone, xpFromPrevious,
            xpBetweenMilestones, percentage, xpNeeded)
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
        return string.format("Milestone %d: %.1f / %.1f (%.1f XP needed)", milestone, xpFromPrevious,
            xpBetweenMilestones, xpNeeded)
    end
end

-- Export
_G.EndeavorTrackerDisplay = EndeavorTrackerDisplay
