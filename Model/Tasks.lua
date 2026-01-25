-- Tasks.lua
-- Data Model: task XP cache and tracking helpers

local Core = EndeavorTrackerCore

function Core:BuildTaskXPCache()
    local cache = {}
    
    if not C_NeighborhoodInitiative then
        return cache
    end
    
    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    
    local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
    if logInfo and logInfo.taskActivity then
        for _, entry in ipairs(logInfo.taskActivity) do
            local taskId = entry.taskID
            local taskName = entry.taskName
            local amount = entry.amount
            local completionTime = entry.completionTime or 0
            
            if taskId and amount and taskName then
                if not cache[taskId] or completionTime > (cache[taskId].completionTime or 0) then
                    cache[taskId] = {
                        name = taskName,
                        amount = amount,
                        completionTime = completionTime,
                    }
                end
            end
        end
    end
    
    Core.taskXPCache = cache
    Core.taskXPCacheTime = GetTime()
    
    return cache
end

function Core:GetTrackedTasks()
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

function Core:TrackTask(initiativeTaskID)
    if not C_NeighborhoodInitiative then
        return false
    end
    
    C_NeighborhoodInitiative.AddTrackedInitiativeTask(initiativeTaskID)
    return true
end

function Core:UntrackTask(initiativeTaskID)
    if not C_NeighborhoodInitiative then
        return false
    end
    
    C_NeighborhoodInitiative.RemoveTrackedInitiativeTask(initiativeTaskID)
    return true
end

function Core:GetTaskInfo(initiativeTaskID)
    if not C_NeighborhoodInitiative then
        return nil
    end
    
    return C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)
end

function Core:IsTaskTracked(initiativeTaskID)
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
