-- Tooltips.lua
-- View: Task tooltip enhancements showing XP contribution

local EndeavorTrackerTooltips = {}

EndeavorTrackerTooltips._globalTooltipHooked = false

function EndeavorTrackerTooltips:HookTaskTooltips(frame)
    -- Find all task frames and add XP tooltips
    if not frame then return end
    
    -- Build the XP cache
    EndeavorTrackerCore:BuildTaskXPCache()
    
    -- Hook GameTooltip globally to catch all tooltips
    if not self._globalTooltipHooked then
        GameTooltip:HookScript("OnShow", function(tooltip)
            C_Timer.After(0.05, function()
                EndeavorTrackerTooltips:EnhanceTaskTooltip(tooltip)
            end)
        end)
        
        self._globalTooltipHooked = true
    end
    
    -- Find and hook ScrollBox frames (they contain the task list)
    local hookedCount = 0
    local function FindAndHookScrollBoxes(parent, depth)
        if depth > 20 then return end
        
        for k, v in pairs(parent) do
            if type(v) == "table" then
                -- Check if it's a ScrollBox
                if type(k) == "string" and k:match("ScrollBox") and v.GetObjectType then
                    -- Hook ScrollBox to monitor frame additions
                    if v.GetFrames and not v._ETScrollBoxHooked then
                        -- Get existing frames
                        local frames = v:GetFrames()
                        if frames then
                            for _, childFrame in ipairs(frames) do
                                EndeavorTrackerTooltips:HookSingleFrame(childFrame)
                                hookedCount = hookedCount + 1
                            end
                        end
                        
                        -- Hook future frame updates
                        if v.SetScript then
                            hooksecurefunc(v, "Update", function()
                                local newFrames = v:GetFrames()
                                if newFrames then
                                    for _, childFrame in ipairs(newFrames) do
                                        if not childFrame._ETFrameHooked then
                                            EndeavorTrackerTooltips:HookSingleFrame(childFrame)
                                        end
                                    end
                                end
                            end)
                        end
                        
                        v._ETScrollBoxHooked = true
                    end
                end
                
                -- Recurse
                if v.GetObjectType then
                    FindAndHookScrollBoxes(v, depth + 1)
                end
            end
        end
    end
    
    FindAndHookScrollBoxes(frame, 0)
end

function EndeavorTrackerTooltips:HookSingleFrame(frame)
    if not frame or frame._ETFrameHooked then return end
    
    if frame.HookScript then
        frame:HookScript("OnEnter", function(self)   
            -- Try to get task info
            local taskID = self.taskID or self.InitiativeTaskID or self.initiativeTaskID
            if taskID and EndeavorTrackerCore.taskXPCache[taskID] then
                -- Show a tooltip
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local taskData = EndeavorTrackerCore.taskXPCache[taskID]
                GameTooltip:SetText(taskData.name, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Endeavor Contribution:", string.format("%.2f XP", taskData.amount), 1, 0.82, 0, 1, 1, 1)
                GameTooltip:Show()
            end          
        end)
        frame:HookScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        frame._ETFrameHooked = true
    end
end

function EndeavorTrackerTooltips:EnhanceTaskTooltip(tooltip)
    -- Check if tooltip is showing and has text
    if not tooltip:IsShown() then return end
    if not EndeavorTrackerCore.taskXPCache or not next(EndeavorTrackerCore.taskXPCache) then return end
    
    -- Try to extract task info from tooltip text
    local tooltipName = tooltip:GetName()
    if not tooltipName then return end
    
    -- Get all text lines from the tooltip
    local numLines = tooltip:NumLines()
    
    -- First, check if we've already added the contribution line
    for i = 1, numLines do
        local leftLine = _G[tooltipName .. "TextLeft" .. i]
        if leftLine then
            local success, result = pcall(function()
                local text = leftLine:GetText()
                return text and text == "Endeavor Contribution:"
            end)
            if success and result then
                -- Already enhanced, don't add again
                return
            end
        end
    end
    
    -- Now search for matching task names
    for i = 1, numLines do
        local line = _G[tooltipName .. "TextLeft" .. i]
        if line then
            local success, text = pcall(function()
                return line:GetText()
            end)
            if success and text then
                -- Check if this text matches any task name in our cache
                for taskID, taskData in pairs(EndeavorTrackerCore.taskXPCache) do
                    local matchSuccess, isMatch = pcall(function()
                        return text == taskData.name or text:find(taskData.name, 1, true)
                    end)
                    if matchSuccess and isMatch then
                        -- Add XP info
                        tooltip:AddLine(" ")
                        tooltip:AddDoubleLine("Endeavor Contribution:", string.format("%.2f XP", taskData.amount), 1, 0.82, 0, 1, 1, 1)
                        tooltip:Show()
                        return
                    end
                end
            end
        end
    end
end

function EndeavorTrackerTooltips:ShowTaskTooltip(taskFrame)
    -- Try to find task ID from the frame
    local taskID = taskFrame.taskID or taskFrame.InitiativeTaskID or taskFrame.initiativeTaskID
    
    if not taskID then
        -- Try to extract from frame name or children
        for k, v in pairs(taskFrame) do
            if type(k) == "string" and (k:lower():match("taskid") or k:lower():match("id")) and type(v) == "number" then
                taskID = v
                break
            end
        end
    end
    
    -- If still no taskID, try to get it from GetInitiativeTaskID method
    if not taskID and taskFrame.GetInitiativeTaskID then
        taskID = taskFrame:GetInitiativeTaskID()
    end
    
    if taskID and EndeavorTrackerCore.taskXPCache[taskID] then
        local taskData = EndeavorTrackerCore.taskXPCache[taskID]
        GameTooltip:SetOwner(taskFrame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(taskData.name, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Endeavor Contribution:", string.format("%.2f XP", taskData.amount), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:Show()
    end
end



-- Export
_G.EndeavorTrackerTooltips = EndeavorTrackerTooltips
