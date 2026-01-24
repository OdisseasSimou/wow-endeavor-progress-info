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
    elseif msg == "neighborhood" or msg == "neighborhoods" or msg == "nbh" then
        -- Show neighborhood endeavor info
        print("=== All Neighborhood Initiatives ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        -- Get active neighborhood ID
        local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
        print("Active Neighborhood ID:", tostring(activeNeighborhoodID))
        
        -- Check current viewing state
        local isViewingActive = C_NeighborhoodInitiative.IsViewingActiveNeighborhood()
        print("Is Viewing Active:", tostring(isViewingActive))
        
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        C_Timer.After(0.5, function()
            print("\nLoading neighborhood data...")
            
            local neighborhoods = EndeavorTrackerCore:GetAllNeighborhoodData()
            
            if not neighborhoods then
                print("|cFFFF0000Error: GetAllNeighborhoodData returned nil|r")
                return
            end
            
            print(string.format("|cFFFFD700Found %d neighborhoods|r\n", #neighborhoods))
            
            if #neighborhoods == 0 then
                print("|cFFFF6B6BNo neighborhoods found. Make sure you're in a neighborhood and initiatives are enabled.|r")
                return
            end
            
            print(string.format("%-30s %-15s %-8s", "Name", "Progress", "M-Stone"))
            print(string.rep("-", 60))
            
            for _, nbh in ipairs(neighborhoods) do
                local mstoneStr = string.format("%d/%d", nbh.completedMilestones, nbh.totalMilestones)
                local progressStr = string.format("%.1f%%", (nbh.progressRequired > 0) and (nbh.currentProgress / nbh.progressRequired * 100) or 0)
                
                print(string.format("%-30s %-15s %-8s", 
                    string.sub(nbh.title, 1, 30),
                    progressStr,
                    mstoneStr))
            end
            
            print("\n\nUse: /et nbh info for detailed information")
        end)
    elseif msg == "nbhdebug" or msg == "nbd" then
        -- Debug neighborhood API
        print("=== Neighborhood API Debug ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        local activeID = C_NeighborhoodInitiative.GetActiveNeighborhood()
        print("Active Neighborhood ID:", activeID)
        print("IsInitiativeEnabled:", C_NeighborhoodInitiative.IsInitiativeEnabled())
        
        -- Try to get current info
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        C_Timer.After(0.5, function()
            local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
            if info then
                print("\n=== Current Neighborhood Info ===")
                print("InitiativeID:", info.initiativeID)
                print("Title:", info.title)
                print("Progress:", info.currentProgress, "/", info.progressRequired)
                print("isLoaded:", info.isLoaded)
                if info.milestones then
                    print("Milestones:", #info.milestones)
                end
            else
                print("GetNeighborhoodInitiativeInfo returned nil")
            end
            
            -- Try scanning for neighborhoods with detailed output
            print("\nScanning neighborhoods 1-20...")
            for id = 1, 20 do
                C_NeighborhoodInitiative.SetViewingNeighborhood(id)
                C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
            end
            
            C_Timer.After(1, function()
                for id = 1, 20 do
                    C_NeighborhoodInitiative.SetViewingNeighborhood(id)
                    local info2 = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
                    if info2 and info2.initiativeID and info2.initiativeID > 0 then
                        print(string.format("ID %d: %s (Initiative %d)", id, info2.title, info2.initiativeID))
                    end
                end
                
                if activeID then
                    C_NeighborhoodInitiative.SetViewingNeighborhood(activeID)
                end
            end)
        end)
    elseif msg == "nbh" or msg == "nbh info" or msg == "neighborhood info" then
        -- Show detailed info about current neighborhood
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        print("=== Current Neighborhood Details ===")
        
        C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        C_NeighborhoodInitiative.RequestInitiativeActivityLog()
        
        C_Timer.After(0.5, function()
            local activeNeighborhoodID = C_NeighborhoodInitiative.GetActiveNeighborhood()
            local info = EndeavorTrackerCore:GetNeighborhoodInfo(activeNeighborhoodID)
            
            if not info then
                print("Neighborhood info not available")
                return
            end
            
            print(string.format("\n[%s]", info.title))
            print("Initiative ID: " .. info.initiativeID)
            print(string.format("Progress: %.1f / %.1f XP (%.1f%% complete)", 
                info.currentProgress, info.progressRequired, info.progressPercent))
            
            if info.milestones and #info.milestones > 0 then
                print("\nMilestones:")
                for _, milestone in ipairs(info.milestones) do
                    local status = milestone.isCompleted and "✓ COMPLETED" or "○ In Progress"
                    print(string.format("  Milestone %d: %d XP required - %s", 
                        milestone.index, milestone.threshold, status))
                end
            end
            
            if info.contributors and #info.contributors > 0 then
                print(string.format("\nTop Contributors (%d total):", info.uniqueContributors))
                for i, contributor in ipairs(info.contributors) do
                    if i > 10 then
                        print(string.format("  ... and %d more contributors", info.uniqueContributors - 10))
                        break
                    end
                    print(string.format("  %2d. %-20s - %.1f XP (%d tasks)", 
                        i, 
                        string.sub(contributor.name, 1, 20),
                        contributor.totalXP,
                        contributor.taskCount))
                end
            end
            
            print(string.format("\nActivity Log Entries: %d", info.totalActivityEntries))
        end)
    elseif msg:match("^nbh%s+(%d+)$") or msg:match("^neighborhood%s+(%d+)$") then
        -- Show detailed info about a specific neighborhood
        local nbhID = tonumber(msg:match("(%d+)"))
        
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        print("=== Loading Neighborhood " .. nbhID .. " Details ===")
        
        C_Timer.After(0.5, function()
            local info = EndeavorTrackerCore:GetNeighborhoodInfo(nbhID)
            
            if not info then
                print("Neighborhood not found or invalid ID")
                return
            end
            
            print(string.format("\n[%s]", info.title))
            print("Initiative ID: " .. info.initiativeID)
            print(string.format("Progress: %.1f / %.1f XP (%.1f%% complete)", 
                info.currentProgress, info.progressRequired, info.progressPercent))
            
            if info.milestones and #info.milestones > 0 then
                print("\nMilestones:")
                for _, milestone in ipairs(info.milestones) do
                    local status = milestone.isCompleted and "✓ COMPLETED" or "○ In Progress"
                    print(string.format("  Milestone %d: %d XP required - %s", 
                        milestone.index, milestone.threshold, status))
                end
            end
            
            if info.contributors and #info.contributors > 0 then
                print(string.format("\nTop Contributors (%d total):", info.uniqueContributors))
                for i, contributor in ipairs(info.contributors) do
                    if i > 10 then
                        print(string.format("  ... and %d more contributors", info.uniqueContributors - 10))
                        break
                    end
                    print(string.format("  %2d. %-20s - %.1f XP (%d tasks)", 
                        i, 
                        string.sub(contributor.name, 1, 20),
                        contributor.totalXP,
                        contributor.taskCount))
                end
            end
            
            print(string.format("\nActivity Log Entries: %d", info.totalActivityEntries))
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
    elseif msg == "tracked" or msg == "tracks" or msg == "mytasks" then
        -- Show currently tracked initiative tasks
        print("=== Your Tracked Initiative Tasks ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        local trackedTasks = EndeavorTrackerCore:GetTrackedTasks()
        
        if #trackedTasks == 0 then
            print("No tasks currently tracked")
            return
        end
        
        print(string.format("Tracking %d tasks:\n", #trackedTasks))
        print(string.format("%-5s %-40s %-12s %s", "ID", "Task Name", "XP Value", "Status"))
        print(string.rep("-", 80))
        
        for _, task in ipairs(trackedTasks) do
            local status = task.completed and "|cFF00FF00✓ Completed|r" or (task.inProgress and "|cFFFFFF00In Progress|r" or "|cFFAAAAAAPending|r")
            print(string.format("%-5d %-40s %-12d %s", 
                task.ID, 
                string.sub(task.taskName, 1, 40),
                task.progressContributionAmount,
                status))
        end
    elseif msg == "requirements" or msg == "reqs" or msg == "check" then
        -- Check player requirements for initiatives
        print("=== Initiative Requirements ===")
        if not C_NeighborhoodInitiative then
            print("API not available")
            return
        end
        
        local reqs = EndeavorTrackerCore:GetInitiativeRequirements()
        
        if reqs then
            print(string.format("Initiative Access: %s", reqs.hasAccess and "|cFF00FF00✓ Yes|r" or "|cFFFF0000✗ No|r"))
            print(string.format("Required Level: %d", reqs.requiredLevel))
            print(string.format("Meets Level: %s", reqs.meetsLevel and "|cFF00FF00✓ Yes|r" or "|cFFFF0000✗ No|r"))
            print(string.format("In Neighborhood Group: %s", reqs.inGroup and "|cFF00FF00✓ Yes|r" or "|cFFFF0000✗ No|r"))
        else
            print("Failed to check requirements")
        end
    elseif msg == "list" or msg == "allnbh" or msg == "neighborhoods list" then
        -- Show all accessible neighborhoods from C_Housing API
        print("=== Requesting All Neighborhoods ===")
        
        if EndeavorTrackerCore then
            local success = EndeavorTrackerCore:RequestAllNeighborhoods()
            if success then
                print("Neighborhood list requested... waiting for NEIGHBORHOOD_LIST_UPDATED event")
                print("This may take a moment. Results will be displayed automatically.")
                
                -- Also try to show cached data if available
                C_Timer.After(2, function()
                    local cached = EndeavorTrackerCore:GetAllNeighborhoodsFromHousingAPI()
                    if cached and #cached > 0 then
                        print("\n|cFFFFD700Cached Neighborhoods Available - Use /et browser to view detailed list|r")
                    end
                end)
            else
                print("|cFFFF0000Failed: C_Housing API not available|r")
            end
        else
            print("|cFFFF0000Failed: EndeavorTrackerCore not loaded|r")
        end
    elseif msg == "show" or msg == "show list" then
        -- Show cached neighborhoods list
        if EndeavorTrackerCore then
            local cached = EndeavorTrackerCore:GetAllNeighborhoodsFromHousingAPI()
            if cached and #cached > 0 then
                print("\n|cFFFFD700=== Cached Neighborhoods ===|r")
                print(string.format("|cFFFFD700%-35s %s|r", "Neighborhood", "Owner/Location"))
                print(string.rep("-", 70))
                for i, nbhInfo in ipairs(cached) do
                    if i > 20 then
                        print(string.format("|cFFAAAAAA... and %d more neighborhoods|r", #cached - 20))
                        break
                    end
                    local ownerInfo = nbhInfo.ownerName or nbhInfo.locationName or "Unknown"
                    print(string.format("%-35s %s", 
                        string.sub(nbhInfo.neighborhoodName or "Unknown", 1, 33),
                        string.sub(ownerInfo, 1, 35)))
                end
                print("\nUse |cFFFFFF00/et browser|r to view detailed list")
            else
                print("No neighborhoods in cache. Try |cFFFFFF00/et list|r first")
            end
        end
    elseif msg == "debug" or msg == "cache" then
        -- Debug: Show cache state
        if EndeavorTrackerCore then
            local cached = EndeavorTrackerCore:GetAllNeighborhoodsFromHousingAPI()
            print("|cFFFFFF00=== Cache Debug ===|r")
            print("Cached neighborhoods: " .. #cached)
            if #cached > 0 then
                for i, nbh in ipairs(cached) do
                    print(string.format("%d. %s (GUID: %s)", i, nbh.neighborhoodName or "Unknown", nbh.neighborhoodGUID or "nil"))
                end
            end
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
