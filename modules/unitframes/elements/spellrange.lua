--[[****************************************************************************
	* oUF_SpellRange by Saiket                                                   *
	* oUF_SpellRange.lua - Improved range element for oUF.                       *
	*                                                                            *
	* Elements handled: .SpellRange                                              *
	* Settings: (Either Update method or both alpha properties are required)     *
	*   - .SpellRange.Update( Frame, InRange ) - Callback fired when a unit      *
	*       either enters or leaves range. Overrides default alpha changing.     *
	*   OR                                                                       *
	*   - .SpellRange.insideAlpha - Frame alpha value for units in range.        *
	*   - .SpellRange.outsideAlpha - Frame alpha for units out of range.         *
	* Note that SpellRange will automatically disable Range elements of frames.  *
	****************************************************************************]]

local _, ns = ...
local oUF = ns.oUF or oUF

-- Localise a bunch of functions
local pairs, ipairs, assert, type, tonumber, next = pairs, ipairs, assert, type, tonumber, next
local CreateFrame, UnitIsConnected, UnitCanAssist, UnitCanAttack, UnitIsUnit, UnitPlayerOrPetInRaid, UnitIsDead, UnitOnTaxi, UnitInRange, IsSpellInRange, CheckInteractDistance,  UnitPlayerOrPetInParty = CreateFrame, UnitIsConnected, UnitCanAssist, UnitCanAttack, UnitIsUnit, UnitPlayerOrPetInRaid, UnitIsDead, UnitOnTaxi, UnitInRange, IsSpellInRange, CheckInteractDistance,  UnitPlayerOrPetInParty

--
local updateRate = 0.1
local playerClass = select(2, UnitClass("player"))

-- Optional lists of low level baseline skills with greater than 28 yard range.
-- Note: Spells probably shouldn't have minimum ranges!
local spellCheckHelp = GetSpellInfo(({
	DEATHKNIGHT 	= 47541, 	-- Death Coil (40yd) 		- Lvl 55
	DRUID 			= 774, 		-- Rejuvenation(40yd) 		- Lvl 4
	MAGE 			= 475, 		-- Remove Curse (40yd) 		- Lvl 29
	MONK 			= 115450, 	-- Detox (40yd)				- Lvl 20
	PALADIN 		= 85673, 	-- Word of Glory (40yd) 	- Lvl 9
	PRIEST 			= 2061, 	-- Flash Heal (40yd) 		- Lvl 7
	SHAMAN 			= 8004, 	-- Healing Surge (40yd) 	- Lvl 7
	WARLOCK 		= 5697, 	-- Unending Breath (30yd) 	- Lvl 16
})[playerClass])

local spellCheckHarm = GetSpellInfo(({
	DEATHKNIGHT 	= 47541, 	-- Death Coil (30yd) 		- Lvl 1
	DRUID 			= 5176, 	-- Wrath (40yd) 			- Lvl 1
	HUNTER 			= 75, 		-- Auto Shot (40yd) 		- Lvl 1
	MAGE 			= 44614, 	-- Frostfire Bolt (40yd)	- Lvl 1
	MONK 			= 115546, 	-- Provoke (40yd)			- Lvl 14
	PALADIN 		= 20271, 	-- Judgment (30yd) 			- Lvl 5
	PRIEST 			= 589, 		-- Shadow Word: Pain (40yd) - Lvl 3
	SHAMAN 			= 403, 		-- Lightning Bolt (30yd) 	- Lvl 1
	WARLOCK 		= 686, 		-- Shadow Bolt (40yd) 		- Lvl 1
	WARRIOR 		= 355, 		-- Taunt (30yd) 			- Lvl 12
})[playerClass])

local updateFrame
local objects, objectRanges = {}, {}

-- Uses an appropriate range check for the given unit.
-- Actual range depends on reaction, known spells, and status of the unit.
local IsInRange = function(unit)
	if (UnitIsUnit(unit, "player")) then return true end

	if (UnitIsConnected(unit)) then
		if (UnitCanAssist("player", unit)) then
			if (spellCheckHelp and not UnitIsDead(unit)) then
				return IsSpellInRange(spellCheckHelp, unit) == 1 and true or false
			elseif (not UnitOnTaxi("player") and (UnitPlayerOrPetInParty(unit) or UnitPlayerOrPetInRaid(unit))) then
				local inRange, checkedRange = UnitInRange(unit)
				return checkedRange and not inRange and false or true  -- Fast checking for party/raid members (38 yd range)
			end
		elseif (spellCheckHarm and not UnitIsDead(unit) and UnitCanAttack("player", unit)) then
			return IsSpellInRange(spellCheckHarm, unit) == 1 and true or false
		end

		-- Fallback when spell not found or class uses none
		return CheckInteractDistance(unit, 4) and true or false
	end
end

--- Rechecks range for a unit frame, and fires callbacks when the unit passes in or out of range.
local UpdateRange = function (self)
	local inRange = IsInRange(self.unit)

	if (objectRanges[self] ~= inRange) then -- Range state changed
		objectRanges[self] = inRange

		local sr = self.SpellRange

		if (sr.Update) then
			sr.Update(self, inRange)
		else
			self:SetAlpha(sr[inRange and "insideAlpha" or "outsideAlpha"])
		end
	end
end

local OnUpdate
do
	local updated = 0

	--- Updates the range display for all visible oUF unit frames on an interval.
	OnUpdate = function(self, elapsed)
		updated = updated + elapsed

		if (updated >= updateRate) then
			updated = 0

			for object in pairs(objects) do
				if (object:IsVisible()) then
					UpdateRange(object)
				end
			end
		end
	end
end

-- Called by oUF when the unit frame's unit changes or
-- otherwise needs a complete update.
local Update = function(self, event, unit)
	-- OnTargetUpdate is fired on a timer for *target units that don't have real events
	if (event ~= "OnTargetUpdate") then
		objectRanges[self] = nil
		UpdateRange(self)
	end
end

local ForceUpdate = function(self)
	return Update(self.__owner, "ForceUpdate", self.__owner.unit)
end

-- Called by oUF for new unit frames to setup range checking.
local Enable = function(self, unit)
	local sr = self.SpellRange

	if (sr) then
		assert(type(sr) == "table", "Layout using invalid SpellRange element.")
		assert(type(sr.Update) == "function" or (tonumber(sr.insideAlpha) and tonumber(sr.outsideAlpha)), "Layout omitted required SpellRange properties.")

		-- Disable default range checking
		if (self.Range) then
			self:DisableElement("Range")
			self.Range = nil -- Prevent range element from enabling, since enable order isn't stable
		end

		sr.__owner = self
		sr.ForceUpdate = ForceUpdate

		if (not updateFrame) then
			updateFrame = CreateFrame"Frame"
			updateFrame:SetScript("OnUpdate", OnUpdate)
			updateFrame:SetScript("OnEvent", OnSpellsChanged)
		end

		-- First object
		if (not next(objects)) then
			updateFrame:Show()
		end

		objects[self] = true

		return true
	end
end

--- Called by oUF to disable range checking on a unit frame.
local Disable = function(self)
	objects[self] = nil
	objectRanges[self] = nil

	if (not next(objects)) then -- Last object
		updateFrame:Hide()
	end
end

oUF:AddElement("SpellRange", Update, Enable, Disable)
