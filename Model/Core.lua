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

-- Multi-neighborhood cache
EndeavorTrackerCore.allNeighborhoodsCache = {}
EndeavorTrackerCore.neighborhoodListRequestTime = 0

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

-- Neighborhood data retrieval functions
function EndeavorTrackerCore:GetAllNeighborhoodData(maxRange)
    -- Get data from all accessible neighborhoods
    -- Note: Neighborhood IDs are strings like "Housing-4-2-0-68", not numbers
    
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local neighborhoods = {}
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    -- Try to get available neighborhoods using the API
    -- First, request info for the current neighborhood
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    
    -- We can only reliably view neighborhoods we know about
    -- For now, just return info about the current neighborhood
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    
    if info and info.initiativeID and info.initiativeID > 0 then
        local milestones = info.milestones or {}
        local completedMilestones = 0
        
        for _, milestone in ipairs(milestones) do
            local threshold = milestone.requiredContributionAmount or 0
            if (info.currentProgress or 0) >= threshold then
                completedMilestones = completedMilestones + 1
            end
        end
        
        table.insert(neighborhoods, {
            id = activeNeighborhoodID,
            initiativeID = info.initiativeID,
            title = info.title or "Unknown",
            currentProgress = info.currentProgress or 0,
            progressRequired = info.progressRequired or 0,
            isActive = true,
            completedMilestones = completedMilestones,
            totalMilestones = #milestones,
            milestones = milestones,
            rawInfo = info,
        })
    end
    
    return neighborhoods
end

function EndeavorTrackerCore:GetNeighborhoodInfo(neighborhoodID)
    -- Get detailed info about a specific neighborhood
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    -- Temporarily switch to this neighborhood and request data
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    
    -- Give the API a moment to process the requests
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    
    -- Reset to active neighborhood
    if activeNeighborhoodID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or not info.initiativeID or info.initiativeID == 0 then
        return nil, "Neighborhood not found"
    end
    
    -- Calculate progress percentage
    local progressPercent = 0
    if info.progressRequired and info.progressRequired > 0 then
        progressPercent = (info.currentProgress or 0) / info.progressRequired * 100
    end
    
    -- Process milestones
    local milestones = {}
    if info.milestones then
        for i, milestone in ipairs(info.milestones) do
            local threshold = milestone.requiredContributionAmount or 0
            local isCompleted = (info.currentProgress or 0) >= threshold
            
            table.insert(milestones, {
                index = i,
                threshold = threshold,
                isCompleted = isCompleted,
                requiredAmount = threshold,
            })
        end
    end
    
    -- Count unique contributors and aggregate their contributions
    local contributors = {}
    if logInfo and logInfo.taskActivity then
        for _, entry in ipairs(logInfo.taskActivity) do
            local playerName = entry.playerName
            local amount = entry.amount or 0
            
            if playerName then
                if not contributors[playerName] then
                    contributors[playerName] = {
                        name = playerName,
                        totalXP = 0,
                        taskCount = 0,
                    }
                end
                contributors[playerName].totalXP = contributors[playerName].totalXP + amount
                contributors[playerName].taskCount = contributors[playerName].taskCount + 1
            end
        end
    end
    
    -- Convert contributors to sorted list
    local contributorList = {}
    for _, contributor in pairs(contributors) do
        table.insert(contributorList, contributor)
    end
    table.sort(contributorList, function(a, b) return a.totalXP > b.totalXP end)
    
    return {
        id = neighborhoodID,
        initiativeID = info.initiativeID,
        title = info.title or "Unknown",
        currentProgress = info.currentProgress or 0,
        progressRequired = info.progressRequired or 0,
        progressPercent = progressPercent,
        milestones = milestones,
        contributors = contributorList,
        uniqueContributors = #contributorList,
        totalActivityEntries = logInfo and #(logInfo.taskActivity) or 0,
        rawInfo = info,
        rawLogInfo = logInfo,
    }
end

-- Task tracking and information functions
function EndeavorTrackerCore:GetTrackedTasks()
    -- Get list of currently tracked initiative tasks
    if not C_NeighborhoodInitiative then
        return {}
    end
    
    local trackedData = C_NeighborhoodInitiative.GetTrackedInitiativeTasks()
    if not trackedData or not trackedData.trackedIDs then
        return {}
    end
    
    local trackedTasks = {}
    for _, taskID in ipairs(trackedData.trackedIDs) do
        local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(taskID)
        if taskInfo then
            table.insert(trackedTasks, taskInfo)
        end
    end
    
    return trackedTasks
end

function EndeavorTrackerCore:TrackTask(initiativeTaskID)
    -- Add a task to tracking list
    if not C_NeighborhoodInitiative then
        return false
    end
    
    C_NeighborhoodInitiative.AddTrackedInitiativeTask(initiativeTaskID)
    return true
end

function EndeavorTrackerCore:UntrackTask(initiativeTaskID)
    -- Remove a task from tracking list
    if not C_NeighborhoodInitiative then
        return false
    end
    
    C_NeighborhoodInitiative.RemoveTrackedInitiativeTask(initiativeTaskID)
    return true
end

function EndeavorTrackerCore:GetTaskInfo(initiativeTaskID)
    -- Get detailed info about a specific task
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    return C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)
end

