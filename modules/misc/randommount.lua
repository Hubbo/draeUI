--[[
		RandomCompanion
		Picks a random vanity pet or mount and automatically chooses the best type of mount for the job.
--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local RC = T:NewModule("RandomMount", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")

--
local _G = _G
local IsUsableSpell, GetRealZoneText, CanQueueForWintergrasp, GetWintergraspWaitTime, GetSpellBookItemInfo, IsSubmerged, IsSwimming, IsUsableSpell, GetProfessionInfo, GetNumCompanions, GetCompanionInfo, GetProfessions = IsUsableSpell, GetRealZoneText, CanQueueForWintergrasp, GetWintergraspWaitTime, GetSpellBookItemInfo, IsSubmerged, IsSwimming, IsUsableSpell, GetProfessionInfo, GetNumCompanions, GetCompanionInfo, GetProfessions
local tremove = table.remove

--
local mountList = {}
local lastMountId = 0

local professionMounts = {
	[61451] = { "Tailoring", 300 }, 	-- Flying Carpet
	[61309] = { "Tailoring", 425 }, 	-- Magnificent Flying Carpet
	[75596] = { "Tailoring", 425 }, 	-- Frosty Flying Carpet
	[44151] = { "Engineering", 375 }, 	-- Turbo-Charged Flying Machine
	[44153] = { "Engineering", 300 }, 	-- Flying Machine
}

local zonesNorthrend = {
	GetMapZones(4)
}

local zonesOldWorld = {
	GetMapZones(1),
	GetMapZones(2)
}

local hasEngineering = 0
local hasTailoring = 0

--[[

--]]
local inarray = function(needle, haystack)
	for _, v in pairs(haystack) do
		if (v == needle) then
			return true
		end
	end

	return false
end

-- Merge tables together returning new table
local tmerge = function(...)
	local t = {}

	for n = 1, select("#", ...) do
		local arg = select(n, ...)

		if (type(arg) == "table") then
			for j = 1, #arg do
				t[#t + 1] = arg[j]
			end
		else
			t[#t + 1] = arg
		end
	end

	return t
end
local CanWeFly = function()
	local index, zoneName

	if (IsFlyableArea()) then
		local canFly = true

		-- Wintergrasp in progress
		if (GetRealZoneText() == "Wintergrasp") then
			if (CanQueueForWintergrasp()) then
				if (GetWintergraspWaitTime()) then
					canFly = false
				end
			end
		end

		-- Cold Weather Flying
		for index, zoneName in pairs(zonesNorthrend) do
			if (zoneName == GetRealZoneText() and select(1, GetSpellBookItemInfo("Cold Weather Flying")) ~= "SPELL") then
				canFly = false
			end
		end

		-- Flight masters' licence
		for index, zoneName in pairs(zonesOldWorld) do
			if (zoneName == GetRealZoneText() and select(1, GetSpellBookItemInfo("Flight Master's License")) ~= "SPELL") then
				canFly = false
			end
		end

		if ((IsSubmerged() or IsSwimming()) and not select(1, IsUsableSpell(59976))) then
			canFly = false
		end

		return canFly
	else
		return false
	end
end

local CheckProfession = function(mountId)
	if (not professionMounts[mountId]) then
		return true
	end

	local mountProfReqd = professionMounts[mountId][1]
	local mountLvlReqd = professionMounts[mountId][2]

	if (mountProfReqd == "Engineering" and hasEngineering >= mountLvlReqd) then
		return true
	elseif (mountProfReqd == "Tailoring" and hasTailoring >= mountLvlReqd) then
		return true
	end

	return false
end

local GetRandomMount = function()
	local canFlySerpents = (select(1, GetSpellBookItemInfo("Cloud Serpent Riding")) == "SPELL") and true or false

	-- Are we in Vashj'ir?
	local inVashjir = inarray(GetRealZoneText(), { "Vashj'ir", "Kelp'thar Forest", "Shimmering Expanse", "Abyssal Depths" })

	-- Are we in Ahn'qiraj?
	local inAhnQiraj = select(1, IsUsableSpell(26054)) and true or false

	local possibleMounts = {}
	if (not IsIndoors()) then
		if (CanWeFly()) then
			possibleMounts = tmerge(G["mounts"]["fly"], G["mounts"]["professions"], canFlySerpents and G["mounts"]["serpents"] or {})
		elseif (inVashjir) then
			if (IsSubmerged()) then
				possibleMounts = G["mounts"]["vashjir"]
			else
				possibleMounts = tmerge(G["mounts"]["vashjir"], G["mounts"]["striders"])
			end
		elseif (inAhnQiraj) then
			possibleMounts = tmerge(G["mounts"]["ahnqiraj"], G["mounts"]["ground"], G["mounts"]["striders"])
		elseif (IsSwimming() or IsSubmerged()) then
			possibleMounts = tmerge(G["mounts"]["striders"])
		end

		-- Use striders if not max level, awesome for that
		if (#possibleMounts == 0) then
			possibleMounts = tmerge(G["mounts"]["striders"], (UnitLevel("player") >= MAX_PLAYER_LEVEL) and G["mounts"]["ground"] or {})
		end

		if (#possibleMounts) then
			for i = #possibleMounts, 1, -1 do
				local spellId = possibleMounts[i]

				if (not mountList[spellId] or not CheckProfession(spellId) or (lastMountId == spellId and #possibleMounts > 1)) then
					tremove(possibleMounts, i)
				end
			end

			return possibleMounts[random(#possibleMounts)]
		end
	end

	return false
end

-- This is made available across the namespace and is bound to /rc in console.lua
RC.Mount = function()
	if (IsMounted()) then
		Dismount()
	elseif (CanExitVehicle()) then
		VehicleExit()
	else
		local mountSpellId = GetRandomMount()
		local spellName = GetSpellInfo(mountSpellId)

		if (mountSpellId) then
			lastMountId = mountSpellId
			CallCompanion("MOUNT", mountList[mountSpellId])
		end
	end
end

--[[

--]]
RC.OnEnable = function(self)
	for i = 1, GetNumCompanions("MOUNT"), 1 do
		local _, _, spellid = GetCompanionInfo("MOUNT", i)
		mountList[spellid] = i
	end

	local prof1, prof2 = GetProfessions()

	if (prof1) then
		local name, _, rank = GetProfessionInfo(prof1)
		if (name == "Engineering") then
			hasEngineering = rank
		elseif (name == "Tailoring") then
			hasTailoring = rank
		end
	end

	if (prof2) then
		local name, _, rank = GetProfessionInfo(prof2)
		if (name == "Engineering") then
			hasEngineering = rank
		elseif (name == "Tailoring") then
			hasTailoring = rank
		end
	end

	self:RegisterChatCommand("rc", "Mount")
end
