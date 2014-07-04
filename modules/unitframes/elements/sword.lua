--[[
--]]
local _, ns = ...
local oUF = oUF or ns.oUF

-- Localise a bunch of functions
local UnitIsUnit, UnitAura, UnitThreatSituation, GetThreatStatusColor, DebuffTypeColor = UnitIsUnit, UnitAura, UnitThreatSituation, GetThreatStatusColor, DebuffTypeColor

local dispellPriority = {
	["Magic"] = 4,
	["Disease"] = 3,
	["Poison"] = 2,
	["Curse"] = 1
}

local GetDebuffType = function(unit)
	local debuffType
	local index = 1
	local pr = 0

	while (true) do
		local name, _, _, _, dtype = UnitAura(unit, index, "HARMFUL")

		if (not name) then break end

		if (dtype and pr < dispellPriority[dtype]) then
			debuffType = dtype
			pr = dispellPriority[dtype]
		end

		index = index + 1
	end

	return debuffType
end

local Update = function(self, event, unit)
	if (unit and self.unit ~= unit) then return end
	unit = unit or self.unit

	local sword = self.Sword

	local show = false
	local r, g, b = 1.0, 1.0, 1.0

	if (UnitIsUnit("player", unit)) then
		local debufftype = GetDebuffType(unit)

		if (debufftype) then
			local color = DebuffTypeColor[debufftype]

			show, r, g, b = true, color.r, color.g, color.b
		end
	end

	if (UnitCanAttack("player", unit)) then
		local status = UnitThreatSituation("player", unit)

		if (status and status > 0) then
			show, r, g, b = true, GetThreatStatusColor(status)
		end
	end

	if (show) then
		sword.overlay:SetVertexColor(r, g, b)

		if (not sword.__isShown) then
			sword.overlay:Show()

			sword.__isShown = true
		end
	elseif (sword.__isShown) then
		sword.overlay:Hide()

		sword.__isShown = nil
	end
end

local Path = function(self, ...)
	return (self.Sword.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self, unit)
	local sword = self.Sword

	if (sword) then
		sword.__owner = self
		sword.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_AURA", Path)
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Path, true)

		return true
	end
end

local Disable = function(self)
	local sword = self.Sword

	if(sword) then
		self:UnregisterEvent("UNIT_AURA", Path)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Path)
	end
end

oUF:AddElement('Sword', Path, Enable, Disable)
