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

function EndeavorTrackerCore:CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Export
_G.EndeavorTrackerCore = EndeavorTrackerCore
