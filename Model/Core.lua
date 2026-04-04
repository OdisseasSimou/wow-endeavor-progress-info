-- Core.lua
-- Data Model: base connector and shared caches

local EndeavorTrackerCore = _G.EndeavorTrackerCore or {}

-- Milestone XP defaults (used by Progress.lua when API data is missing)
EndeavorTrackerCore.MILESTONE_THRESHOLDS = EndeavorTrackerCore.MILESTONE_THRESHOLDS or {
    250,
    500,
    750,
    1000,
}

-- Task XP cache
EndeavorTrackerCore.taskXPCache = EndeavorTrackerCore.taskXPCache or {}
EndeavorTrackerCore.taskXPCacheTime = EndeavorTrackerCore.taskXPCacheTime or 0

-- Multi-neighborhood cache
EndeavorTrackerCore.allNeighborhoodsCache = EndeavorTrackerCore.allNeighborhoodsCache or {}
EndeavorTrackerCore.neighborhoodListRequestTime = EndeavorTrackerCore.neighborhoodListRequestTime or 0

-- Request throttling state for noisy initiative APIs
EndeavorTrackerCore.requestTimestamps = EndeavorTrackerCore.requestTimestamps or {
    neighborhoodInfo = 0,
    activityLog = 0,
}

local function GetNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

function EndeavorTrackerCore:ShouldThrottleRequest(key, minInterval, force)
    if force then
        return false
    end
    if type(key) ~= "string" then
        return false
    end

    local interval = tonumber(minInterval) or 0
    if interval <= 0 then
        return false
    end

    local now = GetNow()
    local last = self.requestTimestamps[key] or 0
    return (now - last) < interval
end

function EndeavorTrackerCore:MarkRequestTime(key)
    if type(key) ~= "string" then
        return
    end
    self.requestTimestamps[key] = GetNow()
end

function EndeavorTrackerCore:RequestNeighborhoodInitiativeInfo(minInterval, force)
    if not C_NeighborhoodInitiative or not C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo then
        return false
    end
    if self:ShouldThrottleRequest("neighborhoodInfo", minInterval or 1.5, force) then
        return false
    end
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
    self:MarkRequestTime("neighborhoodInfo")
    return true
end

function EndeavorTrackerCore:RequestInitiativeActivityLog(minInterval, force)
    if not C_NeighborhoodInitiative or not C_NeighborhoodInitiative.RequestInitiativeActivityLog then
        return false
    end
    if self:ShouldThrottleRequest("activityLog", minInterval or 2.0, force) then
        return false
    end
    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
    self:MarkRequestTime("activityLog")
    return true
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
