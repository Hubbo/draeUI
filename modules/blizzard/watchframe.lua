--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local B = T:GetModule("Blizzard")

--[[

--]]
local noop = function() end

B.MoveWatchFrame = function(self)
	WatchFrame:SetMovable(true)
	WatchFrame:SetResizable(true)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -5, -40)
	WatchFrame:SetHeight(WatchFrame:GetTop() - CONTAINER_OFFSET_Y)
	WatchFrame:SetScale(0.95)
	WatchFrame:SetUserPlaced(true)
	WatchFrame:SetMovable(false)
	WatchFrame:SetResizable(false)

	WatchFrame.SetPoint = noop
end
