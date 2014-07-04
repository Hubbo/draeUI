--[[

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local TS = T:NewModule('SwitchSet', 'AceEvent-3.0')

--
local _G = _G
local GetSpecialization, UseEquipmentSet, UnitClass = GetSpecialization, UseEquipmentSet, UnitClass
local print = print

--[[

--]]
TS.ACTIVE_TALENT_GROUP_CHANGED = function()
	if (C.equipSets[T.playerClass]) then
		local spec = GetSpecialization()

		if (C.equipSets[T.playerClass][spec]) then
			if (UseEquipmentSet(C.equipSets[T.playerClass][spec])) then
				T.Print("Switching to equipment set: ", C.equipSets[T.playerClass][spec])
			end
		end
	end
end

TS.OnEnable = function(self)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
end