function EndeavorTrackerCore:IsTaskTracked(initiativeTaskID)
    -- Check if a task is currently tracked
    local trackedData = C_NeighborhoodInitiative.GetTrackedInitiativeTasks()
    if not trackedData or not trackedData.trackedIDs then
        return false
    end
    
    for _, taskID in ipairs(trackedData.trackedIDs) do
        if taskID == initiativeTaskID then
            return true
        end
    end
    
    return false
end

function EndeavorTrackerCore:GetMilestoneRewards(neighborhoodID)
    -- Get detailed milestone rewards information
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    
    local info = C_NeighborhoodInitiativeInfo()
    
    if activeNeighborhoodID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or not info.milestones then
        return nil
    end
    
    local milestonesWithRewards = {}
    for i, milestone in ipairs(info.milestones) do
        local rewards = {}
        if milestone.rewards then
            for _, reward in ipairs(milestone.rewards) do
                table.insert(rewards, {
                    title = reward.title,
                    description = reward.description,
                    decorID = reward.decorID,
                    decorQuantity = reward.decorQuantity,
                    favor = reward.favor,
                    money = reward.money,
                    rewardQuestID = reward.rewardQuestID,
                })
            end
        end
        
        table.insert(milestonesWithRewards, {
            index = i,
            threshold = milestone.requiredContributionAmount,
            rewards = rewards,
        })
    end
    
    return milestonesWithRewards
end

function EndeavorTrackerCore:GetInitiativeRequirements()
    -- Check if player meets initiative requirements
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    local hasAccess = C_NeighborhoodInitiative.PlayerHasInitiativeAccess()
    local meetsLevel = C_NeighborhoodInitiative.PlayerMeetsRequiredLevel()
    local requiredLevel = C_NeighborhoodInitiative.GetRequiredLevel()
    local inGroup = C_NeighborhoodInitiative.IsPlayerInNeighborhoodGroup()
    
    return {
        hasAccess = hasAccess,
        meetsLevel = meetsLevel,
        requiredLevel = requiredLevel,
        inGroup = inGroup,
    }
end

-- Multi-neighborhood support using C_Housing API
function EndeavorTrackerCore:RequestAllNeighborhoods()
    -- Request list of all accessible neighborhoods from C_Housing API
    if C_Housing and C_Housing.HouseFinderRequestNeighborhoods then
        C_Housing.HouseFinderRequestNeighborhoods()
        return true
    else
        return false, "C_Housing API not available"
    end
end

function EndeavorTrackerCore:GetAllNeighborhoodsFromHousingAPI()
    -- Get the cached neighborhood list from C_Housing
    -- This data comes from the NEIGHBORHOOD_LIST_UPDATED event
    return self.allNeighborhoodsCache or {}
end

function EndeavorTrackerCore:CacheNeighborhoodList(neighborhoodInfos)
    -- Cache the neighborhood list when received from NEIGHBORHOOD_LIST_UPDATED event
    if not neighborhoodInfos then
        return
    end
    
    self.allNeighborhoodsCache = neighborhoodInfos
    self.neighborhoodListRequestTime = GetTime()
    
    -- DEBUG: Log what we received
    -- print("Cached " .. #neighborhoodInfos .. " neighborhoods")
    
    return neighborhoodInfos
end

function EndeavorTrackerCore:RequestNeighborhoodData(neighborhoodGUID, neighborhoodName)
    -- Request detailed data for a specific neighborhood
    if C_Housing and C_Housing.RequestHouseFinderNeighborhoodData then
        C_Housing.RequestHouseFinderNeighborhoodData(neighborhoodGUID, neighborhoodName)
        return true
    else
        return false, "C_Housing API not available"
    end
end

function EndeavorTrackerCore:CheckFactionMatch(neighborhoodGUID)
    -- Check if player's faction matches the neighborhood
    if C_Housing and C_Housing.DoesFactionMatchNeighborhood then
        return C_Housing.DoesFactionMatchNeighborhood(neighborhoodGUID)
    end
    
    return true -- Assume faction matches if API unavailable
end

function EndeavorTrackerCore:GetNeighborhoodInitiativeData(neighborhoodID)
    -- Get initiative data for a specific neighborhood
    -- This requires setting viewing to that neighborhood
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    -- Temporarily switch to this neighborhood
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodID)
    C_Timer.After(0.1, function()
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    end)
    
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    
    -- Reset to active neighborhood
    if activeNeighborhoodID ~= neighborhoodID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or info.initiativeID == 0 then
        return nil, "No initiative for neighborhood"
    end
    
    return {
        info = info,
        logInfo = logInfo,
    }
end

function EndeavorTrackerCore:GetQuickNeighborhoodInitiativeData(neighborhoodGUID)
    -- Quick fetch of just initiative progress for a neighborhood
    -- Used for browser display without full detail fetching
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    -- Try to set viewing to the neighborhood GUID
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodGUID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    
    -- Reset to active neighborhood
    if activeNeighborhoodID ~= neighborhoodGUID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or info.initiativeID == 0 then
        return nil
    end
    
    -- Return just the progress info needed for display
    return {
        title = info.title or "Unknown",
        currentProgress = info.currentProgress or 0,
        progressRequired = info.progressRequired or 0,
        milestonesCount = (info.milestones and #info.milestones) or 0,
        milestones = info.milestones or {},
    }
end

-- Export
_G.EndeavorTrackerCore = EndeavorTrackerCore
