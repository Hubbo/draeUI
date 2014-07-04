--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Localise a bunch of functions
local UnitIsAFK, UnitIsDND, UnitPowerType = UnitIsAFK, UnitIsDND, UnitPowerType
local UnitPlayerControlled, UnitIsTapped, UnitIsTappedByPlayer = UnitPlayerControlled, UnitIsTapped, UnitIsTappedByPlayer
local UnitIsPlayer, UnitPlayerControlled, UnitReaction = UnitIsPlayer, UnitPlayerControlled, UnitReaction
local UnitIsConnected, UnitClass, UnitIsTappedByAllThreatList = UnitIsConnected, UnitClass, UnitIsTappedByAllThreatList
local format = string.format

--[[
		Unit frame tags
--]]
oUF.Tags.Methods["drae:unitcolour"] = function(u, r)
	local reaction = UnitReaction(u, "player")

	if (not UnitPlayerControlled(u) and UnitIsTapped(u) and not (UnitIsTappedByPlayer(u) or UnitIsTappedByAllThreatList(u))) then
		return T.Hex(oUF.colors.tapped)
	elseif (not UnitIsConnected(u)) then
		return T.Hex(oUF.colors.disconnected)
	elseif (UnitIsPlayer(u) or (u == "pet" and UnitPlayerControlled(u))) then
		local _, class = UnitClass(u)
		return T.Hex(oUF.colors.class[class])
	elseif reaction then
		return T.Hex(oUF.colors.reaction[reaction])
	else
		return T.Hex(oUF.colors.health)
	end
end
oUF.Tags.Events["drae:unitcolour"] = "UNIT_FACTION UNIT_ENTERED_VEHICLE UNIT_EXITED_VEHICLE UNIT_PET"

oUF.Tags.Methods["drae:afk"] = function(u)
	if (UnitIsAFK(u)) then
		return "|cffff0000 - AFK|r"
	elseif (UnitIsDND(u)) then
		return "|cffff0000 - DND|r"
	end
end
oUF.Tags.Events["drae:afk"] = "PLAYER_FLAGS_CHANGED"

oUF.Tags.Methods["drae:power"] = function(u, t)
	local _, str = UnitPowerType(u)
	return ("%s%s|r"):format(T.Hex(oUF.colors.power[str] or {1, 1, 1}), T.ShortVal(oUF.Tags.Methods["curpp"](u)))
end
oUF.Tags.Events["drae:power"] = "UNIT_POWER UNIT_MAXPOWER"
