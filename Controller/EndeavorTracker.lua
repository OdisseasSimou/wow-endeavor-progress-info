-- EndeavorTracker.lua
-- Controller: Main addon coordination, event handling, slash commands
--
-- Housing endeavors use C_NeighborhoodInitiative API

local EndeavorTracker = {}

-- Silence chat output in this module
local print = function(...) end

function EndeavorTracker:Initialize()
    -- Setup event listeners
    local eventFrame = CreateFrame("Frame")
    
    -- Register all relevant events
    eventFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
    eventFrame:RegisterEvent("INITIATIVE_ACTIVITY_LOG_UPDATED")
    eventFrame:RegisterEvent("INITIATIVE_TASK_COMPLETED")
    eventFrame:RegisterEvent("INITIATIVE_COMPLETED")
    eventFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_LIST_CHANGED")
    eventFrame:RegisterEvent("NEIGHBORHOOD_LIST_UPDATED")
    eventFrame:RegisterEvent("HOUSE_FINDER_NEIGHBORHOOD_DATA_RECIEVED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "NEIGHBORHOOD_INITIATIVE_UPDATED" then
            -- Neighborhood progress updated
            C_Timer.After(0.2, function()
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:UpdateXPDisplay()
                end
                -- Do not refresh the browser list here; it should only refresh once on open
            end)
            
        elseif event == "INITIATIVE_ACTIVITY_LOG_UPDATED" then
            -- Activity log updated - someone contributed
            -- Don't call RequestInitiativeActivityLog() here as it causes infinite recursion!
            -- The event is already triggered, just update the display
            C_Timer.After(0.3, function()
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:UpdateXPDisplay()
                end
            end)
            
        elseif event == "INITIATIVE_TASK_COMPLETED" then
            -- A task was completed
            local taskName = ...
            print(string.format("|cFF00FF00✓ Initiative Task Completed: %s|r", taskName))
            C_Timer.After(0.5, function()
                if C_NeighborhoodInitiative then
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                    C_NeighborhoodInitiative.RequestInitiativeActivityLog()
                end
            end)
            
        elseif event == "INITIATIVE_COMPLETED" then
            -- Entire initiative completed!
            local initiativeTitle = ...
            print(string.format("|cFFFFD700★★★ Initiative Completed: %s ★★★|r", initiativeTitle))
            C_Timer.After(0.5, function()
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:UpdateXPDisplay()
                end
            end)
            
        elseif event == "INITIATIVE_TASKS_TRACKED_LIST_CHANGED" then
            -- Tracked tasks list changed
            local initiativeTaskID, added = ...
            if added then
                print(string.format("|cFF87CEEB+ Task tracked|r"))
            else
                print(string.format("|cFFFFAAAA- Task untracked|r"))
            end
            
        elseif event == "NEIGHBORHOOD_LIST_UPDATED" then
            -- New neighborhood list received from C_Housing API
            local result, neighborhoodInfos = ...
            if result == 0 then  -- HousingResult.Success
                local count = #(neighborhoodInfos or {})
                print("|cFF4080FFNeighborhood list updated: " .. count .. " neighborhoods available|r")
                
                if EndeavorTrackerCore then
                    EndeavorTrackerCore:CacheNeighborhoodList(neighborhoodInfos)
                end
                
                -- Display neighborhoods in chat
                if neighborhoodInfos and count > 0 then
                    print(string.format("|cFFFFD700%-35s %s|r", "Neighborhood", "Owner/Location"))
                    print(string.rep("-", 70))
                    for i, nbhInfo in ipairs(neighborhoodInfos) do
                        if i > 20 then
                            print(string.format("|cFFAAAAAA... and %d more neighborhoods|r", count - 20))
                            break
                        end
                        local ownerInfo = nbhInfo.ownerName or nbhInfo.locationName or "Unknown"
                        print(string.format("%-35s %s", 
                            string.sub(nbhInfo.neighborhoodName or "Unknown", 1, 33),
                            string.sub(ownerInfo, 1, 35)))
                    end
                end
                
                -- Update browser UI if visible
            else
                print("|cFFFF0000Failed to fetch neighborhoods (result: " .. result .. ")|r")
            end
            
        elseif event == "HOUSE_FINDER_NEIGHBORHOOD_DATA_RECIEVED" then
            -- Received detailed neighborhood data from C_Housing API
            local neighborhoodPlots = ...
            print("|cFF4080FFReceived neighborhood plot data (" .. (#(neighborhoodPlots or {}) or 0) .. " plots)|r")
            
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function()
                if C_NeighborhoodInitiative then
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                end
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:HookEndeavorsFrame()
                end
                if EndeavorTrackerHouseFinderTooltips then
                    EndeavorTrackerHouseFinderTooltips:HookHouseFinderFrame()
                end
                -- Request all neighborhoods using Housing API
                if EndeavorTrackerCore then
                    EndeavorTrackerCore:RequestAllNeighborhoods()
                end
                C_Timer.After(1, function()
                    if EndeavorTrackerDisplay then
                        EndeavorTrackerDisplay:UpdateXPDisplay()
                    end
                end)
            end)
        elseif event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "EndeavorTracker" then
                -- Initialize settings
                if EndeavorTrackerUI then
                    EndeavorTrackerUI:InitializeSettings()
                end
            elseif addonName == "Blizzard_HousingHouseFinder" then
                if EndeavorTrackerHouseFinderTooltips then
                    EndeavorTrackerHouseFinderTooltips:HookHouseFinderFrame()
                end
            end
        end
    end)
end

-- Slash commands
SLASH_ENDEAVORTRACKER1 = "/endeavortracker"
SLASH_ENDEAVORTRACKER2 = "/et"
SlashCmdList["ENDEAVORTRACKER"] = function(msg)
    -- Re-enable chat output within slash commands only
    local print = _G.print

    -- Trim whitespace and convert to lowercase
    msg = msg:lower():trim()

    -- Empty input opens settings directly
    if msg == "" or msg == "config" or msg == "settings" then
        if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
            EndeavorTrackerUI:OpenSettings()
        else
            print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
        end
        return
    end
    
    if msg == "refresh" or msg == "reload" or msg == "update" then
        -- Manual refresh
        print("Endeavor Tracker: Refreshing display...")
        
        -- Purge cache first
        if EndeavorTrackerCore then
            EndeavorTrackerCore.taskXPCache = {}
            EndeavorTrackerCore.taskXPCacheTime = 0
        end
        
        if C_NeighborhoodInitiative then
            C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
            C_NeighborhoodInitiative.RequestInitiativeActivityLog()
        end
        if EndeavorTrackerDisplay then
            EndeavorTrackerDisplay:HookEndeavorsFrame()
        end
        
        -- Wait longer for API data to be ready, then rebuild cache
        C_Timer.After(1, function()
            if EndeavorTrackerCore then
                EndeavorTrackerCore:BuildTaskXPCache()
            end
            if EndeavorTrackerDisplay then
                EndeavorTrackerDisplay:UpdateXPDisplay()
            end
            print("Endeavor Tracker: Cache purged and refresh complete")
        end)
    elseif msg == "leaderboard" or msg == "top" or msg == "top10" then
        -- Show top 10 contributors
        print("=== Top 10 Endeavor Contributors ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        C_NeighborhoodInitiative.RequestInitiativeActivityLog()
        C_Timer.After(0.2, function()
            local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
            if not logInfo or not logInfo.taskActivity then
                print("No activity log available")
                return
            end
            
            -- Aggregate points by player
            local playerTotals = {}
            for _, entry in ipairs(logInfo.taskActivity) do
                local playerName = entry.playerName
                local amount = entry.amount or 0
                
                if playerName then
                    playerTotals[playerName] = (playerTotals[playerName] or 0) + amount
                end
            end
            
            -- Convert to sorted array
            local sortedPlayers = {}
            for name, total in pairs(playerTotals) do
                table.insert(sortedPlayers, {name = name, total = total})
            end
            
            -- Sort by total (highest first)
            table.sort(sortedPlayers, function(a, b)
                return a.total > b.total
            end)
            
            -- Display top 10
            print(string.format("\nBased on %d activity log entries:", #logInfo.taskActivity))
            for i = 1, math.min(10, #sortedPlayers) do
                local player = sortedPlayers[i]
                print(string.format("%d. %s - %.2f XP", i, player.name, player.total))
            end
            
            if #sortedPlayers > 10 then
                print(string.format("\n...and %d more contributors", #sortedPlayers - 10))
            end
        end)
    elseif msg == "tasklog" or msg == "logdebug" then
        -- Debug task XP from activity log
        print("=== Task Activity Log Debug ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        C_NeighborhoodInitiative.RequestInitiativeActivityLog()
        C_Timer.After(0.2, function()
            local logInfo = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
            if not logInfo or not logInfo.taskActivity then
                print("No activity log available")
                return
            end
            
            print(string.format("\nTotal log entries: %d", #logInfo.taskActivity))
            
            -- Aggregate by task to find unique tasks and their most recent entry
            local taskData = {}
            for _, entry in ipairs(logInfo.taskActivity) do
                local taskId = entry.taskID
                local completionTime = entry.completionTime or 0
                
                if taskId then
                    if not taskData[taskId] or completionTime > taskData[taskId].completionTime then
                        taskData[taskId] = {
                            id = taskId,
                            name = entry.taskName or "Unknown",
                            amount = entry.amount or 0,
                            completionTime = completionTime,
                            playerName = entry.playerName or "Unknown",
                            count = (taskData[taskId] and taskData[taskId].count or 0) + 1
                        }
                    else
                        taskData[taskId].count = taskData[taskId].count + 1
                    end
                end
            end
            
            -- Sort by task ID
            local sortedIds = {}
            for taskId in pairs(taskData) do
                table.insert(sortedIds, taskId)
            end
            table.sort(sortedIds)
            
            print("\nUnique tasks (most recent completion):")
            print(string.format("%-5s %-40s %-10s %-8s %s", "ID", "Task Name", "XP", "Count", "Last Player"))
            print(string.rep("-", 80))
            
            for _, taskId in ipairs(sortedIds) do
                local task = taskData[taskId]
                print(string.format("%-5d %-40s %-10.2f %-8d %s", 
                    task.id, 
                    string.sub(task.name, 1, 40),
                    task.amount,
                    task.count,
                    task.playerName))
            end
            
            print(string.format("\nTotal unique tasks: %d", #sortedIds))
        end)
    elseif msg == "debug" or msg == "cache" then
        -- Debug: Show cache state
        if EndeavorTrackerCore then
            print("|cFFFFFF00=== Cache Debug ==="|r")
            print("Task XP Cache entries: " .. EndeavorTrackerCore:CountTableEntries(EndeavorTrackerCore.taskXPCache or {}))
            print("Cache time: " .. (EndeavorTrackerCore.taskXPCacheTime or 0))
        end
    else
        -- Default: show help
        print("\n|cFFFFD700=== Endeavor Tracker Commands ===|r")
        print("|cFFFFFF00/et|r - Open settings panel")
        print("")
        
        -- Also check if this is a help request
        if msg == "help" or msg == "?" then
            return
        end
        
        -- Otherwise open settings if not recognized
        if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
            EndeavorTrackerUI:OpenSettings()
        else
            print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
        end
    end
end

-- Initialize on load
C_Timer.After(1, function()
    EndeavorTracker:Initialize()
end)
