-- Core.lua
-- Data Model: API interactions, data processing, XP calculations

local EndeavorTrackerCore = {}

-- Milestone XP thresholds (fallback values if API data unavailable)
local MILESTONE_THRESHOLDS = {
    250,    -- Milestone 1
    500,    -- Milestone 2
    750,    -- Milestone 3
    1000,   -- Milestone 4 (max)
}

-- Task XP cache
EndeavorTrackerCore.taskXPCache = {}
EndeavorTrackerCore.taskXPCacheTime = 0

function EndeavorTrackerCore:GetCurrentProgress()
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
        rawInfo = info,
    }
end

function EndeavorTrackerCore:GetMilestoneThresholds(data)
    -- Try to extract milestone thresholds from API data
    local thresholds = {}
    
    if data and data.milestones then
        for _, milestone in ipairs(data.milestones) do
            -- Try multiple possible field names for the threshold value
            local threshold = milestone.requiredContributionAmount 
                or milestone.progressRequired 
                or milestone.threshold
                or milestone.amount
            
            if threshold then
                table.insert(thresholds, threshold)
            end
        end
    end
    
    -- If we found valid thresholds from API, use them
    if #thresholds > 0 then
        return thresholds
    end
    
    -- Otherwise fall back to hardcoded values
    return MILESTONE_THRESHOLDS
end

function EndeavorTrackerCore:CalculateXPNeeded(currentXP, milestones)
    -- Find the next milestone that hasn't been reached
    for i, threshold in ipairs(milestones) do
        if currentXP < threshold then
            local xpNeeded = threshold - currentXP
            return xpNeeded, i, threshold, milestones
        end
    end
    
    -- Max milestone reached
    return 0, #milestones, milestones[#milestones], milestones
end

function EndeavorTrackerCore:BuildTaskXPCache()
    -- Always rebuild cache from fresh activity log data
    local cache = {}
    
    if not C_NeighborhoodInitiative then
        return cache
    end
    
    -- Request fresh activity log data
    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    
    -- Get activity log data
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    if logInfo and logInfo.taskActivity then
        for _, entry in ipairs(logInfo.taskActivity) do
            local taskId = entry.taskID
            local taskName = entry.taskName
            local amount = entry.amount
            local completionTime = entry.completionTime or 0
            
            if taskId and amount and taskName then
                -- Store most recent entry for each task (based on completionTime)
                if not cache[taskId] or completionTime > (cache[taskId].completionTime or 0) then
                    cache[taskId] = {
                        name = taskName,
                        amount = amount,
                        completionTime = completionTime
                    }
                end
            end
        end
    end
    
    self.taskXPCache = cache
    self.taskXPCacheTime = GetTime()
    
    return cache
end

function EndeavorTrackerCore:CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Export
_G.EndeavorTrackerCore = EndeavorTrackerCore
