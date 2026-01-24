-- HouseFinderTooltips.lua
-- View: Endeavor progress tooltips for Blizzard's House Finder neighborhood list

local EndeavorTrackerHouseFinderTooltips = {}

function EndeavorTrackerHouseFinderTooltips:HookHouseFinderFrame()
    local frame = _G.HouseFinderFrame
    if not frame then
        self._ET_HF_Tries = (self._ET_HF_Tries or 0) + 1
        if self._ET_HF_Tries <= 10 then
            C_Timer.After(1, function() EndeavorTrackerHouseFinderTooltips:HookHouseFinderFrame() end)
        end
        return
    end
    if frame._ET_LogHooked then
        return
    end

    local function PopulateTooltip(button, guid, nName, attempt)
        attempt = attempt or 1
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT", 10, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(nName, 1, 0.82, 0)

        local nbhData = nil
        if guid and EndeavorTrackerCore and EndeavorTrackerCore.GetQuickNeighborhoodInitiativeData then
            nbhData = EndeavorTrackerCore:GetQuickNeighborhoodInitiativeData(guid)
        end

        if nbhData then
            if nbhData.title then
                GameTooltip:AddLine(nbhData.title, 0.9, 0.9, 0.9, true)
            end
            local progress = nbhData.currentProgress or 0
            local required = nbhData.progressRequired or 0
            local percent = required > 0 and (progress / required) * 100 or 0
            local milestones = nbhData.milestones or {}
            local completed = 0
            for _, ms in ipairs(milestones) do
                local threshold = ms.requiredContributionAmount or ms.progressRequired or ms.threshold or ms.amount or ms.requiredContribution
                if threshold and progress >= threshold then
                    completed = completed + 1
                end
            end
            local total = #milestones
            if total > 0 then
                GameTooltip:AddDoubleLine("Milestone", string.format("%d/%d", completed, total), 1, 1, 1, 0, 1, 0)
            end
            GameTooltip:AddDoubleLine("Progress", string.format("%.0f / %.0f (%.1f%%)", progress, required, percent), 1, 1, 1, 0, 1, 0)
            GameTooltip:Show()
            return
        end

        GameTooltip:AddLine("Loading endeavor data...", 0.8, 0.7, 0.2)
        GameTooltip:Show()

        if attempt < 3 then
            C_Timer.After(0.25, function()
                if button:IsMouseOver() then
                    PopulateTooltip(button, guid, nName, attempt + 1)
                end
            end)
        end
    end

    local function HookNeighborhoodButton(button, isBnet)
        if not button or button._ET_HoverHooked then return end
        button:HookScript("OnEnter", function(self)
            local info = self.neighborhoodInfo or {}
            local guid = info.neighborhoodGUID or "?"
            local nName = info.neighborhoodName or info.name or "(no name)"

            PopulateTooltip(self, guid, nName, 1)
        end)
        button:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        button._ET_HoverHooked = true
    end

    local function HookButtonPools()
        if frame.neighborhoodButtonPool and frame.neighborhoodButtonPool.EnumerateActive then
            for button in frame.neighborhoodButtonPool:EnumerateActive() do
                HookNeighborhoodButton(button, false)
            end
            if not frame.neighborhoodButtonPool._ET_HookedAcquire then
                local orig = frame.neighborhoodButtonPool.Acquire
                frame.neighborhoodButtonPool.Acquire = function(pool, ...)
                    local obj = orig(pool, ...)
                    HookNeighborhoodButton(obj, false)
                    return obj
                end
                frame.neighborhoodButtonPool._ET_HookedAcquire = true
            end
        end

        if frame.bnetNeighborhoodButtonPool and frame.bnetNeighborhoodButtonPool.EnumerateActive then
            for button in frame.bnetNeighborhoodButtonPool:EnumerateActive() do
                HookNeighborhoodButton(button, true)
            end
            if not frame.bnetNeighborhoodButtonPool._ET_HookedAcquire then
                local orig = frame.bnetNeighborhoodButtonPool.Acquire
                frame.bnetNeighborhoodButtonPool.Acquire = function(pool, ...)
                    local obj = orig(pool, ...)
                    HookNeighborhoodButton(obj, true)
                    return obj
                end
                frame.bnetNeighborhoodButtonPool._ET_HookedAcquire = true
            end
        end
    end

    frame:HookScript("OnShow", function()
        C_Timer.After(0.1, HookButtonPools)
    end)

    if frame:IsShown() then
        C_Timer.After(0.1, HookButtonPools)
    end

    frame._ET_LogHooked = true
end

-- Export
_G.EndeavorTrackerHouseFinderTooltips = EndeavorTrackerHouseFinderTooltips
