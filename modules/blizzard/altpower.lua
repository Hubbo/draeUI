--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local B = T:GetModule("Blizzard")

--[[
		Move alt power bar
--]]
B.PositionAltPowerBar = function(self)
	local holder = CreateFrame("Frame", "AltPowerBarHolder")
	holder:SetPoint("TOP", UIParent, "TOP", 0, -80)
	holder:SetSize(128, 50)

	PlayerPowerBarAlt:ClearAllPoints()
	PlayerPowerBarAlt:SetPoint("CENTER", holder, "CENTER")
	PlayerPowerBarAlt:SetParent(holder)
	PlayerPowerBarAlt.ignoreFramePositionManager = true
end
