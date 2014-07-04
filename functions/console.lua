--[[

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

--[[

--]]
local UIReload = function()
	ReloadUI()
end

local ReadyCheck = function()
	DoReadyCheck()
end

local ConsoleGrid = function(msg)
	if (msg and type(tonumber(msg)) == "number" and tonumber(msg) <= 256 and tonumber(msg) >= 4) then
		T:AlignGridToggle(msg)
	else
		T:AlignGridToggle()
	end
end

local DraeHideUI = function()
	if (InCombatLockdown()) then return end

	if (UIParent:IsShown())then
		UIParent:Hide()
		SetCVar("UnitNameOwn", 1)
		SetCVar("UnitNameFriendlyPlayerName", 1)
	else
		UIParent:Show()
		SetCVar("UnitNameOwn", 0)
		SetCVar("UnitNameFriendlyPlayerName", 0)
	end
end

T.InitializeConsoleCommands = function(self)
	self:RegisterChatCommand("rl", UIReload)
	self:RegisterChatCommand("rar", ReadyCheck)
	self:RegisterChatCommand("hideui", DraeHideUI)
	self:RegisterChatCommand("drgrid", ConsoleGrid)
end
