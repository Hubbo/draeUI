--[[ Element: PvP Trinket

]]

local parent, ns = ...
local oUF = ns.oUF

local trinketSpells = {
	[59752] = 120,
	[42292] = 120,
	[7744] = 45,
}

--[[

--]]
local CombatLog = function(self, event, ...)
	local trinket = self.Trinket

	if(trinket.PreUpdate) then
		trinket:PreUpdate(event)
	end

	local _, eventType, _, sourceGUID, _, _, _, _, _, _, _, spellID = ...

	if (eventType == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID(self.unit) and trinketSpells[spellID]) then
		CooldownFrame_SetTimer(trinket.cd, GetTime(), trinketSpells[spellID], 1)
	end

	if (trinket.PostUpdate) then
		trinket:PostUpdate(event)
	end
end

local ArenaUpdate = function(self, event, unit, eventType)
	if (unit and self.unit ~= unit) then return end
	unit = unit or self.unit

	local trinket = self.Trinket

	if (event == "ZONE_CHANGED_NEW_AREA") then
		local _, instanceType = GetInstanceInfo()

		if (instanceType == "arena") then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", CombatLog, true)
			trinket:Show()
		else
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED", CombatLog)
			trinket:Hide()
		end
	elseif (eventType == "seen" and UnitExists(unit) and UnitIsPlayer(unit)) then
		trinket.icon:SetTexture(UnitFactionGroup(unit) == "Horde" and "Interface\\Icons\\INV_Jewelry_TrinketPVP_02" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01")
	end
end

local Enable = function(self)
	local trinket = self.Trinket

	if (trinket) then
		self:RegisterEvent("ARENA_OPPONENT_UPDATE", ArenaUpdate, true)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", ArenaUpdate, true)

		return true
	end
end

local Disable = function(self)
	local trinket = self.Trinket

	if (trinket) then
		self:UnregisterEvent("ARENA_OPPONENT_UPDATE", ArenaUpdate)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", ArenaUpdate)

		trinket:Hide()
	end
end

oUF:AddElement("Trinket", ArenaUpdate, Enable, Disable)
