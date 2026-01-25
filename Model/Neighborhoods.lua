-- Neighborhoods.lua
-- Data Model: neighborhood initiative data and housing helpers

local Core = EndeavorTrackerCore

function Core:GetAllNeighborhoodData(maxRange)
    -- Get data from all accessible neighborhoods
    -- Note: Neighborhood IDs are strings like "Housing-4-2-0-68", not numbers
    
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local neighborhoods = {}
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    
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

function Core:GetNeighborhoodInfo(neighborhoodID)
    -- Get detailed info about a specific neighborhood
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    
    if activeNeighborhoodID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or not info.initiativeID or info.initiativeID == 0 then
        return nil, "Neighborhood not found"
    end
    
    local progressPercent = 0
    if info.progressRequired and info.progressRequired > 0 then
        progressPercent = (info.currentProgress or 0) / info.progressRequired * 100
    end
    
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

function Core:GetMilestoneRewards(neighborhoodID)
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

function Core:GetInitiativeRequirements()
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

function Core:RequestAllNeighborhoods()
    if C_Housing and C_Housing.HouseFinderRequestNeighborhoods then
        C_Housing.HouseFinderRequestNeighborhoods()
        return true
    else
        return false, "C_Housing API not available"
    end
end

function Core:GetAllNeighborhoodsFromHousingAPI()
    return Core.allNeighborhoodsCache or {}
end

function Core:CacheNeighborhoodList(neighborhoodInfos)
    if not neighborhoodInfos then
        return
    end
    
    Core.allNeighborhoodsCache = neighborhoodInfos
    Core.neighborhoodListRequestTime = GetTime()
    
    return neighborhoodInfos
end

function Core:RequestNeighborhoodData(neighborhoodGUID, neighborhoodName)
    if C_Housing and C_Housing.RequestHouseFinderNeighborhoodData then
        C_Housing.RequestHouseFinderNeighborhoodData(neighborhoodGUID, neighborhoodName)
        return true
    else
        return false, "C_Housing API not available"
    end
end

function Core:CheckFactionMatch(neighborhoodGUID)
    if C_Housing and C_Housing.DoesFactionMatchNeighborhood then
        return C_Housing.DoesFactionMatchNeighborhood(neighborhoodGUID)
    end
    
    return true
end

function Core:GetNeighborhoodInitiativeData(neighborhoodID)
    if not C_NeighborhoodInitiative then
        return nil, "C_NeighborhoodInitiative API not available"
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodID)
    C_Timer.After(0.1, function()
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    end)
    
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    
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

function Core:GetQuickNeighborhoodInitiativeData(neighborhoodGUID)
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
    
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodGUID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    
    if activeNeighborhoodID ~= neighborhoodGUID then
        C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
    end
    
    if not info or info.initiativeID == 0 then
        return nil
    end
    
    return {
        title = info.title or "Unknown",
        currentProgress = info.currentProgress or 0,
        progressRequired = info.progressRequired or 0,
        milestonesCount = (info.milestones and #info.milestones) or 0,
        milestones = info.milestones or {},
    }
end
