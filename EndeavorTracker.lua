-- EndeavorTracker.lua
-- Controller: Main addon coordination, event handling, slash commands
--
-- Housing endeavors use C_NeighborhoodInitiative API

local EndeavorTracker = {}

function EndeavorTracker:Initialize()
    -- Setup event listeners
    local eventFrame = CreateFrame("Frame")
    
    eventFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "NEIGHBORHOOD_INITIATIVE_UPDATED" then
            C_Timer.After(0.2, function()
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:UpdateXPDisplay()
                end
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function()
                if C_NeighborhoodInitiative then
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                end
                if EndeavorTrackerDisplay then
                    EndeavorTrackerDisplay:HookEndeavorsFrame()
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
            end
        end
    end)
end

-- Slash commands
SLASH_ENDEAVORTRACKER1 = "/endeavortracker"
SLASH_ENDEAVORTRACKER2 = "/et"
SlashCmdList["ENDEAVORTRACKER"] = function(msg)
    -- Trim whitespace and convert to lowercase
    msg = msg:lower():trim()
    
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
        C_Timer.After(0.2, function()
            print("\nScanning for neighborhoods (IDs 1-100)...")
            local foundNeighborhoods = {}
            
            -- Try to find neighborhoods by ID
            for id = 1, 100 do
                -- Set viewing to this neighborhood
                C_NeighborhoodInitiative.SetViewingNeighborhood(id)
                C_Timer.After(0.05, function()
                    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
                end)
            end
            
            -- Wait for all requests to complete
            C_Timer.After(1.5, function()
                print("\nTrying to read info from different neighborhood IDs...")
                
                for id = 1, 100 do
                    C_NeighborhoodInitiative.SetViewingNeighborhood(id)
                    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
                    
                    if info and info.initiativeID and info.initiativeID > 0 then
                        local isActive = (id == activeNeighborhoodID) and " (ACTIVE)" or ""
                        print(string.format("\n[Neighborhood %d]%s", id, isActive))
                        print("  Title:", info.title or "Unknown")
                        print("  Initiative ID:", info.initiativeID)
                        print("  Progress:", string.format("%.1f / %.1f", info.currentProgress or 0, info.progressRequired or 0))
                        
                        if info.milestones then
                            local completedCount = 0
                            for _, milestone in ipairs(info.milestones) do
                                local threshold = milestone.requiredContributionAmount or 0
                                if (info.currentProgress or 0) >= threshold then
                                    completedCount = completedCount + 1
                                end
                            end
                            print("  Milestones:", string.format("%d/%d completed", completedCount, #info.milestones))
                        end
                    end
                end
                
                -- Reset to active neighborhood
                if activeNeighborhoodID then
                    C_NeighborhoodInitiative.SetViewingNeighborhood(activeNeighborhoodID)
                end
                print("\nReset to active neighborhood")
            end)
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
    else
        -- Default: open settings
        if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
            EndeavorTrackerUI:OpenSettings()
        else
            print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
        end
    end
end

-- Slash command to open settings (kept for compatibility)
SLASH_ENDEAVORTRACKERCONFIG1 = "/etconfig"
SLASH_ENDEAVORTRACKERCONFIG2 = "/etset"
SlashCmdList["ENDEAVORTRACKERCONFIG"] = function(msg)
    if EndeavorTrackerUI and EndeavorTrackerUI.OpenSettings then
        EndeavorTrackerUI:OpenSettings()
    else
        print("Endeavor Tracker: Settings not available yet. Please open via Game Menu → Options → AddOns → Endeavor Tracker")
    end
end

-- Initialize on load
C_Timer.After(1, function()
    EndeavorTracker:Initialize()
end)
