--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Localise a bunch of functions
local _G = _G
local format, unpack = string.format, unpack
local CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown = CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown
local UnitExists, GetComboPoints = UnitExists, GetComboPoints

--[[
		Warlock
		Hijacks all three Blizzard bars
--]]
do
	local OnEvent = function(self, event)
		local rs = self.resourceBar

		if (event == "PLAYER_REGEN_DISABLED") then
			rs:SetAlpha(1.0)
		else
			rs:SetAlpha(0)
		end
	end

	UF.CreateWarlockBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "WARLOCK") then return end

		local scale = 1.2

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs:EnableMouse(false)
		rs.unit = "player"

		_G["ShardBarFrame"]:SetParent(rs)
		_G["ShardBarFrame"]:ClearAllPoints()
		_G["ShardBarFrame"]:SetPoint(point, anchor, relpoint, xOffset / scale, yOffset / scale)
		_G["ShardBarFrame"]:SetScale(scale)

		_G["DemonicFuryBarFrame"]:SetParent(rs)
		_G["DemonicFuryBarFrame"]:ClearAllPoints()
		_G["DemonicFuryBarFrame"]:SetPoint(point, anchor, relpoint, xOffset / scale, yOffset / scale)
		_G["DemonicFuryBarFrame"]:SetScale(scale)

		_G["BurningEmbersBarFrame"]:SetParent(rs)
		_G["BurningEmbersBarFrame"]:ClearAllPoints()
		_G["BurningEmbersBarFrame"]:SetPoint(point, anchor, relpoint, xOffset / scale, yOffset / scale)
		_G["BurningEmbersBarFrame"]:SetScale(scale)

		rs:SetAlpha(0)

		self.resourceBar = rs

		self:RegisterEvent("PLAYER_REGEN_DISABLED", OnEvent, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", OnEvent, true)
	end
end
