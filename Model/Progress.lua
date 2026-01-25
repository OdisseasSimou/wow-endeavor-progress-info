-- Progress.lua
-- Data Model: progress lookups and milestone calculations

local Core = EndeavorTrackerCore
local DEFAULT_THRESHOLDS = Core.MILESTONE_THRESHOLDS

function Core:GetCurrentProgress()
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    if not C_NeighborhoodInitiative.IsInitiativeEnabled() then
        return nil, "Initiatives not enabled"
    end
    
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

function Core:GetMilestoneThresholds(data)
    local thresholds = {}
    
    if data and data.milestones then
        for _, milestone in ipairs(data.milestones) do
            local threshold = milestone.requiredContributionAmount 
                or milestone.progressRequired 
                or milestone.threshold
                or milestone.amount
            
            if threshold then
                table.insert(thresholds, threshold)
            end
        end
    end
    
    if #thresholds > 0 then
        return thresholds
    end
    
    return DEFAULT_THRESHOLDS
end

function Core:CalculateXPNeeded(currentXP, milestones)
    for i, threshold in ipairs(milestones) do
        if currentXP < threshold then
            local xpNeeded = threshold - currentXP
            return xpNeeded, i, threshold, milestones
        end
    end
    
    return 0, #milestones, milestones[#milestones], milestones
end
