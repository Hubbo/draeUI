--[[
		Largely copied from oRA3

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local TI = T:NewModule('AutoInvite', 'AceEvent-3.0')

-- Local copies
local _G = _G
local GetNumGroupMembers, UnitIsGroupAssistant, UnitIsGroupLeader, IsInRaid = GetNumGroupMembers, UnitIsGroupAssistant, UnitIsGroupLeader, IsInRaid
local ConvertToRaid, UnitInRaid, IsInInstance, SendChatMessage, InviteUnit = ConvertToRaid, UnitInRaid, IsInInstance, SendChatMessage, InviteUnit
local BNGetNumFriends, BNGetFriendInfo = BNGetNumFriends, BNGetFriendInfo
local pairs, tremove, next, wipe = pairs, table.remove, next, wipe
local BNET_CLIENT_WOW = BNET_CLIENT_WOW

--
local peopleToInvite = {}
local actualInviteFrame = CreateFrame("Frame")

--[[

--]]
local canInvite = function()
	if (GetNumGroupMembers() > 1) then
		return (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and true or false
	end

	return true
end

local doActualInvites
do
	local aiTotal = 0

	local _convertToRaid = function(self, elapsed)
		aiTotal = aiTotal + elapsed

		if (aiTotal > 1) then
			aiTotal = 0

			if (IsInRaid()) then
				self:SetScript("OnUpdate", nil)
				doActualInvites()
			end
		end
	end

	local _waitForParty = function(self, elapsed)
		aiTotal = aiTotal + elapsed

		if (aiTotal > 1) then
			aiTotal = 0

			if (GetNumGroupMembers() > 0 and not IsInRaid()) then
				ConvertToRaid()
				self:SetScript("OnUpdate", _convertToRaid)
			end
		end
	end

	doActualInvites = function()
		if (not UnitInRaid("player")) then
			local pNum = GetNumGroupMembers() + 1 -- 1-5

			if (pNum == 5) then
				if (#peopleToInvite > 0) then
					ConvertToRaid()
					actualInviteFrame:SetScript("OnUpdate", _convertToRaid)
				end
			else
				local tmp = {}

				for i = 1, (5 - pNum) do
					local u = tremove(peopleToInvite)

					if (u) then
						tmp[u] = true
					end
				end

				if (#peopleToInvite > 0) then
					actualInviteFrame:SetScript("OnUpdate", _waitForParty)
				end

				for k in pairs(tmp) do
					InviteUnit(k)
				end
			end

			return
		end

		for i, v in next, peopleToInvite do
			InviteUnit(v)
		end

		wipe(peopleToInvite)
	end
end

local handleWhisper = function(event, msg, author)
	local low = msg:lower()

	if (low == "i" and canInvite()) then
		local isIn, instanceType = IsInInstance()
		local party = GetNumGroupMembers()
		local raid = IsInRaid()

		if (isIn and instanceType == "party" and party == 4) then
			SendChatMessage("Sorry, the group is full.", "WHISPER", nil, author)
		elseif (party == 4 and not raid) then
			peopleToInvite[#peopleToInvite + 1] = author

			doActualInvites()
		elseif (party == 40 and raid) then
			SendChatMessage("Sorry, the raid is full.", "WHISPER", nil, author)
		else
			InviteUnit(author)
		end
	end
end

--[[

--]]
TI.CHAT_MSG_BN_WHISPER = function(self, event, msg, author, _, _, _, _, _, _, _, _, _, _, presenceId)
	for i = 1, BNGetNumFriends() do
		local friendPresenceId, _, _, _, toonName, _, client = BNGetFriendInfo(i)
		if (client == BNET_CLIENT_WOW and presenceId == friendPresenceId) then
			handleWhisper(event, msg, toonName)
			break
		end
	end
end

TI.CHAT_MSG_WHISPER = function(self, event, msg, author)
	handleWhisper(event, msg, author)
end

TI.OnEnable = function(self)
	self:RegisterEvent("CHAT_MSG_BN_WHISPER")
	self:RegisterEvent("CHAT_MSG_WHISPER")
end
