--[[
--]]
local _, ns = ...
local oUF = oUF or ns.oUF

-- Localise a bunch of functions
local UnitClassification = UnitClassification

--
local Update = function(self, event)
	if (self.unit ~= "target") then return end

	local c = UnitClassification(self.unit)

	self.Classification["elite"]:Hide()
	self.Classification["rare"]:Hide()

	if (c == "worldboss" or c == "elite") then
		self.Classification["elite"]:Show()
	elseif (c == "rare" or c == "rareelite") then
		self.Classification["rare"]:Show()
	end
end

local Path = function(self, ...)
	return (self.Classification.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate")
end

local Enable = function(self)
	local classification = self.Classification

	if (classification and type(classification) == "table") then
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)

		self.Classification.__owner = self
		self.Classification.ForceUpdate = ForceUpdate

		return true
	end
end

local Disable = function(self)
	local classification = self.Classification
	if (classification) then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
	end
end

oUF:AddElement("Classification", Path, Enable, Disable)
